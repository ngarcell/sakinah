import SwiftUI
import SwiftData

struct LessonDetailView: View {
    let lesson: LessonData
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isActionCompleted = false
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            SakinahColor.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Parallax illustration
                    GeometryReader { geo in
                        let offset = geo.frame(in: .global).minY
                        ZStack {
                            SakinahColor.primaryLight
                            LessonIllustration(category: lesson.category)
                                .opacity(0.15)
                            Image(systemName: categoryIcon)
                                .font(.system(size: 48))
                                .foregroundStyle(SakinahColor.primary.opacity(0.25))
                        }
                        .frame(height: max(240, 240 + offset * 0.5))
                        .offset(y: offset > 0 ? -offset * 0.5 : 0)
                    }
                    .frame(height: 240)

                    VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
                        // Title area
                        VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
                            SakinahBadge(text: lesson.category.capitalized)
                            Text(lesson.title)
                                .font(SakinahFont.title1)
                                .foregroundStyle(SakinahColor.textPrimary)
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                Text("\(lesson.readTimeMinutes) min read")
                                    .font(SakinahFont.caption)
                            }
                            .foregroundStyle(SakinahColor.textTertiary)
                        }

                        // Content sections
                        ForEach(lesson.sections) { section in
                            sectionView(section)
                        }

                        // Try This card
                        tryThisCard

                        // Share
                        SakinahButton(title: "Share Lesson", icon: "square.and.arrow.up", variant: .ghost) {
                            // Share sheet handled by system
                        }

                        Spacer().frame(height: 60)
                    }
                    .padding(.horizontal, SakinahSpacing.base)
                    .padding(.top, SakinahSpacing.lg)
                }
            }
            .scrollIndicators(.hidden)

            // Back button
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(SakinahColor.primary)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding(.leading, SakinahSpacing.base)
            .padding(.top, SakinahSpacing.sm)
        }
        .navigationBarBackButtonHidden()
    }

    @ViewBuilder
    private func sectionView(_ section: LessonSection) -> some View {
        if section.type == "hadith" {
            VStack(spacing: SakinahSpacing.md) {
                if let arabic = section.arabic {
                    Text(arabic)
                        .font(SakinahFont.arabic)
                        .foregroundStyle(SakinahColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .environment(\.layoutDirection, .rightToLeft)
                        .lineSpacing(8)
                }
                if let trans = section.transliteration {
                    Text(trans)
                        .font(SakinahFont.bodySmall)
                        .italic()
                        .foregroundStyle(SakinahColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                Rectangle().fill(SakinahColor.divider).frame(width: 40, height: 1)
                if let translation = section.translation {
                    Text(translation)
                        .font(SakinahFont.body)
                        .foregroundStyle(SakinahColor.textPrimary)
                        .multilineTextAlignment(.center)
                }
                if let source = section.source {
                    Text("— \(source)")
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textTertiary)
                }
            }
            .padding(SakinahSpacing.lg)
            .frame(maxWidth: .infinity)
            .background(SakinahColor.backgroundSecondary)
            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
        } else {
            VStack(alignment: .leading, spacing: SakinahSpacing.md) {
                if let heading = section.heading {
                    Text(heading)
                        .font(SakinahFont.title3)
                        .foregroundStyle(SakinahColor.textPrimary)
                }
                if let body = section.body {
                    // Check for pull quotes (lines starting with specific patterns)
                    let paragraphs = body.components(separatedBy: "\n\n")
                    ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, para in
                        Text(para)
                            .font(SakinahFont.body)
                            .foregroundStyle(SakinahColor.textPrimary)
                            .lineSpacing(6)
                    }
                }
            }
        }
    }

    private var tryThisCard: some View {
        VStack(alignment: .leading, spacing: SakinahSpacing.md) {
            Text("Try This Together 💡")
                .font(SakinahFont.headline)
                .foregroundStyle(SakinahColor.textPrimary)
            Text(lesson.tryThis.description)
                .font(SakinahFont.body)
                .foregroundStyle(SakinahColor.textPrimary)
                .lineSpacing(4)
            SakinahButton(title: isActionCompleted ? "Done ✓" : "Mark as Done", variant: .secondary) {
                markComplete()
            }
            .disabled(isActionCompleted)
            .opacity(isActionCompleted ? 0.6 : 1)
        }
        .padding(SakinahSpacing.base)
        .background(SakinahColor.accentLight)
        .clipShape(.rect(cornerRadius: SakinahRadius.medium))
    }

    private func markComplete() {
        HapticEngine.shared.fire(.success)
        let lessonCompletion = Lesson(id: lesson.id, isCompleted: true, completedAt: Date())
        modelContext.insert(lessonCompletion)
        try? modelContext.save()
        withAnimation(SakinahAnimation.bounce) { isActionCompleted = true }
    }

    private var categoryIcon: String {
        switch lesson.category {
        case "communication": return "bubble.left.and.bubble.right.fill"
        case "conflict": return "hand.raised.fill"
        case "spiritual": return "moon.stars.fill"
        case "intimacy": return "heart.fill"
        case "practical": return "briefcase.fill"
        default: return "book.fill"
        }
    }
}

struct PackDetailSheet: View {
    let pack: ConversationPack
    let isPremium: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var expandedPrompt: Int? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                SakinahColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: SakinahSpacing.lg) {
                        // Header gradient
                        ZStack {
                            LinearGradient(colors: [Color(hex: pack.gradientStart), Color(hex: pack.gradientEnd)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            VStack {
                                Image(systemName: pack.icon)
                                    .font(.system(size: 36))
                                    .foregroundStyle(.white)
                                Text(pack.name)
                                    .font(SakinahFont.title2)
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(height: 140)
                        .clipShape(.rect(cornerRadius: SakinahRadius.large))
                        .padding(.horizontal, SakinahSpacing.base)

                        // Prompts list
                        ForEach(Array(pack.prompts.enumerated()), id: \.offset) { index, prompt in
                            let isLocked = !isPremium && index >= 3
                            promptRow(prompt: prompt, index: index, isLocked: isLocked)
                        }

                        if !isPremium {
                            SakinahButton(title: "Upgrade to Premium", icon: "crown.fill") {
                                dismiss()
                            }
                            .padding(.horizontal, SakinahSpacing.base)
                        }
                    }
                    .padding(.vertical, SakinahSpacing.lg)
                }
            }
            .navigationTitle(pack.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(SakinahColor.primary)
                }
            }
        }
    }

    private func promptRow(prompt: String, index: Int, isLocked: Bool) -> some View {
        VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
            HStack(alignment: .top, spacing: SakinahSpacing.md) {
                Text("\(index + 1)")
                    .font(SakinahFont.captionBold)
                    .foregroundStyle(SakinahColor.textTertiary)
                    .frame(width: 24)
                Text(prompt)
                    .font(SakinahFont.body)
                    .foregroundStyle(SakinahColor.textPrimary)
                    .blur(radius: isLocked ? 4 : 0)
                Spacer()
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(SakinahColor.textTertiary)
                }
            }
        }
        .padding(SakinahSpacing.base)
        .background(SakinahColor.surface)
        .clipShape(.rect(cornerRadius: SakinahRadius.medium))
        .padding(.horizontal, SakinahSpacing.base)
    }
}

extension ConversationPack: @retroactive Hashable {
    nonisolated static func == (lhs: ConversationPack, rhs: ConversationPack) -> Bool { lhs.id == rhs.id }
    nonisolated func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

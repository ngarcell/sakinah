import SwiftUI
import SwiftData

struct LessonDetailView: View {
    let lesson: LessonData
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isActionCompleted = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
                    ProgressView(value: chapterProgress)
                        .tint(SakinahColor.primary)

                    VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
                        SakinahBadge(text: lesson.category.capitalized)
                        Text(lesson.title)
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundStyle(SakinahColor.textPrimary)
                            .lineSpacing(4)
                        Text("\(lesson.readTimeMinutes) min read")
                            .font(SakinahFont.caption)
                            .foregroundStyle(SakinahColor.textTertiary)
                    }

                    ForEach(visibleSections) { section in
                        sectionView(section)
                    }

                    if !appState.hasPremiumAccess {
                        UpgradePromptView(
                            icon: "book.closed.fill",
                            headline: "Continue reading with Sakinah Premium",
                            message: "The first chapter is your preview. Unlock the rest of this lesson and the full guided library.",
                            ctaTitle: "Begin my journey"
                        ) {
                            appState.presentPaywall(for: .guidedLesson)
                            dismiss()
                        }
                    } else {
                        tryThisCard
                    }

                    Spacer().frame(height: 32)
                }
                .padding(SakinahSpacing.base)
            }
            .background(SakinahColor.background)
            .navigationTitle("Lesson")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(SakinahColor.primary)
                }
            }
        }
    }

    private var visibleSections: [LessonSection] {
        appState.hasPremiumAccess ? lesson.sections : Array(lesson.sections.prefix(1))
    }

    private var chapterProgress: Double {
        guard !lesson.sections.isEmpty else { return 0 }
        return Double(visibleSections.count) / Double(lesson.sections.count)
    }

    @ViewBuilder
    private func sectionView(_ section: LessonSection) -> some View {
        if section.type == "hadith" {
            VStack(spacing: SakinahSpacing.md) {
                if let arabic = section.arabic {
                    Text(arabic)
                        .font(SakinahFont.arabic)
                        .foregroundStyle(SakinahColor.textPrimary)
                        .multilineTextAlignment(.trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                        .lineSpacing(8)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                if let transliteration = section.transliteration {
                    Text(transliteration)
                        .font(SakinahFont.bodySmall)
                        .italic()
                        .foregroundStyle(SakinahColor.textSecondary)
                }
                Rectangle()
                    .fill(SakinahColor.divider)
                    .frame(width: 40, height: 1)
                if let translation = section.translation {
                    Text(translation)
                        .font(SakinahFont.body)
                        .foregroundStyle(SakinahColor.textPrimary)
                        .lineSpacing(5)
                }
                if let source = section.source {
                    Text(source)
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textTertiary)
                }
            }
            .padding(SakinahSpacing.base)
            .background(SakinahColor.surfaceWarm)
            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
        } else {
            VStack(alignment: .leading, spacing: SakinahSpacing.md) {
                if let heading = section.heading {
                    Text(heading)
                        .font(SakinahFont.title3)
                        .foregroundStyle(SakinahColor.textPrimary)
                }
                if let body = section.body {
                    ForEach(Array(body.components(separatedBy: "\n\n").enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph)
                            .font(SakinahFont.body)
                            .foregroundStyle(SakinahColor.textPrimary)
                            .lineSpacing(7)
                    }
                }
            }
        }
    }

    private var tryThisCard: some View {
        VStack(alignment: .leading, spacing: SakinahSpacing.md) {
            Text("Try this together")
                .font(SakinahFont.headline)
                .foregroundStyle(SakinahColor.textPrimary)

            Text(lesson.tryThis.description)
                .font(SakinahFont.body)
                .foregroundStyle(SakinahColor.textPrimary)
                .lineSpacing(4)

            SakinahButton(title: isActionCompleted ? "Done" : "Mark as Done", icon: isActionCompleted ? "checkmark.circle.fill" : nil, variant: .secondary) {
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
}

struct PackDetailSheet: View {
    let pack: ConversationPack
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SakinahSpacing.md) {
                    Text(pack.name)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(SakinahColor.textPrimary)
                        .padding(.horizontal, SakinahSpacing.base)

                    ForEach(Array(pack.prompts.enumerated()), id: \.offset) { index, prompt in
                        promptRow(prompt: prompt, index: index)
                    }
                }
                .padding(.vertical, SakinahSpacing.base)
            }
            .background(SakinahColor.background)
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

    private func promptRow(prompt: String, index: Int) -> some View {
        HStack(alignment: .top, spacing: SakinahSpacing.md) {
            Text("\(index + 1)")
                .font(SakinahFont.captionBold)
                .foregroundStyle(SakinahColor.textTertiary)
                .frame(width: 24)
            Text(prompt)
                .font(SakinahFont.body)
                .foregroundStyle(SakinahColor.textPrimary)
                .lineSpacing(4)
            Spacer()
        }
        .padding(SakinahSpacing.base)
        .background(SakinahColor.surface)
        .clipShape(.rect(cornerRadius: SakinahRadius.medium))
        .padding(.horizontal, SakinahSpacing.base)
    }
}

extension ConversationPack: Hashable {
    nonisolated static func == (lhs: ConversationPack, rhs: ConversationPack) -> Bool { lhs.id == rhs.id }
    nonisolated func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

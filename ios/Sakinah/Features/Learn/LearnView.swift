import SwiftUI
import SwiftData

struct LearnView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var completedLessons: [Lesson]
    @State private var selectedLesson: LessonData?
    @State private var selectedPack: ConversationPack?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                SakinahColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SakinahSpacing.xxl) {
                        // Header
                        VStack(spacing: SakinahSpacing.xs) {
                            Text("Learn")
                                .font(SakinahFont.title1)
                                .foregroundStyle(SakinahColor.textPrimary)
                            Text("Strengthen what matters most")
                                .font(SakinahFont.bodySmall)
                                .foregroundStyle(SakinahColor.textSecondary)
                        }
                        .padding(.top, SakinahSpacing.lg)

                        // Weekly Lesson
                        weeklyLesson

                        // Conversation Starters
                        conversationStarters

                        // Past lessons
                        pastLessons

                        Spacer().frame(height: 100)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .sheet(item: $selectedLesson) { lesson in
                LessonDetailView(lesson: lesson)
            }
            .sheet(item: $selectedPack) { pack in
                packDetailSheet(pack)
            }
            .sheet(isPresented: $showPaywall) {
                SakinahPaywallView()
            }
        }
    }

    private var weeklyLesson: some View {
        Group {
            if let lesson = LessonService.shared.currentWeekLesson() {
                SakinahCard(elevated: true) {
                    VStack(alignment: .leading, spacing: SakinahSpacing.md) {
                        LessonIllustration(category: lesson.category)
                            .frame(height: 120)
                            .clipShape(.rect(cornerRadius: SakinahRadius.medium))

                        SakinahBadge(text: lesson.category.capitalized, color: SakinahColor.primary, tintedBackground: SakinahColor.primaryLight)

                        Text(lesson.title)
                            .font(SakinahFont.title2)
                            .foregroundStyle(SakinahColor.textPrimary)

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text("\(lesson.readTimeMinutes) min read")
                                .font(SakinahFont.caption)
                        }
                        .foregroundStyle(SakinahColor.textTertiary)

                        if let first = lesson.sections.first, let body = first.body {
                            Text(body)
                                .font(SakinahFont.body)
                                .foregroundStyle(SakinahColor.textSecondary)
                                .lineLimit(2)
                        }

                        SakinahButton(title: "Read Lesson") {
                            selectedLesson = lesson
                        }
                    }
                }
                .padding(.horizontal, SakinahSpacing.base)
            }
        }
    }

    private var conversationStarters: some View {
        VStack(alignment: .leading, spacing: SakinahSpacing.md) {
            HStack {
                Text("Conversation Starters")
                    .font(SakinahFont.title3)
                    .foregroundStyle(SakinahColor.textPrimary)
                if !appState.isPremium {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(SakinahColor.accent)
                }
                Spacer()
            }
            .padding(.horizontal, SakinahSpacing.base)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SakinahSpacing.md) {
                    ForEach(ConversationPack.allPacks) { pack in
                        packCard(pack)
                    }
                }
                .padding(.horizontal, SakinahSpacing.base)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)

            // Upgrade prompt after browsing packs
            if !appState.isPremium {
                UpgradePromptView(
                    icon: "bubble.left.and.bubble.right.fill",
                    headline: "100+ conversation prompts",
                    message: "Go beyond surface-level with themed packs.",
                    ctaTitle: "Unlock all packs",
                    onUpgrade: { showPaywall = true }
                )
                .padding(.horizontal, SakinahSpacing.base)
            }
        }
    }

    private func packCard(_ pack: ConversationPack) -> some View {
        Button {
            HapticEngine.shared.fire(.tap)
            if appState.isPremium {
                selectedPack = pack
            } else {
                showPaywall = true
            }
        } label: {
            VStack(spacing: 0) {
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: pack.gradientStart), Color(hex: pack.gradientEnd)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    Image(systemName: pack.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.white)

                    if !appState.isPremium {
                        Color.black.opacity(0.25)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                    }
                }
                .frame(height: 130)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.name)
                        .font(SakinahFont.headline)
                        .foregroundStyle(SakinahColor.textPrimary)
                        .lineLimit(1)
                    Text("\(pack.promptCount) prompts")
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textSecondary)
                }
                .padding(SakinahSpacing.md)
                .frame(width: 200, alignment: .leading)
            }
            .frame(width: 200, height: 210)
            .background(SakinahColor.surface)
            .clipShape(.rect(cornerRadius: SakinahRadius.large))
            .sakinahShadow(.subtle)
        }
        .pressScale()
    }

    private func packDetailSheet(_ pack: ConversationPack) -> some View {
        NavigationStack {
            List {
                ForEach(pack.prompts, id: \.self) { prompt in
                    Text(prompt)
                        .font(SakinahFont.body)
                        .foregroundStyle(SakinahColor.textPrimary)
                        .listRowBackground(SakinahColor.surface)
                }
            }
            .navigationTitle(pack.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var pastLessons: some View {
        Group {
            let completed = LessonService.shared.completedLessons(from: completedLessons)
            if !completed.isEmpty {
                VStack(alignment: .leading, spacing: SakinahSpacing.md) {
                    Text("Past Lessons")
                        .font(SakinahFont.captionBold)
                        .foregroundStyle(SakinahColor.textSecondary)
                        .tracking(0.4)
                        .textCase(.uppercase)
                        .padding(.horizontal, SakinahSpacing.base)

                    ForEach(completed) { lesson in
                        Button {
                            selectedLesson = lesson
                        } label: {
                            HStack(spacing: SakinahSpacing.md) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(SakinahColor.success)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(lesson.title)
                                        .font(SakinahFont.bodySmall)
                                        .foregroundStyle(SakinahColor.textPrimary)
                                    Text(lesson.category.capitalized)
                                        .font(SakinahFont.caption)
                                        .foregroundStyle(SakinahColor.textTertiary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(SakinahColor.textTertiary)
                            }
                            .padding(SakinahSpacing.base)
                            .background(SakinahColor.surface)
                            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
                        }
                        .padding(.horizontal, SakinahSpacing.base)
                    }
                }
            }
        }
    }
}

struct LessonIllustration: View {
    let category: String
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius: CGFloat = min(size.width, size.height) * 0.3
                for i in 0..<8 {
                    let angle = (Double(i) / 8) * 2 * .pi
                    let x = center.x + cos(angle) * radius
                    let y = center.y + sin(angle) * radius
                    let rect = CGRect(x: x - 15, y: y - 15, width: 30, height: 30)
                    var diamond = Path()
                    diamond.move(to: CGPoint(x: rect.midX, y: rect.minY))
                    diamond.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
                    diamond.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
                    diamond.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
                    diamond.closeSubpath()
                    context.stroke(diamond, with: .color(SakinahColor.primary), lineWidth: 1)
                }
            }
        }
    }
}

extension LessonData: Hashable {
    nonisolated static func == (lhs: LessonData, rhs: LessonData) -> Bool { lhs.id == rhs.id }
    nonisolated func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

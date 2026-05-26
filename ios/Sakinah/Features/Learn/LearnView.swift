import SwiftUI
import SwiftData

struct LearnView: View {
    @Environment(AppState.self) private var appState
    @Query private var completedLessons: [Lesson]
    @State private var selectedLesson: LessonData?
    @State private var selectedPack: ConversationPack?

    var body: some View {
        NavigationStack {
            ZStack {
                SakinahColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: SakinahSpacing.xxl) {
                        weeklyLesson
                        conversationPacks
                        completedLessonsSection
                        Spacer().frame(height: 32)
                    }
                    .padding(.top, SakinahSpacing.md)
                    .padding(.bottom, SakinahSpacing.jumbo)
                }
                .scrollIndicators(.hidden)
            }
            .sheet(item: $selectedLesson) { lesson in
                LessonDetailView(lesson: lesson)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedPack) { pack in
                PackDetailSheet(pack: pack)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    @ViewBuilder
    private var weeklyLesson: some View {
        if let lesson = LessonService.shared.currentWeekLesson() {
            Button {
                HapticEngine.shared.fire(.tap)
                selectedLesson = lesson
            } label: {
                VStack(alignment: .leading, spacing: SakinahSpacing.base) {
                    Text("THIS WEEK")
                        .font(SakinahFont.captionBold)
                        .tracking(0.4)
                        .foregroundStyle(.white.opacity(0.82))

                    Text(lesson.title)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    if let firstBody = lesson.sections.first?.body {
                        Text(firstBody)
                            .font(SakinahFont.bodySmall)
                            .foregroundStyle(.white.opacity(0.86))
                            .lineLimit(2)
                    }

                    HStack(spacing: SakinahSpacing.xs) {
                        ForEach(0..<5, id: \.self) { index in
                            Circle()
                                .fill(index == 0 ? .white : .white.opacity(0.35))
                                .frame(width: 7, height: 7)
                        }
                        Text("1 of 5 chapters")
                            .font(SakinahFont.caption)
                            .foregroundStyle(.white.opacity(0.82))
                        Spacer()
                        Text("\(lesson.readTimeMinutes) min")
                            .font(SakinahFont.caption)
                            .foregroundStyle(.white.opacity(0.82))
                    }

                    HStack {
                        Text(appState.hasPremiumAccess ? "Continue Reading" : "Preview Lesson")
                            .font(SakinahFont.headline)
                        Image(systemName: "arrow.right")
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.top, SakinahSpacing.xs)
                }
                .padding(SakinahSpacing.base)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: SakinahColor.heroGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(.rect(cornerRadius: SakinahRadius.medium))
                .sakinahShadow(.medium)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, SakinahSpacing.base)
        }
    }

    private var conversationPacks: some View {
        VStack(alignment: .leading, spacing: SakinahSpacing.md) {
            Text("CONVERSATION PACKS")
                .font(SakinahFont.captionBold)
                .tracking(0.4)
                .foregroundStyle(SakinahColor.textSecondary)
                .padding(.horizontal, SakinahSpacing.base)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: SakinahSpacing.md),
                    GridItem(.flexible(), spacing: SakinahSpacing.md)
                ],
                spacing: SakinahSpacing.md
            ) {
                ForEach(ConversationPack.allPacks) { pack in
                    packCard(pack)
                }
            }
            .padding(.horizontal, SakinahSpacing.base)
        }
    }

    private func packCard(_ pack: ConversationPack) -> some View {
        Button {
            HapticEngine.shared.fire(.tap)
            if appState.hasPremiumAccess {
                selectedPack = pack
            } else {
                appState.presentPaywall(for: .conversationPacks)
            }
        } label: {
            VStack(alignment: .leading, spacing: SakinahSpacing.md) {
                Image(systemName: pack.icon)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(SakinahColor.primary)

                VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                    Text(pack.name)
                        .font(SakinahFont.headline)
                        .foregroundStyle(SakinahColor.textPrimary)
                        .lineLimit(2)

                    Text("\(pack.promptCount) prompts")
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textSecondary)
                }

                Spacer(minLength: 0)

                SakinahBadge(
                    text: appState.hasPremiumAccess ? "Open" : "Premium",
                    icon: appState.hasPremiumAccess ? "checkmark" : "lock.fill",
                    color: appState.hasPremiumAccess ? SakinahColor.primary : .white,
                    tintedBackground: appState.hasPremiumAccess ? SakinahColor.primaryLight : SakinahColor.accent
                )
            }
            .padding(SakinahSpacing.base)
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
            .background(SakinahColor.surface)
            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: SakinahRadius.medium)
                    .stroke(SakinahColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var completedLessonsSection: some View {
        if !completedLessonItems.isEmpty {
            VStack(alignment: .leading, spacing: SakinahSpacing.md) {
                HStack {
                    Text("COMPLETED")
                        .font(SakinahFont.captionBold)
                        .tracking(0.4)
                        .foregroundStyle(SakinahColor.textSecondary)
                    Spacer()
                    Text("\(completedLessonItems.count) lessons")
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textTertiary)
                }
                .padding(.horizontal, SakinahSpacing.base)

                VStack(spacing: SakinahSpacing.sm) {
                    ForEach(completedLessonItems) { lesson in
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
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, SakinahSpacing.base)
            }
        }
    }

    private var completedLessonItems: [LessonData] {
        LessonService.shared.completedLessons(from: completedLessons)
    }
}

struct LessonIllustration: View {
    let category: String

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius: CGFloat = min(size.width, size.height) * 0.3
            for index in 0..<8 {
                let angle = (Double(index) / 8) * 2 * .pi
                let x = center.x + cos(angle) * radius
                let y = center.y + sin(angle) * radius
                let rect = CGRect(x: x - 15, y: y - 15, width: 30, height: 30)
                var diamond = Path()
                diamond.move(to: CGPoint(x: rect.midX, y: rect.minY))
                diamond.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
                diamond.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
                diamond.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
                diamond.closeSubpath()
                context.stroke(diamond, with: .color(SakinahColor.primary.opacity(0.22)), lineWidth: 1)
            }
        }
    }
}

extension LessonData: Hashable {
    nonisolated static func == (lhs: LessonData, rhs: LessonData) -> Bool { lhs.id == rhs.id }
    nonisolated func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

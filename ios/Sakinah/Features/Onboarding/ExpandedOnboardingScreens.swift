import SwiftUI
import SwiftData

struct OnboardingProgressHeader: View {
    let step: OnboardingStep
    var showsBack: Bool = true
    var backAction: (() -> Void)? = nil

    private var progress: CGFloat {
        CGFloat(step.flowIndex) / CGFloat(OnboardingStep.totalSteps)
    }

    var body: some View {
        VStack(spacing: SakinahSpacing.sm) {
            HStack {
                if showsBack, let backAction {
                    Button {
                        HapticEngine.shared.fire(.tap)
                        backAction()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(SakinahColor.textPrimary)
                            .frame(width: 40, height: 40)
                            .background(SakinahColor.surface)
                            .clipShape(Circle())
                            .sakinahShadow(.subtle)
                    }
                    .buttonStyle(.plain)
                    .pressScale()
                } else {
                    Color.clear
                        .frame(width: 40, height: 40)
                }

                Spacer()

                Text(step.progressPhrase)
                    .font(SakinahFont.captionBold)
                    .foregroundStyle(SakinahColor.textSecondary)

                Spacer()

                Color.clear
                    .frame(width: 40, height: 40)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(SakinahColor.backgroundSecondary)
                    Capsule()
                        .fill(SakinahColor.primary)
                        .frame(width: max(8, proxy.size.width * progress))
                }
            }
            .frame(height: 4)
            .animation(SakinahAnimation.gentle, value: step)
        }
        .padding(.top, SakinahSpacing.sm)
        .padding(.horizontal, SakinahSpacing.base)
    }
}

struct OnboardingIntroText: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
            Text(title)
                .font(SakinahFont.title1)
                .foregroundStyle(SakinahColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(SakinahFont.bodySmall)
                .foregroundStyle(SakinahColor.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct OnboardingSelectionCard: View {
    let title: String
    var subtitle: String? = nil
    var icon: String = "circle"
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticEngine.shared.fire(.select)
            action()
        } label: {
            HStack(alignment: .top, spacing: SakinahSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : SakinahColor.primary)
                    .frame(width: 34, height: 34)
                    .background(isSelected ? SakinahColor.primary : SakinahColor.primaryLight)
                    .clipShape(.rect(cornerRadius: SakinahRadius.small))

                VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                    Text(title)
                        .font(SakinahFont.headline)
                        .foregroundStyle(SakinahColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle {
                        Text(subtitle)
                            .font(SakinahFont.bodySmall)
                            .foregroundStyle(SakinahColor.textSecondary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: SakinahSpacing.sm)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSelected ? SakinahColor.accent : SakinahColor.textTertiary)
            }
            .padding(SakinahSpacing.base)
            .background(isSelected ? SakinahColor.accentLight.opacity(0.75) : SakinahColor.surface)
            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: SakinahRadius.medium)
                    .stroke(isSelected ? SakinahColor.accent.opacity(0.45) : SakinahColor.border.opacity(0.8), lineWidth: 1)
            )
            .sakinahShadow(isSelected ? .medium : .subtle)
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingOutcomeScreen: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressHeader(step: .outcome) {
                vm.goBack(context: modelContext)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
                    OnboardingIntroText(
                        title: "A calmer way to care for your marriage",
                        subtitle: "Sakinah is not another place to manage tasks. It is a private rhythm for feeling understood, making space for faith, and returning to each other with less pressure."
                    )

                    SakinahCard(elevated: true, warm: true) {
                        VStack(spacing: SakinahSpacing.base) {
                            GeometricPattern()
                                .frame(height: 150)
                                .frame(maxWidth: .infinity)
                                .clipShape(.rect(cornerRadius: SakinahRadius.medium))

                            VStack(alignment: .leading, spacing: SakinahSpacing.md) {
                                outcomeRow(
                                    icon: "heart.text.square.fill",
                                    title: "Feel understood before hard conversations",
                                    subtitle: "Begin with one honest answer instead of jumping straight into solving."
                                )
                                outcomeRow(
                                    icon: "sun.max.fill",
                                    title: "Build a rhythm you can actually keep",
                                    subtitle: "Small daily rituals, weekly reflection, and gentle prompts replace heavy relationship homework."
                                )
                                outcomeRow(
                                    icon: "lock.shield.fill",
                                    title: "Keep the space private and intentional",
                                    subtitle: "Your setup shapes the first week without asking for device permissions or public sharing."
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.vertical, SakinahSpacing.xl)
            }

            SakinahButton(title: "Shape our ritual") {
                vm.advance(to: .relationshipStage, context: modelContext)
            }
            .padding(.horizontal, SakinahSpacing.base)
            .padding(.bottom, SakinahSpacing.base)
        }
    }

    private func outcomeRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: SakinahSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(SakinahColor.primary)
                .frame(width: 34, height: 34)
                .background(SakinahColor.primaryLight)
                .clipShape(.rect(cornerRadius: SakinahRadius.small))

            VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                Text(title)
                    .font(SakinahFont.headline)
                    .foregroundStyle(SakinahColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SakinahColor.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct RelationshipStageScreen: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressHeader(step: .relationshipStage) {
                vm.goBack(context: modelContext)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
                    OnboardingIntroText(
                        title: "Where are you together right now?",
                        subtitle: "Your first week should match the season you are actually in, not a generic relationship template."
                    )

                    VStack(spacing: SakinahSpacing.sm) {
                        ForEach(RelationshipStage.allCases, id: \.self) { stage in
                            OnboardingSelectionCard(
                                title: stage.label,
                                subtitle: subtitle(for: stage),
                                icon: icon(for: stage),
                                isSelected: vm.relationshipStage == stage
                            ) {
                                vm.relationshipStage = stage
                            }
                        }
                    }
                }
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.vertical, SakinahSpacing.xl)
            }

            SakinahButton(title: "Continue") {
                vm.advance(to: .focusGoal, context: modelContext)
            }
            .padding(.horizontal, SakinahSpacing.base)
            .padding(.bottom, SakinahSpacing.base)
        }
    }

    private func icon(for stage: RelationshipStage) -> String {
        switch stage {
        case .engaged: return "sparkles"
        case .married: return "house.fill"
        case .longDistance: return "globe"
        }
    }

    private func subtitle(for stage: RelationshipStage) -> String {
        switch stage {
        case .engaged:
            return "Prepare for marriage with gentle conversations and shared intentions."
        case .married:
            return "Care for the rhythm you already live inside every day."
        case .longDistance:
            return "Stay emotionally close while time, place, or schedules make connection harder."
        }
    }
}

struct FocusGoalScreen: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressHeader(step: .focusGoal) {
                vm.goBack(context: modelContext)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
                    OnboardingIntroText(
                        title: "What do you want more of?",
                        subtitle: "Choose the outcome that would make the next few days feel lighter or more grounded."
                    )

                    VStack(spacing: SakinahSpacing.sm) {
                        ForEach(RelationshipFocus.allCases, id: \.self) { focus in
                            OnboardingSelectionCard(
                                title: focus.label,
                                subtitle: subtitle(for: focus),
                                icon: icon(for: focus),
                                isSelected: vm.relationshipFocus == focus
                            ) {
                                vm.relationshipFocus = focus
                            }
                        }
                    }
                }
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.vertical, SakinahSpacing.xl)
            }

            SakinahButton(title: "Make it specific") {
                vm.advance(to: .clarify, context: modelContext)
            }
            .padding(.horizontal, SakinahSpacing.base)
            .padding(.bottom, SakinahSpacing.base)
        }
    }

    private func icon(for focus: RelationshipFocus) -> String {
        switch focus {
        case .connection: return "heart.fill"
        case .communication: return "bubble.left.and.bubble.right.fill"
        case .conflictRepair: return "leaf.fill"
        case .spiritualRhythm: return "moon.stars.fill"
        case .futurePlanning: return "map.fill"
        }
    }

    private func subtitle(for focus: RelationshipFocus) -> String {
        switch focus {
        case .connection:
            return "More warmth, ease, and everyday closeness."
        case .communication:
            return "More honest conversations that feel safe to begin."
        case .conflictRepair:
            return "More gentleness before, during, and after tense moments."
        case .spiritualRhythm:
            return "More shared remembrance, du'a, and grounded intention."
        case .futurePlanning:
            return "More clarity about the life you are building together."
        }
    }
}

struct OnboardingMomentumScreen: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressHeader(step: .momentum) {
                vm.goBack(context: modelContext)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
                    OnboardingIntroText(
                        title: "Your first week is taking shape",
                        subtitle: "A useful marriage ritual should feel specific, realistic, and rooted in the kind of care you actually want to practice."
                    )

                    SakinahCard(elevated: true, warm: true) {
                        VStack(alignment: .leading, spacing: SakinahSpacing.base) {
                            SakinahBadge(
                                text: vm.relationshipFocus.shortLabel,
                                icon: "sparkles",
                                color: SakinahColor.accent,
                                tintedBackground: SakinahColor.accentLight
                            )

                            Text(summaryText)
                                .font(SakinahFont.title3)
                                .foregroundStyle(SakinahColor.textPrimary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)

                            Divider()
                                .background(SakinahColor.divider)

                            momentumRow(
                                icon: "lock.shield.fill",
                                title: "Private by design",
                                subtitle: "This setup stays focused on your relationship and does not ask for device permissions."
                            )
                            momentumRow(
                                icon: "timer",
                                title: "Small enough to keep",
                                subtitle: "The first ritual starts with one answer and one realistic next step."
                            )
                            momentumRow(
                                icon: "moon.stars.fill",
                                title: "Faith-aware",
                                subtitle: "Du'a language and Islamic relevance are part of the experience from the beginning."
                            )
                        }
                    }
                }
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.vertical, SakinahSpacing.xl)
            }

            SakinahButton(title: "Add our details") {
                vm.advance(to: .setup, context: modelContext)
            }
            .padding(.horizontal, SakinahSpacing.base)
            .padding(.bottom, SakinahSpacing.base)
        }
    }

    private var summaryText: String {
        "Sakinah will begin around \(vm.relationshipFocus.shortLabel.lowercased()), with attention to \(vm.relationshipFriction.label.lowercased()) and a \(vm.relationshipUrgency.shortLabel.lowercased()) pace."
    }

    private func momentumRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: SakinahSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SakinahColor.primary)
                .frame(width: 30, height: 30)
                .background(SakinahColor.primaryLight)
                .clipShape(.rect(cornerRadius: SakinahRadius.small))

            VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                Text(title)
                    .font(SakinahFont.headline)
                    .foregroundStyle(SakinahColor.textPrimary)
                Text(subtitle)
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SakinahColor.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct StarterPlanPreviewScreen: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(\.modelContext) private var modelContext

    private var plan: StarterPlan {
        vm.starterPlan ?? StarterPlanService.makePlan(
            partnerName: vm.partnerName,
            focus: vm.relationshipFocus,
            urgency: vm.relationshipUrgency,
            friction: vm.relationshipFriction
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressHeader(step: .planPreview) {
                vm.goBack(context: modelContext)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
                    OnboardingIntroText(
                        title: "Here is your first-week ritual",
                        subtitle: "This preview is built from what you selected. Your full ritual continues after the first answer."
                    )

                    SakinahCard(elevated: true) {
                        VStack(alignment: .leading, spacing: SakinahSpacing.base) {
                            SakinahBadge(
                                text: vm.relationshipFocus.shortLabel,
                                icon: "sparkles",
                                color: SakinahColor.accent,
                                tintedBackground: SakinahColor.accentLight
                            )

                            Text(plan.headline)
                                .font(SakinahFont.title3)
                                .foregroundStyle(SakinahColor.textPrimary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(plan.reason)
                                .font(SakinahFont.bodySmall)
                                .foregroundStyle(SakinahColor.textSecondary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)

                            planSection(
                                label: "First prompt",
                                text: plan.firstPrompt,
                                icon: "quote.bubble.fill"
                            )
                            planSection(
                                label: "First-week action",
                                text: plan.firstWeekAction,
                                icon: "calendar.badge.checkmark"
                            )
                            planSection(
                                label: "Full ritual",
                                text: "Sakinah Premium keeps the deeper packs, weekly reflection, du'a flow, and shared private tools open after this first answer.",
                                icon: "lock.open.fill",
                                tint: SakinahColor.accent
                            )
                        }
                    }
                }
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.vertical, SakinahSpacing.xl)
            }

            SakinahButton(title: "Answer the first prompt") {
                vm.advance(to: .firstValue, context: modelContext)
            }
            .padding(.horizontal, SakinahSpacing.base)
            .padding(.bottom, SakinahSpacing.base)
        }
        .task {
            if vm.starterPlan == nil {
                vm.refreshStarterPlan(context: modelContext)
            }
        }
    }

    private func planSection(label: String, text: String, icon: String, tint: Color = SakinahColor.primary) -> some View {
        HStack(alignment: .top, spacing: SakinahSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12))
                .clipShape(.rect(cornerRadius: SakinahRadius.small))

            VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                Text(label)
                    .font(SakinahFont.captionBold)
                    .foregroundStyle(SakinahColor.textSecondary)
                    .textCase(.uppercase)
                Text(text)
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SakinahColor.textPrimary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

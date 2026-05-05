import SwiftUI

struct FirstPromptScreen: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(\.modelContext) private var modelContext
    let onComplete: () -> Void
    @State private var appeared = false
    @FocusState private var focused: Bool

    private var plan: StarterPlan {
        vm.starterPlan ?? StarterPlanService.makePlan(
            partnerName: vm.partnerName,
            focus: vm.relationshipFocus,
            urgency: vm.relationshipUrgency,
            friction: vm.relationshipFriction
        )
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [SakinahColor.background, SakinahColor.accentLight.opacity(0.5)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        HapticEngine.shared.fire(.tap)
                        vm.goBack(context: modelContext)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(SakinahColor.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(SakinahColor.surface)
                            .clipShape(Circle())
                            .sakinahShadow(.subtle)
                    }
                    .pressScale()
                    Spacer()
                }
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.top, SakinahSpacing.sm)

                ScrollView {
                    VStack(spacing: SakinahSpacing.xl) {
                        VStack(spacing: SakinahSpacing.sm) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 34, weight: .regular))
                                .foregroundStyle(SakinahColor.accent)
                                .scaleEffect(appeared ? 1 : 0.85)
                                .opacity(appeared ? 1 : 0)
                            Text("Your first week in Sakinah")
                                .font(SakinahFont.title2)
                                .foregroundStyle(SakinahColor.textPrimary)
                                .multilineTextAlignment(.center)
                            Text("This is the first plan built from what you told us. Save one honest answer, then continue into the full ritual.")
                                .font(SakinahFont.bodySmall)
                                .foregroundStyle(SakinahColor.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, SakinahSpacing.lg)

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

                                VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                                    Text("First question")
                                        .font(SakinahFont.captionBold)
                                        .foregroundStyle(SakinahColor.textSecondary)
                                        .textCase(.uppercase)
                                    Text(plan.firstPrompt)
                                        .font(SakinahFont.body)
                                        .foregroundStyle(SakinahColor.textPrimary)
                                        .lineSpacing(4)
                                }

                                VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                                    Text("What to do next")
                                        .font(SakinahFont.captionBold)
                                        .foregroundStyle(SakinahColor.textSecondary)
                                        .textCase(.uppercase)
                                    Text(plan.firstWeekAction)
                                        .font(SakinahFont.bodySmall)
                                        .foregroundStyle(SakinahColor.textSecondary)
                                    Text(plan.recommendedPackOrLesson)
                                        .font(SakinahFont.bodySmall)
                                        .foregroundStyle(SakinahColor.accent)
                                }

                                ZStack(alignment: .topLeading) {
                                    if vm.firstResponse.isEmpty {
                                        Text("Write the answer you would want to bring into your next calm conversation.")
                                            .font(SakinahFont.body)
                                            .foregroundStyle(SakinahColor.textTertiary)
                                            .padding(.horizontal, SakinahSpacing.sm)
                                            .padding(.top, SakinahSpacing.sm)
                                    }
                                    TextEditor(text: $vm.firstResponse)
                                        .font(SakinahFont.body)
                                        .foregroundStyle(SakinahColor.textPrimary)
                                        .scrollContentBackground(.hidden)
                                        .frame(minHeight: 120)
                                        .focused($focused)
                                }
                                .padding(SakinahSpacing.sm)
                                .background(SakinahColor.backgroundSecondary)
                                .clipShape(.rect(cornerRadius: SakinahRadius.medium))
                            }
                        }
                        .padding(.horizontal, SakinahSpacing.base)
                    }
                    .padding(.bottom, SakinahSpacing.xl)
                }

                VStack(spacing: SakinahSpacing.xs) {
                    SakinahButton(title: "Save my first answer", icon: "checkmark.circle.fill") {
                        HapticEngine.shared.fire(.success)
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(250))
                            onComplete()
                        }
                    }
                    .disabled(!vm.canCompleteFirstValue)
                    .opacity(vm.canCompleteFirstValue ? 1 : 0.55)

                    Text("Next: choose the plan that keeps this ritual open.")
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textTertiary)
                }
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.bottom, SakinahSpacing.base)
            }
        }
        .task {
            if vm.starterPlan == nil {
                vm.refreshStarterPlan(context: modelContext)
            }
        }
        .onAppear {
            withAnimation(SakinahAnimation.bounce.delay(0.1)) { appeared = true }
        }
    }
}

import SwiftUI
import SwiftData

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
            SakinahColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingProgressHeader(step: .firstValue) {
                    vm.goBack(context: modelContext)
                }

                ScrollView {
                    VStack(spacing: SakinahSpacing.xl) {
                        VStack(spacing: SakinahSpacing.sm) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 34, weight: .regular))
                                .foregroundStyle(SakinahColor.accent)
                                .scaleEffect(appeared ? 1 : 0.85)
                                .opacity(appeared ? 1 : 0)
                            Text("Save your first answer")
                                .font(SakinahFont.title2)
                                .foregroundStyle(SakinahColor.textPrimary)
                                .multilineTextAlignment(.center)
                            Text("This is the first meaningful action in your ritual. Keep it honest, brief, and written for the conversation you want to have gently.")
                                .font(SakinahFont.bodySmall)
                                .foregroundStyle(SakinahColor.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, SakinahSpacing.lg)

                        SakinahCard(elevated: true) {
                            VStack(alignment: .leading, spacing: SakinahSpacing.base) {
                                SakinahBadge(
                                    text: "First prompt",
                                    icon: "quote.bubble.fill",
                                    color: SakinahColor.accent,
                                    tintedBackground: SakinahColor.accentLight
                                )
                                Text(plan.firstPrompt)
                                    .font(SakinahFont.title3)
                                    .foregroundStyle(SakinahColor.textPrimary)
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)

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

                                Text("Your full ritual continues after this answer.")
                                    .font(SakinahFont.caption)
                                    .foregroundStyle(SakinahColor.textTertiary)
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

                    Text("Next: continue into the full ritual.")
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

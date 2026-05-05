import SwiftUI

struct PaywallHandoffView: View {
    @Environment(AppState.self) private var appState

    private var starterPlan: StarterPlan? {
        appState.currentStarterPlan
    }

    var body: some View {
        ZStack {
            SakinahColor.background.ignoresSafeArea()

            VStack(spacing: SakinahSpacing.xl) {
                Spacer()

                VStack(spacing: SakinahSpacing.md) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36, weight: .regular))
                        .foregroundStyle(SakinahColor.accent)

                    Text("Your first answer is saved")
                        .font(SakinahFont.title1)
                        .foregroundStyle(SakinahColor.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("You already started the work. The next step simply keeps that private rhythm, your saved answer, and the shared space open.")
                        .font(SakinahFont.body)
                        .foregroundStyle(SakinahColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, SakinahSpacing.base)
                }

                SakinahCard(elevated: true) {
                    VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
                        Text("What unlocks next")
                            .font(SakinahFont.headline)
                            .foregroundStyle(SakinahColor.textPrimary)

                        Text("Daily prompts, guided lessons, and your shared space stay available in the same calm flow you already started.")
                            .font(SakinahFont.bodySmall)
                            .foregroundStyle(SakinahColor.textSecondary)

                        if let starterPlan {
                            Text(starterPlan.firstWeekAction)
                                .font(SakinahFont.bodySmall)
                                .foregroundStyle(SakinahColor.accent)
                        }
                    }
                }
                .padding(.horizontal, SakinahSpacing.base)

                Spacer()

                VStack(spacing: SakinahSpacing.sm) {
                    SakinahButton(title: "Continue to Plans") {
                        appState.advanceToHostedPaywall(entryPoint: .starterPlan)
                    }

                    Text("If you already have access, you can restore it on the next screen.")
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.bottom, SakinahSpacing.base)
            }
        }
    }
}

import SwiftUI

struct PaywallHandoffView: View {
    @Environment(AppState.self) private var appState

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

                    Text("Next is the hosted plan screen. Choose the plan that keeps your private space, daily rituals, and shared history open.")
                        .font(SakinahFont.body)
                        .foregroundStyle(SakinahColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, SakinahSpacing.base)
                }

                SakinahCard(elevated: true) {
                    VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
                        Text("What happens next")
                            .font(SakinahFont.headline)
                            .foregroundStyle(SakinahColor.textPrimary)

                        Text("The plan screen is fully hosted by RevenueCat, so pricing, trials, and restore stay in one dedicated place.")
                            .font(SakinahFont.bodySmall)
                            .foregroundStyle(SakinahColor.textSecondary)

                        Text("After purchase, you’ll return here and can invite your spouse into the shared space.")
                            .font(SakinahFont.bodySmall)
                            .foregroundStyle(SakinahColor.textSecondary)
                    }
                }
                .padding(.horizontal, SakinahSpacing.base)

                Spacer()

                VStack(spacing: SakinahSpacing.sm) {
                    SakinahButton(title: "Continue to Plans") {
                        appState.advanceToHostedPaywall()
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

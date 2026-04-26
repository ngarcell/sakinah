import SwiftUI

struct UpgradePromptView: View {
    let icon: String
    let headline: String
    let message: String
    var ctaTitle: String = "See what's included"
    var onUpgrade: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: SakinahSpacing.base) {
            HStack(spacing: SakinahSpacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: SakinahColor.premiumGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(headline)
                        .font(SakinahFont.headline)
                        .foregroundStyle(SakinahColor.textPrimary)
                    Text(message)
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
            }

            Button {
                HapticEngine.shared.fire(.tap)
                onUpgrade()
            } label: {
                Text(ctaTitle)
                    .font(SakinahFont.captionBold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SakinahSpacing.md)
                    .background(
                        LinearGradient(
                            colors: [SakinahColor.accent, SakinahColor.accentWarm],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(.rect(cornerRadius: SakinahRadius.small))
            }
            .pressScale()
        }
        .padding(SakinahSpacing.base)
        .background(SakinahColor.surface)
        .clipShape(.rect(cornerRadius: SakinahRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: SakinahRadius.large)
                .stroke(
                    LinearGradient(
                        colors: [SakinahColor.accent.opacity(0.3), SakinahColor.accent.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .sakinahShadow(.warmGlow)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .onAppear {
            withAnimation(SakinahAnimation.gentle.delay(0.3)) {
                appeared = true
            }
        }
    }
}

import SwiftUI

struct SakinahEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var secondaryAction: String? = nil
    var onSecondary: (() -> Void)? = nil

    @State private var appeared = false

    var body: some View {
        VStack(spacing: SakinahSpacing.lg) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [SakinahColor.primaryLight, SakinahColor.primaryLight.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)

                Image(systemName: icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(SakinahColor.primary)
                    .scaleEffect(appeared ? 1 : 0.3)
                    .opacity(appeared ? 1 : 0)
            }

            VStack(spacing: SakinahSpacing.sm) {
                Text(title)
                    .font(SakinahFont.title3)
                    .foregroundStyle(SakinahColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)

                Text(message)
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SakinahColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, SakinahSpacing.xl)
                    .opacity(appeared ? 1 : 0)
            }

            VStack(spacing: SakinahSpacing.sm) {
                if let actionTitle, let action {
                    SakinahButton(title: actionTitle, variant: .primary, isFullWidth: false, action: action)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                }
                if let secondaryAction, let onSecondary {
                    Button(secondaryAction) { onSecondary() }
                        .font(SakinahFont.captionBold)
                        .foregroundStyle(SakinahColor.primary)
                        .opacity(appeared ? 1 : 0)
                }
            }
        }
        .padding(SakinahSpacing.xxl)
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }
}

import SwiftUI

struct SakinahEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: SakinahSpacing.base) {
            ZStack {
                Circle()
                    .fill(SakinahColor.primaryLight)
                    .frame(width: 96, height: 96)
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(SakinahColor.primary)
            }
            Text(title)
                .font(SakinahFont.title3)
                .foregroundStyle(SakinahColor.textPrimary)
            Text(message)
                .font(SakinahFont.bodySmall)
                .foregroundStyle(SakinahColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SakinahSpacing.xl)
            if let actionTitle, let action {
                SakinahButton(title: actionTitle, variant: .secondary, isFullWidth: false, action: action)
                    .padding(.top, SakinahSpacing.sm)
            }
        }
        .padding(SakinahSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

import SwiftUI

struct StreakBadge: View {
    let count: Int
    let label: String
    var icon: String = "flame.fill"

    var body: some View {
        HStack(spacing: SakinahSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(count > 0 ? SakinahColor.accent : SakinahColor.textTertiary)
            Text("\(count)")
                .font(SakinahFont.captionBold)
                .foregroundStyle(count > 0 ? SakinahColor.accent : SakinahColor.textTertiary)
            Text(label)
                .font(SakinahFont.caption)
                .foregroundStyle(SakinahColor.textSecondary)
        }
        .padding(.horizontal, SakinahSpacing.md)
        .padding(.vertical, SakinahSpacing.xs)
        .background(
            Capsule()
                .fill(count > 0 ? SakinahColor.accentLight : SakinahColor.backgroundSecondary)
        )
    }
}

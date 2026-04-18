import SwiftUI

struct SakinahBadge: View {
    let text: String
    var icon: String? = nil
    var color: Color = SakinahColor.primary
    var tintedBackground: Color = SakinahColor.primaryLight

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon).font(.system(size: 11, weight: .semibold))
            }
            Text(text)
                .font(SakinahFont.captionBold)
                .tracking(0.3)
                .textCase(.uppercase)
        }
        .foregroundStyle(color)
        .padding(.horizontal, SakinahSpacing.md)
        .padding(.vertical, 6)
        .background(tintedBackground)
        .clipShape(.capsule)
    }
}

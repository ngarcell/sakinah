import SwiftUI

struct SakinahCard<Content: View>: View {
    var elevated: Bool = false
    var accent: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(SakinahSpacing.base)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Group {
                    if accent {
                        SakinahColor.accentLight
                    } else {
                        elevated ? SakinahColor.surfaceElevated : SakinahColor.surface
                    }
                }
            )
            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: SakinahRadius.medium)
                    .stroke(SakinahColor.cardGlow, lineWidth: elevated ? 1 : 0)
            )
            .sakinahShadow(elevated ? .medium : .subtle)
    }
}

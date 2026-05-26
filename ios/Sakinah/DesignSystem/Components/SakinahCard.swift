import SwiftUI

struct SakinahCard<Content: View>: View {
    var elevated: Bool = false
    var accent: Bool = false
    var warm: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(SakinahSpacing.base)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Group {
                    if accent {
                        SakinahColor.accentLight
                    } else if warm {
                        SakinahColor.surfaceWarm
                    } else {
                        elevated ? SakinahColor.surfaceElevated : SakinahColor.surface
                    }
                }
            )
            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: SakinahRadius.medium)
                    .stroke(accent ? SakinahColor.accent.opacity(0.35) : SakinahColor.border.opacity(0.8), lineWidth: 1)
            )
            .sakinahShadow(elevated ? .medium : .subtle)
    }
}

import SwiftUI

struct SakinahCard<Content: View>: View {
    var elevated: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(SakinahSpacing.base)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(elevated ? SakinahColor.surfaceElevated : SakinahColor.surface)
            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
            .sakinahShadow(elevated ? .medium : .subtle)
    }
}

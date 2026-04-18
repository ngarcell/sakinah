import SwiftUI

struct GlowModifier: ViewModifier {
    var color: Color = SakinahColor.primary
    var radius: CGFloat = 20
    var opacity: Double = 0.35

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(opacity * 0.5), radius: radius * 0.5, x: 0, y: 0)
    }
}

extension View {
    func glow(color: Color = SakinahColor.primary, radius: CGFloat = 20, opacity: Double = 0.35) -> some View {
        modifier(GlowModifier(color: color, radius: radius, opacity: opacity))
    }
}

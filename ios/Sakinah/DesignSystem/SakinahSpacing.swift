import SwiftUI

enum SakinahSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let base: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
    static let jumbo: CGFloat = 48
    static let mega: CGFloat = 64
}

enum SakinahRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 999
}

struct SakinahShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    static let subtle = SakinahShadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
    static let medium = SakinahShadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    static let strong = SakinahShadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 8)
    static let glow = SakinahShadow(color: SakinahColor.primary.opacity(0.20), radius: 20, x: 0, y: 0)
    static let warmGlow = SakinahShadow(color: SakinahColor.accent.opacity(0.15), radius: 16, x: 0, y: 4)
}

extension View {
    func sakinahShadow(_ shadow: SakinahShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

enum SakinahAnimation {
    static let spring: Animation = .spring(response: 0.45, dampingFraction: 0.8)
    static let gentle: Animation = .spring(response: 0.6, dampingFraction: 0.85)
    static let bounce: Animation = .spring(response: 0.35, dampingFraction: 0.6)
    static let slow: Animation = .easeInOut(duration: 0.8)
    static let micro: Animation = .spring(response: 0.25, dampingFraction: 0.9)
    static let breathe: Animation = .easeInOut(duration: 3.0).repeatForever(autoreverses: true)
}

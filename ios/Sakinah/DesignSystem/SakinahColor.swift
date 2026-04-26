import SwiftUI

enum SakinahColor {
    // Core brand
    static let primary = Color(light: Color(hex: 0x0D5C63), dark: Color(hex: 0x14919B))
    static let primaryLight = Color(light: Color(hex: 0xE8F5F6), dark: Color(hex: 0x0D3D42))
    static let accent = Color(light: Color(hex: 0xC4923A), dark: Color(hex: 0xD4A84B))
    static let accentLight = Color(light: Color(hex: 0xFFF3E0), dark: Color(hex: 0x3D2E14))
    static let accentWarm = Color(light: Color(hex: 0xE8A84C), dark: Color(hex: 0xF0C060))

    // Surfaces
    static let surface = Color(light: .white, dark: Color(hex: 0x1A1A2E))
    static let surfaceElevated = Color(light: .white, dark: Color(hex: 0x222244))
    static let background = Color(light: Color(hex: 0xFDF6EC), dark: Color(hex: 0x0A0A1A))
    static let backgroundSecondary = Color(light: Color(hex: 0xF5EFE4), dark: Color(hex: 0x141428))

    // Text
    static let textPrimary = Color(light: Color(hex: 0x1A1A2E), dark: Color(hex: 0xF2F0ED))
    static let textSecondary = Color(light: Color(hex: 0x6B7280), dark: Color(hex: 0x9CA3AF))
    static let textTertiary = Color(light: Color(hex: 0x9CA3AF), dark: Color(hex: 0x6B7280))

    // Semantic
    static let success = Color(light: Color(hex: 0x2D8A4E), dark: Color(hex: 0x34D399))
    static let warning = Color(light: Color(hex: 0xD97706), dark: Color(hex: 0xFBBF24))
    static let error = Color(light: Color(hex: 0xDC2626), dark: Color(hex: 0xF87171))
    static let divider = Color(light: Color(hex: 0xE5E7EB).opacity(0.6), dark: Color(hex: 0x374151).opacity(0.6))

    // Signature gradients
    static let heroGradient: [Color] = [Color(hex: 0x0D5C63), Color(hex: 0x14919B), Color(hex: 0xC4923A).opacity(0.3)]
    static let premiumGradient: [Color] = [Color(hex: 0xC4923A), Color(hex: 0xE8A84C), Color(hex: 0xF4D9A0)]
    static let cardGlow = Color(light: Color(hex: 0x0D5C63).opacity(0.06), dark: Color(hex: 0x14919B).opacity(0.08))
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

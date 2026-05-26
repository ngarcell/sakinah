import SwiftUI

enum SakinahColor {
    // Core brand
    static let primary = Color(light: Color(hex: 0x2C5F4A), dark: Color(hex: 0x7CB397))
    static let primaryPressed = Color(light: Color(hex: 0x3D7A61), dark: Color(hex: 0x95C8AE))
    static let primaryLight = Color(light: Color(hex: 0xEAF1ED), dark: Color(hex: 0x1C2D25))
    static let accent = Color(light: Color(hex: 0xB8965A), dark: Color(hex: 0xD4B07A))
    static let accentLight = Color(light: Color(hex: 0xF5EFE3), dark: Color(hex: 0x322A1F))
    static let accentWarm = Color(light: Color(hex: 0xD4B07A), dark: Color(hex: 0xE1C18D))
    static let rose = Color(light: Color(hex: 0xC4806A), dark: Color(hex: 0xD89B86))
    static let roseLight = Color(light: Color(hex: 0xF7EDEA), dark: Color(hex: 0x35231F))

    // Surfaces
    static let surface = Color(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x191713))
    static let surfaceElevated = Color(light: Color(hex: 0xFCFAF6), dark: Color(hex: 0x211F1A))
    static let surfaceWarm = Color(light: Color(hex: 0xFBF7EF), dark: Color(hex: 0x242018))
    static let background = Color(light: Color(hex: 0xF7F4EF), dark: Color(hex: 0x100F0D))
    static let backgroundSecondary = Color(light: Color(hex: 0xEFE9DF), dark: Color(hex: 0x1C1A16))

    // Text
    static let textPrimary = Color(light: Color(hex: 0x1C1710), dark: Color(hex: 0xF0EDE6))
    static let textSecondary = Color(light: Color(hex: 0x6B6355), dark: Color(hex: 0x9A9080))
    static let textTertiary = Color(light: Color(hex: 0xA09080), dark: Color(hex: 0x5A5448))

    // Semantic
    static let success = Color(light: Color(hex: 0x3A7D5C), dark: Color(hex: 0x70B48D))
    static let warning = Color(light: Color(hex: 0xB8965A), dark: Color(hex: 0xD4B07A))
    static let error = Color(light: Color(hex: 0xC0524A), dark: Color(hex: 0xE1847D))
    static let info = Color(light: Color(hex: 0x4A7FA5), dark: Color(hex: 0x82AFCF))
    static let divider = Color(light: Color(hex: 0xE8E4DC), dark: Color(hex: 0x2A2822))
    static let border = Color(light: Color(hex: 0xDDD8CE), dark: Color(hex: 0x333128))

    // Signature gradients
    static let heroGradient: [Color] = [Color(hex: 0x2C5F4A), Color(hex: 0x3D7A61)]
    static let premiumGradient: [Color] = [Color(hex: 0xB8965A), Color(hex: 0xD4B07A)]
    static let cardGlow = Color(light: Color(hex: 0x2C5F4A).opacity(0.06), dark: Color(hex: 0x7CB397).opacity(0.10))
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

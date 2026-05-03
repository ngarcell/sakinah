import SwiftUI

enum SakinahColor {
    // Core brand
    static let primary = Color(light: Color(hex: 0x0F6266), dark: Color(hex: 0x54B6AF))
    static let primaryLight = Color(light: Color(hex: 0xE4F1F0), dark: Color(hex: 0x183231))
    static let accent = Color(light: Color(hex: 0xB9893B), dark: Color(hex: 0xD8B06A))
    static let accentLight = Color(light: Color(hex: 0xF7EBD8), dark: Color(hex: 0x392A18))
    static let accentWarm = Color(light: Color(hex: 0xD6A25A), dark: Color(hex: 0xE2BF86))

    // Surfaces
    static let surface = Color(light: Color(hex: 0xFEFBF6), dark: Color(hex: 0x16201E))
    static let surfaceElevated = Color(light: .white, dark: Color(hex: 0x1D2927))
    static let background = Color(light: Color(hex: 0xF6F1E8), dark: Color(hex: 0x0E1514))
    static let backgroundSecondary = Color(light: Color(hex: 0xEEE6D9), dark: Color(hex: 0x131D1C))

    // Text
    static let textPrimary = Color(light: Color(hex: 0x16211F), dark: Color(hex: 0xF1ECE4))
    static let textSecondary = Color(light: Color(hex: 0x5F6C68), dark: Color(hex: 0xA9B2AD))
    static let textTertiary = Color(light: Color(hex: 0x8A928F), dark: Color(hex: 0x7A8580))

    // Semantic
    static let success = Color(light: Color(hex: 0x387E58), dark: Color(hex: 0x5FBC8C))
    static let warning = Color(light: Color(hex: 0xB9771A), dark: Color(hex: 0xD7A44E))
    static let error = Color(light: Color(hex: 0xBE4B42), dark: Color(hex: 0xDE8178))
    static let divider = Color(light: Color(hex: 0xD6D0C7).opacity(0.65), dark: Color(hex: 0x2B3634).opacity(0.7))

    // Signature gradients
    static let heroGradient: [Color] = [Color(hex: 0x0F6266), Color(hex: 0x327D7E), Color(hex: 0xCFB07C).opacity(0.35)]
    static let premiumGradient: [Color] = [Color(hex: 0xB9893B), Color(hex: 0xD7A45D), Color(hex: 0xF0DDAB)]
    static let cardGlow = Color(light: Color(hex: 0x0F6266).opacity(0.05), dark: Color(hex: 0x54B6AF).opacity(0.08))
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

import SwiftUI

enum SakinahFont {
    // Signature
    static let display = Font.system(size: 38, weight: .bold, design: .serif)
    static let heroTitle = Font.system(size: 34, weight: .bold, design: .serif)

    // Hierarchy
    static let title1 = Font.system(size: 28, weight: .bold, design: .serif)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .serif)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .serif)
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 15, weight: .regular, design: .default)
    static let caption = Font.system(size: 13, weight: .regular, design: .default)
    static let captionBold = Font.system(size: 13, weight: .semibold, design: .default)
    static let micro = Font.system(size: 11, weight: .medium, design: .default)

    // Arabic
    static let arabic = Font.system(size: 24, weight: .regular, design: .serif)
    static let arabicSmall = Font.system(size: 18, weight: .regular, design: .serif)

    // Mono (for codes, counts)
    static let mono = Font.system(size: 15, weight: .medium, design: .monospaced)
}

extension Text {
    func sakinahStyle(_ font: Font, color: Color = SakinahColor.textPrimary, tracking: CGFloat = 0) -> some View {
        self.font(font).foregroundStyle(color).tracking(tracking)
    }
}

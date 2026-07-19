import SwiftUI

enum TrueMaxBrand {
    static let name = "TrueMax"
    static let onboardingVersion = 1
    static let analysisVersion = "vision-landmarks-1.0"
    static let validationVersion = "cosmetic-guidance-1.0"

    static let privacyURL = URL(string: "https://socialreporthq.com/sakinah/privacy")!
    static let termsURL = URL(string: "https://socialreporthq.com/sakinah/terms")!
    static let supportURL = URL(string: "https://socialreporthq.com/sakinah/support")!
    static let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
}

enum TrueMaxPalette {
    static let background = adaptive(light: 0xFAFAF9, dark: 0x050609)
    static let backgroundRaised = adaptive(light: 0xF0EFEC, dark: 0x0B0D12)
    static let card = adaptive(light: 0xFFFFFF, dark: 0x15171C)
    static let cardRaised = adaptive(light: 0xFFFFFF, dark: 0x1A1D23)
    static let textPrimary = adaptive(light: 0x1C1C1E, dark: 0xF5F5F4)
    static let textSecondary = adaptive(light: 0x4F5158, dark: 0xA5A7AF)
    static let textTertiary = adaptive(light: 0x62636A, dark: 0x777A84)

    // The light variants are deliberately deeper so semantic text and controls
    // remain legible on pale surfaces. Dark-mode values preserve the original UI.
    static let accent = adaptive(light: 0x175CD3, dark: 0x397DF8)
    static let accentLight = adaptive(light: 0x1454B8, dark: 0x5B98FF)
    static let accentPressed = adaptive(light: 0x10479F, dark: 0x2A62CE)
    static let positive = adaptive(light: 0x16783B, dark: 0x4FCB71)
    static let neutral = adaptive(light: 0x765A00, dark: 0xE7B83E)
    static let caution = adaptive(light: 0xC62831, dark: 0xEB3E47)
    static let border = adaptive(light: 0x8A8B91, dark: 0x30333A)

    static let primaryGradient = LinearGradient(
        colors: [accentLight, accent],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// A darker action gradient keeps white button labels readable in both
    /// appearances. `primaryGradient` remains available for decorative marks.
    static let actionGradient = LinearGradient(
        colors: [
            adaptive(light: 0x175CD3, dark: 0x397DF8),
            adaptive(light: 0x10479F, dark: 0x2A62CE),
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    private static func adaptive(light: UInt, dark: UInt) -> Color {
        Color(
            uiColor: UIColor { traits in
                UIColor(
                    hex: traits.userInterfaceStyle == .dark ? dark : light
                )
            }
        )
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

private extension UIColor {
    convenience init(hex: UInt) {
        self.init(
            red: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: 1
        )
    }
}

struct TrueMaxCardModifier: ViewModifier {
    var elevated = false

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                elevated ? TrueMaxPalette.cardRaised : TrueMaxPalette.card,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(TrueMaxPalette.border, lineWidth: 1)
            }
    }
}

extension View {
    func trueMaxCard(elevated: Bool = false) -> some View {
        modifier(TrueMaxCardModifier(elevated: elevated))
    }

    func trueMaxContentWidth() -> some View {
        frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
    }
}

struct TrueMaxPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(Color.white)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background(
                configuration.isPressed
                    ? AnyShapeStyle(TrueMaxPalette.accentPressed)
                    : AnyShapeStyle(TrueMaxPalette.actionGradient),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .opacity(isEnabled ? 1 : 0.42)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct TrueMaxSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(TrueMaxPalette.textPrimary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(
                TrueMaxPalette.card.opacity(configuration.isPressed ? 0.7 : 1),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(TrueMaxPalette.border, lineWidth: 1)
            }
    }
}

struct TrueMaxBrandLockup: View {
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 8 : 12) {
            TrueMaxMark()
                .frame(width: compact ? 36 : 46, height: compact ? 36 : 46)

            HStack(spacing: 0) {
                Text("True")
                    .foregroundStyle(TrueMaxPalette.textPrimary)
                Text("Max")
                    .foregroundStyle(TrueMaxPalette.accentLight)
            }
        }
        .font(compact ? .title.weight(.bold) : .largeTitle.weight(.bold))
        .fontDesign(.rounded)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("TrueMax")
    }
}

struct TrueMaxMark: View {
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: size * 0.08, y: size * 0.28))
                    path.addLine(to: CGPoint(x: size * 0.40, y: size * 0.08))
                    path.addLine(to: CGPoint(x: size * 0.40, y: size * 0.72))
                    path.addLine(to: CGPoint(x: size * 0.50, y: size * 0.92))
                    path.addLine(to: CGPoint(x: size * 0.60, y: size * 0.72))
                    path.addLine(to: CGPoint(x: size * 0.60, y: size * 0.08))
                    path.addLine(to: CGPoint(x: size * 0.92, y: size * 0.28))
                    path.addLine(to: CGPoint(x: size * 0.92, y: size * 0.48))
                    path.addLine(to: CGPoint(x: size * 0.66, y: size * 0.34))
                    path.addLine(to: CGPoint(x: size * 0.66, y: size * 0.76))
                    path.addLine(to: CGPoint(x: size * 0.50, y: size))
                    path.addLine(to: CGPoint(x: size * 0.34, y: size * 0.76))
                    path.addLine(to: CGPoint(x: size * 0.34, y: size * 0.34))
                    path.addLine(to: CGPoint(x: size * 0.08, y: size * 0.48))
                    path.closeSubpath()
                }
                .fill(TrueMaxPalette.primaryGradient)
            }
        }
        .accessibilityHidden(true)
    }
}

struct FaceMeshIllustration: View {
    var mode: CaptureMode = .depth3D
    var lineColor: Color = TrueMaxPalette.accentLight

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(
                x: size.width * 0.20,
                y: size.height * 0.08,
                width: size.width * 0.60,
                height: size.height * 0.76
            )

            context.stroke(
                Path(ellipseIn: rect),
                with: .color(lineColor.opacity(0.88)),
                lineWidth: 1.4
            )

            for index in 1...7 {
                let inset = CGFloat(index) * rect.width * 0.035
                var vertical = Path()
                vertical.move(to: CGPoint(x: rect.midX, y: rect.minY + inset))
                vertical.addCurve(
                    to: CGPoint(x: rect.midX, y: rect.maxY - inset),
                    control1: CGPoint(x: rect.midX - rect.width * 0.32 + inset, y: rect.midY),
                    control2: CGPoint(x: rect.midX + rect.width * 0.32 - inset, y: rect.midY)
                )
                context.stroke(vertical, with: .color(lineColor.opacity(0.32)), lineWidth: 0.65)
            }

            for fraction in stride(from: 0.18, through: 0.82, by: 0.105) {
                let y = rect.minY + rect.height * fraction
                let inset = abs(fraction - 0.5) * rect.width * 0.24
                var horizontal = Path()
                horizontal.move(to: CGPoint(x: rect.minX + inset, y: y))
                horizontal.addCurve(
                    to: CGPoint(x: rect.maxX - inset, y: y),
                    control1: CGPoint(x: rect.midX - rect.width * 0.18, y: y + 8),
                    control2: CGPoint(x: rect.midX + rect.width * 0.18, y: y + 8)
                )
                context.stroke(horizontal, with: .color(lineColor.opacity(0.38)), lineWidth: 0.7)
            }

            var features = Path()
            features.move(to: CGPoint(x: rect.midX - rect.width * 0.22, y: rect.midY - 18))
            features.addQuadCurve(
                to: CGPoint(x: rect.midX - rect.width * 0.04, y: rect.midY - 18),
                control: CGPoint(x: rect.midX - rect.width * 0.13, y: rect.midY - 30)
            )
            features.move(to: CGPoint(x: rect.midX + rect.width * 0.04, y: rect.midY - 18))
            features.addQuadCurve(
                to: CGPoint(x: rect.midX + rect.width * 0.22, y: rect.midY - 18),
                control: CGPoint(x: rect.midX + rect.width * 0.13, y: rect.midY - 30)
            )
            features.move(to: CGPoint(x: rect.midX, y: rect.midY - 10))
            features.addLine(to: CGPoint(x: rect.midX - 5, y: rect.midY + 42))
            features.addLine(to: CGPoint(x: rect.midX + 8, y: rect.midY + 42))
            features.move(to: CGPoint(x: rect.midX - rect.width * 0.13, y: rect.midY + 78))
            features.addQuadCurve(
                to: CGPoint(x: rect.midX + rect.width * 0.13, y: rect.midY + 78),
                control: CGPoint(x: rect.midX, y: rect.midY + 91)
            )
            context.stroke(features, with: .color(lineColor.opacity(0.82)), lineWidth: 1.2)

            if mode == .depth3D {
                for x in stride(from: rect.minX + 10, through: rect.maxX - 10, by: 20) {
                    for y in stride(from: rect.minY + 18, through: rect.maxY - 18, by: 22) {
                        let point = CGPoint(x: x, y: y)
                        if rect.contains(point) {
                            context.fill(
                                Path(ellipseIn: CGRect(x: x - 1.2, y: y - 1.2, width: 2.4, height: 2.4)),
                                with: .color(lineColor.opacity(0.7))
                            )
                        }
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

import SwiftUI

struct GeometricPattern: View {
    @State private var rotation1: Double = 0
    @State private var rotation2: Double = 0
    @State private var pulse: CGFloat = 1

    var body: some View {
        ZStack {
            // Outer 8-point star
            IslamicStar(points: 8)
                .stroke(SakinahColor.primary.opacity(0.25), lineWidth: 1.2)
                .frame(width: 320, height: 320)
                .rotationEffect(.degrees(rotation1))

            // Inner interlocking 8-point star
            IslamicStar(points: 8)
                .stroke(SakinahColor.accent.opacity(0.35), lineWidth: 1)
                .frame(width: 240, height: 240)
                .rotationEffect(.degrees(-rotation1 * 0.6 + 22.5))

            // Small star
            IslamicStar(points: 6)
                .stroke(SakinahColor.primary.opacity(0.2), lineWidth: 1)
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(rotation2))

            Circle()
                .fill(
                    RadialGradient(
                        colors: [SakinahColor.accent.opacity(0.3), .clear],
                        center: .center, startRadius: 0, endRadius: 80
                    )
                )
                .frame(width: 180, height: 180)
                .scaleEffect(pulse)
        }
        .onAppear {
            withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) { rotation1 = 360 }
            withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) { rotation2 = -360 }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) { pulse = 1.15 }
        }
    }
}

struct IslamicStar: Shape {
    let points: Int
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.55
        let total = points * 2
        for i in 0..<total {
            let angle = (CGFloat(i) / CGFloat(total)) * .pi * 2 - .pi / 2
            let r = i.isMultiple(of: 2) ? outer : inner
            let p = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}

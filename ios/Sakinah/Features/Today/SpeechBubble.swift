import SwiftUI

struct SpeechBubble: Shape {
    var tailOnRight: Bool = true

    func path(in rect: CGRect) -> Path {
        let tailSize: CGFloat = 8
        let cornerRadius: CGFloat = SakinahRadius.medium
        var path = Path()

        let bodyRect = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: rect.height - tailSize
        )

        path.addRoundedRect(in: bodyRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))

        let tailX: CGFloat = tailOnRight
            ? bodyRect.maxX - 24
            : bodyRect.minX + 24
        let tailMid = tailX + (tailOnRight ? 6 : -6)

        path.move(to: CGPoint(x: tailX - 6, y: bodyRect.maxY))
        path.addLine(to: CGPoint(x: tailMid, y: bodyRect.maxY + tailSize))
        path.addLine(to: CGPoint(x: tailX + 6, y: bodyRect.maxY))
        path.closeSubpath()

        return path
    }
}

struct SpeechBubbleView<Content: View>: View {
    var tailOnRight: Bool = true
    var backgroundColor: Color = SakinahColor.primaryLight
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, SakinahSpacing.base)
            .padding(.top, SakinahSpacing.md)
            .padding(.bottom, SakinahSpacing.lg)
            .background(
                SpeechBubble(tailOnRight: tailOnRight)
                    .fill(backgroundColor)
            )
    }
}

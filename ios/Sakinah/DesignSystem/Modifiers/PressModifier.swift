import SwiftUI

struct PressScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

extension View {
    func pressScale(_ scale: CGFloat = 0.97) -> some View {
        self.buttonStyle(PressScaleStyle(scale: scale))
    }
}

import SwiftUI

struct SakinahLoadingView: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1
    var label: String? = nil

    var body: some View {
        VStack(spacing: SakinahSpacing.base) {
            ZStack {
                Circle()
                    .stroke(SakinahColor.primaryLight, lineWidth: 3)
                    .frame(width: 48, height: 48)
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(SakinahColor.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(rotation))
                Circle()
                    .fill(SakinahColor.accent)
                    .frame(width: 6, height: 6)
                    .scaleEffect(scale)
            }
            if let label {
                Text(label)
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SakinahColor.textSecondary)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                scale = 1.6
            }
        }
    }
}

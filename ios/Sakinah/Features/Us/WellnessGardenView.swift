import SwiftUI

struct WellnessGardenView: View {
    let gardenState: GardenState
    var onPlantTapped: ((GardenDimension) -> Void)? = nil

    @State private var breezeActive = false
    @State private var time: Double = 0

    private let dimensions = GardenDimension.allCases
    private let swayPeriods: [Double] = [1.3, 0.9, 1.1, 0.7, 1.5] // Different periods for each plant

    var body: some View {
        VStack(spacing: SakinahSpacing.sm) {
            gardenCanvas
                .frame(height: 220)
                .clipShape(.rect(cornerRadius: SakinahRadius.large))
                .sakinahShadow(.subtle)

            // Legend
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SakinahSpacing.md) {
                    ForEach(dimensions, id: \.self) { dim in
                        legendItem(dim)
                    }
                }
                .padding(.horizontal, SakinahSpacing.sm)
            }
        }
    }

    private var gardenCanvas: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let currentTime = timeline.date.timeIntervalSinceReferenceDate

                // Sky gradient
                let skyGradient = Gradient(colors: [
                    SakinahColor.background,
                    SakinahColor.primaryLight.opacity(0.05)
                ])
                context.fill(
                    Rectangle().path(in: CGRect(origin: .zero, size: size)),
                    with: .linearGradient(skyGradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height * 0.75))
                )

                // Ground gradient
                let groundY = size.height * 0.75
                let groundRect = CGRect(x: 0, y: groundY, width: size.width, height: size.height - groundY)
                let groundGradient = Gradient(colors: [
                    SakinahColor.primaryLight.opacity(0.4),
                    Color(hex: 0x2D8A4E).opacity(0.15)
                ])
                context.fill(
                    Rectangle().path(in: groundRect),
                    with: .linearGradient(groundGradient, startPoint: CGPoint(x: 0, y: groundY), endPoint: CGPoint(x: 0, y: size.height))
                )

                // Ground line
                var groundLine = Path()
                groundLine.move(to: CGPoint(x: 0, y: groundY))
                for x in stride(from: CGFloat(0), to: size.width, by: 4) {
                    let waveY = groundY + sin(x * 0.02 + currentTime * 0.5) * 2
                    groundLine.addLine(to: CGPoint(x: x, y: waveY))
                }
                context.stroke(groundLine, with: .color(SakinahColor.primary.opacity(0.1)), lineWidth: 1)

                // Plants
                let plantSpacing = size.width / CGFloat(dimensions.count + 1)
                for (i, dim) in dimensions.enumerated() {
                    let x = plantSpacing * CGFloat(i + 1)
                    let level = gardenState.level(for: dim)

                    GardenPlantRenderer.drawPlant(
                        in: context,
                        dimension: dim,
                        level: level,
                        at: CGPoint(x: x, y: 0),
                        groundY: groundY,
                        time: currentTime,
                        swayPhase: swayPeriods[i],
                        breezeActive: breezeActive
                    )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        handleTap(at: value.location)
                    }
            )
        }
        .task {
            // Breeze effect every ~15 seconds
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 12...18)))
                breezeActive = true
                try? await Task.sleep(for: .seconds(2))
                breezeActive = false
            }
        }
    }

    private func handleTap(at location: CGPoint) {
        // Determine which plant was tapped based on x position
        let totalWidth: CGFloat = 300 // approximate
        let plantSpacing = totalWidth / CGFloat(dimensions.count + 1)

        for (i, dim) in dimensions.enumerated() {
            let plantX = plantSpacing * CGFloat(i + 1)
            if abs(location.x - plantX) < plantSpacing * 0.4 {
                HapticEngine.shared.fire(.tap)
                onPlantTapped?(dim)
                return
            }
        }
    }

    private func legendItem(_ dim: GardenDimension) -> some View {
        HStack(spacing: 4) {
            Text(dim.plantEmoji)
                .font(.system(size: 12))
            Text(dim.label)
                .font(SakinahFont.caption)
                .foregroundStyle(SakinahColor.textTertiary)
        }
    }
}

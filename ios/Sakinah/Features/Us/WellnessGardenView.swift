import SwiftUI

struct WellnessGardenView: View {
    let gardenState: GardenState
    var onPlantTapped: ((GardenDimension) -> Void)? = nil

    @State private var breezeActive = false

    private let dimensions = GardenDimension.allCases
    private let swayPeriods: [Double] = [1.3, 0.9, 1.1, 0.7, 1.5]

    var body: some View {
        SakinahCard(warm: true) {
            VStack(alignment: .leading, spacing: SakinahSpacing.md) {
                Text("YOUR GARDEN")
                    .font(SakinahFont.captionBold)
                    .tracking(0.4)
                    .foregroundStyle(SakinahColor.textSecondary)

                gardenCanvas
                    .frame(height: 188)
                    .clipShape(.rect(cornerRadius: SakinahRadius.medium))

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: SakinahSpacing.sm), count: 3),
                    spacing: SakinahSpacing.sm
                ) {
                    ForEach(dimensions, id: \.self) { dimension in
                        legendItem(dimension)
                    }
                }

                Text("Tap a plant to tend to it")
                    .font(SakinahFont.caption)
                    .foregroundStyle(SakinahColor.textTertiary)
            }
            .frame(minHeight: 280, alignment: .top)
        }
    }

    private var gardenCanvas: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                Canvas { context, size in
                    let currentTime = timeline.date.timeIntervalSinceReferenceDate
                    let groundY = size.height * 0.78

                    context.fill(
                        Rectangle().path(in: CGRect(origin: .zero, size: size)),
                        with: .linearGradient(
                            Gradient(colors: [
                                SakinahColor.background,
                                SakinahColor.primaryLight.opacity(0.65)
                            ]),
                            startPoint: .zero,
                            endPoint: CGPoint(x: 0, y: size.height)
                        )
                    )

                    let groundRect = CGRect(x: 0, y: groundY, width: size.width, height: size.height - groundY)
                    context.fill(
                        Rectangle().path(in: groundRect),
                        with: .color(SakinahColor.primary.opacity(0.08))
                    )

                    let spacing = size.width / CGFloat(dimensions.count + 1)
                    for (index, dimension) in dimensions.enumerated() {
                        let x = spacing * CGFloat(index + 1)
                        GardenPlantRenderer.drawPlant(
                            in: context,
                            dimension: dimension,
                            level: gardenState.level(for: dimension),
                            at: CGPoint(x: x, y: 0),
                            groundY: groundY,
                            time: currentTime,
                            swayPhase: swayPeriods[min(index, swayPeriods.count - 1)],
                            breezeActive: breezeActive
                        )
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            handleTap(at: value.location, width: geometry.size.width)
                        }
                )
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 12...18)))
                breezeActive = true
                try? await Task.sleep(for: .seconds(2))
                breezeActive = false
            }
        }
    }

    private func handleTap(at location: CGPoint, width: CGFloat) {
        let plantSpacing = width / CGFloat(dimensions.count + 1)

        for (index, dimension) in dimensions.enumerated() {
            let plantX = plantSpacing * CGFloat(index + 1)
            if abs(location.x - plantX) < plantSpacing * 0.45 {
                HapticEngine.shared.fire(.tap)
                onPlantTapped?(dimension)
                return
            }
        }
    }

    private func legendItem(_ dimension: GardenDimension) -> some View {
        HStack(spacing: SakinahSpacing.xs) {
            Image(systemName: dimension.icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(SakinahColor.primary)
            Text(dimension.label)
                .font(SakinahFont.caption)
                .foregroundStyle(SakinahColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }
}

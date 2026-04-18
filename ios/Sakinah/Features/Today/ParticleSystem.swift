import SwiftUI

struct ParticleSystem: View {
    let isActive: Bool
    let color: Color
    let particleCount: Int

    @State private var particles: [Particle] = []
    @State private var animationProgress: Double = 0

    struct Particle: Identifiable {
        let id = UUID()
        let angle: Double
        let distance: CGFloat
        let size: CGFloat
        let delay: Double
    }

    init(isActive: Bool, color: Color = SakinahColor.accent, particleCount: Int = 14) {
        self.isActive = isActive
        self.color = color
        self.particleCount = particleCount
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isActive)) { timeline in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let time = timeline.date.timeIntervalSinceReferenceDate

                for particle in particles {
                    let progress = min(1.0, max(0, animationProgress - particle.delay))
                    guard progress > 0 else { continue }

                    let eased = 1 - pow(1 - progress, 3)
                    let dist = particle.distance * eased
                    let alpha = max(0, 1 - eased)
                    let scale = particle.size * (0.5 + 0.5 * (1 - eased))

                    let x = center.x + cos(particle.angle) * dist
                    let y = center.y + sin(particle.angle) * dist

                    let rect = CGRect(
                        x: x - scale / 2,
                        y: y - scale / 2,
                        width: scale,
                        height: scale
                    )
                    context.opacity = alpha
                    context.fill(Circle().path(in: rect), with: .color(color))
                }
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                generateParticles()
                withAnimation(.easeOut(duration: 1.2)) {
                    animationProgress = 1.0
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.5))
                    animationProgress = 0
                    particles = []
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func generateParticles() {
        particles = (0..<particleCount).map { i in
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 60...140)
            let size = CGFloat.random(in: 4...8)
            let delay = Double(i) * 0.02
            return Particle(angle: angle, distance: distance, size: size, delay: delay)
        }
    }
}

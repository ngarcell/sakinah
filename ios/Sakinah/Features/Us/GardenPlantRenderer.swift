import SwiftUI

struct GardenPlantRenderer {

    // MARK: - Main Draw

    static func drawPlant(
        in context: GraphicsContext,
        dimension: GardenDimension,
        level: Double,
        at position: CGPoint,
        groundY: CGFloat,
        time: Double,
        swayPhase: Double,
        breezeActive: Bool
    ) {
        let clampedLevel = max(1, min(5, level))
        let swayAmount: CGFloat = breezeActive ? 4 : 2
        let sway = sin(time * swayPhase) * swayAmount

        switch dimension {
        case .communication:
            drawFlower(context: context, level: clampedLevel, position: position, groundY: groundY, sway: sway, time: time)
        case .qualityTime:
            drawBush(context: context, level: clampedLevel, position: position, groundY: groundY, sway: sway, time: time)
        case .spiritualConnection:
            drawStarFlower(context: context, level: clampedLevel, position: position, groundY: groundY, sway: sway, time: time)
        case .emotionalSafety:
            drawBlossom(context: context, level: clampedLevel, position: position, groundY: groundY, sway: sway, time: time)
        case .growth:
            drawTree(context: context, level: clampedLevel, position: position, groundY: groundY, sway: sway, time: time)
        }
    }

    // MARK: - Communication: Flower

    private static func drawFlower(context: GraphicsContext, level: Double, position: CGPoint, groundY: CGFloat, sway: CGFloat, time: Double) {
        let height = CGFloat(12 + level * 14)
        let opacity = 0.4 + level * 0.12
        let stemColor = Color.green.opacity(opacity)
        let petalColor = Color(hex: 0x0D5C63).opacity(opacity)

        // Stem
        var stemPath = Path()
        let stemBase = CGPoint(x: position.x + sway * 0.3, y: groundY)
        let stemTop = CGPoint(x: position.x + sway, y: groundY - height)
        stemPath.move(to: stemBase)
        stemPath.addQuadCurve(to: stemTop, control: CGPoint(x: position.x + sway * 0.7, y: groundY - height * 0.5))
        context.stroke(stemPath, with: .color(stemColor), lineWidth: max(1.5, CGFloat(level) * 0.5))

        // Petals (only level 3+)
        if level >= 3 {
            let petalCount = Int(min(6, level + 1))
            let petalSize = CGFloat(3 + level * 1.5)
            for i in 0..<petalCount {
                let angle = (Double(i) / Double(petalCount)) * 2 * .pi
                let px = stemTop.x + cos(angle) * petalSize
                let py = stemTop.y + sin(angle) * petalSize
                let petalRect = CGRect(x: px - petalSize/2, y: py - petalSize/2, width: petalSize, height: petalSize)
                context.fill(Ellipse().path(in: petalRect), with: .color(petalColor))
            }
            // Center
            let centerSize = petalSize * 0.5
            let centerRect = CGRect(x: stemTop.x - centerSize/2, y: stemTop.y - centerSize/2, width: centerSize, height: centerSize)
            context.fill(Circle().path(in: centerRect), with: .color(Color(hex: 0xC4923A).opacity(opacity)))
        }

        // Leaves (level 2+)
        if level >= 2 {
            let leafY = groundY - height * 0.5
            let leafSize: CGFloat = CGFloat(4 + level)
            var leaf = Path()
            leaf.addEllipse(in: CGRect(x: position.x + sway * 0.5 - leafSize, y: leafY - leafSize/2, width: leafSize, height: leafSize * 0.5))
            context.fill(leaf, with: .color(stemColor))
        }

        // Sparkle (level 5)
        if level >= 4.5 {
            drawSparkle(context: context, at: stemTop, time: time)
        }
    }

    // MARK: - Quality Time: Bush

    private static func drawBush(context: GraphicsContext, level: Double, position: CGPoint, groundY: CGFloat, sway: CGFloat, time: Double) {
        let width = CGFloat(10 + level * 8)
        let height = CGFloat(8 + level * 10)
        let opacity = 0.4 + level * 0.12
        let bushColor = Color(hex: 0x2D8A4E).opacity(opacity)

        // Layers of ellipses
        let layers = Int(max(1, level))
        for i in 0..<layers {
            let layerH = height * (1 - Double(i) * 0.15)
            let layerW = width * (1 - Double(i) * 0.1)
            let y = groundY - CGFloat(i) * (height / CGFloat(layers)) * 0.5
            let rect = CGRect(
                x: position.x + sway * CGFloat(1 + Double(i) * 0.3) - layerW / 2,
                y: y - layerH,
                width: layerW,
                height: layerH
            )
            context.fill(Ellipse().path(in: rect), with: .color(bushColor.opacity(1 - Double(i) * 0.15)))
        }

        if level >= 4.5 {
            drawSparkle(context: context, at: CGPoint(x: position.x + sway, y: groundY - height * 0.7), time: time)
        }
    }

    // MARK: - Spiritual: Star Flower

    private static func drawStarFlower(context: GraphicsContext, level: Double, position: CGPoint, groundY: CGFloat, sway: CGFloat, time: Double) {
        let height = CGFloat(12 + level * 12)
        let opacity = 0.4 + level * 0.12
        let starColor = Color(hex: 0xC4923A).opacity(opacity)

        // Stem
        var stemPath = Path()
        let stemBase = CGPoint(x: position.x + sway * 0.3, y: groundY)
        let stemTop = CGPoint(x: position.x + sway, y: groundY - height)
        stemPath.move(to: stemBase)
        stemPath.addLine(to: stemTop)
        context.stroke(stemPath, with: .color(Color.green.opacity(opacity)), lineWidth: 1.5)

        // Star (level 3+)
        if level >= 3 {
            let starSize = CGFloat(4 + level * 2)
            let points = 5
            var starPath = Path()
            for i in 0..<(points * 2) {
                let angle = (Double(i) / Double(points * 2)) * 2 * .pi - .pi / 2
                let radius = i.isMultiple(of: 2) ? starSize : starSize * 0.4
                let x = stemTop.x + cos(angle) * radius
                let y = stemTop.y + sin(angle) * radius
                if i == 0 { starPath.move(to: CGPoint(x: x, y: y)) }
                else { starPath.addLine(to: CGPoint(x: x, y: y)) }
            }
            starPath.closeSubpath()
            context.fill(starPath, with: .color(starColor))
        } else {
            // Small bud
            let budSize = CGFloat(3 + level * 1.5)
            let budRect = CGRect(x: stemTop.x - budSize/2, y: stemTop.y - budSize/2, width: budSize, height: budSize)
            context.fill(Circle().path(in: budRect), with: .color(starColor.opacity(0.7)))
        }

        if level >= 4.5 {
            drawSparkle(context: context, at: stemTop, time: time)
        }
    }

    // MARK: - Emotional Safety: Blossom

    private static func drawBlossom(context: GraphicsContext, level: Double, position: CGPoint, groundY: CGFloat, sway: CGFloat, time: Double) {
        let height = CGFloat(12 + level * 13)
        let opacity = 0.4 + level * 0.12
        let blossomColor = Color(hex: 0xE8A0BF).opacity(opacity)

        // Stem
        var stemPath = Path()
        let stemBase = CGPoint(x: position.x + sway * 0.3, y: groundY)
        let stemTop = CGPoint(x: position.x + sway, y: groundY - height)
        stemPath.move(to: stemBase)
        stemPath.addQuadCurve(to: stemTop, control: CGPoint(x: position.x + sway * 0.5 + 4, y: groundY - height * 0.6))
        context.stroke(stemPath, with: .color(Color.green.opacity(opacity)), lineWidth: 1.5)

        // Soft petals
        if level >= 2 {
            let petalCount = Int(min(5, level + 1))
            let petalSize = CGFloat(4 + level * 2)
            for i in 0..<petalCount {
                let angle = (Double(i) / Double(petalCount)) * 2 * .pi
                let px = stemTop.x + cos(angle) * petalSize * 0.7
                let py = stemTop.y + sin(angle) * petalSize * 0.7
                let rect = CGRect(x: px - petalSize/2, y: py - petalSize/2, width: petalSize, height: petalSize)
                context.fill(Ellipse().path(in: rect), with: .color(blossomColor))
            }
        }

        if level >= 4.5 {
            drawSparkle(context: context, at: stemTop, time: time)
        }
    }

    // MARK: - Growth: Tree

    private static func drawTree(context: GraphicsContext, level: Double, position: CGPoint, groundY: CGFloat, sway: CGFloat, time: Double) {
        let trunkH = CGFloat(10 + level * 10)
        let canopyR = CGFloat(5 + level * 6)
        let opacity = 0.4 + level * 0.12

        // Trunk
        let trunkW: CGFloat = max(2, CGFloat(level) * 0.8)
        let trunkRect = CGRect(
            x: position.x + sway * 0.3 - trunkW / 2,
            y: groundY - trunkH,
            width: trunkW,
            height: trunkH
        )
        context.fill(Rectangle().path(in: trunkRect), with: .color(Color.brown.opacity(opacity)))

        // Canopy
        if level >= 2 {
            let canopyCenter = CGPoint(x: position.x + sway, y: groundY - trunkH - canopyR * 0.5)
            let canopyRect = CGRect(
                x: canopyCenter.x - canopyR,
                y: canopyCenter.y - canopyR,
                width: canopyR * 2,
                height: canopyR * 2
            )
            context.fill(Ellipse().path(in: canopyRect), with: .color(Color(hex: 0x2D8A4E).opacity(opacity)))

            // Secondary canopy layer
            if level >= 3 {
                let smallRect = CGRect(
                    x: canopyCenter.x - canopyR * 0.6 + sway * 0.3,
                    y: canopyCenter.y - canopyR * 1.1,
                    width: canopyR * 1.2,
                    height: canopyR * 1.2
                )
                context.fill(Ellipse().path(in: smallRect), with: .color(Color(hex: 0x0D5C63).opacity(opacity * 0.8)))
            }
        }

        if level >= 4.5 {
            drawSparkle(context: context, at: CGPoint(x: position.x + sway, y: groundY - trunkH - canopyR), time: time)
        }
    }

    // MARK: - Sparkle Effect

    private static func drawSparkle(context: GraphicsContext, at point: CGPoint, time: Double) {
        let sparkleAlpha = (sin(time * 3) + 1) / 2 * 0.8
        let offsets: [(CGFloat, CGFloat)] = [(-6, -4), (5, -7), (3, 5)]
        for (dx, dy) in offsets {
            let sp = CGPoint(x: point.x + dx, y: point.y + dy)
            let size: CGFloat = 2
            let rect = CGRect(x: sp.x - size/2, y: sp.y - size/2, width: size, height: size)
            context.fill(Circle().path(in: rect), with: .color(Color(hex: 0xC4923A).opacity(sparkleAlpha)))
        }
    }
}

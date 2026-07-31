import Foundation
import SwiftData

nonisolated enum CaptureMode: String, Codable, CaseIterable, Sendable {
    case depth3D
    case photo2D

    var title: String {
        switch self {
        case .depth3D:
            return "3D"
        case .photo2D:
            return "Photo"
        }
    }

    var badgeTitle: String {
        switch self {
        case .depth3D:
            return "3D · TrueDepth"
        case .photo2D:
            return "2D · Photo mode"
        }
    }

    var confidence: ConfidenceLevel {
        switch self {
        case .depth3D:
            return .high
        case .photo2D:
            return .estimated
        }
    }
}

nonisolated enum ConfidenceLevel: String, Codable, Sendable {
    case high
    case estimated

    var title: String {
        switch self {
        case .high:
            return "Depth-assisted estimate"
        case .estimated:
            return "Photo estimate"
        }
    }
}

nonisolated enum MetricKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case symmetry
    case proportion
    case canthalTilt
    case jawAngle
    case skinTexture

    var id: String { rawValue }

    var title: String {
        switch self {
        case .symmetry:
            return "Facial symmetry"
        case .proportion:
            return "Proportion balance"
        case .canthalTilt:
            return "Canthal tilt"
        case .jawAngle:
            return "Jaw angle"
        case .skinTexture:
            return "Visible skin texture"
        }
    }

    var shortTitle: String {
        switch self {
        case .symmetry:
            return "Symmetry"
        case .proportion:
            return "Proportion"
        case .canthalTilt:
            return "Canthal tilt"
        case .jawAngle:
            return "Jaw angle"
        case .skinTexture:
            return "Skin texture"
        }
    }

    var symbol: String {
        switch self {
        case .symmetry:
            return "scale.3d"
        case .proportion:
            return "aspectratio"
        case .canthalTilt:
            return "eye"
        case .jawAngle:
            return "angle"
        case .skinTexture:
            return "circle.grid.3x3"
        }
    }

    var unit: MetricUnit {
        switch self {
        case .symmetry, .proportion, .skinTexture:
            return .index
        case .canthalTilt, .jawAngle:
            return .degrees
        }
    }

    var summary: String {
        switch self {
        case .symmetry:
            return "How closely key left and right facial landmarks align."
        case .proportion:
            return "The balance between visible facial thirds and feature spacing."
        case .canthalTilt:
            return "The visible angle through the inner and outer eye corners."
        case .jawAngle:
            return "An estimate from the visible jaw contour in this capture."
        case .skinTexture:
            return "Visible tonal variation in this image, not a skin-health assessment."
        }
    }

    var methodology: String {
        switch self {
        case .symmetry:
            return "Vision landmarks are reflected across the estimated facial midline. Corresponding eye, nose, mouth, and contour offsets are combined into a neutral alignment index."
        case .proportion:
            return "Distances between the eye line, nose base, mouth, chin, and visible face bounds are compared. The result describes balance in this capture, not attractiveness."
        case .canthalTilt:
            return "The app estimates the line between the inner and outer points of each detected eye, then reports a range that includes landmark and pose variation."
        case .jawAngle:
            return "The visible lower-face contour is sampled near the jaw corners and chin. Photo mode cannot measure a clinical gonial angle and therefore uses a wider estimate."
        case .skinTexture:
            return "Local image contrast is sampled inside the detected face while excluding the background. Lighting and camera processing can change this estimate."
        }
    }
}

nonisolated enum MetricUnit: String, Codable, Sendable {
    case index
    case degrees
}

nonisolated struct MetricRangeValue: Codable, Hashable, Sendable {
    let low: Double
    let high: Double
    let unit: MetricUnit

    init(low: Double, high: Double, unit: MetricUnit) {
        let finiteLow = low.isFinite ? low : 0
        let finiteHigh = high.isFinite ? high : finiteLow
        self.low = min(finiteLow, finiteHigh)
        self.high = max(finiteLow, finiteHigh)
        self.unit = unit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            low: try container.decode(Double.self, forKey: .low),
            high: try container.decode(Double.self, forKey: .high),
            unit: try container.decode(MetricUnit.self, forKey: .unit)
        )
    }

    var displayText: String {
        let lowText = formatted(low)
        let highText = formatted(high)
        let prefix = unit == .degrees && low > 0 && high < 30 ? "+" : ""
        let suffix = unit == .degrees ? "°" : ""
        return "\(prefix)\(lowText)–\(highText)\(suffix)"
    }

    var accessibilityText: String {
        let unitText = unit == .degrees ? " degrees" : ""
        return "\(formatted(low)) to \(formatted(high))\(unitText)"
    }

    var midpoint: Double {
        (low + high) / 2
    }

    private func formatted(_ value: Double) -> String {
        if abs(value.rounded() - value) < 0.05 {
            return String(Int(value.rounded()))
        }
        return String(format: "%.1f", value)
    }
}

nonisolated struct GuidanceItem: Codable, Hashable, Identifiable, Sendable {
    enum Category: String, Codable, Sendable {
        case hair
        case skin
        case presentation
        case style

        var title: String {
            rawValue.capitalized
        }

        var symbol: String {
            switch self {
            case .hair:
                return "comb"
            case .skin:
                return "drop"
            case .presentation:
                return "camera"
            case .style:
                return "tshirt"
            }
        }
    }

    let id: UUID
    let category: Category
    let priority: String
    let title: String
    let detail: String

    init(
        id: UUID = UUID(),
        category: Category,
        priority: String,
        title: String,
        detail: String
    ) {
        self.id = id
        self.category = category
        self.priority = priority
        self.title = title
        self.detail = detail
    }
}

nonisolated struct TrueMaxAnalysisResult: Sendable {
    let captureMode: CaptureMode
    let confidence: ConfidenceLevel
    let symmetry: MetricRangeValue
    let proportion: MetricRangeValue
    let canthalTilt: MetricRangeValue
    let jawAngle: MetricRangeValue
    let skinTexture: MetricRangeValue
    let guidance: [GuidanceItem]
    let qualityNote: String
}

@Model
final class ScanRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var captureModeRaw: String
    var confidenceRaw: String
    var imageFilename: String?
    var analysisVersion: String
    var validationVersion: String
    var qualityNote: String

    var symmetryLow: Double
    var symmetryHigh: Double
    var proportionLow: Double
    var proportionHigh: Double
    var canthalTiltLow: Double
    var canthalTiltHigh: Double
    var jawAngleLow: Double
    var jawAngleHigh: Double
    var skinTextureLow: Double
    var skinTextureHigh: Double

    var guidanceData: Data

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        imageFilename: String?,
        analysis: TrueMaxAnalysisResult
    ) {
        self.id = id
        self.createdAt = createdAt
        self.captureModeRaw = analysis.captureMode.rawValue
        self.confidenceRaw = analysis.confidence.rawValue
        self.imageFilename = imageFilename
        self.analysisVersion = TrueMaxBrand.analysisVersion
        self.validationVersion = TrueMaxBrand.validationVersion
        self.qualityNote = analysis.qualityNote
        self.symmetryLow = analysis.symmetry.low
        self.symmetryHigh = analysis.symmetry.high
        self.proportionLow = analysis.proportion.low
        self.proportionHigh = analysis.proportion.high
        self.canthalTiltLow = analysis.canthalTilt.low
        self.canthalTiltHigh = analysis.canthalTilt.high
        self.jawAngleLow = analysis.jawAngle.low
        self.jawAngleHigh = analysis.jawAngle.high
        self.skinTextureLow = analysis.skinTexture.low
        self.skinTextureHigh = analysis.skinTexture.high
        self.guidanceData = (try? JSONEncoder().encode(analysis.guidance)) ?? Data()
    }

    var captureMode: CaptureMode {
        CaptureMode(rawValue: captureModeRaw) ?? .photo2D
    }

    var confidence: ConfidenceLevel {
        ConfidenceLevel(rawValue: confidenceRaw) ?? .estimated
    }

    var guidance: [GuidanceItem] {
        (try? JSONDecoder().decode([GuidanceItem].self, from: guidanceData)) ?? []
    }

    func range(for metric: MetricKind) -> MetricRangeValue {
        switch metric {
        case .symmetry:
            return MetricRangeValue(low: symmetryLow, high: symmetryHigh, unit: .index)
        case .proportion:
            return MetricRangeValue(low: proportionLow, high: proportionHigh, unit: .index)
        case .canthalTilt:
            return MetricRangeValue(low: canthalTiltLow, high: canthalTiltHigh, unit: .degrees)
        case .jawAngle:
            return MetricRangeValue(low: jawAngleLow, high: jawAngleHigh, unit: .degrees)
        case .skinTexture:
            return MetricRangeValue(low: skinTextureLow, high: skinTextureHigh, unit: .index)
        }
    }
}

@Model
final class StyleFavorite {
    @Attribute(.unique) var id: UUID
    var styleID: String
    var title: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        styleID: String,
        title: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.styleID = styleID
        self.title = title
        self.createdAt = createdAt
    }
}

@MainActor
enum TrueMaxFavoriteStore {
    @discardableResult
    static func toggle(
        styleID: String,
        title: String,
        in context: ModelContext
    ) throws -> Bool {
        let requestedStyleID = styleID
        let descriptor = FetchDescriptor<StyleFavorite>(
            predicate: #Predicate { favorite in
                favorite.styleID == requestedStyleID
            }
        )

        do {
            let matches = try context.fetch(descriptor)
            if matches.isEmpty {
                context.insert(
                    StyleFavorite(styleID: styleID, title: title)
                )
                try context.save()
                return true
            }

            // Clean up any legacy duplicates as part of removing a favorite.
            for favorite in matches {
                context.delete(favorite)
            }
            try context.save()
            return false
        } catch {
            context.rollback()
            throw error
        }
    }
}

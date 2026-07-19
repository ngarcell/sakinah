import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftData
import SwiftUI

private struct TrueMaxHairStyle: Identifiable, Hashable {
    enum Category: String, CaseIterable, Identifiable {
        case recommended = "Recommended"
        case short = "Short"
        case medium = "Medium"
        case textured = "Textured"
        case lowMaintenance = "Low maintenance"

        var id: String { rawValue }
    }

    let id: String
    let title: String
    let detail: String
    let category: Category
    let symbol: String
    let target: TrueMaxStyleTarget

    static let library: [TrueMaxHairStyle] = [
        TrueMaxHairStyle(
            id: "textured-crop",
            title: "Textured crop",
            detail: "Adds controlled texture through the upper sides.",
            category: .textured,
            symbol: "scribble",
            target: TrueMaxStyleTarget(
                contourDefinition: 0.54,
                proportionBalance: 0.62,
                centeredFraming: 0.58,
                visualDirection: 0.52
            )
        ),
        TrueMaxHairStyle(
            id: "side-part",
            title: "Side part",
            detail: "Clean direction with a versatile, defined shape.",
            category: .medium,
            symbol: "line.diagonal",
            target: TrueMaxStyleTarget(
                contourDefinition: 0.46,
                proportionBalance: 0.68,
                centeredFraming: 0.38,
                visualDirection: 0.72
            )
        ),
        TrueMaxHairStyle(
            id: "low-taper",
            title: "Low taper",
            detail: "Low-maintenance tapering with a natural outline.",
            category: .short,
            symbol: "arrow.down.right",
            target: TrueMaxStyleTarget(
                contourDefinition: 0.68,
                proportionBalance: 0.76,
                centeredFraming: 0.70,
                visualDirection: 0.38
            )
        ),
        TrueMaxHairStyle(
            id: "natural-quiff",
            title: "Natural quiff",
            detail: "Controlled lift at the front without changing your face.",
            category: .medium,
            symbol: "wind",
            target: TrueMaxStyleTarget(
                contourDefinition: 0.34,
                proportionBalance: 0.48,
                centeredFraming: 0.62,
                visualDirection: 0.82
            )
        ),
        TrueMaxHairStyle(
            id: "soft-buzz",
            title: "Soft buzz",
            detail: "An even, simple shape with minimal daily styling.",
            category: .lowMaintenance,
            symbol: "circle.dotted",
            target: TrueMaxStyleTarget(
                contourDefinition: 0.82,
                proportionBalance: 0.88,
                centeredFraming: 0.86,
                visualDirection: 0.22
            )
        ),
    ]
}

private struct TrueMaxStyleTarget: Hashable {
    let contourDefinition: Double
    let proportionBalance: Double
    let centeredFraming: Double
    let visualDirection: Double
}

private struct TrueMaxFaceStyleProfile {
    let contourDefinition: Double
    let proportionBalance: Double
    let centeredFraming: Double
    let visualDirection: Double
    let measurementCertainty: Double

    init(scan: ScanRecord) {
        let jawAngle = scan.range(for: .jawAngle).midpoint
        let proportion = scan.range(for: .proportion).midpoint
        let symmetry = scan.range(for: .symmetry).midpoint
        let canthalTilt = abs(scan.range(for: .canthalTilt).midpoint)

        // These values are normalized measurement descriptors, not
        // attractiveness scores or inferred demographic attributes.
        contourDefinition = Self.normalized(
            145 - jawAngle,
            lowerBound: -20,
            upperBound: 75
        )
        proportionBalance = Self.normalized(
            proportion,
            lowerBound: 35,
            upperBound: 98
        )
        centeredFraming = Self.normalized(
            symmetry,
            lowerBound: 35,
            upperBound: 98
        )
        visualDirection = Self.normalized(
            canthalTilt,
            lowerBound: 0,
            upperBound: 15
        )

        let proportionRange = scan.range(for: .proportion)
        let symmetryRange = scan.range(for: .symmetry)
        let jawRange = scan.range(for: .jawAngle)
        let totalUncertainty = (proportionRange.high - proportionRange.low) / 63
            + (symmetryRange.high - symmetryRange.low) / 63
            + (jawRange.high - jawRange.low) / 100
        let rangeCertainty = 1 - min(max(totalUncertainty / 3, 0), 1)
        // Depth-assisted captures already receive narrower bands from the
        // analysis engine. Do not add a second, unsupported confidence boost
        // merely because a depth summary was available.
        measurementCertainty = rangeCertainty
    }

    var summary: String {
        let contour: String
        if contourDefinition >= 0.64 {
            contour = "Defined contour"
        } else if contourDefinition <= 0.38 {
            contour = "Soft contour"
        } else {
            contour = "Balanced contour"
        }

        let balance: String
        if proportionBalance >= 0.72 {
            balance = "High balance"
        } else if proportionBalance <= 0.46 {
            balance = "Variable balance"
        } else {
            balance = "Moderate balance"
        }
        return "\(contour) · \(balance)"
    }

    private static func normalized(
        _ value: Double,
        lowerBound: Double,
        upperBound: Double
    ) -> Double {
        guard upperBound > lowerBound else { return 0.5 }
        return min(max((value - lowerBound) / (upperBound - lowerBound), 0), 1)
    }
}

private struct TrueMaxStyleRecommendation: Identifiable, Hashable {
    let style: TrueMaxHairStyle
    let score: Int
    let match: String
    let reason: String

    var id: String { style.id }
}

private enum TrueMaxStyleRecommender {
    static func recommendations(
        for scan: ScanRecord
    ) -> [TrueMaxStyleRecommendation] {
        let profile = TrueMaxFaceStyleProfile(scan: scan)

        return TrueMaxHairStyle.library
            .map { style in
                let closeness = weightedCloseness(
                    profile: profile,
                    target: style.target
                )
                let rawScore = 51
                    + closeness * 43
                    + profile.measurementCertainty * 3
                let score = Int(min(max(rawScore.rounded(), 0), 99))
                return TrueMaxStyleRecommendation(
                    style: style,
                    score: score,
                    match: matchLabel(for: score),
                    reason: reason(
                        for: style,
                        profile: profile
                    )
                )
            }
            .sorted {
                if $0.score == $1.score {
                    return $0.style.id < $1.style.id
                }
                return $0.score > $1.score
            }
    }

    private static func weightedCloseness(
        profile: TrueMaxFaceStyleProfile,
        target: TrueMaxStyleTarget
    ) -> Double {
        let contour = 1 - abs(
            profile.contourDefinition - target.contourDefinition
        )
        let proportion = 1 - abs(
            profile.proportionBalance - target.proportionBalance
        )
        let framing = 1 - abs(
            profile.centeredFraming - target.centeredFraming
        )
        let direction = 1 - abs(
            profile.visualDirection - target.visualDirection
        )

        return min(
            max(
                contour * 0.34
                    + proportion * 0.29
                    + framing * 0.25
                    + direction * 0.12,
                0
            ),
            1
        )
    }

    private static func matchLabel(for score: Int) -> String {
        switch score {
        case 86...:
            return "Strong match"
        case 77...:
            return "Good match"
        default:
            return "Worth exploring"
        }
    }

    private static func reason(
        for style: TrueMaxHairStyle,
        profile: TrueMaxFaceStyleProfile
    ) -> String {
        switch style.id {
        case "textured-crop":
            if profile.contourDefinition >= 0.64 {
                return "Controlled top texture adds contrast above the more defined jaw contour measured in this scan."
            }
            if profile.proportionBalance <= 0.46 {
                return "Flexible texture makes the upper framing easy to tune alongside the scan’s more varied facial-third balance."
            }
            return "Controlled texture follows the scan’s balanced contour without relying on rigid, centered framing."

        case "side-part":
            if profile.centeredFraming <= 0.52 {
                return "An adjustable part gives directional framing where this scan shows more left-to-right landmark variation."
            }
            if profile.visualDirection >= 0.55 {
                return "The clean directional line echoes the stronger eye-line direction measured in this scan."
            }
            return "A clean off-center line complements the scan’s higher landmark alignment while keeping the framing flexible."

        case "low-taper":
            if profile.contourDefinition >= 0.64 {
                return "The low transition keeps the scan’s more defined lower contour as the main framing line."
            }
            if profile.proportionBalance >= 0.72 {
                return "A natural low outline works with the higher facial-third balance measured in this scan."
            }
            return "The gradual low outline provides adaptable framing for this scan’s moderate measurement balance."

        case "natural-quiff":
            if profile.visualDirection >= 0.55 {
                return "Adjustable front lift follows the stronger visual direction measured along the eye line."
            }
            if profile.proportionBalance <= 0.46 {
                return "Adjustable lift offers more control alongside the scan’s more varied facial-third balance."
            }
            return "Soft front lift adds direction while preserving the scan’s measured contour and landmark alignment."

        case "soft-buzz":
            if profile.centeredFraming >= 0.72
                && profile.proportionBalance >= 0.72 {
                return "Even length leaves the scan’s higher landmark alignment and facial-third balance unobstructed."
            }
            if profile.contourDefinition >= 0.64 {
                return "Even length makes the more defined lower contour measured in this scan the primary outline."
            }
            return "The uniform outline is a simple option for the scan’s softer contour and moderate measurement balance."

        default:
            return style.detail
        }
    }
}

struct TrueMaxStyleLibraryView: View {
    let scan: ScanRecord

    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [StyleFavorite]
    @Query(sort: \ScanRecord.createdAt, order: .reverse)
    private var scans: [ScanRecord]

    @State private var category: TrueMaxHairStyle.Category = .recommended

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ZStack {
            TrueMaxPageBackground()

            ScrollView {
                VStack(spacing: 18) {
                    TrueMaxPill(
                        icon: "sparkles",
                        text: "\(faceProfile.summary) · Latest scan"
                    )

                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(TrueMaxHairStyle.Category.allCases) { option in
                                Button {
                                    category = option
                                } label: {
                                    Text(option.rawValue)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(
                                            category == option
                                                ? Color.white
                                                : TrueMaxPalette.textSecondary
                                        )
                                        .padding(.horizontal, 15)
                                        .frame(minHeight: 46)
                                        .background(
                                            category == option
                                                ? AnyShapeStyle(TrueMaxPalette.primaryGradient)
                                                : AnyShapeStyle(TrueMaxPalette.card),
                                            in: RoundedRectangle(cornerRadius: 13)
                                        )
                                        .overlay {
                                            if category != option {
                                                RoundedRectangle(cornerRadius: 13)
                                                    .strokeBorder(TrueMaxPalette.border)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredRecommendations) { recommendation in
                            NavigationLink {
                                TrueMaxStylePreviewView(
                                    scan: recommendationScan,
                                    initialRecommendation: recommendation,
                                    recommendations: recommendations
                                )
                            } label: {
                                StyleLibraryCard(
                                    scan: recommendationScan,
                                    recommendation: recommendation,
                                    isFavorite: isFavorite(
                                        recommendation.style
                                    )
                                ) {
                                    toggleFavorite(recommendation.style)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Recommendations use your latest measurement ranges—not attractiveness. Style previews are neutral, non-photorealistic guides, and TrueMax never generates an “idealized” version of your face.")
                        .font(.footnote)
                        .foregroundStyle(TrueMaxPalette.textTertiary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 18)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .trueMaxContentWidth()
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Styles for you")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            TrueMaxAnalytics.shared.screen("style library", properties: [
                "category": category.rawValue
            ])
        }
    }

    private var recommendationScan: ScanRecord {
        scans.first ?? scan
    }

    private var faceProfile: TrueMaxFaceStyleProfile {
        TrueMaxFaceStyleProfile(scan: recommendationScan)
    }

    private var recommendations: [TrueMaxStyleRecommendation] {
        TrueMaxStyleRecommender.recommendations(for: recommendationScan)
    }

    private var filteredRecommendations: [TrueMaxStyleRecommendation] {
        if category == .recommended {
            return Array(recommendations.prefix(3))
        }
        return recommendations.filter { $0.style.category == category }
    }

    private func isFavorite(_ style: TrueMaxHairStyle) -> Bool {
        favorites.contains { $0.styleID == style.id }
    }

    private func toggleFavorite(_ style: TrueMaxHairStyle) {
        if let existing = favorites.first(where: { $0.styleID == style.id }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(
                StyleFavorite(styleID: style.id, title: style.title)
            )
        }
        try? modelContext.save()
    }
}

private struct TrueMaxStylePreviewView: View {
    let scan: ScanRecord
    let recommendations: [TrueMaxStyleRecommendation]

    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [StyleFavorite]

    @State private var selectedRecommendation: TrueMaxStyleRecommendation

    init(
        scan: ScanRecord,
        initialRecommendation: TrueMaxStyleRecommendation,
        recommendations: [TrueMaxStyleRecommendation]
    ) {
        self.scan = scan
        self.recommendations = recommendations
        _selectedRecommendation = State(
            initialValue: initialRecommendation
        )
    }

    var body: some View {
        ZStack {
            TrueMaxPageBackground()

            ScrollView {
                VStack(spacing: 18) {
                    ZStack(alignment: .top) {
                        Group {
                            if let image = TrueMaxStorage.image(filename: scan.imageFilename) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                FaceMeshIllustration(mode: scan.captureMode)
                                    .padding(30)
                                    .background(TrueMaxPalette.backgroundRaised)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 470)
                        .clipped()

                        ZStack {
                            HairGuideOverlay(styleID: selectedStyle.id)
                                .fill(TrueMaxPalette.accent.opacity(0.25))
                            HairGuideOverlay(styleID: selectedStyle.id)
                                .strokeBorder(
                                    TrueMaxPalette.accentLight,
                                    lineWidth: 2
                                )
                        }
                        .frame(width: 270, height: 150)
                        .padding(.top, 28)
                        .accessibilityHidden(true)

                        Text("STYLE GUIDE · NOT A GENERATED PHOTO")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.64), in: Capsule())
                            .padding(.top, 12)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(TrueMaxPalette.border)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(selectedStyle.title)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(TrueMaxPalette.textPrimary)
                            Spacer()
                            Label(
                                selectedRecommendation.match,
                                systemImage: "checkmark.circle"
                            )
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(TrueMaxPalette.positive)
                        }

                        TrueMaxDisclosureRow(
                            icon: "chart.bar.doc.horizontal",
                            title: selectedRecommendation.reason,
                            showsChevron: false
                        )
                        TrueMaxDisclosureRow(
                            icon: "arrow.up",
                            title: selectedStyle.detail,
                            showsChevron: false
                        )
                        TrueMaxDisclosureRow(
                            icon: "scissors",
                            title: "Show this guide to your barber or stylist",
                            showsChevron: false
                        )

                        ScrollView(.horizontal) {
                            HStack(spacing: 10) {
                                ForEach(recommendations) { recommendation in
                                    Button {
                                        selectedRecommendation = recommendation
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(
                                                systemName: recommendation.style.symbol
                                            )
                                                .font(.title2)
                                                .foregroundStyle(TrueMaxPalette.accentLight)
                                            Text(recommendation.style.title)
                                                .font(.caption2)
                                                .foregroundStyle(TrueMaxPalette.textSecondary)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 94, height: 78)
                                        .background(
                                            selectedStyle.id
                                                == recommendation.style.id
                                                ? TrueMaxPalette.accent.opacity(0.12)
                                                : TrueMaxPalette.backgroundRaised,
                                            in: RoundedRectangle(cornerRadius: 12)
                                        )
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(
                                                    selectedStyle.id
                                                        == recommendation.style.id
                                                        ? TrueMaxPalette.accentLight
                                                        : TrueMaxPalette.border,
                                                    lineWidth: selectedStyle.id
                                                        == recommendation.style.id
                                                        ? 2
                                                        : 1
                                                )
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)

                        Button {
                            toggleFavorite()
                        } label: {
                            Label(
                                isFavorite ? "Saved to favorites" : "Save to favorites",
                                systemImage: isFavorite ? "star.fill" : "star"
                            )
                        }
                        .buttonStyle(TrueMaxPrimaryButtonStyle())
                    }
                    .trueMaxCard(elevated: true)

                    Label(
                        "Preview changes only the local guide overlay—your face is never modified.",
                        systemImage: "lock.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(TrueMaxPalette.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .trueMaxContentWidth()
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Try a style")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var isFavorite: Bool {
        favorites.contains { $0.styleID == selectedStyle.id }
    }

    private var selectedStyle: TrueMaxHairStyle {
        selectedRecommendation.style
    }

    private func toggleFavorite() {
        if let favorite = favorites.first(where: { $0.styleID == selectedStyle.id }) {
            modelContext.delete(favorite)
        } else {
            modelContext.insert(
                StyleFavorite(
                    styleID: selectedStyle.id,
                    title: selectedStyle.title
                )
            )
        }
        try? modelContext.save()
    }
}

struct TrueMaxColorAnalysisView: View {
    let scan: ScanRecord

    private var profile: TrueMaxColorProfile {
        TrueMaxColorAnalyzer.profile(
            for: TrueMaxStorage.image(filename: scan.imageFilename)
        )
    }

    var body: some View {
        ZStack {
            TrueMaxPageBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Your colors")
                        .font(.title2.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(TrueMaxPalette.textPrimary)

                    HStack(alignment: .center, spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(profile.title)
                                .font(.title.weight(.bold))
                                .foregroundStyle(TrueMaxPalette.textPrimary)
                            Text(profile.detail)
                                .font(.subheadline)
                                .foregroundStyle(TrueMaxPalette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)

                        PaletteWheel(colors: profile.colors)
                            .frame(width: 180, height: 180)
                    }

                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(Array(profile.namedColors.enumerated()), id: \.offset) { _, named in
                                VStack(spacing: 7) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(named.color)
                                        .frame(width: 70, height: 82)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(Color.white.opacity(0.35))
                                        }
                                    Text(named.name)
                                        .font(.caption2)
                                        .foregroundStyle(TrueMaxPalette.textSecondary)
                                }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)

                    HStack(spacing: 18) {
                        TrueMaxIconCircle(symbol: "tshirt", size: 62)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Best near your face")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(TrueMaxPalette.textPrimary)
                            Text(profile.guidance)
                                .font(.body)
                                .foregroundStyle(TrueMaxPalette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .trueMaxCard(elevated: true)

                    VStack(spacing: 0) {
                        ColorGuidanceRow(
                            title: "Choose",
                            detail: profile.chooseDetail,
                            colors: profile.colors
                        )
                        Divider().overlay(TrueMaxPalette.border)
                        ColorGuidanceRow(
                            title: "Use sparingly",
                            detail: profile.sparingDetail,
                            colors: profile.avoidColors
                        )
                    }
                    .trueMaxCard()

                    Label(
                        "Color guidance is an estimate from the central region of your latest capture. Camera processing and lighting can change it.",
                        systemImage: "info.circle"
                    )
                    .font(.footnote)
                    .foregroundStyle(TrueMaxPalette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .trueMaxContentWidth()
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            TrueMaxAnalytics.shared.screen("color analysis")
        }
    }
}

private struct StyleLibraryCard: View {
    let scan: ScanRecord
    let recommendation: TrueMaxStyleRecommendation
    let isFavorite: Bool
    let toggleFavorite: () -> Void

    private var style: TrueMaxHairStyle {
        recommendation.style
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let image = TrueMaxStorage.image(filename: scan.imageFilename) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        FaceMeshIllustration(mode: scan.captureMode)
                            .padding(15)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(TrueMaxPalette.backgroundRaised)
                .clipped()

                ZStack {
                    HairGuideOverlay(styleID: style.id)
                        .fill(TrueMaxPalette.accent.opacity(0.20))
                    HairGuideOverlay(styleID: style.id)
                        .strokeBorder(
                            TrueMaxPalette.accentLight,
                            lineWidth: 1.5
                        )
                }
                .frame(width: 130, height: 72)
                .padding(.top, 12)
                .padding(.horizontal, 8)

                Button(action: toggleFavorite) {
                    Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                        .font(.headline)
                        .foregroundStyle(Color.white)
                        .frame(width: 38, height: 38)
                        .background(Color.black.opacity(0.65), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(8)
                .accessibilityLabel(isFavorite ? "Remove favorite" : "Save favorite")
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    topTrailingRadius: 16
                )
            )

            Text(style.title)
                .font(.headline)
                .foregroundStyle(TrueMaxPalette.textPrimary)
            Label(
                recommendation.match,
                systemImage: "checkmark.circle"
            )
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    recommendation.match == "Strong match"
                        ? TrueMaxPalette.positive
                        : TrueMaxPalette.neutral
                )
            Text(recommendation.reason)
                .font(.caption)
                .foregroundStyle(TrueMaxPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 14)
        .background(TrueMaxPalette.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(TrueMaxPalette.border)
        }
    }
}

private struct HairGuideOverlay: InsettableShape {
    let styleID: String
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let inset = rect.insetBy(dx: insetAmount, dy: insetAmount)
        var path = Path()

        switch styleID {
        case "side-part":
            path.move(to: CGPoint(x: inset.minX, y: inset.maxY))
            path.addCurve(
                to: CGPoint(x: inset.maxX, y: inset.maxY),
                control1: CGPoint(x: inset.midX * 0.70, y: inset.minY - 10),
                control2: CGPoint(x: inset.maxX * 0.90, y: inset.minY + 20)
            )
            path.addLine(to: CGPoint(x: inset.minX, y: inset.maxY))
        case "low-taper", "soft-buzz":
            path.addRoundedRect(
                in: CGRect(
                    x: inset.minX + inset.width * 0.12,
                    y: inset.minY + inset.height * 0.28,
                    width: inset.width * 0.76,
                    height: inset.height * 0.62
                ),
                cornerSize: CGSize(width: 44, height: 38)
            )
        case "natural-quiff":
            path.move(to: CGPoint(x: inset.minX, y: inset.maxY))
            path.addCurve(
                to: CGPoint(x: inset.maxX, y: inset.maxY),
                control1: CGPoint(x: inset.midX * 0.72, y: inset.minY - 32),
                control2: CGPoint(x: inset.midX * 1.20, y: inset.minY + 12)
            )
            path.closeSubpath()
        default:
            path.move(to: CGPoint(x: inset.minX, y: inset.maxY))
            path.addCurve(
                to: CGPoint(x: inset.maxX, y: inset.maxY),
                control1: CGPoint(x: inset.minX + inset.width * 0.22, y: inset.minY),
                control2: CGPoint(x: inset.maxX - inset.width * 0.22, y: inset.minY)
            )
            path.closeSubpath()
        }
        return path
    }

    func inset(by amount: CGFloat) -> HairGuideOverlay {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

private struct TrueMaxNamedColor {
    let name: String
    let color: Color
}

private struct TrueMaxColorProfile {
    let title: String
    let detail: String
    let guidance: String
    let chooseDetail: String
    let sparingDetail: String
    let namedColors: [TrueMaxNamedColor]
    let avoidColors: [Color]

    var colors: [Color] {
        namedColors.map(\.color)
    }
}

private enum TrueMaxColorAnalyzer {
    static func profile(for image: UIImage?) -> TrueMaxColorProfile {
        guard let image,
              let values = averageRGBA(of: image) else {
            return neutralProfile
        }

        let red = values.red
        let green = values.green
        let blue = values.blue
        let brightness = (red + green + blue) / 3
        let cool = blue + 0.025 >= red
        let deep = brightness < 0.60

        if cool && deep {
            return winterProfile
        } else if cool {
            return summerProfile
        } else if deep {
            return autumnProfile
        }
        return springProfile
    }

    private static func averageRGBA(
        of image: UIImage
    ) -> (red: Double, green: Double, blue: Double, alpha: Double)? {
        guard let input = CIImage(image: image) else { return nil }
        let crop = input.extent.insetBy(
            dx: input.extent.width * 0.25,
            dy: input.extent.height * 0.22
        )
        guard !crop.isEmpty else { return nil }

        let filter = CIFilter.areaAverage()
        filter.inputImage = input.cropped(to: crop)
        filter.extent = crop
        guard let output = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        CIContext(options: [.workingColorSpace: NSNull()])
            .render(
                output,
                toBitmap: &bitmap,
                rowBytes: 4,
                bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                format: .RGBA8,
                colorSpace: CGColorSpaceCreateDeviceRGB()
            )

        return (
            Double(bitmap[0]) / 255,
            Double(bitmap[1]) / 255,
            Double(bitmap[2]) / 255,
            Double(bitmap[3]) / 255
        )
    }

    private static let winterProfile = TrueMaxColorProfile(
        title: "Deep Winter",
        detail: "Higher contrast · Cool-neutral estimate",
        guidance: "Clear, deep, cool colors can create clean contrast near your face.",
        chooseDetail: "Clear, cool, high-contrast colors",
        sparingDetail: "Muted warm tones may soften contrast",
        namedColors: [
            .init(name: "Navy", color: Color(hex: 0x10285B)),
            .init(name: "Charcoal", color: Color(hex: 0x2B2E34)),
            .init(name: "Crisp white", color: Color(hex: 0xF8F8F5)),
            .init(name: "Cobalt", color: Color(hex: 0x1746B5)),
            .init(name: "Burgundy", color: Color(hex: 0x730F35)),
            .init(name: "Forest", color: Color(hex: 0x154D36)),
            .init(name: "Icy blue", color: Color(hex: 0xB8D9EE)),
            .init(name: "Black", color: Color(hex: 0x080808)),
        ],
        avoidColors: [
            Color(hex: 0xC3975A),
            Color(hex: 0xBD6C53),
            Color(hex: 0xB5A083),
            Color(hex: 0xD2C5B0),
        ]
    )

    private static let summerProfile = TrueMaxColorProfile(
        title: "Soft Summer",
        detail: "Lower contrast · Cool-neutral estimate",
        guidance: "Soft cool colors can sit naturally near your face without overpowering it.",
        chooseDetail: "Soft blue, slate, berry, and cool neutrals",
        sparingDetail: "Very bright orange and yellow",
        namedColors: [
            .init(name: "Slate", color: Color(hex: 0x607184)),
            .init(name: "Denim", color: Color(hex: 0x527B9D)),
            .init(name: "Soft white", color: Color(hex: 0xEEECE7)),
            .init(name: "Berry", color: Color(hex: 0x8A4B67)),
            .init(name: "Sage", color: Color(hex: 0x789083)),
            .init(name: "Lavender", color: Color(hex: 0x9991B3)),
        ],
        avoidColors: [Color(hex: 0xFF8D26), Color(hex: 0xF2CB32)]
    )

    private static let autumnProfile = TrueMaxColorProfile(
        title: "Deep Autumn",
        detail: "Higher contrast · Warm-neutral estimate",
        guidance: "Deep earthy colors can echo the warmth visible in this capture.",
        chooseDetail: "Forest, rust, camel, warm navy, and cream",
        sparingDetail: "Icy pastels and blue-white",
        namedColors: [
            .init(name: "Olive", color: Color(hex: 0x5D6331)),
            .init(name: "Rust", color: Color(hex: 0xA44B2A)),
            .init(name: "Camel", color: Color(hex: 0xB98552)),
            .init(name: "Cream", color: Color(hex: 0xEFE2C7)),
            .init(name: "Forest", color: Color(hex: 0x294A36)),
            .init(name: "Warm navy", color: Color(hex: 0x24364A)),
        ],
        avoidColors: [Color(hex: 0xBEE4FA), Color(hex: 0xF6F7FF)]
    )

    private static let springProfile = TrueMaxColorProfile(
        title: "Clear Spring",
        detail: "Lighter contrast · Warm-neutral estimate",
        guidance: "Clear warm colors can add brightness near your face.",
        chooseDetail: "Clear green, warm blue, coral, and cream",
        sparingDetail: "Dusty gray and very dark black",
        namedColors: [
            .init(name: "Teal", color: Color(hex: 0x168E8B)),
            .init(name: "Coral", color: Color(hex: 0xE96D5F)),
            .init(name: "Cream", color: Color(hex: 0xFFF0CF)),
            .init(name: "Leaf", color: Color(hex: 0x5E9E48)),
            .init(name: "Warm blue", color: Color(hex: 0x3D81BA)),
            .init(name: "Camel", color: Color(hex: 0xC7985D)),
        ],
        avoidColors: [Color(hex: 0x696970), Color(hex: 0x080808)]
    )

    private static let neutralProfile = TrueMaxColorProfile(
        title: "Neutral starting palette",
        detail: "Complete a scan for a capture-based estimate",
        guidance: "Balanced navy, charcoal, soft white, and forest are flexible starting points.",
        chooseDetail: "Balanced, medium-contrast colors",
        sparingDetail: "Extremely bright or highly muted colors",
        namedColors: [
            .init(name: "Navy", color: Color(hex: 0x17345C)),
            .init(name: "Charcoal", color: Color(hex: 0x34363B)),
            .init(name: "Soft white", color: Color(hex: 0xEEEDE8)),
            .init(name: "Forest", color: Color(hex: 0x315643)),
        ],
        avoidColors: [Color(hex: 0xFF5A36), Color(hex: 0xD7D0C6)]
    )
}

private struct PaletteWheel: View {
    let colors: [Color]

    var body: some View {
        Canvas { context, size in
            guard !colors.isEmpty else { return }
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            let innerRadius = radius * 0.52
            let segment = (Double.pi * 2) / Double(colors.count)

            for (index, color) in colors.enumerated() {
                let start = -Double.pi / 2 + Double(index) * segment
                let end = start + segment
                var path = Path()
                path.move(
                    to: CGPoint(
                        x: center.x + innerRadius * CGFloat(cos(start)),
                        y: center.y + innerRadius * CGFloat(sin(start))
                    )
                )
                path.addLine(
                    to: CGPoint(
                        x: center.x + radius * CGFloat(cos(start)),
                        y: center.y + radius * CGFloat(sin(start))
                    )
                )
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .radians(start),
                    endAngle: .radians(end),
                    clockwise: false
                )
                path.addLine(
                    to: CGPoint(
                        x: center.x + innerRadius * CGFloat(cos(end)),
                        y: center.y + innerRadius * CGFloat(sin(end))
                    )
                )
                path.addArc(
                    center: center,
                    radius: innerRadius,
                    startAngle: .radians(end),
                    endAngle: .radians(start),
                    clockwise: true
                )
                path.closeSubpath()
                context.fill(path, with: .color(color))
                context.stroke(path, with: .color(Color.white.opacity(0.22)), lineWidth: 0.7)
            }
        }
        .accessibilityLabel("Suggested color palette")
    }
}

private struct ColorGuidanceRow: View {
    let title: String
    let detail: String
    let colors: [Color]

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(TrueMaxPalette.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(TrueMaxPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 120, alignment: .leading)

            HStack(spacing: -4) {
                ForEach(Array(colors.prefix(6).enumerated()), id: \.offset) { _, color in
                    Circle()
                        .fill(color)
                        .frame(width: 34, height: 34)
                        .overlay {
                            Circle().strokeBorder(Color.white.opacity(0.4))
                        }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 15)
    }
}

import Foundation

/// Versioned, local knowledge used by TrueMax's guidance rules. The app never
/// fetches face-related guidance at runtime: this keeps the privacy boundary
/// deterministic and makes every recommendation traceable to a reviewed source.
struct TrueMaxKnowledgeEntry: Identifiable, Hashable, Sendable {
    enum EvidenceGrade: String, Hashable, Sendable {
        case platform
        case guardrail
    }

    let id: String
    let title: String
    let publisher: String
    let summary: String
    let sourceURL: URL
    let reviewedOn: String
    let evidenceGrade: EvidenceGrade
}

enum TrueMaxKnowledgeBase {
    static let schemaVersion = 1
    static let packVersion = "2026.07.19"
    static let revision = "2026-07-19"
    static let reviewCadenceDays = 90

    static let entries: [TrueMaxKnowledgeEntry] = [
        TrueMaxKnowledgeEntry(
            id: "vision-face-landmarks",
            title: "Vision face landmarks",
            publisher: "Apple Developer",
            summary: "Use landmark geometry for visible, image-dependent relationships; do not present it as clinical anatomy or an attractiveness score.",
            sourceURL: URL(string: "https://developer.apple.com/documentation/vision/detectfacelandmarksrequest")!,
            reviewedOn: revision,
            evidenceGrade: .platform
        ),
        TrueMaxKnowledgeEntry(
            id: "vision-face-capture-quality",
            title: "Vision face capture quality",
            publisher: "Apple Developer",
            summary: "Use Vision's 0–1 capture-quality signal as an uncertainty input for lighting, sharpness, pose, and framing; never as a person score.",
            sourceURL: URL(string: "https://developer.apple.com/documentation/vision/detectfacecapturequalityrequest")!,
            reviewedOn: revision,
            evidenceGrade: .platform
        ),
        TrueMaxKnowledgeEntry(
            id: "avfoundation-photo-capture",
            title: "AVFoundation photo capture",
            publisher: "Apple Developer",
            summary: "Treat each deliberate still capture as a new sample and preserve the user's lighting, pose, and framing guidance.",
            sourceURL: URL(string: "https://developer.apple.com/documentation/avfoundation/avcapturephotooutput")!,
            reviewedOn: revision,
            evidenceGrade: .platform
        ),
        TrueMaxKnowledgeEntry(
            id: "avfoundation-depth-data",
            title: "AVDepthData calibration",
            publisher: "Apple Developer",
            summary: "Depth values are camera data that require calibration and distortion awareness; TrueMax retains only a compact transient summary.",
            sourceURL: URL(string: "https://developer.apple.com/documentation/avfoundation/avdepthdata")!,
            reviewedOn: revision,
            evidenceGrade: .platform
        ),
        TrueMaxKnowledgeEntry(
            id: "declared-age-range",
            title: "Declared Age Range",
            publisher: "Apple Developer",
            summary: "Use a system age-range signal for the adult gate without requesting or persisting an exact birth date.",
            sourceURL: URL(string: "https://developer.apple.com/documentation/DeclaredAgeRange")!,
            reviewedOn: revision,
            evidenceGrade: .platform
        ),
        TrueMaxKnowledgeEntry(
            id: "privacy-manifest",
            title: "Apple privacy manifest",
            publisher: "Apple Developer",
            summary: "Keep required-reason declarations and data-use statements aligned with the APIs and local-only storage actually used by the target.",
            sourceURL: URL(string: "https://developer.apple.com/documentation/bundleresources/privacy-manifest-files")!,
            reviewedOn: revision,
            evidenceGrade: .platform
        ),
        TrueMaxKnowledgeEntry(
            id: "apple-app-review-safety",
            title: "App Store safety boundary",
            publisher: "Apple Developer",
            summary: "Keep cosmetic claims truthful and avoid medical, psychological, ranking, or harmful appearance promises.",
            sourceURL: URL(string: "https://developer.apple.com/app-store/review/guidelines/")!,
            reviewedOn: revision,
            evidenceGrade: .guardrail
        ),
        TrueMaxKnowledgeEntry(
            id: "nist-ai-rmf-1",
            title: "AI risk traceability",
            publisher: "National Institute of Standards and Technology",
            summary: "Version sources, evaluate deterministic behavior, expose limitations, and keep human-readable provenance for every guidance rule.",
            sourceURL: URL(string: "https://www.nist.gov/publications/artificial-intelligence-risk-management-framework-ai-rmf-10")!,
            reviewedOn: revision,
            evidenceGrade: .guardrail
        ),
    ]

    static func entry(_ id: String) -> TrueMaxKnowledgeEntry? {
        entries.first { $0.id == id }
    }
}

struct TrueMaxIntelligenceSignal: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let detail: String
    let knowledgeID: String
}

/// Deterministic decision layer. It consumes only persisted derived ranges and
/// capture mode, never a raw image, depth map, or remote profile.
enum TrueMaxIntelligenceEngine {
    static func signals(for scan: ScanRecord) -> [TrueMaxIntelligenceSignal] {
        var signals: [TrueMaxIntelligenceSignal] = []

        if scan.captureMode == .photo2D {
            signals.append(
                TrueMaxIntelligenceSignal(
                    id: "photo-repeatability",
                    title: "Repeat the same setup",
                    detail: "Photo mode is most useful when light, distance, and expression stay consistent between scans.",
                    knowledgeID: "vision-face-landmarks"
                )
            )
        } else {
            signals.append(
                TrueMaxIntelligenceSignal(
                    id: "depth-assisted-boundary",
                    title: "Keep the depth context in view",
                    detail: "TrueDepth can narrow selected estimate bands, but expression and pose still affect visible landmarks.",
                    knowledgeID: "avfoundation-depth-data"
                )
            )
        }

        let widestBand = MetricKind.allCases.map { metric in
            let range = scan.range(for: metric)
            return range.high - range.low
        }.max() ?? 0
        if widestBand >= 12 {
            signals.append(
                TrueMaxIntelligenceSignal(
                    id: "capture-quality-band",
                    title: "Use a tighter capture for comparison",
                    detail: "At least one estimate band is wide. Even light, a centered pose, and the same distance can make your next comparison more useful.",
                    knowledgeID: "vision-face-capture-quality"
                )
            )
        }

        let textureWidth = scan.range(for: .skinTexture).high
            - scan.range(for: .skinTexture).low
        if textureWidth >= 12 {
            signals.append(
                TrueMaxIntelligenceSignal(
                    id: "texture-image-dependent",
                    title: "Treat texture as image-dependent",
                    detail: "Side light and camera processing can change visible texture; use the result to compare photos, not to assess skin health.",
                    knowledgeID: "apple-app-review-safety"
                )
            )
        }

        signals.append(
            TrueMaxIntelligenceSignal(
                id: "local-first-provenance",
                title: "Guidance adapts to your results",
                detail: "This guidance was selected from the bundled knowledge pack (\(TrueMaxKnowledgeBase.packVersion)).",
                knowledgeID: "nist-ai-rmf-1"
            )
        )

        return signals
    }
}

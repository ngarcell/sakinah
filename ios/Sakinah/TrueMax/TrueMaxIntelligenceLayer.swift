import Foundation

/// Versioned, local knowledge used by TrueMax's guidance rules. The app never
/// fetches face-related guidance at runtime: this keeps the privacy boundary
/// deterministic and makes every recommendation traceable to a reviewed source.
struct TrueMaxKnowledgeEntry: Identifiable, Hashable, Sendable {
    enum EvidenceGrade: String, Sendable {
        case platform
        case guardrail
    }

    let id: String
    let title: String
    let summary: String
    let sourceURL: URL
    let reviewedOn: String
    let evidenceGrade: EvidenceGrade
}

enum TrueMaxKnowledgeBase {
    static let revision = "2026-07-19"

    static let entries: [TrueMaxKnowledgeEntry] = [
        TrueMaxKnowledgeEntry(
            id: "vision-face-landmarks",
            title: "Vision face landmarks",
            summary: "Use landmark geometry for visible, image-dependent relationships; do not present it as clinical anatomy or an attractiveness score.",
            sourceURL: URL(string: "https://developer.apple.com/documentation/vision/detectfacelandmarksrequest")!,
            reviewedOn: revision,
            evidenceGrade: .platform
        ),
        TrueMaxKnowledgeEntry(
            id: "avfoundation-photo-capture",
            title: "AVFoundation photo capture",
            summary: "Treat each deliberate still capture as a new sample and preserve the user's lighting, pose, and framing guidance.",
            sourceURL: URL(string: "https://developer.apple.com/documentation/avfoundation/avcapturephotooutput")!,
            reviewedOn: revision,
            evidenceGrade: .platform
        ),
        TrueMaxKnowledgeEntry(
            id: "privacy-manifest",
            title: "Apple privacy manifest",
            summary: "Keep required-reason declarations and data-use statements aligned with the APIs and local-only storage actually used by the target.",
            sourceURL: URL(string: "https://developer.apple.com/documentation/bundleresources/privacy-manifest-files")!,
            reviewedOn: revision,
            evidenceGrade: .platform
        ),
        TrueMaxKnowledgeEntry(
            id: "cosmetic-safety-boundary",
            title: "Cosmetic guidance boundary",
            summary: "Recommendations are optional grooming and presentation experiments. They must not diagnose, rank people, or direct medical treatment.",
            sourceURL: URL(string: "https://developer.apple.com/app-store/review/guidelines/")!,
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
                    knowledgeID: "avfoundation-photo-capture"
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
                    knowledgeID: "cosmetic-safety-boundary"
                )
            )
        }

        signals.append(
            TrueMaxIntelligenceSignal(
                id: "local-first-provenance",
                title: "Your plan stays on-device",
                detail: "This guidance was selected from the bundled knowledge revision (TrueMaxKnowledgeBase.revision); no face data was sent to a model or service.",
                knowledgeID: "privacy-manifest"
            )
        )

        return signals
    }
}

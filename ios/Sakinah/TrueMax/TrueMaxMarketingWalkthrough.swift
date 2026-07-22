import Observation
import SwiftData
import SwiftUI
import UIKit

enum TrueMaxMarketingPhase: String, CaseIterable {
    case idle
    case home
    case homeScroll
    case scanChecklist
    case scanCapture
    case scanProcessing
    case scanResult
    case resultScroll
    case actionPlan
    case actionPlanAll
    case styles
    case styleCategory
    case stylePreview
    case styleFavorite
    case history
    case historySelect
    case historyFirst
    case historySecond
    case historyCompare
    case historyScroll
    case finished

    var caption: String {
        switch self {
        case .idle: return "Ready"
        case .home: return "Your private baseline, at a glance"
        case .homeScroll: return "Weekly guidance built from your scan"
        case .scanChecklist: return "A consistent capture starts here"
        case .scanCapture: return "Capturing a real demo scan"
        case .scanProcessing: return "Apple Vision analyzes it on device"
        case .scanResult: return "Honest measurement ranges—not a score"
        case .resultScroll: return "Five practical signals from one scan"
        case .actionPlan: return "A personalized plan for this week"
        case .actionPlanAll: return "Every recommendation stays actionable"
        case .styles: return "Styles matched to measured face structure"
        case .styleCategory: return "Explore recommendations by category"
        case .stylePreview: return "Preview a guide on your real capture"
        case .styleFavorite: return "Saved to favorites"
        case .history: return "Private progress stored on this iPhone"
        case .historySelect, .historyFirst, .historySecond: return "Select two real scans to compare"
        case .historyCompare: return "See grooming and measurement changes"
        case .historyScroll: return "Track progress without judging appearance"
        case .finished: return "Your baseline. Your plan. Your progress."
        }
    }

    var tapPosition: UnitPoint? {
        switch self {
        case .scanCapture: return UnitPoint(x: 0.50, y: 0.78)
        case .actionPlan: return UnitPoint(x: 0.50, y: 0.71)
        case .actionPlanAll: return UnitPoint(x: 0.72, y: 0.30)
        case .styleCategory: return UnitPoint(x: 0.57, y: 0.22)
        case .stylePreview: return UnitPoint(x: 0.28, y: 0.53)
        case .styleFavorite: return UnitPoint(x: 0.50, y: 0.76)
        case .historySelect: return UnitPoint(x: 0.87, y: 0.12)
        case .historyFirst: return UnitPoint(x: 0.50, y: 0.38)
        case .historySecond: return UnitPoint(x: 0.50, y: 0.66)
        case .historyCompare: return UnitPoint(x: 0.50, y: 0.80)
        default: return nil
        }
    }
}

@Observable
@MainActor
final class TrueMaxMarketingWalkthroughController {
    private struct Step {
        let phase: TrueMaxMarketingPhase
        let seconds: Double
    }

    private static let steps: [Step] = [
        Step(phase: .home, seconds: 2.6),
        Step(phase: .homeScroll, seconds: 2.2),
        Step(phase: .scanChecklist, seconds: 3.0),
        Step(phase: .scanCapture, seconds: 1.0),
        Step(phase: .scanProcessing, seconds: 4.2),
        Step(phase: .scanResult, seconds: 3.6),
        Step(phase: .resultScroll, seconds: 2.7),
        Step(phase: .actionPlan, seconds: 3.0),
        Step(phase: .actionPlanAll, seconds: 3.2),
        Step(phase: .styles, seconds: 3.0),
        Step(phase: .styleCategory, seconds: 2.0),
        Step(phase: .stylePreview, seconds: 3.2),
        Step(phase: .styleFavorite, seconds: 2.2),
        Step(phase: .history, seconds: 2.4),
        Step(phase: .historySelect, seconds: 1.0),
        Step(phase: .historyFirst, seconds: 1.0),
        Step(phase: .historySecond, seconds: 1.2),
        Step(phase: .historyCompare, seconds: 3.6),
        Step(phase: .historyScroll, seconds: 3.2),
        Step(phase: .finished, seconds: 3.0),
    ]

    var phase: TrueMaxMarketingPhase = .idle
    var showsLauncher = false
    var isPlaying = false
    var isPaused = false
    private(set) var progress = 0.0

    @ObservationIgnored private var playbackTask: Task<Void, Never>?
    @ObservationIgnored private var stepIndex = 0

    nonisolated init() {}

    func presentLauncher() {
        stop()
        showsLauncher = true
    }

    func start() {
        stop()
        showsLauncher = false
        isPlaying = true
        stepIndex = 0
        runFromCurrentStep()
    }

    func replay() { start() }

    func togglePause() {
        guard isPlaying else { return }
        isPaused.toggle()
        if isPaused {
            playbackTask?.cancel()
        } else {
            runFromCurrentStep()
        }
    }

    func stop() {
        playbackTask?.cancel()
        playbackTask = nil
        phase = .idle
        isPlaying = false
        isPaused = false
        progress = 0
        stepIndex = 0
    }

    private func runFromCurrentStep() {
        playbackTask?.cancel()
        playbackTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while stepIndex < Self.steps.count, !Task.isCancelled {
                let step = Self.steps[stepIndex]
                phase = step.phase
                progress = Double(stepIndex) / Double(Self.steps.count)
                do {
                    try await Task.sleep(for: .seconds(step.seconds))
                } catch { return }
                stepIndex += 1
            }
            guard !Task.isCancelled else { return }
            progress = 1
            isPlaying = false
            isPaused = false
        }
    }
}

@MainActor
enum TrueMaxMarketingSeed {
    static let olderID = UUID(uuidString: "7A49FB8C-2791-438B-B4DB-626F32D9D15B")!
    static let currentID = UUID(uuidString: "DE442953-00D8-44CB-8186-C6BB676E172B")!

    static func prepare(in context: ModelContext) throws {
        try removeDemoScans(in: context)
        guard let image = UIImage(named: "TrueMaxDemoEarlier") else {
            throw TrueMaxMarketingSeedError.missingImage("TrueMaxDemoEarlier")
        }
        let filename = try TrueMaxStorage.saveCapture(image, id: olderID)
        let date = Calendar.current.date(byAdding: .day, value: -28, to: Date()) ?? Date()
        context.insert(ScanRecord(id: olderID, createdAt: date, imageFilename: filename, analysis: olderAnalysis))
        try context.save()
    }

    static func fallbackCurrentAnalysis() -> TrueMaxAnalysisResult {
        TrueMaxAnalysisResult(
            captureMode: .photo2D,
            confidence: .estimated,
            symmetry: .init(low: 76, high: 84, unit: .index),
            proportion: .init(low: 72, high: 82, unit: .index),
            canthalTilt: .init(low: 3.2, high: 6.8, unit: .degrees),
            jawAngle: .init(low: 118, high: 126, unit: .degrees),
            skinTexture: .init(low: 70, high: 80, unit: .index),
            guidance: demoGuidance,
            qualityNote: "Photo mode estimates visible 2D landmarks only. The demo capture is processed and stored locally on this simulator."
        )
    }

    private static var olderAnalysis: TrueMaxAnalysisResult {
        TrueMaxAnalysisResult(
            captureMode: .photo2D,
            confidence: .estimated,
            symmetry: .init(low: 72, high: 81, unit: .index),
            proportion: .init(low: 68, high: 78, unit: .index),
            canthalTilt: .init(low: 2.6, high: 6.4, unit: .degrees),
            jawAngle: .init(low: 116, high: 125, unit: .degrees),
            skinTexture: .init(low: 64, high: 75, unit: .index),
            guidance: demoGuidance,
            qualityNote: "Photo mode estimates visible 2D landmarks only. Consistent lighting and camera distance make comparisons more useful."
        )
    }

    private static var demoGuidance: [GuidanceItem] {
        [
            GuidanceItem(category: .presentation, priority: "Start here", title: "Keep every scan comparable", detail: "Use soft front light, a relaxed expression, and the same camera distance each week."),
            GuidanceItem(category: .hair, priority: "This week", title: "Try a textured crop", detail: "A little controlled lift adds shape while keeping the forehead open."),
            GuidanceItem(category: .style, priority: "Next", title: "Refine the beard line", detail: "Keep the cheek line natural and clean the neckline for more deliberate framing."),
            GuidanceItem(category: .skin, priority: "Keep in mind", title: "Use even light for texture", detail: "Side lighting and camera sharpening can exaggerate visible texture."),
            GuidanceItem(category: .style, priority: "Optional", title: "Compare one change at a time", detail: "Keep your pose and expression constant when testing a new style."),
        ]
    }

    private static func removeDemoScans(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<ScanRecord>()
        for scan in try context.fetch(descriptor) where scan.id == olderID || scan.id == currentID {
            _ = TrueMaxStorage.deleteCapture(filename: scan.imageFilename)
            context.delete(scan)
        }
        try context.save()
    }
}

enum TrueMaxMarketingSeedError: LocalizedError {
    case missingImage(String)
    var errorDescription: String? {
        switch self { case let .missingImage(name): return "The bundled demo image \(name) is missing." }
    }
}

struct TrueMaxMarketingLauncherView: View {
    let onPlay: () -> Void
    let onExplore: () -> Void

    var body: some View {
        ZStack {
            TrueMaxPageBackground()
            ScrollView {
                VStack(spacing: 24) {
                    TrueMaxBrandLockup()
                    ZStack(alignment: .bottomLeading) {
                        Image("TrueMaxDemoCurrent")
                            .resizable().scaledToFill()
                            .frame(maxWidth: .infinity).frame(height: 390).clipped()
                        LinearGradient(colors: [.clear, .black.opacity(0.88)], startPoint: .center, endPoint: .bottom)
                        VStack(alignment: .leading, spacing: 7) {
                            Text("SEE TRUEMAX IN ACTION").font(.caption.weight(.bold)).tracking(1.4).foregroundStyle(TrueMaxPalette.accentLight)
                            Text("One scan. A practical plan. Progress you can see.")
                                .font(.title2.weight(.bold)).fontDesign(.rounded).foregroundStyle(.white)
                        }.padding(20)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(TrueMaxPalette.border) }

                    VStack(spacing: 12) {
                        Button(action: onPlay) { Label("Play 55-second walkthrough", systemImage: "play.fill") }
                            .buttonStyle(TrueMaxPrimaryButtonStyle())
                        Button("Explore on my own", action: onExplore)
                            .buttonStyle(TrueMaxSecondaryButtonStyle())
                    }
                    Label("Live simulator interactions · On-device analysis · Replay anytime", systemImage: "iphone.gen3")
                        .font(.footnote).foregroundStyle(TrueMaxPalette.textTertiary).multilineTextAlignment(.center)
                }
                .padding(20).padding(.top, 12).trueMaxContentWidth()
            }.scrollIndicators(.hidden)
        }
    }
}

struct TrueMaxMarketingPlaybackOverlay: View {
    @Environment(TrueMaxMarketingWalkthroughController.self) private var demo

    var body: some View {
        if demo.isPlaying || demo.phase == .finished {
            ZStack {
                if let point = demo.phase.tapPosition {
                    GeometryReader { geometry in
                        TrueMaxMarketingTapPulse()
                            .position(
                                x: geometry.size.width * point.x,
                                y: geometry.size.height * point.y
                            )
                    }
                    .id(demo.phase)
                    .allowsHitTesting(false)
                }

                VStack {
                    Spacer()
                    VStack(spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles").foregroundStyle(TrueMaxPalette.accentLight)
                            Text(demo.phase.caption).font(.subheadline.weight(.semibold)).foregroundStyle(.white).lineLimit(2)
                            Spacer()
                            Button { demo.togglePause() } label: {
                                Image(systemName: demo.isPaused ? "play.fill" : "pause.fill")
                            }.foregroundStyle(.white).accessibilityLabel(demo.isPaused ? "Resume walkthrough" : "Pause walkthrough")
                            Button { demo.replay() } label: { Image(systemName: "arrow.clockwise") }
                                .foregroundStyle(.white).accessibilityLabel("Replay walkthrough")
                        }
                        ProgressView(value: demo.progress).tint(TrueMaxPalette.accentLight)
                    }
                    .padding(14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                    .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(Color.white.opacity(0.18)) }
                    .padding(.horizontal, 14).padding(.bottom, 58)
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .allowsHitTesting(true)
        }
    }
}

private struct TrueMaxMarketingTapPulse: View {
    @State private var expands = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(expands ? 0 : 0.9), lineWidth: 2)
                .frame(width: expands ? 58 : 24, height: expands ? 58 : 24)
            Circle()
                .fill(Color.white.opacity(0.94))
                .frame(width: 16, height: 16)
                .shadow(color: TrueMaxPalette.accentLight, radius: 7)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.75).repeatForever(autoreverses: false)) {
                expands = true
            }
        }
        .accessibilityHidden(true)
    }
}

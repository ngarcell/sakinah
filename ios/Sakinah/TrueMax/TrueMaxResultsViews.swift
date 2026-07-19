import Foundation
import SwiftUI

struct TrueMaxResultDetailView: View {
    @Environment(TrueMaxAppState.self) private var appState
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let scan: ScanRecord
    var showsResultReveal = true
    var onDone: (() -> Void)?

    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible())]
        }
        return [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ]
    }

    var body: some View {
        ZStack {
            TrueMaxPageBackground()

            ScrollView {
                VStack(spacing: 22) {
                    if showsResultReveal {
                        revealHeader
                    }

                    captureCard

                    VStack(spacing: 8) {
                        Text(showsResultReveal ? "A clear starting point." : "Your measurements")
                            .font(.title.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(TrueMaxPalette.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Measurements are shown as ranges because lighting, expression, and capture angle naturally vary.")
                            .font(.body)
                            .foregroundStyle(TrueMaxPalette.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(MetricKind.allCases) { metric in
                            NavigationLink {
                                TrueMaxMetricDetailView(metric: metric, scan: scan)
                            } label: {
                                ResultMetricCard(
                                    metric: metric,
                                    range: scan.range(for: metric)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    NavigationLink {
                        TrueMaxActionPlanView(scan: scan)
                    } label: {
                        HStack {
                            Label("View your action plan", systemImage: "list.bullet.clipboard")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                    .buttonStyle(TrueMaxPrimaryButtonStyle())

                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(TrueMaxPalette.positive)
                        Text("Saved privately to History")
                            .font(.subheadline)
                            .foregroundStyle(TrueMaxPalette.textSecondary)
                    }

                    Text(scan.qualityNote)
                        .font(.footnote)
                        .foregroundStyle(TrueMaxPalette.textTertiary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 22)
                }
                .padding(.horizontal, 20)
                .trueMaxContentWidth()
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(showsResultReveal ? "Your baseline" : scan.createdAt.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsResultReveal {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        if let onDone {
                            onDone()
                        } else {
                            appState.selectedTab = .home
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var revealHeader: some View {
        TrueMaxPill(
            icon: scan.captureMode == .depth3D ? "cube" : "camera",
            text: "\(scan.captureMode.title) · \(scan.confidence.title)"
        )
        .padding(.top, 8)
    }

    private var captureCard: some View {
        Group {
            if let image = TrueMaxStorage.image(filename: scan.imageFilename) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay {
                        FaceGuideOverlay()
                            .padding(32)
                    }
                    .accessibilityLabel("Facial capture with neutral measurement guide")
            } else {
                FaceMeshIllustration(mode: scan.captureMode)
                    .frame(height: 340)
                    .padding(24)
                    .background(
                        TrueMaxPalette.backgroundRaised,
                        in: RoundedRectangle(cornerRadius: 20)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(TrueMaxPalette.border)
                    }
                    .accessibilityLabel("Geometric facial analysis illustration")
            }
        }
    }
}

struct TrueMaxMetricDetailView: View {
    let metric: MetricKind
    let scan: ScanRecord

    @State private var showsMethodology = false

    var body: some View {
        ZStack {
            TrueMaxPageBackground()

            ScrollView {
                VStack(spacing: 22) {
                    TrueMaxPill(
                        icon: scan.captureMode == .depth3D ? "cube" : "camera",
                        text: scan.captureMode.badgeTitle
                    )

                    Text(scan.range(for: metric).displayText)
                        .font(.largeTitle.weight(.light))
                        .fontDesign(.rounded)
                        .monospacedDigit()
                        .foregroundStyle(TrueMaxPalette.accentLight)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(scan.range(for: metric).accessibilityText)

                    Text(scan.confidence.title + " band")
                        .font(.title3)
                        .foregroundStyle(TrueMaxPalette.textSecondary)

                    ZStack {
                        if let image = TrueMaxStorage.image(filename: scan.imageFilename) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 410)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .saturation(0.15)
                        } else {
                            FaceMeshIllustration(mode: scan.captureMode)
                                .frame(height: 350)
                        }

                        FaceGuideOverlay()
                            .padding(34)
                    }

                    MetricExplanationCard(
                        symbol: "info.circle",
                        title: "What this measures",
                        detail: metric.summary
                    )

                    MetricExplanationCard(
                        symbol: "questionmark.circle",
                        title: "Why a range?",
                        detail: rangeReason
                    )

                    Button {
                        showsMethodology.toggle()
                    } label: {
                        HStack(spacing: 14) {
                            TrueMaxIconCircle(symbol: "book.closed", size: 46)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("View methodology")
                                    .font(.headline)
                                    .foregroundStyle(TrueMaxPalette.accentLight)
                                if showsMethodology {
                                    Text(metric.methodology)
                                        .font(.subheadline)
                                        .foregroundStyle(TrueMaxPalette.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Spacer()
                            Image(systemName: showsMethodology ? "chevron.up" : "chevron.down")
                                .foregroundStyle(TrueMaxPalette.textTertiary)
                        }
                        .trueMaxCard()
                    }
                    .buttonStyle(.plain)

                    Text("This is a cosmetic estimate from one capture, not a clinical measurement or attractiveness score.")
                        .font(.footnote)
                        .foregroundStyle(TrueMaxPalette.textTertiary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .trueMaxContentWidth()
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(metric.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var rangeReason: String {
        if scan.captureMode == .photo2D {
            return "Photo mode uses a wider interval because depth, angle, lighting, and landmark visibility cannot be fully separated in a flat image."
        }
        return "Natural expression, sensor sampling, and capture angle create small variation. A range is more honest than a single precise-looking number."
    }
}

struct TrueMaxActionPlanView: View {
    let scan: ScanRecord

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showsAll = false

    var body: some View {
        ZStack {
            TrueMaxPageBackground()

            ScrollView {
                VStack(spacing: 18) {
                    Group {
                        if dynamicTypeSize.isAccessibilitySize {
                            VStack(alignment: .leading, spacing: 12) {
                                actionPlanHeaderContent
                            }
                        } else {
                            HStack(spacing: 18) {
                                actionPlanHeaderContent
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .trueMaxCard(elevated: true)

                    Picker("Plan range", selection: $showsAll) {
                        Text("This week").tag(false)
                        Text("All").tag(true)
                    }
                    .pickerStyle(.segmented)

                    ForEach(Array(visibleGuidance.enumerated()), id: \.element.id) { index, item in
                        GuidanceCard(index: index + 1, item: item)
                    }

                    ForEach(TrueMaxIntelligenceEngine.signals(for: scan)) { signal in
                        IntelligenceSignalCard(signal: signal)
                    }

                    if scan.guidance.isEmpty {
                        TrueMaxEmptyState(
                            symbol: "list.bullet.clipboard",
                            title: "Your plan is being prepared",
                            message: "Try another well-lit capture to generate practical local guidance."
                        )
                    }

                    Label(
                        "Guidance is cosmetic and informational—not medical advice.",
                        systemImage: "shield.lefthalf.filled"
                    )
                    .font(.footnote)
                    .foregroundStyle(TrueMaxPalette.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .trueMaxContentWidth()
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Your action plan")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var visibleGuidance: [GuidanceItem] {
        showsAll ? scan.guidance : Array(scan.guidance.prefix(3))
    }

    @ViewBuilder
    private var actionPlanHeaderContent: some View {
        TrueMaxIconCircle(symbol: "scope", size: 68)
        VStack(alignment: .leading, spacing: 7) {
            Text("Built from your baseline")
                .font(.title2.weight(.bold))
                .foregroundStyle(TrueMaxPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Start with the highest-impact, lowest-effort changes.")
                .font(.body)
                .foregroundStyle(TrueMaxPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ResultMetricCard: View {
    let metric: MetricKind
    let range: MetricRangeValue

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                TrueMaxIconCircle(symbol: metric.symbol, size: 40)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(TrueMaxPalette.textTertiary)
            }
            Text(metric.title)
                .font(.subheadline)
                .foregroundStyle(TrueMaxPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Divider().overlay(TrueMaxPalette.border)
            Text(range.displayText)
                .font(.title.weight(.medium))
                .fontDesign(.rounded)
                .monospacedDigit()
                .foregroundStyle(TrueMaxPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 158, alignment: .leading)
        .trueMaxCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metric.title), \(range.accessibilityText)")
    }
}

private struct MetricExplanationCard: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            TrueMaxIconCircle(symbol: symbol, size: 46)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(TrueMaxPalette.textPrimary)
                Text(detail)
                    .font(.body)
                    .foregroundStyle(TrueMaxPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .trueMaxCard()
    }
}

private struct GuidanceCard: View {
    let index: Int
    let item: GuidanceItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(String(format: "%02d", index))
                .font(.title3.weight(.bold))
                .foregroundStyle(TrueMaxPalette.accentLight)
                .frame(width: 48, height: 48)
                .overlay {
                    Circle().strokeBorder(TrueMaxPalette.accentLight, lineWidth: 1.5)
                }

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text(item.category.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TrueMaxPalette.textSecondary)
                    Text(item.priority)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(TrueMaxPalette.accentLight)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(TrueMaxPalette.accent.opacity(0.10), in: Capsule())
                    Spacer()
                    Image(systemName: item.category.symbol)
                        .foregroundStyle(TrueMaxPalette.accentLight)
                }

                Text(item.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(TrueMaxPalette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.detail)
                    .font(.body)
                    .foregroundStyle(TrueMaxPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .trueMaxCard()
    }
}

private struct IntelligenceSignalCard: View {
    let signal: TrueMaxIntelligenceSignal

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            TrueMaxIconCircle(symbol: "brain.head.profile", size: 42)
            VStack(alignment: .leading, spacing: 5) {
                Text(signal.title)
                    .font(.headline)
                    .foregroundStyle(TrueMaxPalette.textPrimary)
                Text(signal.detail)
                    .font(.subheadline)
                    .foregroundStyle(TrueMaxPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let source = TrueMaxKnowledgeBase.entry(signal.knowledgeID) {
                    Text("Source: \(source.publisher) · \(source.title) · reviewed \(source.reviewedOn)")
                        .font(.caption)
                        .foregroundStyle(TrueMaxPalette.textTertiary)
                }
            }
            Spacer(minLength: 0)
        }
        .trueMaxCard()
        .accessibilityElement(children: .combine)
    }
}

private struct FaceGuideOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            Path { path in
                path.move(to: CGPoint(x: width * 0.5, y: height * 0.08))
                path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.90))
                path.move(to: CGPoint(x: width * 0.18, y: height * 0.38))
                path.addLine(to: CGPoint(x: width * 0.82, y: height * 0.38))
                path.move(to: CGPoint(x: width * 0.22, y: height * 0.58))
                path.addLine(to: CGPoint(x: width * 0.78, y: height * 0.58))
                path.move(to: CGPoint(x: width * 0.30, y: height * 0.74))
                path.addLine(to: CGPoint(x: width * 0.70, y: height * 0.74))
            }
            .stroke(
                TrueMaxPalette.accentLight.opacity(0.76),
                style: StrokeStyle(lineWidth: 1, dash: [5, 4])
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

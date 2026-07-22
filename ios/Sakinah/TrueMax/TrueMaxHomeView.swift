import SwiftData
import SwiftUI

struct TrueMaxHomeView: View {
    @Environment(TrueMaxAppState.self) private var appState
    @Environment(TrueMaxMarketingWalkthroughController.self) private var demo
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \ScanRecord.createdAt, order: .reverse) private var scans: [ScanRecord]
    @State private var showsDemoStyles = false

    var body: some View {
        ZStack {
            TrueMaxPageBackground()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        homeHeader.id("home-top")

                        if let latest = scans.first {
                            returningHome(latest)
                        } else {
                            firstScanHome
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                    .trueMaxContentWidth()
                }
                .scrollIndicators(.hidden)
                .onChange(of: demo.phase) { _, phase in
                    switch phase {
                    case .home:
                        withAnimation(.easeInOut(duration: 0.7)) { proxy.scrollTo("home-top", anchor: .top) }
                    case .homeScroll:
                        withAnimation(.easeInOut(duration: 1.1)) { proxy.scrollTo("home-tools", anchor: .center) }
                    case .styles:
                        showsDemoStyles = scans.first != nil
                    case .history, .finished:
                        showsDemoStyles = false
                    default:
                        break
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            TrueMaxAnalytics.shared.screen("home", properties: [
                "scan_count": scans.count,
                "has_baseline": !scans.isEmpty
            ])
        }
        .navigationDestination(isPresented: $showsDemoStyles) {
            if let latest = scans.first {
                TrueMaxStyleLibraryView(scan: latest)
            }
        }
    }

    private var homeHeader: some View {
        TrueMaxBrandLockup(compact: true)
    }

    private var firstScanHome: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ready for your baseline?")
                    .font(.title2.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(TrueMaxPalette.textPrimary)
                Text("Let’s establish your starting point and build a plan that’s right for you.")
                    .font(.title3)
                    .foregroundStyle(TrueMaxPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 18) {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 12) {
                            firstScanCardContent
                        }
                    } else {
                        HStack(alignment: .top, spacing: 8) {
                            firstScanCardContent
                        }
                    }
                }

                Button {
                    appState.startScan()
                } label: {
                    Label("Start first scan", systemImage: "viewfinder")
                }
                .buttonStyle(TrueMaxPrimaryButtonStyle())

                Text("About 60 seconds")
                    .font(.footnote)
                    .foregroundStyle(TrueMaxPalette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .trueMaxCard(elevated: true)

            VStack(alignment: .leading, spacing: 8) {
                Text("What you’ll get")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(TrueMaxPalette.textPrimary)
                Text("Insights to improve with confidence.")
                    .font(.body)
                    .foregroundStyle(TrueMaxPalette.textSecondary)
            }

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: 10) {
                        benefitCards
                    }
                } else {
                    HStack(alignment: .top, spacing: 10) {
                        benefitCards
                    }
                }
            }
            .id("home-tools")
        }
    }

    private func returningHome(_ latest: ScanRecord) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(greeting)
                .font(.title2.weight(.bold))
                .fontDesign(.rounded)
                .foregroundStyle(TrueMaxPalette.textPrimary)

            NavigationLink {
                TrueMaxResultDetailView(scan: latest, showsResultReveal: false)
            } label: {
                LatestResultCard(scan: latest)
            }
            .buttonStyle(.plain)

            Button {
                appState.startScan()
            } label: {
                HStack {
                    Label("New scan", systemImage: "viewfinder")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
            .buttonStyle(TrueMaxPrimaryButtonStyle())

            if !latest.guidance.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Focus this week")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(TrueMaxPalette.textPrimary)

                    ForEach(latest.guidance.prefix(3)) { item in
                        HStack(spacing: 14) {
                            TrueMaxIconCircle(
                                symbol: item.category.symbol,
                                size: 48
                            )
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.category.title)
                                    .font(.headline)
                                    .foregroundStyle(TrueMaxPalette.textPrimary)
                                Text(item.title)
                                    .font(.subheadline)
                                    .foregroundStyle(TrueMaxPalette.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(TrueMaxPalette.textTertiary)
                        }
                        .trueMaxCard()
                    }
                }
            }

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: 12) {
                        quickTools(for: latest)
                    }
                } else {
                    HStack(spacing: 12) {
                        quickTools(for: latest)
                    }
                }
            }
            .id("home-tools")

            nextScanSuggestion(for: latest)
        }
    }

    private func nextScanSuggestion(for latest: ScanRecord) -> some View {
        let nextDate = Calendar.current.date(
            byAdding: .day,
            value: appState.cooldownDays,
            to: latest.createdAt
        ) ?? latest.createdAt
        let days = max(
            0,
            Calendar.current.dateComponents(
                [.day],
                from: Calendar.current.startOfDay(for: Date()),
                to: Calendar.current.startOfDay(for: nextDate)
            ).day ?? 0
        )

        return Label(
            days == 0
                ? "Ready for a new check-in"
                : "Next suggested check-in in \(days) \(days == 1 ? "day" : "days")",
            systemImage: "calendar.badge.clock"
        )
        .font(.subheadline.weight(.medium))
        .foregroundStyle(TrueMaxPalette.textSecondary)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .trueMaxCard()
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<18:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }

    @ViewBuilder
    private var firstScanCardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Start your first scan")
                .font(.title.weight(.bold))
                .fontDesign(.rounded)
                .foregroundStyle(TrueMaxPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Capture key data to measure what matters and track progress.")
                .font(.body)
                .foregroundStyle(TrueMaxPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }

        FaceMeshIllustration()
            .frame(maxWidth: .infinity)
            .frame(height: 210)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var benefitCards: some View {
        BenefitCard(
            symbol: "face.dashed",
            title: "Structure",
            detail: "Facial geometry and proportions."
        )
        BenefitCard(
            symbol: "circle.grid.3x3",
            title: "Skin & hair",
            detail: "Visible surface and style cues."
        )
        BenefitCard(
            symbol: "checklist",
            title: "Action plan",
            detail: "Practical personal steps."
        )
    }

    @ViewBuilder
    private func quickTools(for scan: ScanRecord) -> some View {
        NavigationLink {
            TrueMaxStyleLibraryView(scan: scan)
        } label: {
            QuickToolCard(
                symbol: "scissors",
                title: "Styles",
                detail: "Explore hair"
            )
        }
        .buttonStyle(.plain)

        NavigationLink {
            TrueMaxColorAnalysisView(scan: scan)
        } label: {
            QuickToolCard(
                symbol: "paintpalette",
                title: "Colors",
                detail: "Find your palette"
            )
        }
        .buttonStyle(.plain)
    }
}

private struct LatestResultCard: View {
    let scan: ScanRecord

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 8) {
                        latestTitle
                        TrueMaxPill(
                            icon: scan.captureMode == .depth3D ? "cube" : "camera",
                            text: scan.captureMode.title
                        )
                    }
                } else {
                    HStack {
                        latestTitle
                        Spacer()
                        TrueMaxPill(
                            icon: scan.captureMode == .depth3D ? "cube" : "camera",
                            text: scan.captureMode.title
                        )
                    }
                }
            }

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 16) {
                        latestImage
                        latestMetrics
                    }
                } else {
                    HStack(spacing: 16) {
                        latestImage
                        latestMetrics
                    }
                }
            }

            Divider().overlay(TrueMaxPalette.border)

            HStack {
                Spacer()
                Text("View full analysis")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TrueMaxPalette.accentLight)
                Image(systemName: "chevron.right")
                    .foregroundStyle(TrueMaxPalette.accentLight)
            }
        }
        .trueMaxCard(elevated: true)
    }

    private var latestTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Your latest baseline")
                .font(.title3.weight(.bold))
                .foregroundStyle(TrueMaxPalette.textPrimary)
            Text(scan.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(TrueMaxPalette.textSecondary)
        }
    }

    @ViewBuilder
    private var latestImage: some View {
        if let image = TrueMaxStorage.image(filename: scan.imageFilename) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 132, height: 172)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .accessibilityLabel("Your latest facial capture")
        } else {
            FaceMeshIllustration(mode: scan.captureMode)
                .frame(width: 132, height: 172)
                .background(
                    TrueMaxPalette.backgroundRaised,
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .accessibilityHidden(true)
        }
    }

    private var latestMetrics: some View {
        VStack(spacing: 12) {
            HomeMetricRow(
                metric: .symmetry,
                range: scan.range(for: .symmetry)
            )
            HomeMetricRow(
                metric: .proportion,
                range: scan.range(for: .proportion)
            )
            HomeMetricRow(
                metric: .jawAngle,
                range: scan.range(for: .jawAngle)
            )
        }
    }
}

private struct HomeMetricRow: View {
    let metric: MetricKind
    let range: MetricRangeValue

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: metric.symbol)
                .font(.subheadline)
                .foregroundStyle(TrueMaxPalette.accentLight)
                .frame(width: 32, height: 32)
                .background(TrueMaxPalette.accent.opacity(0.10), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(metric.shortTitle)
                    .font(.caption)
                    .foregroundStyle(TrueMaxPalette.textSecondary)
                Text(range.displayText)
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(TrueMaxPalette.textPrimary)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct BenefitCard: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(TrueMaxPalette.accentLight)
                .frame(width: 46, height: 46)
                .background(TrueMaxPalette.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(TrueMaxPalette.textPrimary)
            Text(detail)
                .font(.caption)
                .foregroundStyle(TrueMaxPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(TrueMaxPalette.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(TrueMaxPalette.border)
        }
    }
}

private struct QuickToolCard: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TrueMaxIconCircle(symbol: symbol, size: 44)
            Text(title)
                .font(.headline)
                .foregroundStyle(TrueMaxPalette.textPrimary)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(TrueMaxPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trueMaxCard()
    }
}

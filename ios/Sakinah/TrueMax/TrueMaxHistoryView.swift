import Foundation
import SwiftData
import SwiftUI

struct TrueMaxHistoryView: View {
    private enum Filter: String, CaseIterable, Identifiable {
        case all = "All scans"
        case depth = "3D"
        case photo = "Photo"

        var id: String { rawValue }
    }

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScanRecord.createdAt, order: .reverse) private var scans: [ScanRecord]

    @State private var filter: Filter = .all
    @State private var isSelecting = false
    @State private var selectedIDs = Set<UUID>()
    @State private var showsComparison = false
    @State private var scanPendingDeletion: ScanRecord?
    @State private var showsDeleteConfirmation = false
    @State private var deletionNotice: HistoryDeletionNotice?

    var body: some View {
        ZStack {
            TrueMaxPageBackground()

            ScrollView {
                VStack(spacing: 20) {
                    header

                    Text("Your private progress, stored on this iPhone.")
                        .font(.body)
                        .foregroundStyle(TrueMaxPalette.textSecondary)
                        .multilineTextAlignment(.center)

                    filterBar

                    if filteredScans.isEmpty {
                        TrueMaxEmptyState(
                            symbol: "clock",
                            title: scans.isEmpty ? "No scans yet" : "No matching scans",
                            message: scans.isEmpty
                                ? "Complete your first private scan to build a local timeline."
                                : "Choose a different capture filter."
                        )
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(filteredScans) { scan in
                                if isSelecting {
                                    Button {
                                        toggle(scan)
                                    } label: {
                                        HistoryScanCard(
                                            scan: scan,
                                            isSelected: selectedIDs.contains(scan.id)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    NavigationLink {
                                        TrueMaxResultDetailView(
                                            scan: scan,
                                            showsResultReveal: false
                                        )
                                    } label: {
                                        HistoryScanCard(scan: scan)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            requestDeletion(of: scan)
                                        } label: {
                                            Label("Delete scan", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if isSelecting {
                        selectionFooter
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 28)
                .trueMaxContentWidth()
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showsComparison) {
            if comparisonScans.count == 2 {
                TrueMaxComparisonView(
                    older: comparisonScans[1],
                    newer: comparisonScans[0]
                )
            }
        }
        .confirmationDialog(
            "Delete this scan?",
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible,
            presenting: scanPendingDeletion
        ) { scan in
            Button("Delete scan", role: .destructive) {
                delete(scan)
            }
            Button("Cancel", role: .cancel) {
                scanPendingDeletion = nil
            }
        } message: { scan in
            Text(
                "This permanently removes the scan from \(scan.createdAt.formatted(date: .abbreviated, time: .shortened)) and its saved photo from this iPhone."
            )
        }
        .alert(item: $deletionNotice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var header: some View {
        HStack {
            Color.clear.frame(width: 58)
            Spacer()
            Text("History")
                .font(.title2.weight(.bold))
                .foregroundStyle(TrueMaxPalette.textPrimary)
            Spacer()
            Button(isSelecting ? "Done" : "Select") {
                isSelecting.toggle()
                selectedIDs.removeAll()
            }
            .font(.body.weight(.semibold))
            .frame(width: 58, alignment: .trailing)
        }
    }

    private var filterBar: some View {
        HStack(spacing: 10) {
            ForEach(Filter.allCases) { option in
                Button {
                    filter = option
                    selectedIDs = selectedIDs.intersection(
                        Set(filteredScans.map(\.id))
                    )
                } label: {
                    Label(
                        option.rawValue,
                        systemImage: filterSymbol(option)
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        filter == option
                            ? TrueMaxPalette.accentLight
                            : TrueMaxPalette.textSecondary
                    )
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                    .background(
                        filter == option
                            ? TrueMaxPalette.accent.opacity(0.10)
                            : TrueMaxPalette.card,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                filter == option
                                    ? TrueMaxPalette.accentLight
                                    : TrueMaxPalette.border,
                                lineWidth: filter == option ? 1.5 : 1
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var selectionFooter: some View {
        VStack(spacing: 10) {
            Text(
                selectedIDs.count < 2
                    ? "Select two scans to compare"
                    : "Two scans selected"
            )
            .font(.subheadline)
            .foregroundStyle(TrueMaxPalette.textSecondary)

            Button {
                showsComparison = comparisonScans.count == 2
            } label: {
                Label("Compare selected scans", systemImage: "rectangle.split.2x1")
            }
            .buttonStyle(TrueMaxPrimaryButtonStyle())
            .disabled(comparisonScans.count != 2)
        }
        .padding(.top, 8)
    }

    private var filteredScans: [ScanRecord] {
        switch filter {
        case .all:
            return scans
        case .depth:
            return scans.filter { $0.captureMode == .depth3D }
        case .photo:
            return scans.filter { $0.captureMode == .photo2D }
        }
    }

    private var comparisonScans: [ScanRecord] {
        scans.filter { selectedIDs.contains($0.id) }.prefix(2).map { $0 }
    }

    private func filterSymbol(_ filter: Filter) -> String {
        switch filter {
        case .all:
            return "square.stack.3d.up"
        case .depth:
            return "cube"
        case .photo:
            return "camera"
        }
    }

    private func toggle(_ scan: ScanRecord) {
        if selectedIDs.contains(scan.id) {
            selectedIDs.remove(scan.id)
        } else if selectedIDs.count < 2 {
            selectedIDs.insert(scan.id)
        }
    }

    private func requestDeletion(of scan: ScanRecord) {
        scanPendingDeletion = scan
        showsDeleteConfirmation = true
    }

    private func delete(_ scan: ScanRecord) {
        let scanID = scan.id
        let imageFilename = scan.imageFilename
        scanPendingDeletion = nil
        modelContext.delete(scan)

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            deletionNotice = HistoryDeletionNotice(
                title: "Scan wasn’t deleted",
                message: "TrueMax could not save the database deletion, so it did not attempt to remove the protected photo. Database error: \(error.localizedDescription)"
            )
            return
        }

        selectedIDs.remove(scanID)

        if case let .failure(error) = TrueMaxStorage.deleteCapture(
            filename: imageFilename
        ) {
            deletionNotice = HistoryDeletionNotice(
                title: "Photo cleanup incomplete",
                message: "The scan record was deleted, but its protected photo file could not be removed. \(error.localizedDescription) Use Delete all TrueMax data in Settings to retry cleanup."
            )
        }
    }
}

private struct HistoryDeletionNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct TrueMaxComparisonView: View {
    @State private var leftScan: ScanRecord
    @State private var rightScan: ScanRecord

    init(older: ScanRecord, newer: ScanRecord) {
        _leftScan = State(initialValue: older)
        _rightScan = State(initialValue: newer)
    }

    var body: some View {
        ZStack {
            TrueMaxPageBackground()

            ScrollView {
                VStack(spacing: 20) {
                    scanSelectors
                    imageComparison

                    VStack(alignment: .leading, spacing: 14) {
                        Text("What changed")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(TrueMaxPalette.textPrimary)

                        ForEach(MetricKind.allCases) { metric in
                            ComparisonMetricRow(
                                metric: metric,
                                left: leftScan.range(for: metric),
                                right: rightScan.range(for: metric)
                            )
                        }
                    }

                    Label(
                        "Lighting, expression, grooming, and capture angle can affect visible change.",
                        systemImage: "info.circle"
                    )
                    .font(.footnote)
                    .foregroundStyle(TrueMaxPalette.neutral)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 22)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .trueMaxContentWidth()
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Swap") {
                    let oldLeft = leftScan
                    leftScan = rightScan
                    rightScan = oldLeft
                }
            }
        }
    }

    private var scanSelectors: some View {
        HStack(spacing: 12) {
            ComparisonDateChip(date: leftScan.createdAt)
            Image(systemName: "arrow.right")
                .foregroundStyle(TrueMaxPalette.textTertiary)
            ComparisonDateChip(date: rightScan.createdAt)
        }
    }

    private var imageComparison: some View {
        HStack(spacing: 2) {
            ComparisonImage(scan: leftScan)
            ComparisonImage(scan: rightScan)
        }
        .frame(height: 330)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Scan comparison")
        .accessibilityValue("Older scan on the left, newer scan on the right")
        .accessibilityHint("Use the Swap button to reverse the scans.")
        .overlay(alignment: .center) {
            Image(systemName: "pause.fill")
                .font(.caption)
                .foregroundStyle(TrueMaxPalette.textPrimary)
                .frame(width: 42, height: 42)
                .background(TrueMaxPalette.backgroundRaised, in: Circle())
                .overlay {
                    Circle().strokeBorder(TrueMaxPalette.border, lineWidth: 2)
                }
        }
    }
}

private struct HistoryScanCard: View {
    let scan: ScanRecord
    var isSelected = false

    var body: some View {
        HStack(spacing: 14) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(TrueMaxPalette.accentLight)
            }

            Group {
                if let image = TrueMaxStorage.image(filename: scan.imageFilename) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    FaceMeshIllustration(mode: scan.captureMode)
                        .padding(8)
                }
            }
            .frame(width: 104, height: 136)
            .background(TrueMaxPalette.backgroundRaised)
            .clipShape(RoundedRectangle(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(scan.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline)
                        .foregroundStyle(TrueMaxPalette.textPrimary)
                    Spacer()
                    TrueMaxPill(
                        icon: scan.captureMode == .depth3D ? "cube" : "camera",
                        text: scan.captureMode.title
                    )
                }

                HistoryMetricLine(metric: .symmetry, scan: scan)
                Divider().overlay(TrueMaxPalette.border)
                HistoryMetricLine(metric: .proportion, scan: scan)
                Divider().overlay(TrueMaxPalette.border)
                HistoryMetricLine(metric: .jawAngle, scan: scan)
            }
        }
        .trueMaxCard()
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(TrueMaxPalette.accentLight, lineWidth: 2)
            }
        }
    }
}

private struct HistoryMetricLine: View {
    let metric: MetricKind
    let scan: ScanRecord

    var body: some View {
        HStack {
            Image(systemName: metric.symbol)
                .foregroundStyle(TrueMaxPalette.textSecondary)
                .frame(width: 24)
            Text(metric.shortTitle)
                .font(.caption)
                .foregroundStyle(TrueMaxPalette.textSecondary)
            Spacer()
            Text(scan.range(for: metric).displayText)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(TrueMaxPalette.textPrimary)
        }
    }
}

private struct ComparisonDateChip: View {
    let date: Date

    var body: some View {
        Label(
            date.formatted(date: .abbreviated, time: .omitted),
            systemImage: "calendar"
        )
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(TrueMaxPalette.textPrimary)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 52)
        .background(TrueMaxPalette.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(TrueMaxPalette.border)
        }
    }
}

private struct ComparisonImage: View {
    let scan: ScanRecord

    var body: some View {
        Group {
            if let image = TrueMaxStorage.image(filename: scan.imageFilename) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                FaceMeshIllustration(mode: scan.captureMode)
                    .padding(18)
                    .background(TrueMaxPalette.backgroundRaised)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

private struct ComparisonMetricRow: View {
    let metric: MetricKind
    let left: MetricRangeValue
    let right: MetricRangeValue

    var body: some View {
        HStack(spacing: 12) {
            TrueMaxIconCircle(symbol: metric.symbol, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(metric.shortTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TrueMaxPalette.textPrimary)
                HStack(spacing: 7) {
                    Text(left.displayText)
                        .foregroundStyle(TrueMaxPalette.textSecondary)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(TrueMaxPalette.textTertiary)
                    Text(right.displayText)
                        .foregroundStyle(TrueMaxPalette.accentLight)
                }
                .font(.subheadline)
                .monospacedDigit()
            }
            Spacer()
            Text(changeLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(changeColor)
                .multilineTextAlignment(.trailing)
        }
        .trueMaxCard()
    }

    private var changeLabel: String {
        let delta = right.midpoint - left.midpoint
        if abs(delta) < 0.75 {
            return "Similar range"
        }
        return delta > 0
            ? "Range shifted +\(formatted(abs(delta)))"
            : "Range shifted −\(formatted(abs(delta)))"
    }

    private var changeColor: Color {
        abs(right.midpoint - left.midpoint) < 0.75
            ? TrueMaxPalette.neutral
            : TrueMaxPalette.positive
    }

    private func formatted(_ value: Double) -> String {
        String(format: value < 10 ? "%.1f" : "%.0f", value)
    }
}

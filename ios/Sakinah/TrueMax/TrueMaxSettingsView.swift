import AVFoundation
import SwiftData
import SwiftUI
import UIKit

struct TrueMaxSettingsView: View {
    @Environment(TrueMaxAppState.self) private var appState
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \ScanRecord.createdAt, order: .reverse)
    private var scans: [ScanRecord]

    @State private var cameraAuthorization = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var exportItem: TrueMaxExportItem?
    @State private var notice: TrueMaxNotice?

    var body: some View {
        ZStack {
            TrueMaxPageBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    compactHeader
                    accessCard
                    experienceSection
                    privacySection
                    purchaseSection
                    supportSection
                    versionFooter
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 36)
                .trueMaxContentWidth()
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            TrueMaxAnalytics.shared.screen("settings", properties: [
                "is_premium": subscriptionService.isPremium,
                "scan_count": scans.count
            ])
        }
        .sheet(item: $exportItem) { item in
            TrueMaxActivityView(activityItems: [item.url])
                .presentationDetents([.medium, .large])
        }
        .alert(item: $notice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .task {
            cameraAuthorization = AVCaptureDevice.authorizationStatus(for: .video)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            cameraAuthorization = AVCaptureDevice.authorizationStatus(for: .video)
        }
    }

    private var compactHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Settings")
                .font(.title2.weight(.bold))
                .foregroundStyle(TrueMaxPalette.textPrimary)

            Spacer()

            TrueMaxBrandLockup(compact: true)
                .scaleEffect(0.82, anchor: .trailing)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .contain)
    }

    private var accessCard: some View {
        HStack(spacing: 16) {
            TrueMaxMark()
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 5) {
                Text(subscriptionService.isPremium ? "TrueMax unlocked" : "TrueMax")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(TrueMaxPalette.textPrimary)

                Text(accessDetail)
                    .font(.subheadline)
                    .foregroundStyle(TrueMaxPalette.textSecondary)
            }

            Spacer(minLength: 8)

            Image(systemName: subscriptionService.isPremium ? "checkmark.seal.fill" : "lock.fill")
                .font(.title3)
                .foregroundStyle(
                    subscriptionService.isPremium
                        ? TrueMaxPalette.positive
                        : TrueMaxPalette.textTertiary
                )
                .accessibilityHidden(true)
        }
        .trueMaxCard(elevated: true)
        .accessibilityElement(children: .combine)
    }

    private var accessDetail: String {
        if subscriptionService.isPremium {
            return "\(subscriptionService.currentPlanName) access"
        }
        return "No account"
    }

    private var experienceSection: some View {
        TrueMaxSettingsSection(title: "EXPERIENCE") {
            VStack(alignment: .leading, spacing: 12) {
                Stepper(value: cooldownBinding, in: 1...30) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Rescan reminder")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(TrueMaxPalette.textPrimary)

                        Text(cooldownDescription)
                            .font(.subheadline)
                            .foregroundStyle(TrueMaxPalette.textSecondary)
                    }
                }
                .frame(minHeight: 58)
                .accessibilityHint("Adjusts the local, non-blocking rescan reminder")
            }

            TrueMaxSettingsDivider()

            Button(action: openSystemSettings) {
                TrueMaxDisclosureRow(
                    icon: "accessibility",
                    title: "System & accessibility settings",
                    detail: "Text size, motion, contrast and app permissions",
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the Settings app")
        }
    }

    private var privacySection: some View {
        TrueMaxSettingsSection(title: "PRIVACY") {
            NavigationLink {
                TrueMaxDataPrivacyView()
            } label: {
                TrueMaxDisclosureRow(
                    icon: "lock.shield",
                    title: "Data & Privacy",
                    detail: "Your captures and results stay on this device"
                )
            }
            .buttonStyle(.plain)

            TrueMaxSettingsDivider()

            Button(action: openSystemSettings) {
                TrueMaxDisclosureRow(
                    icon: "camera",
                    title: "Camera permission",
                    detail: cameraPermissionDetail
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the Settings app")

            TrueMaxSettingsDivider()

            Button(action: exportData) {
                TrueMaxDisclosureRow(
                    icon: "square.and.arrow.up",
                    title: "Export my data",
                    detail: scans.isEmpty
                        ? "Create an empty local JSON export"
                        : "Create a local JSON export of \(scans.count) \(scanNoun)"
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Creates a file locally, then opens the system share sheet")
        }
    }

    private var purchaseSection: some View {
        TrueMaxSettingsSection(title: "PURCHASE") {
            TrueMaxDisclosureRow(
                icon: subscriptionService.isPremium ? "checkmark.seal" : "lock",
                title: "Purchase status",
                detail: subscriptionService.isPremium
                    ? subscriptionService.currentPlanName
                    : "No active TrueMax access",
                color: subscriptionService.isPremium
                    ? TrueMaxPalette.positive
                    : TrueMaxPalette.textTertiary,
                showsChevron: false
            )

            TrueMaxSettingsDivider()

            Button(action: restorePurchases) {
                TrueMaxDisclosureRow(
                    icon: "arrow.counterclockwise",
                    title: subscriptionService.isRestoringPurchases
                        ? "Restoring…"
                        : "Restore purchases",
                    detail: "Checks the App Store for previous access",
                    color: TrueMaxPalette.neutral,
                    showsChevron: !subscriptionService.isRestoringPurchases
                )
                .overlay(alignment: .trailing) {
                    if subscriptionService.isRestoringPurchases {
                        ProgressView()
                            .tint(TrueMaxPalette.neutral)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(subscriptionService.isRestoringPurchases)

            TrueMaxSettingsDivider()

            Button(action: manageSubscriptions) {
                TrueMaxDisclosureRow(
                    icon: "creditcard",
                    title: "Manage subscription",
                    detail: "Review or change your plan in the App Store"
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens App Store subscription settings")
        }
    }

    private var supportSection: some View {
        TrueMaxSettingsSection(title: "SUPPORT") {
            NavigationLink {
                TrueMaxMethodologyView()
            } label: {
                TrueMaxDisclosureRow(
                    icon: "info.circle",
                    title: "How measurements work",
                    detail: "Estimate bands and methodology"
                )
            }
            .buttonStyle(.plain)

            TrueMaxSettingsDivider()

            NavigationLink {
                TrueMaxAboutView()
            } label: {
                TrueMaxDisclosureRow(
                    icon: "app.badge",
                    title: "About TrueMax",
                    detail: "Product principles and version"
                )
            }
            .buttonStyle(.plain)

            TrueMaxSettingsDivider()

            NavigationLink {
                TrueMaxMedicalDisclaimerView()
            } label: {
                TrueMaxDisclosureRow(
                    icon: "cross.case",
                    title: "Medical disclaimer",
                    detail: "What TrueMax can and cannot tell you",
                    color: TrueMaxPalette.neutral
                )
            }
            .buttonStyle(.plain)

            TrueMaxSettingsDivider()

            Link(destination: TrueMaxBrand.privacyURL) {
                TrueMaxDisclosureRow(
                    icon: "hand.raised",
                    title: "Privacy policy",
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)

            TrueMaxSettingsDivider()

            Link(destination: TrueMaxBrand.termsURL) {
                TrueMaxDisclosureRow(
                    icon: "doc.text",
                    title: "Terms of use",
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)

            TrueMaxSettingsDivider()

            Link(destination: TrueMaxBrand.supportURL) {
                TrueMaxDisclosureRow(
                    icon: "questionmark.circle",
                    title: "Support",
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var versionFooter: some View {
        VStack(spacing: 5) {
            Text("Version \(TrueMaxVersion.display)")
            Text("No account")
        }
        .font(.footnote)
        .foregroundStyle(TrueMaxPalette.textTertiary)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }

    private var cooldownBinding: Binding<Int> {
        Binding(
            get: { appState.cooldownDays },
            set: { appState.cooldownDays = $0 }
        )
    }

    private var cooldownDescription: String {
        appState.cooldownDays == 1
            ? "After 1 day · reminder only"
            : "After \(appState.cooldownDays) days · reminder only"
    }

    private var cameraPermissionDetail: String {
        switch cameraAuthorization {
        case .authorized:
            return "Allowed"
        case .denied:
            return "Not allowed · tap to open Settings"
        case .restricted:
            return "Restricted by device settings"
        case .notDetermined:
            return "Not requested yet"
        @unknown default:
            return "Review in system Settings"
        }
    }

    private var scanNoun: String {
        scans.count == 1 ? "scan" : "scans"
    }

    private func exportData() {
        TrueMaxAnalytics.shared.capture("data export requested", properties: [
            "scan_count": scans.count
        ])
        do {
            exportItem = TrueMaxExportItem(
                url: try TrueMaxStorage.makeJSONExport(scans: scans)
            )
        } catch {
            notice = TrueMaxNotice(
                title: "Export couldn’t be created",
                message: error.localizedDescription
            )
        }
    }

    private func restorePurchases() {
        TrueMaxAnalytics.shared.capture("restore purchases started", properties: [
            "location": "settings"
        ])
        Task {
            await subscriptionService.restorePurchases()

            if let purchaseError = subscriptionService.purchaseError {
                notice = TrueMaxNotice(
                    title: "Restore purchases",
                    message: purchaseError
                )
            } else {
                TrueMaxAnalytics.shared.capture("subscription restored", properties: [
                    "location": "settings"
                ])
                notice = TrueMaxNotice(
                    title: "Purchases restored",
                    message: "Your App Store purchase status is up to date."
                )
            }
        }
    }

    private func manageSubscriptions() {
        TrueMaxAnalytics.shared.capture("subscription management opened")
        openURL(subscriptionService.managementURL ?? TrueMaxBrand.manageSubscriptionsURL)
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

private struct TrueMaxDataPrivacyView: View {
    @Environment(TrueMaxAppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ScanRecord.createdAt, order: .reverse)
    private var scans: [ScanRecord]

    @Query(sort: \StyleFavorite.createdAt, order: .reverse)
    private var favorites: [StyleFavorite]

    @State private var showsDeleteConfirmation = false
    @State private var exportItem: TrueMaxExportItem?
    @State private var notice: TrueMaxNotice?

    var body: some View {
        TrueMaxDetailScaffold(title: "Data & Privacy") {
            VStack(alignment: .leading, spacing: 24) {
                privacyHero
                storageSummary
                controls
                dataNotCollectedCard
            }
        }
        .sheet(item: $exportItem) { item in
            TrueMaxActivityView(activityItems: [item.url])
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            "Delete all TrueMax data?",
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete all data", role: .destructive, action: deleteAllData)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This permanently removes every scan, captured photo, measurement, local export and style favorite. Your App Store purchase is not affected."
            )
        }
        .alert(item: $notice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var privacyHero: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundStyle(TrueMaxPalette.primaryGradient)
                .accessibilityHidden(true)

            Text("Stored only on this iPhone")
                .font(.title2.weight(.bold))
                .foregroundStyle(TrueMaxPalette.textPrimary)
                .multilineTextAlignment(.center)

            Text("TrueMax has no account, cloud sync, ads, or product analytics. Face captures, measurements, and product interactions stay on this iPhone.")
                .font(.body)
                .foregroundStyle(TrueMaxPalette.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .trueMaxCard(elevated: true)
    }

    private var storageSummary: some View {
        TrueMaxSettingsSection(title: "STORED LOCALLY") {
            TrueMaxPrivacyFactRow(
                symbol: "camera",
                title: "Captured photos",
                detail: "Protected local files",
                value: "\(scansWithPhotos) saved"
            )

            TrueMaxSettingsDivider()

            TrueMaxPrivacyFactRow(
                symbol: "ruler",
                title: "Measurements",
                detail: "SwiftData storage",
                value: "\(scans.count) \(scans.count == 1 ? "scan" : "scans")"
            )

            TrueMaxSettingsDivider()

            TrueMaxPrivacyFactRow(
                symbol: "star",
                title: "Style favorites",
                detail: "SwiftData storage",
                value: "\(favorites.count) saved"
            )

            TrueMaxSettingsDivider()

            TrueMaxPrivacyFactRow(
                symbol: "network.slash",
                title: "Face and scan uploads",
                detail: "No account or backend",
                value: "Never"
            )
        }
    }

    private var controls: some View {
        TrueMaxSettingsSection(title: "YOUR CONTROLS") {
            Button(action: exportData) {
                TrueMaxDisclosureRow(
                    icon: "square.and.arrow.up",
                    title: "Export my data",
                    detail: "Create a local JSON file",
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the system share sheet after creating the file")

            TrueMaxSettingsDivider()

            Button {
                showsDeleteConfirmation = true
            } label: {
                TrueMaxDisclosureRow(
                    icon: "trash",
                    title: "Delete all TrueMax data",
                    detail: "Scans, photos, measurements and favorites",
                    color: TrueMaxPalette.caution,
                    showsChevron: false
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Requires confirmation")
        }
    }

    private var dataNotCollectedCard: some View {
        HStack(alignment: .top, spacing: 15) {
            TrueMaxIconCircle(
                symbol: "hand.raised.fill",
                color: TrueMaxPalette.accentLight,
                size: 48
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("App privacy")
                    .font(.subheadline)
                    .foregroundStyle(TrueMaxPalette.textSecondary)

                Text("Face data not collected")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(TrueMaxPalette.textPrimary)

                Text("TrueMax does not send your face, photos, measurements or style choices off this device. RevenueCat handles purchases, while anonymous product events contain no face data.")
                    .font(.subheadline)
                    .foregroundStyle(TrueMaxPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .trueMaxCard(elevated: true)
        .accessibilityElement(children: .combine)
    }

    private var scansWithPhotos: Int {
        scans.filter {
            TrueMaxStorage.captureExists(filename: $0.imageFilename)
        }.count
    }

    private func exportData() {
        do {
            exportItem = TrueMaxExportItem(
                url: try TrueMaxStorage.makeJSONExport(scans: scans)
            )
        } catch {
            notice = TrueMaxNotice(
                title: "Export couldn’t be created",
                message: error.localizedDescription
            )
        }
    }

    private func deleteAllData() {
        TrueMaxAnalytics.shared.capture("data deletion requested", properties: [
            "scan_count": scans.count,
            "favorite_count": favorites.count
        ])
        for scan in scans {
            modelContext.delete(scan)
        }
        for favorite in favorites {
            modelContext.delete(favorite)
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            notice = TrueMaxNotice(
                title: "Data wasn’t deleted",
                message: "TrueMax could not save the database deletion. The pending changes were rolled back, and protected photo and export cleanup was not attempted. Database error: \(error.localizedDescription)"
            )
            return
        }

        do {
            try TrueMaxStorage.deleteAllUserFiles()
            appState.startScan()
        } catch {
            notice = TrueMaxNotice(
                title: "File cleanup incomplete",
                message: "TrueMax saved the database deletion, but some protected local files remain. \(error.localizedDescription) Tap Delete all TrueMax data again to retry cleanup."
            )
        }
    }
}

private struct TrueMaxMethodologyView: View {
    var body: some View {
        TrueMaxDetailScaffold(title: "How measurements work") {
            VStack(alignment: .leading, spacing: 20) {
                TrueMaxInformationCard(
                    symbol: "scope",
                    title: "Transparent estimates",
                    message: "TrueMax detects visible facial landmarks and reports a range. A range reflects pose, lighting and landmark uncertainty; it is not a beauty or attractiveness score."
                )

                ForEach(MetricKind.allCases) { metric in
                    VStack(alignment: .leading, spacing: 10) {
                        Label(metric.title, systemImage: metric.symbol)
                            .font(.headline)
                            .foregroundStyle(TrueMaxPalette.textPrimary)

                        Text(metric.methodology)
                            .font(.body)
                            .foregroundStyle(TrueMaxPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(metric.summary)
                            .font(.footnote)
                            .foregroundStyle(TrueMaxPalette.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .trueMaxCard()
                }

                TrueMaxInformationCard(
                    symbol: "camera.aperture",
                        title: "Capture quality",
                    message: "Photo mode uses wider estimate ranges because a single two-dimensional image cannot provide clinical depth measurements. Recapturing in even, front-facing light can improve consistency."
                )
            }
        }
    }
}

private struct TrueMaxAboutView: View {
    var body: some View {
        TrueMaxDetailScaffold(title: "About TrueMax") {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 14) {
                    TrueMaxMark()
                        .frame(width: 72, height: 72)

                    TrueMaxBrandLockup()

                    Text("Know what works for you.")
                        .font(.body)
                        .foregroundStyle(TrueMaxPalette.textSecondary)

                    Text("Version \(TrueMaxVersion.display)")
                        .font(.footnote)
                        .foregroundStyle(TrueMaxPalette.textTertiary)
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .trueMaxCard(elevated: true)

                TrueMaxInformationCard(
                    symbol: "iphone",
                    title: "Private by architecture",
                    message: "There is no TrueMax account or cloud scan library. Capture analysis and scan history live on your device. Purchase services do not receive your face or measurement data."
                )

                TrueMaxInformationCard(
                    symbol: "equal.circle",
                    title: "Neutral by design",
                    message: "TrueMax uses measurement ranges and practical presentation guidance. It does not rank attractiveness, compare you with other people, or generate an altered ‘ideal’ face."
                )

                TrueMaxInformationCard(
                    symbol: "heart.text.square",
                    title: "Use with perspective",
                    message: "Appearance is only one part of wellbeing. If checking your appearance is causing distress or disrupting daily life, step away from scanning and consider speaking with someone you trust or a qualified professional."
                )
            }
        }
    }
}

private struct TrueMaxMedicalDisclaimerView: View {
    var body: some View {
        TrueMaxDetailScaffold(title: "Medical disclaimer") {
            VStack(alignment: .leading, spacing: 20) {
                TrueMaxInformationCard(
                    symbol: "cross.case",
                    title: "Cosmetic information only",
                    message: "TrueMax provides estimates of visible facial geometry, image texture and general grooming or style guidance. It is not a medical device."
                )

                TrueMaxInformationCard(
                    symbol: "stethoscope",
                    title: "Not a diagnosis",
                    message: "Results are not medical, dermatological, dental, orthodontic or psychological advice. Do not use TrueMax to diagnose, prevent or treat any condition."
                )

                TrueMaxInformationCard(
                    symbol: "person.crop.circle.badge.questionmark",
                    title: "Talk to a professional",
                    message: "For concerns about your skin, facial development, pain, body image or mental wellbeing, speak with an appropriately qualified healthcare professional."
                )

                Text("Image conditions, camera hardware and facial pose affect every estimate. Results can vary between captures.")
                    .font(.footnote)
                    .foregroundStyle(TrueMaxPalette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
        }
    }
}

private struct TrueMaxDetailScaffold<Content: View>: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let content: Content

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        ZStack {
            TrueMaxPageBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 10) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(TrueMaxPalette.accentLight)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Back")

                        Text(title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(TrueMaxPalette.textPrimary)
                            .lineLimit(2)

                        Spacer()
                    }

                    content
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 36)
                .trueMaxContentWidth()
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct TrueMaxSettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.footnote.weight(.medium))
                .foregroundStyle(TrueMaxPalette.textTertiary)
                .padding(.leading, 4)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                content
            }
            .trueMaxCard()
        }
    }
}

private struct TrueMaxSettingsDivider: View {
    var body: some View {
        Divider()
            .overlay(TrueMaxPalette.border)
            .padding(.leading, 58)
    }
}

private struct TrueMaxPrivacyFactRow: View {
    let symbol: String
    let title: String
    let detail: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            TrueMaxIconCircle(symbol: symbol, size: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(TrueMaxPalette.textPrimary)

                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(TrueMaxPalette.textSecondary)
            }

            Spacer(minLength: 8)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TrueMaxPalette.positive)
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: 58)
        .accessibilityElement(children: .combine)
    }
}

private struct TrueMaxInformationCard: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            TrueMaxIconCircle(symbol: symbol, size: 44)

            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(TrueMaxPalette.textPrimary)

                Text(message)
                    .font(.body)
                    .foregroundStyle(TrueMaxPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .trueMaxCard()
        .accessibilityElement(children: .combine)
    }
}

private struct TrueMaxActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

private struct TrueMaxExportItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct TrueMaxNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private enum TrueMaxVersion {
    static var display: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0"
        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String

        guard let build, !build.isEmpty else { return version }
        return "\(version) (\(build))"
    }
}

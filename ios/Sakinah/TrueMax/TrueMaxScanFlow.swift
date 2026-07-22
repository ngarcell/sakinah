import SwiftData
import SwiftUI
import UIKit

struct TrueMaxScanRootView: View {
    private enum Phase: Equatable {
        case checklist
        case photoMode
        case camera
        case demoCamera
        case processing
        case result
        case permission
    }

    let isOnboardingTrial: Bool
    let onTrialExit: (() -> Void)?
    let onTrialCompleted: (() -> Void)?

    init(
        isOnboardingTrial: Bool = false,
        onTrialExit: (() -> Void)? = nil,
        onTrialCompleted: (() -> Void)? = nil
    ) {
        self.isOnboardingTrial = isOnboardingTrial
        self.onTrialExit = onTrialExit
        self.onTrialCompleted = onTrialCompleted
    }

    @Environment(TrueMaxAppState.self) private var appState
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(TrueMaxMarketingWalkthroughController.self) private var demo
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \ScanRecord.createdAt, order: .reverse) private var scans: [ScanRecord]

    @State private var cameraController = CameraCaptureController()
    @State private var phase: Phase = .checklist
    @State private var isOpeningCamera = false
    @State private var capturedImage: UIImage?
    @State private var completedScan: ScanRecord?
    @State private var errorMessage: String?
    @State private var showsCooldownPrompt = false
    @State private var bypassedCooldown = false
    @State private var photoModeExplained = false
    @State private var isRunningDemoCapture = false

    var body: some View {
        phaseContent
        .toolbar(navigationBarVisibility, for: .navigationBar)
        .toolbar(tabBarVisibility, for: .tabBar)
        .onChange(of: appState.scanRequestID) { _, _ in
            resetForNewScan()
        }
        .onChange(of: phase) { _, newPhase in
            TrueMaxAnalytics.shared.capture("scan phase changed", properties: [
                "phase": String(describing: newPhase),
                "onboarding_trial": isOnboardingTrial
            ])
        }
        .onChange(of: demo.phase) { _, demoPhase in
            switch demoPhase {
            case .scanChecklist:
                resetForNewScan()
            case .scanCapture:
                runDemoCapture()
            case .home, .styles, .history, .finished:
                if phase == .result { finishResult() }
            default:
                break
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            cameraController.setSceneActive(newPhase == .active)
        }
        .onDisappear {
            cameraController.stop()
        }
        .onAppear {
            TrueMaxAnalytics.shared.screen("scan", properties: [
                "onboarding_trial": isOnboardingTrial,
                "is_premium": subscriptionService.isPremium
            ])
        }
        .confirmationDialog(
            "Rescan now?",
            isPresented: $showsCooldownPrompt,
            titleVisibility: .visible
        ) {
            Button("Rescan anyway") {
                bypassedCooldown = true
                beginCameraPreparation()
            }
            Button("Wait until later", role: .cancel) {}
        } message: {
            Text(cooldownMessage)
        }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch phase {
        case .checklist:
            checklistView
        case .photoMode:
            photoModeView
        case .camera:
            cameraView
        case .demoCamera:
            demoCameraView
        case .processing:
            processingView
        case .result:
            resultView
        case .permission:
            cameraPermissionView
        }
    }

    @ViewBuilder
    private var resultView: some View {
        if let completedScan {
            TrueMaxResultDetailView(
                scan: completedScan,
                showsResultReveal: true,
                onDone: finishResult
            )
        } else {
            checklistView
        }
    }

    private var checklistView: some View {
        ZStack {
            TrueMaxPageBackground()

            ScrollView {
                VStack(spacing: 22) {
                    scanHeader(title: "New scan")

                    VStack(spacing: 8) {
                        Text("Set up a consistent scan.")
                            .font(.title2.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(TrueMaxPalette.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Follow these steps for the most reliable ranges.")
                            .font(.body)
                            .foregroundStyle(TrueMaxPalette.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    ZStack {
                        FaceMeshIllustration()
                            .frame(height: 330)
                            .padding(20)
                        FaceGuideOverlayForCapture()
                            .padding(48)
                    }
                    .background(
                        TrueMaxPalette.backgroundRaised,
                        in: RoundedRectangle(cornerRadius: 20)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(TrueMaxPalette.border)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Front-facing neutral capture guide")

                    VStack(spacing: 10) {
                        ChecklistRow(text: "Face a window or soft light")
                        ChecklistRow(text: "Remove glasses and headwear")
                        ChecklistRow(text: "Keep a neutral expression")
                        ChecklistRow(text: "Hold the phone at eye level")
                    }

                    Label(
                        "Consistency gives you tighter estimate bands.",
                        systemImage: "info.circle"
                    )
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(TrueMaxPalette.neutral)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        TrueMaxPalette.neutral.opacity(0.10),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(TrueMaxPalette.neutral.opacity(0.55))
                    }

                    Button {
                        requestCamera()
                    } label: {
                        HStack(spacing: 10) {
                            if isOpeningCamera {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "camera")
                            }
                            Text(isOpeningCamera ? "Opening camera…" : "Open camera")
                        }
                    }
                    .buttonStyle(TrueMaxPrimaryButtonStyle())
                    .disabled(isOpeningCamera)

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .trueMaxContentWidth()
            }
            .scrollIndicators(.hidden)
        }
    }

    private var photoModeView: some View {
        ZStack {
            TrueMaxPageBackground()

            ScrollView {
                VStack(spacing: 24) {
                    scanHeader(title: "Photo mode")

                    TrueMaxPill(
                        icon: "camera",
                        text: "2D · Photo mode",
                        color: TrueMaxPalette.neutral
                    )

                    FaceMeshIllustration(mode: .photo2D, lineColor: TrueMaxPalette.accentLight)
                        .frame(height: 330)
                        .padding(24)
                        .background(
                            TrueMaxPalette.backgroundRaised,
                            in: RoundedRectangle(cornerRadius: 20)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(TrueMaxPalette.border)
                        }

                    VStack(spacing: 8) {
                        Text("Still useful. Slightly wider ranges.")
                            .font(.title2.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(TrueMaxPalette.textPrimary)
                            .multilineTextAlignment(.center)
                        Text("This camera did not deliver depth data, so the result will use 2D landmarks and wider ranges.")
                            .font(.body)
                            .foregroundStyle(TrueMaxPalette.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Group {
                        if dynamicTypeSize.isAccessibilitySize {
                            VStack(spacing: 12) {
                                captureModeCards
                            }
                        } else {
                            HStack(spacing: 12) {
                                captureModeCards
                            }
                        }
                    }

                    Button("Continue in Photo mode") {
                        photoModeExplained = true
                        phase = .camera
                        cameraController.start()
                    }
                    .buttonStyle(TrueMaxPrimaryButtonStyle())
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .trueMaxContentWidth()
            }
            .scrollIndicators(.hidden)
        }
    }

    private var cameraView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraCapturePreview(controller: cameraController)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.65),
                    Color.clear,
                    Color.black.opacity(0.78),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            FaceCaptureOval()
                .stroke(
                    cameraController.canCapture
                        ? TrueMaxPalette.positive
                        : TrueMaxPalette.accentLight,
                    style: StrokeStyle(lineWidth: 2, dash: [8, 5])
                )
                .padding(.horizontal, 54)
                .padding(.vertical, 165)
                .allowsHitTesting(false)

            VStack {
                HStack {
                    TrueMaxCloseButton {
                        cameraController.stop()
                        phase = .checklist
                    }
                    Spacer()
                    Text("Position your face")
                        .font(.headline)
                        .foregroundStyle(Color.white)
                    Spacer()
                    Text(cameraController.captureMode.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 44, height: 38)
                        .background(
                            cameraController.captureMode == .depth3D
                                ? TrueMaxPalette.accent
                                : TrueMaxPalette.neutral,
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)

                Spacer()

                VStack(spacing: 18) {
                    Label(
                        cameraStatusText,
                        systemImage: cameraController.liveGuidance.allowsCapture
                            ? "checkmark.circle.fill"
                            : "camera.aperture"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        cameraController.liveGuidance.allowsCapture
                            ? TrueMaxPalette.positive
                            : Color.white
                    )

                    Button {
                        capture()
                    } label: {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 82, height: 82)
                            .overlay {
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 4)
                                    .padding(-8)
                            }
                            .overlay {
                                if cameraController.isCapturing {
                                    ProgressView().tint(Color.black)
                                }
                            }
                    }
                    .disabled(!cameraController.canCapture)
                    .opacity(cameraController.canCapture ? 1 : 0.52)
                    .accessibilityLabel("Take photo")

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(TrueMaxPalette.caution)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, 38)
            }
        }
        .onAppear {
            if !cameraController.isRunning {
                cameraController.start()
            }
        }
    }

    private var demoCameraView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image("TrueMaxDemoCurrent")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            LinearGradient(
                colors: [.black.opacity(0.55), .clear, .black.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            FaceCaptureOval()
                .stroke(TrueMaxPalette.positive, style: StrokeStyle(lineWidth: 2, dash: [8, 5]))
                .padding(.horizontal, 54)
                .padding(.vertical, 165)
            VStack {
                Text("Position your face")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.top, 18)
                Spacer()
                Label("Great framing · Hold still", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TrueMaxPalette.positive)
                Circle()
                    .fill(Color.white)
                    .frame(width: 82, height: 82)
                    .overlay { Circle().strokeBorder(Color.white, lineWidth: 4).padding(-8) }
                    .padding(.top, 18)
                    .padding(.bottom, 38)
            }
        }
    }

    private var processingView: some View {
        ZStack {
            TrueMaxPageBackground()

            ScrollView {
                VStack(spacing: 24) {
                    TrueMaxBrandLockup()

                    ZStack {
                        if let capturedImage {
                            Image(uiImage: capturedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 430)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .saturation(0.48)
                        } else {
                            FaceMeshIllustration(mode: cameraController.captureMode)
                                .frame(height: 380)
                        }

                        FaceGuideOverlayForCapture()
                            .padding(42)

                        Rectangle()
                            .fill(TrueMaxPalette.accentLight.opacity(0.70))
                            .frame(height: 2)
                            .shadow(color: TrueMaxPalette.accentLight, radius: 10)
                    }

                    VStack(spacing: 8) {
                        Text("Measuring your baseline")
                            .font(.title.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(TrueMaxPalette.textPrimary)
                            .multilineTextAlignment(.center)
                        Text("This usually takes a few seconds.")
                            .font(.body)
                            .foregroundStyle(TrueMaxPalette.textSecondary)
                    }

                    ProcessingRow(
                        symbol: "checkmark.circle.fill",
                        title: "Capture secured locally",
                        state: .complete
                    )
                    ProcessingRow(
                        symbol: "ruler",
                        title: "Calculating estimate bands",
                        state: .active
                    )
                    ProcessingRow(
                        symbol: "list.bullet.clipboard",
                        title: "Building your action plan",
                        state: .waiting
                    )

                    Label("Nothing is being uploaded.", systemImage: "lock.fill")
                        .font(.footnote)
                        .foregroundStyle(TrueMaxPalette.textTertiary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .trueMaxContentWidth()
            }
            .scrollIndicators(.hidden)
        }
    }

    private var cameraPermissionView: some View {
        ZStack {
            TrueMaxPageBackground()

            ScrollView {
                VStack(spacing: 24) {
                    TrueMaxBrandLockup(compact: true)

                    ZStack {
                        Circle()
                            .stroke(TrueMaxPalette.accent.opacity(0.25), lineWidth: 1)
                            .frame(width: 220, height: 220)
                        Circle()
                            .stroke(TrueMaxPalette.accent.opacity(0.16), lineWidth: 1)
                            .frame(width: 180, height: 180)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 66, weight: .light))
                            .foregroundStyle(TrueMaxPalette.textPrimary)
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundStyle(TrueMaxPalette.accentLight)
                            .offset(x: 50, y: 47)
                    }

                    VStack(spacing: 10) {
                        Text("Camera access is needed to scan.")
                            .font(.title2.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(TrueMaxPalette.textPrimary)
                            .multilineTextAlignment(.center)
                        Text("TrueMax uses the camera only for deliberate facial capture.")
                            .font(.body)
                            .foregroundStyle(TrueMaxPalette.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 0) {
                        PrivacyPermissionRow(
                            symbol: "checkmark.shield",
                            title: "Capture locally",
                            detail: "Photos stay in protected app storage."
                        )
                        Divider().overlay(TrueMaxPalette.border)
                        PrivacyPermissionRow(
                            symbol: "cpu",
                            title: "Analyze the capture",
                            detail: "Apple Vision measures the visible landmarks."
                        )
                        Divider().overlay(TrueMaxPalette.border)
                        PrivacyPermissionRow(
                            symbol: "trash",
                            title: "Delete anytime",
                            detail: "You control your local data."
                        )
                    }
                    .trueMaxCard()

                    Button("Open iPhone Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                    .buttonStyle(TrueMaxPrimaryButtonStyle())

                    Button("Not now") {
                        phase = .checklist
                    }
                    .buttonStyle(TrueMaxSecondaryButtonStyle())
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .trueMaxContentWidth()
            }
            .scrollIndicators(.hidden)
        }
    }

    private func scanHeader(title: String) -> some View {
        HStack {
            TrueMaxCloseButton {
                cameraController.stop()
                if isOnboardingTrial {
                    onTrialExit?()
                } else {
                    appState.selectedTab = .home
                }
            }
            Spacer()
            Text(title)
                .font(.headline)
                .foregroundStyle(TrueMaxPalette.textPrimary)
            Spacer()
            TrueMaxPill(
                icon: cameraController.captureMode == .depth3D ? "cube" : "camera",
                text: cameraController.captureMode.badgeTitle,
                color: cameraController.captureMode == .depth3D
                    ? TrueMaxPalette.accentLight
                    : TrueMaxPalette.neutral
            )
            .frame(maxWidth: 144)
        }
    }

    @ViewBuilder
    private var captureModeCards: some View {
        CaptureModeCard(
            mode: .depth3D,
            detail: "Tighter ranges when depth is delivered",
            isSelected: false
        )
        CaptureModeCard(
            mode: .photo2D,
            detail: "Wider ranges with 2D landmarks",
            isSelected: true
        )
    }

    private var tabBarVisibility: Visibility {
        switch phase {
        case .camera, .demoCamera, .processing, .photoMode, .permission, .result:
            return .hidden
        case .checklist:
            return .visible
        }
    }

    private var navigationBarVisibility: Visibility {
        phase == .result ? .visible : .hidden
    }

    private var cameraStatusText: String {
        if cameraController.permissionState == .requesting {
            return "Waiting for camera permission"
        }
        if !cameraController.isConfigured {
            return "Preparing front camera"
        }
        if !cameraController.isRunning {
            return "Starting camera"
        }
        return cameraController.liveGuidance.instruction
    }

    private var needsCooldownConfirmation: Bool {
        guard !bypassedCooldown, let latest = scans.first else { return false }
        let nextDate = Calendar.current.date(
            byAdding: .day,
            value: appState.cooldownDays,
            to: latest.createdAt
        ) ?? latest.createdAt
        return Date() < nextDate
    }

    private var cooldownMessage: String {
        guard let latest = scans.first else {
            return "A consistent interval can make comparisons more useful."
        }
        let elapsed = max(
            0,
            Calendar.current.dateComponents(
                [.day],
                from: latest.createdAt,
                to: Date()
            ).day ?? 0
        )
        return "It has been \(elapsed) \(elapsed == 1 ? "day" : "days") since your last scan. Waiting can make comparisons more meaningful, but this reminder never blocks you."
    }

    private func requestCamera() {
        TrueMaxAnalytics.shared.capture("scan camera requested", properties: [
            "onboarding_trial": isOnboardingTrial,
            "is_premium": subscriptionService.isPremium
        ])
        guard subscriptionService.isPremium || appState.canUseReverseTrialScan else {
            TrueMaxAnalytics.shared.capture("scan blocked", properties: [
                "reason": "subscription_required",
                "onboarding_trial": isOnboardingTrial
            ])
            appState.presentPaywall()
            return
        }

        if needsCooldownConfirmation {
            showsCooldownPrompt = true
        } else {
            beginCameraPreparation()
        }
    }

    private func beginCameraPreparation() {
        guard !isOpeningCamera else { return }
        TrueMaxAnalytics.shared.capture("camera preparation started", properties: [
            "onboarding_trial": isOnboardingTrial
        ])
        isOpeningCamera = true
        errorMessage = nil

        Task {
            await cameraController.prepare()
            isOpeningCamera = false

            switch cameraController.permissionState {
            case .denied, .restricted:
                phase = .permission
            case .authorized:
                if cameraController.captureMode == .photo2D, !photoModeExplained {
                    cameraController.stop()
                    phase = .photoMode
                } else {
                    phase = .camera
                }
            case .notDetermined, .requesting:
                errorMessage = "Camera permission could not be confirmed."
            }
        }
    }

    private func capture() {
        guard cameraController.canCapture else { return }
        errorMessage = nil

        Task {
            do {
                let captured = try await cameraController.capturePhoto()
                TrueMaxAnalytics.shared.capture("scan capture completed", properties: [
                    "capture_mode": captured.captureMode.title,
                    "onboarding_trial": isOnboardingTrial
                ])
                cameraController.stop()
                capturedImage = captured.image
                phase = .processing

                let analysis = try await TrueMaxAnalysisEngine.analyze(
                    image: captured.image,
                    captureMode: captured.captureMode,
                    depthGeometry: captured.depthGeometry
                )
                let id = UUID()
                let filename = try TrueMaxStorage.saveCapture(
                    captured.image,
                    id: id
                )
                let scan = ScanRecord(
                    id: id,
                    imageFilename: filename,
                    analysis: analysis
                )

                do {
                    modelContext.insert(scan)
                    try modelContext.save()
                } catch {
                    let databaseError = error
                    let cleanupResult = TrueMaxStorage.deleteCapture(
                        filename: filename
                    )
                    modelContext.rollback()

                    if case let .failure(cleanupError) = cleanupResult {
                        throw TrueMaxScanPersistenceError(
                            databaseReason: databaseError.localizedDescription,
                            cleanupReason: cleanupError.localizedDescription
                        )
                    }

                    throw databaseError
                }

                completedScan = scan
                phase = .result
                TrueMaxAnalytics.shared.capture("scan result available", properties: [
                    "capture_mode": scan.captureMode.title,
                    "confidence": scan.confidence.title,
                    "onboarding_trial": isOnboardingTrial
                ])
            } catch {
                TrueMaxAnalytics.shared.capture("scan failed", properties: [
                    "error_type": String(describing: type(of: error)),
                    "onboarding_trial": isOnboardingTrial
                ])
                errorMessage = error.localizedDescription
                capturedImage = nil
                phase = .camera
                cameraController.start()
            }
        }
    }

    private func runDemoCapture() {
        guard demo.isPlaying, !isRunningDemoCapture,
              let image = UIImage(named: "TrueMaxDemoCurrent") else { return }
        isRunningDemoCapture = true
        cameraController.stop()
        capturedImage = image
        phase = .demoCamera

        Task {
            try? await Task.sleep(for: .milliseconds(650))
            phase = .processing
            let analysis: TrueMaxAnalysisResult
            do {
                analysis = try await TrueMaxAnalysisEngine.analyze(
                    image: image,
                    captureMode: .photo2D
                )
            } catch {
                // The bundled portrait is designed for Vision. Keep simulator
                // playback reliable on runtimes where face detection differs.
                analysis = TrueMaxMarketingSeed.fallbackCurrentAnalysis()
            }

            do {
                for scan in scans where scan.id == TrueMaxMarketingSeed.currentID {
                    _ = TrueMaxStorage.deleteCapture(filename: scan.imageFilename)
                    modelContext.delete(scan)
                }
                try modelContext.save()

                let filename = try TrueMaxStorage.saveCapture(
                    image,
                    id: TrueMaxMarketingSeed.currentID
                )
                let scan = ScanRecord(
                    id: TrueMaxMarketingSeed.currentID,
                    imageFilename: filename,
                    analysis: analysis
                )
                modelContext.insert(scan)
                try modelContext.save()
                try await Task.sleep(for: .seconds(2.4))
                completedScan = scan
                phase = .result
            } catch {
                errorMessage = error.localizedDescription
                phase = .checklist
            }
            isRunningDemoCapture = false
        }
    }

    private func finishResult() {
        TrueMaxAnalytics.shared.capture("scan AHA result completed", properties: [
            "onboarding_trial": isOnboardingTrial,
            "is_premium": subscriptionService.isPremium
        ])
        cameraController.stop()
        phase = .checklist
        capturedImage = nil
        completedScan = nil
        bypassedCooldown = false

        if isOnboardingTrial {
            onTrialCompleted?()
            return
        }

        appState.selectedTab = .home

        if !subscriptionService.isPremium && !demo.isPlaying {
            appState.consumeReverseTrial()
        }
    }

    private func resetForNewScan() {
        cameraController.stop()
        phase = .checklist
        capturedImage = nil
        completedScan = nil
        errorMessage = nil
        bypassedCooldown = false
    }
}

private struct TrueMaxScanPersistenceError: LocalizedError {
    let databaseReason: String
    let cleanupReason: String

    var errorDescription: String? {
        "The scan could not be saved, and its protected photo file could not be removed. Database error: \(databaseReason) Cleanup error: \(cleanupReason) Use Delete all TrueMax data in Settings to retry cleanup."
    }
}

private struct ChecklistRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.white)
                .frame(width: 44, height: 44)
                .background(TrueMaxPalette.primaryGradient, in: Circle())
            Text(text)
                .font(.body.weight(.medium))
                .foregroundStyle(TrueMaxPalette.textPrimary)
            Spacer()
        }
        .trueMaxCard()
    }
}

private struct CaptureModeCard: View {
    let mode: CaptureMode
    let detail: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: mode == .depth3D ? "cube" : "face.dashed")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(
                    isSelected
                        ? TrueMaxPalette.accentLight
                        : TrueMaxPalette.textTertiary
                )
            Text(mode == .depth3D ? "3D capture" : "Photo mode")
                .font(.headline)
                .foregroundStyle(
                    isSelected
                        ? TrueMaxPalette.accentLight
                        : TrueMaxPalette.textPrimary
                )
            Text(detail)
                .font(.caption)
                .foregroundStyle(TrueMaxPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 170)
        .trueMaxCard()
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(TrueMaxPalette.accentLight, lineWidth: 2)
            }
        }
    }
}

private struct FaceCaptureOval: Shape {
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: rect)
    }
}

private struct FaceGuideOverlayForCapture: View {
    var body: some View {
        GeometryReader { proxy in
            let rect = CGRect(
                x: proxy.size.width * 0.12,
                y: proxy.size.height * 0.07,
                width: proxy.size.width * 0.76,
                height: proxy.size.height * 0.85
            )
            ZStack {
                Path(ellipseIn: rect)
                    .stroke(
                        TrueMaxPalette.accentLight,
                        style: StrokeStyle(lineWidth: 1.5, dash: [7, 5])
                    )
                Path { path in
                    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
                    path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
                    path.move(to: CGPoint(x: rect.minX, y: rect.midY))
                    path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
                }
                .stroke(
                    TrueMaxPalette.textSecondary.opacity(0.75),
                    style: StrokeStyle(lineWidth: 1, dash: [6, 5])
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct PrivacyPermissionRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(TrueMaxPalette.accentLight)
                .frame(width: 46)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(TrueMaxPalette.textPrimary)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(TrueMaxPalette.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 13)
    }
}

private struct ProcessingRow: View {
    enum State {
        case complete
        case active
        case waiting
    }

    let symbol: String
    let title: String
    let state: State

    var body: some View {
        HStack(spacing: 14) {
            if state == .active {
                ProgressView()
                    .tint(TrueMaxPalette.accentLight)
                    .frame(width: 38, height: 38)
            } else {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(
                        state == .complete
                            ? TrueMaxPalette.positive
                            : TrueMaxPalette.textTertiary
                    )
                    .frame(width: 38, height: 38)
            }

            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(
                    state == .waiting
                        ? TrueMaxPalette.textTertiary
                        : TrueMaxPalette.textPrimary
                )
            Spacer()
            if state == .complete {
                Image(systemName: "checkmark")
                    .foregroundStyle(TrueMaxPalette.positive)
            }
        }
        .trueMaxCard()
    }
}

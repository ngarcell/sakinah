@preconcurrency import AVFoundation
import Foundation
import ImageIO
import Observation
import SwiftUI
import UIKit
@preconcurrency import Vision

nonisolated enum CameraPermissionState: String, Equatable, Sendable {
    case notDetermined
    case requesting
    case authorized
    case denied
    case restricted
}

nonisolated enum CameraCaptureError: Error, Equatable, LocalizedError, Sendable {
    case missingUsageDescription
    case permissionDenied
    case permissionRestricted
    case frontCameraUnavailable
    case cannotCreateInput(String)
    case cannotAddInput
    case cannotAddPhotoOutput
    case captureNotConfigured
    case cameraNotRunning
    case captureAlreadyInProgress
    case photoDataUnavailable
    case captureFailed(String)
    case runtime(String)

    var errorDescription: String? {
        switch self {
        case .missingUsageDescription:
            return "Camera access is not configured for this build."
        case .permissionDenied:
            return "Camera access is off. Allow camera access in Settings to scan."
        case .permissionRestricted:
            return "Camera access is restricted on this device."
        case .frontCameraUnavailable:
            return "A front camera is not available on this device."
        case .cannotCreateInput, .cannotAddInput, .cannotAddPhotoOutput:
            return "TrueMax could not configure the front camera."
        case .captureNotConfigured:
            return "The camera is still preparing. Try again in a moment."
        case .cameraNotRunning:
            return "The camera is not ready. Start the camera and try again."
        case .captureAlreadyInProgress:
            return "A photo is already being captured."
        case .photoDataUnavailable:
            return "TrueMax could not read this photo. Please try again."
        case .captureFailed:
            return "TrueMax could not capture this photo. Please try again."
        case .runtime:
            return "The camera stopped unexpectedly. Please try again."
        }
    }
}

nonisolated enum CameraLiveGuidanceState: String, Equatable, Sendable {
    case waitingForSample
    case ready
    case noFace
    case multipleFaces
    case centerFace
    case moveCloser
    case moveBack
    case moreLight
    case reduceLight
    case samplingUnavailable
}

/// A throttled, on-device summary of the latest preview frame.
///
/// This intentionally contains only framing/quality measurements, never a
/// preview image or biometric template. `samplingUnavailable` is a fail-open
/// fallback for devices that cannot attach a video-data output.
nonisolated struct CameraLiveGuidance: Equatable, Sendable {
    let state: CameraLiveGuidanceState
    let faceCount: Int?
    let faceCenterX: Double?
    let faceCenterY: Double?
    let faceArea: Double?
    let approximateLuminance: Double?

    var allowsCapture: Bool {
        state == .ready || state == .samplingUnavailable
    }

    var instruction: String {
        switch state {
        case .waitingForSample:
            return "Checking framing and light…"
        case .ready:
            return "Framing and light look ready"
        case .noFace:
            return "Center one face in the guide"
        case .multipleFaces:
            return "Only one face should be in frame"
        case .centerFace:
            return "Move your face toward the center"
        case .moveCloser:
            return "Move a little closer"
        case .moveBack:
            return "Move a little farther away"
        case .moreLight:
            return "Use a little more front-facing light"
        case .reduceLight:
            return "Reduce the light on your face"
        case .samplingUnavailable:
            return "Hold still and center your face"
        }
    }

    static let waiting = CameraLiveGuidance(
        state: .waitingForSample,
        faceCount: nil,
        faceCenterX: nil,
        faceCenterY: nil,
        faceArea: nil,
        approximateLuminance: nil
    )

    static let samplingUnavailable = CameraLiveGuidance(
        state: .samplingUnavailable,
        faceCount: nil,
        faceCenterX: nil,
        faceCenterY: nil,
        faceArea: nil,
        approximateLuminance: nil
    )
}

/// A deliberately small, transient summary derived from an AVDepthData map.
///
/// Values are robust regional medians in meters plus capture-quality
/// statistics. The raw depth map never leaves the photo delegate and this
/// value is not part of the persistence model.
nonisolated struct CameraDepthGeometry: Equatable, Sendable {
    let centerDepthMeters: Double
    let leftMidfaceDepthMeters: Double
    let rightMidfaceDepthMeters: Double
    let upperFaceDepthMeters: Double
    let lowerFaceDepthMeters: Double
    let leftJawDepthMeters: Double
    let rightJawDepthMeters: Double
    let validSampleFraction: Double
    let medianAbsoluteDeviationMeters: Double

    var isUsable: Bool {
        let depths = [
            centerDepthMeters,
            leftMidfaceDepthMeters,
            rightMidfaceDepthMeters,
            upperFaceDepthMeters,
            lowerFaceDepthMeters,
            leftJawDepthMeters,
            rightJawDepthMeters,
        ]
        return depths.allSatisfy {
            $0.isFinite && (0.15...2.5).contains($0)
        }
            && validSampleFraction.isFinite
            && validSampleFraction >= 0.35
            && medianAbsoluteDeviationMeters.isFinite
            && medianAbsoluteDeviationMeters >= 0
    }

    var reliability: Double {
        guard isUsable else { return 0 }
        let coverage = Self.clamped(
            (validSampleFraction - 0.35) / 0.55
        )
        let relativeNoise = medianAbsoluteDeviationMeters
            / max(centerDepthMeters, 0.001)
        let noiseQuality = 1 - Self.clamped(relativeNoise / 0.10)
        return Self.clamped(coverage * 0.58 + noiseQuality * 0.42)
    }

    var bilateralAsymmetry: Double {
        abs(leftMidfaceDepthMeters - rightMidfaceDepthMeters)
            / max(centerDepthMeters, 0.001)
    }

    var verticalDepthSpread: Double {
        abs(upperFaceDepthMeters - lowerFaceDepthMeters)
            / max(centerDepthMeters, 0.001)
    }

    var jawDepthAsymmetry: Double {
        abs(leftJawDepthMeters - rightJawDepthMeters)
            / max(centerDepthMeters, 0.001)
    }

    private static func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

struct CameraCapturedPhoto {
    let image: UIImage
    let captureMode: CaptureMode
    let depthGeometry: CameraDepthGeometry?

    var mode: CaptureMode {
        captureMode
    }
}

/// Scene-owned front-camera controller. All observable/UI state is main-actor
/// isolated; the capture pipeline owns AVFoundation work on a serial queue.
@MainActor
@Observable
final class CameraCaptureController {
    private(set) var permissionState: CameraPermissionState
    private(set) var captureMode: CaptureMode = .photo2D
    private(set) var isConfigured = false
    private(set) var isRunning = false
    private(set) var isCapturing = false
    private(set) var lastError: CameraCaptureError?
    private(set) var liveGuidance: CameraLiveGuidance = .waiting

    @ObservationIgnored private var wantsRunning = false
    @ObservationIgnored private var sceneIsActive = true
    @ObservationIgnored private var operationGeneration = 0
    @ObservationIgnored private var lifecycleTask: Task<Void, Never>?
    @ObservationIgnored private var guidanceFallbackTask: Task<Void, Never>?
    @ObservationIgnored private var pendingCompletion: ((
        Result<CameraCapturedPhoto, CameraCaptureError>
    ) -> Void)?

    @ObservationIgnored private lazy var pipeline = TrueMaxCapturePipeline {
        [weak self] event in
        Task { @MainActor [weak self] in
            self?.handle(event)
        }
    }

    var captureSession: AVCaptureSession {
        pipeline.session
    }

    var canCapture: Bool {
        permissionState == .authorized
            && isConfigured
            && isRunning
            && !isCapturing
            && liveGuidance.allowsCapture
    }

    init() {
        permissionState = Self.currentPermission
    }

    /// Authorizes, configures, and starts the camera, returning when this
    /// lifecycle attempt has completed.
    func prepare() async {
        wantsRunning = true
        operationGeneration += 1
        let generation = operationGeneration
        lifecycleTask?.cancel()
        lifecycleTask = nil
        guidanceFallbackTask?.cancel()
        liveGuidance = .waiting
        await authorizeConfigureAndStart(generation: generation)
    }

    /// Convenience for view lifecycle callbacks that cannot await.
    func start() {
        wantsRunning = true
        operationGeneration += 1
        let generation = operationGeneration
        lifecycleTask?.cancel()
        guidanceFallbackTask?.cancel()
        liveGuidance = .waiting
        lifecycleTask = Task { [weak self] in
            await self?.authorizeConfigureAndStart(generation: generation)
        }
    }

    func stop() {
        wantsRunning = false
        operationGeneration += 1
        lifecycleTask?.cancel()
        lifecycleTask = nil
        guidanceFallbackTask?.cancel()
        guidanceFallbackTask = nil
        isRunning = false
        isCapturing = false
        liveGuidance = .waiting
        failPendingCapture(with: .cameraNotRunning)

        Task { [pipeline] in
            await pipeline.stopRunning()
        }
    }

    /// Keeps a delayed authorization response from starting capture when the
    /// scene has already moved to the background.
    func setSceneActive(_ isActive: Bool) {
        guard sceneIsActive != isActive else { return }
        sceneIsActive = isActive

        if isActive {
            if wantsRunning {
                start()
            }
        } else {
            operationGeneration += 1
            lifecycleTask?.cancel()
            lifecycleTask = nil
            guidanceFallbackTask?.cancel()
            guidanceFallbackTask = nil
            isRunning = false
            isCapturing = false
            liveGuidance = .waiting
            failPendingCapture(with: .cameraNotRunning)
            Task { [pipeline] in
                await pipeline.stopRunning()
            }
        }
    }

    func retry() {
        lastError = nil
        start()
    }

    func capturePhoto(
        completion: @escaping (
            Result<CameraCapturedPhoto, CameraCaptureError>
        ) -> Void
    ) {
        guard permissionState == .authorized else {
            let failure: CameraCaptureError = permissionState == .restricted
                ? .permissionRestricted
                : .permissionDenied
            lastError = failure
            completion(.failure(failure))
            return
        }
        guard isConfigured else {
            lastError = .captureNotConfigured
            completion(.failure(.captureNotConfigured))
            return
        }
        guard isRunning else {
            lastError = .cameraNotRunning
            completion(.failure(.cameraNotRunning))
            return
        }
        guard !isCapturing, pendingCompletion == nil else {
            completion(.failure(.captureAlreadyInProgress))
            return
        }

        pendingCompletion = completion
        isCapturing = true
        lastError = nil

        Task { [weak self] in
            guard let self else { return }
            let result = await self.pipeline.capturePhoto()
            guard case .failure(let failure) = result else { return }
            self.isCapturing = false
            self.lastError = failure
            self.failPendingCapture(with: failure)
        }
    }

    func capturePhoto() async throws -> CameraCapturedPhoto {
        try await withCheckedThrowingContinuation { continuation in
            capturePhoto { result in
                switch result {
                case .success(let photo):
                    continuation.resume(returning: photo)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

@MainActor
private extension CameraCaptureController {
    static var currentPermission: CameraPermissionState {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .restricted
        }
    }

    var hasCameraUsageDescription: Bool {
        guard let value = Bundle.main.object(
            forInfoDictionaryKey: "NSCameraUsageDescription"
        ) as? String else {
            return false
        }
        return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func authorizeConfigureAndStart(generation: Int) async {
        guard hasCameraUsageDescription else {
            lastError = .missingUsageDescription
            return
        }

        permissionState = Self.currentPermission
        if permissionState == .notDetermined {
            permissionState = .requesting
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard isCurrent(generation) else { return }
            permissionState = granted ? .authorized : Self.currentPermission
        }

        guard isCurrent(generation) else { return }
        switch permissionState {
        case .authorized:
            break
        case .denied:
            lastError = .permissionDenied
            return
        case .restricted:
            lastError = .permissionRestricted
            return
        case .notDetermined, .requesting:
            lastError = .permissionDenied
            return
        }

        let configuration = await pipeline.configure()
        guard isCurrent(generation) else { return }

        switch configuration {
        case .success(let capability):
            isConfigured = true
            captureMode = capability == .trueDepth ? .depth3D : .photo2D
        case .failure(let failure):
            isConfigured = false
            lastError = failure
            return
        }

        let startResult = await pipeline.startRunning()
        guard isCurrent(generation) else {
            await pipeline.stopRunning()
            return
        }

        switch startResult {
        case .success:
            isRunning = true
            lastError = nil
            scheduleGuidanceFallback(generation: generation)
        case .failure(let failure):
            isRunning = false
            lastError = failure
        }
    }

    func isCurrent(_ generation: Int) -> Bool {
        generation == operationGeneration
            && wantsRunning
            && sceneIsActive
            && !Task.isCancelled
    }

    func handle(_ event: TrueMaxCaptureEvent) {
        switch event {
        case .captured(let data, let depthGeometry):
            isCapturing = false
            guard let image = UIImage(data: data) else {
                lastError = .photoDataUnavailable
                failPendingCapture(with: .photoDataUnavailable)
                return
            }

            let deliveredMode: CaptureMode = depthGeometry?.isUsable == true
                ? .depth3D
                : .photo2D
            captureMode = deliveredMode
            let photo = CameraCapturedPhoto(
                image: image,
                captureMode: deliveredMode,
                depthGeometry: depthGeometry
            )
            let completion = pendingCompletion
            pendingCompletion = nil
            completion?(.success(photo))

        case .failed(let failure):
            isCapturing = false
            if case .runtime = failure {
                isRunning = false
            }
            lastError = failure
            failPendingCapture(with: failure)

        case .interrupted:
            isRunning = false
            isCapturing = false
            failPendingCapture(with: .cameraNotRunning)

        case .interruptionEnded:
            if wantsRunning, sceneIsActive {
                start()
            }

        case .guidance(let guidance):
            liveGuidance = guidance
            if guidance.state != .waitingForSample {
                guidanceFallbackTask?.cancel()
                guidanceFallbackTask = nil
            }
        }
    }

    func scheduleGuidanceFallback(generation: Int) {
        guidanceFallbackTask?.cancel()
        guard liveGuidance.state == .waitingForSample else { return }

        guidanceFallbackTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled,
                  let self,
                  self.isCurrent(generation),
                  self.isRunning,
                  self.liveGuidance.state == .waitingForSample else {
                return
            }
            // Photo capture remains available when frame sampling is not
            // supported or does not start. Final Vision analysis still
            // validates face count, size, and pose before saving anything.
            self.liveGuidance = .samplingUnavailable
        }
    }

    func failPendingCapture(with failure: CameraCaptureError) {
        let completion = pendingCompletion
        pendingCompletion = nil
        completion?(.failure(failure))
    }
}

nonisolated private enum TrueMaxCaptureCapability: Equatable, Sendable {
    case trueDepth
    case photo
}

nonisolated private enum TrueMaxCaptureEvent: Sendable {
    case captured(Data, depthGeometry: CameraDepthGeometry?)
    case failed(CameraCaptureError)
    case interrupted
    case interruptionEnded
    case guidance(CameraLiveGuidance)
}

/// Serializes all mutable AVFoundation state away from the main actor.
nonisolated private final class TrueMaxCapturePipeline:
    NSObject,
    @unchecked Sendable,
    AVCapturePhotoCaptureDelegate,
    AVCaptureVideoDataOutputSampleBufferDelegate
{
    let session = AVCaptureSession()

    private let eventHandler: @Sendable (TrueMaxCaptureEvent) -> Void
    private let sessionQueue = DispatchQueue(
        label: "TrueMax.Camera.Session",
        qos: .userInitiated
    )
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(
        label: "TrueMax.Camera.LiveGuidance",
        qos: .userInitiated
    )
    private var observers: [NSObjectProtocol] = []
    private var isConfigured = false
    private var capability: TrueMaxCaptureCapability = .photo
    private var isPhotoCaptureInFlight = false
    private var hasLiveSampling = false
    private var lastLiveSampleUptime: TimeInterval = 0

    init(
        eventHandler: @escaping @Sendable (TrueMaxCaptureEvent) -> Void
    ) {
        self.eventHandler = eventHandler
        super.init()
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func configure() async -> Result<
        TrueMaxCaptureCapability,
        CameraCaptureError
    > {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(
                        returning: .failure(.captureNotConfigured)
                    )
                    return
                }
                continuation.resume(returning: self.configureOnSessionQueue())
            }
        }
    }

    func startRunning() async -> Result<Void, CameraCaptureError> {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self, self.isConfigured else {
                    continuation.resume(
                        returning: .failure(.captureNotConfigured)
                    )
                    return
                }
                if !self.session.isRunning {
                    self.session.startRunning()
                }
                continuation.resume(returning: .success(()))
            }
        }
    }

    func stopRunning() async {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                if let self = self, self.session.isRunning {
                    self.session.stopRunning()
                }
                continuation.resume()
            }
        }
    }

    func capturePhoto() async -> Result<Void, CameraCaptureError> {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(
                        returning: .failure(.captureNotConfigured)
                    )
                    return
                }
                continuation.resume(returning: self.captureOnSessionQueue())
            }
        }
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let event: TrueMaxCaptureEvent
        if let error {
            event = .failed(.captureFailed(error.localizedDescription))
        } else if let data = photo.fileDataRepresentation() {
            event = .captured(
                data,
                depthGeometry: Self.depthGeometry(
                    from: photo.depthData,
                    orientation: Self.exifOrientation(
                        from: photo.metadata
                    )
                )
            )
        } else {
            event = .failed(.photoDataUnavailable)
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.isPhotoCaptureInFlight = false
            self.eventHandler(event)
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastLiveSampleUptime >= 0.55 else { return }
        lastLiveSampleUptime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            eventHandler(.guidance(.samplingUnavailable))
            return
        }

        autoreleasepool {
            eventHandler(
                .guidance(Self.liveGuidance(from: pixelBuffer))
            )
        }
    }
}

nonisolated private extension TrueMaxCapturePipeline {
    func configureOnSessionQueue() -> Result<
        TrueMaxCaptureCapability,
        CameraCaptureError
    > {
        if isConfigured {
            applyPhotoConnectionConfiguration()
            applyVideoConnectionConfiguration()
            return .success(capability)
        }

        let trueDepthCamera = AVCaptureDevice.default(
            .builtInTrueDepthCamera,
            for: .video,
            position: .front
        )
        let camera = trueDepthCamera ?? AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        )
        guard let camera else {
            return .failure(.frontCameraUnavailable)
        }

        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: camera)
        } catch {
            return .failure(.cannotCreateInput(error.localizedDescription))
        }

        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }

        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        }

        guard session.canAddInput(input) else {
            return .failure(.cannotAddInput)
        }
        session.addInput(input)

        guard session.canAddOutput(photoOutput) else {
            session.removeInput(input)
            return .failure(.cannotAddPhotoOutput)
        }
        session.addOutput(photoOutput)
        photoOutput.maxPhotoQualityPrioritization = .quality

        videoOutput.alwaysDiscardsLateVideoFrames = true
        let nativePixelFormat: OSType
        if videoOutput.availableVideoPixelFormatTypes.contains(
            kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ) {
            nativePixelFormat =
                kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        } else if videoOutput.availableVideoPixelFormatTypes.contains(
            kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        ) {
            nativePixelFormat =
                kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        } else {
            nativePixelFormat = kCVPixelFormatType_32BGRA
        }
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String:
                Int(nativePixelFormat),
        ]
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            hasLiveSampling = true
        } else {
            hasLiveSampling = false
            videoOutput.setSampleBufferDelegate(nil, queue: nil)
        }

        let supportsTrueDepth = camera.deviceType == .builtInTrueDepthCamera
            && photoOutput.isDepthDataDeliverySupported
        photoOutput.isDepthDataDeliveryEnabled = supportsTrueDepth
        capability = supportsTrueDepth ? .trueDepth : .photo

        configureDevice(camera)
        applyPhotoConnectionConfiguration()
        applyVideoConnectionConfiguration()
        installSessionObservers()
        isConfigured = true
        if !hasLiveSampling {
            eventHandler(.guidance(.samplingUnavailable))
        }
        return .success(capability)
    }

    func configureDevice(_ camera: AVCaptureDevice) {
        do {
            try camera.lockForConfiguration()
            defer { camera.unlockForConfiguration() }

            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            }
            if camera.isExposureModeSupported(.continuousAutoExposure) {
                camera.exposureMode = .continuousAutoExposure
            }
            if camera.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                camera.whiteBalanceMode = .continuousAutoWhiteBalance
            }
        } catch {
            // Device defaults remain safe and usable if configuration is locked.
        }
    }

    func captureOnSessionQueue() -> Result<Void, CameraCaptureError> {
        guard isConfigured else {
            return .failure(.captureNotConfigured)
        }
        guard session.isRunning else {
            return .failure(.cameraNotRunning)
        }
        guard !isPhotoCaptureInFlight else {
            return .failure(.captureAlreadyInProgress)
        }

        let settings: AVCapturePhotoSettings
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings = AVCapturePhotoSettings(
                format: [AVVideoCodecKey: AVVideoCodecType.hevc]
            )
        } else {
            settings = AVCapturePhotoSettings()
        }

        settings.photoQualityPrioritization = .quality
        if capability == .trueDepth,
           photoOutput.isDepthDataDeliverySupported,
           photoOutput.isDepthDataDeliveryEnabled {
            settings.isDepthDataDeliveryEnabled = true
            settings.isDepthDataFiltered = true
            // The transient depth map confirms capture capability, but is not
            // embedded in the JPEG that can later be stored by the app.
            settings.embedsDepthDataInPhoto = false
        }

        applyPhotoConnectionConfiguration()
        isPhotoCaptureInFlight = true
        photoOutput.capturePhoto(with: settings, delegate: self)
        return .success(())
    }

    func applyPhotoConnectionConfiguration() {
        guard let connection = photoOutput.connection(with: .video) else {
            return
        }
        if connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
    }

    func applyVideoConnectionConfiguration() {
        guard hasLiveSampling,
              let connection = videoOutput.connection(with: .video) else {
            return
        }
        if connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
    }

    static func depthGeometry(
        from sourceDepthData: AVDepthData?,
        orientation: CGImagePropertyOrientation
    ) -> CameraDepthGeometry? {
        guard let sourceDepthData else { return nil }

        let orientedDepthData = sourceDepthData.applyingExifOrientation(
            orientation
        )
        let depthData: AVDepthData
        if orientedDepthData.depthDataType
            == kCVPixelFormatType_DepthFloat32 {
            depthData = orientedDepthData
        } else {
            // AVDepthData raises an Objective-C exception for unsupported
            // conversion targets, so validate before requesting Float32.
            guard orientedDepthData.availableDepthDataTypes.contains(
                kCVPixelFormatType_DepthFloat32
            ) else {
                return nil
            }
            depthData = orientedDepthData.converting(
                toDepthDataType: kCVPixelFormatType_DepthFloat32
            )
        }

        let map = depthData.depthDataMap
        guard CVPixelBufferGetPixelFormatType(map)
                == kCVPixelFormatType_DepthFloat32,
              CVPixelBufferLockBaseAddress(map, .readOnly)
                == kCVReturnSuccess else {
            return nil
        }
        defer {
            CVPixelBufferUnlockBaseAddress(map, .readOnly)
        }

        let width = CVPixelBufferGetWidth(map)
        let height = CVPixelBufferGetHeight(map)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(map)
        guard width >= 16,
              height >= 16,
              let baseAddress = CVPixelBufferGetBaseAddress(map) else {
            return nil
        }

        let samplingStep = max(1, min(width, height) / 96)

        func samples(in normalizedRect: CGRect) -> (
            values: [Double],
            attempted: Int
        ) {
            let minimumX = max(
                0,
                min(width - 1, Int(normalizedRect.minX * CGFloat(width)))
            )
            let maximumX = max(
                minimumX,
                min(width - 1, Int(normalizedRect.maxX * CGFloat(width)))
            )
            let minimumY = max(
                0,
                min(height - 1, Int(normalizedRect.minY * CGFloat(height)))
            )
            let maximumY = max(
                minimumY,
                min(height - 1, Int(normalizedRect.maxY * CGFloat(height)))
            )

            var values: [Double] = []
            var attempted = 0
            for y in stride(
                from: minimumY,
                through: maximumY,
                by: samplingStep
            ) {
                let row = baseAddress
                    .advanced(by: y * bytesPerRow)
                    .assumingMemoryBound(to: Float.self)
                for x in stride(
                    from: minimumX,
                    through: maximumX,
                    by: samplingStep
                ) {
                    attempted += 1
                    let value = Double(row[x])
                    if value.isFinite, (0.15...2.5).contains(value) {
                        values.append(value)
                    }
                }
            }
            return (values, attempted)
        }

        func median(_ values: [Double]) -> Double? {
            guard !values.isEmpty else { return nil }
            let sorted = values.sorted()
            let middle = sorted.count / 2
            if sorted.count.isMultiple(of: 2) {
                return (sorted[middle - 1] + sorted[middle]) / 2
            }
            return sorted[middle]
        }

        // The photo connection is portrait-oriented. These broad regions are
        // intentionally tolerant of face shape and use the centered framing
        // enforced by live guidance.
        let center = samples(
            in: CGRect(x: 0.42, y: 0.34, width: 0.16, height: 0.22)
        )
        let leftMidface = samples(
            in: CGRect(x: 0.25, y: 0.37, width: 0.16, height: 0.22)
        )
        let rightMidface = samples(
            in: CGRect(x: 0.59, y: 0.37, width: 0.16, height: 0.22)
        )
        let upperFace = samples(
            in: CGRect(x: 0.34, y: 0.18, width: 0.32, height: 0.16)
        )
        let lowerFace = samples(
            in: CGRect(x: 0.34, y: 0.60, width: 0.32, height: 0.18)
        )
        let leftJaw = samples(
            in: CGRect(x: 0.25, y: 0.58, width: 0.21, height: 0.20)
        )
        let rightJaw = samples(
            in: CGRect(x: 0.54, y: 0.58, width: 0.21, height: 0.20)
        )
        let faceRegion = samples(
            in: CGRect(x: 0.22, y: 0.16, width: 0.56, height: 0.64)
        )

        guard let centerDepth = median(center.values),
              let leftMidfaceDepth = median(leftMidface.values),
              let rightMidfaceDepth = median(rightMidface.values),
              let upperFaceDepth = median(upperFace.values),
              let lowerFaceDepth = median(lowerFace.values),
              let leftJawDepth = median(leftJaw.values),
              let rightJawDepth = median(rightJaw.values),
              let faceMedian = median(faceRegion.values),
              faceRegion.values.count >= 24,
              faceRegion.attempted > 0 else {
            return nil
        }

        let deviations = faceRegion.values.map { abs($0 - faceMedian) }
        guard let medianAbsoluteDeviation = median(deviations) else {
            return nil
        }

        let geometry = CameraDepthGeometry(
            centerDepthMeters: centerDepth,
            leftMidfaceDepthMeters: leftMidfaceDepth,
            rightMidfaceDepthMeters: rightMidfaceDepth,
            upperFaceDepthMeters: upperFaceDepth,
            lowerFaceDepthMeters: lowerFaceDepth,
            leftJawDepthMeters: leftJawDepth,
            rightJawDepthMeters: rightJawDepth,
            validSampleFraction: Double(faceRegion.values.count)
                / Double(faceRegion.attempted),
            medianAbsoluteDeviationMeters: medianAbsoluteDeviation
        )
        return geometry.isUsable ? geometry : nil
    }

    static func exifOrientation(
        from metadata: [String: Any]
    ) -> CGImagePropertyOrientation {
        let key = kCGImagePropertyOrientation as String
        if let number = metadata[key] as? NSNumber,
           let orientation = CGImagePropertyOrientation(
               rawValue: number.uint32Value
           ) {
            return orientation
        }
        if let rawValue = metadata[key] as? UInt32,
           let orientation = CGImagePropertyOrientation(rawValue: rawValue) {
            return orientation
        }
        return .up
    }

    static func liveGuidance(
        from pixelBuffer: CVPixelBuffer
    ) -> CameraLiveGuidance {
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up,
            options: [:]
        )

        do {
            try handler.perform([request])
        } catch {
            return .samplingUnavailable
        }

        let faces = request.results ?? []
        guard faces.count == 1, let face = faces.first else {
            let luminance = approximateLuminance(
                in: pixelBuffer,
                normalizedBounds: CGRect(
                    x: 0.25,
                    y: 0.20,
                    width: 0.50,
                    height: 0.60
                )
            )
            return CameraLiveGuidance(
                state: faces.isEmpty ? .noFace : .multipleFaces,
                faceCount: faces.count,
                faceCenterX: nil,
                faceCenterY: nil,
                faceArea: nil,
                approximateLuminance: luminance
            )
        }

        let bounds = face.boundingBox
        let centerX = Double(bounds.midX)
        let centerY = Double(bounds.midY)
        let faceArea = Double(bounds.width * bounds.height)
        let luminance = approximateLuminance(
            in: pixelBuffer,
            normalizedBounds: bounds
        )

        let state: CameraLiveGuidanceState
        if bounds.width < 0.22
            || bounds.height < 0.28
            || bounds.width * bounds.height < 0.085 {
            state = .moveCloser
        } else if bounds.width > 0.78
            || bounds.height > 0.90
            || bounds.width * bounds.height > 0.58 {
            state = .moveBack
        } else if abs(bounds.midX - 0.50) > 0.14
            || abs(bounds.midY - 0.52) > 0.18 {
            state = .centerFace
        } else if let luminance, luminance < 0.16 {
            state = .moreLight
        } else if let luminance, luminance > 0.94 {
            state = .reduceLight
        } else {
            state = .ready
        }

        return CameraLiveGuidance(
            state: state,
            faceCount: 1,
            faceCenterX: centerX,
            faceCenterY: centerY,
            faceArea: faceArea,
            approximateLuminance: luminance
        )
    }

    static func approximateLuminance(
        in pixelBuffer: CVPixelBuffer,
        normalizedBounds visionBounds: CGRect
    ) -> Double? {
        guard CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
                == kCVReturnSuccess else {
            return nil
        }
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        guard width > 0, height > 0 else { return nil }

        // Vision uses a bottom-left origin; pixel buffers use top-left.
        let topLeftBounds = CGRect(
            x: visionBounds.minX,
            y: 1 - visionBounds.maxY,
            width: visionBounds.width,
            height: visionBounds.height
        ).insetBy(
            dx: visionBounds.width * 0.12,
            dy: visionBounds.height * 0.12
        )
        let minimumX = max(
            0,
            min(width - 1, Int(topLeftBounds.minX * CGFloat(width)))
        )
        let maximumX = max(
            minimumX,
            min(width - 1, Int(topLeftBounds.maxX * CGFloat(width)))
        )
        let minimumY = max(
            0,
            min(height - 1, Int(topLeftBounds.minY * CGFloat(height)))
        )
        let maximumY = max(
            minimumY,
            min(height - 1, Int(topLeftBounds.maxY * CGFloat(height)))
        )
        let xStep = max(1, (maximumX - minimumX) / 48)
        let yStep = max(1, (maximumY - minimumY) / 48)

        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        var luminanceTotal = 0.0
        var sampleCount = 0

        if pixelFormat == kCVPixelFormatType_32BGRA,
           let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) {
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
            for y in stride(from: minimumY, through: maximumY, by: yStep) {
                let row = baseAddress
                    .advanced(by: y * bytesPerRow)
                    .assumingMemoryBound(to: UInt8.self)
                for x in stride(
                    from: minimumX,
                    through: maximumX,
                    by: xStep
                ) {
                    let offset = x * 4
                    let blue = Double(row[offset])
                    let green = Double(row[offset + 1])
                    let red = Double(row[offset + 2])
                    luminanceTotal += (
                        red * 0.2126
                            + green * 0.7152
                            + blue * 0.0722
                    ) / 255
                    sampleCount += 1
                }
            }
        } else if CVPixelBufferIsPlanar(pixelBuffer),
                  CVPixelBufferGetPlaneCount(pixelBuffer) > 0,
                  let lumaAddress = CVPixelBufferGetBaseAddressOfPlane(
                    pixelBuffer,
                    0
                  ) {
            let lumaWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
            let lumaHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
            guard lumaWidth > 0, lumaHeight > 0 else { return nil }
            let scaleX = Double(lumaWidth) / Double(width)
            let scaleY = Double(lumaHeight) / Double(height)
            for y in stride(from: minimumY, through: maximumY, by: yStep) {
                let lumaY = min(lumaHeight - 1, Int(Double(y) * scaleY))
                let row = lumaAddress
                    .advanced(by: lumaY * bytesPerRow)
                    .assumingMemoryBound(to: UInt8.self)
                for x in stride(
                    from: minimumX,
                    through: maximumX,
                    by: xStep
                ) {
                    let lumaX = min(lumaWidth - 1, Int(Double(x) * scaleX))
                    let rawLuma = Double(row[lumaX])
                    if pixelFormat
                        == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange {
                        luminanceTotal += min(
                            max((rawLuma - 16) / 219, 0),
                            1
                        )
                    } else {
                        luminanceTotal += rawLuma / 255
                    }
                    sampleCount += 1
                }
            }
        }

        guard sampleCount > 0 else { return nil }
        return min(max(luminanceTotal / Double(sampleCount), 0), 1)
    }

    func installSessionObservers() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default

        observers.append(
            center.addObserver(
                forName: AVCaptureSession.wasInterruptedNotification,
                object: session,
                queue: nil
            ) { [weak self] _ in
                self?.eventHandler(.interrupted)
            }
        )
        observers.append(
            center.addObserver(
                forName: AVCaptureSession.interruptionEndedNotification,
                object: session,
                queue: nil
            ) { [weak self] _ in
                self?.eventHandler(.interruptionEnded)
            }
        )
        observers.append(
            center.addObserver(
                forName: AVCaptureSession.runtimeErrorNotification,
                object: session,
                queue: nil
            ) { [weak self] notification in
                let error = notification.userInfo?[
                    AVCaptureSessionErrorKey
                ] as? NSError
                let message = error?.localizedDescription
                    ?? "Camera capture stopped unexpectedly."
                self?.eventHandler(.failed(.runtime(message)))
            }
        )
    }
}

@MainActor
struct CameraCapturePreview: UIViewRepresentable {
    private let session: AVCaptureSession

    init(session: AVCaptureSession) {
        self.session = session
    }

    init(controller: CameraCaptureController) {
        self.session = controller.captureSession
    }

    func makeUIView(context: Context) -> TrueMaxCameraPreviewView {
        let view = TrueMaxCameraPreviewView()
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.session = session
        view.configureConnection()
        return view
    }

    func updateUIView(
        _ view: TrueMaxCameraPreviewView,
        context: Context
    ) {
        if view.previewLayer.session !== session {
            view.previewLayer.session = session
        }
        view.configureConnection()
    }
}

@MainActor
final class TrueMaxCameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
        isAccessibilityElement = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        configureConnection()
    }

    func configureConnection() {
        guard let connection = previewLayer.connection else { return }
        if connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
    }
}

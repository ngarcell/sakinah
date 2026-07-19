import CoreGraphics
import Foundation
import ImageIO
import UIKit
@preconcurrency import Vision

nonisolated enum TrueMaxAnalysisError: Error, Equatable, LocalizedError, Sendable {
    case invalidImage
    case noFaceDetected
    case multipleFacesDetected
    case faceTooSmall
    case faceNotStraight
    case incompleteLandmarks
    case analysisFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "TrueMax could not read this image. Please take another photo."
        case .noFaceDetected:
            return "No face was detected. Center your face in the guide and try again."
        case .multipleFacesDetected:
            return "More than one face was detected. Take a photo with only you in frame."
        case .faceTooSmall:
            return "Move a little closer so your face fills the guide."
        case .faceNotStraight:
            return "Look straight at the camera and keep your head level."
        case .incompleteLandmarks:
            return "Some facial landmarks were not clear. Use even light and try again."
        case .analysisFailed:
            return "TrueMax could not finish this scan. Please try again."
        }
    }
}

/// On-device facial landmark analysis.
///
/// UIKit image encoding stays on the main actor. Vision and pixel sampling run
/// off the main actor with a `Data` boundary, so no non-Sendable `UIImage`
/// crosses an isolation domain.
@MainActor
enum TrueMaxAnalysisEngine {
    static func analyze(
        image: UIImage,
        captureMode: CaptureMode,
        depthGeometry: CameraDepthGeometry? = nil
    ) async throws -> TrueMaxAnalysisResult {
        guard let encodedImage = image.jpegData(compressionQuality: 0.98) else {
            throw TrueMaxAnalysisError.invalidImage
        }

        let usableDepthGeometry = captureMode == .depth3D
            && depthGeometry?.isUsable == true
            ? depthGeometry
            : nil
        let effectiveCaptureMode: CaptureMode = usableDepthGeometry == nil
            ? .photo2D
            : .depth3D

        let rawResult = try await TrueMaxAnalysisBridge.analyze(
            encodedImage: encodedImage,
            depthGeometry: usableDepthGeometry
        )

        return TrueMaxAnalysisResult(
            captureMode: effectiveCaptureMode,
            confidence: effectiveCaptureMode.confidence,
            symmetry: MetricRangeValue(
                low: rawResult.symmetry.low,
                high: rawResult.symmetry.high,
                unit: .index
            ),
            proportion: MetricRangeValue(
                low: rawResult.proportion.low,
                high: rawResult.proportion.high,
                unit: .index
            ),
            canthalTilt: MetricRangeValue(
                low: rawResult.canthalTilt.low,
                high: rawResult.canthalTilt.high,
                unit: .degrees
            ),
            jawAngle: MetricRangeValue(
                low: rawResult.jawAngle.low,
                high: rawResult.jawAngle.high,
                unit: .degrees
            ),
            skinTexture: MetricRangeValue(
                low: rawResult.skinTexture.low,
                high: rawResult.skinTexture.high,
                unit: .index
            ),
            guidance: rawResult.guidance.map(guidanceItem(for:)),
            qualityNote: qualityNote(
                captureMode: effectiveCaptureMode,
                faceCaptureQuality: rawResult.faceCaptureQuality
            )
        )
    }

    private static func qualityNote(
        captureMode: CaptureMode,
        faceCaptureQuality: Double?
    ) -> String {
        let captureNote: String
        switch captureMode {
        case .depth3D:
            captureNote = "Transient TrueDepth geometry refined the uncertainty of this on-device analysis. No depth map is saved. Results can still vary with expression, pose, and lighting."
        case .photo2D:
            captureNote = "Photo mode estimates visible 2D landmarks only, so its ranges are intentionally wider. Lighting, pose, and lens distance can change them."
        }

        guard let faceCaptureQuality else {
            return captureNote
        }

        if faceCaptureQuality < 0.45 {
            return "\(captureNote) This image had limited capture detail; use the same even lighting when comparing scans."
        }
        return captureNote
    }

    private static func guidanceItem(
        for key: TrueMaxGuidanceKey
    ) -> GuidanceItem {
        switch key {
        case .consistentCapture:
            return GuidanceItem(
                id: UUID(uuidString: "ED1981CB-C9E5-4318-9101-84021C169B55")!,
                category: .presentation,
                priority: "Start here",
                title: "Make the next scan comparable",
                detail: "Use soft front-facing light, a relaxed expression, and the same camera distance. Consistency makes changes easier to compare."
            )
        case .levelCamera:
            return GuidanceItem(
                id: UUID(uuidString: "4554A8EA-D24E-45E4-B9D7-FEC07A432F83")!,
                category: .presentation,
                priority: "Start here",
                title: "Level the camera",
                detail: "Place the lens near eye height and keep the phone upright. This reduces perspective changes without judging your features."
            )
        case .compareFraming:
            return GuidanceItem(
                id: UUID(uuidString: "6801AF04-E0DB-4B77-84DF-E8EB6D0AAB29")!,
                category: .hair,
                priority: "Next",
                title: "Compare two framing lengths",
                detail: "Save one close-framing and one open-framing style, then compare them in the same light before choosing."
            )
        case .textureIsImageDependent:
            return GuidanceItem(
                id: UUID(uuidString: "B896D63B-3DA6-448F-B928-B1DDBF70482F")!,
                category: .skin,
                priority: "Keep in mind",
                title: "Treat texture as image-dependent",
                detail: "Camera sharpening and side lighting can exaggerate visible texture. Use this as a photo comparison, not a skin-health assessment."
            )
        case .compareAccessories:
            return GuidanceItem(
                id: UUID(uuidString: "4859193B-5A4E-4AF5-8698-33A61DA586F3")!,
                category: .style,
                priority: "Optional",
                title: "Test one variable at a time",
                detail: "When comparing eyewear or facial-hair framing, keep your angle and expression unchanged so the difference is easier to see."
            )
        }
    }
}

nonisolated private enum TrueMaxGuidanceKey: Equatable, Sendable {
    case consistentCapture
    case levelCamera
    case compareFraming
    case textureIsImageDependent
    case compareAccessories
}

nonisolated private struct TrueMaxRawRange: Sendable {
    let low: Double
    let high: Double
}

nonisolated private struct TrueMaxRawAnalysisResult: Sendable {
    let symmetry: TrueMaxRawRange
    let proportion: TrueMaxRawRange
    let canthalTilt: TrueMaxRawRange
    let jawAngle: TrueMaxRawRange
    let skinTexture: TrueMaxRawRange
    let guidance: [TrueMaxGuidanceKey]
    let faceCaptureQuality: Double?
}

nonisolated private struct TrueMaxUncertaintyProfile: Sendable {
    let symmetry: Double
    let proportion: Double
    let canthal: Double
    let jaw: Double
    let texture: Double
}

nonisolated private enum TrueMaxAnalysisBridge {
    static func analyze(
        encodedImage: Data,
        depthGeometry: CameraDepthGeometry?
    ) async throws -> TrueMaxRawAnalysisResult {
        try await Task.detached(priority: .userInitiated) {
            try analyzeSynchronously(
                encodedImage: encodedImage,
                depthGeometry: depthGeometry
            )
        }.value
    }

    private static func analyzeSynchronously(
        encodedImage: Data,
        depthGeometry: CameraDepthGeometry?
    ) throws -> TrueMaxRawAnalysisResult {
        guard let image = decodedUprightImage(from: encodedImage) else {
            throw TrueMaxAnalysisError.invalidImage
        }

        let landmarkRequest = VNDetectFaceLandmarksRequest()
        let qualityRequest = VNDetectFaceCaptureQualityRequest()
        let handler = VNImageRequestHandler(cgImage: image, orientation: .up)

        do {
            try handler.perform([landmarkRequest, qualityRequest])
        } catch {
            throw TrueMaxAnalysisError.analysisFailed(error.localizedDescription)
        }

        let faces = landmarkRequest.results ?? []
        guard !faces.isEmpty else {
            throw TrueMaxAnalysisError.noFaceDetected
        }
        guard faces.count == 1 else {
            throw TrueMaxAnalysisError.multipleFacesDetected
        }

        let face = faces[0]
        guard face.boundingBox.width >= 0.22,
              face.boundingBox.height >= 0.22,
              face.boundingBox.width * face.boundingBox.height >= 0.075 else {
            throw TrueMaxAnalysisError.faceTooSmall
        }

        let yaw = abs(face.yaw?.doubleValue ?? 0)
        let roll = abs(face.roll?.doubleValue ?? 0)
        guard yaw <= 0.38, roll <= 0.34 else {
            throw TrueMaxAnalysisError.faceNotStraight
        }

        guard let landmarks = face.landmarks else {
            throw TrueMaxAnalysisError.incompleteLandmarks
        }

        let leftEye = imagePoints(landmarks.leftEye, face: face)
        let rightEye = imagePoints(landmarks.rightEye, face: face)
        let nose = imagePoints(landmarks.nose, face: face)
        let noseCrest = imagePoints(landmarks.noseCrest, face: face)
        let mouth = imagePoints(landmarks.outerLips, face: face)
        let contour = imagePoints(landmarks.faceContour, face: face)
        let medianLine = imagePoints(landmarks.medianLine, face: face)

        guard leftEye.count >= 4,
              rightEye.count >= 4,
              !nose.isEmpty,
              mouth.count >= 4,
              contour.count >= 8 else {
            throw TrueMaxAnalysisError.incompleteLandmarks
        }

        let faceWidth = max(face.boundingBox.width, 0.001)
        let faceHeight = max(face.boundingBox.height, 0.001)
        let leftEyeCenter = centroid(leftEye)
        let rightEyeCenter = centroid(rightEye)
        let eyeSpacing = max(distance(leftEyeCenter, rightEyeCenter), faceWidth * 0.12)
        let eyeLineY = (leftEyeCenter.y + rightEyeCenter.y) / 2
        let noseCenter = centroid(nose)
        let mouthCenter = centroid(mouth)
        let midlineX = medianLine.isEmpty
            ? centroid(noseCrest.isEmpty ? nose : noseCrest).x
            : centroid(medianLine).x

        let symmetryMidpoint = symmetryIndex(
            leftEye: leftEye,
            rightEye: rightEye,
            leftEyeCenter: leftEyeCenter,
            rightEyeCenter: rightEyeCenter,
            noseCenter: noseCenter,
            mouthCenter: mouthCenter,
            midlineX: midlineX,
            eyeSpacing: eyeSpacing,
            faceWidth: faceWidth
        )

        let proportionMidpoint = proportionIndex(
            face: face.boundingBox,
            eyeLineY: eyeLineY,
            noseY: noseCenter.y,
            mouthY: mouthCenter.y,
            contour: contour,
            leftEyeCenter: leftEyeCenter,
            rightEyeCenter: rightEyeCenter
        )

        let rollDegrees = (face.roll?.doubleValue ?? 0) * 180 / .pi
        let canthalMidpoint = clamped(
            (
                eyeAngle(leftEye)
                + eyeAngle(rightEye)
            ) / 2 - rollDegrees,
            to: -20...20
        )

        let jawMidpoint = jawContourAngle(
            contour: contour,
            faceHeight: faceHeight
        )
        let textureMidpoint = visibleTextureIndex(
            image: image,
            faceBounds: face.boundingBox
        )

        let qualityFaces = qualityRequest.results ?? []
        let quality = qualityFaces.max(by: {
            area($0.boundingBox) < area($1.boundingBox)
        })?.faceCaptureQuality?.doubleValue

        let uncertainty = uncertaintyProfile(
            depthGeometry: depthGeometry,
            faceCaptureQuality: quality,
            yawRadians: yaw,
            rollRadians: roll,
            faceArea: area(face.boundingBox)
        )

        var guidance: [TrueMaxGuidanceKey] = [.consistentCapture]
        if abs(canthalMidpoint) > 6 || roll > 0.16 {
            guidance[0] = .levelCamera
        }
        guidance.append(
            proportionMidpoint < 72 ? .compareFraming : .compareAccessories
        )
        if textureMidpoint > 22 {
            guidance.append(.textureIsImageDependent)
        } else if !guidance.contains(where: { $0 == .compareAccessories }) {
            guidance.append(.compareAccessories)
        }

        return TrueMaxRawAnalysisResult(
            symmetry: range(
                around: symmetryMidpoint,
                uncertainty: uncertainty.symmetry,
                limits: 0...100
            ),
            proportion: range(
                around: proportionMidpoint,
                uncertainty: uncertainty.proportion,
                limits: 0...100
            ),
            canthalTilt: range(
                around: canthalMidpoint,
                uncertainty: uncertainty.canthal,
                limits: -25...25
            ),
            jawAngle: range(
                around: jawMidpoint,
                uncertainty: uncertainty.jaw,
                limits: 70...170
            ),
            skinTexture: range(
                around: textureMidpoint,
                uncertainty: uncertainty.texture,
                limits: 0...100
            ),
            guidance: guidance,
            faceCaptureQuality: quality
        )
    }

    /// Uses actual compact depth geometry to refine only the measurements it
    /// can support. Canthal tilt and visible texture remain 2D image
    /// measurements and therefore do not get a confidence upgrade merely
    /// because a depth map existed.
    private static func uncertaintyProfile(
        depthGeometry: CameraDepthGeometry?,
        faceCaptureQuality: Double?,
        yawRadians: Double,
        rollRadians: Double,
        faceArea: Double
    ) -> TrueMaxUncertaintyProfile {
        let base: TrueMaxUncertaintyProfile
        if let depthGeometry, depthGeometry.isUsable {
            let reliability = depthGeometry.reliability

            // Large left/right offsets are usually residual pose or incomplete
            // face coverage, so they reduce how much depth narrows the range.
            let bilateralQuality = 1 - clamped(
                depthGeometry.bilateralAsymmetry / 0.16,
                to: 0...1
            )
            let jawBilateralQuality = 1 - clamped(
                depthGeometry.jawDepthAsymmetry / 0.18,
                to: 0...1
            )

            // Extreme upper/lower separation often means pitch or partial depth
            // coverage. It is used as a quality signal, not as an aesthetic score.
            let verticalQuality = 1 - clamped(
                depthGeometry.verticalDepthSpread / 0.42,
                to: 0...1
            )

            let symmetryQuality = reliability * (0.55 + bilateralQuality * 0.45)
            let proportionQuality = reliability * (0.52 + verticalQuality * 0.48)
            let jawQuality = reliability * (0.50 + jawBilateralQuality * 0.50)

            base = TrueMaxUncertaintyProfile(
                symmetry: 6.0 - 3.2 * symmetryQuality,
                proportion: 6.0 - 3.0 * proportionQuality,
                canthal: 3.5,
                jaw: 7.0 - 4.0 * jawQuality,
                texture: 8.0
            )
        } else {
            base = TrueMaxUncertaintyProfile(
                symmetry: 6.0,
                proportion: 6.0,
                canthal: 3.5,
                jaw: 7.0,
                texture: 8.0
            )
        }

        // Widen bands when the face is small, pose is less frontal, or Vision
        // reports lower image quality. The penalty is deliberately bounded so
        // depth-assisted captures never imply clinical precision.
        let qualitySignal = clamped(faceCaptureQuality ?? 0.70, to: 0...1)
        let coverageSignal = clamped((faceArea - 0.075) / 0.20, to: 0...1)
        let poseSignal = 1 - clamped(
            (yawRadians / 0.38) * 0.55 + (rollRadians / 0.34) * 0.45,
            to: 0...1
        )
        let captureQuality = clamped(
            qualitySignal * 0.50 + coverageSignal * 0.25 + poseSignal * 0.25,
            to: 0...1
        )
        let penalty = 1 + (1 - captureQuality) * 0.85

        return TrueMaxUncertaintyProfile(
            symmetry: base.symmetry * penalty,
            proportion: base.proportion * penalty,
            canthal: base.canthal * penalty,
            jaw: base.jaw * penalty,
            texture: base.texture * penalty
        )
    }

    private static func decodedUprightImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 2_048,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        return CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        )
    }

    private static func imagePoints(
        _ region: VNFaceLandmarkRegion2D?,
        face: VNFaceObservation
    ) -> [CGPoint] {
        guard let region else { return [] }
        return region.normalizedPoints.map { point in
            CGPoint(
                x: face.boundingBox.minX + point.x * face.boundingBox.width,
                y: face.boundingBox.minY + point.y * face.boundingBox.height
            )
        }
    }

    private static func symmetryIndex(
        leftEye: [CGPoint],
        rightEye: [CGPoint],
        leftEyeCenter: CGPoint,
        rightEyeCenter: CGPoint,
        noseCenter: CGPoint,
        mouthCenter: CGPoint,
        midlineX: CGFloat,
        eyeSpacing: CGFloat,
        faceWidth: CGFloat
    ) -> Double {
        let eyeVerticalOffset = abs(leftEyeCenter.y - rightEyeCenter.y) / eyeSpacing
        let eyeMidpointOffset = abs(
            (leftEyeCenter.x + rightEyeCenter.x) / 2 - midlineX
        ) / faceWidth
        let noseOffset = abs(noseCenter.x - midlineX) / faceWidth
        let mouthOffset = abs(mouthCenter.x - midlineX) / faceWidth

        let leftEyeWidth = extent(leftEye, keyPath: \.x)
        let rightEyeWidth = extent(rightEye, keyPath: \.x)
        let eyeWidthDifference = abs(leftEyeWidth - rightEyeWidth)
            / max(max(leftEyeWidth, rightEyeWidth), 0.001)

        let normalizedError = Double(
            eyeVerticalOffset * 0.28
                + eyeMidpointOffset * 0.18
                + noseOffset * 0.20
                + mouthOffset * 0.20
                + eyeWidthDifference * 0.14
        )
        return clamped(100 - normalizedError * 155, to: 35...98)
    }

    private static func proportionIndex(
        face: CGRect,
        eyeLineY: CGFloat,
        noseY: CGFloat,
        mouthY: CGFloat,
        contour: [CGPoint],
        leftEyeCenter: CGPoint,
        rightEyeCenter: CGPoint
    ) -> Double {
        let chinY = contour.map(\.y).min() ?? face.minY
        let topY = face.maxY
        let segments = [
            max(topY - eyeLineY, 0.001),
            max(eyeLineY - noseY, 0.001),
            max(noseY - chinY, 0.001),
        ].map(Double.init)

        let mean = segments.reduce(0, +) / Double(segments.count)
        let variance = segments.reduce(0) { partial, value in
            partial + pow(value - mean, 2)
        } / Double(segments.count)
        let variation = sqrt(variance) / max(mean, 0.001)

        let eyeMidpointX = (leftEyeCenter.x + rightEyeCenter.x) / 2
        let horizontalOffset = abs(eyeMidpointX - face.midX)
            / max(face.width, 0.001)
        let mouthToChin = max(mouthY - chinY, 0)
            / max(face.height, 0.001)
        let compressedLowerFacePenalty = max(0, 0.12 - mouthToChin)

        return clamped(
            100
                - variation * 48
                - Double(horizontalOffset) * 85
                - Double(compressedLowerFacePenalty) * 80,
            to: 35...98
        )
    }

    private static func eyeAngle(_ points: [CGPoint]) -> Double {
        guard let left = points.min(by: { $0.x < $1.x }),
              let right = points.max(by: { $0.x < $1.x }) else {
            return 0
        }
        return atan2(
            Double(right.y - left.y),
            Double(right.x - left.x)
        ) * 180 / .pi
    }

    private static func jawContourAngle(
        contour: [CGPoint],
        faceHeight: CGFloat
    ) -> Double {
        guard let chin = contour.min(by: { $0.y < $1.y }) else {
            return 120
        }

        let lowerLimit = chin.y + faceHeight * 0.10
        let upperLimit = chin.y + faceHeight * 0.48
        let leftCandidates = contour.filter {
            $0.x < chin.x && $0.y >= lowerLimit && $0.y <= upperLimit
        }
        let rightCandidates = contour.filter {
            $0.x > chin.x && $0.y >= lowerLimit && $0.y <= upperLimit
        }

        guard let leftCorner = leftCandidates.min(by: { $0.x < $1.x }),
              let rightCorner = rightCandidates.max(by: { $0.x < $1.x }) else {
            let lowerWidth = extent(
                contour.filter { $0.y <= chin.y + faceHeight * 0.45 },
                keyPath: \.x
            )
            let highestPoint = contour.map(\.y).max() ?? chin.y
            let lowerHeight = max(highestPoint - chin.y, faceHeight * 0.15)
            return clamped(
                2 * atan2(Double(lowerWidth / 2), Double(lowerHeight)) * 180 / .pi,
                to: 80...155
            )
        }

        let leftUpper = contour
            .filter { $0.x <= leftCorner.x + faceHeight * 0.12 }
            .max(by: { $0.y < $1.y })
        let rightUpper = contour
            .filter { $0.x >= rightCorner.x - faceHeight * 0.12 }
            .max(by: { $0.y < $1.y })

        let leftAngle = vertexAngle(
            first: leftUpper ?? CGPoint(x: leftCorner.x, y: leftCorner.y + faceHeight * 0.25),
            vertex: leftCorner,
            second: chin
        )
        let rightAngle = vertexAngle(
            first: rightUpper ?? CGPoint(x: rightCorner.x, y: rightCorner.y + faceHeight * 0.25),
            vertex: rightCorner,
            second: chin
        )
        return clamped((leftAngle + rightAngle) / 2, to: 80...160)
    }

    private static func vertexAngle(
        first: CGPoint,
        vertex: CGPoint,
        second: CGPoint
    ) -> Double {
        let a = CGVector(dx: first.x - vertex.x, dy: first.y - vertex.y)
        let b = CGVector(dx: second.x - vertex.x, dy: second.y - vertex.y)
        let denominator = max(
            hypot(Double(a.dx), Double(a.dy))
                * hypot(Double(b.dx), Double(b.dy)),
            0.000_001
        )
        let cosine = clamped(
            Double(a.dx * b.dx + a.dy * b.dy) / denominator,
            to: -1...1
        )
        return acos(cosine) * 180 / .pi
    }

    private static func visibleTextureIndex(
        image: CGImage,
        faceBounds: CGRect
    ) -> Double {
        let width = 256
        let height = max(
            1,
            Int(
                (Double(image.height) / Double(max(image.width, 1))
                    * Double(width)).rounded()
            )
        )
        var pixels = [UInt8](repeating: 0, count: width * height)
        let rendered = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let baseAddress = buffer.baseAddress,
                  let context = CGContext(
                      data: baseAddress,
                      width: width,
                      height: height,
                      bitsPerComponent: 8,
                      bytesPerRow: width,
                      space: CGColorSpaceCreateDeviceGray(),
                      bitmapInfo: CGImageAlphaInfo.none.rawValue
                  ) else {
                return false
            }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard rendered else { return 0 }

        let xInset = faceBounds.width * 0.20
        let yInset = faceBounds.height * 0.18
        let sampleBounds = faceBounds.insetBy(dx: xInset, dy: yInset)

        let minimumX = max(1, Int(sampleBounds.minX * CGFloat(width)))
        let maximumX = min(width - 2, Int(sampleBounds.maxX * CGFloat(width)))
        let minimumY = max(1, Int(sampleBounds.minY * CGFloat(height)))
        let maximumY = min(height - 2, Int(sampleBounds.maxY * CGFloat(height)))
        guard minimumX < maximumX, minimumY < maximumY else { return 0 }

        var gradientTotal = 0.0
        var pairCount = 0
        for y in stride(from: minimumY, through: maximumY, by: 2) {
            for x in stride(from: minimumX, through: maximumX, by: 2) {
                let index = y * width + x
                let value = Int(pixels[index])
                gradientTotal += Double(abs(value - Int(pixels[index + 1])))
                gradientTotal += Double(abs(value - Int(pixels[index + width])))
                pairCount += 2
            }
        }

        guard pairCount > 0 else { return 0 }
        let meanNeighborDifference = gradientTotal / Double(pairCount)
        return clamped(meanNeighborDifference / 255 * 320, to: 0...100)
    }

    private static func range(
        around midpoint: Double,
        uncertainty: Double,
        limits: ClosedRange<Double>
    ) -> TrueMaxRawRange {
        TrueMaxRawRange(
            low: rounded(clamped(midpoint - uncertainty, to: limits)),
            high: rounded(clamped(midpoint + uncertainty, to: limits))
        )
    }

    private static func rounded(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }

    private static func clamped(
        _ value: Double,
        to limits: ClosedRange<Double>
    ) -> Double {
        min(max(value, limits.lowerBound), limits.upperBound)
    }

    private static func centroid(_ points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        let total = points.reduce(CGPoint.zero) { partial, point in
            CGPoint(x: partial.x + point.x, y: partial.y + point.y)
        }
        return CGPoint(
            x: total.x / CGFloat(points.count),
            y: total.y / CGFloat(points.count)
        )
    }

    private static func distance(_ first: CGPoint, _ second: CGPoint) -> CGFloat {
        hypot(first.x - second.x, first.y - second.y)
    }

    private static func extent(
        _ points: [CGPoint],
        keyPath: KeyPath<CGPoint, CGFloat>
    ) -> CGFloat {
        guard let minimum = points.map({ $0[keyPath: keyPath] }).min(),
              let maximum = points.map({ $0[keyPath: keyPath] }).max() else {
            return 0
        }
        return maximum - minimum
    }

    private static func area(_ rect: CGRect) -> CGFloat {
        rect.width * rect.height
    }
}

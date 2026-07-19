import Foundation
import SwiftData
import UIKit

enum TrueMaxStorage {
    enum CaptureDeletionResult {
        case deletedOrAbsent
        case failure(StorageError)
    }

    enum StorageError: LocalizedError {
        case couldNotEncodeImage
        case couldNotLocateApplicationSupport
        case couldNotSecureStoredFile(reason: String, cleanupReason: String?)
        case couldNotDeleteCapture(reason: String)
        case couldNotDeleteAllUserFiles(details: [String])

        var errorDescription: String? {
            switch self {
            case .couldNotEncodeImage:
                return "TrueMax could not prepare this capture for local storage."
            case .couldNotLocateApplicationSupport:
                return "TrueMax could not locate its protected local storage."
            case let .couldNotSecureStoredFile(reason, cleanupReason):
                if let cleanupReason {
                    return "TrueMax could not secure the local file and could not remove the incomplete file. Storage error: \(reason) Cleanup error: \(cleanupReason)"
                }
                return "TrueMax could not secure the local file. \(reason)"
            case let .couldNotDeleteCapture(reason):
                return "The protected capture file could not be removed. \(reason)"
            case let .couldNotDeleteAllUserFiles(details):
                return "Protected local file cleanup was incomplete. \(details.joined(separator: " "))"
            }
        }
    }

    private static let capturesDirectoryName = "TrueMaxCaptures"
    private static let exportsDirectoryName = "TrueMaxExports"

    static func saveCapture(_ image: UIImage, id: UUID) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.92) else {
            throw StorageError.couldNotEncodeImage
        }

        let filename = "\(id.uuidString).jpg"
        let url = try capturesDirectory().appendingPathComponent(filename)
        try writeProtectedData(data, to: url)
        return filename
    }

    static func image(filename: String?) -> UIImage? {
        guard let filename,
              let directory = try? capturesDirectory() else {
            return nil
        }

        return UIImage(contentsOfFile: directory.appendingPathComponent(filename).path)
    }

    @discardableResult
    static func deleteCapture(filename: String?) -> CaptureDeletionResult {
        guard let filename, !filename.isEmpty else {
            return .deletedOrAbsent
        }

        guard URL(fileURLWithPath: filename).lastPathComponent == filename else {
            return .failure(
                .couldNotDeleteCapture(
                    reason: "The stored filename was invalid, so no file was touched."
                )
            )
        }

        do {
            let directory = try storageDirectoryURL(named: capturesDirectoryName)
            try removeItemIfPresent(
                at: directory.appendingPathComponent(filename)
            )
            return .deletedOrAbsent
        } catch {
            return .failure(
                .couldNotDeleteCapture(reason: error.localizedDescription)
            )
        }
    }

    static func deleteAllUserFiles() throws {
        let targets = [
            ("Captured photos:", capturesDirectoryName),
            ("Local exports:", exportsDirectoryName),
        ]
        var failures: [String] = []

        for (label, directoryName) in targets {
            do {
                let directory = try storageDirectoryURL(named: directoryName)
                try removeItemIfPresent(at: directory)
            } catch {
                failures.append("\(label) \(error.localizedDescription)")
            }
        }

        if !failures.isEmpty {
            throw StorageError.couldNotDeleteAllUserFiles(details: failures)
        }
    }

    static func makeJSONExport(scans: [ScanRecord]) throws -> URL {
        struct ExportMetric: Codable {
            let id: String
            let low: Double
            let high: Double
            let unit: String
            let methodology: String
        }

        struct ExportScan: Codable {
            let id: UUID
            let createdAt: Date
            let captureMode: String
            let confidence: String
            let analysisVersion: String
            let qualityNote: String
            let metrics: [ExportMetric]
            let guidance: [GuidanceItem]
        }

        struct ExportBundle: Codable {
            let product: String
            let generatedAt: Date
            let privacyNote: String
            let scans: [ExportScan]
        }

        let exportedScans = scans.map { scan in
            ExportScan(
                id: scan.id,
                createdAt: scan.createdAt,
                captureMode: scan.captureMode.title,
                confidence: scan.confidence.title,
                analysisVersion: scan.analysisVersion,
                qualityNote: scan.qualityNote,
                metrics: MetricKind.allCases.map { metric in
                    let range = scan.range(for: metric)
                    return ExportMetric(
                        id: metric.rawValue,
                        low: range.low,
                        high: range.high,
                        unit: range.unit.rawValue,
                        methodology: metric.methodology
                    )
                },
                guidance: scan.guidance
            )
        }

        let bundle = ExportBundle(
            product: TrueMaxBrand.name,
            generatedAt: Date(),
            privacyNote: "Generated locally at your request. No capture image or purchase identifier is included.",
            scans: exportedScans
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(bundle)
        let url = try exportsDirectory().appendingPathComponent("TrueMax-Export.json")
        try writeProtectedData(data, to: url)
        return url
    }

    private static func capturesDirectory() throws -> URL {
        try protectedDirectory(named: capturesDirectoryName)
    }

    private static func exportsDirectory() throws -> URL {
        try protectedDirectory(named: exportsDirectoryName)
    }

    private static func protectedDirectory(named name: String) throws -> URL {
        let manager = FileManager.default
        let directory = try storageDirectoryURL(named: name)

        if !manager.fileExists(atPath: directory.path) {
            try manager.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.complete]
            )
        }

        try manager.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: directory.path
        )
        try excludeFromBackup(directory)
        return directory
    }

    private static func storageDirectoryURL(named name: String) throws -> URL {
        guard let support = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw StorageError.couldNotLocateApplicationSupport
        }

        return support.appendingPathComponent(name, isDirectory: true)
    }

    private static func writeProtectedData(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: [.atomic, .completeFileProtection])

        do {
            try excludeFromBackup(url)
        } catch {
            let storageReason = error.localizedDescription

            do {
                try removeItemIfPresent(at: url)
            } catch {
                throw StorageError.couldNotSecureStoredFile(
                    reason: storageReason,
                    cleanupReason: error.localizedDescription
                )
            }

            throw StorageError.couldNotSecureStoredFile(
                reason: storageReason,
                cleanupReason: nil
            )
        }
    }

    private static func excludeFromBackup(_ url: URL) throws {
        var protectedURL = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try protectedURL.setResourceValues(values)
    }

    private static func removeItemIfPresent(at url: URL) throws {
        let manager = FileManager.default
        guard manager.fileExists(atPath: url.path) else { return }

        do {
            try manager.removeItem(at: url)
        } catch {
            let cocoaError = error as NSError
            if cocoaError.domain == NSCocoaErrorDomain,
               cocoaError.code == NSFileNoSuchFileError {
                return
            }
            throw error
        }
    }
}

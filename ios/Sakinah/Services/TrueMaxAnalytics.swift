import Foundation

/// No-op telemetry boundary for TrueMax.
///
/// Existing call sites intentionally remain so protected commercial surfaces do
/// not need to change. No SDK is configured and no event or property leaves the
/// device, matching the product requirements and published privacy policy.
@MainActor
final class TrueMaxAnalytics {
    static let shared = TrueMaxAnalytics()

    private init() {}

    func configure() {}

    func capture(_ event: String, properties: [String: Any] = [:]) {}

    func screen(_ name: String, properties: [String: Any] = [:]) {}
}

import Foundation
import PostHog

/// Centralized anonymous product analytics for TrueMax.
///
/// Only product-usage metadata is sent. Facial images, measurements, landmark
/// data, style choices, and free-form user content remain on the device.
@MainActor
final class TrueMaxAnalytics {
    static let shared = TrueMaxAnalytics()

    private static let projectToken = "phc_qR88a5FF4vWuSMrUZ8yGBsC5hPfMuHkcHgEydgcRQo5f"
    private static let host = "https://us.i.posthog.com"

    private var isConfigured = false

    private init() {}

    func configure() {
        guard !isConfigured else { return }

        let config = PostHogConfig(
            projectToken: Self.projectToken,
            host: Self.host
        )
        config.captureElementInteractions = true
        config.rageClickConfig.enabled = true
        config.personProfiles = .identifiedOnly
        PostHogSDK.shared.setup(config)
        isConfigured = true

        capture("app opened")
    }

    func capture(_ event: String, properties: [String: Any] = [:]) {
        guard isConfigured else { return }
        PostHogSDK.shared.capture(event, properties: properties)
    }

    func screen(_ name: String, properties: [String: Any] = [:]) {
        capture("screen viewed", properties: [
            "$screen_name": name,
            "screen": name,
            "source": "manual_swiftui",
        ].merging(properties) { _, new in new })
    }
}

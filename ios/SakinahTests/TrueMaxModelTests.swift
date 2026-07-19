import Foundation
import Testing
@testable import Sakinah

@MainActor
struct TrueMaxModelTests {
    @Test
    func metricRangesUseHonestIntervals() {
        let index = MetricRangeValue(low: 82, high: 88, unit: .index)
        let angle = MetricRangeValue(low: 5, high: 7, unit: .degrees)

        #expect(index.displayText == "82–88")
        #expect(index.midpoint == 85)
        #expect(angle.displayText == "+5–7°")
    }

    @Test
    func photoModeIsExplicitlyLowerConfidence() {
        #expect(CaptureMode.depth3D.confidence == .high)
        #expect(CaptureMode.photo2D.confidence == .estimated)
        #expect(CaptureMode.photo2D.badgeTitle == "2D · Photo mode")
    }

    @MainActor
    @Test
    func freshInstallDefaultsToDarkAndSevenDayCooldown() {
        let suiteName = "TrueMaxAppStateTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let state = TrueMaxAppState(defaults: defaults)

        #expect(state.appearance == .dark)
        #expect(state.cooldownDays == 7)
        #expect(!state.hasCompletedOnboarding)
    }

    @MainActor
    @Test
    func onboardingCompletionIsVersionedAndShowsFirstScanDisclaimer() {
        let suiteName = "TrueMaxOnboardingTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let state = TrueMaxAppState(defaults: defaults)
        state.completeOnboarding()

        #expect(state.hasCompletedOnboarding)
        #expect(state.selectedTab == .scan)
        #expect(state.requiresMedicalDisclaimer)

        let restoredState = TrueMaxAppState(defaults: defaults)
        #expect(restoredState.requiresMedicalDisclaimer)

        restoredState.acknowledgeDisclaimer()
        #expect(!restoredState.requiresMedicalDisclaimer)
    }

    @Test
    func intelligencePackIsVersionedAndFullyProvenanced() {
        let entries = TrueMaxKnowledgeBase.entries
        #expect(TrueMaxKnowledgeBase.schemaVersion == 1)
        #expect(TrueMaxKnowledgeBase.packVersion == "2026.07.19")
        #expect(TrueMaxKnowledgeBase.reviewCadenceDays == 90)
        #expect(Set(entries.map(\.id)).count == entries.count)
        #expect(entries.count == 8)
        #expect(entries.allSatisfy { $0.sourceURL.scheme == "https" })
        #expect(entries.contains { $0.id == "vision-face-capture-quality" })
        #expect(entries.contains { $0.id == "avfoundation-depth-data" })
        #expect(entries.contains { $0.id == "privacy-manifest" })
        #expect(entries.contains { $0.id == "nist-ai-rmf-1" })
    }
}

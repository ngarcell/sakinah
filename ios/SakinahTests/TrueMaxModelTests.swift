import Foundation
import SwiftData
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
    func metricRangesNormalizeCorruptValuesBeforeDisplay() {
        let reversed = MetricRangeValue(
            low: 88,
            high: 82,
            unit: .index
        )
        let nonFinite = MetricRangeValue(
            low: .nan,
            high: .infinity,
            unit: .degrees
        )

        #expect(reversed.low == 82)
        #expect(reversed.high == 88)
        #expect(reversed.displayText == "82–88")
        #expect(nonFinite.low == 0)
        #expect(nonFinite.high == 0)
        #expect(nonFinite.displayText == "0–0°")
    }

    @Test
    func decodedMetricRangesNormalizeReversedPersistedValues() throws {
        let data = Data(
            #"{"low":88,"high":82,"unit":"index"}"#.utf8
        )
        let decoded = try JSONDecoder().decode(
            MetricRangeValue.self,
            from: data
        )

        #expect(decoded.low == 82)
        #expect(decoded.high == 88)
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
        #expect(state.canUseReverseTrialScan)
        #expect(!state.hasCompletedOnboarding)
    }

    @MainActor
    @Test
    func reverseTrialIsConsumedAndPersistsAfterTheFirstResult() {
        let suiteName = "TrueMaxReverseTrialTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let state = TrueMaxAppState(defaults: defaults)
        state.consumeReverseTrial()

        #expect(state.reverseTrialConsumed)
        #expect(!state.canUseReverseTrialScan)
        #expect(state.presentsPaywall)

        let restoredState = TrueMaxAppState(defaults: defaults)
        #expect(restoredState.reverseTrialConsumed)
        #expect(!restoredState.canUseReverseTrialScan)
    }

    @Test
    func savedReverseTrialResultPersistsWithoutCoveringTheResult() {
        let suiteName = "TrueMaxSavedTrialTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let state = TrueMaxAppState(defaults: defaults)
        state.recordReverseTrialResult()

        #expect(state.reverseTrialConsumed)
        #expect(!state.presentsPaywall)
        #expect(!state.canUseReverseTrialScan)

        state.consumeReverseTrial()
        #expect(state.presentsPaywall)
    }

    @Test
    func favoriteTogglePersistsAndRemovesLegacyDuplicates() throws {
        let schema = Schema([ScanRecord.self, StyleFavorite.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        let context = container.mainContext

        let inserted = try TrueMaxFavoriteStore.toggle(
            styleID: "textured-crop",
            title: "Textured crop",
            in: context
        )
        #expect(inserted)

        context.insert(
            StyleFavorite(
                styleID: "textured-crop",
                title: "Duplicate"
            )
        )
        try context.save()

        let removed = try TrueMaxFavoriteStore.toggle(
            styleID: "textured-crop",
            title: "Textured crop",
            in: context
        )
        #expect(!removed)

        let remaining = try context.fetch(FetchDescriptor<StyleFavorite>())
        #expect(remaining.isEmpty)
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
        #expect(state.onboardingCompleted)
        #expect(state.selectedTab == .home)
        #expect(state.requiresMedicalDisclaimer)

        let restoredState = TrueMaxAppState(defaults: defaults)
        #expect(restoredState.onboardingCompleted)
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

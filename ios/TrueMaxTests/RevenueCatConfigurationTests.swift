import Foundation
import Testing
@testable import TrueMax

@MainActor
struct RevenueCatConfigurationTests {
    @Test
    func customPaywallPlanCatalogPreservesStoreProductIdentifiers() {
        #expect(SubscriptionService.defaultPlan.rawValue == "annual")
        #expect(
            SubscriptionService.Plan.annual.productIdentifier
                == "com.socialreporthq.sakinah.premium.annual"
        )
        #expect(
            SubscriptionService.Plan.monthly.productIdentifier
                == "com.socialreporthq.sakinah.premium.monthly"
        )
    }

    @Test
    func debugConfigurationDefaultsToTestStoreKey() throws {
        let configuration = try RevenueCatConfigurationResolver.resolve(
            infoDictionary: debugInfoDictionary(),
            userDefaults: makeUserDefaults(),
            environment: [:]
        )

        #expect(configuration.apiKey == "test_debug_key")
        #expect(configuration.usesTestStore)
        #expect(configuration.hasBundledTestStoreKey)
        #expect(configuration.keySource == .buildConfiguration)
        #expect(configuration.premiumEntitlementIDs == ["TrueMax Premium", "premium"])
    }

    @Test
    func debugConfigurationCanOverrideToAppleSandbox() throws {
        let userDefaults = makeUserDefaults()
        userDefaults.set(true, forKey: RevenueCatDebugOverrideKeys.appleSandboxUserDefaultsKey)

        let configuration = try RevenueCatConfigurationResolver.resolve(
            infoDictionary: debugInfoDictionary(),
            userDefaults: userDefaults,
            environment: [:]
        )

        #expect(configuration.apiKey == "appl_live_key")
        #expect(!configuration.usesTestStore)
        #expect(configuration.keySource == .appleSandboxOverride)
    }

    @Test
    func debugConfigurationFallsBackToTestKeyWhenDefaultKeyIsMissing() throws {
        var infoDictionary = debugInfoDictionary()
        infoDictionary.removeValue(forKey: "CFRevenueCatDefaultAPIKey")

        let configuration = try RevenueCatConfigurationResolver.resolve(
            infoDictionary: infoDictionary,
            userDefaults: makeUserDefaults(),
            environment: [:]
        )

        #expect(configuration.apiKey == "test_debug_key")
        #expect(configuration.usesTestStore)
    }

    @Test
    func debugConfigurationIgnoresUnresolvedBuildSettingPlaceholderForDefaultKey() throws {
        var infoDictionary = debugInfoDictionary()
        infoDictionary["CFRevenueCatDefaultAPIKey"] = "$(CFRevenueCatDefaultAPIKey)"

        let configuration = try RevenueCatConfigurationResolver.resolve(
            infoDictionary: infoDictionary,
            userDefaults: makeUserDefaults(),
            environment: [:]
        )

        #expect(configuration.apiKey == "test_debug_key")
        #expect(configuration.usesTestStore)
    }

    @Test
    func releaseConfigurationRejectsEmbeddedTestStoreKey() {
        do {
            _ = try RevenueCatConfigurationResolver.resolve(
                infoDictionary: releaseInfoDictionary(testKey: "test_should_not_ship"),
                userDefaults: makeUserDefaults(),
                environment: [:]
            )
            Issue.record("Expected release configuration to reject an embedded RevenueCat test key.")
        } catch {
            #expect(error.localizedDescription.contains("must not ship"))
        }
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "RevenueCatConfigurationTests-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private func debugInfoDictionary() -> [String: Any] {
        [
            "CFRevenueCatDefaultAPIKey": "test_debug_key",
            "CFRevenueCatAppleAPIKey": "appl_live_key",
            "CFRevenueCatTestAPIKey": "test_debug_key",
            "CFRevenueCatPremiumEntitlementID": "TrueMax Premium",
            "CFRevenueCatPremiumEntitlementFallbackIDs": "premium",
            "CFRevenueCatAllowDebugOverrides": "YES",
            "CFRevenueCatRequireAppleKey": "NO",
            "CFRevenueCatLogLevel": "debug",
        ]
    }

    private func releaseInfoDictionary(testKey: String) -> [String: Any] {
        [
            "CFRevenueCatDefaultAPIKey": "appl_live_key",
            "CFRevenueCatAppleAPIKey": "appl_live_key",
            "CFRevenueCatTestAPIKey": testKey,
            "CFRevenueCatPremiumEntitlementID": "TrueMax Premium",
            "CFRevenueCatPremiumEntitlementFallbackIDs": "premium",
            "CFRevenueCatAllowDebugOverrides": "NO",
            "CFRevenueCatRequireAppleKey": "YES",
            "CFRevenueCatLogLevel": "error",
        ]
    }
}

import Foundation
import RevenueCat

enum RevenueCatDebugOverrideKeys {
    static let appleSandboxUserDefaultsKey = "sakinah.revenuecat.useAppleSandboxInDebug"
    static let apiKeyEnvironmentOverride = "SAKINAH_RC_API_KEY_OVERRIDE"
    static let appleSandboxEnvironmentOverride = "SAKINAH_RC_USE_APPLE_SANDBOX"
}

struct RevenueCatConfiguration: Sendable {
    enum KeySource: String, Sendable {
        case buildConfiguration
        case appleSandboxOverride
        case explicitEnvironmentOverride
    }

    let apiKey: String
    let keySource: KeySource
    let usesTestStore: Bool
    let hasBundledTestStoreKey: Bool
    let premiumEntitlementIDs: [String]
    let allowDebugOverrides: Bool
    let requireAppleKey: Bool
    let logLevel: LogLevel
}

enum RevenueCatBootstrapper {
    private static var cachedResult: Result<RevenueCatConfiguration, Error>?

    @discardableResult
    static func configureIfNeeded(
        bundle: Bundle = .main,
        userDefaults: UserDefaults = .standard,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Result<RevenueCatConfiguration, Error> {
        if let cachedResult {
            return cachedResult
        }

        let result: Result<RevenueCatConfiguration, Error>

        do {
            let configuration = try RevenueCatConfigurationResolver.resolve(
                bundle: bundle,
                userDefaults: userDefaults,
                environment: environment
            )

            Purchases.logLevel = configuration.logLevel

            if !Purchases.isConfigured {
                let builder = Configuration
                    .builder(withAPIKey: configuration.apiKey)
                    .with(purchasesAreCompletedBy: .revenueCat, storeKitVersion: .storeKit2)

                Purchases.configure(with: builder)
            }

            result = .success(configuration)
        } catch {
            result = .failure(error)
        }

        cachedResult = result
        return result
    }

    static var configuration: RevenueCatConfiguration? {
        if case .success(let configuration) = cachedResult {
            return configuration
        }

        return nil
    }

    static var errorDescription: String? {
        if case .failure(let error) = cachedResult {
            return error.localizedDescription
        }

        return nil
    }
}

enum RevenueCatConfigurationResolver {
    static func resolve(
        bundle: Bundle = .main,
        userDefaults: UserDefaults = .standard,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> RevenueCatConfiguration {
        try resolve(
            infoDictionary: bundle.infoDictionary ?? [:],
            userDefaults: userDefaults,
            environment: environment
        )
    }

    static func resolve(
        infoDictionary: [String: Any],
        userDefaults: UserDefaults = .standard,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> RevenueCatConfiguration {
        let allowDebugOverrides = infoDictionary.boolValue(forKey: "CFRevenueCatAllowDebugOverrides") ?? false
        let requireAppleKey = infoDictionary.boolValue(forKey: "CFRevenueCatRequireAppleKey") ?? false
        let logLevel = infoDictionary.logLevel(forKey: "CFRevenueCatLogLevel")
        let rawDefaultKey = infoDictionary.optionalResolvedString(forKey: "CFRevenueCatDefaultAPIKey")
        let rawAppleKey = infoDictionary.optionalResolvedString(forKey: "CFRevenueCatAppleAPIKey")
        let rawTestKey = infoDictionary.optionalResolvedString(forKey: "CFRevenueCatTestAPIKey")
        let primaryEntitlement = try infoDictionary.requiredResolvedString(forKey: "CFRevenueCatPremiumEntitlementID")
        let fallbackEntitlements = infoDictionary.csvValues(forKey: "CFRevenueCatPremiumEntitlementFallbackIDs")

        let appleKey = rawAppleKey
            ?? (rawDefaultKey?.hasPrefix("appl_") == true ? rawDefaultKey : nil)

        guard let appleKey else {
            throw RevenueCatConfigurationError.missingInfoDictionaryValue("CFRevenueCatAppleAPIKey")
        }

        guard appleKey.hasPrefix("appl_") else {
            throw RevenueCatConfigurationError.invalidAPIKey(appleKey)
        }

        let testKey = rawTestKey
            ?? (rawDefaultKey?.hasPrefix("test_") == true ? rawDefaultKey : nil)

        if let testKey, !testKey.hasPrefix("test_") {
            throw RevenueCatConfigurationError.invalidAPIKey(testKey)
        }

        let defaultKey = rawDefaultKey
            ?? testKey
            ?? appleKey

        guard defaultKey.hasPrefix("appl_") || defaultKey.hasPrefix("test_") else {
            throw RevenueCatConfigurationError.invalidAPIKey(defaultKey)
        }

        if requireAppleKey {
            guard defaultKey.hasPrefix("appl_") else {
                throw RevenueCatConfigurationError.releaseBuildUsingTestStore(defaultKey)
            }

            if let testKey, !testKey.isEmpty {
                throw RevenueCatConfigurationError.releaseBuildContainsTestStoreKey(testKey)
            }
        }

        let explicitOverride = environment[RevenueCatDebugOverrideKeys.apiKeyEnvironmentOverride]?.trimmedNonEmpty
        let prefersAppleSandboxFromEnvironment = environment[RevenueCatDebugOverrideKeys.appleSandboxEnvironmentOverride]
            .flatMap(parseEnvironmentBool(_:)) ?? false
        let prefersAppleSandbox = prefersAppleSandboxFromEnvironment
            || userDefaults.bool(forKey: RevenueCatDebugOverrideKeys.appleSandboxUserDefaultsKey)

        let resolvedKey: String
        let keySource: RevenueCatConfiguration.KeySource

        if allowDebugOverrides, let explicitOverride {
            resolvedKey = explicitOverride
            keySource = .explicitEnvironmentOverride
        } else if allowDebugOverrides, prefersAppleSandbox {
            resolvedKey = appleKey
            keySource = .appleSandboxOverride
        } else {
            resolvedKey = defaultKey
            keySource = .buildConfiguration
        }

        guard resolvedKey.hasPrefix("appl_") || resolvedKey.hasPrefix("test_") else {
            throw RevenueCatConfigurationError.invalidAPIKey(resolvedKey)
        }

        if requireAppleKey, !resolvedKey.hasPrefix("appl_") {
            throw RevenueCatConfigurationError.releaseBuildUsingTestStore(resolvedKey)
        }

        let premiumEntitlementIDs = Array(
            NSOrderedSet(array: [primaryEntitlement] + fallbackEntitlements)
        ) as? [String] ?? [primaryEntitlement] + fallbackEntitlements

        return RevenueCatConfiguration(
            apiKey: resolvedKey,
            keySource: keySource,
            usesTestStore: resolvedKey.hasPrefix("test_"),
            hasBundledTestStoreKey: testKey?.hasPrefix("test_") == true,
            premiumEntitlementIDs: premiumEntitlementIDs,
            allowDebugOverrides: allowDebugOverrides,
            requireAppleKey: requireAppleKey,
            logLevel: logLevel
        )
    }
}

private enum RevenueCatConfigurationError: LocalizedError {
    case missingInfoDictionaryValue(String)
    case invalidAPIKey(String)
    case releaseBuildUsingTestStore(String)
    case releaseBuildContainsTestStoreKey(String)

    var errorDescription: String? {
        switch self {
        case .missingInfoDictionaryValue(let key):
            return "Missing RevenueCat configuration value for \(key)."
        case .invalidAPIKey(let key):
            return "RevenueCat API key is invalid or unresolved: \(key). Expected an appl_ or test_ public SDK key."
        case .releaseBuildUsingTestStore(let key):
            return "Release/TestFlight/App Store builds must use an appl_ RevenueCat key. Resolved key: \(key)"
        case .releaseBuildContainsTestStoreKey(let key):
            return "Release/TestFlight/App Store builds must not ship a RevenueCat test_ key. Found: \(key)"
        }
    }
}

private extension Dictionary where Key == String, Value == Any {
    func requiredResolvedString(forKey key: String) throws -> String {
        if let stringValue = self[key] as? String,
           let trimmed = stringValue.resolvedBuildSettingValue {
            return trimmed
        }

        throw RevenueCatConfigurationError.missingInfoDictionaryValue(key)
    }

    func optionalResolvedString(forKey key: String) -> String? {
        if let stringValue = self[key] as? String {
            return stringValue.resolvedBuildSettingValue
        }

        return nil
    }

    func csvValues(forKey key: String) -> [String] {
        guard let rawValue = optionalResolvedString(forKey: key) else { return [] }

        return rawValue
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    func boolValue(forKey key: String) -> Bool? {
        if let boolValue = self[key] as? Bool {
            return boolValue
        }

        if let numberValue = self[key] as? NSNumber {
            return numberValue.boolValue
        }

        if let stringValue = optionalResolvedString(forKey: key) {
            return parseEnvironmentBool(stringValue)
        }

        return nil
    }

    func logLevel(forKey key: String) -> LogLevel {
        guard let value = optionalResolvedString(forKey: key) else {
            return .warn
        }

        switch value.lowercased() {
        case "debug":
            return .debug
        case "info":
            return .info
        case "error":
            return .error
        case "verbose":
            return .verbose
        default:
            return .warn
        }
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var resolvedBuildSettingValue: String? {
        guard let trimmed = trimmedNonEmpty else { return nil }
        guard !trimmed.isBuildSettingPlaceholder else { return nil }
        return trimmed
    }

    var isBuildSettingPlaceholder: Bool {
        (hasPrefix("$(") && hasSuffix(")"))
            || (hasPrefix("${") && hasSuffix("}"))
    }
}

private func parseEnvironmentBool(_ rawValue: String) -> Bool? {
    switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
    case "1", "true", "yes", "y", "on":
        return true
    case "0", "false", "no", "n", "off":
        return false
    default:
        return nil
    }
}

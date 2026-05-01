import Foundation
import Observation
import RevenueCat

private final class CustomerInfoUpdatesObserver: @unchecked Sendable {
    private var task: Task<Void, Never>?

    func set(_ task: Task<Void, Never>?) {
        self.task = task
    }

    deinit {
        task?.cancel()
    }
}

@Observable
@MainActor
final class SubscriptionService {
    private enum ProductCatalog {
        static let monthly = "com.socialreporthq.sakinah.premium.monthly"
        static let annual = "com.socialreporthq.sakinah.premium.annual"
        static let lifetime = "com.socialreporthq.sakinah.premium.lifetimev2"

        static let allProductIDs: Set<String> = [monthly, annual, lifetime]
    }

    private enum DefaultsKey {
        static let tier = "sakinah.subscriptionTier"
        static let migrationSyncCompleted = "sakinah.revenuecatMigrationSyncCompleted"
    }

    private static let unavailablePriceText = "Price unavailable"

    static let shared = SubscriptionService()
    static let monthlyProductID = ProductCatalog.monthly
    static let annualProductID = ProductCatalog.annual
    static let lifetimeProductID = ProductCatalog.lifetime

    var currentTier: SubscriptionTier = .free
    var isLoadingProducts = false
    var isRestoringPurchases = false
    var isSyncingLegacyPurchases = false
    var purchaseError: String?

    private(set) var customerInfo: CustomerInfo?
    private(set) var offerings: Offerings?
    private(set) var monthlyProduct: StoreProduct?
    private(set) var annualProduct: StoreProduct?
    private(set) var lifetimeProduct: StoreProduct?

    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let configuration: RevenueCatConfiguration?
    @ObservationIgnored private let configurationErrorDescription: String?
    @ObservationIgnored private let customerInfoUpdatesObserver = CustomerInfoUpdatesObserver()

    var isPremium: Bool { currentTier == .premium }
    var isLoading: Bool { isLoadingProducts || isRestoringPurchases || isSyncingLegacyPurchases }
    var canOpenCustomerCenter: Bool { isRevenueCatAvailable }
    var isRevenueCatAvailable: Bool { configuration != nil && Purchases.isConfigured }
    var revenueCatUnavailableMessage: String {
        Self.unavailableMessage(from: configurationErrorDescription ?? "Plans are unavailable.")
    }

    var currentOffering: Offering? {
        offerings?.current
            ?? offerings?.all.values.first(where: { !$0.availablePackages.isEmpty })
            ?? offerings?.all.values.first
    }

    var managementURL: URL? {
        customerInfo?.managementURL
    }

    var activeProductIdentifier: String? {
        activeProductIdentifiers.first
    }

    var currentPlanName: String {
        activeProductIdentifier.flatMap(Self.planDisplayName(for:)) ?? currentTier.displayName
    }

    var monthlyDisplayPrice: String {
        Self.priceDescription(for: monthlyPackage, fallbackProduct: monthlyProduct)
    }

    var annualDisplayPrice: String {
        Self.priceDescription(for: annualPackage, fallbackProduct: annualProduct)
    }

    var lifetimeDisplayPrice: String {
        Self.priceDescription(for: lifetimePackage, fallbackProduct: lifetimeProduct)
    }

    var featuredUpgradePrice: String? {
        if annualDisplayPrice != Self.unavailablePriceText {
            return annualDisplayPrice
        }

        if monthlyDisplayPrice != Self.unavailablePriceText {
            return monthlyDisplayPrice
        }

        if lifetimeDisplayPrice != Self.unavailablePriceText {
            return lifetimeDisplayPrice
        }

        return nil
    }

    private var monthlyPackage: Package? {
        availablePackages.first { $0.storeProduct.productIdentifier == ProductCatalog.monthly }
    }

    private var annualPackage: Package? {
        availablePackages.first { $0.storeProduct.productIdentifier == ProductCatalog.annual }
    }

    private var lifetimePackage: Package? {
        availablePackages.first { $0.storeProduct.productIdentifier == ProductCatalog.lifetime }
    }

    private var availablePackages: [Package] {
        let currentOfferingPackages = currentOffering?.availablePackages ?? []
        let fallbackPackages = offerings?.all.values.flatMap(\.availablePackages) ?? []

        var seenProductIDs = Set<String>()

        return (currentOfferingPackages + fallbackPackages).filter { package in
            seenProductIDs.insert(package.storeProduct.productIdentifier).inserted
        }
    }

    private var activeProductIdentifiers: [String] {
        guard let customerInfo else { return [] }

        let activeEntitlementProductIDs = activeEntitlementProductIdentifiers(from: customerInfo)
        if !activeEntitlementProductIDs.isEmpty {
            return activeEntitlementProductIDs.sorted(by: Self.productPriority)
        }

        let activeSubscriptions = Array(customerInfo.activeSubscriptions)
        if !activeSubscriptions.isEmpty {
            return activeSubscriptions.sorted(by: Self.productPriority)
        }

        let ownedNonConsumables = customerInfo.nonSubscriptions
            .map(\.productIdentifier)
            .filter { ProductCatalog.allProductIDs.contains($0) }

        return Array(Set(ownedNonConsumables)).sorted(by: Self.productPriority)
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        switch RevenueCatBootstrapper.configureIfNeeded(userDefaults: userDefaults) {
        case .success(let configuration):
            self.configuration = configuration
            self.configurationErrorDescription = nil
        case .failure(let error):
            self.configuration = nil
            self.configurationErrorDescription = error.localizedDescription
            self.purchaseError = Self.unavailableMessage(from: error.localizedDescription)
            print("RevenueCat configuration error: \(error.localizedDescription)")
        }

        _ = restoreCachedPurchaseState()

        if isRevenueCatAvailable, let cachedCustomerInfo = Purchases.shared.cachedCustomerInfo {
            applyCustomerInfo(cachedCustomerInfo)
        }

        if isRevenueCatAvailable {
            startObservingCustomerInfoUpdates()
        }
    }

    func loadSubscriptionState() {
        _ = restoreCachedPurchaseState()

        guard ensureRevenueCatAvailable() else { return }

        let shouldAttemptMigration = !userDefaults.bool(forKey: DefaultsKey.migrationSyncCompleted)

        Task {
            _ = await preparePaywall(forceRefresh: false)
            await runLegacyMigrationSyncIfNeeded(shouldAttemptMigration: shouldAttemptMigration)
        }
    }

    func preparePaywall(forceRefresh: Bool = false) async -> Bool {
        guard ensureRevenueCatAvailable() else { return false }

        let loadedProducts = await loadProducts(forceRefresh: forceRefresh || currentOffering == nil)
        await refreshEntitlements()

        return loadedProducts && currentOffering != nil
    }

    @discardableResult
    func loadProducts(forceRefresh: Bool) async -> Bool {
        guard ensureRevenueCatAvailable() else { return false }

        if isLoadingProducts {
            return hasAnyPurchaseOption
        }

        if hasAnyPurchaseOption && !forceRefresh {
            return true
        }

        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            offerings = try await Purchases.shared.offerings()

            if currentOffering == nil {
                purchaseError = "Plans are unavailable right now. Please try again in a moment."
            } else {
                purchaseError = nil
            }
        } catch {
            purchaseError = userFacingErrorMessage(for: error)
        }

        let products = await Purchases.shared.products(Array(ProductCatalog.allProductIDs))
        monthlyProduct = products.first { $0.productIdentifier == ProductCatalog.monthly }
        annualProduct = products.first { $0.productIdentifier == ProductCatalog.annual }
        lifetimeProduct = products.first { $0.productIdentifier == ProductCatalog.lifetime }

        return hasAnyPurchaseOption
    }

    func refreshEntitlements() async {
        guard ensureRevenueCatAvailable() else { return }

        do {
            let info = try await Purchases.shared.customerInfo()
            syncCustomerInfo(info)
        } catch {
            purchaseError = userFacingErrorMessage(for: error)
        }
    }

    func restorePurchases() async {
        guard ensureRevenueCatAvailable() else { return }

        purchaseError = nil
        isRestoringPurchases = true
        defer { isRestoringPurchases = false }

        do {
            let info = try await Purchases.shared.restorePurchases()
            syncCustomerInfo(info)

            if currentTier == .free {
                purchaseError = "No previous access was found to restore."
            }
        } catch {
            purchaseError = userFacingErrorMessage(for: error)
        }
    }

    func syncCustomerInfo(_ customerInfo: CustomerInfo) {
        applyCustomerInfo(customerInfo)
        purchaseError = nil
    }

    func clearError() {
        purchaseError = nil
    }

    func setError(from error: Error) {
        purchaseError = userFacingErrorMessage(for: error)
    }

    private func restoreCachedPurchaseState() -> Bool {
        if let cachedTier = userDefaults.string(forKey: DefaultsKey.tier),
           let decodedTier = SubscriptionTier(rawValue: cachedTier) {
            currentTier = decodedTier
        } else {
            currentTier = .free
        }

        return currentTier != .free
    }

    private func applyCustomerInfo(_ customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo

        let resolvedTier = resolvedTier(from: customerInfo)
        currentTier = resolvedTier
        userDefaults.set(resolvedTier.rawValue, forKey: DefaultsKey.tier)
    }

    private func resolvedTier(from customerInfo: CustomerInfo) -> SubscriptionTier {
        let activeEntitlementProductIDs = Set(activeEntitlementProductIdentifiers(from: customerInfo))

        if !activeEntitlementProductIDs.isDisjoint(with: ProductCatalog.allProductIDs) {
            return .premium
        }

        if !customerInfo.activeSubscriptions.isDisjoint(with: ProductCatalog.allProductIDs) {
            return .premium
        }

        let ownedNonConsumables = Set(customerInfo.nonSubscriptions.map(\.productIdentifier))
        if ownedNonConsumables.contains(ProductCatalog.lifetime) {
            return .premium
        }

        if hasConfiguredPremiumEntitlement(from: customerInfo) {
            return .premium
        }

        return .free
    }

    private func activeEntitlementProductIdentifiers(from customerInfo: CustomerInfo) -> [String] {
        guard let configuration else { return [] }

        return configuration.premiumEntitlementIDs.compactMap { entitlementID in
            customerInfo.entitlements.activeInCurrentEnvironment[entitlementID]?.productIdentifier
                ?? customerInfo.entitlements.active[entitlementID]?.productIdentifier
        }
    }

    private func hasConfiguredPremiumEntitlement(from customerInfo: CustomerInfo) -> Bool {
        guard let configuration else { return false }

        return configuration.premiumEntitlementIDs.contains { entitlementID in
            customerInfo.entitlements.activeInCurrentEnvironment[entitlementID]?.isActive == true
                || customerInfo.entitlements.active[entitlementID]?.isActive == true
        }
    }

    private func runLegacyMigrationSyncIfNeeded(shouldAttemptMigration: Bool) async {
        guard shouldAttemptMigration else { return }
        guard !userDefaults.bool(forKey: DefaultsKey.migrationSyncCompleted) else { return }
        guard ensureRevenueCatAvailable(), let configuration else { return }

        guard !configuration.usesTestStore else {
            userDefaults.set(true, forKey: DefaultsKey.migrationSyncCompleted)
            return
        }

        isSyncingLegacyPurchases = true
        defer { isSyncingLegacyPurchases = false }

        do {
            let info = try await Purchases.shared.syncPurchases()
            syncCustomerInfo(info)
            userDefaults.set(true, forKey: DefaultsKey.migrationSyncCompleted)
        } catch {
            purchaseError = userFacingErrorMessage(for: error)
        }
    }

    private func startObservingCustomerInfoUpdates() {
        customerInfoUpdatesObserver.set(Task { [weak self] in
            guard let self else { return }

            for await customerInfo in Purchases.shared.customerInfoStream {
                if Task.isCancelled { return }
                self.handleCustomerInfoUpdate(customerInfo)
            }
        })
    }

    private func handleCustomerInfoUpdate(_ customerInfo: CustomerInfo) {
        applyCustomerInfo(customerInfo)
    }

    private var hasAnyPurchaseOption: Bool {
        currentOffering != nil || monthlyProduct != nil || annualProduct != nil || lifetimeProduct != nil
    }

    private func ensureRevenueCatAvailable() -> Bool {
        if configuration == nil {
            purchaseError = revenueCatUnavailableMessage
            return false
        }

        return true
    }

    private func isUserCancelledError(_ error: Error) -> Bool {
        let nsError = error as NSError

        return nsError.domain == ErrorCode.errorDomain
            && nsError.code == ErrorCode.purchaseCancelledError.rawValue
    }

    private func isPaymentPendingError(_ error: Error) -> Bool {
        let nsError = error as NSError

        return nsError.domain == ErrorCode.errorDomain
            && nsError.code == ErrorCode.paymentPendingError.rawValue
    }

    private func userFacingErrorMessage(for error: Error) -> String {
        if isUserCancelledError(error) {
            return "No changes were made."
        }

        if isPaymentPendingError(error) {
            return "Your access is pending confirmation. It will unlock as soon as it’s approved."
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return "You’re offline right now. Reconnect and try again."
            case .timedOut:
                return "That took too long. Please try again."
            default:
                break
            }
        }

        return "Something went wrong. Please try again."
    }

    private static func unavailableMessage(from _: String) -> String {
        "Plans are temporarily unavailable. Please try again soon."
    }

    private static func priceDescription(for package: Package?, fallbackProduct: StoreProduct?) -> String {
        if let package {
            return formatPrice(package.localizedPriceString, period: package.storeProduct.subscriptionPeriod)
        }

        if let fallbackProduct {
            return formatPrice(fallbackProduct.localizedPriceString, period: fallbackProduct.subscriptionPeriod)
        }

        return unavailablePriceText
    }

    private static func formatPrice(_ localizedPrice: String, period: SubscriptionPeriod?) -> String {
        guard let period else { return localizedPrice }
        return "\(localizedPrice)/\(compactSubscriptionPeriod(period))"
    }

    private static func compactSubscriptionPeriod(_ period: SubscriptionPeriod) -> String {
        let value = period.value

        switch period.unit {
        case .day:
            return value == 1 ? "day" : "\(value) days"
        case .week:
            return value == 1 ? "week" : "\(value) weeks"
        case .month:
            return value == 1 ? "month" : "\(value) months"
        case .year:
            return value == 1 ? "year" : "\(value) years"
        @unknown default:
            return "period"
        }
    }

    private static func productPriority(lhs: String, rhs: String) -> Bool {
        priority(for: lhs) < priority(for: rhs)
    }

    private static func priority(for productIdentifier: String) -> Int {
        switch productIdentifier {
        case ProductCatalog.lifetime:
            return 0
        case ProductCatalog.annual:
            return 1
        case ProductCatalog.monthly:
            return 2
        default:
            return 3
        }
    }

    private static func planDisplayName(for productIdentifier: String) -> String? {
        switch productIdentifier {
        case ProductCatalog.monthly:
            return "Monthly"
        case ProductCatalog.annual:
            return "Annual"
        case ProductCatalog.lifetime:
            return "Lifetime"
        default:
            return nil
        }
    }
}

private extension SubscriptionTier {
    var displayName: String {
        switch self {
        case .free:
            return "Access required"
        case .premium:
            return "Premium"
        }
    }
}

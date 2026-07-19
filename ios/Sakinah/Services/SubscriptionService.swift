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

        // RevenueCat's Test Store uses these identifiers for the same packages.
        // They are only considered when the debug Test Store key is active; the
        // protected App Store product IDs above remain unchanged for production.
        static let testStoreMonthly = "monthly"
        static let testStoreAnnual = "yearly"

        static let allProductIDs: Set<String> = [monthly, annual, lifetime]
        static let sellablePlanProductIDs: Set<String> = [monthly, annual]
    }

    private static let allPlansOfferingIdentifier = "default2"

    private enum DefaultsKey {
        static let tier = "sakinah.subscriptionTier"
        static let migrationSyncCompleted = "sakinah.revenuecatMigrationSyncCompleted"
    }

    private static let unavailablePriceText = "Price unavailable"
    private static let requiredFreeTrialDays = 3

    static let shared = SubscriptionService()
    static let monthlyProductID = ProductCatalog.monthly
    static let annualProductID = ProductCatalog.annual
    static let lifetimeProductID = ProductCatalog.lifetime
    static let defaultPlan: Plan = .annual

    enum Plan: String, CaseIterable, Identifiable, Sendable {
        case annual
        case monthly

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .annual:
                return "Annual"
            case .monthly:
                return "Monthly"
            }
        }

        var productIdentifier: String {
            switch self {
            case .annual:
                return SubscriptionService.annualProductID
            case .monthly:
                return SubscriptionService.monthlyProductID
            }
        }

        fileprivate var fallbackCadence: String {
            switch self {
            case .annual:
                return "year"
            case .monthly:
                return "month"
            }
        }
    }

    struct PlanDetails {
        let plan: Plan
        let package: Package?
        let product: StoreProduct?
        let localizedPrice: String?
        let cadence: String
        let trialDuration: String?
        let monthlyEquivalentPrice: String?
        let annualSavingsPercent: Int?

        var productIdentifier: String { plan.productIdentifier }
        var displayName: String { plan.displayName }
        /// Whether StoreKit has a free-trial offer configured; check customer eligibility separately.
        var hasFreeTrial: Bool { trialDuration != nil }
        var isAvailable: Bool { package != nil || product != nil }
    }

    var currentTier: SubscriptionTier = .free
    var isLoadingProducts = false
    private(set) var isPurchasing = false
    var isRestoringPurchases = false
    var isSyncingLegacyPurchases = false
    var purchaseError: String?

    private(set) var customerInfo: CustomerInfo?
    private(set) var offerings: Offerings?
    private(set) var currentOffering: Offering?
    private(set) var manageOffering: Offering?
    private(set) var monthlyProduct: StoreProduct?
    private(set) var annualProduct: StoreProduct?
    private(set) var lifetimeProduct: StoreProduct?

    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let configuration: RevenueCatConfiguration?
    @ObservationIgnored private let configurationErrorDescription: String?
    @ObservationIgnored private let customerInfoUpdatesObserver = CustomerInfoUpdatesObserver()

    var isPremium: Bool { currentTier == .premium }
    var isLoading: Bool {
        isLoadingProducts || isPurchasing || isRestoringPurchases || isSyncingLegacyPurchases
    }
    var canOpenCustomerCenter: Bool { isRevenueCatAvailable }
    var isRevenueCatAvailable: Bool { configuration != nil && Purchases.isConfigured }
    var revenueCatUnavailableMessage: String {
        Self.unavailableMessage(from: configurationErrorDescription ?? "Plans are unavailable.")
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

    var annualTrialDurationText: String? {
        Self.freeTrialDuration(for: annualPackage?.storeProduct ?? annualProduct)
    }

    var annualTrialHeadline: String? {
        annualTrialDurationText.map { "\($0) free trial on annual" }
    }

    var featuredPlanSummary: String {
        if let trial = annualTrialDurationText {
            return "Start with a \(trial) free trial, then continue on annual for \(annualDisplayPrice)."
        }

        return "Annual is the best value at \(annualDisplayPrice)."
    }

    var premiumAccessSummary: String {
        "Private scans, estimate bands, and TrueMax style tools stay unlocked as long as your plan is active."
    }

    var featuredUpgradePrice: String? {
        if annualDisplayPrice != Self.unavailablePriceText {
            return annualDisplayPrice
        }

        if monthlyDisplayPrice != Self.unavailablePriceText {
            return monthlyDisplayPrice
        }

        return nil
    }

    func package(for plan: Plan) -> Package? {
        switch plan {
        case .annual:
            return annualPackage
        case .monthly:
            return monthlyPackage
        }
    }

    func product(for plan: Plan) -> StoreProduct? {
        if let package = package(for: plan) {
            return package.storeProduct
        }

        switch plan {
        case .annual:
            return annualProduct
        case .monthly:
            return monthlyProduct
        }
    }

    func planDetails(for plan: Plan) -> PlanDetails {
        let package = package(for: plan)
        let product = self.product(for: plan)
        let annualPlanProduct = self.product(for: .annual)
        let monthlyPlanProduct = self.product(for: .monthly)

        return PlanDetails(
            plan: plan,
            package: package,
            product: product,
            localizedPrice: product?.localizedPriceString,
            cadence: product?.subscriptionPeriod.map(Self.compactSubscriptionPeriod) ?? plan.fallbackCadence,
            trialDuration: Self.freeTrialDuration(for: product),
            monthlyEquivalentPrice: plan == .annual
                ? Self.annualMonthlyEquivalent(for: annualPlanProduct)
                : nil,
            annualSavingsPercent: plan == .annual
                ? Self.annualSavingsPercent(
                    annualProduct: annualPlanProduct,
                    monthlyProduct: monthlyPlanProduct
                )
                : nil
        )
    }

    func trialEligibility(for plan: Plan) async -> IntroEligibilityStatus {
        guard ensureRevenueCatAvailable() else { return .unknown }

        if product(for: plan) == nil {
            _ = await loadProducts(forceRefresh: false)
        }

        guard let product = product(for: plan),
              Self.freeTrialDuration(for: product) != nil else {
            return .noIntroOfferExists
        }

        return await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: product)
    }

    private var monthlyPackage: Package? {
        availablePackages.first { matches($0.storeProduct, to: .monthly) }
    }

    private var annualPackage: Package? {
        availablePackages.first { matches($0.storeProduct, to: .annual) }
    }

    private var lifetimePackage: Package? {
        availablePackages.first { $0.storeProduct.productIdentifier == ProductCatalog.lifetime }
    }

    private var availablePackages: [Package] {
        let primaryPackages = manageOffering?.availablePackages ?? currentOffering?.availablePackages ?? []
        let currentOfferingPackages = currentOffering?.availablePackages ?? []
        let fallbackPackages = offerings?.all.values.flatMap(\.availablePackages) ?? []

        var seenProductIDs = Set<String>()

        return (primaryPackages + currentOfferingPackages + fallbackPackages).filter { package in
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
            .filter { knownProductIDs.contains($0) }

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
            await runLegacyMigrationSyncIfNeeded(shouldAttemptMigration: shouldAttemptMigration)
        }
    }

    func preparePaywall(forceRefresh: Bool = false) async -> Bool {
        guard ensureRevenueCatAvailable() else { return false }

        var loadedProducts = await loadProducts(forceRefresh: forceRefresh || currentOffering == nil)

        // The app bootstrap and the paywall can become active at nearly the same time.
        // If RevenueCat returns an incomplete cache on that first request, retry once so
        // the custom paywall does not remain stuck showing placeholder prices.
        if !loadedProducts {
            loadedProducts = await loadProducts(forceRefresh: true)
        }

        await refreshEntitlements()

        return loadedProducts && hasAnyPurchaseOption
    }

    @discardableResult
    func loadProducts(forceRefresh: Bool) async -> Bool {
        guard ensureRevenueCatAvailable() else { return false }

        if isLoadingProducts {
            return hasAnyPurchaseOption
        }

        if hasLoadedRequiredOfferingsAndProducts && !forceRefresh {
            return true
        }

        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let loadedOfferings = try await Purchases.shared.offerings()
            offerings = loadedOfferings
            currentOffering = selectMainOffering(from: loadedOfferings)
            manageOffering = selectManageOffering(from: loadedOfferings)

            if currentOffering == nil && manageOffering == nil {
                purchaseError = "Plans are unavailable right now. Please try again in a moment."
            } else {
                purchaseError = nil
            }
        } catch {
            purchaseError = userFacingErrorMessage(for: error)
        }

        let products = await Purchases.shared.products(Array(productIDsToLoad))
        monthlyProduct = products.first { matches($0, to: .monthly) }
        annualProduct = products.first { matches($0, to: .annual) }
        lifetimeProduct = products.first { $0.productIdentifier == ProductCatalog.lifetime }

        if monthlyProduct == nil || annualProduct == nil {
            let loadedProductIDs = products.map(\.productIdentifier).sorted().joined(separator: ", ")
            let receivedProductIDs = loadedProductIDs.isEmpty ? "none" : loadedProductIDs
            print(
                "RevenueCat did not return both sellable TrueMax products. "
                    + "Expected monthly/annual IDs; received: \(receivedProductIDs)"
            )

            if currentOffering == nil && manageOffering == nil {
                purchaseError = "Plans are temporarily unavailable. Please try again soon."
            }
        }

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

    @discardableResult
    func purchase(plan: Plan) async -> Bool {
        guard ensureRevenueCatAvailable() else { return false }
        guard !isPurchasing else { return false }

        purchaseError = nil
        isPurchasing = true
        defer { isPurchasing = false }

        if package(for: plan) == nil && product(for: plan) == nil {
            _ = await loadProducts(forceRefresh: false)
        }

        do {
            let result: PurchaseResultData

            if let package = package(for: plan) {
                result = try await Purchases.shared.purchase(package: package)
            } else if let product = product(for: plan) {
                result = try await Purchases.shared.purchase(product: product)
            } else {
                purchaseError = "That plan is unavailable right now. Please try again in a moment."
                return false
            }

            applyCustomerInfo(result.customerInfo)

            if result.userCancelled {
                purchaseError = nil
                return false
            }

            guard isPremium else {
                purchaseError = "Your purchase is being confirmed. Premium will unlock automatically."
                return false
            }

            purchaseError = nil
            return true
        } catch {
            purchaseError = isUserCancelledError(error) ? nil : userFacingErrorMessage(for: error)
            return false
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

        if !activeEntitlementProductIDs.isDisjoint(with: knownProductIDs) {
            return .premium
        }

        if !customerInfo.activeSubscriptions.isDisjoint(with: knownProductIDs) {
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
        currentOffering != nil || manageOffering != nil || monthlyProduct != nil || annualProduct != nil
    }

    private var hasLoadedRequiredOfferingsAndProducts: Bool {
        currentOffering != nil
            && manageOffering != nil
            && monthlyProduct != nil
            && annualProduct != nil
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

    private static func freeTrialDuration(for product: StoreProduct?) -> String? {
        guard let introductoryDiscount = product?.introductoryDiscount else { return nil }
        guard introductoryDiscount.paymentMode == .freeTrial else { return nil }

        let period = introductoryDiscount.subscriptionPeriod
        guard period.unit == .day,
              period.value * max(introductoryDiscount.numberOfPeriods, 1) == requiredFreeTrialDays else {
            return nil
        }

        return "\(requiredFreeTrialDays) days"
    }

    private static func annualMonthlyEquivalent(for product: StoreProduct?) -> String? {
        guard hasPeriod(product, unit: .year, value: 1) else { return nil }
        return product?.localizedPricePerMonth
    }

    private static func annualSavingsPercent(
        annualProduct: StoreProduct?,
        monthlyProduct: StoreProduct?
    ) -> Int? {
        guard let annualProduct, let monthlyProduct else { return nil }
        guard hasPeriod(annualProduct, unit: .year, value: 1) else { return nil }
        guard hasPeriod(monthlyProduct, unit: .month, value: 1) else { return nil }
        guard let annualCurrency = annualProduct.currencyCode,
              let monthlyCurrency = monthlyProduct.currencyCode,
              annualCurrency == monthlyCurrency else {
            return nil
        }

        let annualizedMonthlyPrice = monthlyProduct.price * 12
        guard annualizedMonthlyPrice > 0,
              annualProduct.price > 0,
              annualProduct.price < annualizedMonthlyPrice else {
            return nil
        }

        let savings = (annualizedMonthlyPrice - annualProduct.price) / annualizedMonthlyPrice
        let roundedPercentage = Int((NSDecimalNumber(decimal: savings).doubleValue * 100).rounded())

        return roundedPercentage > 0 ? roundedPercentage : nil
    }

    private static func hasPeriod(
        _ product: StoreProduct?,
        unit: SubscriptionPeriod.Unit,
        value: Int
    ) -> Bool {
        guard let period = product?.subscriptionPeriod else { return false }
        return period.unit == unit && period.value == value
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

    private func selectMainOffering(from offerings: Offerings) -> Offering? {
        let preferredOffering = offerings.all[Self.allPlansOfferingIdentifier]
            ?? offerings.current
            ?? offerings.all["default"]
        let candidates = [preferredOffering].compactMap { $0 } + offerings.all.values.sorted(by: { $0.identifier < $1.identifier })

        if let annualOnly = candidates.first(where: isAnnualOnlyOffering) {
            return annualOnly
        }

        if let annualOffering = candidates.first(where: includesAnnualPlan) {
            return annualOffering
        }

        return preferredOffering ?? candidates.first
    }

    private func selectManageOffering(from offerings: Offerings) -> Offering? {
        let preferredKeys = [Self.allPlansOfferingIdentifier, "manage", "plans", "allplans"]
        let preferredOfferings = preferredKeys.compactMap { offerings.all[$0] }
        let remainingOfferings = offerings.all.values
            .filter { !preferredKeys.contains($0.identifier) }
            .sorted(by: { $0.identifier < $1.identifier })

        let candidates = preferredOfferings + remainingOfferings

        if let exactTwoPlanOffering = candidates.first(where: isMonthlyAnnualOnlyOffering) {
            return exactTwoPlanOffering
        }

        if let multiPlanOffering = candidates.first(where: includesMonthlyAndAnnualPlans) {
            return multiPlanOffering
        }

        return preferredOfferings.first ?? offerings.current ?? offerings.all["default"] ?? candidates.first
    }

    private func includesAnnualPlan(_ offering: Offering) -> Bool {
        offering.availablePackages.contains { matches($0.storeProduct, to: .annual) }
    }

    private func isAnnualOnlyOffering(_ offering: Offering) -> Bool {
        packageProductIdentifiers(in: offering).count == 1
            && includesAnnualPlan(offering)
    }

    private func isMonthlyAnnualOnlyOffering(_ offering: Offering) -> Bool {
        packageProductIdentifiers(in: offering).count == 2
            && includesMonthlyAndAnnualPlans(offering)
    }

    private func includesMonthlyAndAnnualPlans(_ offering: Offering) -> Bool {
        includesMonthlyPlan(offering) && includesAnnualPlan(offering)
    }

    private func includesMonthlyPlan(_ offering: Offering) -> Bool {
        offering.availablePackages.contains { matches($0.storeProduct, to: .monthly) }
    }

    private func matches(_ product: StoreProduct, to plan: Plan) -> Bool {
        switch plan {
        case .annual:
            return product.productIdentifier == ProductCatalog.annual
                || (configuration?.usesTestStore == true
                    && product.productIdentifier == ProductCatalog.testStoreAnnual)
        case .monthly:
            return product.productIdentifier == ProductCatalog.monthly
                || (configuration?.usesTestStore == true
                    && product.productIdentifier == ProductCatalog.testStoreMonthly)
        }
    }

    private var productIDsToLoad: Set<String> {
        var productIDs = ProductCatalog.allProductIDs
        if configuration?.usesTestStore == true {
            productIDs.insert(ProductCatalog.testStoreMonthly)
            productIDs.insert(ProductCatalog.testStoreAnnual)
        }
        return productIDs
    }

    private var knownProductIDs: Set<String> {
        productIDsToLoad
    }

    private func packageProductIdentifiers(in offering: Offering) -> Set<String> {
        Set(offering.availablePackages.map(\.storeProduct.productIdentifier))
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

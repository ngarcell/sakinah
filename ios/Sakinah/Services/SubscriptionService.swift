import Foundation
import Observation
import RevenueCat

enum SubscriptionStatus: Equatable, Sendable {
    case notSubscribed
    case subscribed(String)
    case expired
}

@Observable
@MainActor
final class SubscriptionService: NSObject {
    static let shared = SubscriptionService()

    var subscriptionStatus: SubscriptionStatus = .notSubscribed
    var availableProducts: [String] = []
    var isPremium: Bool = false
    var isConfigured: Bool = false

    static let monthlyID  = "com.socialreporthq.sakinah.premium.monthly"
    static let annualID   = "com.socialreporthq.sakinah.premium.annual"
    static let lifetimeID = "com.socialreporthq.sakinah.premium.lifetimev2"

    private var packagesByProductID: [String: Package] = [:]

    private override init() {
        super.init()
    }

    func configure(apiKey: String) {
        guard !isConfigured else { return }
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self
        isConfigured = true
    }

    func loadProducts() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            let packages =
                offerings.current?.availablePackages
                ?? offerings.all.values.first(where: { !$0.availablePackages.isEmpty })?.availablePackages
                ?? []
            packagesByProductID = Dictionary(uniqueKeysWithValues: packages.map { ($0.storeProduct.productIdentifier, $0) })
            availableProducts = packages.map(\.storeProduct.productIdentifier)
            print("[Sakinah] Loaded \(packages.count) products: \(availableProducts)")
        } catch {
            print("[Sakinah] Failed to load products: \(error)")
            packagesByProductID = [:]
            availableProducts = []
        }
    }

    func purchase(productID: String) async throws -> Bool {
        // Ensure products are loaded
        if packagesByProductID.isEmpty {
            await loadProducts()
        }

        guard let package = packagesByProductID[productID] else {
            print("[Sakinah] No package found for \(productID). Available: \(Array(packagesByProductID.keys))")
            return false
        }

        print("[Sakinah] Starting purchase for \(productID)...")

        // This call triggers the Apple payment sheet
        let result = try await Purchases.shared.purchase(package: package)

        if result.userCancelled {
            print("[Sakinah] User cancelled purchase")
            return false
        }

        print("[Sakinah] Purchase successful, updating status...")
        await updateSubscriptionStatus(customerInfo: result.customerInfo)
        return true
    }

    func checkEntitlement() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await updateSubscriptionStatus(customerInfo: customerInfo)
        } catch {
            print("[Sakinah] Failed to check entitlement: \(error)")
            isPremium = false
            subscriptionStatus = .notSubscribed
        }
    }

    func restorePurchases() async {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            await updateSubscriptionStatus(customerInfo: customerInfo)
        } catch {
            await checkEntitlement()
        }
    }

    private func updateSubscriptionStatus(customerInfo: CustomerInfo) async {
        // Check for active entitlement first (most reliable)
        if customerInfo.entitlements["premium"]?.isActive == true {
            isPremium = true
            let activeID = customerInfo.activeSubscriptions.first ?? "premium"
            subscriptionStatus = .subscribed(activeID)
            print("[Sakinah] Premium active via entitlement")
            return
        }

        // Fallback: check active subscriptions directly
        let active = Set(customerInfo.activeSubscriptions)
        for productID in [Self.monthlyID, Self.annualID, Self.lifetimeID] {
            if active.contains(productID) {
                isPremium = true
                subscriptionStatus = .subscribed(productID)
                print("[Sakinah] Premium active via subscription: \(productID)")
                return
            }
        }

        // Check non-consumable purchases (lifetime)
        let nonConsumable = Set(customerInfo.nonSubscriptions.map(\.productIdentifier))
        if nonConsumable.contains(Self.lifetimeID) {
            isPremium = true
            subscriptionStatus = .subscribed(Self.lifetimeID)
            print("[Sakinah] Premium active via lifetime purchase")
            return
        }

        isPremium = false
        subscriptionStatus = .notSubscribed
        print("[Sakinah] No active premium")
    }
}

extension SubscriptionService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor [weak self] in
            await self?.updateSubscriptionStatus(customerInfo: customerInfo)
        }
    }
}

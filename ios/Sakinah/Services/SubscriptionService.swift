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
        // Force StoreKit 1 — SK2 has known issues with payment sheet presentation
        Purchases.configure(
            with: .init(withAPIKey: apiKey)
                .with(storeKitVersion: .storeKit1)
        )
        Purchases.shared.delegate = self
        isConfigured = true
        print("[Sakinah] RevenueCat configured with SK1")
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
            print("[Sakinah] Products not loaded, loading now...")
            await loadProducts()
        }

        guard let package = packagesByProductID[productID] else {
            print("[Sakinah] ERROR: No package found for \(productID)")
            print("[Sakinah] Available packages: \(Array(packagesByProductID.keys))")
            return false
        }

        print("[Sakinah] Initiating purchase for: \(productID)")

        // Purchase — SK1 will show the native Apple payment sheet
        let result = try await Purchases.shared.purchase(package: package)

        if result.userCancelled {
            print("[Sakinah] User cancelled")
            return false
        }

        print("[Sakinah] Purchase completed successfully")
        await updateSubscriptionStatus(customerInfo: result.customerInfo)
        return true
    }

    func checkEntitlement() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await updateSubscriptionStatus(customerInfo: customerInfo)
        } catch {
            print("[Sakinah] Entitlement check failed: \(error)")
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
        // 1. Check entitlements (most reliable)
        if customerInfo.entitlements["premium"]?.isActive == true {
            isPremium = true
            let activeID = customerInfo.activeSubscriptions.first ?? "premium"
            subscriptionStatus = .subscribed(activeID)
            print("[Sakinah] Premium ACTIVE via entitlement")
            return
        }

        // 2. Check active subscriptions by product ID
        let active = Set(customerInfo.activeSubscriptions)
        for productID in [Self.monthlyID, Self.annualID, Self.lifetimeID] {
            if active.contains(productID) {
                isPremium = true
                subscriptionStatus = .subscribed(productID)
                print("[Sakinah] Premium ACTIVE via subscription: \(productID)")
                return
            }
        }

        // 3. Check non-consumable (lifetime)
        let nonConsumable = Set(customerInfo.nonSubscriptions.map(\.productIdentifier))
        if nonConsumable.contains(Self.lifetimeID) {
            isPremium = true
            subscriptionStatus = .subscribed(Self.lifetimeID)
            print("[Sakinah] Premium ACTIVE via lifetime")
            return
        }

        isPremium = false
        subscriptionStatus = .notSubscribed
        print("[Sakinah] No active premium found")
    }
}

extension SubscriptionService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor [weak self] in
            await self?.updateSubscriptionStatus(customerInfo: customerInfo)
        }
    }
}

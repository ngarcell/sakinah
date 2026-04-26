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

    static let monthlyID  = "com.socialreporthq.sakinah.premium.monthly"
    static let annualID   = "com.socialreporthq.sakinah.premium.annual"
    static let lifetimeID = "com.socialreporthq.sakinah.premium.lifetimev2"

    private var packagesByProductID: [String: Package] = [:]

    private override init() {
        super.init()
    }

    func configure(apiKey: String) {
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self
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
        } catch {
            packagesByProductID = [:]
            availableProducts = []
        }
    }

    func purchase(productID: String) async throws -> Bool {
        if packagesByProductID[productID] == nil {
            await loadProducts()
        }

        guard let package = packagesByProductID[productID] else {
            return false
        }

        let result = try await Purchases.shared.purchase(package: package)
        await updateSubscriptionStatus(customerInfo: result.customerInfo)
        return !result.userCancelled
    }

    func checkEntitlement() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await updateSubscriptionStatus(customerInfo: customerInfo)
        } catch {
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
        let active = Set(customerInfo.activeSubscriptions)
        for productID in [Self.monthlyID, Self.annualID, Self.lifetimeID] {
            if active.contains(productID) {
                isPremium = true
                subscriptionStatus = .subscribed(productID)
                return
            }
        }

        isPremium = false
        subscriptionStatus = .notSubscribed
    }
}

extension SubscriptionService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor [weak self] in
            await self?.updateSubscriptionStatus(customerInfo: customerInfo)
        }
    }
}

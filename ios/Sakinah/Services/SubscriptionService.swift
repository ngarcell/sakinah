import Foundation
import StoreKit
import Observation

enum SubscriptionStatus: Equatable {
    case notSubscribed
    case subscribed(Product.ID)
    case expired
}

@Observable
@MainActor
final class SubscriptionService {
    static let shared = SubscriptionService()

    var subscriptionStatus: SubscriptionStatus = .notSubscribed
    var availableProducts: [Product] = []
    var isPremium: Bool = false

    static let monthlyID = "com.sakinah.premium.monthly"
    static let annualID = "com.sakinah.premium.annual"
    static let lifetimeID = "com.sakinah.premium.lifetime"

    private var updateListenerTask: Task<Void, Error>? = nil

    private init() {
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [
                Self.monthlyID,
                Self.annualID,
                Self.lifetimeID
            ])
            availableProducts = products.sorted { $0.price < $1.price }
        } catch {
            // Products not available (likely no App Store config)
            // Use placeholder data for development
            availableProducts = []
        }
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    func checkEntitlement() async {
        await updateSubscriptionStatus()
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updateSubscriptionStatus()
    }

    private func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                isPremium = true
                subscriptionStatus = .subscribed(transaction.productID)
                return
            }
        }
        isPremium = false
        subscriptionStatus = .notSubscribed
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? self?.checkVerified(result) {
                    await self?.updateSubscriptionStatus()
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    enum StoreError: Error {
        case verificationFailed
    }
}

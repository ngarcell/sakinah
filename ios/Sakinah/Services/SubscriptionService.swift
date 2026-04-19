import Foundation
import StoreKit
import Observation

enum SubscriptionStatus: Equatable, Sendable {
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

    static let monthlyID  = "com.socialreporthq.sakinah.premium.monthly"
    static let annualID   = "com.socialreporthq.sakinah.premium.annual"
    static let lifetimeID = "com.socialreporthq.sakinah.premium.lifetime"

    private init() {
        Task { [weak self] in
            await self?.listenForTransactions()
        }
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
            availableProducts = []
        }
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try Self.checkVerified(verification)
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
            if let transaction = try? Self.checkVerified(result) {
                isPremium = true
                subscriptionStatus = .subscribed(transaction.productID)
                return
            }
        }
        isPremium = false
        subscriptionStatus = .notSubscribed
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? Self.checkVerified(result) {
                await updateSubscriptionStatus()
                await transaction.finish()
            }
        }
    }

    nonisolated private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
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

import Foundation

@MainActor
protocol SubscriptionServiceProtocol {
    var isSubscribed: Bool { get }
    func loadProducts() async throws
    func purchase(productID: String) async throws -> Bool
    func restore() async throws
}

@MainActor
final class SubscriptionService: SubscriptionServiceProtocol {
    static let shared = SubscriptionService()
    var isSubscribed: Bool = false
    private init() {}
    func loadProducts() async throws {}
    func purchase(productID: String) async throws -> Bool { false }
    func restore() async throws {}
}

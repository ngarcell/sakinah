import Foundation

@MainActor
final class CloudKitService {
    static let shared = CloudKitService()
    private init() {}

    func saveCoupleInvite(code: String, userID: String) async throws {}
    func lookupInvite(code: String) async throws -> (userID: String, name: String)? { nil }
    func linkPartner(code: String, userID: String, name: String) async throws {}
}

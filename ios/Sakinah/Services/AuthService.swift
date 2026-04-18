import Foundation
import AuthenticationServices
import Security
import Observation

@Observable
@MainActor
final class AuthService: NSObject {
    static let shared = AuthService()
    var currentUser: User?

    func handleAppleSignIn(_ authorization: ASAuthorization) -> (id: String, name: String)? {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return nil }
        let id = credential.user
        let name = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }.joined(separator: " ")
        saveToKeychain(key: "appleUserID", value: id)
        return (id, name.isEmpty ? "Friend" : name)
    }

    func signOut() {
        currentUser = nil
        deleteFromKeychain(key: "appleUserID")
    }

    private func saveToKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

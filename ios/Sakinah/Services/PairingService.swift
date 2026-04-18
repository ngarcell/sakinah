import Foundation

@MainActor
final class PairingService {
    static let shared = PairingService()
    private init() {}

    func generateInviteCode() -> String {
        let alphabet = Constants.inviteCodeAlphabet
        return String((0..<Constants.inviteCodeLength).map { _ in
            alphabet.randomElement() ?? "A"
        })
    }

    func validateFormat(_ code: String) -> Bool {
        let cleaned = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.count == Constants.inviteCodeLength else { return false }
        let allowed = CharacterSet(charactersIn: Constants.inviteCodeAlphabet)
        return cleaned.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}

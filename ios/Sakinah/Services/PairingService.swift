import Foundation
import SwiftData

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

    /// Link a partner to an existing couple via invite code.
    /// In a full CloudKit implementation this would query the public DB for the code.
    func linkPartner(code: String, user: User, context: ModelContext) -> Couple? {
        let cleaned = code.uppercased()
        guard validateFormat(cleaned) else { return nil }

        // Search local SwiftData for a couple with this invite code
        let predicate = #Predicate<Couple> { c in c.inviteCode == cleaned }
        let descriptor = FetchDescriptor<Couple>(predicate: predicate)
        guard let couple = (try? context.fetch(descriptor))?.first else { return nil }

        // Link user as partner
        couple.user2ID = user.id
        couple.user2Name = user.name
        user.coupleID = couple.id
        user.partnerID = couple.user1ID
        try? context.save()

        return couple
    }

    /// Unlink the current partner — clears couple association but preserves user data.
    func unlinkPartner(user: User, context: ModelContext) {
        guard let coupleID = user.coupleID else { return }

        let predicate = #Predicate<Couple> { c in c.id == coupleID }
        let descriptor = FetchDescriptor<Couple>(predicate: predicate)

        if let couple = (try? context.fetch(descriptor))?.first {
            // Clear partner fields
            couple.user2ID = ""
            couple.user2Name = ""
        }

        user.coupleID = nil
        user.partnerID = nil
        try? context.save()
    }
}

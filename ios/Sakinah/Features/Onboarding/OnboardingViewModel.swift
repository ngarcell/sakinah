import SwiftUI
import SwiftData

enum OnboardingStep: Int, CaseIterable {
    case welcome, invitePartner, waiting, coupleSetup, firstPrompt
}

enum InvitePath {
    case starting, joining
}

@Observable
@MainActor
final class OnboardingViewModel {
    var step: OnboardingStep = .welcome
    var invitePath: InvitePath = .starting
    var inviteCode: String = ""
    var joinCode: String = ""
    var joinError: String?

    var yourName: String = ""
    var partnerName: String = ""
    var relationshipStage: RelationshipStage = .married
    var anniversaryDate: Date = Date()
    var hasAnniversary: Bool = false
    var useHijri: Bool = false
    var duaLanguage: DuaLanguage = .arabicEnglish

    var firstResponse: String = ""

    init() {
        self.inviteCode = PairingService.shared.generateInviteCode()
    }

    func advance(to step: OnboardingStep) {
        withAnimation(SakinahAnimation.gentle) {
            self.step = step
        }
    }

    func validateAndJoin() -> Bool {
        let code = joinCode.uppercased()
        guard PairingService.shared.validateFormat(code) else {
            joinError = "Enter the full code to continue."
            HapticEngine.shared.fire(.error)
            return false
        }
        joinError = nil
        HapticEngine.shared.fire(.success)
        advance(to: .coupleSetup)
        return true
    }

    func finish(context: ModelContext, appState: AppState) {
        let firstPrompt = ContentService.shared.firstPrompt(
            partnerName: partnerName.isEmpty ? "your partner" : partnerName
        )
        let user = User(
            id: UUID().uuidString,
            name: yourName.isEmpty ? "You" : yourName,
            duaLanguagePreference: duaLanguage
        )
        let couple = Couple(
            user1ID: user.id,
            user1Name: user.name,
            user2Name: partnerName.isEmpty ? "Partner" : partnerName,
            inviteCode: inviteCode,
            relationshipStage: relationshipStage,
            anniversaryDate: hasAnniversary ? anniversaryDate : nil,
            useHijriCalendar: useHijri
        )
        user.coupleID = couple.id
        context.insert(user)
        context.insert(couple)

        let response = PromptResponse(
            promptID: firstPrompt.id,
            coupleID: couple.id,
            userID: user.id,
            responseText: firstResponse.trimmingCharacters(in: .whitespacesAndNewlines),
            isRevealed: false
        )
        context.insert(response)

        try? context.save()
        appState.completeOnboarding(user: user, couple: couple)
    }
}

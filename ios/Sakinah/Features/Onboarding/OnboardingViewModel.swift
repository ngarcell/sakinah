import SwiftUI
import SwiftData
import AuthenticationServices

enum OnboardingStep: Int, CaseIterable {
    case welcome, signIn, invitePartner, waiting, coupleSetup, firstPrompt
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

    var appleUserID: String = ""
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

    func handleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let info = AuthService.shared.handleAppleSignIn(auth) {
                self.appleUserID = info.id
                self.yourName = info.name
                HapticEngine.shared.fire(.success)
                advance(to: .invitePartner)
            }
        case .failure:
            HapticEngine.shared.fire(.error)
        }
    }

    func validateAndJoin() -> Bool {
        let code = joinCode.uppercased()
        guard PairingService.shared.validateFormat(code) else {
            joinError = "Please enter a valid 6-character code"
            HapticEngine.shared.fire(.error)
            return false
        }
        joinError = nil
        HapticEngine.shared.fire(.success)
        advance(to: .coupleSetup)
        return true
    }

    func finish(context: ModelContext, appState: AppState) {
        let user = User(
            id: appleUserID.isEmpty ? UUID().uuidString : appleUserID,
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
        try? context.save()
        appState.completeOnboarding(user: user, couple: couple)
    }
}

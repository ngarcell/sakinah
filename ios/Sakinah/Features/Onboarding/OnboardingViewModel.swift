import SwiftUI
import SwiftData

enum OnboardingStep: Int, CaseIterable {
    case welcome, coupleSetup, firstPrompt
}

@Observable
@MainActor
final class OnboardingViewModel {
    var step: OnboardingStep = .welcome
    var inviteCode: String = ""
    let hasPendingShareInvitation: Bool

    var yourName: String = ""
    var partnerName: String = ""
    var relationshipStage: RelationshipStage = .married
    var anniversaryDate: Date = Date()
    var hasAnniversary: Bool = false
    var useHijri: Bool = false
    var duaLanguage: DuaLanguage = .arabicEnglish

    var firstResponse: String = ""

    init() {
        hasPendingShareInvitation = CloudKitService.shared.hasPendingAcceptedShare
        self.inviteCode = PairingService.shared.generateInviteCode()
    }

    func advance(to step: OnboardingStep) {
        withAnimation(SakinahAnimation.gentle) {
            self.step = step
        }
    }

    func finish(context: ModelContext, appState: AppState) {
        let firstPrompt = ContentService.shared.firstPrompt(
            partnerName: partnerName.isEmpty ? "your spouse" : partnerName
        )
        let user = User(
            id: UUID().uuidString,
            name: yourName.isEmpty ? "You" : yourName,
            duaLanguagePreference: duaLanguage
        )
        let couple = Couple(
            user1ID: user.id,
            user1Name: user.name,
            user2Name: partnerName.isEmpty ? "Spouse" : partnerName,
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

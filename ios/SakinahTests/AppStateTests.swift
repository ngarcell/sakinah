import SwiftUI
import Testing
@testable import Sakinah

struct AppStateTests {

    @Test
    @MainActor
    func onboardingCompletionRequiresPremiumAccess() {
        let appState = AppState()
        let user = User(id: "user-1", name: "Yusuf")
        let couple = Couple(
            user1ID: user.id,
            user1Name: user.name,
            user2Name: "Aisha",
            inviteCode: "ABC123"
        )

        appState.completeOnboarding(user: user, couple: couple)

        #expect(appState.route == .main)
        #expect(appState.paywallState == .handoffAfterOnboarding)
        #expect(appState.shouldShowPaywallHandoff)
        #expect(!appState.shouldShowMandatoryPaywall)
        #expect(appState.pairingStatus == .readyToInvite)
    }

    @Test
    @MainActor
    func onboardingHandoffAdvancesToHostedPaywall() {
        let appState = AppState()
        let user = User(id: "user-1", name: "Yusuf")
        let couple = Couple(
            user1ID: user.id,
            user1Name: user.name,
            user2Name: "Aisha",
            inviteCode: "ABC123"
        )

        appState.completeOnboarding(user: user, couple: couple)
        appState.advanceToHostedPaywall()

        #expect(appState.paywallState == .requiredAfterOnboarding)
        #expect(!appState.shouldShowPaywallHandoff)
        #expect(appState.shouldShowMandatoryPaywall)
    }

    @Test
    @MainActor
    func premiumAccessClearsMandatoryPaywall() {
        let appState = AppState()
        let user = User(id: "user-1", name: "Yusuf")
        let couple = Couple(
            user1ID: user.id,
            user1Name: user.name,
            user2Name: "Aisha",
            inviteCode: "ABC123"
        )

        appState.restoreSession(user: user, couple: couple)
        appState.handleSubscriptionState(isPremium: true)

        #expect(appState.paywallState == .none)
        #expect(appState.hasPremiumAccess)
        #expect(!appState.shouldShowMandatoryPaywall)
    }

    @Test
    @MainActor
    func partnerNameReflectsOtherMemberOfCouple() {
        let user = User(id: "user-2", name: "Aisha")
        let couple = Couple(
            user1ID: "user-1",
            user2ID: user.id,
            user1Name: "Yusuf",
            user2Name: user.name,
            inviteCode: "ABC123"
        )
        let appState = AppState()

        appState.restoreSession(user: user, couple: couple)

        #expect(appState.partnerName == "Yusuf")
    }

    @Test
    func appearanceModesMapToExpectedColorSchemes() {
        #expect(AppAppearanceMode.system.colorScheme == nil)
        #expect(AppAppearanceMode.light.colorScheme == .light)
        #expect(AppAppearanceMode.dark.colorScheme == .dark)
    }
}

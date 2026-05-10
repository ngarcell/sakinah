import SwiftUI
import Testing
@testable import Sakinah

struct AppStateTests {

    @Test
    @MainActor
    func onboardingCompletionPresentsStarterPaywallSheet() {
        let appState = AppState()
        let user = User(id: "user-1", name: "Yusuf")
        user.requiresInitialSubscriptionUnlock = true
        let couple = Couple(
            user1ID: user.id,
            user1Name: user.name,
            user2Name: "Aisha",
            inviteCode: "ABC123"
        )

        appState.completeOnboarding(user: user, couple: couple)

        #expect(appState.route == .main)
        #expect(appState.paywallState == .none)
        #expect(appState.presentedPaywallEntryPoint == .starterPlan)
        #expect(!appState.shouldShowMandatoryPaywall)
        #expect(appState.pairingStatus == .readyToInvite)
    }

    @Test
    @MainActor
    func advanceToHostedPaywallPresentsHostedSheet() {
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

        #expect(appState.paywallState == .none)
        #expect(appState.presentedPaywallEntryPoint == .starterPlan)
        #expect(!appState.shouldShowPaywallHandoff)
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
    func lapsedUsersStayInMainAppReadOnly() {
        let appState = AppState()
        let user = User(id: "user-1", name: "Yusuf")
        let couple = Couple(
            user1ID: user.id,
            user1Name: user.name,
            user2Name: "Aisha",
            inviteCode: "ABC123"
        )

        appState.restoreSession(user: user, couple: couple)
        appState.handleSubscriptionState(isPremium: false)

        #expect(appState.route == .main)
        #expect(appState.paywallState == .none)
        #expect(appState.hasLapsedAccess)
        #expect(!appState.shouldShowMandatoryPaywall)
    }

    @Test
    @MainActor
    func initialUnlockRequirementRestoresStarterPaywallAfterRelaunch() {
        let appState = AppState()
        let user = User(id: "user-1", name: "Yusuf")
        user.requiresInitialSubscriptionUnlock = true
        let couple = Couple(
            user1ID: user.id,
            user1Name: user.name,
            user2Name: "Aisha",
            inviteCode: "ABC123"
        )

        appState.restoreSession(user: user, couple: couple)
        appState.handleSubscriptionState(isPremium: false)

        #expect(appState.paywallState == .none)
        #expect(appState.presentedPaywallEntryPoint == .starterPlan)
    }

    @Test
    @MainActor
    func seenStarterPaywallDoesNotAutoPresentAgain() {
        let appState = AppState()
        let user = User(id: "user-1", name: "Yusuf")
        user.requiresInitialSubscriptionUnlock = true
        user.hasSeenInitialSubscriptionPaywall = true
        let couple = Couple(
            user1ID: user.id,
            user1Name: user.name,
            user2Name: "Aisha",
            inviteCode: "ABC123"
        )

        appState.restoreSession(user: user, couple: couple)
        appState.handleSubscriptionState(isPremium: false)

        #expect(appState.presentedPaywallEntryPoint == nil)
    }

    @Test
    @MainActor
    func contextualPaywallPresentationTracksEntryPoint() {
        let appState = AppState()
        let user = User(id: "user-1", name: "Yusuf")
        let couple = Couple(
            user1ID: user.id,
            user1Name: user.name,
            user2Name: "Aisha",
            inviteCode: "ABC123"
        )

        appState.restoreSession(user: user, couple: couple)
        appState.presentPaywall(for: .sharedSpace)

        #expect(appState.presentedPaywallEntryPoint == .sharedSpace)
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

    @Test
    func relationshipDurationOnlyExistsWhenAnniversaryIsKnown() {
        let unknownDurationCouple = Couple(
            user1ID: "user-1",
            user1Name: "Yusuf",
            user2Name: "Aisha",
            inviteCode: "ABC123",
            anniversaryDate: nil
        )

        #expect(unknownDurationCouple.relationshipDurationDays == nil)
        #expect(unknownDurationCouple.daysTogether == 0)
    }
}

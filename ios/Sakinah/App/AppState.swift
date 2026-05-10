import SwiftUI
import Observation

enum AppRoute: Equatable {
    case onboarding
    case main
}

enum AppPaywallState: Equatable {
    case none
    case handoffAfterOnboarding
    case requiredAfterOnboarding
}

enum PairingStatus: Equatable {
    case solo
    case readyToInvite
    case invitationSent
    case invitationWaiting
    case paired
}

enum SyncStatus: Equatable {
    case idle
    case syncing
    case upToDate(Date)
    case failed(String)
}

enum AppAppearanceMode: Int, CaseIterable, Identifiable {
    case system = 0
    case light = 1
    case dark = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

@Observable
@MainActor
final class AppState {
    var route: AppRoute = .onboarding
    var currentUser: User?
    var currentCouple: Couple?
    var isSubscribed: Bool = false
    var paywallState: AppPaywallState = .none
    var requiredPaywallEntryPoint: SakinahPaywallEntryPoint = .starterPlan
    var presentedPaywallEntryPoint: SakinahPaywallEntryPoint?
    var pairingStatus: PairingStatus = .solo
    var syncStatus: SyncStatus = .idle
    var onboardingStep: OnboardingStep = .welcome
    var selectedTab: MainTab = .today
    var showPartnerInvitePrompt: Bool = false
    var pendingShareDetected: Bool = false

    func completeOnboarding(user: User, couple: Couple?) {
        self.currentUser = user
        self.currentCouple = couple
        withAnimation(SakinahAnimation.gentle) {
            self.route = .main
        }
        paywallState = .none
        if shouldAutoPresentStarterPaywall {
            presentedPaywallEntryPoint = .starterPlan
        }
        refreshPairingStatus()
    }

    var partnerName: String {
        guard let couple = currentCouple else { return "Spouse" }
        guard let currentUser else {
            return nonEmptyPartnerName(in: couple, excluding: nil)
        }

        if couple.user1ID == currentUser.id {
            return couple.user2Name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Spouse" : couple.user2Name
        }

        if couple.user2ID == currentUser.id {
            return couple.user1Name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Spouse" : couple.user1Name
        }

        return nonEmptyPartnerName(in: couple, excluding: currentUser.name)
    }

    var userName: String {
        currentUser?.name ?? "You"
    }

    var daysTogether: Int {
        currentCouple?.daysTogether ?? 0
    }

    var relationshipDurationDays: Int? {
        currentCouple?.relationshipDurationDays
    }

    var isPremium: Bool {
        isSubscribed
    }

    var hasPremiumAccess: Bool {
        isSubscribed
    }

    var shouldShowMandatoryPaywall: Bool {
        false
    }

    var shouldShowPaywallHandoff: Bool {
        false
    }

    func restoreSession(user: User?, couple: Couple?) {
        currentUser = user
        currentCouple = couple
        route = user == nil ? .onboarding : .main
        refreshRoutingState()
    }

    func handleSubscriptionState(isPremium: Bool) {
        isSubscribed = isPremium
        refreshRoutingState()
    }

    func advanceToHostedPaywall(entryPoint: SakinahPaywallEntryPoint = .starterPlan) {
        guard currentUser != nil, !hasPremiumAccess else { return }
        requiredPaywallEntryPoint = entryPoint
        presentedPaywallEntryPoint = entryPoint
        paywallState = .none
    }

    func presentPaywall(for entryPoint: SakinahPaywallEntryPoint) {
        guard currentUser != nil, !hasPremiumAccess else { return }
        presentedPaywallEntryPoint = entryPoint
    }

    func dismissPresentedPaywall() {
        presentedPaywallEntryPoint = nil
    }

    func markInitialStarterPaywallSeen() {
        currentUser?.hasSeenInitialSubscriptionPaywall = true
        currentUser?.touch()
    }

    func preparePostPurchaseExperience() {
        paywallState = .none
        presentedPaywallEntryPoint = nil
        selectedTab = .today
        showPartnerInvitePrompt = pendingShareDetected
        refreshPairingStatus()
    }

    func notePendingShareDetected() {
        pendingShareDetected = true

        if currentCouple == nil {
            pairingStatus = .invitationWaiting
        }
    }

    func markShareAttached() {
        pendingShareDetected = false
        pairingStatus = .paired
        showPartnerInvitePrompt = false
    }

    func markInviteCreated() {
        pairingStatus = .invitationSent
        showPartnerInvitePrompt = false
    }

    func markSyncStarted() {
        syncStatus = .syncing
    }

    func markSyncFinished(at date: Date = Date()) {
        syncStatus = .upToDate(date)
        refreshPairingStatus()
    }

    func markSyncFailed(_ message: String) {
        syncStatus = .failed(message)
    }

    private func refreshRoutingState() {
        route = currentUser == nil ? .onboarding : .main

        if currentUser == nil {
            paywallState = .none
            presentedPaywallEntryPoint = nil
            showPartnerInvitePrompt = false
        } else if hasPremiumAccess {
            paywallState = .none
            currentUser?.requiresInitialSubscriptionUnlock = false
            currentUser?.hasSeenInitialSubscriptionPaywall = true
        } else {
            paywallState = .none

            if shouldAutoPresentStarterPaywall, presentedPaywallEntryPoint == nil {
                presentedPaywallEntryPoint = .starterPlan
            }
        }

        refreshPairingStatus()
    }

    var hasLapsedAccess: Bool {
        currentUser != nil && !hasPremiumAccess
    }

    var currentStarterPlan: StarterPlan? {
        currentUser?.starterPlan
    }

    var shouldShowStarterPlanCard: Bool {
        hasPremiumAccess && currentUser?.shouldShowStarterPlan == true
    }

    private var shouldAutoPresentStarterPaywall: Bool {
        guard let currentUser else { return false }

        return currentUser.requiresInitialSubscriptionUnlock
            && !currentUser.hasSeenInitialSubscriptionPaywall
            && !hasPremiumAccess
    }

    private func refreshPairingStatus() {
        guard let couple = currentCouple else {
            pairingStatus = pendingShareDetected ? .invitationWaiting : .solo
            return
        }

        if !couple.user2ID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !couple.user1Name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !couple.user2Name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            pairingStatus = .paired
            return
        }

        if pendingShareDetected {
            pairingStatus = .invitationWaiting
            return
        }

        if couple.cloudShareURLString != nil {
            pairingStatus = .invitationSent
            return
        }

        pairingStatus = .readyToInvite
    }

    private func nonEmptyPartnerName(in couple: Couple, excluding currentName: String?) -> String {
        let excluded = currentName?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let candidates = [couple.user1Name, couple.user2Name]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let firstDistinct = candidates.first(where: { $0.lowercased() != excluded }) {
            return firstDistinct
        }

        return "Spouse"
    }
}

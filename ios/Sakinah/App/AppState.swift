import SwiftUI
import Observation

enum AppRoute: Equatable {
    case onboarding
    case waitingForPartner
    case main
}

@Observable
@MainActor
final class AppState {
    var route: AppRoute = .onboarding
    var currentUser: User?
    var currentCouple: Couple?
    var isSubscribed: Bool = false
    var onboardingStep: OnboardingStep = .welcome
    var selectedTab: MainTab = .today

    func completeOnboarding(user: User, couple: Couple?) {
        self.currentUser = user
        self.currentCouple = couple
        withAnimation(SakinahAnimation.gentle) {
            self.route = .main
        }
    }

    var partnerName: String {
        currentCouple?.user2Name ?? "Partner"
    }

    var userName: String {
        currentUser?.name ?? "Friend"
    }

    var daysTogether: Int {
        currentCouple?.daysTogether ?? 0
    }

    var isPremium: Bool {
        isSubscribed || SubscriptionService.shared.isPremium
    }
}

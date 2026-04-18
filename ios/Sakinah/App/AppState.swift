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

    func completeOnboarding(user: User, couple: Couple?) {
        self.currentUser = user
        self.currentCouple = couple
        withAnimation(SakinahAnimation.gentle) {
            self.route = .main
        }
    }
}

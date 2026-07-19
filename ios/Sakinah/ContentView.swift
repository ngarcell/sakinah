import SwiftUI

struct ContentView: View {
    @Environment(TrueMaxAppState.self) private var appState
    @Environment(SubscriptionService.self) private var subscriptionService

    var body: some View {
        ZStack {
            TrueMaxPageBackground()

            if appState.isBootstrapping {
                TrueMaxLoadingView(
                    title: "Preparing TrueMax",
                    detail: "Checking your access and preparing your workspace."
                )
            } else if !appState.hasCompletedOnboarding {
                TrueMaxOnboardingFlow()
                    .id(appState.onboardingRestartID)
            } else if !subscriptionService.isPremium {
                TrueMaxPaywallView(
                    showsCloseButton: false,
                    onUnlocked: {
                        appState.selectedTab = .home
                    }
                )
            } else {
                TrueMaxMainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.24), value: appState.isBootstrapping)
        .animation(.easeInOut(duration: 0.24), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.24), value: subscriptionService.isPremium)
    }
}

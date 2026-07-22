import SwiftUI

struct ContentView: View {
    @Environment(TrueMaxAppState.self) private var appState
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(TrueMaxMarketingWalkthroughController.self) private var demo
    @Environment(\.modelContext) private var modelContext
    @State private var demoError: String?

    var body: some View {
        ZStack {
            TrueMaxPageBackground()

            if appState.isBootstrapping {
                TrueMaxLoadingView(
                    title: "Preparing TrueMax",
                    detail: "Checking your access and preparing your workspace."
                )
            } else if demo.showsLauncher {
                TrueMaxMarketingLauncherView(
                    onPlay: startWalkthrough,
                    onExplore: {
                        demo.showsLauncher = false
                        appState.selectedTab = .home
                    }
                )
            } else if !appState.hasCompletedOnboarding {
                TrueMaxOnboardingFlow()
                    .id(appState.onboardingRestartID)
            } else if appState.presentsPaywall && !subscriptionService.isPremium {
                TrueMaxPaywallView(
                    showsCloseButton: true,
                    onUnlocked: {
                        appState.dismissPaywall()
                        appState.selectedTab = .home
                        demo.presentLauncher()
                    },
                    onClose: {
                        appState.dismissPaywall()
                    }
                )
            } else {
                TrueMaxMainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.24), value: appState.isBootstrapping)
        .animation(.easeInOut(duration: 0.24), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.24), value: subscriptionService.isPremium)
        .onAppear {
            TrueMaxAnalytics.shared.screen(
                appState.hasCompletedOnboarding ? "workspace" : "onboarding",
                properties: ["is_premium": subscriptionService.isPremium]
            )
        }
        .onChange(of: appState.presentsPaywall) { _, isPresented in
            TrueMaxAnalytics.shared.capture(
                isPresented ? "paywall presented" : "paywall dismissed",
                properties: ["placement": "truemax"]
            )
        }
        .onChange(of: appState.selectedTab) { _, tab in
            TrueMaxAnalytics.shared.capture("tab selected", properties: [
                "tab": tab.title
            ])
        }
        .alert("Walkthrough unavailable", isPresented: Binding(
            get: { demoError != nil },
            set: { if !$0 { demoError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(demoError ?? "Please try again.")
        }
    }

    private func startWalkthrough() {
        do {
            try TrueMaxMarketingSeed.prepare(in: modelContext)
            appState.selectedTab = .home
            demo.start()
        } catch {
            demoError = error.localizedDescription
        }
    }
}

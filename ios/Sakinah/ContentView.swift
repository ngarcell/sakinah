import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var subscriptionService = SubscriptionService.shared

    var body: some View {
        ZStack {
            SakinahColor.background.ignoresSafeArea()
            Group {
                if appState.route == .onboarding || appState.currentUser == nil {
                    OnboardingView()
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity.combined(with: .scale(scale: 0.98))
                        ))
                } else if appState.shouldShowMandatoryPaywall {
                    SakinahPaywallView(entryPoint: .generic, isMandatory: true)
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity
                        ))
                } else {
                    MainTabView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 1.02)),
                            removal: .opacity
                        ))
                }
            }
        }
        .animation(SakinahAnimation.gentle, value: appState.currentUser?.id)
        .animation(SakinahAnimation.gentle, value: appState.paywallState)
        .animation(SakinahAnimation.gentle, value: appState.pairingStatus)
        .onAppear {
            restoreSession()
        }
        .onChange(of: subscriptionService.currentTier) { _, tier in
            appState.handleSubscriptionState(isPremium: tier == .premium)
        }
    }

    private func restoreSession() {
        let userDescriptor = FetchDescriptor<User>()
        let user = (try? modelContext.fetch(userDescriptor))?.first

        let coupleDescriptor = FetchDescriptor<Couple>()
        let couple = (try? modelContext.fetch(coupleDescriptor))?.first

        appState.restoreSession(user: user, couple: couple)

        if user != nil, appState.hasPremiumAccess {
            Task {
                await CloudKitService.shared.syncIfPossible(appState: appState, context: modelContext)
            }
        }
    }
}

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
                if appState.currentUser == nil {
                    OnboardingView()
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity.combined(with: .scale(scale: 0.98))
                        ))
                } else if appState.isSubscribed || subscriptionService.isPremium {
                    MainTabView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 1.02)),
                            removal: .opacity
                        ))
                } else {
                    SakinahPaywallView(entryPoint: .generic, isMandatory: true)
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity
                        ))
                }
            }
        }
        .animation(SakinahAnimation.gentle, value: appState.currentUser?.id)
        .animation(SakinahAnimation.gentle, value: appState.isSubscribed)
        .animation(SakinahAnimation.gentle, value: subscriptionService.currentTier)
        .onAppear {
            restoreSession()
        }
    }

    private func restoreSession() {
        let userDescriptor = FetchDescriptor<User>()
        guard let user = try? modelContext.fetch(userDescriptor).first else { return }
        
        let coupleDescriptor = FetchDescriptor<Couple>()
        let couple = try? modelContext.fetch(coupleDescriptor).first
        
        appState.currentUser = user
        appState.currentCouple = couple
        appState.route = .main
    }
}

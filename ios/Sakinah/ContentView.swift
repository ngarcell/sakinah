import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            SakinahColor.background.ignoresSafeArea()
            Group {
                switch appState.route {
                case .onboarding, .waitingForPartner:
                    OnboardingView()
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .opacity.combined(with: .scale(scale: 0.98))
                        ))
                case .main:
                    MainTabView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 1.02)),
                            removal: .opacity
                        ))
                }
            }
        }
        .animation(SakinahAnimation.gentle, value: appState.route)
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

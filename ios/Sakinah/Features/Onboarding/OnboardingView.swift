import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var vm = OnboardingViewModel()

    var body: some View {
        ZStack {
            SakinahColor.background.ignoresSafeArea()
            content
                .animation(SakinahAnimation.gentle, value: vm.step)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.step {
        case .welcome:
            WelcomeScreen(vm: vm)
                .transition(screenTransition)
        case .signIn:
            SignInScreen(vm: vm)
                .transition(screenTransition)
        case .invitePartner:
            InvitePartnerScreen(vm: vm)
                .transition(screenTransition)
        case .waiting:
            WaitingForPartnerScreen(vm: vm)
                .transition(screenTransition)
        case .coupleSetup:
            CoupleSetupScreen(vm: vm)
                .transition(screenTransition)
        case .firstPrompt:
            FirstPromptScreen(vm: vm) {
                vm.finish(context: modelContext, appState: appState)
            }
            .transition(screenTransition)
        }
    }

    private var screenTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        )
    }
}

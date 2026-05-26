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
        .task {
            vm.loadDraft(context: modelContext)
        }
        .onChange(of: vm.yourName) { _, _ in vm.persist(context: modelContext) }
        .onChange(of: vm.partnerName) { _, _ in vm.persist(context: modelContext) }
        .onChange(of: vm.relationshipStage) { _, _ in vm.persist(context: modelContext) }
        .onChange(of: vm.relationshipFocus) { _, _ in vm.persist(context: modelContext) }
        .onChange(of: vm.anniversaryDate) { _, _ in vm.persist(context: modelContext) }
        .onChange(of: vm.hasAnniversary) { _, _ in vm.persist(context: modelContext) }
        .onChange(of: vm.useHijri) { _, _ in vm.persist(context: modelContext) }
        .onChange(of: vm.duaLanguage) { _, _ in vm.persist(context: modelContext) }
        .onChange(of: vm.relationshipUrgency) { _, _ in vm.persist(context: modelContext) }
        .onChange(of: vm.relationshipFriction) { _, _ in vm.persist(context: modelContext) }
        .onChange(of: vm.firstResponse) { _, _ in vm.persist(context: modelContext) }
    }

    @ViewBuilder
    private var content: some View {
        switch vm.step {
        case .welcome:
            WelcomeScreen(vm: vm)
                .transition(screenTransition)
        case .context:
            RelationshipStageScreen(vm: vm)
                .transition(screenTransition)
        case .outcome:
            OnboardingOutcomeScreen(vm: vm)
                .transition(screenTransition)
        case .relationshipStage:
            RelationshipStageScreen(vm: vm)
                .transition(screenTransition)
        case .focusGoal:
            FocusGoalScreen(vm: vm)
                .transition(screenTransition)
        case .setup:
            CoupleSetupScreen(vm: vm)
                .transition(screenTransition)
        case .clarify:
            OnboardingClarifyScreen(vm: vm)
                .transition(screenTransition)
        case .momentum:
            OnboardingMomentumScreen(vm: vm)
                .transition(screenTransition)
        case .planPreview:
            StarterPlanPreviewScreen(vm: vm)
                .transition(screenTransition)
        case .firstValue:
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

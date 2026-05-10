import SwiftData
import Testing
@testable import Sakinah

struct OnboardingDraftTests {

    @Test
    @MainActor
    func onboardingDraftResumesPersistedStepAndFields() throws {
        let context = try makeContext()
        let draft = OnboardingDraft()
        draft.step = .clarify
        draft.yourName = "Yusuf"
        draft.partnerName = "Aisha"
        draft.relationshipFocus = .spiritualRhythm
        draft.relationshipUrgency = .now
        draft.relationshipFriction = .spiritualAlignment
        draft.firstResponse = "We need a calmer shared habit."
        context.insert(draft)
        try context.save()

        let vm = OnboardingViewModel()
        vm.loadDraft(context: context)

        #expect(vm.step == .clarify)
        #expect(vm.yourName == "Yusuf")
        #expect(vm.partnerName == "Aisha")
        #expect(vm.relationshipFocus == .spiritualRhythm)
        #expect(vm.relationshipUrgency == .now)
        #expect(vm.relationshipFriction == .spiritualAlignment)
        #expect(vm.firstResponse == "We need a calmer shared habit.")
    }

    @Test
    @MainActor
    func onboardingDraftResumesFirstValuePlanAndSavedDraftAnswer() throws {
        let context = try makeContext()
        let draft = OnboardingDraft()
        draft.step = .firstValue
        draft.partnerName = "Aisha"
        draft.relationshipFocus = .communication
        draft.relationshipUrgency = .soon
        draft.relationshipFriction = .honestConversations
        draft.starterPlan = StarterPlanService.makePlan(
            partnerName: "Aisha",
            focus: .communication,
            urgency: .soon,
            friction: .honestConversations
        )
        draft.firstResponse = "I want harder things to feel easier to start."
        context.insert(draft)
        try context.save()

        let vm = OnboardingViewModel()
        vm.loadDraft(context: context)

        #expect(vm.step == .firstValue)
        #expect(vm.starterPlan != nil)
        #expect(vm.starterPlan?.firstPrompt.contains("Aisha") == true)
        #expect(vm.firstResponse == "I want harder things to feel easier to start.")
    }

    @Test
    @MainActor
    func finishCreatesUserCouplePromptAndClearsDraft() throws {
        let context = try makeContext()
        let vm = OnboardingViewModel()
        let appState = AppState()

        vm.yourName = "Yusuf"
        vm.partnerName = "Aisha"
        vm.relationshipStage = .married
        vm.relationshipFocus = .connection
        vm.relationshipUrgency = .soon
        vm.relationshipFriction = .makingTime
        vm.firstResponse = "I miss our quieter evenings."
        vm.refreshStarterPlan(context: context)
        vm.finish(context: context, appState: appState)

        let users = try context.fetch(FetchDescriptor<User>())
        let couples = try context.fetch(FetchDescriptor<Couple>())
        let responses = try context.fetch(FetchDescriptor<PromptResponse>())
        let drafts = try context.fetch(FetchDescriptor<OnboardingDraft>())

        #expect(users.count == 1)
        #expect(couples.count == 1)
        #expect(responses.count == 1)
        #expect(drafts.isEmpty)
        #expect(users.first?.starterPlan != nil)
        #expect(users.first?.requiresInitialSubscriptionUnlock == true)
        #expect(users.first?.hasSeenInitialSubscriptionPaywall == false)
        #expect(appState.paywallState == .none)
        #expect(appState.presentedPaywallEntryPoint == .starterPlan)
    }

    @MainActor
    private func makeContext() throws -> ModelContext {
        let schema = Schema([
            User.self,
            Couple.self,
            PromptResponse.self,
            OnboardingDraft.self,
        ])
        let configuration = ModelConfiguration(
            "TestStore",
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return container.mainContext
    }
}

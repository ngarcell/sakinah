import SwiftData
import Testing
@testable import Sakinah

struct OnboardingDraftTests {

    @Test
    func onboardingStepsKeepLegacyRawValuesAndUseNineStepFlowOrder() {
        #expect(OnboardingStep.welcome.rawValue == 0)
        #expect(OnboardingStep.context.rawValue == 1)
        #expect(OnboardingStep.setup.rawValue == 2)
        #expect(OnboardingStep.clarify.rawValue == 3)
        #expect(OnboardingStep.firstValue.rawValue == 4)
        #expect(OnboardingStep.totalSteps == 9)
        #expect(OnboardingStep.ordered == [
            .welcome,
            .outcome,
            .relationshipStage,
            .focusGoal,
            .clarify,
            .momentum,
            .setup,
            .planPreview,
            .firstValue
        ])
    }

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
    func legacyContextDraftResumesAtRelationshipStage() throws {
        let context = try makeContext()
        let draft = OnboardingDraft()
        draft.stepRaw = OnboardingStep.context.rawValue
        draft.relationshipStage = .longDistance
        context.insert(draft)
        try context.save()

        let vm = OnboardingViewModel()
        vm.loadDraft(context: context)

        #expect(vm.step == .relationshipStage)
        #expect(vm.relationshipStage == .longDistance)
    }

    @Test
    @MainActor
    func draftResumesNewPlanPreviewStepAndGeneratesStarterPlan() throws {
        let context = try makeContext()
        let draft = OnboardingDraft()
        draft.step = .planPreview
        draft.partnerName = "Aisha"
        draft.relationshipFocus = .communication
        draft.relationshipUrgency = .soon
        draft.relationshipFriction = .honestConversations
        context.insert(draft)
        try context.save()

        let vm = OnboardingViewModel()
        vm.loadDraft(context: context)

        #expect(vm.step == .planPreview)
        #expect(vm.starterPlan != nil)
        #expect(vm.starterPlan?.firstPrompt.contains("Aisha") == true)
    }

    @Test
    @MainActor
    func navigationUsesNineStepOrderAndBackNavigation() throws {
        let context = try makeContext()
        let vm = OnboardingViewModel()
        vm.loadDraft(context: context)

        vm.advance(to: .outcome, context: context)
        #expect(vm.step == .outcome)
        vm.advance(to: .relationshipStage, context: context)
        #expect(vm.step == .relationshipStage)
        vm.advance(to: .focusGoal, context: context)
        #expect(vm.step == .focusGoal)
        vm.advance(to: .clarify, context: context)
        #expect(vm.step == .clarify)
        vm.advance(to: .momentum, context: context)
        #expect(vm.step == .momentum)
        vm.advance(to: .setup, context: context)
        #expect(vm.step == .setup)
        vm.advance(to: .planPreview, context: context)
        #expect(vm.step == .planPreview)
        vm.advance(to: .firstValue, context: context)
        #expect(vm.step == .firstValue)

        vm.goBack(context: context)
        #expect(vm.step == .planPreview)
    }

    @Test
    @MainActor
    func starterPlanRefreshesBeforePlanPreviewAndFirstValue() throws {
        let context = try makeContext()
        let vm = OnboardingViewModel()
        vm.loadDraft(context: context)
        vm.partnerName = "Aisha"
        vm.relationshipFocus = .spiritualRhythm
        vm.relationshipUrgency = .now
        vm.relationshipFriction = .spiritualAlignment

        vm.advance(to: .planPreview, context: context)
        #expect(vm.step == .planPreview)
        #expect(vm.starterPlan != nil)
        #expect(vm.starterPlan?.recommendedPackOrLesson.contains("spiritual") == true)

        vm.starterPlan = nil
        vm.advance(to: .firstValue, context: context)
        #expect(vm.step == .firstValue)
        #expect(vm.starterPlan != nil)
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

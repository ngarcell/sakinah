import SwiftUI
import SwiftData

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case context = 1
    case setup = 2
    case clarify = 3
    case firstValue = 4
    case outcome = 5
    case relationshipStage = 6
    case focusGoal = 7
    case momentum = 8
    case planPreview = 9

    static let ordered: [OnboardingStep] = [
        .welcome,
        .outcome,
        .relationshipStage,
        .focusGoal,
        .clarify,
        .momentum,
        .setup,
        .planPreview,
        .firstValue
    ]

    static var totalSteps: Int {
        ordered.count
    }

    var normalizedForFlow: OnboardingStep {
        self == .context ? .relationshipStage : self
    }

    var flowIndex: Int {
        Self.ordered.firstIndex(of: normalizedForFlow).map { $0 + 1 } ?? 1
    }

    var progressPhrase: String {
        switch normalizedForFlow {
        case .welcome:
            return "A quiet beginning"
        case .outcome:
            return "Picture the rhythm"
        case .relationshipStage, .focusGoal, .clarify:
            return "Make it personal"
        case .momentum:
            return "Taking shape"
        case .setup:
            return "Your shared space"
        case .planPreview:
            return "First-week preview"
        case .firstValue:
            return "First answer"
        case .context:
            return "Make it personal"
        }
    }
}

@Observable
@MainActor
final class OnboardingViewModel {
    var step: OnboardingStep = .welcome
    let hasPendingShareInvitation: Bool
    private var draftIdentifier = "default"
    private var hasLoadedDraft = false

    var yourName: String = ""
    var partnerName: String = ""
    var relationshipStage: RelationshipStage = .married
    var relationshipFocus: RelationshipFocus = .connection
    var anniversaryDate: Date = Date()
    var hasAnniversary: Bool = false
    var useHijri: Bool = false
    var duaLanguage: DuaLanguage = .arabicEnglish
    var relationshipUrgency: RelationshipUrgency = .steady
    var relationshipFriction: RelationshipFriction = .makingTime

    var starterPlan: StarterPlan?
    var firstResponse: String = ""

    init() {
        hasPendingShareInvitation = CloudKitService.shared.hasPendingAcceptedShare
    }

    func loadDraft(context: ModelContext) {
        guard !hasLoadedDraft else { return }
        hasLoadedDraft = true

        let descriptor = FetchDescriptor<OnboardingDraft>()
        let draft = (try? context.fetch(descriptor))?.first ?? {
            let newDraft = OnboardingDraft(id: draftIdentifier)
            context.insert(newDraft)
            try? context.save()
            return newDraft
        }()

        draftIdentifier = draft.id
        apply(draft: draft)

        if (step == .planPreview || step == .firstValue), starterPlan == nil {
            refreshStarterPlan(context: context)
        }
    }

    func persist(context: ModelContext) {
        let descriptor = FetchDescriptor<OnboardingDraft>()
        let draft = (try? context.fetch(descriptor))?.first ?? {
            let newDraft = OnboardingDraft(id: draftIdentifier)
            context.insert(newDraft)
            return newDraft
        }()

        draft.step = step.normalizedForFlow
        draft.yourName = yourName
        draft.partnerName = partnerName
        draft.relationshipStage = relationshipStage
        draft.anniversaryDate = anniversaryDate
        draft.hasAnniversary = hasAnniversary
        draft.useHijri = useHijri
        draft.duaLanguage = duaLanguage
        draft.relationshipFocus = relationshipFocus
        draft.relationshipUrgency = relationshipUrgency
        draft.relationshipFriction = relationshipFriction
        draft.firstResponse = firstResponse
        draft.starterPlan = starterPlan
        draft.touch()

        try? context.save()
    }

    func advance(to step: OnboardingStep, context: ModelContext) {
        let targetStep = step.normalizedForFlow
        if targetStep == .planPreview || targetStep == .firstValue {
            refreshStarterPlan(context: context)
        }

        withAnimation(SakinahAnimation.gentle) {
            self.step = targetStep
        }
        persist(context: context)
    }

    func goBack(context: ModelContext) {
        let currentStep = step.normalizedForFlow
        guard let currentIndex = OnboardingStep.ordered.firstIndex(of: currentStep), currentIndex > 0 else { return }
        let previous = OnboardingStep.ordered[currentIndex - 1]
        withAnimation(SakinahAnimation.gentle) {
            step = previous
        }
        persist(context: context)
    }

    func refreshStarterPlan(context: ModelContext) {
        starterPlan = StarterPlanService.makePlan(
            partnerName: partnerName,
            focus: relationshipFocus,
            urgency: relationshipUrgency,
            friction: relationshipFriction
        )
        persist(context: context)
    }

    var canContinueFromSetup: Bool {
        !yourName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canCompleteFirstValue: Bool {
        !firstResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func finish(context: ModelContext, appState: AppState) {
        let plan = starterPlan ?? StarterPlanService.makePlan(
            partnerName: partnerName,
            focus: relationshipFocus,
            urgency: relationshipUrgency,
            friction: relationshipFriction
        )
        let inviteCode = PairingService.shared.generateInviteCode()
        let user = User(
            id: UUID().uuidString,
            name: yourName.isEmpty ? "You" : yourName,
            duaLanguagePreference: duaLanguage
        )
        user.storeStarterPlan(
            plan,
            focus: relationshipFocus,
            urgency: relationshipUrgency,
            friction: relationshipFriction
        )
        let couple = Couple(
            user1ID: user.id,
            user1Name: user.name,
            user2Name: partnerName.isEmpty ? "Spouse" : partnerName,
            inviteCode: inviteCode,
            relationshipStage: relationshipStage,
            anniversaryDate: hasAnniversary ? anniversaryDate : nil,
            useHijriCalendar: useHijri
        )
        user.coupleID = couple.id
        context.insert(user)
        context.insert(couple)

        let response = PromptResponse(
            promptID: starterPromptID,
            coupleID: couple.id,
            userID: user.id,
            responseText: firstResponse.trimmingCharacters(in: .whitespacesAndNewlines),
            isRevealed: true
        )
        context.insert(response)

        let descriptor = FetchDescriptor<OnboardingDraft>()
        if let draft = (try? context.fetch(descriptor))?.first {
            context.delete(draft)
        }

        try? context.save()
        appState.completeOnboarding(user: user, couple: couple)
    }

    private var starterPromptID: String {
        "starter.\(relationshipFocus.rawValue).\(relationshipUrgency.rawValue)"
    }

    private func apply(draft: OnboardingDraft) {
        step = draft.step.normalizedForFlow
        yourName = draft.yourName
        partnerName = draft.partnerName
        relationshipStage = draft.relationshipStage
        anniversaryDate = draft.anniversaryDate
        hasAnniversary = draft.hasAnniversary
        useHijri = draft.useHijri
        duaLanguage = draft.duaLanguage
        relationshipFocus = draft.relationshipFocus
        relationshipUrgency = draft.relationshipUrgency
        relationshipFriction = draft.relationshipFriction
        firstResponse = draft.firstResponse
        starterPlan = draft.starterPlan
    }
}

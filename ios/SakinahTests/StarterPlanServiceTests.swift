import Testing
@testable import Sakinah

struct StarterPlanServiceTests {

    @Test
    func starterPlanGenerationIsDeterministicForInputs() {
        let first = StarterPlanService.makePlan(
            partnerName: "Aisha",
            focus: .communication,
            urgency: .soon,
            friction: .honestConversations
        )
        let second = StarterPlanService.makePlan(
            partnerName: "Aisha",
            focus: .communication,
            urgency: .soon,
            friction: .honestConversations
        )

        #expect(first == second)
        #expect(first.recommendedPackOrLesson.contains("communication"))
        #expect(first.firstPrompt.contains("Aisha"))
    }

    @Test
    func starterPlanVariesByFocus() {
        let spiritual = StarterPlanService.makePlan(
            partnerName: "Aisha",
            focus: .spiritualRhythm,
            urgency: .steady,
            friction: .spiritualAlignment
        )
        let future = StarterPlanService.makePlan(
            partnerName: "Aisha",
            focus: .futurePlanning,
            urgency: .steady,
            friction: .makingTime
        )

        #expect(spiritual.headline != future.headline)
        #expect(spiritual.recommendedPackOrLesson.contains("spiritual"))
        #expect(future.recommendedPackOrLesson.contains("Our Dreams"))
    }
}

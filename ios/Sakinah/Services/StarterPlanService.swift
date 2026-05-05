import Foundation

enum StarterPlanService {
    static func makePlan(
        partnerName: String,
        focus: RelationshipFocus,
        urgency: RelationshipUrgency,
        friction: RelationshipFriction
    ) -> StarterPlan {
        let safePartnerName = partnerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "your spouse" : partnerName

        let headline: String
        switch focus {
        case .connection:
            headline = "Start with a calmer daily rhythm of care."
        case .communication:
            headline = "Make honest conversation feel easier to begin."
        case .conflictRepair:
            headline = "Create more gentleness before the next hard moment."
        case .spiritualRhythm:
            headline = "Build a quieter shared rhythm around faith."
        case .futurePlanning:
            headline = "Get more aligned on the life you are building."
        }

        let reason = reasonText(focus: focus, urgency: urgency, friction: friction)
        let firstPrompt = firstPrompt(partnerName: safePartnerName, focus: focus, friction: friction)
        let recommendation = recommendedNextStep(focus: focus)
        let action = firstWeekAction(friction: friction, urgency: urgency)

        return StarterPlan(
            headline: headline,
            reason: reason,
            firstPrompt: firstPrompt,
            recommendedPackOrLesson: recommendation,
            firstWeekAction: action
        )
    }

    private static func reasonText(
        focus: RelationshipFocus,
        urgency: RelationshipUrgency,
        friction: RelationshipFriction
    ) -> String {
        let urgencyLead: String
        switch urgency {
        case .steady:
            urgencyLead = "You are not looking for drama."
        case .soon:
            urgencyLead = "You want momentum before distance grows."
        case .now:
            urgencyLead = "Something important needs attention now."
        }

        let focusLine: String
        switch focus {
        case .connection:
            focusLine = "A smaller daily ritual can help you feel close again without forcing a big conversation."
        case .communication:
            focusLine = "A better opening question can make honesty feel safer and more natural."
        case .conflictRepair:
            focusLine = "A calmer structure can lower defensiveness before you reach the harder topics."
        case .spiritualRhythm:
            focusLine = "A shared habit can keep faith from becoming something you care about separately."
        case .futurePlanning:
            focusLine = "A clearer rhythm can turn vague hopes into a conversation you both return to."
        }

        return "\(urgencyLead) \(focusLine) The first week will stay focused on \(friction.label.lowercased())."
    }

    private static func firstPrompt(partnerName: String, focus: RelationshipFocus, friction: RelationshipFriction) -> String {
        switch (focus, friction) {
        case (.connection, .makingTime):
            return "When do you feel most at ease with \(partnerName), and what usually gets in the way of that time?"
        case (.connection, _):
            return "What is one small moment with \(partnerName) that still makes your chest feel lighter when you remember it?"
        case (.communication, .honestConversations):
            return "What is something you wish felt easier to say to \(partnerName), even if you are not ready to say it out loud yet?"
        case (.communication, _):
            return "What kind of conversation with \(partnerName) usually leaves you feeling more understood than before?"
        case (.conflictRepair, .hardTopics):
            return "When a hard topic comes up with \(partnerName), what do you most wish could stay gentle?"
        case (.conflictRepair, _):
            return "What helps you stay soft-hearted when you and \(partnerName) are not seeing something the same way?"
        case (.spiritualRhythm, .spiritualAlignment):
            return "What is one practice that helps you feel closer to Allah and more present with \(partnerName) at the same time?"
        case (.spiritualRhythm, _):
            return "What would a spiritually grounding week with \(partnerName) look like in ordinary life?"
        case (.futurePlanning, _):
            return "What part of the future with \(partnerName) feels most important to talk about with more clarity this season?"
        }
    }

    private static func recommendedNextStep(focus: RelationshipFocus) -> String {
        switch focus {
        case .connection:
            return "Recommended next step: the Intimacy & Closeness conversation pack."
        case .communication:
            return "Recommended next step: the communication lesson in Learn."
        case .conflictRepair:
            return "Recommended next step: the Difficult Conversations pack."
        case .spiritualRhythm:
            return "Recommended next step: the spiritual lesson in Learn."
        case .futurePlanning:
            return "Recommended next step: the Our Dreams conversation pack."
        }
    }

    private static func firstWeekAction(friction: RelationshipFriction, urgency: RelationshipUrgency) -> String {
        switch (friction, urgency) {
        case (.makingTime, .now):
            return "For the first week, protect ten quiet minutes before anything else asks for you."
        case (.makingTime, _):
            return "For the first week, return to one quiet check-in each day before the day runs away."
        case (.honestConversations, .now):
            return "For the first week, answer one question honestly before trying to solve anything."
        case (.honestConversations, _):
            return "For the first week, use one thoughtful question to open a conversation gently."
        case (.spiritualAlignment, _):
            return "For the first week, pair one short reflection with one shared du'a or intention."
        case (.hardTopics, .now):
            return "For the first week, stay brief, honest, and kind before stepping into the heavier subject."
        case (.hardTopics, _):
            return "For the first week, build trust with smaller truths before the harder topic arrives."
        }
    }
}

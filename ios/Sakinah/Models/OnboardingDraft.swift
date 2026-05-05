import Foundation
import SwiftData

@Model
final class OnboardingDraft {
    @Attribute(.unique) var id: String
    var stepRaw: Int
    var yourName: String
    var partnerName: String
    var relationshipStageRaw: String
    var anniversaryDate: Date
    var hasAnniversary: Bool
    var useHijri: Bool
    var duaLanguageRaw: String
    var relationshipFocusRaw: String
    var relationshipUrgencyRaw: String
    var relationshipFrictionRaw: String
    var firstResponse: String
    var starterPlanData: Data?
    var createdAt: Date
    var updatedAt: Date

    var step: OnboardingStep {
        get { OnboardingStep(rawValue: stepRaw) ?? .welcome }
        set { stepRaw = newValue.rawValue }
    }

    var relationshipStage: RelationshipStage {
        get { RelationshipStage(rawValue: relationshipStageRaw) ?? .married }
        set { relationshipStageRaw = newValue.rawValue }
    }

    var duaLanguage: DuaLanguage {
        get { DuaLanguage(rawValue: duaLanguageRaw) ?? .arabicEnglish }
        set { duaLanguageRaw = newValue.rawValue }
    }

    var relationshipFocus: RelationshipFocus {
        get { RelationshipFocus(rawValue: relationshipFocusRaw) ?? .connection }
        set { relationshipFocusRaw = newValue.rawValue }
    }

    var relationshipUrgency: RelationshipUrgency {
        get { RelationshipUrgency(rawValue: relationshipUrgencyRaw) ?? .steady }
        set { relationshipUrgencyRaw = newValue.rawValue }
    }

    var relationshipFriction: RelationshipFriction {
        get { RelationshipFriction(rawValue: relationshipFrictionRaw) ?? .makingTime }
        set { relationshipFrictionRaw = newValue.rawValue }
    }

    var starterPlan: StarterPlan? {
        get {
            guard let starterPlanData else { return nil }
            return try? JSONDecoder().decode(StarterPlan.self, from: starterPlanData)
        }
        set { starterPlanData = try? JSONEncoder().encode(newValue) }
    }

    init(id: String = "default", createdAt: Date = Date()) {
        self.id = id
        self.stepRaw = OnboardingStep.welcome.rawValue
        self.yourName = ""
        self.partnerName = ""
        self.relationshipStageRaw = RelationshipStage.married.rawValue
        self.anniversaryDate = Date()
        self.hasAnniversary = false
        self.useHijri = false
        self.duaLanguageRaw = DuaLanguage.arabicEnglish.rawValue
        self.relationshipFocusRaw = RelationshipFocus.connection.rawValue
        self.relationshipUrgencyRaw = RelationshipUrgency.steady.rawValue
        self.relationshipFrictionRaw = RelationshipFriction.makingTime.rawValue
        self.firstResponse = ""
        self.starterPlanData = nil
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    func touch(_ date: Date = Date()) {
        updatedAt = date
    }
}

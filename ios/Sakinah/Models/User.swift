import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: String
    var name: String
    var partnerID: String?
    var coupleID: String?
    var duaLanguagePreferenceRaw: String
    var notificationTime: Date
    var createdAt: Date
    var updatedAt: Date
    var subscriptionTierRaw: String
    var relationshipFocusRaw: String?
    var relationshipUrgencyRaw: String?
    var relationshipFrictionRaw: String?
    var starterPlanData: Data?
    var starterPlanCreatedAt: Date?
    var starterPlanDismissedAt: Date?
    var requiresInitialSubscriptionUnlockFlag: Bool?
    var hasSeenInitialSubscriptionPaywallFlag: Bool?

    var duaLanguagePreference: DuaLanguage {
        get { DuaLanguage(rawValue: duaLanguagePreferenceRaw) ?? .arabicEnglish }
        set { duaLanguagePreferenceRaw = newValue.rawValue }
    }

    var subscriptionTier: SubscriptionTier {
        get { SubscriptionTier(rawValue: subscriptionTierRaw) ?? .free }
        set { subscriptionTierRaw = newValue.rawValue }
    }

    var relationshipFocus: RelationshipFocus? {
        get {
            guard let relationshipFocusRaw else { return nil }
            return RelationshipFocus(rawValue: relationshipFocusRaw)
        }
        set { relationshipFocusRaw = newValue?.rawValue }
    }

    var relationshipUrgency: RelationshipUrgency? {
        get {
            guard let relationshipUrgencyRaw else { return nil }
            return RelationshipUrgency(rawValue: relationshipUrgencyRaw)
        }
        set { relationshipUrgencyRaw = newValue?.rawValue }
    }

    var relationshipFriction: RelationshipFriction? {
        get {
            guard let relationshipFrictionRaw else { return nil }
            return RelationshipFriction(rawValue: relationshipFrictionRaw)
        }
        set { relationshipFrictionRaw = newValue?.rawValue }
    }

    var starterPlan: StarterPlan? {
        get {
            guard let starterPlanData else { return nil }
            return try? JSONDecoder().decode(StarterPlan.self, from: starterPlanData)
        }
        set { starterPlanData = try? JSONEncoder().encode(newValue) }
    }

    var shouldShowStarterPlan: Bool {
        guard starterPlan != nil,
              starterPlanDismissedAt == nil,
              let starterPlanCreatedAt else { return false }

        let visibleDays = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: starterPlanCreatedAt),
            to: Calendar.current.startOfDay(for: Date())
        ).day ?? 0

        return visibleDays < 7
    }

    var requiresInitialSubscriptionUnlock: Bool {
        get { requiresInitialSubscriptionUnlockFlag ?? false }
        set { requiresInitialSubscriptionUnlockFlag = newValue }
    }

    var hasSeenInitialSubscriptionPaywall: Bool {
        get { hasSeenInitialSubscriptionPaywallFlag ?? false }
        set { hasSeenInitialSubscriptionPaywallFlag = newValue }
    }

    init(id: String, name: String, partnerID: String? = nil, coupleID: String? = nil,
         duaLanguagePreference: DuaLanguage = .arabicEnglish,
         notificationTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(),
         createdAt: Date = Date(),
         subscriptionTier: SubscriptionTier = .free) {
        self.id = id
        self.name = name
        self.partnerID = partnerID
        self.coupleID = coupleID
        self.duaLanguagePreferenceRaw = duaLanguagePreference.rawValue
        self.notificationTime = notificationTime
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.subscriptionTierRaw = subscriptionTier.rawValue
        self.relationshipFocusRaw = nil
        self.relationshipUrgencyRaw = nil
        self.relationshipFrictionRaw = nil
        self.starterPlanData = nil
        self.starterPlanCreatedAt = nil
        self.starterPlanDismissedAt = nil
        self.requiresInitialSubscriptionUnlockFlag = false
        self.hasSeenInitialSubscriptionPaywallFlag = false
    }

    func touch(_ date: Date = Date()) {
        updatedAt = date
    }

    func storeStarterPlan(
        _ plan: StarterPlan,
        focus: RelationshipFocus,
        urgency: RelationshipUrgency,
        friction: RelationshipFriction,
        date: Date = Date()
    ) {
        starterPlan = plan
        relationshipFocus = focus
        relationshipUrgency = urgency
        relationshipFriction = friction
        starterPlanCreatedAt = date
        starterPlanDismissedAt = nil
        requiresInitialSubscriptionUnlock = true
        hasSeenInitialSubscriptionPaywall = false
        touch(date)
    }

    func dismissStarterPlan(_ date: Date = Date()) {
        starterPlanDismissedAt = date
        touch(date)
    }
}

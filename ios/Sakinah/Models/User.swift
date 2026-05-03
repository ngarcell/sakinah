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

    var duaLanguagePreference: DuaLanguage {
        get { DuaLanguage(rawValue: duaLanguagePreferenceRaw) ?? .arabicEnglish }
        set { duaLanguagePreferenceRaw = newValue.rawValue }
    }

    var subscriptionTier: SubscriptionTier {
        get { SubscriptionTier(rawValue: subscriptionTierRaw) ?? .free }
        set { subscriptionTierRaw = newValue.rawValue }
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
    }

    func touch(_ date: Date = Date()) {
        updatedAt = date
    }
}

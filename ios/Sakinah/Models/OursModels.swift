import Foundation
import SwiftData

@Model
final class Lesson {
    @Attribute(.unique) var id: String
    var isCompleted: Bool
    var completedAt: Date?

    init(id: String, isCompleted: Bool = false, completedAt: Date? = nil) {
        self.id = id
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}

@Model
final class JournalEntry {
    @Attribute(.unique) var id: String
    var coupleID: String
    var userID: String
    var authorName: String
    var content: String
    var isShared: Bool
    var createdAt: Date

    init(id: String = UUID().uuidString, coupleID: String, userID: String, authorName: String, content: String, isShared: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.coupleID = coupleID
        self.userID = userID
        self.authorName = authorName
        self.content = content
        self.isShared = isShared
        self.createdAt = createdAt
    }
}

@Model
final class LoveLetter {
    @Attribute(.unique) var id: String
    var coupleID: String
    var senderID: String
    var senderName: String
    var recipientName: String
    var title: String
    var content: String
    var deliveryDate: Date
    var isDelivered: Bool
    var isRead: Bool
    var createdAt: Date

    init(id: String = UUID().uuidString, coupleID: String, senderID: String, senderName: String, recipientName: String, title: String = "", content: String, deliveryDate: Date, isDelivered: Bool = false, isRead: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.coupleID = coupleID
        self.senderID = senderID
        self.senderName = senderName
        self.recipientName = recipientName
        self.title = title
        self.content = content
        self.deliveryDate = deliveryDate
        self.isDelivered = isDelivered
        self.isRead = isRead
        self.createdAt = createdAt
    }
}

@Model
final class SharedGoal {
    @Attribute(.unique) var id: String
    var coupleID: String
    var title: String
    var targetCount: Int
    var currentCount: Int
    var categoryRaw: String
    var deadline: Date
    var isCompleted: Bool
    var createdAt: Date

    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return Double(currentCount) / Double(targetCount)
    }

    var category: GoalCategory {
        get { GoalCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(id: String = UUID().uuidString, coupleID: String, title: String, targetCount: Int, currentCount: Int = 0, category: GoalCategory = .other, deadline: Date, isCompleted: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.coupleID = coupleID
        self.title = title
        self.targetCount = targetCount
        self.currentCount = currentCount
        self.categoryRaw = category.rawValue
        self.deadline = deadline
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

nonisolated enum GoalCategory: String, Codable, CaseIterable, Sendable {
    case spiritual, qualityTime, health, financial, other

    var label: String {
        switch self {
        case .spiritual: return "Spiritual 🤲"
        case .qualityTime: return "Quality Time 💑"
        case .health: return "Health 🌿"
        case .financial: return "Financial 💰"
        case .other: return "Other ✨"
        }
    }
}

@Model
final class WishItem {
    @Attribute(.unique) var id: String
    var coupleID: String
    var userID: String
    var text: String
    var note: String?
    var link: String?
    var createdAt: Date

    init(id: String = UUID().uuidString, coupleID: String, userID: String, text: String, note: String? = nil, link: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.coupleID = coupleID
        self.userID = userID
        self.text = text
        self.note = note
        self.link = link
        self.createdAt = createdAt
    }
}

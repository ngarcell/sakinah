import Foundation

nonisolated enum DuaLanguage: String, Codable, CaseIterable, Sendable {
    case arabicEnglish
    case arabicTransliteration
    case all

    var label: String {
        switch self {
        case .arabicEnglish: return "Arabic + English"
        case .arabicTransliteration: return "Arabic + Transliteration"
        case .all: return "All three"
        }
    }
}

nonisolated enum SubscriptionTier: String, Codable, Sendable {
    case free, premium
}

nonisolated enum RelationshipStage: String, Codable, CaseIterable, Sendable {
    case engaged, married, longDistance

    var label: String {
        switch self {
        case .engaged: return "Engaged"
        case .married: return "Married"
        case .longDistance: return "Long Distance"
        }
    }

    var emoji: String {
        switch self {
        case .engaged: return "💍"
        case .married: return "🤍"
        case .longDistance: return "🌍"
        }
    }
}

nonisolated enum PromptCategory: String, Codable, CaseIterable, Sendable {
    case gratitude, dreams, memories, faith, intimacy, fun

    var label: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .gratitude: return "heart.fill"
        case .dreams: return "sparkles"
        case .memories: return "photo.stack.fill"
        case .faith: return "moon.stars.fill"
        case .intimacy: return "bubble.left.and.bubble.right.fill"
        case .fun: return "face.smiling.fill"
        }
    }
}

nonisolated enum Mood: Int, Codable, CaseIterable, Sendable {
    case verySad = 1, sad, neutral, good, great

    var emoji: String {
        switch self {
        case .verySad: return "😢"
        case .sad: return "😕"
        case .neutral: return "😌"
        case .good: return "😊"
        case .great: return "🥰"
        }
    }
}

nonisolated struct GardenState: Codable, Sendable {
    var streakDays: Int = 0
    var plantsGrown: Int = 0
    var lastWatered: Date?
}

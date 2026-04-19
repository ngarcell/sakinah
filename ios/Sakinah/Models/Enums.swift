import Foundation
import SwiftUI

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

    var displayLabel: String {
        switch self {
        case .gratitude: return "Gratitude ✨"
        case .dreams: return "Dreams 💭"
        case .memories: return "Memories 📸"
        case .faith: return "Faith 🤲"
        case .intimacy: return "Connection 💞"
        case .fun: return "Fun 😄"
        }
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

    @MainActor
    var badgeColor: Color {
        switch self {
        case .gratitude: return SakinahColor.accent
        case .dreams: return SakinahColor.primary
        case .memories: return SakinahColor.success
        case .faith: return SakinahColor.accent
        case .intimacy: return SakinahColor.primary
        case .fun: return SakinahColor.success
        }
    }
}

nonisolated enum Mood: Int, Codable, CaseIterable, Sendable {
    case tough = 1, low, okay, good, great

    var emoji: String {
        switch self {
        case .great: return "😊"
        case .good: return "🙂"
        case .okay: return "😐"
        case .low: return "😔"
        case .tough: return "😢"
        }
    }

    var label: String {
        switch self {
        case .great: return "Great"
        case .good: return "Good"
        case .okay: return "Okay"
        case .low: return "Low"
        case .tough: return "Tough"
        }
    }
}

nonisolated enum GardenDimension: String, Codable, CaseIterable, Sendable {
    case communication
    case qualityTime
    case spiritualConnection
    case emotionalSafety
    case growth

    var label: String {
        switch self {
        case .communication: return "Communication"
        case .qualityTime: return "Quality Time"
        case .spiritualConnection: return "Spiritual"
        case .emotionalSafety: return "Emotional Safety"
        case .growth: return "Growth"
        }
    }

    var icon: String {
        switch self {
        case .communication: return "bubble.left.and.bubble.right.fill"
        case .qualityTime: return "clock.fill"
        case .spiritualConnection: return "star.fill"
        case .emotionalSafety: return "heart.fill"
        case .growth: return "leaf.fill"
        }
    }

    var plantEmoji: String {
        switch self {
        case .communication: return "🌱"
        case .qualityTime: return "🌿"
        case .spiritualConnection: return "⭐"
        case .emotionalSafety: return "🌸"
        case .growth: return "🌳"
        }
    }

    var reflectionQuestion: String {
        switch self {
        case .communication: return "I felt heard by my partner this week"
        case .qualityTime: return "We made quality time for each other"
        case .spiritualConnection: return "We connected spiritually this week"
        case .emotionalSafety: return "I felt emotionally safe and supported"
        case .growth: return "We grew or learned something together"
        }
    }
}

nonisolated struct GardenState: Codable, Sendable {
    var communication: Double = 2.0
    var qualityTime: Double = 2.0
    var spiritualConnection: Double = 2.0
    var emotionalSafety: Double = 2.0
    var growth: Double = 2.0
    var lastUpdated: Date = Date()

    func level(for dimension: GardenDimension) -> Double {
        switch dimension {
        case .communication: return communication
        case .qualityTime: return qualityTime
        case .spiritualConnection: return spiritualConnection
        case .emotionalSafety: return emotionalSafety
        case .growth: return growth
        }
    }

    mutating func setLevel(_ value: Double, for dimension: GardenDimension) {
        let clamped = max(1.0, min(5.0, value))
        switch dimension {
        case .communication: communication = clamped
        case .qualityTime: qualityTime = clamped
        case .spiritualConnection: spiritualConnection = clamped
        case .emotionalSafety: emotionalSafety = clamped
        case .growth: growth = clamped
        }
        lastUpdated = Date()
    }

    var averageLevel: Double {
        (communication + qualityTime + spiritualConnection + emotionalSafety + growth) / 5.0
    }

    mutating func applyDecay(daysSinceLastUpdate: Int) {
        let weeksInactive = Double(daysSinceLastUpdate) / 7.0
        let decayAmount = weeksInactive * 0.5
        guard decayAmount > 0 else { return }
        for dim in GardenDimension.allCases {
            let current = level(for: dim)
            setLevel(current - decayAmount, for: dim)
        }
    }

    mutating func applyDailyEngagementBoost() {
        communication = min(5.0, communication + 0.05)
        emotionalSafety = min(5.0, emotionalSafety + 0.05)
    }

    mutating func applyReflectionScores(_ scores: [GardenDimension: Int]) {
        for (dim, score) in scores {
            let current = level(for: dim)
            let target = Double(score)
            let newLevel = current + (target - current) * 0.4
            setLevel(newLevel, for: dim)
        }
    }
}

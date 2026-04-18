import Foundation

@MainActor
final class ContentService {
    static let shared = ContentService()
    private init() {}

    private let seededPrompts: [(String, PromptCategory)] = [
        ("What's one thing about your partner that made you smile this week?", .gratitude),
        ("What's a dream you've been carrying that you haven't shared yet?", .dreams),
        ("Describe the moment you knew this was love.", .memories),
        ("What's a du'a you've been making for us lately?", .faith),
        ("What's one small act that makes you feel most loved?", .intimacy),
        ("If we had a free afternoon tomorrow, what would you want to do?", .fun),
        ("When did you feel closest to Allah together this week?", .faith),
        ("What's something you appreciate about our journey so far?", .gratitude),
    ]

    func firstPrompt(partnerName: String) -> (text: String, category: PromptCategory) {
        let personalised = "What's one thing about \(partnerName) that made you smile this week?"
        return (personalised, .gratitude)
    }

    func todaysPrompt() -> (text: String, category: PromptCategory) {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let idx = day % seededPrompts.count
        return seededPrompts[idx]
    }
}

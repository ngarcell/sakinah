import Foundation

struct LessonData: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let category: String
    let readTimeMinutes: Int
    let sections: [LessonSection]
    let tryThis: TryThisAction
    let isPremium: Bool
}

struct LessonSection: Codable, Sendable, Identifiable {
    var id: String { (heading ?? "") + type }
    let type: String // "text" or "hadith"
    var heading: String?
    var body: String?
    var arabic: String?
    var transliteration: String?
    var translation: String?
    var source: String?
}

struct TryThisAction: Codable, Sendable {
    let description: String
    let category: String
}

struct ConversationPack: Identifiable {
    let id: String
    let name: String
    let icon: String
    let promptCount: Int
    let gradientStart: UInt32
    let gradientEnd: UInt32
    let prompts: [String]

    static let allPacks: [ConversationPack] = [
        ConversationPack(id: "baby", name: "Before Baby", icon: "figure.and.child.holdinghands", promptCount: 20,
            gradientStart: 0xFDE68A, gradientEnd: 0xF59E0B, prompts: [
                "What kind of parent do you imagine yourself being?",
                "What value from your upbringing do you most want to pass on?",
                "How do you think a baby would change our daily routine?",
                "What's your biggest fear about becoming a parent?",
                "What's one parenting decision we should agree on early?",
                "How will we balance childcare responsibilities?",
                "What family traditions do you want to create?",
                "How do you feel about our parents' involvement?",
                "What's your dream nursery like?",
                "How will we keep our relationship strong with a baby?",
                "What's your stance on screen time for kids?",
                "How should we handle disagreements about parenting?",
                "What Islamic values are most important to teach first?",
                "How do you feel about our financial readiness?",
                "What support system do we have in place?",
                "How will we handle sleep deprivation as a team?",
                "What's one thing your parents did right that you want to replicate?",
                "How do you envision weekends as a family?",
                "What name meanings are important to you?",
                "What does a 'good childhood' mean to you?"
            ]),
        ConversationPack(id: "money", name: "Money & Us", icon: "banknote", promptCount: 20,
            gradientStart: 0x34D399, gradientEnd: 0x059669, prompts: [
                "What's your earliest memory about money?",
                "How did your family handle finances growing up?",
                "What's one financial goal you'd love us to achieve this year?",
                "How do you feel about our current saving habits?",
                "What's a purchase you've been wanting but haven't mentioned?",
                "How should we handle unexpected expenses?",
                "What's your comfort level with debt?",
                "Should we have joint accounts, separate, or both?",
                "What does financial security mean to you?",
                "How do you feel about charitable giving and sadaqah?",
                "What's one money habit you'd like to change?",
                "How should we make big purchase decisions?",
                "What's your dream home like?",
                "How do you feel about investing?",
                "What financial legacy do you want to leave?",
                "How should we budget for vacations?",
                "What's your relationship with impulse spending?",
                "How do you feel about lending money to family?",
                "What's one financial worry you haven't shared?",
                "How can we better support each other financially?"
            ]),
        ConversationPack(id: "dreams", name: "Our Dreams", icon: "sparkles", promptCount: 20,
            gradientStart: 0x818CF8, gradientEnd: 0x6366F1, prompts: [
                "Where do you see us in 10 years?",
                "What's a dream you've never told anyone?",
                "If money was no object, what would our life look like?",
                "What's one place you absolutely must visit together?",
                "What skill would you love to learn together?",
                "What does your ideal retirement look like?",
                "If you could change one thing about our life, what would it be?",
                "What's a project you'd love to start together?",
                "What does success mean to you?",
                "What's a cause you're passionate about?",
                "If we could live anywhere for a year, where would you choose?",
                "What's something you want to accomplish before 40?",
                "What does your dream weekend look like?",
                "What business would you start if you could?",
                "What's one tradition you want to start?",
                "How do you want to grow spiritually?",
                "What does community mean to you?",
                "What legacy do you want to build together?",
                "What's something adventurous you want to try?",
                "What does 'growing old together' look like to you?"
            ]),
        ConversationPack(id: "difficult", name: "Difficult Conversations", icon: "waveform", promptCount: 20,
            gradientStart: 0x67E8F9, gradientEnd: 0x0891B2, prompts: [
                "What's something I do that unintentionally hurts you?",
                "How do you feel about how we handle conflict?",
                "What's a boundary you need me to respect better?",
                "When you're upset, what's the best way to approach you?",
                "Is there something you've been holding back?",
                "How do you feel about our in-law relationships?",
                "What's one way I could show up better for you?",
                "Do you feel we divide household responsibilities fairly?",
                "How do you feel about our intimacy?",
                "What's something from our past that still affects you?",
                "How do you handle stress, and how can I help?",
                "Do you feel heard in our relationship?",
                "What's one compromise that's been hard for you?",
                "How do you feel about our social life as a couple?",
                "Is there a family dynamic we need to address?",
                "What do you need more of from me?",
                "How do you feel about how we make decisions?",
                "What's something you'd like to forgive and move past?",
                "How can we argue more constructively?",
                "What does healing look like for us?"
            ]),
        ConversationPack(id: "intimacy", name: "Intimacy & Closeness", icon: "heart.circle", promptCount: 20,
            gradientStart: 0xFDA4AF, gradientEnd: 0xE11D48, prompts: [
                "What makes you feel most connected to me?",
                "What's your favorite way to spend time together?",
                "When do you feel most attracted to me?",
                "What's a romantic gesture that would mean a lot to you?",
                "How do you like to be comforted when you're sad?",
                "What's one thing I do that always makes you smile?",
                "How do you feel about our quality time together?",
                "What's a date night you'd love to have?",
                "What makes you feel safe with me?",
                "How do you prefer to show and receive affection?",
                "What's one thing we used to do that you miss?",
                "What's something new you'd like to try together?",
                "When do you feel closest to me?",
                "What does romance mean to you at this stage?",
                "How can we create more moments of closeness?",
                "What's your idea of a perfect evening together?",
                "What's something small that makes a big difference?",
                "How do you feel about our daily check-ins?",
                "What's one way we've grown closer recently?",
                "What does being 'home' with me feel like?"
            ])
    ]
}

@MainActor
final class LessonService {
    static let shared = LessonService()
    private(set) var lessons: [LessonData] = []

    private init() { loadLessons() }

    private func loadLessons() {
        guard let url = Bundle.main.url(forResource: "Lessons", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            lessons = []
            return
        }
        lessons = (try? JSONDecoder().decode([LessonData].self, from: data)) ?? []
    }

    func currentWeekLesson() -> LessonData? {
        guard !lessons.isEmpty else { return lessons.first }
        let weekOfYear = Calendar.current.component(.weekOfYear, from: Date())
        let index = weekOfYear % lessons.count
        return lessons[index]
    }

    func completedLessons(from completed: [Lesson]) -> [LessonData] {
        let completedIDs = Set(completed.map(\.id))
        return lessons.filter { completedIDs.contains($0.id) }
    }
}

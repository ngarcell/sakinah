import Foundation

struct PromptData: Codable, Sendable {
    let id: String
    let text: String
    let category: String
    let tags: [String]
    let minRelationshipDays: Int
}

struct DuaData: Codable, Sendable {
    let id: String
    let arabic: String
    let transliteration: String
    let translation: String
    let source: String
    let audioFile: String
    let category: String
}

@MainActor
final class ContentService {
    static let shared = ContentService()

    private var prompts: [PromptData] = []
    private var duas: [DuaData] = []
    private var lastCheckedDate: Date = Date()

    private init() {
        loadPrompts()
        loadDuas()
    }

    // MARK: - Loading

    private func loadPrompts() {
        guard let url = Bundle.main.url(forResource: "Prompts", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            prompts = fallbackPrompts
            return
        }
        prompts = (try? JSONDecoder().decode([PromptData].self, from: data)) ?? fallbackPrompts
    }

    private func loadDuas() {
        guard let url = Bundle.main.url(forResource: "Duas", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            duas = fallbackDuas
            return
        }
        duas = (try? JSONDecoder().decode([DuaData].self, from: data)) ?? fallbackDuas
    }

    // MARK: - Daily Selection (Deterministic)

    func todaysPrompt(coupleID: String = "", partnerName: String = "your partner", relationshipDays: Int = 0) -> (id: String, text: String, category: PromptCategory) {
        let eligible = prompts.filter { $0.minRelationshipDays <= relationshipDays }
        guard !eligible.isEmpty else {
            let p = prompts.first ?? fallbackPrompts[0]
            return (p.id, resolveTemplate(p.text, partnerName: partnerName), PromptCategory(rawValue: p.category) ?? .gratitude)
        }

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let seed = deterministicHash(coupleID: coupleID, day: dayOfYear)
        let index = abs(seed) % eligible.count
        let prompt = eligible[index]
        let category = PromptCategory(rawValue: prompt.category) ?? .gratitude
        let text = resolveTemplate(prompt.text, partnerName: partnerName)
        return (prompt.id, text, category)
    }

    func todaysDua(coupleID: String = "") -> DuaData {
        guard !duas.isEmpty else { return fallbackDuas[0] }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let seed = deterministicHash(coupleID: coupleID, day: dayOfYear)
        let index = abs(seed) % duas.count
        return duas[index]
    }

    func firstPrompt(partnerName: String) -> (id: String, text: String, category: PromptCategory) {
        let personalised = "What's one thing about \(partnerName) that made you smile this week?"
        return ("first_prompt", personalised, .gratitude)
    }

    // MARK: - Helpers

    private func resolveTemplate(_ text: String, partnerName: String) -> String {
        text.replacingOccurrences(of: "{partnerName}", with: partnerName)
    }

    private func deterministicHash(coupleID: String, day: Int) -> Int {
        var hasher = Hasher()
        hasher.combine(coupleID)
        hasher.combine(day)
        return abs(hasher.finalize())
    }

    // MARK: - Date Rollover

    func checkDateRollover() {
        let cal = Calendar.current
        if !cal.isDate(lastCheckedDate, inSameDayAs: Date()) {
            lastCheckedDate = Date()
            // Content will be re-fetched with new date next time todaysPrompt/todaysDua is called
        }
    }

    // MARK: - Fallbacks

    private let fallbackPrompts: [PromptData] = [
        PromptData(id: "fb_001", text: "What's one thing about {partnerName} that made you smile this week?", category: "gratitude", tags: ["beginner"], minRelationshipDays: 0),
        PromptData(id: "fb_002", text: "What's a dream you've been carrying that you haven't shared yet?", category: "dreams", tags: ["deep"], minRelationshipDays: 0),
        PromptData(id: "fb_003", text: "What's a du'a you've been making for {partnerName} lately?", category: "faith", tags: ["beginner"], minRelationshipDays: 0),
        PromptData(id: "fb_004", text: "What's one small act that makes you feel most loved?", category: "intimacy", tags: ["beginner"], minRelationshipDays: 0),
        PromptData(id: "fb_005", text: "If we had a free afternoon tomorrow, what would you want to do?", category: "fun", tags: ["light"], minRelationshipDays: 0),
        PromptData(id: "fb_006", text: "Describe the moment you knew this was love.", category: "memories", tags: ["deep"], minRelationshipDays: 0),
        PromptData(id: "fb_007", text: "What's something you appreciate about our journey so far?", category: "gratitude", tags: ["reflective"], minRelationshipDays: 0),
        PromptData(id: "fb_008", text: "When did you feel closest to Allah together this week?", category: "faith", tags: ["spiritual"], minRelationshipDays: 0),
    ]

    private let fallbackDuas: [DuaData] = [
        DuaData(id: "fb_dua_001",
                arabic: "رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ",
                transliteration: "Rabbana hab lana min azwajina wa dhurriyyatina qurrata a'yun",
                translation: "Our Lord, grant us from among our spouses and offspring comfort to our eyes",
                source: "Quran 25:74",
                audioFile: "dua_001.mp3",
                category: "family"),
        DuaData(id: "fb_dua_002",
                arabic: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",
                transliteration: "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar",
                translation: "Our Lord, give us in this world that which is good and in the Hereafter that which is good, and protect us from the punishment of the Fire.",
                source: "Quran 2:201",
                audioFile: "dua_002.mp3",
                category: "general"),
    ]
}

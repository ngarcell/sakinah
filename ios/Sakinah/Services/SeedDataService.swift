import Foundation
import SwiftData

/// Populates the app with realistic demo data for App Store screenshots.
@MainActor
final class SeedDataService {
    static let shared = SeedDataService()
    private init() {}

    func seed(context: ModelContext, appState: AppState) {
        purgeAll(context: context, appState: appState, resetRoute: false)

        // MARK: - Users & Couple
        let user = User(
            id: "demo-user-yusuf",
            name: "Yusuf",
            partnerID: "demo-user-aisha",
            coupleID: "demo-couple-001",
            duaLanguagePreference: .all,
            notificationTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
        )

        let couple = Couple(
            id: "demo-couple-001",
            user1ID: "demo-user-yusuf",
            user2ID: "demo-user-aisha",
            user1Name: "Yusuf",
            user2Name: "Aisha",
            inviteCode: "DEMO42",
            relationshipStage: .married,
            anniversaryDate: Calendar.current.date(from: DateComponents(year: 2021, month: 9, day: 14)),
            useHijriCalendar: false,
            createdAt: Calendar.current.date(byAdding: .day, value: -187, to: Date()) ?? Date()
        )

        // Garden — healthy mid-bloom state for screenshots
        var garden = GardenState()
        garden.setLevel(4.2, for: .communication)
        garden.setLevel(3.8, for: .qualityTime)
        garden.setLevel(4.5, for: .spiritualConnection)
        garden.setLevel(3.5, for: .emotionalSafety)
        garden.setLevel(4.0, for: .growth)
        couple.gardenState = garden

        context.insert(user)
        context.insert(couple)

        // MARK: - Check-ins (last 7 days)
        let moods: [Mood] = [.great, .good, .good, .okay, .great, .great, .good]
        for (i, mood) in moods.enumerated() {
            let checkIn = CheckIn(
                coupleID: couple.id,
                userID: user.id,
                mood: mood,
                note: i == 0 ? "Alhamdulillah, feeling really connected today 🤍" : nil,
                date: Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            )
            context.insert(checkIn)
        }

        // MARK: - Prompt Response (revealed)
        let response = PromptResponse(
            promptID: "demo-prompt-001",
            coupleID: couple.id,
            userID: user.id,
            responseText: "The way she always remembers how I take my tea, even when she's tired. It's such a small thing but it means everything. 🍵",
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            isRevealed: true
        )
        context.insert(response)

        // MARK: - Weekly Reflections (correct field names)
        let reflection = WeeklyReflection(
            coupleID: couple.id,
            userID: user.id,
            weekStartDate: Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date(),
            communicationScore: 4,
            qualityTimeScore: 4,
            spiritualConnectionScore: 5,
            emotionalSafetyScore: 3,
            growthScore: 4,
            isSharedWithPartner: true
        )
        context.insert(reflection)

        // MARK: - Memories (caption field, no emoji/title)
        let memoryCaptions: [(caption: String, daysAgo: Int)] = [
            ("First anniversary trip to Istanbul — saw the Blue Mosque at dawn 🕌", 60),
            ("Movie night blanket fort — silly cat documentary 🎬", 14),
            ("Eid celebration with family. Aisha's mum's biryani 🌙", 45),
            ("Sunday morning walk. Found our little coffee spot ☕", 7),
        ]
        for m in memoryCaptions {
            let memory = Memory(
                coupleID: couple.id,
                caption: m.caption,
                date: Calendar.current.date(byAdding: .day, value: -m.daysAgo, to: Date()) ?? Date()
            )
            context.insert(memory)
        }

        // MARK: - Journal Entries (content + userID fields)
        let journalEntries: [(content: String, userID: String, daysAgo: Int)] = [
            ("Feeling so grateful for this quiet evening together. Made du'a side by side after Isha — one of those moments I want to hold onto forever.", "demo-user-yusuf", 2),
            ("I was having a rough day at work and you somehow just knew. Thank you for the tea and the silence. That was exactly what I needed. 💙", "demo-user-aisha", 1),
            ("We talked about the future today — kids, where we want to live, all of it. I love how we dream the same dreams.", "demo-user-yusuf", 5),
        ]
        for entry in journalEntries {
            let je = JournalEntry(
                coupleID: couple.id,
                userID: entry.userID,
                authorName: entry.userID == "demo-user-yusuf" ? "Yusuf" : "Aisha",
                content: entry.content,
                isShared: true,
                createdAt: Calendar.current.date(byAdding: .day, value: -entry.daysAgo, to: Date()) ?? Date()
            )
            context.insert(je)
        }

        // MARK: - Love Letters (correct field names: senderID, recipientName, content, deliveryDate)
        let letter1 = LoveLetter(
            coupleID: couple.id,
            senderID: user.id,
            senderName: "Yusuf",
            recipientName: "Aisha",
            title: "For you, on a quiet morning",
            content: "I wrote this at Fajr time because something about the stillness of that hour makes me think of you most clearly. You are my sukoon, my sakinah. May Allah bless what we have and keep growing it. I love you more than yesterday, and less than tomorrow.\n\nYour Yusuf 🤍",
            deliveryDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
            isDelivered: false,
            isRead: false,
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        )
        let letter2 = LoveLetter(
            coupleID: couple.id,
            senderID: "demo-user-aisha",
            senderName: "Aisha",
            recipientName: "Yusuf",
            title: "Six months in ✨",
            content: "Half a year of mornings with you. Half a year of bad jokes and really good food. Half a year of growing in deen together. Alhamdulillah for you, Yusuf. Here's to every year after this one.\n\nAll my love, Aisha 🌙",
            deliveryDate: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
            isDelivered: true,
            isRead: true,
            createdAt: Calendar.current.date(byAdding: .day, value: -32, to: Date()) ?? Date()
        )
        context.insert(letter1)
        context.insert(letter2)

        // MARK: - Shared Goals (no creatorID field, uses deadline)
        let goals: [(title: String, category: GoalCategory, target: Int, current: Int, isCompleted: Bool)] = [
            ("Read Surah Al-Kahf together every Friday", .spiritual, 10, 7, false),
            ("Plan a weekend trip together", .qualityTime, 1, 0, false),
            ("Cook a new recipe every two weeks", .other, 6, 6, true),
            ("30-day morning walk challenge", .health, 30, 30, true),
            ("Save for Umrah fund", .financial, 100, 38, false),
        ]
        for g in goals {
            let goal = SharedGoal(
                coupleID: couple.id,
                title: g.title,
                targetCount: g.target,
                currentCount: g.current,
                category: g.category,
                deadline: Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date(),
                isCompleted: g.isCompleted,
                createdAt: Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? Date()
            )
            context.insert(goal)
        }

        // MARK: - Wishlists (text field, not title)
        let myWishes: [(text: String, note: String)] = [
            ("Linen bedsheets set", "The oat-coloured ones from that little homeware shop"),
            ("Weekend in Cappadocia", "Hot air balloon, cave hotel — bucket list ✈️"),
            ("Arabic calligraphy class", "Something we can do together on weekends"),
        ]
        let partnerWishes: [(text: String, note: String)] = [
            ("New tea collection", "She's been wanting to try proper loose-leaf oolong"),
            ("The Comfort of Distance (book)", "Fatima Bhutto — she's had it wishlisted for months"),
        ]
        for w in myWishes {
            context.insert(WishItem(coupleID: couple.id, userID: user.id, text: w.text, note: w.note))
        }
        for w in partnerWishes {
            context.insert(WishItem(coupleID: couple.id, userID: "demo-user-aisha", text: w.text, note: w.note))
        }

        // MARK: - Completed lesson
        context.insert(Lesson(id: "lesson-001", isCompleted: true, completedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())))

        try? context.save()
        appState.completeOnboarding(user: user, couple: couple)
    }

    /// Wipe all SwiftData records and optionally reset to onboarding.
    func purgeAll(context: ModelContext, appState: AppState, resetRoute: Bool = true) {
        try? context.delete(model: User.self)
        try? context.delete(model: Couple.self)
        try? context.delete(model: CheckIn.self)
        try? context.delete(model: PromptResponse.self)
        try? context.delete(model: DailyPrompt.self)
        try? context.delete(model: WeeklyReflection.self)
        try? context.delete(model: Memory.self)
        try? context.delete(model: JournalEntry.self)
        try? context.delete(model: LoveLetter.self)
        try? context.delete(model: SharedGoal.self)
        try? context.delete(model: WishItem.self)
        try? context.delete(model: Lesson.self)
        try? context.save()

        if resetRoute {
            appState.currentUser = nil
            appState.currentCouple = nil
            appState.route = .onboarding
        }
    }
}

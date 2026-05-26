#if DEBUG
import Foundation
import SwiftData

@MainActor
enum DemoDataSeeder {
    private static let demoUserID = "demo-user-yusuf"
    private static let demoPartnerID = "demo-user-aisha"
    private static let demoCoupleID = "demo-couple-yusuf-aisha"

    @discardableResult
    static func load(context: ModelContext, appState: AppState) -> Bool {
        do {
            try removeExistingDemoData(context: context)

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let anniversaryDate = calendar.date(byAdding: .day, value: -1280, to: today) ?? today
            let createdAt = calendar.date(byAdding: .day, value: -30, to: today) ?? today

            let user = User(
                id: demoUserID,
                name: "Yusuf",
                partnerID: demoPartnerID,
                coupleID: demoCoupleID,
                duaLanguagePreference: .all,
                createdAt: createdAt,
                subscriptionTier: .premium
            )
            let starterPlan = StarterPlanService.makePlan(
                partnerName: "Aisha",
                focus: .connection,
                urgency: .steady,
                friction: .makingTime
            )
            user.storeStarterPlan(
                starterPlan,
                focus: .connection,
                urgency: .steady,
                friction: .makingTime,
                date: calendar.date(byAdding: .day, value: -2, to: today) ?? today
            )
            user.requiresInitialSubscriptionUnlock = false
            user.hasSeenInitialSubscriptionPaywall = true

            let couple = Couple(
                id: demoCoupleID,
                user1ID: demoUserID,
                user2ID: demoPartnerID,
                user1Name: "Yusuf",
                user2Name: "Aisha",
                inviteCode: "DEMO42",
                relationshipStage: .married,
                anniversaryDate: anniversaryDate,
                useHijriCalendar: true,
                createdAt: createdAt
            )
            var garden = GardenState()
            garden.setLevel(4.2, for: .communication)
            garden.setLevel(4.6, for: .qualityTime)
            garden.setLevel(4.1, for: .spiritualConnection)
            garden.setLevel(3.9, for: .emotionalSafety)
            garden.setLevel(4.4, for: .growth)
            couple.gardenState = garden

            context.insert(user)
            context.insert(couple)

            seedToday(calendar: calendar, today: today, context: context)
            seedReflections(calendar: calendar, today: today, context: context)
            seedOurs(calendar: calendar, today: today, context: context)
            seedLessonProgress(calendar: calendar, today: today, context: context)

            try context.save()

            appState.restoreSession(user: user, couple: couple)
            appState.handleSubscriptionState(isPremium: true)
            appState.selectedTab = .today
            appState.presentedPaywallEntryPoint = nil
            appState.showPartnerInvitePrompt = false
            return true
        } catch {
            print("Demo data load failed: \(error)")
            return false
        }
    }

    private static func removeExistingDemoData(context: ModelContext) throws {
        try context.delete(model: OnboardingDraft.self)

        for response in try context.fetch(FetchDescriptor<PromptResponse>()) {
            if response.id.hasPrefix("demo-") || response.coupleID == demoCoupleID || response.userID == demoUserID || response.userID == demoPartnerID {
                context.delete(response)
            }
        }

        for checkIn in try context.fetch(FetchDescriptor<CheckIn>()) {
            if checkIn.id.hasPrefix("demo-") || checkIn.coupleID == demoCoupleID || checkIn.userID == demoUserID || checkIn.userID == demoPartnerID {
                context.delete(checkIn)
            }
        }

        for reflection in try context.fetch(FetchDescriptor<WeeklyReflection>()) where reflection.id.hasPrefix("demo-") || reflection.coupleID == demoCoupleID {
            context.delete(reflection)
        }

        for memory in try context.fetch(FetchDescriptor<Memory>()) where memory.id.hasPrefix("demo-") || memory.coupleID == demoCoupleID {
            context.delete(memory)
        }

        for entry in try context.fetch(FetchDescriptor<JournalEntry>()) where entry.id.hasPrefix("demo-") || entry.coupleID == demoCoupleID {
            context.delete(entry)
        }

        for letter in try context.fetch(FetchDescriptor<LoveLetter>()) where letter.id.hasPrefix("demo-") || letter.coupleID == demoCoupleID {
            context.delete(letter)
        }

        for goal in try context.fetch(FetchDescriptor<SharedGoal>()) where goal.id.hasPrefix("demo-") || goal.coupleID == demoCoupleID {
            context.delete(goal)
        }

        for wish in try context.fetch(FetchDescriptor<WishItem>()) where wish.id.hasPrefix("demo-") || wish.coupleID == demoCoupleID {
            context.delete(wish)
        }

        for couple in try context.fetch(FetchDescriptor<Couple>()) where couple.id == demoCoupleID {
            context.delete(couple)
        }

        for user in try context.fetch(FetchDescriptor<User>()) where user.id == demoUserID {
            context.delete(user)
        }
    }

    private static func seedToday(calendar: Calendar, today: Date, context: ModelContext) {
        let prompt = ContentService.shared.todaysPrompt(
            coupleID: demoCoupleID,
            partnerName: "Aisha",
            relationshipDays: 1280
        )

        context.insert(PromptResponse(
            id: "demo-response-today-yusuf",
            promptID: prompt.id,
            coupleID: demoCoupleID,
            userID: demoUserID,
            responseText: "I felt close to you after Fajr when we had a few quiet minutes before the day started.",
            createdAt: date(daysAgo: 0, hour: 8, calendar: calendar, today: today),
            isRevealed: true
        ))
        context.insert(PromptResponse(
            id: "demo-response-today-aisha",
            promptID: prompt.id,
            coupleID: demoCoupleID,
            userID: demoPartnerID,
            responseText: "I noticed the same thing. The quiet felt like we were on the same side again.",
            createdAt: date(daysAgo: 0, hour: 9, calendar: calendar, today: today),
            isRevealed: true
        ))

        let moods: [Mood] = [.great, .good, .good, .okay, .great, .good, .great]
        for (index, mood) in moods.enumerated() {
            context.insert(CheckIn(
                id: "demo-checkin-user-\(index)",
                coupleID: demoCoupleID,
                userID: demoUserID,
                mood: mood,
                note: index == 0 ? "Grateful for the slower morning." : nil,
                date: date(daysAgo: index, hour: 20, calendar: calendar, today: today)
            ))
        }

        context.insert(CheckIn(
            id: "demo-checkin-partner-today",
            coupleID: demoCoupleID,
            userID: demoPartnerID,
            mood: .good,
            note: "Feeling lighter after our check-in.",
            date: date(daysAgo: 0, hour: 20, calendar: calendar, today: today)
        ))

        for index in 1...10 {
            context.insert(PromptResponse(
                id: "demo-response-history-\(index)",
                promptID: "demo-history-prompt-\(index)",
                coupleID: demoCoupleID,
                userID: demoUserID,
                responseText: "A saved reflection from day \(index).",
                createdAt: date(daysAgo: index, hour: 18, calendar: calendar, today: today),
                isRevealed: true
            ))
        }
    }

    private static func seedReflections(calendar: Calendar, today: Date, context: ModelContext) {
        let scoreSets = [
            (4, 5, 4, 4, 5),
            (4, 4, 4, 3, 4),
            (3, 4, 5, 4, 4),
            (4, 5, 4, 5, 4)
        ]

        for (index, scores) in scoreSets.enumerated() {
            context.insert(WeeklyReflection(
                id: "demo-reflection-\(index)",
                coupleID: demoCoupleID,
                userID: demoUserID,
                weekStartDate: date(daysAgo: (index + 1) * 7, hour: 9, calendar: calendar, today: today),
                communicationScore: scores.0,
                qualityTimeScore: scores.1,
                spiritualConnectionScore: scores.2,
                emotionalSafetyScore: scores.3,
                growthScore: scores.4,
                isSharedWithPartner: true,
                createdAt: date(daysAgo: index * 7 + 1, hour: 19, calendar: calendar, today: today)
            ))
        }
    }

    private static func seedOurs(calendar: Calendar, today: Date, context: ModelContext) {
        let memories = [
            ("A slow walk after Maghrib", 5),
            ("The day we chose our first home colors", 42),
            ("Coffee before the family visit", 75)
        ]
        for (index, item) in memories.enumerated() {
            context.insert(Memory(
                id: "demo-memory-\(index)",
                coupleID: demoCoupleID,
                caption: item.0,
                date: date(daysAgo: item.1, hour: 16, calendar: calendar, today: today),
                createdAt: date(daysAgo: item.1, hour: 16, calendar: calendar, today: today)
            ))
        }

        context.insert(JournalEntry(
            id: "demo-journal-1",
            coupleID: demoCoupleID,
            userID: demoUserID,
            authorName: "Yusuf",
            content: "This week I want us to protect the quiet after dinner before we reach for our phones.",
            createdAt: date(daysAgo: 1, hour: 21, calendar: calendar, today: today)
        ))
        context.insert(JournalEntry(
            id: "demo-journal-2",
            coupleID: demoCoupleID,
            userID: demoPartnerID,
            authorName: "Aisha",
            content: "I loved that we made du'a for the same thing without planning it.",
            createdAt: date(daysAgo: 3, hour: 20, calendar: calendar, today: today)
        ))

        context.insert(LoveLetter(
            id: "demo-letter-1",
            coupleID: demoCoupleID,
            senderID: demoPartnerID,
            senderName: "Aisha",
            recipientName: "Yusuf",
            title: "For the morning you needed encouragement",
            content: "I see how hard you are trying, and I am grateful for the softness you keep choosing.",
            deliveryDate: date(daysAgo: 0, hour: 7, calendar: calendar, today: today),
            isDelivered: true,
            isRead: false,
            createdAt: date(daysAgo: 2, hour: 22, calendar: calendar, today: today)
        ))
        context.insert(LoveLetter(
            id: "demo-letter-2",
            coupleID: demoCoupleID,
            senderID: demoUserID,
            senderName: "Yusuf",
            recipientName: "Aisha",
            title: "After our walk",
            content: "That small walk reminded me how peaceful life feels when I slow down with you.",
            deliveryDate: date(daysAgo: 4, hour: 9, calendar: calendar, today: today),
            isDelivered: true,
            isRead: true,
            createdAt: date(daysAgo: 5, hour: 21, calendar: calendar, today: today)
        ))

        context.insert(SharedGoal(
            id: "demo-goal-1",
            coupleID: demoCoupleID,
            title: "Read Surah Al-Mulk together",
            targetCount: 7,
            currentCount: 5,
            category: .spiritual,
            deadline: date(daysAgo: -6, hour: 20, calendar: calendar, today: today)
        ))
        context.insert(SharedGoal(
            id: "demo-goal-2",
            coupleID: demoCoupleID,
            title: "Two phones-away evenings",
            targetCount: 2,
            currentCount: 1,
            category: .qualityTime,
            deadline: date(daysAgo: -3, hour: 20, calendar: calendar, today: today)
        ))

        context.insert(WishItem(
            id: "demo-wish-1",
            coupleID: demoCoupleID,
            userID: demoUserID,
            text: "Book a quiet cabin weekend",
            note: "Somewhere with a kitchen and no packed schedule.",
            createdAt: date(daysAgo: 4, hour: 13, calendar: calendar, today: today)
        ))
        context.insert(WishItem(
            id: "demo-wish-2",
            coupleID: demoCoupleID,
            userID: demoPartnerID,
            text: "Replace our prayer mats",
            note: "Soft neutral colors for the bedroom corner.",
            createdAt: date(daysAgo: 8, hour: 18, calendar: calendar, today: today)
        ))
    }

    private static func seedLessonProgress(calendar: Calendar, today: Date, context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Lesson>())) ?? []
        let existingIDs = Set(existing.map(\.id))
        let completions = ["lesson_001", "lesson_002", "lesson_004"]

        for (index, id) in completions.enumerated() where !existingIDs.contains(id) {
            context.insert(Lesson(
                id: id,
                isCompleted: true,
                completedAt: date(daysAgo: index + 2, hour: 19, calendar: calendar, today: today)
            ))
        }
    }

    private static func date(daysAgo: Int, hour: Int, calendar: Calendar, today: Date) -> Date {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
        return calendar.date(byAdding: .hour, value: hour, to: day) ?? day
    }
}
#endif

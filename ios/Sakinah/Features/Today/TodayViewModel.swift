import SwiftUI
import SwiftData

enum PromptState: Equatable {
    case unanswered
    case revealed
}

@Observable
@MainActor
final class TodayViewModel {
    // Prompt
    var promptID: String = ""
    var promptText: String = ""
    var promptCategory: PromptCategory = .gratitude
    var promptState: PromptState = .unanswered
    var userResponse: String = ""
    var partnerResponse: String = ""
    var selectedReaction: String? = nil
    var showRevealAnimation: Bool = false
    var particlesActive: Bool = false
    var revealFlash: Bool = false

    // Check-in
    var selectedMood: Mood? = nil
    var checkInNote: String = ""
    var showCheckInNote: Bool = false
    var hasCheckedInToday: Bool = false
    var partnerMood: Mood? = nil
    var partnerNote: String? = nil
    var isUpdatingCheckIn: Bool = false

    // Du'a
    var todaysDua: DuaData?
    var isPlayingAudio: Bool = false

    // Progress & Streaks
    var currentStreak: Int = 0
    var totalPromptsAnswered: Int = 0

    // Context
    var userName: String = ""
    var partnerName: String = ""
    var coupleID: String = ""
    var userID: String = ""
    var useHijri: Bool = false
    var relationshipDays: Int?

    let maxResponseLength = 500

    var characterCount: String {
        "\(userResponse.count)/\(maxResponseLength)"
    }

    var isResponseValid: Bool {
        !userResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && userResponse.count <= maxResponseLength
    }

    func loadContent(appState: AppState) {
        userName = appState.currentUser?.name ?? "You"
        partnerName = appState.partnerName
        coupleID = appState.currentCouple?.id ?? ""
        userID = appState.currentUser?.id ?? ""
        useHijri = appState.currentCouple?.useHijriCalendar ?? false
        relationshipDays = appState.relationshipDurationDays

        let prompt = ContentService.shared.todaysPrompt(
            coupleID: coupleID,
            partnerName: partnerName,
            relationshipDays: relationshipDays
        )
        promptID = prompt.id
        promptText = prompt.text
        promptCategory = prompt.category

        todaysDua = ContentService.shared.todaysDua(coupleID: coupleID)
    }

    func loadExistingData(context: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        promptState = .unanswered
        userResponse = ""
        selectedMood = nil
        checkInNote = ""
        hasCheckedInToday = false
        partnerResponse = ""
        partnerMood = nil
        partnerNote = nil

        let pid = promptID
        let uid = userID
        let responsePredicate = #Predicate<PromptResponse> { r in
            r.promptID == pid && r.userID == uid && r.createdAt >= today && r.createdAt < tomorrow
        }
        let responseDescriptor = FetchDescriptor<PromptResponse>(predicate: responsePredicate)
        if let existing = (try? context.fetch(responseDescriptor))?.first {
            userResponse = existing.responseText
            promptState = .revealed
        }

        let cid = coupleID
        let partnerResponsePredicate = #Predicate<PromptResponse> { r in
            r.promptID == pid && r.coupleID == cid && r.userID != uid && r.createdAt >= today && r.createdAt < tomorrow
        }
        let partnerResponseDescriptor = FetchDescriptor<PromptResponse>(predicate: partnerResponsePredicate)
        if let existingPartnerResponse = (try? context.fetch(partnerResponseDescriptor))?.first {
            partnerResponse = existingPartnerResponse.responseText
        }

        let checkInPredicate = #Predicate<CheckIn> { c in
            c.coupleID == cid && c.userID == uid && c.date >= today && c.date < tomorrow
        }
        let checkInDescriptor = FetchDescriptor<CheckIn>(predicate: checkInPredicate)
        if let existing = (try? context.fetch(checkInDescriptor))?.first {
            selectedMood = existing.mood
            checkInNote = existing.note ?? ""
            hasCheckedInToday = true
        }

        let partnerCheckInPredicate = #Predicate<CheckIn> { c in
            c.coupleID == cid && c.userID != uid && c.date >= today && c.date < tomorrow
        }
        let partnerCheckInDescriptor = FetchDescriptor<CheckIn>(predicate: partnerCheckInPredicate)
        if let partnerCheckIn = (try? context.fetch(partnerCheckInDescriptor))?.first {
            partnerMood = partnerCheckIn.mood
            partnerNote = partnerCheckIn.note
        }

        calculateStreak(context: context)

        let allResponsePredicate = #Predicate<PromptResponse> { r in r.userID == uid }
        let allResponseDescriptor = FetchDescriptor<PromptResponse>(predicate: allResponsePredicate)
        totalPromptsAnswered = (try? context.fetchCount(allResponseDescriptor)) ?? 0
    }

    private func calculateStreak(context: ModelContext) {
        let uid = userID
        let cid = coupleID
        let allPredicate = #Predicate<CheckIn> { c in c.coupleID == cid && c.userID == uid }
        let allDescriptor = FetchDescriptor<CheckIn>(predicate: allPredicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
        guard let all = try? context.fetch(allDescriptor) else { return }

        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: Date())
        for checkIn in all {
            let checkDay = Calendar.current.startOfDay(for: checkIn.date)
            if checkDay == checkDate {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
            } else { break }
        }
        currentStreak = streak
    }

    func submitResponse(context: ModelContext) {
        guard isResponseValid else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let trimmed = userResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        let pid = promptID
        let uid = userID
        let predicate = #Predicate<PromptResponse> { r in
            r.promptID == pid && r.userID == uid && r.createdAt >= today && r.createdAt < tomorrow
        }
        let descriptor = FetchDescriptor<PromptResponse>(predicate: predicate)

        let didCreateNewResponse: Bool

        if let existing = (try? context.fetch(descriptor))?.first {
            existing.responseText = trimmed
            existing.isRevealed = true
            existing.touch()
            didCreateNewResponse = false
        } else {
            let response = PromptResponse(
                promptID: promptID,
                coupleID: coupleID,
                userID: userID,
                responseText: trimmed,
                isRevealed: true
            )
            context.insert(response)
            didCreateNewResponse = true
        }
        try? context.save()

        HapticEngine.shared.fire(.success)
        if didCreateNewResponse {
            totalPromptsAnswered += 1
        }
        revealFlash = true

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            revealFlash = false

            withAnimation(SakinahAnimation.gentle) {
                promptState = .revealed
            }

            try? await Task.sleep(for: .milliseconds(100))
            particlesActive = true
            try? await Task.sleep(for: .seconds(1.2))
            particlesActive = false
        }
    }

    func selectMood(_ mood: Mood, context: ModelContext) {
        HapticEngine.shared.fire(.select)

        withAnimation(SakinahAnimation.bounce) {
            selectedMood = mood
        }

        withAnimation(SakinahAnimation.gentle) {
            showCheckInNote = true
        }

        saveCheckIn(context: context)
    }

    func saveCheckIn(context: ModelContext, requestReview: @escaping () -> Void = {}) {
        guard let mood = selectedMood else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let uid = userID
        let cid = coupleID
        let predicate = #Predicate<CheckIn> { c in
            c.coupleID == cid && c.userID == uid && c.date >= today && c.date < tomorrow
        }
        let descriptor = FetchDescriptor<CheckIn>(predicate: predicate)

        if let existing = (try? context.fetch(descriptor))?.first {
            existing.mood = mood
            existing.note = checkInNote.isEmpty ? nil : checkInNote
            existing.touch()
        } else {
            let checkIn = CheckIn(
                coupleID: coupleID,
                userID: userID,
                mood: mood,
                note: checkInNote.isEmpty ? nil : checkInNote
            )
            context.insert(checkIn)
        }

        try? context.save()
        hasCheckedInToday = true

        // Recalculate streak
        calculateStreak(context: context)

        ReviewService.shared.onCheckInSaved(streakDays: currentStreak, requestReview: requestReview)
    }

    func toggleUpdateCheckIn() {
        isUpdatingCheckIn = true
        showCheckInNote = true
    }

    func selectReaction(_ emoji: String) {
        HapticEngine.shared.fire(.tap)
        withAnimation(SakinahAnimation.bounce) {
            selectedReaction = selectedReaction == emoji ? nil : emoji
        }
    }
}

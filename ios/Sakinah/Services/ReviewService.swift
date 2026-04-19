import Foundation
import StoreKit

/// Manages App Store review request timing per Apple guidelines:
/// - Max 3 prompts per 365-day period (enforced by the OS)
/// - Only after meaningful, positive events
/// - Never on first launch or immediately after onboarding
@MainActor
final class ReviewService {
    static let shared = ReviewService()

    private let appStoreID = "6762535411"
    private let defaults = UserDefaults.standard

    // Keys
    private let promptRevealCountKey = "review.promptRevealCount"
    private let checkInStreakKey = "review.checkInStreak"
    private let goalCompletedCountKey = "review.goalCompletedCount"
    private let lastReviewRequestKey = "review.lastRequestDate"
    private let hasEverRequestedKey = "review.hasEverRequested"

    private init() {}

    // MARK: - Trigger Events

    /// Call after a prompt reveal (the "aha" emotional moment).
    /// Requests review on the 3rd and 10th reveal.
    func onPromptRevealed(requestReview: @escaping () -> Void) {
        let count = defaults.integer(forKey: promptRevealCountKey) + 1
        defaults.set(count, forKey: promptRevealCountKey)
        if count == 3 || count == 10 {
            requestReviewIfEligible(requestReview: requestReview)
        }
    }

    /// Call after saving a check-in. Requests review on a 7-day streak.
    func onCheckInSaved(streakDays: Int, requestReview: @escaping () -> Void) {
        if streakDays == 7 || streakDays == 30 {
            requestReviewIfEligible(requestReview: requestReview)
        }
    }

    /// Call after completing a shared goal.
    func onGoalCompleted(requestReview: @escaping () -> Void) {
        let count = defaults.integer(forKey: goalCompletedCountKey) + 1
        defaults.set(count, forKey: goalCompletedCountKey)
        if count == 1 || count == 5 {
            requestReviewIfEligible(requestReview: requestReview)
        }
    }

    // MARK: - Manual Review Link (always available in Settings)

    var writeReviewURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!
    }

    // MARK: - Core Logic

    private func requestReviewIfEligible(requestReview: @escaping () -> Void) {
        // Don't prompt more often than every 60 days (OS enforces 3/year, this adds UX grace)
        if let lastDate = defaults.object(forKey: lastReviewRequestKey) as? Date {
            let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            guard daysSince >= 60 else { return }
        }

        defaults.set(Date(), forKey: lastReviewRequestKey)
        defaults.set(true, forKey: hasEverRequestedKey)

        // Small delay so it doesn't interrupt the immediate moment
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1200))
            requestReview()
        }
    }
}

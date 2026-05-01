import Foundation

enum Constants {
    static let appName = "Sakinah"
    static let tagline = "Your marriage, growing daily"
    static let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
    static let inviteCodeLength = 6
    static let inviteCodeAlphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"

    // Free tier: creates habit + trust
    static let freePromptHistoryDays = 7
    static let freeConversationPacks = 0
    static let freeLessonCount = 2

    // Upgrade triggers: tied to real usage moments
    static let promptsBeforeUpgradeHint = 2
    static let checkInsBeforeUpgradeHint = 7
    static let journalEntriesBeforeUpgradeHint = 3
}

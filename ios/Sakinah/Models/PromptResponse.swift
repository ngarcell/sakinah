import Foundation
import SwiftData

@Model
final class PromptResponse {
    @Attribute(.unique) var id: String
    var promptID: String
    var coupleID: String
    var userID: String
    var responseText: String
    var createdAt: Date
    var updatedAt: Date
    var isRevealed: Bool

    init(id: String = UUID().uuidString, promptID: String, coupleID: String, userID: String, responseText: String, createdAt: Date = Date(), isRevealed: Bool = false) {
        self.id = id
        self.promptID = promptID
        self.coupleID = coupleID
        self.userID = userID
        self.responseText = responseText
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isRevealed = isRevealed
    }

    func touch(_ date: Date = Date()) {
        updatedAt = date
    }
}

import Foundation
import SwiftData

@Model
final class CheckIn {
    @Attribute(.unique) var id: String
    var coupleID: String
    var userID: String
    var moodRaw: Int
    var note: String?
    var date: Date
    var updatedAt: Date

    var mood: Mood {
        get { Mood(rawValue: moodRaw) ?? .okay }
        set { moodRaw = newValue.rawValue }
    }

    init(id: String = UUID().uuidString, coupleID: String, userID: String, mood: Mood, note: String? = nil, date: Date = Date()) {
        self.id = id
        self.coupleID = coupleID
        self.userID = userID
        self.moodRaw = mood.rawValue
        self.note = note
        self.date = date
        self.updatedAt = date
    }

    func touch(_ date: Date = Date()) {
        updatedAt = date
    }
}

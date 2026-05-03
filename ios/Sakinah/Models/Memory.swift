import Foundation
import SwiftData

@Model
final class Memory {
    @Attribute(.unique) var id: String
    var coupleID: String
    var caption: String
    var photoData: Data?
    var date: Date
    var createdAt: Date
    var updatedAt: Date

    init(id: String = UUID().uuidString,
         coupleID: String,
         caption: String,
         photoData: Data? = nil,
         date: Date = Date(),
         createdAt: Date = Date()) {
        self.id = id
        self.coupleID = coupleID
        self.caption = caption
        self.photoData = photoData
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    func touch(_ date: Date = Date()) {
        updatedAt = date
    }
}

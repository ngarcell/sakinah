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
    }
}

import Foundation
import CloudKit
import SwiftData

@Model
final class Couple {
    @Attribute(.unique) var id: String
    var user1ID: String
    var user2ID: String
    var user1Name: String
    var user2Name: String
    var inviteCode: String
    var relationshipStageRaw: String
    var anniversaryDate: Date?
    var useHijriCalendar: Bool
    var createdAt: Date
    var updatedAt: Date
    var lastCloudSyncAt: Date?
    var cloudZoneName: String?
    var cloudZoneOwnerName: String?
    var cloudShareRecordName: String?
    var cloudShareURLString: String?
    var gardenStateData: Data?

    var relationshipStage: RelationshipStage {
        get { RelationshipStage(rawValue: relationshipStageRaw) ?? .married }
        set { relationshipStageRaw = newValue.rawValue }
    }

    var gardenState: GardenState {
        get {
            guard let data = gardenStateData else { return GardenState() }
            return (try? JSONDecoder().decode(GardenState.self, from: data)) ?? GardenState()
        }
        set {
            gardenStateData = try? JSONEncoder().encode(newValue)
        }
    }

    var relationshipDurationDays: Int? {
        guard let anniversaryDate else { return nil }

        let start = Calendar.current.startOfDay(for: anniversaryDate)
        let today = Calendar.current.startOfDay(for: Date())
        let days = Calendar.current.dateComponents([.day], from: start, to: today).day ?? 0
        return max(days, 0)
    }

    var daysTogether: Int {
        relationshipDurationDays ?? 0
    }

    init(id: String = UUID().uuidString,
         user1ID: String,
         user2ID: String = "",
         user1Name: String,
         user2Name: String = "",
         inviteCode: String,
         relationshipStage: RelationshipStage = .married,
         anniversaryDate: Date? = nil,
         useHijriCalendar: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.user1ID = user1ID
        self.user2ID = user2ID
        self.user1Name = user1Name
        self.user2Name = user2Name
        self.inviteCode = inviteCode
        self.relationshipStageRaw = relationshipStage.rawValue
        self.anniversaryDate = anniversaryDate
        self.useHijriCalendar = useHijriCalendar
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.lastCloudSyncAt = nil
        self.cloudZoneName = "couple.\(id)"
        self.cloudZoneOwnerName = CKCurrentUserDefaultName
        self.cloudShareRecordName = nil
        self.cloudShareURLString = nil
        self.gardenStateData = try? JSONEncoder().encode(GardenState())
    }

    func touch(_ date: Date = Date()) {
        updatedAt = date
    }
}

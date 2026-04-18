import Foundation
import SwiftData

@Model
final class WeeklyReflection {
    @Attribute(.unique) var id: String
    var coupleID: String
    var userID: String
    var weekStartDate: Date
    var communicationScore: Int
    var qualityTimeScore: Int
    var spiritualConnectionScore: Int
    var emotionalSafetyScore: Int
    var growthScore: Int
    var isSharedWithPartner: Bool
    var createdAt: Date

    var scores: [GardenDimension: Int] {
        [
            .communication: communicationScore,
            .qualityTime: qualityTimeScore,
            .spiritualConnection: spiritualConnectionScore,
            .emotionalSafety: emotionalSafetyScore,
            .growth: growthScore
        ]
    }

    var averageScore: Double {
        Double(communicationScore + qualityTimeScore + spiritualConnectionScore + emotionalSafetyScore + growthScore) / 5.0
    }

    init(id: String = UUID().uuidString,
         coupleID: String,
         userID: String,
         weekStartDate: Date = Date(),
         communicationScore: Int = 0,
         qualityTimeScore: Int = 0,
         spiritualConnectionScore: Int = 0,
         emotionalSafetyScore: Int = 0,
         growthScore: Int = 0,
         isSharedWithPartner: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.coupleID = coupleID
        self.userID = userID
        self.weekStartDate = weekStartDate
        self.communicationScore = communicationScore
        self.qualityTimeScore = qualityTimeScore
        self.spiritualConnectionScore = spiritualConnectionScore
        self.emotionalSafetyScore = emotionalSafetyScore
        self.growthScore = growthScore
        self.isSharedWithPartner = isSharedWithPartner
        self.createdAt = createdAt
    }
}

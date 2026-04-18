import Foundation
import SwiftData

@Model
final class DailyPrompt {
    @Attribute(.unique) var id: String
    var text: String
    var categoryRaw: String
    var scheduledDate: Date
    var isActive: Bool

    var category: PromptCategory {
        get { PromptCategory(rawValue: categoryRaw) ?? .gratitude }
        set { categoryRaw = newValue.rawValue }
    }

    init(id: String = UUID().uuidString, text: String, category: PromptCategory, scheduledDate: Date = Date(), isActive: Bool = true) {
        self.id = id
        self.text = text
        self.categoryRaw = category.rawValue
        self.scheduledDate = scheduledDate
        self.isActive = isActive
    }
}

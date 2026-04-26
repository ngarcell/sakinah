import SwiftUI

enum Theme {
    static let minTouchTarget: CGFloat = 44
    static let buttonHeight: CGFloat = 50
    static let fieldHeight: CGFloat = 50

    static var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Salaam"
        }
    }

    static var greetingEmoji: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<7: return "\u{1F305}"
        case 7..<12: return "\u{2600}\u{FE0F}"
        case 12..<17: return "\u{1F324}\u{FE0F}"
        case 17..<21: return "\u{1F319}"
        default: return "\u{2B50}"
        }
    }
}

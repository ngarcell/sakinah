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
        default: return "Good evening"
        }
    }
}

import UIKit

enum HapticType {
    case tap, select, success, celebration, error
}

@MainActor
final class HapticEngine {
    static let shared = HapticEngine()
    private init() {}

    func fire(_ type: HapticType) {
        switch type {
        case .tap:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .select:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .celebration:
            let heavy = UIImpactFeedbackGenerator(style: .heavy)
            let medium = UIImpactFeedbackGenerator(style: .medium)
            let light = UIImpactFeedbackGenerator(style: .light)
            heavy.impactOccurred()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(120))
                medium.impactOccurred()
                try? await Task.sleep(for: .milliseconds(120))
                light.impactOccurred()
            }
        }
    }
}

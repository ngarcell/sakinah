import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func scheduleDailyPrompt(at time: Date) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily.prompt"])
        let content = UNMutableNotificationContent()
        content.title = "Your daily moment"
        content.body = "Today's prompt is ready when you are."
        content.sound = .default
        var comp = Calendar.current.dateComponents([.hour, .minute], from: time)
        comp.second = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comp, repeats: true)
        let req = UNNotificationRequest(identifier: "daily.prompt", content: content, trigger: trigger)
        try? await center.add(req)
    }
}

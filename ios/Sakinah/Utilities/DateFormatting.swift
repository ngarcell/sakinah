import Foundation

enum DateFormatting {
    static func gregorian(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let f = DateFormatter()
        f.dateStyle = style
        return f.string(from: date)
    }

    static func hijri(_ date: Date) -> String {
        var cal = Calendar(identifier: .islamicUmmAlQura)
        cal.locale = Locale(identifier: "en_US")
        let f = DateFormatter()
        f.calendar = cal
        f.dateStyle = .medium
        return f.string(from: date)
    }

    static func timeAgo(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }
}

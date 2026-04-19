import WidgetKit
import SwiftUI

struct SakinahDailyEntry: TimelineEntry {
    let date: Date
    let promptText: String
    let promptCategory: String
    let duaArabic: String
    let duaTranslation: String
}

struct SakinahDailyProvider: TimelineProvider {
    func placeholder(in context: Context) -> SakinahDailyEntry {
        SakinahDailyEntry(
            date: Date(),
            promptText: "What's one thing that made you smile this week?",
            promptCategory: "gratitude",
            duaArabic: "رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ",
            duaTranslation: "Our Lord, grant us from among our spouses and offspring comfort to our eyes"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SakinahDailyEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SakinahDailyEntry>) -> Void) {
        let entry = makeEntry()
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }

    private func makeEntry() -> SakinahDailyEntry {
        // Load content from bundle JSON
        let prompt = loadTodaysPrompt()
        let dua = loadTodaysDua()
        return SakinahDailyEntry(
            date: Date(),
            promptText: prompt.text,
            promptCategory: prompt.category,
            duaArabic: dua.arabic,
            duaTranslation: dua.translation
        )
    }

    private func loadTodaysPrompt() -> (text: String, category: String) {
        guard let url = Bundle.main.url(forResource: "Prompts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let prompts = try? JSONDecoder().decode([WidgetPrompt].self, from: data),
              !prompts.isEmpty else {
            return ("What's one thing that made you smile today?", "gratitude")
        }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let idx = day % prompts.count
        let p = prompts[idx]
        return (p.text.replacingOccurrences(of: "{partnerName}", with: "your partner"), p.category)
    }

    private func loadTodaysDua() -> (arabic: String, translation: String) {
        guard let url = Bundle.main.url(forResource: "Duas", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let duas = try? JSONDecoder().decode([WidgetDua].self, from: data),
              !duas.isEmpty else {
            return ("رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ", "Our Lord, grant us comfort from our spouses")
        }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let idx = day % duas.count
        return (duas[idx].arabic, duas[idx].translation)
    }
}

struct WidgetPrompt: Codable {
    let text: String
    let category: String
}

struct WidgetDua: Codable {
    let arabic: String
    let translation: String
}

// MARK: - Small Widget

struct SakinahSmallWidgetView: View {
    let entry: SakinahDailyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("sakinah")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: 0x0D5C63))

            Spacer()

            Text(entry.promptText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: 0x1A1A2E))
                .lineLimit(3)

            Spacer()

            Text(entry.promptCategory.capitalized)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(hex: 0x0D5C63))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(hex: 0xE8F5F6))
                .clipShape(Capsule())
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color(hex: 0xFDF6EC)
        }
        .widgetURL(URL(string: "sakinah://today/prompt"))
    }
}

// MARK: - Medium Widget

struct SakinahMediumWidgetView: View {
    let entry: SakinahDailyEntry

    var body: some View {
        HStack(spacing: 0) {
            // Left: prompt
            VStack(alignment: .leading, spacing: 6) {
                Text("sakinah")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0D5C63))
                Spacer()
                Text(entry.promptText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x1A1A2E))
                    .lineLimit(4)
                Spacer()
                Text(entry.promptCategory.capitalized)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0D5C63))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: 0xE8F5F6))
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)

            // Divider
            Rectangle()
                .fill(Color(hex: 0xE5E7EB).opacity(0.6))
                .frame(width: 1)
                .padding(.vertical, 12)

            // Right: du'a
            VStack(spacing: 6) {
                Text(entry.duaArabic)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundStyle(Color(hex: 0x1A1A2E))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .environment(\.layoutDirection, .rightToLeft)
                Text(entry.duaTranslation)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: 0x6B7280))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
        }
        .containerBackground(for: .widget) {
            Color(hex: 0xFDF6EC)
        }
    }
}

// MARK: - Widget Definition

struct SakinahDailyWidget: Widget {
    let kind = "SakinahDailyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SakinahDailyProvider()) { entry in
            if #available(iOS 17.0, *) {
                WidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Daily Sakinah")
        .description("Your daily prompt and du'a")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: SakinahDailyEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SakinahSmallWidgetView(entry: entry)
        case .systemMedium:
            SakinahMediumWidgetView(entry: entry)
        default:
            SakinahSmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct SakinahWidgetBundle: WidgetBundle {
    var body: some Widget {
        SakinahDailyWidget()
    }
}

// Color extension for widget (standalone)
extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

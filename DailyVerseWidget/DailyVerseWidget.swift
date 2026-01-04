import WidgetKit
import SwiftUI

// MARK: - Widget Constants
// Important: Must match AppConfiguration.App.appGroupId in the main app
private enum WidgetConstants {
    static let appGroupId = "group.com.biblestudy.app"
    static let deepLinkScheme = "biblestudy"
}

// MARK: - Daily Verse Widget
// Displays a daily Bible verse with streak count

struct DailyVerseWidget: Widget {
    let kind: String = "DailyVerseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyVerseTimelineProvider()) { entry in
            DailyVerseWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "\(WidgetConstants.deepLinkScheme)://verse/\(entry.verse.reference.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")"))
        }
        .configurationDisplayName("Daily Verse")
        .description("Display a Bible verse to inspire your day.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Timeline Entry

struct DailyVerseEntry: TimelineEntry {
    let date: Date
    let verse: WidgetVerse
    let streakCount: Int
    let readingProgress: Double // 0.0 to 1.0 for progress ring
}

// MARK: - Widget Verse Model

struct WidgetVerse {
    let text: String
    let reference: String
    let translation: String

    static let placeholder = WidgetVerse(
        text: "For God so loved the world, that he gave his only begotten Son...",
        reference: "John 3:16",
        translation: "KJV"
    )

    static let sample = WidgetVerse(
        text: "Be strong and of a good courage; be not afraid, neither be thou dismayed: for the LORD thy God is with thee whithersoever thou goest.",
        reference: "Joshua 1:9",
        translation: "KJV"
    )
}

// MARK: - Timeline Provider

struct DailyVerseTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyVerseEntry {
        DailyVerseEntry(
            date: Date(),
            verse: .placeholder,
            streakCount: 7,
            readingProgress: 0.8
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyVerseEntry) -> Void) {
        let entry = DailyVerseEntry(
            date: Date(),
            verse: .sample,
            streakCount: loadStreakCount(),
            readingProgress: loadReadingProgress()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyVerseEntry>) -> Void) {
        let currentDate = Date()
        let verse = loadDailyVerse()
        let streak = loadStreakCount()
        let progress = loadReadingProgress()

        let entry = DailyVerseEntry(
            date: currentDate,
            verse: verse,
            streakCount: streak,
            readingProgress: progress
        )

        // Refresh at midnight
        let calendar = Calendar.current
        let tomorrow: Date
        if let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) {
            tomorrow = calendar.startOfDay(for: nextDay)
        } else {
            // Fallback: refresh in 24 hours if date calculation fails
            tomorrow = currentDate.addingTimeInterval(24 * 60 * 60)
        }

        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    // MARK: - Data Loading from App Group

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: WidgetConstants.appGroupId)
    }

    private func loadDailyVerse() -> WidgetVerse {
        guard let defaults = sharedDefaults else { return .sample }

        if let verseText = defaults.string(forKey: "dailyVerseText"),
           let verseRef = defaults.string(forKey: "dailyVerseReference"),
           let translation = defaults.string(forKey: "dailyVerseTranslation") {
            return WidgetVerse(text: verseText, reference: verseRef, translation: translation)
        }

        return .sample
    }

    private func loadStreakCount() -> Int {
        sharedDefaults?.integer(forKey: "currentStreak") ?? 0
    }

    private func loadReadingProgress() -> Double {
        sharedDefaults?.double(forKey: "dailyReadingProgress") ?? 0.0
    }
}

// MARK: - Widget Entry View

struct DailyVerseWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: DailyVerseEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (2x2)

struct SmallWidgetView: View {
    let entry: DailyVerseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Verse text (truncated)
            Text(truncatedVerse)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(4)
                .minimumScaleFactor(0.8)

            Spacer()

            // Bottom row: reference + streak
            HStack {
                Text(entry.verse.reference)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if entry.streakCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                        Text("\(entry.streakCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(12)
    }

    private var truncatedVerse: String {
        let text = entry.verse.text
        if text.count > 80 {
            return String(text.prefix(77)) + "..."
        }
        return text
    }
}

// MARK: - Medium Widget (4x2)

struct MediumWidgetView: View {
    let entry: DailyVerseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "book.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text("Daily Verse")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                if entry.streakCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)
                        Text("\(entry.streakCount)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.orange)
                    }
                }
            }

            // Verse text
            Text(entry.verse.text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(3)
                .minimumScaleFactor(0.8)

            Spacer()

            // Reference
            HStack {
                Spacer()
                Text("— \(entry.verse.reference) (\(entry.verse.translation))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
    }
}

// MARK: - Large Widget (4x4)

struct LargeWidgetView: View {
    let entry: DailyVerseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "book.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Text("Daily Verse")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                if entry.streakCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.orange)
                        Text("\(entry.streakCount)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.orange)
                    }
                }
            }

            // Verse text
            Text(entry.verse.text)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(6)
                .minimumScaleFactor(0.85)

            Spacer()

            // Reference
            HStack {
                Spacer()
                Text("— \(entry.verse.reference) (\(entry.verse.translation))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            // Divider
            Divider()

            // Progress section
            HStack {
                Text("Today's Goal:")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(width: geometry.size.width * entry.readingProgress, height: 8)
                    }
                }
                .frame(height: 8)

                Text("\(Int(entry.readingProgress * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // CTA
            HStack {
                Spacer()
                Text("Continue Reading")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Image(systemName: "arrow.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(16)
    }
}

// MARK: - Widget Bundle

@main
struct DailyVerseWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyVerseWidget()
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    DailyVerseWidget()
} timeline: {
    DailyVerseEntry(date: .now, verse: .sample, streakCount: 7, readingProgress: 0.8)
}

#Preview(as: .systemMedium) {
    DailyVerseWidget()
} timeline: {
    DailyVerseEntry(date: .now, verse: .sample, streakCount: 14, readingProgress: 0.6)
}

#Preview(as: .systemLarge) {
    DailyVerseWidget()
} timeline: {
    DailyVerseEntry(date: .now, verse: .sample, streakCount: 30, readingProgress: 0.45)
}

import Foundation
import WidgetKit

// MARK: - Widget Service
// Manages data sharing between the main app and widgets

@MainActor
final class WidgetService {
    // MARK: - Singleton
    static let shared = WidgetService()

    // MARK: - App Group Identifier
    private var appGroupId: String { AppConfiguration.App.appGroupId }

    // MARK: - Shared UserDefaults Keys
    private enum Keys {
        static let dailyVerseText = "dailyVerseText"
        static let dailyVerseReference = "dailyVerseReference"
        static let dailyVerseTranslation = "dailyVerseTranslation"
        static let currentStreak = "currentStreak"
        static let dailyReadingProgress = "dailyReadingProgress"
        static let lastVerseUpdateDate = "lastVerseUpdateDate"
    }

    // MARK: - Properties
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    // MARK: - Initialization
    private init() {}

    // MARK: - Update Daily Verse

    /// Updates the daily verse shown in the widget
    func updateDailyVerse(text: String, reference: String, translation: String) {
        guard let defaults = sharedDefaults else {
            print("WidgetService: Unable to access shared UserDefaults")
            return
        }

        defaults.set(text, forKey: Keys.dailyVerseText)
        defaults.set(reference, forKey: Keys.dailyVerseReference)
        defaults.set(translation, forKey: Keys.dailyVerseTranslation)
        defaults.set(Date(), forKey: Keys.lastVerseUpdateDate)

        // Request widget refresh
        reloadWidgets()
    }

    /// Updates the daily verse from a verse range
    func updateDailyVerse(from verses: [Verse], range: VerseRange, translation: String) {
        let text = verses.map { $0.text }.joined(separator: " ")
        let reference = range.reference
        updateDailyVerse(text: text, reference: reference, translation: translation)
    }

    // MARK: - Update Streak

    /// Updates the streak count shown in the widget
    func updateStreak(_ count: Int) {
        guard let defaults = sharedDefaults else { return }
        defaults.set(count, forKey: Keys.currentStreak)
        reloadWidgets()
    }

    // MARK: - Update Reading Progress

    /// Updates the daily reading progress (0.0 to 1.0)
    func updateReadingProgress(_ progress: Double) {
        guard let defaults = sharedDefaults else { return }
        defaults.set(min(1.0, max(0.0, progress)), forKey: Keys.dailyReadingProgress)
        reloadWidgets()
    }

    // MARK: - Sync All Widget Data

    /// Syncs all relevant data to the widget
    func syncWidgetData() async {
        // Get current streak from ProgressService
        let streak = ProgressService.shared.currentStreak

        // Get reading progress (placeholder - integrate with actual reading tracking)
        let progress = calculateDailyProgress()

        // Update shared defaults
        updateStreak(streak)
        updateReadingProgress(progress)

        // Update daily verse if needed
        await updateDailyVerseIfNeeded()
    }

    /// Updates the daily verse if it hasn't been updated today
    private func updateDailyVerseIfNeeded() async {
        guard let defaults = sharedDefaults else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check if we've already updated today
        if let lastUpdate = defaults.object(forKey: Keys.lastVerseUpdateDate) as? Date {
            let lastUpdateDay = calendar.startOfDay(for: lastUpdate)
            if lastUpdateDay >= today {
                return // Already updated today
            }
        }

        // Get a verse for today
        await fetchAndUpdateDailyVerse()
    }

    /// Fetches a verse for today and updates the widget
    private func fetchAndUpdateDailyVerse() async {
        // Use a curated list of inspirational verses
        let dailyVerses: [(bookId: Int, chapter: Int, verse: Int, verseEnd: Int)] = [
            (43, 3, 16, 16),   // John 3:16
            (6, 1, 9, 9),      // Joshua 1:9
            (19, 23, 1, 6),    // Psalm 23:1-6
            (50, 4, 13, 13),   // Philippians 4:13
            (45, 8, 28, 28),   // Romans 8:28
            (20, 3, 5, 6),     // Proverbs 3:5-6
            (23, 40, 31, 31),  // Isaiah 40:31
            (24, 29, 11, 11),  // Jeremiah 29:11
            (19, 46, 1, 1),    // Psalm 46:1
            (40, 11, 28, 30),  // Matthew 11:28-30
            (19, 119, 105, 105), // Psalm 119:105
            (48, 5, 22, 23),   // Galatians 5:22-23
            (49, 2, 8, 9),     // Ephesians 2:8-9
            (58, 11, 1, 1),    // Hebrews 11:1
            (59, 1, 2, 4),     // James 1:2-4
        ]

        // Select verse based on day of year
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % dailyVerses.count
        let verseInfo = dailyVerses[index]

        let range = VerseRange(
            bookId: verseInfo.bookId,
            chapter: verseInfo.chapter,
            verseStart: verseInfo.verse,
            verseEnd: verseInfo.verseEnd
        )

        do {
            let verses = try await BibleService.shared.getVerses(range: range)
            let translation = BibleService.shared.currentTranslation?.abbreviation ?? "KJV"
            updateDailyVerse(from: verses, range: range, translation: translation)
        } catch {
            print("WidgetService: Failed to fetch daily verse: \(error)")
            // Use fallback verse
            updateDailyVerse(
                text: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
                reference: "John 3:16",
                translation: "KJV"
            )
        }
    }

    // MARK: - Calculate Daily Progress

    /// Calculate daily reading progress based on goals
    private func calculateDailyProgress() -> Double {
        // Get progress from ReadingAnalyticsService
        let analyticsProgress = ReadingAnalyticsService.shared.todayGoalProgress

        // Also check ProgressService for daily goal tracking
        if let progress = ProgressService.shared.progress {
            let progressGoal = progress.dailyGoalProgress
            // Use the higher of the two (they track slightly different things)
            return max(analyticsProgress, progressGoal)
        }

        return analyticsProgress
    }

    // MARK: - Widget Reload

    /// Request all widgets to refresh their timelines
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Reload specific widget kind
    func reloadWidget(kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let widgetDataDidUpdate = Notification.Name("widgetDataDidUpdate")
}

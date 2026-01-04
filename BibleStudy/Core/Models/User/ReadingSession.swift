import Foundation
import GRDB

// MARK: - Reading Session
// Tracks individual reading sessions for analytics

struct ReadingSession: Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let startedAt: Date
    var endedAt: Date?
    var bookId: Int
    var chapter: Int
    var versesRead: Set<Int>
    var translationId: String
    var durationSeconds: Int

    var isActive: Bool {
        endedAt == nil
    }

    var duration: TimeInterval {
        if let endedAt {
            return endedAt.timeIntervalSince(startedAt)
        }
        return Date().timeIntervalSince(startedAt)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    var reference: String {
        let bookName = Book.find(byId: bookId)?.name ?? "Unknown"
        return "\(bookName) \(chapter)"
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        bookId: Int,
        chapter: Int,
        versesRead: Set<Int> = [],
        translationId: String = "kjv",
        durationSeconds: Int = 0
    ) {
        self.id = id
        self.userId = userId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.bookId = bookId
        self.chapter = chapter
        self.versesRead = versesRead
        self.translationId = translationId
        self.durationSeconds = durationSeconds
    }

    mutating func end() {
        endedAt = Date()
        durationSeconds = Int(duration)
    }

    mutating func recordVerseRead(_ verse: Int) {
        versesRead.insert(verse)
    }
}

// MARK: - GRDB Support
extension ReadingSession: FetchableRecord, PersistableRecord {
    nonisolated static var databaseTableName: String { "reading_sessions" }

    enum Columns: String, ColumnExpression {
        case id
        case userId = "user_id"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case bookId = "book_id"
        case chapter
        case versesRead = "verses_read"
        case translationId = "translation_id"
        case durationSeconds = "duration_seconds"
    }

    nonisolated init(row: Row) {
        id = row[Columns.id]
        userId = row[Columns.userId]
        startedAt = row[Columns.startedAt]
        endedAt = row[Columns.endedAt]
        bookId = row[Columns.bookId]
        chapter = row[Columns.chapter]
        translationId = row[Columns.translationId]
        durationSeconds = row[Columns.durationSeconds]

        // Decode verses from JSON
        if let versesJson: String = row[Columns.versesRead],
           let versesData = versesJson.data(using: .utf8),
           let versesArray = try? JSONDecoder().decode([Int].self, from: versesData) {
            versesRead = Set(versesArray)
        } else {
            versesRead = []
        }
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.userId] = userId
        container[Columns.startedAt] = startedAt
        container[Columns.endedAt] = endedAt
        container[Columns.bookId] = bookId
        container[Columns.chapter] = chapter
        container[Columns.translationId] = translationId
        container[Columns.durationSeconds] = durationSeconds

        // Encode verses to JSON
        if let versesData = try? JSONEncoder().encode(Array(versesRead)),
           let versesJson = String(data: versesData, encoding: .utf8) {
            container[Columns.versesRead] = versesJson
        } else {
            container[Columns.versesRead] = "[]"
        }
    }
}

// MARK: - Reading Stats
// Aggregated reading statistics

struct ReadingStats: Sendable {
    var totalSessions: Int = 0
    var totalMinutesRead: Int = 0
    var totalChaptersRead: Int = 0
    var totalVersesRead: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var averageSessionMinutes: Double = 0

    // Books completed (read all chapters)
    var completedBooks: Set<Int> = []

    // Reading by book (bookId -> chapters read)
    var chaptersByBook: [Int: Set<Int>] = [:]

    // Sessions by day (for streak calculation)
    var sessionDays: Set<DateComponents> = []

    var formattedTotalTime: String {
        let hours = totalMinutesRead / 60
        let minutes = totalMinutesRead % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Daily Goal
// User's daily reading goal

struct DailyGoal: Codable, Sendable {
    var targetMinutes: Int
    var targetChapters: Int
    var isEnabled: Bool

    static let `default` = DailyGoal(targetMinutes: 15, targetChapters: 1, isEnabled: false)

    func isMetForMinutes(_ minutes: Int) -> Bool {
        minutes >= targetMinutes
    }

    func isMetForChapters(_ chapters: Int) -> Bool {
        chapters >= targetChapters
    }

    func progressForMinutes(_ minutes: Int) -> Double {
        guard targetMinutes > 0 else { return 0 }
        return min(1.0, Double(minutes) / Double(targetMinutes))
    }

    func progressForChapters(_ chapters: Int) -> Double {
        guard targetChapters > 0 else { return 0 }
        return min(1.0, Double(chapters) / Double(targetChapters))
    }
}

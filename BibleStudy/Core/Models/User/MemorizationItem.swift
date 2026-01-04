import Foundation
import GRDB

// MARK: - Memorization Item
// A verse or passage the user is memorizing, with SM-2 spaced repetition data

struct MemorizationItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let bookId: Int
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int
    let verseText: String
    let createdAt: Date
    var updatedAt: Date

    // SM-2 Spaced Repetition Fields
    var easeFactor: Double      // Starting at 2.5, adjusted based on performance
    var interval: Int           // Days until next review
    var repetitions: Int        // Number of successful reviews in a row
    var nextReviewDate: Date    // When this item is due for review
    var lastReviewDate: Date?   // When it was last reviewed

    // Mastery tracking
    var masteryLevel: MasteryLevel
    var totalReviews: Int
    var correctReviews: Int

    // Local sync tracking
    var needsSync: Bool = false
    var deletedAt: Date?

    var range: VerseRange {
        VerseRange(bookId: bookId, chapter: chapter, verseStart: verseStart, verseEnd: verseEnd)
    }

    var reference: String {
        range.reference
    }

    var accuracy: Double {
        guard totalReviews > 0 else { return 0 }
        return Double(correctReviews) / Double(totalReviews)
    }

    var isDueForReview: Bool {
        nextReviewDate <= Date()
    }

    var daysUntilReview: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: nextReviewDate)
        return max(0, components.day ?? 0)
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        bookId: Int,
        chapter: Int,
        verseStart: Int,
        verseEnd: Int,
        verseText: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        easeFactor: Double = 2.5,
        interval: Int = 0,
        repetitions: Int = 0,
        nextReviewDate: Date = Date(),
        lastReviewDate: Date? = nil,
        masteryLevel: MasteryLevel = .learning,
        totalReviews: Int = 0,
        correctReviews: Int = 0,
        needsSync: Bool = false,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.bookId = bookId
        self.chapter = chapter
        self.verseStart = verseStart
        self.verseEnd = verseEnd
        self.verseText = verseText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.easeFactor = easeFactor
        self.interval = interval
        self.repetitions = repetitions
        self.nextReviewDate = nextReviewDate
        self.lastReviewDate = lastReviewDate
        self.masteryLevel = masteryLevel
        self.totalReviews = totalReviews
        self.correctReviews = correctReviews
        self.needsSync = needsSync
        self.deletedAt = deletedAt
    }

    init(userId: UUID, range: VerseRange, verseText: String) {
        self.init(
            userId: userId,
            bookId: range.bookId,
            chapter: range.chapter,
            verseStart: range.verseStart,
            verseEnd: range.verseEnd,
            verseText: verseText,
            needsSync: true
        )
    }
}

// MARK: - Mastery Level

enum MasteryLevel: String, Codable, CaseIterable, Sendable {
    case learning       // Just started, needs frequent review
    case reviewing      // Making progress, spaced reviews
    case mastered       // Well-known, infrequent reviews

    var displayName: String {
        switch self {
        case .learning: return "Learning"
        case .reviewing: return "Reviewing"
        case .mastered: return "Mastered"
        }
    }

    var icon: String {
        switch self {
        case .learning: return "book.pages"
        case .reviewing: return "arrow.clockwise"
        case .mastered: return "checkmark.seal.fill"
        }
    }

    var color: String {
        switch self {
        case .learning: return "accentBlue"
        case .reviewing: return "accentGold"
        case .mastered: return "success"
        }
    }
}

// MARK: - Review Quality (SM-2)

enum ReviewQuality: Int, CaseIterable {
    case completeBlackout = 0   // Total failure
    case incorrectButRemembered = 1  // Wrong but recognized after
    case incorrectEasyRecall = 2     // Wrong but easy recall after hint
    case correctDifficult = 3        // Correct with difficulty
    case correctWithHesitation = 4   // Correct after hesitation
    case perfectRecall = 5           // Perfect, immediate recall

    var displayName: String {
        switch self {
        case .completeBlackout: return "Forgot"
        case .incorrectButRemembered: return "Hard"
        case .incorrectEasyRecall: return "Struggled"
        case .correctDifficult: return "Okay"
        case .correctWithHesitation: return "Good"
        case .perfectRecall: return "Perfect"
        }
    }

    var icon: String {
        switch self {
        case .completeBlackout: return "xmark.circle"
        case .incorrectButRemembered: return "exclamationmark.triangle"
        case .incorrectEasyRecall: return "questionmark.circle"
        case .correctDifficult: return "checkmark.circle"
        case .correctWithHesitation: return "hand.thumbsup"
        case .perfectRecall: return "star.fill"
        }
    }

    var isCorrect: Bool {
        self.rawValue >= 3
    }
}

// MARK: - GRDB Support

extension MemorizationItem: FetchableRecord, PersistableRecord {
    nonisolated static var databaseTableName: String { "memorization_items" }

    enum Columns: String, ColumnExpression {
        case id
        case userId = "user_id"
        case bookId = "book_id"
        case chapter
        case verseStart = "verse_start"
        case verseEnd = "verse_end"
        case verseText = "verse_text"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case easeFactor = "ease_factor"
        case interval
        case repetitions
        case nextReviewDate = "next_review_date"
        case lastReviewDate = "last_review_date"
        case masteryLevel = "mastery_level"
        case totalReviews = "total_reviews"
        case correctReviews = "correct_reviews"
        case needsSync = "needs_sync"
        case deletedAt = "deleted_at"
    }

    nonisolated init(row: Row) {
        id = row[Columns.id]
        userId = row[Columns.userId]
        bookId = row[Columns.bookId]
        chapter = row[Columns.chapter]
        verseStart = row[Columns.verseStart]
        verseEnd = row[Columns.verseEnd]
        verseText = row[Columns.verseText]
        createdAt = row[Columns.createdAt]
        updatedAt = row[Columns.updatedAt]
        easeFactor = row[Columns.easeFactor]
        interval = row[Columns.interval]
        repetitions = row[Columns.repetitions]
        nextReviewDate = row[Columns.nextReviewDate]
        lastReviewDate = row[Columns.lastReviewDate]
        masteryLevel = MasteryLevel(rawValue: row[Columns.masteryLevel]) ?? .learning
        totalReviews = row[Columns.totalReviews]
        correctReviews = row[Columns.correctReviews]
        needsSync = row[Columns.needsSync]
        deletedAt = row[Columns.deletedAt]
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.userId] = userId
        container[Columns.bookId] = bookId
        container[Columns.chapter] = chapter
        container[Columns.verseStart] = verseStart
        container[Columns.verseEnd] = verseEnd
        container[Columns.verseText] = verseText
        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt
        container[Columns.easeFactor] = easeFactor
        container[Columns.interval] = interval
        container[Columns.repetitions] = repetitions
        container[Columns.nextReviewDate] = nextReviewDate
        container[Columns.lastReviewDate] = lastReviewDate
        container[Columns.masteryLevel] = masteryLevel.rawValue
        container[Columns.totalReviews] = totalReviews
        container[Columns.correctReviews] = correctReviews
        container[Columns.needsSync] = needsSync
        container[Columns.deletedAt] = deletedAt
    }
}

// MARK: - SM-2 Algorithm

extension MemorizationItem {
    /// Applies the SM-2 spaced repetition algorithm based on review quality
    /// Returns a new MemorizationItem with updated scheduling
    func applyReview(quality: ReviewQuality) -> MemorizationItem {
        var updated = self
        updated.totalReviews += 1
        updated.lastReviewDate = Date()
        updated.updatedAt = Date()
        updated.needsSync = true

        if quality.isCorrect {
            updated.correctReviews += 1

            // SM-2 Algorithm
            if quality.rawValue < 3 {
                // Incorrect response: reset repetitions
                updated.repetitions = 0
                updated.interval = 1
            } else {
                // Correct response
                if updated.repetitions == 0 {
                    updated.interval = 1
                } else if updated.repetitions == 1 {
                    updated.interval = 6
                } else {
                    updated.interval = Int(Double(updated.interval) * updated.easeFactor)
                }
                updated.repetitions += 1
            }

            // Update ease factor
            let qualityFactor = Double(5 - quality.rawValue)
            updated.easeFactor = max(1.3, updated.easeFactor + (0.1 - qualityFactor * (0.08 + qualityFactor * 0.02)))

        } else {
            // Failed: reset to beginning
            updated.repetitions = 0
            updated.interval = 1
        }

        // Calculate next review date
        updated.nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: updated.interval,
            to: Date()
        ) ?? Date()

        // Update mastery level based on performance
        updated.masteryLevel = updated.calculateMasteryLevel()

        return updated
    }

    private func calculateMasteryLevel() -> MasteryLevel {
        if repetitions >= 5 && accuracy >= 0.9 && interval >= 21 {
            return .mastered
        } else if repetitions >= 2 && accuracy >= 0.7 {
            return .reviewing
        } else {
            return .learning
        }
    }
}

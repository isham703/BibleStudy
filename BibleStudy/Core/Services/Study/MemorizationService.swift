import Foundation
import GRDB
import Auth

// MARK: - Memorization Service
// Manages scripture memorization with SM-2 spaced repetition

private let analytics = AnalyticsService.shared

@MainActor
@Observable
final class MemorizationService {
    // MARK: - Singleton
    static let shared = MemorizationService()

    // MARK: - Properties
    private let supabase = SupabaseManager.shared
    private let db = DatabaseManager.shared

    var items: [MemorizationItem] = [] {
        didSet { updateCachedCounts() }
    }
    var dueItems: [MemorizationItem] = []
    var isLoading: Bool = false
    var error: Error?

    // MARK: - Cached Statistics (Performance Optimization)
    // These are recalculated only when items change, not on every view access

    private(set) var masteredCount: Int = 0
    private(set) var learningCount: Int = 0
    private(set) var reviewingCount: Int = 0

    // Cached filtered arrays by mastery level
    private(set) var masteredItems: [MemorizationItem] = []
    private(set) var learningItems: [MemorizationItem] = []
    private(set) var reviewingItems: [MemorizationItem] = []

    var totalItems: Int { items.count }
    var dueCount: Int { dueItems.count }

    private func updateCachedCounts() {
        var mastered: [MemorizationItem] = []
        var learning: [MemorizationItem] = []
        var reviewing: [MemorizationItem] = []

        for item in items {
            switch item.masteryLevel {
            case .mastered: mastered.append(item)
            case .learning: learning.append(item)
            case .reviewing: reviewing.append(item)
            }
        }

        masteredItems = mastered
        learningItems = learning
        reviewingItems = reviewing

        masteredCount = mastered.count
        learningCount = learning.count
        reviewingCount = reviewing.count
    }

    // Streak tracking is now managed by ProgressService
    var streakDays: Int {
        ProgressService.shared.currentStreak
    }

    // MARK: - Initialization
    private init() {}

    // MARK: - Load Items

    func loadItems() async {
        guard let userId = supabase.currentUser?.id else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await loadFromCache(userId: userId)
            updateDueItems()
        } catch {
            self.error = error
        }
    }

    private nonisolated func fetchItemsFromCache(userId: UUID, dbQueue: DatabaseQueue) throws -> [MemorizationItem] {
        return try dbQueue.read { db in
            try MemorizationItem
                .filter(MemorizationItem.Columns.userId == userId.uuidString)
                .filter(MemorizationItem.Columns.deletedAt == nil)
                .order(MemorizationItem.Columns.nextReviewDate.asc)
                .fetchAll(db)
        }
    }

    private func loadFromCache(userId: UUID) async throws {
        guard let dbQueue = db.dbQueue else { return }
        items = try fetchItemsFromCache(userId: userId, dbQueue: dbQueue)
    }

    private func updateDueItems() {
        let now = Date()
        dueItems = items.filter { $0.nextReviewDate <= now && $0.deletedAt == nil }
    }

    // MARK: - Nonisolated DB Helpers

    private nonisolated func saveItemToCache(_ item: MemorizationItem, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try item.save(db)
        }
    }

    // MARK: - Add Item

    func addItem(range: VerseRange, verseText: String) async throws {
        guard let userId = supabase.currentUser?.id else {
            throw MemorizationError.notAuthenticated
        }

        // Check if already exists
        if items.contains(where: { $0.range == range }) {
            throw MemorizationError.alreadyExists
        }

        let item = MemorizationItem(userId: userId, range: range, verseText: verseText)

        // Save to local database
        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        try saveItemToCache(item, dbQueue: dbQueue)

        // Update local state
        items.append(item)
        updateDueItems()
    }

    // MARK: - Record Review

    func recordReview(item: MemorizationItem, quality: ReviewQuality) async throws {
        let updatedItem = item.applyReview(quality: quality)

        // Save to local database
        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        try saveItemToCache(updatedItem, dbQueue: dbQueue)

        // Update local state
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = updatedItem
        }
        updateDueItems()

        // Record activity and award XP via ProgressService
        let progressService = ProgressService.shared
        try await progressService.recordActivity()

        // Award XP based on review quality
        let mastered = updatedItem.masteryLevel == .mastered && item.masteryLevel != .mastered
        try await progressService.recordVerseReviewed(mastered: mastered)

        // Track memorization analytics
        analytics.trackVerseMemorized(reference: item.reference, mastered: mastered)
    }

    // MARK: - Remove Item

    func removeItem(_ item: MemorizationItem) async throws {
        var deletedItem = item
        deletedItem.deletedAt = Date()
        deletedItem.updatedAt = Date()
        deletedItem.needsSync = true

        // Save to local database
        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        try saveItemToCache(deletedItem, dbQueue: dbQueue)

        // Update local state
        items.removeAll { $0.id == item.id }
        updateDueItems()
    }

    // MARK: - Get Next Due Item

    func getNextDueItem() -> MemorizationItem? {
        return dueItems.first
    }

    // MARK: - Get Items by Mastery Level

    func getItems(masteryLevel: MasteryLevel) -> [MemorizationItem] {
        // Return cached arrays for O(1) access instead of filtering
        switch masteryLevel {
        case .learning: return learningItems
        case .reviewing: return reviewingItems
        case .mastered: return masteredItems
        }
    }

    // MARK: - Check if Range is Being Memorized

    func isMemorizing(range: VerseRange) -> Bool {
        return items.contains { $0.range == range && $0.deletedAt == nil }
    }
}

// MARK: - Memorization Errors

enum MemorizationError: Error, LocalizedError {
    case notAuthenticated
    case alreadyExists
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to use memorization features."
        case .alreadyExists:
            return "This passage is already in your memorization queue."
        case .itemNotFound:
            return "Memorization item not found."
        }
    }
}

// MARK: - Hint Generation

extension MemorizationService {
    /// Generates first-letter hints for memorization practice
    /// Example: "In the beginning" → "I___ t__ b________"
    static func generateFirstLetterHints(text: String) -> String {
        let words = text.components(separatedBy: .whitespaces)
        return words.map { word in
            guard let firstChar = word.first else { return "" }

            // Keep punctuation attached to first letter if present
            if firstChar.isPunctuation {
                if word.count > 1 {
                    let secondChar = word[word.index(after: word.startIndex)]
                    let rest = String(repeating: "_", count: max(0, word.count - 2))
                    return "\(firstChar)\(secondChar)\(rest)"
                }
                return String(firstChar)
            }

            let rest = String(repeating: "_", count: max(0, word.count - 1))
            return "\(firstChar)\(rest)"
        }.joined(separator: " ")
    }

    /// Generates progressive hints revealing more letters
    /// level 0: full hints (I___ t__ b________)
    /// level 1: show first two letters (In__ th_ be_______)
    /// level 2: show first half (In t___ the begi_____)
    /// level 3: full text
    static func generateProgressiveHint(text: String, level: Int) -> String {
        switch level {
        case 0:
            return generateFirstLetterHints(text: text)
        case 1:
            return generatePartialHints(text: text, revealFraction: 0.3)
        case 2:
            return generatePartialHints(text: text, revealFraction: 0.6)
        default:
            return text
        }
    }

    /// Generates hints revealing a fraction of each word
    private static func generatePartialHints(text: String, revealFraction: Double) -> String {
        let words = text.components(separatedBy: .whitespaces)
        return words.map { word in
            let revealCount = max(1, Int(ceil(Double(word.count) * revealFraction)))
            let hiddenCount = max(0, word.count - revealCount)

            let revealed = word.prefix(revealCount)
            let hidden = String(repeating: "_", count: hiddenCount)
            return "\(revealed)\(hidden)"
        }.joined(separator: " ")
    }

    /// Checks if user input matches the expected text (case-insensitive, ignoring punctuation)
    static func checkAnswer(userInput: String, expectedText: String) -> AnswerResult {
        let normalizedInput = normalizeText(userInput)
        let normalizedExpected = normalizeText(expectedText)

        if normalizedInput == normalizedExpected {
            return .correct
        }

        // Calculate similarity for partial credit
        let similarity = calculateSimilarity(normalizedInput, normalizedExpected)

        if similarity >= 0.9 {
            return .almostCorrect(similarity: similarity)
        } else if similarity >= 0.7 {
            return .partiallyCorrect(similarity: similarity)
        } else {
            return .incorrect
        }
    }

    private static func normalizeText(_ text: String) -> String {
        return text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: " ")
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func calculateSimilarity(_ str1: String, _ str2: String) -> Double {
        let words1 = str1.split(separator: " ")
        let words2 = str2.split(separator: " ")

        guard !words2.isEmpty else { return 0 }

        var matchCount = 0
        for word in words1 {
            if words2.contains(word) {
                matchCount += 1
            }
        }

        return Double(matchCount) / Double(words2.count)
    }
}

// MARK: - Answer Result

enum AnswerResult {
    case correct
    case almostCorrect(similarity: Double)
    case partiallyCorrect(similarity: Double)
    case incorrect

    var isCorrect: Bool {
        switch self {
        case .correct, .almostCorrect:
            return true
        default:
            return false
        }
    }

    var reviewQuality: ReviewQuality {
        switch self {
        case .correct:
            return .perfectRecall
        case .almostCorrect:
            return .correctWithHesitation
        case .partiallyCorrect:
            return .correctDifficult
        case .incorrect:
            return .incorrectButRemembered
        }
    }

    var feedbackMessage: String {
        switch self {
        case .correct:
            return "Perfect!"
        case .almostCorrect(let similarity):
            return "Almost! \(Int(similarity * 100))% correct"
        case .partiallyCorrect(let similarity):
            return "Good try! \(Int(similarity * 100))% correct"
        case .incorrect:
            return "Not quite. Keep practicing!"
        }
    }
}

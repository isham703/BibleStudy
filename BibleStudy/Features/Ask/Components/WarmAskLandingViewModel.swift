import Foundation
import SwiftUI

// MARK: - Warm Ask Landing ViewModel
// Manages context-aware state for the Ask tab landing view

@MainActor
@Observable
final class WarmAskLandingViewModel {
    // MARK: - Dependencies
    private let analyticsService = ReadingAnalyticsService.shared

    // MARK: - State
    var readingContext: ReadingContext?
    var suggestedQuestions: [String] = []
    var isLoading = false

    // MARK: - User Info
    var userName: String? {
        UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.userName)
    }

    // MARK: - Reading History Detection
    var hasReadingHistory: Bool {
        UserDefaults.standard.data(
            forKey: AppConfiguration.UserDefaultsKeys.lastReadLocation
        ) != nil
    }

    // MARK: - Load Context
    func loadContext(from appState: AppState) {
        isLoading = true
        defer { isLoading = false }

        // Only show context if user has reading history
        guard hasReadingHistory else {
            // Fresh install - show general questions only
            suggestedQuestions = getGeneralQuestions()
            readingContext = nil
            return
        }

        let currentLocation = appState.currentLocation

        // Skip if still at default Genesis 1 with no saved location
        // (This shouldn't happen if hasReadingHistory is true, but double-check)
        let isDefaultLocation = currentLocation.bookId == 1 && currentLocation.chapter == 1

        if isDefaultLocation && !hasReadingHistory {
            suggestedQuestions = getGeneralQuestions()
            readingContext = nil
            return
        }

        // Determine recency: is user currently reading or was reading previously?
        let isCurrentlyReading = analyticsService.currentSession != nil
            || analyticsService.todaysSessions.contains {
                $0.bookId == currentLocation.bookId && $0.chapter == currentLocation.chapter
            }

        // Build reading context
        if let book = Book.find(byId: currentLocation.bookId) {
            readingContext = ReadingContext(
                bookId: currentLocation.bookId,
                bookName: book.name,
                chapter: currentLocation.chapter,
                isCurrentlyReading: isCurrentlyReading
            )
        }

        // Generate contextual questions
        suggestedQuestions = generateContextualQuestions(
            bookId: currentLocation.bookId,
            chapter: currentLocation.chapter
        )
    }

    // MARK: - Question Generation

    private func generateContextualQuestions(bookId: Int, chapter: Int) -> [String] {
        // If we have a book-specific mapping, use it
        if let bookQuestions = getBookSpecificQuestions(bookId: bookId) {
            return Array(bookQuestions.shuffled().prefix(4))
        }

        // Fallback: generic questions for the book
        if let book = Book.find(byId: bookId) {
            return getGenericBookQuestions(book: book, chapter: chapter)
        }

        return getGeneralQuestions()
    }

    private func getBookSpecificQuestions(bookId: Int) -> [String]? {
        let bookQuestions: [Int: [String]] = [
            // Genesis (bookId: 1)
            1: [
                "What does 'in the beginning' tell us about God?",
                "Why did God create humans in His image?",
                "What was the significance of the tree of knowledge?",
                "Why did God call Abraham?",
                "What is the meaning of Jacob's ladder dream?",
                "How does Genesis point to Jesus?"
            ],
            // Psalms (bookId: 19)
            19: [
                "What does it mean to meditate on God's law?",
                "How do the Psalms express lament and hope?",
                "What is the shepherd imagery in Psalm 23?",
                "Why are there songs of ascent?",
                "How did David worship through difficulty?",
                "What makes the Psalms different from other books?"
            ],
            // Matthew (bookId: 40)
            40: [
                "What is the Sermon on the Mount about?",
                "Why does Matthew include Jesus' genealogy?",
                "What are the Beatitudes teaching us?",
                "How did Jesus fulfill Old Testament prophecy?",
                "What parables are unique to Matthew?",
                "Why did Matthew write to a Jewish audience?"
            ],
            // John (bookId: 43)
            43: [
                "What does 'the Word' mean in John 1?",
                "Who was Nicodemus and why did he come at night?",
                "What does 'born again' mean in John 3?",
                "Why did Jesus wash the disciples' feet?",
                "What are the 'I am' statements in John?",
                "How is John's Gospel different from the others?"
            ],
            // Romans (bookId: 45)
            45: [
                "What does Paul mean by 'justification by faith'?",
                "How does Romans 8 comfort believers?",
                "What is the 'renewing of the mind' in Romans 12?",
                "How should we understand predestination?",
                "What does 'all have sinned' mean?",
                "Why is Romans considered foundational?"
            ]
        ]

        return bookQuestions[bookId]
    }

    private func getGenericBookQuestions(book: Book, chapter: Int) -> [String] {
        return [
            "What is the main theme of \(book.name)?",
            "Who wrote \(book.name) and why?",
            "What can I learn from \(book.name) \(chapter)?",
            "How does \(book.name) connect to Jesus?"
        ].shuffled()
    }

    private func getGeneralQuestions() -> [String] {
        let allQuestions = [
            "What does it mean to have faith?",
            "How should I pray?",
            "What does the Bible say about worry?",
            "Who is Jesus and why does it matter?",
            "How do I read the Bible effectively?",
            "What is grace?",
            "How do I forgive someone who hurt me?",
            "What does the Bible say about purpose?",
            "How can I grow spiritually?",
            "What is the gospel?"
        ]
        return Array(allQuestions.shuffled().prefix(4))
    }
}

// MARK: - Reading Context Model

struct ReadingContext {
    let bookId: Int
    let bookName: String
    let chapter: Int
    let isCurrentlyReading: Bool

    /// Display text for the context card
    var displayText: String {
        if isCurrentlyReading {
            return "You're reading \(bookName) \(chapter)"
        } else {
            return "You were reading \(bookName) \(chapter)"
        }
    }

    /// Reference string for accessibility
    var reference: String {
        "\(bookName) chapter \(chapter)"
    }
}

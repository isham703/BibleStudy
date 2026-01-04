import SwiftUI
import UIKit

// MARK: - Scholar's Reader View Model
// Manages state for the Scholar's Marginalia reader experience
// Enhanced with multi-verse selection, highlights, and AI insights

@Observable
@MainActor
final class ScholarsReaderViewModel {
    // MARK: - Dependencies
    private let bibleService: BibleService
    private let userContentService: UserContentService
    private let aiService: AIServiceProtocol

    // MARK: - State
    var currentLocation: BibleLocation
    var chapter: Chapter?
    var isLoading: Bool = false
    var error: Error?

    // MARK: - Multi-Verse Selection
    var selectedVerses: Set<Int> = []
    var selectionMode: ScholarSelectionMode = .none

    // MARK: - Context Menu State
    var showContextMenu: Bool = false
    var selectionBounds: CGRect = .zero
    var containerBounds: CGRect = .zero

    // MARK: - Inline Insight State
    var showInlineInsight: Bool = false
    var inlineInsightViewModel: InsightViewModel?
    var insightSheetRange: VerseRange?

    // MARK: - User Content
    var chapterHighlights: [Highlight] = []
    var chapterNotes: [Note] = []

    // MARK: - Highlight Undo
    private(set) var lastHighlightAction: ScholarHighlightUndoAction?

    // Navigation
    var canGoBack: Bool = false
    var canGoForward: Bool = false

    // MARK: - Computed Properties
    var book: Book? {
        Book.find(byId: currentLocation.bookId)
    }

    var headerTitle: String {
        guard let book = book else { return "" }
        return "\(book.name) \(currentLocation.chapter)"
    }

    var headerReference: String {
        guard let book = book else { return "" }
        return "\(book.abbreviation) \(currentLocation.chapter)"
    }

    var currentTranslation: Translation? {
        bibleService.currentTranslation
    }

    /// Computed verse range from current selection
    var selectedRange: VerseRange? {
        guard !selectedVerses.isEmpty else { return nil }
        let sorted = selectedVerses.sorted()
        return VerseRange(
            bookId: currentLocation.bookId,
            chapter: currentLocation.chapter,
            verseStart: sorted.first!,
            verseEnd: sorted.last!
        )
    }

    /// Returns highlight color for the current selection, if highlighted
    var existingHighlightColorForSelection: HighlightColor? {
        guard let range = selectedRange else { return nil }
        return chapterHighlights.first { highlight in
            highlight.verseStart == range.verseStart &&
            highlight.verseEnd == range.verseEnd
        }?.color
    }

    /// Returns the highlight for the current selection, if any
    var existingHighlightForSelection: Highlight? {
        guard let range = selectedRange else { return nil }
        return chapterHighlights.first { highlight in
            highlight.verseStart == range.verseStart &&
            highlight.verseEnd == range.verseEnd
        }
    }

    /// Whether any verses are selected
    var hasSelection: Bool {
        !selectedVerses.isEmpty
    }

    // MARK: - Initialization
    init(
        bibleService: BibleService? = nil,
        userContentService: UserContentService? = nil,
        aiService: AIServiceProtocol? = nil,
        location: BibleLocation? = nil
    ) {
        self.bibleService = bibleService ?? BibleService.shared
        self.userContentService = userContentService ?? UserContentService.shared
        self.aiService = aiService ?? OpenAIProvider.shared
        self.currentLocation = location ?? .genesis1
    }

    // MARK: - Loading
    func loadChapter() async {
        isLoading = true
        error = nil

        do {
            chapter = try await bibleService.getChapter(location: currentLocation)
            updateNavigationState()
            loadUserContent()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func loadChapter(at location: BibleLocation) async {
        currentLocation = location
        clearSelection()
        await loadChapter()
    }

    // MARK: - Navigation
    private func updateNavigationState() {
        canGoBack = currentLocation.previous() != nil
        if let book = book {
            canGoForward = currentLocation.next(maxChapter: book.chapters) != nil
        } else {
            canGoForward = false
        }
    }

    func goToPreviousChapter() async {
        guard let previous = currentLocation.previous() else { return }
        await loadChapter(at: previous)
    }

    func goToNextChapter() async {
        guard let book = book,
              let next = currentLocation.next(maxChapter: book.chapters) else { return }
        await loadChapter(at: next)
    }

    func goToChapter(_ chapter: Int) async {
        let location = BibleLocation(bookId: currentLocation.bookId, chapter: chapter)
        await loadChapter(at: location)
    }

    func goToBook(_ bookId: Int, chapter: Int = 1) async {
        let location = BibleLocation(bookId: bookId, chapter: chapter)
        await loadChapter(at: location)
    }

    // MARK: - Selection

    /// Select a single verse (toggles if already selected)
    func selectVerse(_ verse: Int) {
        if selectionMode == .none {
            selectionMode = .single
        }

        if selectedVerses.contains(verse) {
            selectedVerses.remove(verse)
            if selectedVerses.isEmpty {
                selectionMode = .none
                showContextMenu = false
            }
        } else {
            if selectionMode == .single {
                selectedVerses = [verse]
            } else {
                selectedVerses.insert(verse)
            }
            showContextMenu = true
        }
    }

    /// Extend selection to create a range
    func extendSelection(to verse: Int) {
        guard let first = selectedVerses.min() else {
            selectVerse(verse)
            return
        }
        selectionMode = .range
        selectedVerses = Set(min(first, verse)...max(first, verse))
        showContextMenu = true
    }

    /// Start range selection mode from a verse
    func startRangeSelection(from verse: Int) {
        selectionMode = .range
        selectedVerses = [verse]
        showContextMenu = true
    }

    /// Clear all selection state
    func clearSelection() {
        selectedVerses.removeAll()
        selectionMode = .none
        showContextMenu = false
        showInlineInsight = false
        inlineInsightViewModel = nil
        insightSheetRange = nil
    }

    /// Check if a verse is selected
    func isVerseSelected(_ verse: Int) -> Bool {
        selectedVerses.contains(verse)
    }

    // MARK: - Context Menu

    /// Update selection bounds for menu positioning
    func updateSelectionBounds(_ bounds: CGRect, container: CGRect) {
        selectionBounds = bounds
        containerBounds = container
    }

    /// Dismiss context menu without clearing selection
    func dismissContextMenu() {
        showContextMenu = false
    }

    // MARK: - Inline Insights

    /// Open the inline insight card for current selection
    func openInlineInsight() {
        guard let range = selectedRange else { return }

        insightSheetRange = range
        inlineInsightViewModel = InsightViewModel(verseRange: range)
        showInlineInsight = true
        showContextMenu = false

        Task {
            await inlineInsightViewModel?.loadExplanation()
        }
    }

    /// Dismiss inline insight and clear selection
    func dismissInlineInsight() {
        showInlineInsight = false
        clearSelection()
    }

    // MARK: - Highlights

    /// Create a highlight for current selection
    func createHighlight(color: HighlightColor) async {
        guard let range = selectedRange else { return }

        do {
            try await userContentService.createHighlight(for: range, color: color)
            HapticService.shared.verseHighlighted()
            loadUserContent()

            // Store for undo
            if let createdHighlight = chapterHighlights.first(where: {
                $0.verseStart == range.verseStart &&
                $0.verseEnd == range.verseEnd &&
                $0.color == color
            }) {
                lastHighlightAction = ScholarHighlightUndoAction(
                    highlight: createdHighlight,
                    type: .created
                )

                // Show undo toast
                ToastManager.shared.showHighlightToast(
                    color: color,
                    reference: range.reference,
                    onUndo: { [weak self] in
                        await self?.undoLastHighlight()
                    }
                )
            }

            clearSelection()
        } catch {
            self.error = error
        }
    }

    /// Quick highlight with color (replaces existing if present)
    func quickHighlight(color: HighlightColor) async {
        guard selectedRange != nil else { return }

        // Remove existing highlight if present
        if let existing = existingHighlightForSelection {
            do {
                try await userContentService.deleteHighlight(existing)
            } catch {
                self.error = error
                return
            }
        }

        await createHighlight(color: color)
    }

    /// Remove highlight for current selection
    func removeHighlightForSelection() async {
        guard let highlight = existingHighlightForSelection else { return }

        do {
            try await userContentService.deleteHighlight(highlight)
            HapticService.shared.lightTap()
            loadUserContent()
            clearSelection()
        } catch {
            self.error = error
        }
    }

    /// Undo the last highlight action
    func undoLastHighlight() async {
        guard let action = lastHighlightAction else { return }

        do {
            switch action.type {
            case .created:
                try await userContentService.deleteHighlight(action.highlight)
                HapticService.shared.undoAction()
            case .deleted:
                try await userContentService.createHighlight(
                    for: action.highlight.range,
                    color: action.highlight.color,
                    category: action.highlight.category
                )
                HapticService.shared.undoAction()
            case .modified:
                break
            }

            loadUserContent()
            lastHighlightAction = nil
        } catch {
            self.error = error
        }
    }

    // MARK: - Copy & Share

    /// Copy selected verses to clipboard
    func copySelectedVerses() {
        guard let range = selectedRange,
              let chapter = chapter else { return }

        let verses = chapter.verses.filter {
            $0.verse >= range.verseStart && $0.verse <= range.verseEnd
        }
        let text = verses.map { $0.text }.joined(separator: " ")
        let formatted = "\"\(text)\"\n— \(range.reference)"

        UIPasteboard.general.string = formatted
        HapticService.shared.success()
        clearSelection()
    }

    /// Get formatted text for sharing
    func getShareText() -> String? {
        guard let range = selectedRange,
              let chapter = chapter else { return nil }

        let verses = chapter.verses.filter {
            $0.verse >= range.verseStart && $0.verse <= range.verseEnd
        }
        let text = verses.map { $0.text }.joined(separator: " ")
        return "\"\(text)\"\n\n— \(range.reference)"
    }

    // MARK: - User Content

    func loadUserContent() {
        chapterHighlights = userContentService.getHighlights(
            for: currentLocation.chapter,
            bookId: currentLocation.bookId
        )
        chapterNotes = userContentService.getNotes(
            for: currentLocation.chapter,
            bookId: currentLocation.bookId
        )
    }

    func highlightColor(for verseNumber: Int) -> HighlightColor? {
        chapterHighlights.first { highlight in
            verseNumber >= highlight.verseStart && verseNumber <= highlight.verseEnd
        }?.color
    }

    func hasNote(for verseNumber: Int) -> Bool {
        chapterNotes.contains { note in
            verseNumber >= note.verseStart && verseNumber <= note.verseEnd
        }
    }

    // MARK: - Search Navigation

    /// Verse to flash highlight after search navigation
    var flashVerseId: Int?

    /// Navigate to a verse from search results
    func navigateToVerse(_ range: VerseRange) async {
        let location = BibleLocation(
            bookId: range.bookId,
            chapter: range.chapter,
            verse: range.verseStart
        )
        await loadChapter(at: location)
        flashVerseId = range.verseStart
    }

    /// Clear the flash highlight
    func clearFlash() {
        flashVerseId = nil
    }

    // MARK: - Audio

    /// Creates an AudioChapter from the current chapter for playback
    func createAudioChapter() -> AudioChapter? {
        guard let chapter = chapter,
              let book = book else { return nil }

        let translation = currentTranslation?.abbreviation ?? "KJV"

        return AudioChapter(
            location: currentLocation,
            bookName: book.name,
            translation: translation,
            verses: chapter.verses
        )
    }

    /// Start audio playback for current chapter
    func playAudio() async {
        guard let audioChapter = createAudioChapter() else { return }

        await AudioService.shared.loadChapter(audioChapter)
        AudioService.shared.play()
    }
}

// MARK: - Selection Mode

enum ScholarSelectionMode {
    case none
    case single
    case range
}

// MARK: - Highlight Undo Action

struct ScholarHighlightUndoAction {
    let highlight: Highlight
    let type: ActionType

    enum ActionType {
        case created
        case deleted
        case modified
    }
}

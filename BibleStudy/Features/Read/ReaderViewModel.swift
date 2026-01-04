import SwiftUI

// MARK: - Reader View Model
// Manages state for the Bible reader

private let analytics = AnalyticsService.shared

@Observable
@MainActor
final class ReaderViewModel {
    // MARK: - Dependencies
    private let bibleService: BibleService
    private let userContentService: UserContentService
    private let aiService: AIServiceProtocol

    // MARK: - State
    var currentLocation: BibleLocation
    var currentTranslationId: String { bibleService.currentTranslationId }
    var currentTranslation: Translation? { bibleService.currentTranslation }
    var availableTranslations: [Translation] { bibleService.availableTranslations }
    var chapter: Chapter?
    var isLoading: Bool = false
    var error: Error?

    // Selection
    var selectedVerses: Set<Int> = []
    var selectionMode: SelectionMode = .none

    // User Content
    var chapterHighlights: [Highlight] = []
    var chapterNotes: [Note] = []
    var showNoteEditor: Bool = false
    var showHighlightPicker: Bool = false
    var editingNote: Note?

    /// Last highlight action for undo capability
    private(set) var lastHighlightAction: HighlightUndoAction?

    /// All notes for linking in NoteEditor
    var allNotes: [Note] {
        userContentService.notes
    }

    // UI State
    var showInsightSheet: Bool = false
    /// Captured range for insight sheet (prevents race condition with computed selectedRange)
    var insightSheetRange: VerseRange?
    var showBookPicker: Bool = false

    // MARK: - Inline Insight State (New UX)
    /// Current insight display mode (state machine)
    var insightMode: InsightDisplayMode = .none
    /// Whether to show the inline insight card below selected verse
    var showInlineInsight: Bool = false
    /// Whether to show the deep study sheet (Scholar's Codex)
    var showDeepStudySheet: Bool = false
    /// ViewModel for the inline insight card and deep study sheet
    var inlineInsightViewModel: InsightViewModel?
    var showSettings: Bool = false
    var showTranslationPicker: Bool = false
    var activeLens: Lens = .none

    /// Focus Mode: hides study UI for immersive reading
    var isFocusMode: Bool = false

    /// Current visible verse for progress tracking
    var currentVisibleVerse: Int = 1

    /// Flash highlight for search result navigation (verse number to highlight briefly)
    var flashVerseId: Int? = nil

    // MARK: - Quick Insight State
    /// Shows the inline quick insight card above the floating menu
    var showQuickInsight: Bool = false
    /// The quick insight data (summary + key term)
    var quickInsight: QuickInsightOutput?
    /// Whether quick insight is currently loading
    var isLoadingQuickInsight: Bool = false

    // MARK: - Context Preservation State
    /// Verses to keep highlighted after insight sheet dismissal
    var preservedVerses: Set<Int> = []
    /// Opacity for the preserved highlight (fades out)
    var preservedHighlightOpacity: Double = 0.0
    /// Whether to show the "return to insights" pill
    var showReturnToInsightsPill: Bool = false
    /// The verse range that was being studied (for returning)
    var lastStudiedRange: VerseRange?
    /// Task for managing the fade-out timer
    private var preservationFadeTask: Task<Void, Never>?
    /// The last verse range that was opened for inline insights (for cache detection)
    private var lastOpenedInsightRange: VerseRange?

    // Navigation
    var canGoBack: Bool = false
    var canGoForward: Bool = false

    // MARK: - Computed Properties
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

    var book: Book? {
        Book.find(byId: currentLocation.bookId)
    }

    var headerTitle: String {
        guard let book = book else { return "" }
        return "\(book.name) \(currentLocation.chapter)"
    }

    /// Progress subtitle showing verse and chapter position
    var chapterProgressText: String {
        guard let book = book else { return "" }
        let totalVerses = chapter?.verses.count ?? 0
        if totalVerses > 0 {
            return "v.\(currentVisibleVerse) / \(totalVerses) • Ch.\(currentLocation.chapter) of \(book.chapters)"
        }
        return "Chapter \(currentLocation.chapter) of \(book.chapters)"
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

            // Load user content (highlights and notes) for this chapter
            // This ensures highlights are available for rendering when verses are displayed
            loadUserContent()

            // Prefetch audio in background (starts generation before user taps play)
            if let audioChapter = createAudioChapter() {
                AudioService.shared.prefetchChapter(audioChapter)
            }

            // Track chapter read
            if let book = book {
                analytics.trackChapterRead(book: book.name, chapter: currentLocation.chapter)
            }
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

    /// Navigate to a specific verse range (used for search results)
    /// Sets flashVerseId to trigger the flash-on-land animation
    func navigateToVerse(_ range: VerseRange) async {
        let location = BibleLocation(
            bookId: range.bookId,
            chapter: range.chapter,
            verse: range.verseStart
        )
        await loadChapter(at: location)
        // Trigger flash animation on the target verse
        flashVerseId = range.verseStart
    }

    /// Clear the flash highlight (called after animation completes)
    func clearFlash() {
        flashVerseId = nil
    }

    // MARK: - Translation
    func switchTranslation(to translationId: String) async {
        // Only reload chapter if translation change was allowed
        if bibleService.setTranslation(translationId) {
            await loadChapter()
        }
        // If blocked, paywall will be shown automatically by BibleService
    }

    // MARK: - Selection
    func selectVerse(_ verse: Int) {
        if selectionMode == .none {
            selectionMode = .single
        }

        if selectedVerses.contains(verse) {
            selectedVerses.remove(verse)
            if selectedVerses.isEmpty {
                selectionMode = .none
            }
        } else {
            if selectionMode == .single {
                selectedVerses = [verse]
            } else {
                selectedVerses.insert(verse)
            }
        }
    }

    func selectRange(from start: Int, to end: Int) {
        selectionMode = .range
        selectedVerses = Set(min(start, end)...max(start, end))
    }

    func extendSelection(to verse: Int) {
        guard let first = selectedVerses.min() else {
            selectVerse(verse)
            return
        }
        selectionMode = .range
        selectedVerses = Set(min(first, verse)...max(first, verse))
    }

    func clearSelection() {
        selectedVerses.removeAll()
        selectionMode = .none
        showInsightSheet = false
        // Clear quick insight state
        showQuickInsight = false
        quickInsight = nil
        isLoadingQuickInsight = false
        // Clear inline insight state
        clearInlineInsightState()
    }

    // MARK: - Actions

    /// Legacy method - opens inline insight instead
    /// Deprecated: Use openInlineInsight() or openDeepStudySheet() directly
    func openInsights() {
        openInlineInsight()
    }

    // MARK: - Inline Insight Transitions (New UX)

    /// Opens the inline insight card below the selected verse
    /// Called when user taps the insight area in the context menu
    func openInlineInsight() {
        guard let range = selectedRange else { return }

        // Pause audio if playing (will remember state for resume)
        AudioService.shared.pauseForInterruption()

        // Capture the range
        insightSheetRange = range

        // Check if this is the same verse as before
        let isSameVerse = (lastOpenedInsightRange == range)

        // Only create a new InsightViewModel if the verse changed
        if !isSameVerse || inlineInsightViewModel == nil {
            inlineInsightViewModel = InsightViewModel(verseRange: range)
        }

        // Update tracking
        lastOpenedInsightRange = range

        // Transition: context menu → inline card
        insightMode = .inlineCard
        showInlineInsight = true

        // Dismiss quick insight (context menu will hide automatically)
        showQuickInsight = false

        // Load the explanation content
        // Only force refresh if the verse changed (use cache for same verse)
        Task {
            await inlineInsightViewModel?.loadExplanation(forceRefresh: !isSameVerse)
        }
    }

    /// Opens the deep study sheet (Scholar's Codex) from the inline card
    func openDeepStudySheet() {
        guard let range = insightSheetRange ?? selectedRange else { return }

        // Ensure we have a view model
        if inlineInsightViewModel?.verseRange != range {
            inlineInsightViewModel = InsightViewModel(verseRange: range)
        }

        // Transition to deep study mode
        insightMode = .deepStudySheet
        showDeepStudySheet = true
    }

    /// Dismisses the inline insight card and clears selection
    /// This prevents the context menu from reappearing after dismissal
    func dismissInlineInsight() {
        showInlineInsight = false
        clearSelection()
        insightMode = .none

        // Resume audio if it was playing before insight appeared
        AudioService.shared.resumeAfterInterruption()
    }

    /// Dismisses the deep study sheet
    func dismissDeepStudySheet() {
        showDeepStudySheet = false
        // Return to inline card if verses still selected, otherwise none
        if showInlineInsight {
            insightMode = .inlineCard
        } else {
            insightMode = selectedVerses.isEmpty ? .none : .contextMenu
        }
    }

    /// Clears all insight state (called when selection changes to different verse)
    func clearInlineInsightState() {
        showInlineInsight = false
        showDeepStudySheet = false
        insightMode = .none
        inlineInsightViewModel = nil
        lastOpenedInsightRange = nil
    }

    // MARK: - Quick Insight
    /// Loads a brief AI insight preview for the selected verses
    func loadQuickInsight() async {
        guard let range = selectedRange,
              !isLoadingQuickInsight else { return }

        isLoadingQuickInsight = true
        showQuickInsight = true

        // Get verse text
        do {
            let verses = try await bibleService.getVerses(range: range)
            let verseText = verses.map { $0.text }.joined(separator: " ")

            // Check cache first
            let cache = AIResponseCache.shared
            let translationId = currentTranslationId
            if let cached = cache.getQuickInsight(for: range, translationId: translationId) {
                quickInsight = cached
                isLoadingQuickInsight = false
                return
            }

            // Generate new quick insight
            let insight = try await aiService.generateQuickInsight(verseRange: range, verseText: verseText)
            quickInsight = insight

            // Cache the result
            cache.cacheQuickInsight(insight, for: range, translationId: translationId)
        } catch {
            // On error, show a fallback insight
            quickInsight = QuickInsightOutput(
                summary: "Tap \"Explain\" to explore the meaning and context of this passage.",
                keyTerm: nil,
                keyTermMeaning: nil,
                suggestedAction: .explainMore
            )
        }

        isLoadingQuickInsight = false
    }

    /// Dismisses the quick insight card
    func dismissQuickInsight() {
        showQuickInsight = false
    }

    // MARK: - Context Preservation
    /// Called when the insight sheet is dismissed - preserves selection briefly
    func handleInsightSheetDismiss() {
        // Cancel any existing fade task
        preservationFadeTask?.cancel()

        // Store the current selection for preservation
        guard !selectedVerses.isEmpty else { return }

        preservedVerses = selectedVerses
        lastStudiedRange = selectedRange
        preservedHighlightOpacity = 0.15

        // Clear the active selection
        selectedVerses.removeAll()
        selectionMode = .none
        showQuickInsight = false

        // Start the fade-out timer (3 seconds)
        preservationFadeTask = Task {
            // Subtle pulse animation before fade
            try? await Task.sleep(for: .milliseconds(500))

            // Begin fade out over 2.5 seconds
            for step in 0..<25 {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .milliseconds(100))
                await MainActor.run {
                    preservedHighlightOpacity = 0.15 * (1 - Double(step) / 25.0)
                }
            }

            // Final cleanup
            await MainActor.run {
                clearPreservedContext()
            }
        }
    }

    /// Returns to the insights for the preserved selection
    func returnToPreservedInsights() {
        guard let range = lastStudiedRange else { return }

        // Cancel the fade
        preservationFadeTask?.cancel()

        // Restore selection
        selectedVerses = Set(range.verseStart...range.verseEnd)
        selectionMode = selectedVerses.count > 1 ? .range : .single

        // Clear preservation state
        preservedVerses.removeAll()
        preservedHighlightOpacity = 0
        showReturnToInsightsPill = false

        // Reopen inline insight
        openInlineInsight()
    }

    /// Clears all preserved context state
    func clearPreservedContext() {
        preservationFadeTask?.cancel()
        preservedVerses.removeAll()
        preservedHighlightOpacity = 0
        showReturnToInsightsPill = false
        lastStudiedRange = nil
    }

    /// Called when user scrolls away from preserved verses
    func userScrolledAwayFromPreservedVerses() {
        if !preservedVerses.isEmpty && preservedHighlightOpacity > 0 {
            showReturnToInsightsPill = true
        }
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

    func setLens(_ lens: Lens) {
        if activeLens == lens {
            activeLens = .none
        } else {
            activeLens = lens
        }
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

    /// Returns the highlight color for the currently selected verse range, if any
    var existingHighlightColorForSelection: HighlightColor? {
        guard let range = selectedRange else { return nil }
        return chapterHighlights.first { highlight in
            highlight.verseStart == range.verseStart &&
            highlight.verseEnd == range.verseEnd
        }?.color
    }

    /// Returns the highlight for the currently selected verse range, if any
    var existingHighlightForSelection: Highlight? {
        guard let range = selectedRange else { return nil }
        return chapterHighlights.first { highlight in
            highlight.verseStart == range.verseStart &&
            highlight.verseEnd == range.verseEnd
        }
    }

    func hasNote(for verseNumber: Int) -> Bool {
        chapterNotes.contains { note in
            verseNumber >= note.verseStart && verseNumber <= note.verseEnd
        }
    }

    func createHighlight(color: HighlightColor) async {
        guard let range = selectedRange else { return }

        do {
            try await userContentService.createHighlight(for: range, color: color)
            HapticService.shared.verseHighlighted()
            loadUserContent()

            // Store for undo and show toast
            if let createdHighlight = chapterHighlights.first(where: {
                $0.verseStart == range.verseStart &&
                $0.verseEnd == range.verseEnd &&
                $0.color == color
            }) {
                lastHighlightAction = HighlightUndoAction(
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

            // Track highlight created
            analytics.trackHighlightCreated(reference: range.reference, color: color.rawValue)
        } catch {
            self.error = error
        }
    }

    func deleteHighlight(_ highlight: Highlight) async {
        do {
            try await userContentService.deleteHighlight(highlight)
            loadUserContent()
        } catch {
            self.error = error
        }
    }

    /// Removes the highlight for the currently selected verse range
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

    /// Applies a highlight with the given color to the current selection
    /// If there's an existing highlight, it will be replaced
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

        // Create new highlight
        await createHighlight(color: color)
    }

    /// Undoes the last highlight action
    func undoLastHighlight() async {
        guard let action = lastHighlightAction else { return }

        do {
            switch action.type {
            case .created:
                // Delete the highlight that was created
                try await userContentService.deleteHighlight(action.highlight)
                HapticService.shared.undoAction()

            case .deleted:
                // Recreate the highlight that was deleted
                try await userContentService.createHighlight(
                    for: action.highlight.range,
                    color: action.highlight.color,
                    category: action.highlight.category
                )
                HapticService.shared.undoAction()

            case .modified:
                // Revert to previous state (not yet implemented)
                break
            }

            loadUserContent()
            lastHighlightAction = nil
        } catch {
            self.error = error
        }
    }

    /// Clears the last highlight action (called when undo is no longer available)
    func clearLastHighlightAction() {
        lastHighlightAction = nil
    }

    func openNoteEditor() {
        guard let range = selectedRange else { return }
        // Check if there's an existing note for this selection
        editingNote = chapterNotes.first { note in
            note.range == range
        }
        showNoteEditor = true
    }

    func saveNote(content: String, template: NoteTemplate, linkedNoteIds: [UUID] = []) async {
        guard let range = selectedRange else { return }

        do {
            if var existingNote = editingNote {
                existingNote.content = content
                existingNote.template = template
                existingNote.linkedNoteIds = linkedNoteIds
                existingNote.updatedAt = Date()
                existingNote.needsSync = true
                try await userContentService.updateNote(existingNote)
            } else {
                try await userContentService.createNote(for: range, content: content, template: template, linkedNoteIds: linkedNoteIds)

                // Track note created
                analytics.trackNoteCreated(reference: range.reference, template: template.rawValue)
            }
            loadUserContent()
            clearSelection()
            editingNote = nil
        } catch {
            self.error = error
        }
    }

    func deleteNote(_ note: Note) async {
        do {
            try await userContentService.deleteNote(note)
            loadUserContent()
            editingNote = nil
        } catch {
            self.error = error
        }
    }
}

// MARK: - Selection Mode
enum SelectionMode {
    case none
    case single
    case range
}

// MARK: - Highlight Undo Action
/// Stores information needed to undo a highlight action
struct HighlightUndoAction {
    let highlight: Highlight
    let type: ActionType

    enum ActionType {
        case created   // Can undo by deleting
        case deleted   // Can undo by recreating
        case modified  // Can undo by reverting to previous state
    }
}

// MARK: - Insight Display Mode
/// State machine for insight display transitions
enum InsightDisplayMode: Equatable {
    /// No insight UI visible
    case none
    /// Floating context menu showing (IlluminatedContextMenu)
    case contextMenu
    /// Inline insight card expanded below verse (InlineInsightCard)
    case inlineCard
    /// Full deep study sheet modal (DeepStudySheet)
    case deepStudySheet
}

// MARK: - Lens Types
enum Lens: String, CaseIterable {
    case none
    case context
    case crossRefs
    case language
    case interpretation
    case understand  // Phase 5: Comprehension

    var title: String {
        switch self {
        case .none: return "None"
        case .context: return "Context"
        case .crossRefs: return "Cross-refs"
        case .language: return "Language"
        case .interpretation: return "Interpretation"
        case .understand: return "Understand"
        }
    }

    var icon: String {
        switch self {
        case .none: return "eye.slash"
        case .context: return "text.alignleft"
        case .crossRefs: return "arrow.triangle.branch"
        case .language: return "character.book.closed"
        case .interpretation: return "text.magnifyingglass"
        case .understand: return "graduationcap"
        }
    }

    /// Maps to consolidated InsightTab (4-tab structure) for sheet navigation
    var insightTab: InsightTab {
        switch self {
        case .none: return .insight          // Default to Insight tab (explanation mode)
        case .context: return .context       // Context tab (now includes cross-refs)
        case .crossRefs: return .context     // Merged into Context tab
        case .language: return .language     // Language tab (promoted to primary)
        case .interpretation: return .insight // Merged into Insight tab (Views mode)
        case .understand: return .insight    // Merged into Insight tab (Understand mode)
        }
    }
}

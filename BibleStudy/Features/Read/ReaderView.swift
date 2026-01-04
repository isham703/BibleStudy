import SwiftUI
import UIKit

// MARK: - Reader View
// The main Bible reading interface

struct ReaderView: View {
    @Environment(AppState.self) private var appState
    @Environment(BibleService.self) private var bibleService
    @State private var viewModel: ReaderViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var isNavigating: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var shareText: String = ""
    @State private var memorizationFeedback: MemorizationFeedback?
    @State private var showCollectionPicker: Bool = false
    @State private var collectionFeedback: CollectionFeedback?
    @State private var showSearchSheet: Bool = false
    @State private var flashOpacity: Double = 1.0
    @State private var showAppSettings: Bool = false

    // Floating context menu positioning
    @State private var selectionBounds: CGRect? = nil

    // First-use swipe hint
    @AppStorage("hasSeenSwipeHint") private var hasSeenSwipeHint: Bool = false
    @State private var showSwipeHint: Bool = false
    @State private var hintOpacity: Double = 0

    // First-use insight hint (shows after onboarding to teach verse tapping)
    @AppStorage("hasSeenInsightHint") private var hasSeenInsightHint: Bool = false
    @State private var showInsightHint: Bool = false
    @State private var insightHintOpacity: Double = 0

    // First-use reading menu hint (shows to teach new chrome pattern)
    @AppStorage("hasSeenReadingMenuHint") private var hasSeenReadingMenuHint: Bool = false
    @State private var showReadingMenuHint: Bool = false
    @State private var readingMenuHintOpacity: Double = 0

    // Recent chapters for Contents sheet
    @State private var recentChapters: [RecentChapter] = []

    // Audio playback
    @State private var audioService = AudioService.shared
    @State private var currentPlayingVerse: Int? = nil

    // Page mode (e-reader style with page curl)
    @AppStorage(AppConfiguration.UserDefaultsKeys.usePagedReader) private var usePagedReader: Bool = false

    // Chrome visibility (top bar + FAB hide on scroll)
    @State private var showChrome: Bool = true

    private let memorizationService = MemorizationService.shared
    private let collectionService = StudyCollectionService.shared


    init() {
        _viewModel = State(initialValue: ReaderViewModel())
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        GeometryReader { _ in
            ZStack {
                // Background (theme-aware: sepia/OLED use custom colors)
                (appState.preferredTheme.customBackground ?? Color.appBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if usePagedReader {
                        // Page Mode: E-reader style with page curl
                        PagedReaderView(viewModel: viewModel)
                    } else {
                        // Scroll Mode: Traditional scrolling (extracted component)
                        ScrollModeReaderContent(
                            viewModel: viewModel,
                            onSelectVerse: { verseNum in
                                dismissInsightHint()
                                // Toggle: if tapping the same verse with insight showing, dismiss it
                                if viewModel.selectedVerses.count == 1,
                                   viewModel.selectedVerses.contains(verseNum),
                                   viewModel.showInlineInsight {
                                    viewModel.dismissInlineInsight()
                                    viewModel.clearSelection()
                                } else {
                                    viewModel.selectVerse(verseNum)
                                    appState.saveScrollPosition(verse: verseNum)
                                    // Open inline insight directly (skip context menu)
                                    viewModel.openInlineInsight()
                                }
                            },
                            onLongPressVerse: { verseNum in
                                dismissInsightHint()
                                viewModel.selectVerse(verseNum)
                                viewModel.selectionMode = .range
                                appState.saveScrollPosition(verse: verseNum)
                                // Open inline insight directly (same as single tap)
                                viewModel.openInlineInsight()
                            },
                            onDoubleTapVerse: { verseNum in
                                dismissInsightHint()
                                viewModel.clearPreservedContext()
                                if !viewModel.selectedVerses.contains(verseNum) {
                                    viewModel.selectVerse(verseNum)
                                }
                                appState.saveScrollPosition(verse: verseNum)
                                // Open inline insight for quick access
                                viewModel.openInlineInsight()
                            },
                            onVisibleVerseChange: { verse in
                                viewModel.currentVisibleVerse = verse
                            },
                            onSelectionBoundsChange: { bounds in
                                selectionBounds = bounds
                            },
                            onFlashAnimationComplete: {
                                viewModel.clearFlash()
                            },
                            onChapterChange: {},
                            onSwipeNavigate: { direction in
                                dismissSwipeHint()
                                switch direction {
                                case .previous:
                                    await viewModel.goToPreviousChapter()
                                case .next:
                                    await viewModel.goToNextChapter()
                                }
                            },
                            onScrollDirectionChange: { direction in
                                // Chrome visibility with premium spring animation
                                withAnimation(AppTheme.Animation.spring) {
                                    showChrome = direction == .up
                                }
                            },
                            currentPlayingVerse: currentPlayingVerse,
                            dragOffset: $dragOffset,
                            isNavigating: $isNavigating,
                            flashOpacity: $flashOpacity,
                            showChrome: showChrome
                        )
                    } // End of else (scroll mode)

                }

                // Floating Context Menu (positioned above selected verse)
                // Hidden in Focus Mode for immersive reading
                // Also hidden when inline insight is showing
                if let range = viewModel.selectedRange,
                   let bounds = selectionBounds,
                   !viewModel.isFocusMode,
                   !viewModel.showInlineInsight {
                    floatingContextMenuContent(range: range, bounds: bounds)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.85, anchor: .bottom).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                }

                // InlineInsightCard is now rendered INLINE within ScrollModeReaderContent
                // (inserted directly after the selected verse in the scroll content)
            }

            // Loading Overlay
            if viewModel.isLoading {
                LoadingView()
            }

            // Error Overlay
            if let error = viewModel.error {
                ErrorView(error: error) {
                    Task {
                        await viewModel.loadChapter()
                    }
                }
            }

            // First-use swipe hint overlay
            if showSwipeHint {
                SwipeHintOverlay(opacity: hintOpacity)
            }

            // First-use insight hint overlay (teaches verse tapping)
            if showInsightHint {
                InsightHintOverlay(opacity: insightHintOpacity)
            }

            // First-use reading menu hint overlay (teaches new chrome pattern)
            if showReadingMenuHint {
                ReadingMenuHintOverlay(opacity: readingMenuHintOpacity)
            }

            // MARK: - Return to Insights Pill (Context Preservation)
            if viewModel.showReturnToInsightsPill {
                VStack {
                    Spacer()
                    returnToInsightsPill
                        .padding(.bottom, AppTheme.Spacing.xxxl)
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(y: 20)),
                    removal: .opacity
                ))
            }

            // Immersive reader chrome (Apple Books-style)
            immersiveReaderOverlay
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true) // Hide nav bar for immersive reading
        .sheet(isPresented: $viewModel.showBookPicker) {
            BookPickerView(
                currentBookId: viewModel.currentLocation.bookId,
                currentChapter: viewModel.currentLocation.chapter
            ) { bookId, chapter in
                Task {
                    await viewModel.goToBook(bookId, chapter: chapter)
                }
            }
        }
        .sheet(isPresented: $showSearchSheet) {
            NavigationStack {
                SearchView { range in
                    showSearchSheet = false
                    Task {
                        await viewModel.navigateToVerse(range)
                    }
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showSettings) {
            ThemesSettingsSheet()
        }
        // MARK: - Deep Study Sheet (Scholar's Codex - New UX)
        .sheet(isPresented: $viewModel.showDeepStudySheet, onDismiss: {
            viewModel.dismissDeepStudySheet()
        }) {
            if let range = viewModel.insightSheetRange ?? viewModel.selectedRange,
               let insightVM = viewModel.inlineInsightViewModel {
                DeepStudySheet(
                    verseRange: range,
                    viewModel: insightVM,
                    onNavigate: { targetRange in
                        // Navigate to cross-referenced verse
                        viewModel.showDeepStudySheet = false
                        viewModel.clearSelection()
                        Task {
                            let location = BibleLocation(
                                bookId: targetRange.bookId,
                                chapter: targetRange.chapter,
                                verse: targetRange.verseStart
                            )
                            await viewModel.loadChapter(at: location)
                        }
                    },
                    onDismiss: {
                        viewModel.dismissDeepStudySheet()
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $viewModel.showTranslationPicker) {
            TranslationPickerView(
                currentTranslationId: viewModel.currentTranslationId,
                translations: viewModel.availableTranslations
            ) { translationId in
                Task {
                    await viewModel.switchTranslation(to: translationId)
                }
            }
        }
        // Legacy InsightSheetView removed - replaced by InlineInsightCard + DeepStudySheet
        .task {
            viewModel.currentLocation = appState.currentLocation
            await viewModel.loadChapter()

            // Show swipe hint for first-time users
            if !hasSeenSwipeHint && viewModel.chapter != nil {
                showSwipeHint = true
                // Fade in the hint
                withAnimation(AppTheme.Animation.slow.delay(0.5)) {
                    hintOpacity = 1.0
                }
                // Auto-dismiss after 4 seconds if user doesn't swipe
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                if showSwipeHint {
                    withAnimation(AppTheme.Animation.standard) {
                        hintOpacity = 0
                    }
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    showSwipeHint = false
                    hasSeenSwipeHint = true
                }
            }

            // Show insight hint after swipe hint (or immediately if swipe hint already seen)
            if !hasSeenInsightHint && viewModel.chapter != nil && !showSwipeHint {
                // Small delay to let user orient
                try? await Task.sleep(nanoseconds: 500_000_000)
                showInsightHint = true
                withAnimation(AppTheme.Animation.slow) {
                    insightHintOpacity = 1.0
                }
                // Auto-dismiss after 5 seconds
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                dismissInsightHint()
            }

            // Show reading menu hint after other hints (teaches new Apple Books-style chrome)
            if !hasSeenReadingMenuHint && viewModel.chapter != nil && !showSwipeHint && !showInsightHint {
                // Small delay to let user orient
                try? await Task.sleep(nanoseconds: 800_000_000)
                showReadingMenuHint = true
                withAnimation(AppTheme.Animation.slow) {
                    readingMenuHintOpacity = 1.0
                }
                // Auto-dismiss after 6 seconds
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                dismissReadingMenuHint()
            }
        }
        .onChange(of: viewModel.currentLocation) { _, newLocation in
            appState.saveLocation(newLocation)
        }
        .animation(AppTheme.Animation.standard, value: viewModel.selectedVerses)
        .animation(AppTheme.Animation.sacredSpring, value: viewModel.showInlineInsight)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
        .sheet(isPresented: $viewModel.showNoteEditor) {
            if let range = viewModel.selectedRange {
                NoteEditor(
                    range: range,
                    existingNote: viewModel.editingNote,
                    allNotes: viewModel.allNotes,
                    onSave: { content, template, linkedNoteIds in
                        Task {
                            await viewModel.saveNote(content: content, template: template, linkedNoteIds: linkedNoteIds)
                        }
                    },
                    onDelete: viewModel.editingNote != nil ? {
                        Task {
                            if let note = viewModel.editingNote {
                                await viewModel.deleteNote(note)
                            }
                        }
                    } : nil
                )
            }
        }
        .overlay(alignment: .top) {
            if let feedback = memorizationFeedback {
                MemorizationFeedbackToast(feedback: feedback)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(AppTheme.Animation.spring, value: memorizationFeedback)
            }
        }
        .overlay(alignment: .top) {
            if let feedback = collectionFeedback {
                CollectionFeedbackToast(feedback: feedback)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(AppTheme.Animation.spring, value: collectionFeedback)
            }
        }
        .sheet(isPresented: $showCollectionPicker) {
            if let range = viewModel.selectedRange {
                AddToCollectionSheet(range: range) { collection in
                    addToCollection(range: range, collection: collection)
                }
            }
        }
        .sheet(isPresented: $showAppSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkSearchRequested)) { notification in
            // Open search sheet, optionally with a pre-filled query
            if let query = notification.userInfo?["query"] as? String {
                // Store query for SearchView to pick up
                UserDefaults.standard.set(query, forKey: "pendingSearchQuery")
            }
            showSearchSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkSettingsRequested)) { _ in
            showAppSettings = true
        }
        // Audio verse change listener
        .onReceive(NotificationCenter.default.publisher(for: .audioVerseChanged)) { notification in
            guard let verse = notification.userInfo?["verse"] as? Int else { return }
            let bookId = notification.userInfo?["bookId"] as? Int
            let chapter = notification.userInfo?["chapter"] as? Int
            let translation = notification.userInfo?["translation"] as? String
            let matchesLocation = bookId == viewModel.currentLocation.bookId &&
                chapter == viewModel.currentLocation.chapter
            let expectedTranslation = viewModel.currentTranslation?.abbreviation ?? "KJV"
            let matchesTranslation = translation == nil || translation == expectedTranslation

            if matchesLocation && matchesTranslation {
                currentPlayingVerse = verse
            } else {
                currentPlayingVerse = nil
            }
        }
        .onChange(of: viewModel.currentLocation) { _, _ in
            currentPlayingVerse = nil
        }
        // Clear audio highlight when audio stops
        .onChange(of: audioService.playbackState) { _, newState in
            if newState == .idle || newState == .finished {
                currentPlayingVerse = nil
            }
        }
        // MARK: - Toast Presenter (Undo Toasts)
        .toastPresenter()
    }

    // MARK: - Return to Insights Pill (Context Preservation)

    private var returnToInsightsPill: some View {
        Button(action: {
            withAnimation(AppTheme.Animation.spring) {
                viewModel.returnToPreservedInsights()
            }
        }) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(Typography.UI.iconSm)

                Text("Return to insights")
                    .font(Typography.UI.chipLabel)

                Image(systemName: "chevron.right")
                    .font(Typography.UI.iconXxs)
            }
            .foregroundStyle(Color.accentGold)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(Color.elevatedBackground)
            )
            .overlay(
                Capsule()
                    .stroke(Color.divineGold, lineWidth: AppTheme.Border.thin)
            )
            .shadow(AppTheme.Shadow.goldGlow)
        }
        .accessibilityLabel("Return to insights")
        .accessibilityHint("Reopens the insight sheet for the previously selected verses")
    }

    // MARK: - Immersive Reader Overlay (Apple Books-style)

    @ViewBuilder
    private var immersiveReaderOverlay: some View {
        // Only show when not in focus mode AND no verses selected
        // (Context menu handles all actions when verses are selected)
        if !viewModel.isFocusMode && viewModel.selectedRange == nil {
            // Top bar (floats above content, positioned at top)
            if !usePagedReader {
                VStack {
                    ReaderTopBar(
                        bookName: viewModel.book?.name ?? "Loading",
                        chapter: viewModel.currentLocation.chapter,
                        translationName: viewModel.currentTranslation?.abbreviation ?? "KJV",
                        isVisible: showChrome,
                        isAudioPlaying: audioService.isPlaying,
                        onBookTap: {
                            HapticService.shared.lightTap()
                            viewModel.showBookPicker = true
                        },
                        onTranslationTap: {
                            HapticService.shared.lightTap()
                            viewModel.showTranslationPicker = true
                        },
                        onSettingsTap: {
                            HapticService.shared.lightTap()
                            viewModel.showSettings = true
                        },
                        onVoiceTap: {
                            HapticService.shared.buttonPress()
                            Task { await viewModel.playAudio() }
                        },
                        onSearchTap: {
                            HapticService.shared.lightTap()
                            showSearchSheet = true
                        }
                    )
                    Spacer()
                }
            }
        }
    }


    // MARK: - Selection Toolbar Content

    /// Floating context menu that appears above selected verse
    /// Uses IlluminatedContextMenu - a unified manuscript-styled component
    /// Merges quick insight preview with action buttons in one elegant panel
    @ViewBuilder
    private func floatingContextMenuContent(range: VerseRange, bounds: CGRect) -> some View {
        GeometryReader { geometry in
            IlluminatedContextMenu(
                verseRange: range,
                selectionBounds: bounds,
                containerBounds: geometry.frame(in: .global),
                safeAreaInsets: geometry.safeAreaInsets,
                existingHighlightColor: viewModel.existingHighlightColorForSelection,
                insight: viewModel.quickInsight,
                isInsightLoading: viewModel.isLoadingQuickInsight,
                isLimitReached: !EntitlementManager.shared.canUseAIInsights,
                onCopy: {
                    copySelectedVerses()
                },
                onHighlight: { color in
                    Task {
                        await viewModel.quickHighlight(color: color)
                    }
                },
                onStudy: {
                    // Fallback: open deep study sheet directly
                    viewModel.openDeepStudySheet()
                },
                onOpenInlineInsight: {
                    viewModel.openInlineInsight()
                },
                onShare: {
                    prepareShareText()
                    showShareSheet = true
                },
                onNote: {
                    viewModel.openNoteEditor()
                },
                onAddToCollection: {
                    showCollectionPicker = true
                },
                onRemoveHighlight: {
                    Task {
                        await viewModel.removeHighlightForSelection()
                    }
                },
                onDismiss: {
                    viewModel.clearSelection()
                }
            )
        }
    }

    /// Handles quick insight action chip taps (legacy - kept for compatibility)
    private func handleQuickInsightAction(_ action: QuickInsightAction) {
        // Open inline insight for quick access
        viewModel.openInlineInsight()
    }

    // Legacy selection toolbar content (kept for backwards compatibility, can be removed)
    @ViewBuilder
    private var selectionToolbarContent: some View {
        if let range = viewModel.selectedRange {
            SelectionToolbar(
                range: range,
                onCopy: {
                    copySelectedVerses()
                },
                onShare: {
                    prepareShareText()
                    showShareSheet = true
                },
                onHighlight: {
                    viewModel.showHighlightPicker = true
                },
                onNote: {
                    viewModel.openNoteEditor()
                },
                onStudy: { viewModel.openInlineInsight() },
                onMemorize: {
                    addToMemorization()
                },
                onAddToCollection: {
                    showCollectionPicker = true
                },
                onClear: { viewModel.clearSelection() }
            )
        }
    }

    // MARK: - Copy & Share Helpers

    private func getSelectedVersesText() -> String {
        guard let range = viewModel.selectedRange,
              let chapter = viewModel.chapter else { return "" }

        let verses = chapter.verses.filter { verse in
            verse.verse >= range.verseStart && verse.verse <= range.verseEnd
        }

        return verses.map { $0.text }.joined(separator: " ")
    }

    private func copySelectedVerses() {
        guard let range = viewModel.selectedRange else { return }

        let verseText = getSelectedVersesText()
        let formattedText = "\"\(verseText)\"\n— \(range.reference)"

        UIPasteboard.general.string = formattedText

        // Haptic feedback
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)

        // Clear selection after copy
        viewModel.clearSelection()
    }

    private func prepareShareText() {
        guard let range = viewModel.selectedRange else { return }

        let verseText = getSelectedVersesText()
        shareText = "\"\(verseText)\"\n\n— \(range.reference)"
    }

    private func shareChapter() {
        guard let chapter = viewModel.chapter,
              let book = viewModel.book else { return }

        // Compile full chapter text
        let verseTexts = chapter.verses.map { "\($0.verse). \($0.text)" }.joined(separator: "\n")
        let reference = "\(book.name) \(viewModel.currentLocation.chapter)"
        shareText = "\(reference)\n\n\(verseTexts)\n\n— \(viewModel.currentTranslation?.name ?? "KJV")"
        showShareSheet = true
    }

    // MARK: - Memorization

    private func addToMemorization() {
        guard let range = viewModel.selectedRange else { return }

        let verseText = getSelectedVersesText()

        Task {
            do {
                try await memorizationService.addItem(range: range, verseText: verseText)

                // Haptic feedback
                HapticService.shared.bookmarkAdded()

                memorizationFeedback = .added(reference: range.reference)

                // Clear selection
                viewModel.clearSelection()

                // Auto-dismiss feedback after 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                memorizationFeedback = nil

            } catch MemorizationError.alreadyExists {
                memorizationFeedback = .alreadyExists(reference: range.reference)

                try? await Task.sleep(nanoseconds: 2_000_000_000)
                memorizationFeedback = nil

            } catch {
                memorizationFeedback = .error(message: error.localizedDescription)

                try? await Task.sleep(nanoseconds: 2_000_000_000)
                memorizationFeedback = nil
            }
        }
    }

    // MARK: - Swipe Hint

    private func dismissSwipeHint() {
        guard showSwipeHint else { return }
        withAnimation(AppTheme.Animation.quick) {
            hintOpacity = 0
        }
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            showSwipeHint = false
            hasSeenSwipeHint = true
        }
    }

    // MARK: - Insight Hint

    private func dismissInsightHint() {
        guard showInsightHint else { return }
        withAnimation(AppTheme.Animation.quick) {
            insightHintOpacity = 0
        }
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            showInsightHint = false
            hasSeenInsightHint = true
        }
    }

    // MARK: - Reading Menu Hint

    private func dismissReadingMenuHint() {
        guard showReadingMenuHint else { return }
        withAnimation(AppTheme.Animation.quick) {
            readingMenuHintOpacity = 0
        }
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            showReadingMenuHint = false
            hasSeenReadingMenuHint = true
        }
    }

    // MARK: - Add to Collection

    private func addToCollection(range: VerseRange, collection: StudyCollection) {
        Task {
            do {
                try await collectionService.addVerseToCollection(collection, range: range)

                // Haptic feedback
                let feedback = UINotificationFeedbackGenerator()
                feedback.notificationOccurred(.success)

                collectionFeedback = .added(reference: range.reference, collectionName: collection.name)

                // Clear selection
                viewModel.clearSelection()

                // Auto-dismiss feedback after 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                collectionFeedback = nil

            } catch CollectionError.itemAlreadyExists {
                collectionFeedback = .alreadyExists(reference: range.reference, collectionName: collection.name)

                try? await Task.sleep(nanoseconds: 2_000_000_000)
                collectionFeedback = nil

            } catch {
                collectionFeedback = .error(message: error.localizedDescription)

                try? await Task.sleep(nanoseconds: 2_000_000_000)
                collectionFeedback = nil
            }
        }
    }
}

// MARK: - Extracted Components
// The following types have been extracted for better maintainability:
// - CollectionFeedback, CollectionFeedbackToast, MemorizationFeedback, MemorizationFeedbackToast, ShareSheet → ReaderFeedbackToasts.swift
// - AddToCollectionSheet → AddToCollectionSheet.swift
// - SwipeHintOverlay, InsightHintOverlay, ReadingMenuHintOverlay → ReaderHintOverlays.swift
// - ScrollModeReaderContent → ScrollModeReaderContent.swift

// MARK: - Preview
#Preview {
    NavigationStack {
        ReaderView()
    }
    .environment(AppState())
    .environment(BibleService.shared)
}

import SwiftUI
import UIKit

// MARK: - Bible Reader View
// Bible reader orchestrator with verse-by-verse layout
// Coordinates: BibleChapterHeader, BibleVerseRow, BibleChapterFooter, BibleContextMenuOverlay

struct BibleReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(AppState.self) private var appState
    @State private var viewModel: BibleReaderViewModel?
    @State private var isVisible = false
    @State private var showBookPicker = false
    @State private var showReadingMenu = false
    @State private var showAudioPlayer = false
    @State private var scrollProxy: ScrollViewProxy?

    // Chrome auto-hide state (ritual reading mode)
    @State private var showToolbar = true

    // Audio state
    @State private var audioService = AudioService.shared
    @State private var currentPlayingVerse: Int?

    // Search flash state
    @State private var flashOpacity: Double = 1.0

    // Insight Sheet state
    @State private var showInsightSheet = false
    @State private var insightSheetVerse: Verse?
    @State private var insightSheetInsights: [BibleInsight] = []
    @State private var insightSheetVerseInsightCounts: [Int: Int] = [:]

    // Chapter panel state
    @State private var showChapterPanel = false

    // Persist last reading position
    @AppStorage("scholarLastBookId") private var lastBookId: Int = 43
    @AppStorage("scholarLastChapter") private var lastChapter: Int = 1

    let initialLocation: BibleLocation?

    init(location: BibleLocation? = nil) {
        self.initialLocation = location
    }

    private var isUITestingReader: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui_testing_reader")
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    // Background with tap to dismiss
                    Color.appBackground
                        .ignoresSafeArea()
                        .onTapGesture {
                            if let viewModel = viewModel, viewModel.showContextMenu {
                                withAnimation(Theme.Animation.fade) {
                                    viewModel.clearSelection()
                                }
                            }
                        }

                    // Main content
                    if let viewModel = viewModel {
                        mainContent(viewModel: viewModel, geometry: geometry)
                    } else {
                        loadingView
                    }
                }
                .coordinateSpace(name: "scholarReader")
            }

            // Chapter panel overlay
            if let viewModel = viewModel, let book = viewModel.book {
                ChapterSidePanel(
                    book: book,
                    currentChapter: viewModel.currentLocation.chapter,
                    isPresented: $showChapterPanel,
                    onSelectChapter: { chapter in
                        Task { await viewModel.goToChapter(chapter) }
                    }
                )
            }
        }
        .simultaneousGesture(chapterPanelSwipeGesture)
        .toolbar {
            // Leading: Reading menu button
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    HapticService.shared.lightTap()
                    showReadingMenu = true
                } label: {
                    Image(systemName: "textformat.size")
                        .font(Typography.Icon.md.weight(.medium))
                }
                .accessibilityLabel("Reading settings")
                .accessibilityIdentifier("ReaderToolbarReadingMenuButton")
            }

            // Center: Chapter selector button
            ToolbarItem(placement: .principal) {
                if let viewModel = viewModel {
                    BibleChapterMenuButton(
                        currentBook: viewModel.book,
                        currentChapter: viewModel.currentLocation.chapter,
                        onTap: { showBookPicker = true }
                    )
                }
            }

            // Trailing: Chapter panel toggle
            ToolbarItem(placement: .topBarTrailing) {
                if let viewModel = viewModel {
                    Button {
                        HapticService.shared.lightTap()
                        withAnimation(Theme.Animation.settle) {
                            showChapterPanel.toggle()
                        }
                    } label: {
                        Group {
                            if showChapterPanel {
                                Image(systemName: "xmark")
                                    .font(Typography.Icon.sm.weight(.semibold))
                            } else {
                                Text("\(viewModel.currentLocation.chapter)")
                                    .font(Typography.Command.body.weight(.semibold))
                            }
                        }
                    }
                    .animation(Theme.Animation.fade, value: showChapterPanel)
                    .accessibilityLabel(showChapterPanel ? "Close chapter selector" : "Chapter \(viewModel.currentLocation.chapter)")
                    .accessibilityHint(showChapterPanel ? "Closes the chapter selector panel" : "Opens chapter selector panel")
                    .accessibilityIdentifier("ReaderToolbarChapterButton")
                }
            }
        }
        .toolbar(showToolbar ? .visible : .hidden, for: .navigationBar)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .animation(Theme.Animation.fade, value: showToolbar)
        .sheet(isPresented: $showReadingMenu) { readingMenuSheet }
        .sheet(isPresented: $showBookPicker) { bookPickerSheet }
        .sheet(isPresented: $showAudioPlayer) { AudioPlayerSheet(audioService: audioService) }
        .sheet(isPresented: $showInsightSheet, onDismiss: { viewModel?.clearSelection() }) { insightSheetContent }
        .task { await initializeViewModel() }
        .onAppear { appState.hideTabBar = true }
        .onDisappear { appState.hideTabBar = false }
        .onReceive(NotificationCenter.default.publisher(for: .audioVerseChanged)) { handleAudioVerseChange($0) }
        .onChange(of: audioService.playbackState) { handlePlaybackStateChange($1) }
        .onChange(of: viewModel?.flashVerseId) { handleFlashVerseChange($1) }
        .onChange(of: viewModel?.currentLocation) { handleLocationChange($1) }
    }

    // MARK: - Chapter Panel Swipe Gesture

    private var chapterPanelSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                // Swipe left (negative x) opens panel
                if value.translation.width < -50 && !showChapterPanel {
                    withAnimation(Theme.Animation.settle) {
                        showChapterPanel = true
                    }
                    HapticService.shared.lightTap()
                }
            }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func mainContent(viewModel: BibleReaderViewModel, geometry: GeometryProxy) -> some View {
        if viewModel.isLoading {
            loadingView
        } else if let error = viewModel.error {
            errorView(error, viewModel: viewModel)
        } else if let chapter = viewModel.chapter {
            contentView(chapter: chapter, geometry: geometry, viewModel: viewModel)

            // Context menu overlay
            if viewModel.showContextMenu, let range = viewModel.selectedRange {
                BibleContextMenuOverlay(
                    verseRange: range,
                    selectionBounds: viewModel.selectionBounds,
                    containerBounds: geometry.frame(in: .global),
                    safeAreaInsets: geometry.safeAreaInsets,
                    existingHighlightColor: viewModel.existingHighlightColorForSelection,
                    onCopy: {
                        viewModel.copySelectedVerses()
                        viewModel.clearSelection()
                    },
                    onShare: {
                        shareVerse(viewModel: viewModel)
                        viewModel.clearSelection()
                    },
                    onNote: { viewModel.clearSelection() },
                    onHighlight: { color in Task { await viewModel.quickHighlight(color: color) } },
                    onRemoveHighlight: { Task { await viewModel.removeHighlightForSelection() } },
                    onStudy: { openInsightSheetFromMenu(viewModel: viewModel) },
                    onDismiss: { viewModel.clearSelection() }
                )
            }
        } else {
            loadingView
        }
    }

    // MARK: - Sheets

    @ViewBuilder
    private var readingMenuSheet: some View {
        BibleReadingMenuSheet(
            onAudioTap: {
                showReadingMenu = false
                if let viewModel = viewModel {
                    Task {
                        await viewModel.playAudio()
                        showAudioPlayer = true
                    }
                }
            },
            onNavigate: { range in
                showReadingMenu = false
                Task { await viewModel?.navigateToVerse(range) }
            }
        )
    }

    @ViewBuilder
    private var bookPickerSheet: some View {
        if let viewModel = viewModel {
            BibleBookPickerView(
                currentBookId: viewModel.currentLocation.bookId,
                currentChapter: viewModel.currentLocation.chapter
            ) { bookId, chapter in
                Task { await viewModel.goToBook(bookId, chapter: chapter) }
            }
        }
    }

    @ViewBuilder
    private var insightSheetContent: some View {
        if let verse = insightSheetVerse,
           let viewModel = viewModel,
           let chapter = viewModel.chapter {
            BibleInsightSheet(
                verse: verse,
                insights: insightSheetInsights,
                allVerses: chapter.verses,
                verseInsightCounts: insightSheetVerseInsightCounts,
                onDismiss: { showInsightSheet = false },
                onOpenInStudy: { showInsightSheet = false },
                onNavigateToVerse: { navigateToVerseInSheet($0) },
                onNavigateToReference: { navigateToReferenceFromSheet($0, viewModel: viewModel) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Loading & Error Views

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .tint(Color("AppAccentAction"))
            Text("Loading...")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
        }
    }

    private func errorView(_ error: Error, viewModel: BibleReaderViewModel) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(Typography.Icon.xxl.weight(.light))
                .foregroundStyle(Color("FeedbackError"))

            Text("Unable to load chapter")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color("AppTextPrimary"))

            Text(error.localizedDescription)
                .font(Typography.Command.caption)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            Button {
                Task { await viewModel.loadChapter() }
            } label: {
                Text("Try Again")
                    .font(Typography.Command.cta)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .fill(Color("AppAccentAction"))
                    )
            }
        }
    }

    // MARK: - Content View

    private func contentView(chapter: Chapter, geometry: GeometryProxy, viewModel: BibleReaderViewModel) -> some View {
        let contentWidth = appState.contentWidth.resolvedWidth(for: geometry.size.width)

        return ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Chapter header
                    BibleChapterHeader(
                        book: viewModel.book,
                        chapter: viewModel.currentLocation.chapter,
                        isVisible: isVisible
                    )
                    .padding(.top, Theme.Size.minTapTarget + Theme.Spacing.xl)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .id("chapter-top")

                    let shouldShowDivider = Layout.shouldShowEditorialDivider(
                        isContentVisible: isVisible,
                        isChapterPanelPresented: showChapterPanel
                    )

                    // Editorial divider - hidden when chapter panel is open to avoid visual break
                    Group {
                        if shouldShowDivider {
                            BibleEditorialDivider(isVisible: true)
                        } else {
                            Color.clear.frame(height: Theme.Stroke.hairline)
                        }
                    }
                    .padding(.vertical, Theme.Spacing.xl)

                    // Verses
                    versesSection(chapter: chapter, geometry: geometry, viewModel: viewModel)

                    // Chapter footer with optional artwork
                    BibleChapterFooter(
                        chapter: viewModel.currentLocation.chapter,
                        canGoForward: viewModel.canGoForward,
                        nextLocation: viewModel.book.flatMap { viewModel.currentLocation.next(maxChapter: $0.chapters) },
                        onNextChapter: { Task { await viewModel.goToNextChapter() } },
                        bookName: viewModel.book?.name,
                        bottomSafeAreaInset: geometry.safeAreaInsets.bottom
                    )
                    .padding(.horizontal, viewModel.book?.name != nil ? 0 : Theme.Spacing.xl)
                }
                .frame(width: contentWidth)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(minHeight: geometry.size.height)
            }
            .onAppear { scrollProxy = proxy }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 5)
                .onChanged { value in
                    handleDragChange(value.translation.height)
                }
        )
    }

    private func handleDragChange(_ translation: CGFloat) {
        guard !reduceMotion else { return }

        // Negative translation = scrolling down (dragging up)
        // Positive translation = scrolling up (dragging down)
        let hideThreshold: CGFloat = -60
        let showThreshold: CGFloat = 30

        if translation < hideThreshold && showToolbar {
            withAnimation(Theme.Animation.fade) {
                showToolbar = false
            }
        } else if translation > showThreshold && !showToolbar {
            withAnimation(Theme.Animation.fade) {
                showToolbar = true
            }
        }
    }

    // MARK: - Verses Section

    private func versesSection(chapter: Chapter, geometry: GeometryProxy, viewModel: BibleReaderViewModel) -> some View {
        Group {
            if appState.paragraphMode {
                paragraphModeContent(chapter: chapter, viewModel: viewModel)
            } else {
                verseModeContent(chapter: chapter, geometry: geometry, viewModel: viewModel)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private func verseModeContent(chapter: Chapter, geometry: GeometryProxy, viewModel: BibleReaderViewModel) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            ForEach(Array(chapter.verses.enumerated()), id: \.element.id) { index, verse in
                BibleVerseRow(
                    verse: verse,
                    isSelected: viewModel.isVerseSelected(verse.verse),
                    isInRange: viewModel.selectedVerses.contains(verse.verse),
                    highlightColor: viewModel.highlightColor(for: verse.verse),
                    selectionMode: viewModel.selectionMode,
                    isSpokenVerse: currentPlayingVerse == verse.verse,
                    fontSize: appState.scriptureFontSize,
                    scriptureFont: appState.scriptureFont,
                    lineSpacing: appState.lineSpacing.value,
                    flashOpacity: viewModel.flashVerseId == verse.verse ? flashOpacity : 0,
                    onTap: { handleVerseTap(verse: verse, viewModel: viewModel) },
                    onLongPress: { handleVerseLongPress(verse: verse, chapter: chapter, viewModel: viewModel) },
                    onBoundsChange: { bounds in
                        if viewModel.isVerseSelected(verse.verse) {
                            viewModel.updateSelectionBounds(bounds, container: geometry.frame(in: .global))
                        }
                    }
                )
                .id("verse-\(verse.verse)")
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
                // swiftlint:disable:next hardcoded_animation_spring
                .animation(Theme.Animation.settle.delay(0.4 + Double(index) * 0.02), value: isVisible)
            }
        }
    }

    private func paragraphModeContent(chapter: Chapter, viewModel: BibleReaderViewModel) -> some View {
        ParagraphModeView(
            verses: chapter.verses,
            selectedVerses: viewModel.selectedVerses,
            fontSize: appState.scriptureFontSize,
            lineSpacing: appState.lineSpacing.value,
            onSelectVerse: { verseNum in
                withAnimation(Theme.Animation.fade) {
                    viewModel.selectVerse(verseNum)
                }
                HapticService.shared.lightTap()
            },
            getHighlightColor: { viewModel.highlightColor(for: $0) }
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        // swiftlint:disable:next hardcoded_animation_spring
        .animation(Theme.Animation.settle.delay(0.4), value: isVisible)
    }

    // MARK: - Event Handlers

    private func handleVerseTap(verse: Verse, viewModel: BibleReaderViewModel) {
        withAnimation(Theme.Animation.fade) {
            if viewModel.selectionMode == .range {
                if viewModel.selectedVerses.count == 1 && viewModel.selectedVerses.contains(verse.verse) {
                    viewModel.clearSelection()
                } else {
                    viewModel.extendSelection(to: verse.verse)
                }
            } else {
                viewModel.selectVerse(verse.verse)
            }
        }
        HapticService.shared.lightTap()
    }

    private func handleVerseLongPress(verse: Verse, chapter: Chapter, viewModel: BibleReaderViewModel) {
        withAnimation(Theme.Animation.fade) {
            viewModel.startRangeSelection(from: verse.verse)
        }
        HapticService.shared.mediumTap()
        openInsightSheet(for: verse, chapter: chapter)
    }

    private func initializeViewModel() async {
        let vm = BibleReaderViewModel(location: initialLocation)
        viewModel = vm
        await vm.loadChapter()
        if isUITestingReader {
            showChapterPanel = true
        }
        // swiftlint:disable:next hardcoded_animation_spring
        withAnimation(Theme.Animation.settle) {
            isVisible = true
        }
    }

    private func handleAudioVerseChange(_ notification: Notification) {
        guard let verse = notification.userInfo?["verse"] as? Int,
              let viewModel = viewModel else {
            currentPlayingVerse = nil
            return
        }

        let bookId = notification.userInfo?["bookId"] as? Int
        let chapter = notification.userInfo?["chapter"] as? Int
        let matchesLocation = bookId == viewModel.currentLocation.bookId && chapter == viewModel.currentLocation.chapter

        currentPlayingVerse = matchesLocation ? verse : nil
    }

    private func handlePlaybackStateChange(_ newState: PlaybackState) {
        if newState == .idle || newState == .finished {
            currentPlayingVerse = nil
        }
    }

    private func handleFlashVerseChange(_ newFlashId: Int?) {
        guard let verseId = newFlashId else { return }

        withAnimation(Theme.Animation.settle) {
            scrollProxy?.scrollTo("verse-\(verseId)", anchor: .center)
        }

        flashOpacity = 1.0
        withAnimation(Theme.Animation.slowFade) { flashOpacity = 0 }

        Task {
            try? await Task.sleep(for: .milliseconds(1500))
            viewModel?.clearFlash()
        }
    }

    private func handleLocationChange(_ newLocation: BibleLocation?) {
        withAnimation(Theme.Animation.settle) {
            scrollProxy?.scrollTo("chapter-top", anchor: .top)
        }
        if let location = newLocation {
            lastBookId = location.bookId
            lastChapter = location.chapter
        }
    }

    // MARK: - Insight Sheet Helpers

    private func openInsightSheet(for verse: Verse, chapter: Chapter) {
        viewModel?.showContextMenu = false
        insightSheetVerse = verse
        insightSheetInsights = []
        insightSheetVerseInsightCounts = [:]
        showInsightSheet = true

        Task {
            do {
                let insights = try await BibleInsightService.shared.getInsights(
                    bookId: verse.bookId, chapter: verse.chapter, verse: verse.verse
                )

                var counts: [Int: Int] = [:]
                for v in chapter.verses {
                    let verseInsights = try await BibleInsightService.shared.getInsights(
                        bookId: v.bookId, chapter: v.chapter, verse: v.verse
                    )
                    if !verseInsights.isEmpty { counts[v.verse] = verseInsights.count }
                }

                await MainActor.run {
                    insightSheetInsights = insights
                    insightSheetVerseInsightCounts = counts
                }
            } catch {
                print("Failed to load insights for verse: \(error)")
            }
        }
    }

    private func openInsightSheetFromMenu(viewModel: BibleReaderViewModel) {
        if let chapter = viewModel.chapter,
           let selectedVerseNum = viewModel.selectedVerses.first,
           let verse = chapter.verses.first(where: { $0.verse == selectedVerseNum }) {
            openInsightSheet(for: verse, chapter: chapter)
        }
    }

    private func navigateToVerseInSheet(_ newVerse: Verse) {
        Task {
            let newInsights = try? await BibleInsightService.shared.getInsights(
                bookId: newVerse.bookId, chapter: newVerse.chapter, verse: newVerse.verse
            )
            insightSheetVerse = newVerse
            insightSheetInsights = newInsights ?? []
        }
    }

    private func navigateToReferenceFromSheet(_ reference: String, viewModel: BibleReaderViewModel) {
        showInsightSheet = false
        if let range = VerseRange.parse(reference) {
            Task {
                await viewModel.goToBook(range.bookId, chapter: range.chapter)
                viewModel.flashVerseId = range.verseStart
            }
        }
    }

    private func shareVerse(viewModel: BibleReaderViewModel) {
        guard let text = viewModel.getShareText() else { return }
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Layout Helpers

extension BibleReaderView {
    enum Layout {
        static func shouldShowEditorialDivider(
            isContentVisible: Bool,
            isChapterPanelPresented: Bool
        ) -> Bool {
            isContentVisible && !isChapterPanelPresented
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BibleReaderView(location: .john1)
    }
    .environment(BibleService.shared)
}

#Preview("With Selection") {
    NavigationStack {
        BibleReaderView(location: .genesis1)
    }
    .environment(BibleService.shared)
}

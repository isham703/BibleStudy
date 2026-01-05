import SwiftUI
import UIKit

// MARK: - Bible Reader View
// Bible reader with verse-by-verse layout
// Full-featured: multi-verse selection, context menu, highlights, AI insights

struct BibleReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var viewModel: BibleReaderViewModel?
    @State private var isVisible = false
    @State private var showBookPicker = false
    @State private var showReadingMenu = false
    @State private var showAudioPlayer = false
    @State private var scrollProxy: ScrollViewProxy?

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

    // Persist last reading position
    @AppStorage("scholarLastBookId") private var lastBookId: Int = 43
    @AppStorage("scholarLastChapter") private var lastChapter: Int = 1

    // Dynamic Type Support for header
    @ScaledMetric(relativeTo: .title) private var chapterTitleSize: CGFloat = 52
    @ScaledMetric(relativeTo: .footnote) private var chapterLabelSize: CGFloat = 14
    @ScaledMetric(relativeTo: .caption) private var headerLabelSize: CGFloat = 11

    let initialLocation: BibleLocation?

    init(location: BibleLocation? = nil) {
        self.initialLocation = location
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - adaptive semantic color with tap to dismiss
                Color.appBackground
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Tap on background to dismiss context menu
                        if let viewModel = viewModel, viewModel.showContextMenu {
                            withAnimation(AppTheme.Animation.selection) {
                                viewModel.clearSelection()
                            }
                        }
                    }

                // Main content
                if let viewModel = viewModel {
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.error {
                        errorView(error, viewModel: viewModel)
                    } else if let chapter = viewModel.chapter {
                        contentView(chapter: chapter, geometry: geometry, viewModel: viewModel)
                    } else {
                        loadingView
                    }

                    // Context menu overlay
                    if viewModel.showContextMenu,
                       let range = viewModel.selectedRange {
                        contextMenuOverlay(viewModel: viewModel, range: range, geometry: geometry)
                    }
                } else {
                    loadingView
                }
            }
            .coordinateSpace(name: "scholarReader")
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let viewModel = viewModel {
                    BibleChapterSelector(
                        reference: viewModel.headerReference,
                        bookName: viewModel.book?.name ?? "",
                        chapter: viewModel.currentLocation.chapter
                    ) {
                        HapticService.shared.lightTap()
                        showBookPicker = true
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                if let viewModel = viewModel {
                    navigationButtons(viewModel: viewModel)
                }
            }

            ToolbarItem(placement: .topBarLeading) {
                Button {
                    HapticService.shared.lightTap()
                    showReadingMenu = true
                } label: {
                    Image(systemName: "textformat.size")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.primaryText)
                }
            }
        }
        .sheet(isPresented: $showReadingMenu) {
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
                    Task {
                        await viewModel?.navigateToVerse(range)
                    }
                }
            )
        }
        .sheet(isPresented: $showBookPicker) {
            if let viewModel = viewModel {
                BibleBookPickerView(
                    currentBookId: viewModel.currentLocation.bookId,
                    currentChapter: viewModel.currentLocation.chapter
                ) { bookId, chapter in
                    Task {
                        await viewModel.goToBook(bookId, chapter: chapter)
                    }
                }
            }
        }
        .task {
            let vm = BibleReaderViewModel(location: initialLocation)
            viewModel = vm
            await vm.loadChapter()
            withAnimation(.spring(response: 0.4, dampingFraction: 1.0)) {
                isVisible = true
            }
        }
        .onAppear {
            appState.hideTabBar = true
        }
        .onDisappear {
            appState.hideTabBar = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .audioVerseChanged)) { notification in
            guard let verse = notification.userInfo?["verse"] as? Int,
                  let viewModel = viewModel else {
                currentPlayingVerse = nil
                return
            }

            let bookId = notification.userInfo?["bookId"] as? Int
            let chapter = notification.userInfo?["chapter"] as? Int

            let matchesLocation = bookId == viewModel.currentLocation.bookId &&
                chapter == viewModel.currentLocation.chapter

            if matchesLocation {
                currentPlayingVerse = verse
            } else {
                currentPlayingVerse = nil
            }
        }
        .onChange(of: audioService.playbackState) { _, newState in
            if newState == .idle || newState == .finished {
                currentPlayingVerse = nil
            }
        }
        .onChange(of: viewModel?.flashVerseId) { _, newFlashId in
            if let verseId = newFlashId {
                // Scroll to the flashed verse
                withAnimation(AppTheme.Animation.cardUnfurl) {
                    scrollProxy?.scrollTo("verse-\(verseId)", anchor: .center)
                }

                // Animate the flash
                flashOpacity = 1.0
                withAnimation(.easeOut(duration: 0.6)) {
                    flashOpacity = 0
                }

                // Clear flash after animation
                Task {
                    try? await Task.sleep(for: .milliseconds(1500))
                    viewModel?.clearFlash()
                }
            }
        }
        .onChange(of: viewModel?.currentLocation) { _, newLocation in
            // Scroll to top of new chapter
            withAnimation(AppTheme.Animation.spring) {
                scrollProxy?.scrollTo("chapter-top", anchor: .top)
            }

            // Save last reading position when location changes
            if let location = newLocation {
                lastBookId = location.bookId
                lastChapter = location.chapter
            }
        }
        .sheet(isPresented: $showAudioPlayer) {
            AudioPlayerSheet(audioService: audioService)
        }
        .sheet(isPresented: $showInsightSheet, onDismiss: {
            // Clear verse selection when sheet is dismissed
            viewModel?.clearSelection()
        }) {
            insightSheetContent
        }
    }

    // MARK: - Insight Sheet Content

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
                onOpenInStudy: {
                    // Already in Scholar mode - just dismiss sheet
                    showInsightSheet = false
                },
                onNavigateToVerse: { newVerse in
                    navigateToVerseInSheet(newVerse)
                },
                onNavigateToReference: { reference in
                    navigateToReferenceFromSheet(reference, viewModel: viewModel)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func navigateToVerseInSheet(_ newVerse: Verse) {
        Task {
            let newInsights = try? await BibleInsightService.shared.getInsights(
                bookId: newVerse.bookId,
                chapter: newVerse.chapter,
                verse: newVerse.verse
            )
            insightSheetVerse = newVerse
            insightSheetInsights = newInsights ?? []
        }
    }

    private func navigateToReferenceFromSheet(_ reference: String, viewModel: BibleReaderViewModel) {
        showInsightSheet = false
        // Parse reference and navigate
        if let range = VerseRange.parse(reference) {
            Task {
                await viewModel.goToBook(range.bookId, chapter: range.chapter)
                // Flash the target verse after navigation
                viewModel.flashVerseId = range.verseStart
            }
        }
    }

    // MARK: - Navigation Buttons

    private func navigationButtons(viewModel: BibleReaderViewModel) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Button {
                Task { await viewModel.goToPreviousChapter() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(viewModel.canGoBack ? Color.primaryText : Color.primaryText.opacity(0.3))
            }
            .disabled(!viewModel.canGoBack)

            Button {
                Task { await viewModel.goToNextChapter() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(viewModel.canGoForward ? Color.primaryText : Color.primaryText.opacity(0.3))
            }
            .disabled(!viewModel.canGoForward)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ProgressView()
                .tint(Color.scholarIndigo)

            Text("Loading...")
                .insightBody()
                .foregroundStyle(Color.tertiaryText)
        }
    }

    // MARK: - Error View

    private func errorView(_ error: Error, viewModel: BibleReaderViewModel) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.scholarIndigo)

            Text("Unable to load chapter")
                .insightEmphasis()
                .foregroundStyle(Color.primaryText)

            Text(error.localizedDescription)
                .font(Typography.UI.footnote)
                .foregroundStyle(Color.tertiaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)

            Button {
                Task { await viewModel.loadChapter() }
            } label: {
                Text("Try Again")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(Color.scholarIndigo)
                    .clipShape(Capsule())
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
                    chapterHeader(viewModel: viewModel)
                        .padding(.top, AppTheme.Spacing.xl)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .id("chapter-top")

                    // Editorial divider
                    editorialDivider
                        .padding(.vertical, AppTheme.Spacing.xl)

                    // Verses with inline insight cards
                    versesSection(chapter: chapter, geometry: geometry, viewModel: viewModel)

                    // Chapter footer with manuscript colophon style
                    chapterFooter(viewModel: viewModel)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                }
                .frame(width: contentWidth)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(minHeight: geometry.size.height)
            }
            .onAppear {
                scrollProxy = proxy
            }
        }
    }

    // MARK: - Chapter Header (Living Commentary Style)

    private func chapterHeader(viewModel: BibleReaderViewModel) -> some View {
        VStack(spacing: 12) {
            // Book category label (e.g., "THE GOSPEL OF", "THE BOOK OF")
            Text(bookCategoryLabel(for: viewModel.book))
                .font(.system(size: headerLabelSize, weight: .medium))
                .tracking(3)
                .foregroundStyle(Color.primaryText.opacity(0.4))

            // Book name - large Cormorant font
            Text(viewModel.book?.name ?? "")
                .font(.custom("CormorantGaramond-SemiBold", size: chapterTitleSize))
                .foregroundStyle(Color.primaryText)

            // Chapter with decorative lines
            HStack(spacing: 16) {
                Rectangle()
                    .fill(Color.scholarIndigo.opacity(0.3))
                    .frame(width: 40, height: 1)

                Text("Chapter \(viewModel.currentLocation.chapter)")
                    .font(.system(size: chapterLabelSize, weight: .semibold))
                    .foregroundStyle(Color.scholarIndigo)

                Rectangle()
                    .fill(Color.scholarIndigo.opacity(0.3))
                    .frame(width: 40, height: 1)
            }
        }
        .frame(maxWidth: .infinity)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
        .animation(.spring(duration: 0.7).delay(0.2), value: isVisible)
    }

    /// Returns the appropriate label for the book category
    private func bookCategoryLabel(for book: Book?) -> String {
        guard let book = book else { return "THE BOOK OF" }

        switch book.category {
        case .gospels:
            return "THE GOSPEL OF"
        case .paulineEpistles:
            return "THE EPISTLE OF PAUL TO THE"
        case .generalEpistles:
            return "THE EPISTLE OF"
        case .revelation:
            return "THE BOOK OF"
        case .pentateuch:
            return "THE BOOK OF"
        case .historical:
            return "THE BOOK OF"
        case .wisdom:
            return "THE BOOK OF"
        case .prophets:
            return "THE BOOK OF"
        case .theTwelve:
            return "THE BOOK OF"
        case .acts:
            return "THE BOOK OF"
        }
    }

    // MARK: - Editorial Divider

    private var editorialDivider: some View {
        Rectangle()
            .fill(Color.primaryText.opacity(0.1))
            .frame(height: 1)
            .padding(.horizontal, AppTheme.Spacing.xl)
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: isVisible)
    }

    // MARK: - Chapter Footer (Manuscript Colophon Style)

    private func chapterFooter(viewModel: BibleReaderViewModel) -> some View {
        VStack(spacing: 0) {
            // Elegant chapter closing ornament
            chapterClosingOrnament(chapter: viewModel.currentLocation.chapter)
                .padding(.bottom, AppTheme.Spacing.xxl)

            // Next chapter invitation (conditional)
            if viewModel.canGoForward,
               let nextLocation = getNextLocation(viewModel: viewModel) {
                nextChapterInvitation(
                    nextLocation: nextLocation,
                    viewModel: viewModel
                )
                .padding(.bottom, AppTheme.Spacing.xl)
            }

            // Breathing room
            Spacer()
                .frame(height: 100)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func chapterClosingOrnament(chapter: Int) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Triple-line flourish
            VStack(spacing: 4) {
                Rectangle()
                    .fill(Color.scholarIndigo.opacity(0.15))
                    .frame(width: 80, height: 0.5)
                Rectangle()
                    .fill(Color.scholarIndigo.opacity(0.25))
                    .frame(width: 120, height: 1)
                Rectangle()
                    .fill(Color.scholarIndigo.opacity(0.15))
                    .frame(width: 80, height: 0.5)
            }

            // Chapter completion label
            Text("CHAPTER \(chapter)")
                .font(.system(size: 10, weight: .medium, design: .default))
                .tracking(4)
                .foregroundStyle(Color.scholarIndigo.opacity(0.4))
        }
    }

    private func nextChapterInvitation(
        nextLocation: BibleLocation,
        viewModel: BibleReaderViewModel
    ) -> some View {
        Button {
            Task {
                await viewModel.goToNextChapter()
            }
        } label: {
            VStack(spacing: AppTheme.Spacing.sm) {
                // "Continue reading" label
                Text("CONTINUE READING")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(2.5)
                    .foregroundStyle(Color.scholarIndigo.opacity(0.5))

                // Destination with elegant typography
                HStack(spacing: AppTheme.Spacing.sm) {
                    if let book = nextLocation.book {
                        Text(book.name)
                            .font(.custom("CormorantGaramond-SemiBold", size: 20))
                        Text("\(nextLocation.chapter)")
                            .font(.custom("CormorantGaramond-Regular", size: 20))
                            .foregroundStyle(Color.scholarIndigo.opacity(0.7))
                    }
                }
                .foregroundStyle(Color.scholarIndigo)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.lg)
            .padding(.horizontal, AppTheme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(Color.scholarIndigo.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .strokeBorder(Color.scholarIndigo.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func getNextLocation(viewModel: BibleReaderViewModel) -> BibleLocation? {
        guard let book = viewModel.book else { return nil }
        return viewModel.currentLocation.next(maxChapter: book.chapters)
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
        .padding(.horizontal, AppTheme.Spacing.lg)
    }

    // MARK: - Verse Mode Content

    private func verseModeContent(chapter: Chapter, geometry: GeometryProxy, viewModel: BibleReaderViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
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
                    onTap: {
                        withAnimation(AppTheme.Animation.selection) {
                            if viewModel.selectionMode == .range {
                                // If tapping the only selected verse, clear selection
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
                    },
                    onLongPress: {
                        withAnimation(AppTheme.Animation.selection) {
                            viewModel.startRangeSelection(from: verse.verse)
                        }
                        HapticService.shared.mediumTap()
                        // Open Living Commentary InsightSheet on long-press
                        openBibleInsightSheet(for: verse, chapter: chapter)
                    },
                    onBoundsChange: { bounds in
                        if viewModel.isVerseSelected(verse.verse) {
                            let containerBounds = geometry.frame(in: .global)
                            viewModel.updateSelectionBounds(bounds, container: containerBounds)
                        }
                    }
                )
                .id("verse-\(verse.verse)")
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
                .animation(
                    .spring(response: 0.4, dampingFraction: 1.0).delay(0.4 + Double(index) * 0.02),
                    value: isVisible
                )
            }
        }
    }

    // MARK: - Paragraph Mode Content

    private func paragraphModeContent(chapter: Chapter, viewModel: BibleReaderViewModel) -> some View {
        ParagraphModeView(
            verses: chapter.verses,
            selectedVerses: viewModel.selectedVerses,
            fontSize: appState.scriptureFontSize,
            lineSpacing: appState.lineSpacing.value,
            onSelectVerse: { verseNum in
                withAnimation(AppTheme.Animation.selection) {
                    viewModel.selectVerse(verseNum)
                }
                HapticService.shared.lightTap()
            },
            getHighlightColor: { verseNum in
                viewModel.highlightColor(for: verseNum)
            }
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 1.0).delay(0.4), value: isVisible)
    }

    // MARK: - Open Insight Sheet (Living Commentary)

    /// Opens the Living Commentary InsightSheet for a verse
    private func openBibleInsightSheet(for verse: Verse, chapter: Chapter) {
        // Dismiss context menu first
        viewModel?.showContextMenu = false

        // Set verse and show sheet immediately (insights load async)
        insightSheetVerse = verse
        insightSheetInsights = []
        insightSheetVerseInsightCounts = [:]
        showInsightSheet = true

        // Load insights async
        Task {
            do {
                // Get insights for this verse
                let insights = try await BibleInsightService.shared.getInsights(
                    bookId: verse.bookId,
                    chapter: verse.chapter,
                    verse: verse.verse
                )

                // Also load insight counts for all verses in chapter (for navigation)
                var counts: [Int: Int] = [:]
                for v in chapter.verses {
                    let verseInsights = try await BibleInsightService.shared.getInsights(
                        bookId: v.bookId,
                        chapter: v.chapter,
                        verse: v.verse
                    )
                    if !verseInsights.isEmpty {
                        counts[v.verse] = verseInsights.count
                    }
                }

                // Update state with loaded data
                await MainActor.run {
                    insightSheetInsights = insights
                    insightSheetVerseInsightCounts = counts
                }
            } catch {
                print("Failed to load insights for verse: \(error)")
                // Keep empty state - user sees "No insights" message
            }
        }
    }

    // Note: inlineInsightPayload function removed - now using InsightSheet from Living Commentary

    // MARK: - Context Menu Overlay

    private func contextMenuOverlay(viewModel: BibleReaderViewModel, range: VerseRange, geometry: GeometryProxy) -> some View {
        UnifiedContextMenu(
            mode: .actionsFirst,
            verseRange: range,
            selectionBounds: viewModel.selectionBounds,
            containerBounds: geometry.frame(in: .global),
            safeAreaInsets: geometry.safeAreaInsets,
            existingHighlightColor: viewModel.existingHighlightColorForSelection,
            insight: nil,  // Scholar mode: no insight preview
            isInsightLoading: false,
            isLimitReached: false,
            onCopy: {
                viewModel.copySelectedVerses()
                viewModel.clearSelection()
            },
            onShare: {
                shareVerse(viewModel: viewModel)
                viewModel.clearSelection()
            },
            onNote: {
                // Open note editor
                viewModel.clearSelection()
            },
            onHighlight: { color in
                Task {
                    await viewModel.quickHighlight(color: color)
                }
            },
            onRemoveHighlight: {
                Task {
                    await viewModel.removeHighlightForSelection()
                }
            },
            onStudy: {
                // Open Living Commentary InsightSheet
                if let chapter = viewModel.chapter,
                   let selectedVerseNum = viewModel.selectedVerses.first,
                   let verse = chapter.verses.first(where: { $0.verse == selectedVerseNum }) {
                    openBibleInsightSheet(for: verse, chapter: chapter)
                }
            },
            onDismiss: {
                viewModel.clearSelection()
            }
        )
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Share Helper

    private func shareVerse(viewModel: BibleReaderViewModel) {
        guard let text = viewModel.getShareText() else { return }
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Bible Verse Row
// Note: BibleInlineInsightPayload removed - now using InsightSheet

private struct BibleVerseRow: View {
    let verse: Verse
    let isSelected: Bool
    let isInRange: Bool
    let highlightColor: HighlightColor?
    let selectionMode: BibleSelectionMode
    // Note: inlineInsight parameter removed - now using InsightSheet from Living Commentary
    let isSpokenVerse: Bool
    let fontSize: ScriptureFontSize
    let scriptureFont: ScriptureFont
    let lineSpacing: CGFloat
    let flashOpacity: Double
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onBoundsChange: (CGRect) -> Void

    @State private var isPressed = false
    private let verseNumberWidth: CGFloat = 28

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                // Verse number
                Text("\(verse.verse)")
                    .readingVerseNumber()
                    .foregroundStyle(isSelected ? Color.scholarIndigo : Color.primaryText)
                    .frame(width: verseNumberWidth, alignment: .trailing)

                // Verse text
                Text(verse.text)
                    .readingVerse(size: fontSize, font: scriptureFont, lineSpacing: lineSpacing)
                    .foregroundStyle(Color.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(verseBackground)
        .overlay(verseOverlay)
        .overlay(flashOverlay)
        .overlay(spokenUnderline, alignment: .bottomLeading)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.98 : 1)
        .onTapGesture(perform: onTap)
        .onLongPressGesture(minimumDuration: 0.4, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: onLongPress)
        .background(selectionBoundsReader)
        .frame(minHeight: 60)
    }

    // MARK: - Verse Background

    @ViewBuilder
    private var verseBackground: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
            .fill(backgroundColor)
    }

    private var backgroundColor: Color {
        if isSelected || isInRange {
            return Color.scholarIndigo.opacity(0.08)
        } else if isSpokenVerse {
            return Color.scholarAccent.opacity(0.15)
        } else if let highlight = highlightColor {
            return highlight.color.opacity(0.15)
        } else {
            return Color.clear
        }
    }

    // MARK: - Verse Overlay

    @ViewBuilder
    private var verseOverlay: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
            .stroke(overlayColor, lineWidth: isSelected ? 1.5 : 1)
    }

    private var overlayColor: Color {
        if isSelected {
            return Color.scholarIndigo.opacity(0.3)
        } else if isInRange {
            return Color.scholarIndigo.opacity(0.2)
        } else {
            return Color.clear
        }
    }


    @ViewBuilder
    private var flashOverlay: some View {
        if flashOpacity > 0 {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(Color.scholarAccent.opacity(flashOpacity * 0.4))
        }
    }

    @ViewBuilder
    private var spokenUnderline: some View {
        if isSpokenVerse {
            Rectangle()
                .fill(AppTheme.InlineInsight.spokenUnderline)
                .frame(height: 2)
                .padding(.leading, verseNumberWidth + AppTheme.Spacing.md)
                .padding(.trailing, AppTheme.Spacing.sm)
                .padding(.bottom, 2)
        }
    }

    private var selectionBoundsReader: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear {
                    if isSelected {
                        onBoundsChange(geo.frame(in: .global))
                    }
                }
                .onChange(of: isSelected) { _, newValue in
                    if newValue {
                        onBoundsChange(geo.frame(in: .global))
                    }
                }
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

import SwiftUI
import UIKit

// MARK: - Scroll Mode Reader Content
// Extracts the scroll mode reading view from ReaderView for better maintainability

struct ScrollModeReaderContent: View {
    @Bindable var viewModel: ReaderViewModel
    @Environment(AppState.self) private var appState

    // MARK: - Callbacks
    let onSelectVerse: (Int) -> Void
    let onLongPressVerse: (Int) -> Void
    let onDoubleTapVerse: (Int) -> Void
    let onVisibleVerseChange: (Int) -> Void
    let onSelectionBoundsChange: (CGRect?) -> Void
    let onFlashAnimationComplete: () -> Void
    let onChapterChange: () -> Void
    let onSwipeNavigate: (ChapterNavigationDirection) async -> Void
    let onScrollDirectionChange: ((ScrollDirection) -> Void)?

    // MARK: - State from parent
    let currentPlayingVerse: Int?
    @Binding var dragOffset: CGFloat
    @Binding var isNavigating: Bool
    @Binding var flashOpacity: Double

    /// Chrome visibility state (controls top content inset)
    let showChrome: Bool

    // MARK: - Scroll State
    /// Target ID for scrolling to expanded insight sections
    @State private var scrollTarget: String?
    /// Last recorded scroll offset for direction detection
    @State private var lastScrollOffset: CGFloat = 0
    /// Whether initial scroll offset has been captured (prevents false hide on load)
    @State private var initialScrollCaptured: Bool = false
    /// Threshold to trigger scroll direction change (prevents jitter)
    private let scrollThreshold: CGFloat = 20

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Scroll offset tracker (invisible)
                    GeometryReader { geo in
                        Color.clear
                            .preference(
                                key: ReaderScrollOffsetKey.self,
                                value: geo.frame(in: .named("scrollView")).minY
                            )
                    }
                    .frame(height: 0)

                    if let chapter = viewModel.chapter {
                        if appState.paragraphMode {
                            paragraphModeContent(chapter: chapter)
                        } else {
                            verseModeContent(chapter: chapter)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.xl)
                .frame(maxWidth: appState.contentWidth.maxWidth ?? .infinity)
                .frame(maxWidth: .infinity)
            }
            .coordinateSpace(name: "scrollView")
            .onPreferenceChange(ReaderScrollOffsetKey.self) { offset in
                detectScrollDirection(currentOffset: offset)
            }
            .refreshable {
                HapticService.shared.pullToRefresh()
                await viewModel.loadChapter()
            }
            .onChange(of: viewModel.chapter) { _, newChapter in
                if newChapter != nil && appState.lastScrolledVerse > 1 {
                    withAnimation(AppTheme.Animation.standard) {
                        proxy.scrollTo(appState.lastScrolledVerse, anchor: .top)
                    }
                }
                viewModel.currentVisibleVerse = 1
                onChapterChange()
            }
            .onChange(of: viewModel.flashVerseId) { _, newFlashId in
                if let verseId = newFlashId {
                    withAnimation(AppTheme.Animation.standard) {
                        proxy.scrollTo(verseId, anchor: .center)
                    }
                }
            }
            .onPreferenceChange(VisibleVersePreferenceKey.self) { visibleVerse in
                if let verse = visibleVerse {
                    onVisibleVerseChange(verse)
                }
            }
            .onPreferenceChange(SelectionBoundsPreferenceKey.self) { bounds in
                onSelectionBoundsChange(bounds)
            }
            .onChange(of: scrollTarget) { _, targetId in
                // Auto-scroll to expanded insight section
                if let targetId = targetId {
                    withAnimation(AppTheme.Animation.standard) {
                        proxy.scrollTo(targetId, anchor: .center)
                    }
                    // Clear target after scrolling
                    scrollTarget = nil
                }
            }
            .onChange(of: viewModel.showInlineInsight) { _, showInsight in
                // Auto-scroll to show the inline insight card when it appears
                if showInsight,
                   let range = viewModel.insightSheetRange ?? viewModel.selectedRange {
                    // Small delay to allow the card to render before scrolling
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(AppTheme.Animation.standard) {
                            // Scroll to show both the selected verse and the insight card
                            // Using .top anchor keeps the verse visible with card below
                            proxy.scrollTo(range.verseEnd, anchor: .top)
                        }
                    }
                }
            }
        }
        // Animated top inset for floating top bar
        // When chrome is visible, reserve space so content doesn't hide under it
        // When chrome is hidden, content expands to use full height
        // Height must match ReaderTopBar: icons (36) + vertical padding (12*2) = 60
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear
                .frame(height: showChrome ? 60 : 0)
                .animation(AppTheme.Animation.spring, value: showChrome)
        }
        .offset(x: dragOffset)
        .gesture(swipeNavigationGesture)
    }

    // MARK: - Paragraph Mode Content

    @ViewBuilder
    private func paragraphModeContent(chapter: Chapter) -> some View {
        ParagraphModeView(
            verses: chapter.verses,
            selectedVerses: viewModel.isFocusMode ? [] : viewModel.selectedVerses,
            fontSize: appState.scriptureFontSize,
            lineSpacing: appState.lineSpacing.value,
            onSelectVerse: { verseNum in
                guard !viewModel.isFocusMode else { return }
                onSelectVerse(verseNum)
            },
            getHighlightColor: { verseNum in
                viewModel.highlightColor(for: verseNum)
            }
        )
    }

    // MARK: - Verse Mode Content

    @ViewBuilder
    private func verseModeContent(chapter: Chapter) -> some View {
        ForEach(chapter.verses) { verse in
            VerseText(
                verse: verse,
                isSelected: viewModel.selectedVerses.contains(verse.verse) && !viewModel.isFocusMode,
                fontSize: appState.scriptureFontSize,
                lineSpacing: appState.lineSpacing.value,
                onTap: {
                    guard !viewModel.isFocusMode else { return }
                    onSelectVerse(verse.verse)
                },
                onLongPress: {
                    guard !viewModel.isFocusMode else { return }
                    onLongPressVerse(verse.verse)
                },
                onDoubleTap: {
                    guard !viewModel.isFocusMode else { return }
                    onDoubleTapVerse(verse.verse)
                },
                isPlayingAudio: currentPlayingVerse == verse.verse,
                preservedHighlightOpacity: viewModel.preservedVerses.contains(verse.verse)
                    ? viewModel.preservedHighlightOpacity
                    : 0,
                highlightColor: viewModel.highlightColor(for: verse.verse)
            )
            .id(verse.verse)
            .overlay(flashOverlay(for: verse))
            .background(visibleVerseTracker(for: verse, totalVerses: chapter.verses.count))

            // MARK: - Inline Insight Card (True Inline - below selected verse)
            // Insert the card INLINE after the last selected verse
            if viewModel.showInlineInsight,
               !viewModel.isFocusMode,
               let range = viewModel.insightSheetRange ?? viewModel.selectedRange,
               verse.verse == range.verseEnd,
               let insightVM = viewModel.inlineInsightViewModel {
                InlineInsightCard(
                    verseRange: range,
                    viewModel: insightVM,
                    isVisible: Binding(
                        get: { viewModel.showInlineInsight },
                        set: { if !$0 { viewModel.dismissInlineInsight() } }
                    ),
                    onOpenDeepStudy: {
                        viewModel.openDeepStudySheet()
                    },
                    onDismiss: {
                        viewModel.dismissInlineInsight()
                    },
                    onRequestScroll: { targetId in
                        // Trigger scroll to expanded content
                        scrollTarget = targetId
                    },
                    existingHighlightColor: viewModel.existingHighlightColorForSelection,
                    onSelectHighlightColor: { color in
                        Task {
                            await viewModel.quickHighlight(color: color)
                        }
                    },
                    onRemoveHighlight: {
                        Task {
                            await viewModel.removeHighlightForSelection()
                        }
                    }
                )
                .id("inlineInsight-\(range.verseEnd)")
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
                .padding(.vertical, AppTheme.Spacing.md)
            }
        }
    }

    // MARK: - Flash Overlay (Search Result Highlight)

    @ViewBuilder
    private func flashOverlay(for verse: Verse) -> some View {
        if viewModel.flashVerseId == verse.verse {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(Color.scholarAccent.opacity(flashOpacity * 0.4))
                .onAppear {
                    flashOpacity = 1.0
                    withAnimation(AppTheme.Animation.slow) {
                        flashOpacity = 0
                    }
                    Task {
                        try? await Task.sleep(for: .milliseconds(1500))
                        onFlashAnimationComplete()
                    }
                }
        }
    }

    // MARK: - Visible Verse Tracker (Progress Indication)

    @ViewBuilder
    private func visibleVerseTracker(for verse: Verse, totalVerses: Int) -> some View {
        // Track milestone verses for progress (every 5th verse + first + last)
        if verse.verse == 1 || verse.verse % 5 == 0 || verse.verse == totalVerses {
            GeometryReader { geo in
                Color.clear.preference(
                    key: VisibleVersePreferenceKey.self,
                    value: geo.frame(in: .global).minY < 200 && geo.frame(in: .global).minY > -100
                        ? verse.verse
                        : nil
                )
            }
        }
    }

    // MARK: - Swipe Navigation Gesture

    private var swipeNavigationGesture: some Gesture {
        DragGesture(minimumDistance: AppTheme.Gesture.minimumDragDistance, coordinateSpace: .local)
            .onChanged { value in
                // Disable swipe navigation during selection or when sheet is open
                guard viewModel.selectedRange == nil && !viewModel.showInsightSheet else {
                    return
                }

                // Only respond to horizontal swipes
                if abs(value.translation.width) > abs(value.translation.height) {
                    if value.translation.width > 0 && viewModel.canGoBack {
                        dragOffset = min(value.translation.width * 0.4, AppTheme.Gesture.maxDragOffset)
                    } else if value.translation.width < 0 && viewModel.canGoForward {
                        dragOffset = max(value.translation.width * 0.4, -AppTheme.Gesture.maxDragOffset)
                    }
                }
            }
            .onEnded { value in
                // Disable swipe navigation during selection or when sheet is open
                guard viewModel.selectedRange == nil && !viewModel.showInsightSheet else {
                    withAnimation(AppTheme.Animation.spring) {
                        dragOffset = 0
                    }
                    return
                }

                let horizontalAmount = value.translation.width

                withAnimation(AppTheme.Animation.spring) {
                    dragOffset = 0
                }

                // Navigate if swipe exceeded threshold
                if horizontalAmount > AppTheme.Gesture.swipeThreshold && viewModel.canGoBack && !isNavigating {
                    isNavigating = true
                    Task {
                        await onSwipeNavigate(.previous)
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        isNavigating = false
                    }
                } else if horizontalAmount < -AppTheme.Gesture.swipeThreshold && viewModel.canGoForward && !isNavigating {
                    isNavigating = true
                    Task {
                        await onSwipeNavigate(.next)
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        isNavigating = false
                    }
                }
            }
    }

    // MARK: - Scroll Direction Detection

    private func detectScrollDirection(currentOffset: CGFloat) {
        // Skip the first few scroll events to avoid hiding on initial load
        guard initialScrollCaptured else {
            lastScrollOffset = currentOffset
            // Wait for a small scroll before considering initial captured
            if abs(currentOffset) > 5 {
                initialScrollCaptured = true
            }
            return
        }

        let delta = currentOffset - lastScrollOffset

        // Only trigger if scroll exceeds threshold (prevents jitter)
        if abs(delta) > scrollThreshold {
            if delta > 0 {
                // Scrolling up (revealing top content) - show chrome
                onScrollDirectionChange?(.up)
            } else {
                // Scrolling down (reading) - hide chrome
                onScrollDirectionChange?(.down)
            }
            lastScrollOffset = currentOffset
        }
    }
}

// MARK: - Scroll Direction

enum ScrollDirection {
    case up    // Scrolling up (toward top of content) - show chrome
    case down  // Scrolling down (reading) - hide chrome
}

// MARK: - Reader Scroll Offset Preference Key

struct ReaderScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Chapter Navigation Direction

enum ChapterNavigationDirection {
    case previous
    case next
}

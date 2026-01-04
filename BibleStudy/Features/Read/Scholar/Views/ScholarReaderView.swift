import SwiftUI
import UIKit

// MARK: - Scholar's Marginalia Reader View
// Scholar's Atrium-based reader with verse-by-verse layout
// Full-featured: multi-verse selection, context menu, highlights, AI insights

struct ScholarReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var viewModel: ScholarsReaderViewModel?
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

    let initialLocation: BibleLocation?

    init(location: BibleLocation? = nil) {
        self.initialLocation = location
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - clean vellum cream
                Color.vellumCream
                    .ignoresSafeArea()

                // Subtle paper gradient
                Color.paperGradient
                    .ignoresSafeArea()

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
        .preferredColorScheme(.light)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let viewModel = viewModel {
                    ScholarChapterSelector(
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
                        .foregroundStyle(ScholarPalette.ink)
                }
            }
        }
        .sheet(isPresented: $showReadingMenu) {
            ScholarReadingMenuSheet(
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
                ScholarBookPickerView(
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
            let vm = ScholarsReaderViewModel(location: initialLocation)
            viewModel = vm
            await vm.loadChapter()
            withAnimation(.spring(response: 0.4, dampingFraction: 1.0)) {
                isVisible = true
            }
        }
        .onTapGesture {
            // Tap outside to dismiss context menu
            if let viewModel = viewModel, viewModel.showContextMenu {
                withAnimation(ScholarPalette.Animation.selection) {
                    viewModel.clearSelection()
                }
            }
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
                withAnimation(ScholarPalette.Animation.cardUnfurl) {
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
        .sheet(isPresented: $showAudioPlayer) {
            AudioPlayerSheet(audioService: audioService)
        }
    }

    // MARK: - Navigation Buttons

    private func navigationButtons(viewModel: ScholarsReaderViewModel) -> some View {
        HStack(spacing: ScholarPalette.Spacing.sm) {
            Button {
                Task { await viewModel.goToPreviousChapter() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(viewModel.canGoBack ? Color.scholarInk : Color.scholarInk.opacity(0.3))
            }
            .disabled(!viewModel.canGoBack)

            Button {
                Task { await viewModel.goToNextChapter() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(viewModel.canGoForward ? Color.scholarInk : Color.scholarInk.opacity(0.3))
            }
            .disabled(!viewModel.canGoForward)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: ScholarPalette.Spacing.lg) {
            ProgressView()
                .tint(ScholarPalette.accent)

            Text("Loading...")
                .font(.custom("CormorantGaramond-Regular", size: 16))
                .foregroundStyle(ScholarPalette.footnote)
        }
    }

    // MARK: - Error View

    private func errorView(_ error: Error, viewModel: ScholarsReaderViewModel) -> some View {
        VStack(spacing: ScholarPalette.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(ScholarPalette.accent)

            Text("Unable to load chapter")
                .font(.custom("CormorantGaramond-SemiBold", size: 18))
                .foregroundStyle(ScholarPalette.ink)

            Text(error.localizedDescription)
                .font(.system(size: 14))
                .foregroundStyle(ScholarPalette.footnote)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ScholarPalette.Spacing.xl)

            Button {
                Task { await viewModel.loadChapter() }
            } label: {
                Text("Try Again")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, ScholarPalette.Spacing.lg)
                    .padding(.vertical, ScholarPalette.Spacing.sm)
                    .background(ScholarPalette.accent)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Content View

    private func contentView(chapter: Chapter, geometry: GeometryProxy, viewModel: ScholarsReaderViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Chapter header
                    chapterHeader(viewModel: viewModel)
                        .padding(.top, ScholarPalette.Spacing.xl)
                        .padding(.horizontal, ScholarPalette.Spacing.xl)

                    // Editorial divider
                    editorialDivider
                        .padding(.vertical, ScholarPalette.Spacing.xl)

                    // Verses with inline insight cards
                    versesSection(chapter: chapter, geometry: geometry, viewModel: viewModel)
                        .padding(.horizontal, ScholarPalette.Spacing.lg)

                    // Bottom spacing
                    Spacer()
                        .frame(height: 120)
                }
                .frame(minHeight: geometry.size.height)
            }
            .onAppear {
                scrollProxy = proxy
            }
        }
    }

    // MARK: - Chapter Header

    private func chapterHeader(viewModel: ScholarsReaderViewModel) -> some View {
        VStack(alignment: .leading, spacing: ScholarPalette.Spacing.sm) {
            // Book name - editorial style
            Text(viewModel.book?.name.uppercased() ?? "")
                .font(.system(size: 11, weight: .bold))
                .tracking(2.5)
                .foregroundStyle(ScholarPalette.accent)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.3), value: isVisible)

            // Chapter number
            HStack(spacing: 0) {
                Text("Chapter \(viewModel.currentLocation.chapter)")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(ScholarPalette.ink)

                Spacer()
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .animation(.easeOut(duration: 0.4).delay(0.1), value: isVisible)

            // Greek blue underline
            Rectangle()
                .fill(ScholarPalette.greek)
                .frame(height: 2)
                .frame(maxWidth: 120)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: isVisible)
        }
    }

    // MARK: - Editorial Divider

    private var editorialDivider: some View {
        Rectangle()
            .fill(ScholarPalette.ink.opacity(0.1))
            .frame(height: 1)
            .padding(.horizontal, ScholarPalette.Spacing.xl)
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: isVisible)
    }

    // MARK: - Verses Section

    private func versesSection(chapter: Chapter, geometry: GeometryProxy, viewModel: ScholarsReaderViewModel) -> some View {
        VStack(alignment: .leading, spacing: ScholarPalette.Spacing.lg) {
            ForEach(Array(chapter.verses.enumerated()), id: \.element.id) { index, verse in
                ScholarVerseRow(
                    verse: verse,
                    isSelected: viewModel.isVerseSelected(verse.verse),
                    isInRange: viewModel.selectedVerses.contains(verse.verse),
                    highlightColor: viewModel.highlightColor(for: verse.verse),
                    selectionMode: viewModel.selectionMode,
                    inlineInsight: inlineInsightPayload(for: verse, viewModel: viewModel),
                    isSpokenVerse: currentPlayingVerse == verse.verse,
                    fontSize: appState.scriptureFontSize,
                    lineSpacing: appState.lineSpacing.value,
                    flashOpacity: viewModel.flashVerseId == verse.verse ? flashOpacity : 0,
                    onTap: {
                        withAnimation(ScholarPalette.Animation.selection) {
                            if viewModel.selectionMode == .range {
                                viewModel.extendSelection(to: verse.verse)
                            } else {
                                viewModel.selectVerse(verse.verse)
                            }
                        }
                        HapticService.shared.lightTap()
                    },
                    onLongPress: {
                        withAnimation(ScholarPalette.Animation.selection) {
                            viewModel.startRangeSelection(from: verse.verse)
                        }
                        HapticService.shared.mediumTap()
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

    private func inlineInsightPayload(for verse: Verse, viewModel: ScholarsReaderViewModel) -> ScholarInlineInsightPayload? {
        guard viewModel.showInlineInsight,
              let insightVM = viewModel.inlineInsightViewModel,
              let range = viewModel.insightSheetRange,
              verse.verse == range.verseEnd else {
            return nil
        }

        return ScholarInlineInsightPayload(
            range: range,
            viewModel: insightVM,
            onOpenDeepStudy: {
                // Open deep study sheet
            },
            onDismiss: {
                viewModel.dismissInlineInsight()
            },
            onRequestScroll: { id in
                withAnimation(ScholarPalette.Animation.cardUnfurl) {
                    scrollProxy?.scrollTo(id, anchor: .center)
                }
            },
            onCopy: {
                viewModel.copySelectedVerses()
            },
            onShare: {
                shareVerse(viewModel: viewModel)
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
    }

    // MARK: - Context Menu Overlay

    private func contextMenuOverlay(viewModel: ScholarsReaderViewModel, range: VerseRange, geometry: GeometryProxy) -> some View {
        ScholarContextMenu(
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
                withAnimation(ScholarPalette.Animation.cardUnfurl) {
                    viewModel.openInlineInsight()
                }
            },
            onDismiss: {
                viewModel.clearSelection()
            }
        )
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Share Helper

    private func shareVerse(viewModel: ScholarsReaderViewModel) {
        guard let text = viewModel.getShareText() else { return }
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Scholar Verse Row

private struct ScholarInlineInsightPayload {
    let range: VerseRange
    let viewModel: InsightViewModel
    let onOpenDeepStudy: () -> Void
    let onDismiss: () -> Void
    let onRequestScroll: ((String) -> Void)?
    let onCopy: (() -> Void)?
    let onShare: (() -> Void)?
    let existingHighlightColor: HighlightColor?
    let onSelectHighlightColor: ((HighlightColor) -> Void)?
    let onRemoveHighlight: (() -> Void)?
}

private struct ScholarVerseRow: View {
    let verse: Verse
    let isSelected: Bool
    let isInRange: Bool
    let highlightColor: HighlightColor?
    let selectionMode: ScholarSelectionMode
    let inlineInsight: ScholarInlineInsightPayload?
    let isSpokenVerse: Bool
    let fontSize: ScriptureFontSize
    let lineSpacing: CGFloat
    let flashOpacity: Double
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onBoundsChange: (CGRect) -> Void

    @State private var isPressed = false
    private let verseNumberWidth: CGFloat = 28

    var body: some View {
        VStack(alignment: .leading, spacing: ScholarPalette.Spacing.sm) {
            HStack(alignment: .top, spacing: ScholarPalette.Spacing.md) {
                // Verse number with selection indicator
                ZStack(alignment: .trailing) {
                    // Selection range indicator bar
                    if isInRange && selectionMode == .range {
                        Rectangle()
                            .fill(ScholarPalette.accent)
                            .frame(width: 3)
                            .offset(x: verseNumberWidth + 2)
                    }

                    Text("\(verse.verse)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isSelected ? ScholarPalette.accent : ScholarPalette.ink)
                        .frame(width: verseNumberWidth, alignment: .trailing)
                }

                // Verse text
                Text(verse.text)
                    .font(.custom("CormorantGaramond-Regular", size: fontSize.rawValue + 1))
                    .foregroundStyle(ScholarPalette.inkWell)
                    .lineSpacing(lineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let inlineInsight = inlineInsight {
                HStack(alignment: .top, spacing: ScholarPalette.Spacing.md) {
                    Color.clear
                        .frame(width: verseNumberWidth)

                    ScholarInlineInsightPanel(
                        verseRange: inlineInsight.range,
                        viewModel: inlineInsight.viewModel,
                        onOpenDeepStudy: inlineInsight.onOpenDeepStudy,
                        onDismiss: inlineInsight.onDismiss,
                        onRequestScroll: inlineInsight.onRequestScroll,
                        onCopy: inlineInsight.onCopy,
                        onShare: inlineInsight.onShare,
                        existingHighlightColor: inlineInsight.existingHighlightColor,
                        onSelectHighlightColor: inlineInsight.onSelectHighlightColor,
                        onRemoveHighlight: inlineInsight.onRemoveHighlight
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(ScholarPalette.Spacing.md)
        .background(verseBackground)
        .overlay(verseOverlay)
        .overlay(flashOverlay)
        .overlay(spokenUnderline, alignment: .bottomLeading)
        .clipShape(RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.small))
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
        RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.small)
            .fill(backgroundColor)
    }

    private var backgroundColor: Color {
        if isSelected || isInRange {
            return ScholarPalette.selectionBackground
        } else if isSpokenVerse {
            return Color.accentGold.opacity(0.15)
        } else if let highlight = highlightColor {
            return highlight.color.opacity(0.15)
        } else {
            return Color.clear
        }
    }

    // MARK: - Verse Overlay

    @ViewBuilder
    private var verseOverlay: some View {
        RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.small)
            .stroke(overlayColor, lineWidth: isSelected ? 1.5 : 1)
    }

    private var overlayColor: Color {
        if isSelected {
            return ScholarPalette.selectionBorder
        } else if isInRange {
            return ScholarPalette.accent.opacity(0.2)
        } else {
            return Color.clear
        }
    }


    @ViewBuilder
    private var flashOverlay: some View {
        if flashOpacity > 0 {
            RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.small)
                .fill(Color.accentGold.opacity(flashOpacity * 0.4))
        }
    }

    @ViewBuilder
    private var spokenUnderline: some View {
        if isSpokenVerse {
            Rectangle()
                .fill(ScholarPalette.InlineInsight.spokenUnderline)
                .frame(height: 2)
                .padding(.leading, verseNumberWidth + ScholarPalette.Spacing.md)
                .padding(.trailing, ScholarPalette.Spacing.sm)
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
        ScholarReaderView(location: .john1)
    }
    .environment(BibleService.shared)
}

#Preview("With Selection") {
    NavigationStack {
        ScholarReaderView(location: .genesis1)
    }
    .environment(BibleService.shared)
}

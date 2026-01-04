//
//  PagedReaderView.swift
//  BibleStudy
//
//  E-reader style Bible reading with page curl effect
//

import SwiftUI
import UIKit

// MARK: - Paged Reader View

struct PagedReaderView: View {
    @Environment(AppState.self) private var appState
    var viewModel: ReaderViewModel

    // Page curl configuration
    @State private var curlConfig: PageCurlCarouselConfig = .init(curlRadius: 60)
    @State private var pages: [PagedContentModel.Page] = []
    @State private var currentPageIndex: Int = 0

    // Size tracking for page calculation
    @State private var availableSize: CGSize = .zero

    // Floating context menu positioning
    @State private var selectionBounds: CGRect? = nil

    // Share sheet
    @State private var showShareSheet: Bool = false
    @State private var shareText: String = ""

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                // Background
                (appState.preferredTheme.customBackground ?? Color.appBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Page content with curl effect
                    if let chapter = viewModel.chapter, !pages.isEmpty {
                        PageCurlCarousel(config: curlConfig) { _ in
                            ForEach(pages) { page in
                                PageContentView(
                                    page: page,
                                    chapter: chapter,
                                    viewModel: viewModel,
                                    fontSize: appState.scriptureFontSize,
                                    lineSpacing: appState.lineSpacing.value,
                                    theme: appState.preferredTheme
                                )
                            }
                        }
                        .frame(width: pageSize(size).width, height: pageSize(size).height)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Loading state
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // Page indicator
                    pageIndicator
                }

                // Floating Context Menu (positioned above selected verse)
                // Hidden in Focus Mode for immersive reading
                // Also hidden when inline insight is showing
                if let range = viewModel.selectedRange,
                   let bounds = selectionBounds,
                   !viewModel.isFocusMode,
                   !viewModel.showInlineInsight {
                    floatingContextMenuContent(range: range, bounds: bounds, geometry: geometry)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.85, anchor: .bottom).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                }

                // MARK: - Inline Insight Card (New UX)
                // Shows at bottom when user taps "Interpret" in context menu
                if viewModel.showInlineInsight,
                   let range = viewModel.insightSheetRange ?? viewModel.selectedRange,
                   let insightVM = viewModel.inlineInsightViewModel,
                   !viewModel.isFocusMode {
                    VStack {
                        Spacer()
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
                        .padding(.bottom, AppTheme.Spacing.lg)
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            .onChange(of: size) { _, newSize in
                if availableSize != newSize {
                    availableSize = newSize
                    recalculatePages()
                }
            }
            .onChange(of: viewModel.chapter) { _, _ in
                recalculatePages()
            }
            .onChange(of: appState.scriptureFontSize) { _, _ in
                recalculatePages()
            }
            .onChange(of: appState.lineSpacing) { _, _ in
                recalculatePages()
            }
            .onAppear {
                availableSize = size
                setupCurlConfig()
                recalculatePages()
            }
            .onPreferenceChange(SelectionBoundsPreferenceKey.self) { bounds in
                selectionBounds = bounds
            }
            .sheet(isPresented: $showShareSheet) {
                PagedReaderShareSheet(items: [shareText])
            }
            // MARK: - Deep Study Sheet
            .sheet(isPresented: Binding(
                get: { viewModel.showDeepStudySheet },
                set: { if !$0 { viewModel.dismissDeepStudySheet() } }
            )) {
                if let range = viewModel.insightSheetRange ?? viewModel.selectedRange,
                   let insightVM = viewModel.inlineInsightViewModel {
                    DeepStudySheet(
                        verseRange: range,
                        viewModel: insightVM,
                        onDismiss: {
                            viewModel.dismissDeepStudySheet()
                        }
                    )
                }
            }
            .animation(AppTheme.Animation.standard, value: viewModel.selectedVerses)
            .animation(AppTheme.Animation.sacredSpring, value: viewModel.showInlineInsight)
        }
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Chapter navigation (previous)
            Button {
                Task { await viewModel.goToPreviousChapter() }
            } label: {
                Image(systemName: "chevron.left.2")
                    .font(Typography.UI.subheadline)
                    .foregroundStyle(viewModel.canGoBack ? Color.primaryText : Color.tertiaryText)
            }
            .disabled(!viewModel.canGoBack)

            Spacer()

            // Page info
            VStack(spacing: AppTheme.Spacing.xxs) {
                Text("Page \(currentPageIndex + 1) of \(pages.count)")
                    .font(Typography.UI.caption1.monospacedDigit())
                    .foregroundStyle(Color.secondaryText)

                if let chapter = viewModel.chapter {
                    Text(chapter.reference)
                        .font(Typography.UI.caption2.monospacedDigit())
                        .foregroundStyle(Color.tertiaryText)
                }
            }

            Spacer()

            // Chapter navigation (next)
            Button {
                Task { await viewModel.goToNextChapter() }
            } label: {
                Image(systemName: "chevron.right.2")
                    .font(Typography.UI.subheadline)
                    .foregroundStyle(viewModel.canGoForward ? Color.primaryText : Color.tertiaryText)
            }
            .disabled(!viewModel.canGoForward)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(
            (appState.preferredTheme.customSurface ?? Color.surfaceBackground)
                .opacity(AppTheme.Opacity.nearOpaque)
        )
    }

    // MARK: - Helpers

    private func setupCurlConfig() {
        curlConfig = PageCurlCarouselConfig(
            curlRadius: 60,
            curlShadow: 0.3,
            underneathShadow: 0.1,
            roundedRectangle: .init(topLeft: 0, topRight: 12, bottomLeft: 0, bottomRight: 12),
            curlCenter: .init(x: 1, y: 0.4),
            isCurledUpVisible: true
        )
    }

    private func recalculatePages() {
        guard let chapter = viewModel.chapter, availableSize.width > 0 else {
            pages = []
            return
        }

        let calculatedSize = pageSize(availableSize)
        pages = PagedContentModel.calculatePages(
            chapter: chapter,
            availableSize: calculatedSize,
            fontSize: appState.scriptureFontSize,
            lineSpacing: appState.lineSpacing.value
        )

        // Reset to first page when chapter changes
        currentPageIndex = 0

        // If we have a saved verse position, find that page
        if viewModel.currentVisibleVerse > 1,
           let pageIndex = PagedContentModel.pageIndex(for: viewModel.currentVisibleVerse, in: pages) {
            currentPageIndex = pageIndex
        }
    }

    private func pageSize(_ viewSize: CGSize) -> CGSize {
        // Calculate page size maintaining aspect ratio
        let maxWidth = min(viewSize.width - AppTheme.Spacing.lg * 2, 500)
        let maxHeight = viewSize.height - 60 // Leave room for page indicator

        // Use full available space
        return CGSize(width: maxWidth, height: maxHeight)
    }

    // MARK: - Floating Context Menu

    /// Floating context menu that appears above selected verse
    /// Uses VerseContextMenu component with UX laws applied
    @ViewBuilder
    private func floatingContextMenuContent(range: VerseRange, bounds: CGRect, geometry: GeometryProxy) -> some View {
        VerseContextMenu(
            verseRange: range,
            selectionBounds: bounds,
            existingHighlightColor: viewModel.existingHighlightColorForSelection,
            safeAreaInsets: geometry.safeAreaInsets,
            containerBounds: geometry.frame(in: .global),
            onCopy: {
                copySelectedVerses()
            },
            onInterpret: {
                // Open deep study sheet for full interpretation
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
            onDismiss: {
                viewModel.clearSelection()
            }
        )
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
        HapticService.shared.success()

        // Clear selection after copy
        viewModel.clearSelection()
    }

    private func prepareShareText() {
        guard let range = viewModel.selectedRange else { return }

        let verseText = getSelectedVersesText()
        shareText = "\"\(verseText)\"\n\n— \(range.reference)"
    }
}

// MARK: - Share Sheet for PagedReaderView

private struct PagedReaderShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Page Content View

/// A single page of verses
private struct PageContentView: View {
    let page: PagedContentModel.Page
    let chapter: Chapter
    var viewModel: ReaderViewModel
    let fontSize: ScriptureFontSize
    let lineSpacing: CGFloat
    let theme: AppThemeMode

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Verses on this page
            ForEach(page.verses) { verse in
                VerseText(
                    verse: verse,
                    isSelected: viewModel.selectedVerses.contains(verse.verse) && !viewModel.isFocusMode,
                    fontSize: fontSize,
                    lineSpacing: lineSpacing,
                    onTap: {
                        guard !viewModel.isFocusMode else { return }
                        // Toggle: if tapping the same verse with insight showing, dismiss it
                        if viewModel.selectedVerses.count == 1,
                           viewModel.selectedVerses.contains(verse.verse),
                           viewModel.showInlineInsight {
                            viewModel.dismissInlineInsight()
                            viewModel.clearSelection()
                        } else {
                            viewModel.selectVerse(verse.verse)
                            // Open inline insight directly (skip context menu)
                            viewModel.openInlineInsight()
                        }
                    },
                    onLongPress: {
                        guard !viewModel.isFocusMode else { return }
                        viewModel.selectVerse(verse.verse)
                        viewModel.selectionMode = .range
                        // Open inline insight directly (same as single tap)
                        viewModel.openInlineInsight()
                    }
                )
                .id(verse.verse)
            }

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.customBackground ?? Color.appBackground)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PagedReaderView(viewModel: ReaderViewModel())
    }
    .environment(AppState())
}

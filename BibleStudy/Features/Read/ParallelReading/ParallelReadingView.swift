import SwiftUI

// MARK: - Parallel Reading View
// Split-screen view for comparing two passages side-by-side

struct ParallelReadingView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: ParallelReadingViewModel
    @State private var showLeftPicker = false
    @State private var showRightPicker = false
    @State private var showPresets = false

    // Scale verse number width with Dynamic Type
    @ScaledMetric(relativeTo: .caption) private var verseNumberWidth: CGFloat = 24

    init(
        leftLocation: BibleLocation = BibleLocation(bookId: 1, chapter: 1),
        rightLocation: BibleLocation = BibleLocation(bookId: 43, chapter: 1)
    ) {
        _viewModel = State(initialValue: ParallelReadingViewModel(
            leftLocation: leftLocation,
            rightLocation: rightLocation
        ))
    }

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let isWide = geometry.size.width > 600

            if isLandscape || isWide {
                // Side-by-side layout
                HStack(spacing: 0) {
                    leftPanel
                        .frame(maxWidth: .infinity)

                    Divider()

                    rightPanel
                        .frame(maxWidth: .infinity)
                }
            } else {
                // Tab layout for portrait
                TabView {
                    leftPanel
                        .tabItem {
                            Label(viewModel.leftTitle, systemImage: "1.circle")
                        }

                    rightPanel
                        .tabItem {
                            Label(viewModel.rightTitle, systemImage: "2.circle")
                        }
                }
            }
        }
        .navigationTitle("Parallel Reading")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        viewModel.swapPanels()
                    } label: {
                        Label("Swap Panels", systemImage: "arrow.left.arrow.right")
                    }

                    Toggle(isOn: $viewModel.syncScrolling) {
                        Label("Sync Scrolling", systemImage: "link")
                    }

                    Divider()

                    Menu {
                        ForEach(ParallelReadingViewModel.synopticPresets, id: \.name) { preset in
                            Button(preset.name) {
                                Task {
                                    await viewModel.loadSynopticPreset(preset)
                                }
                            }
                        }
                    } label: {
                        Label("Synoptic Gospels", systemImage: "book.pages")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await viewModel.loadBothChapters()
        }
        .sheet(isPresented: $showLeftPicker) {
            BookPickerView(
                currentBookId: viewModel.leftLocation.bookId,
                currentChapter: viewModel.leftLocation.chapter
            ) { bookId, chapter in
                Task {
                    await viewModel.goToLeftChapter(bookId: bookId, chapter: chapter)
                }
            }
        }
        .sheet(isPresented: $showRightPicker) {
            BookPickerView(
                currentBookId: viewModel.rightLocation.bookId,
                currentChapter: viewModel.rightLocation.chapter
            ) { bookId, chapter in
                Task {
                    await viewModel.goToRightChapter(bookId: bookId, chapter: chapter)
                }
            }
        }
    }

    // MARK: - Left Panel

    private var leftPanel: some View {
        VStack(spacing: 0) {
            // Header
            panelHeader(
                title: viewModel.leftTitle,
                onBookTap: { showLeftPicker = true },
                onPrevious: { Task { await viewModel.goToPreviousLeft() } },
                onNext: { Task { await viewModel.goToNextLeft() } },
                canGoPrevious: viewModel.leftLocation.chapter > 1,
                canGoNext: true
            )

            Divider()

            // Content
            if viewModel.isLoadingLeft {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if let chapter = viewModel.leftChapter {
                chapterContent(chapter: chapter)
            } else {
                Text("No content")
                    .foregroundStyle(Color.secondaryText)
                    .frame(maxHeight: .infinity)
            }
        }
        .background(Color.appBackground)
    }

    // MARK: - Right Panel

    private var rightPanel: some View {
        VStack(spacing: 0) {
            // Header
            panelHeader(
                title: viewModel.rightTitle,
                onBookTap: { showRightPicker = true },
                onPrevious: { Task { await viewModel.goToPreviousRight() } },
                onNext: { Task { await viewModel.goToNextRight() } },
                canGoPrevious: viewModel.rightLocation.chapter > 1,
                canGoNext: true
            )

            Divider()

            // Content
            if viewModel.isLoadingRight {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if let chapter = viewModel.rightChapter {
                chapterContent(chapter: chapter)
            } else {
                Text("No content")
                    .foregroundStyle(Color.secondaryText)
                    .frame(maxHeight: .infinity)
            }
        }
        .background(Color.appBackground)
    }

    // MARK: - Panel Header

    private func panelHeader(
        title: String,
        onBookTap: @escaping () -> Void,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void,
        canGoPrevious: Bool,
        canGoNext: Bool
    ) -> some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(canGoPrevious ? Color.primaryText : Color.tertiaryText)
            }
            .disabled(!canGoPrevious)

            Spacer()

            Button(action: onBookTap) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Text(title)
                        .font(Typography.UI.headline)
                        .foregroundStyle(Color.primaryText)

                    Image(systemName: "chevron.down")
                        .font(Typography.UI.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.secondaryText)
                }
            }

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(canGoNext ? Color.primaryText : Color.tertiaryText)
            }
            .disabled(!canGoNext)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(Color.surfaceBackground)
    }

    // MARK: - Chapter Content

    private func chapterContent(chapter: Chapter) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(chapter.verses) { verse in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                        Text("\(verse.verse)")
                            .font(Typography.Scripture.verseNumber.monospacedDigit())
                            .foregroundStyle(Color.verseNumber)
                            .frame(width: verseNumberWidth, alignment: .trailing)

                        Text(verse.text)
                            .font(Typography.Scripture.bodyWithSize(appState.scriptureFontSize))
                            .foregroundStyle(Color.primaryText)
                    }
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .id(verse.verse)
                }
            }
            .padding(.vertical, AppTheme.Spacing.md)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ParallelReadingView(
            leftLocation: BibleLocation(bookId: 40, chapter: 5),
            rightLocation: BibleLocation(bookId: 42, chapter: 6)
        )
    }
    .environment(AppState())
}

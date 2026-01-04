import SwiftUI

// MARK: - Ask Tab View
// AI-powered Q&A with verse-anchored mode
// Thin wrapper that creates its own viewModel for backward compatibility

struct AskTabView: View {
    @State private var viewModel = AskViewModel()

    var body: some View {
        AskTabContentView(viewModel: viewModel)
    }
}

// MARK: - Ask Tab Content View
// Extracted content view that accepts external viewModel
// Used by both AskTabView (standalone) and AskModalView (modal presentation)

struct AskTabContentView: View {
    @Bindable var viewModel: AskViewModel
    var showCloseButton: Bool = false
    var onClose: (() -> Void)?
    @FocusState private var isInputFocused: Bool
    @State private var showConsentSheet = false
    @State private var showSearch = false
    @AppStorage(AppConfiguration.UserDefaultsKeys.hasConsentedToAIProcessing)
    private var hasAIConsent: Bool = false

    // MARK: - Entrance Animation State
    @State private var contentAppeared = false
    @State private var contentOffset: CGFloat = 30

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages or Empty State with entrance animation
                if viewModel.messages.isEmpty {
                    ScrollView {
                        askEmptyState
                            .frame(maxWidth: .infinity)
                            .padding(.top, AppTheme.Spacing.lg)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture {
                        isInputFocused = false
                    }
                    .offset(y: contentOffset)
                    .opacity(contentAppeared ? 1 : 0)
                } else {
                    // Living Scroll: Revolutionary illuminated manuscript chat experience
                    LivingScrollView(
                        messages: viewModel.messages,
                        isLoading: viewModel.isLoading,
                        lastUncertaintyLevel: viewModel.lastUncertaintyLevel,
                        suggestedFollowUps: viewModel.suggestedFollowUps,
                        onSelectFollowUp: { question in
                            // Auto-send follow-up questions without requiring keyboard
                            viewModel.inputText = question
                            HapticService.shared.divineReveal()
                            Task {
                                await viewModel.sendMessage()
                            }
                        },
                        onDismissKeyboard: {
                            isInputFocused = false
                        }
                    )
                    .opacity(contentAppeared ? 1 : 0)
                }
            }
            .background(ScholarAskPalette.background)
            .safeAreaInset(edge: .bottom) {
                // Animated Input Bar with expandable actions
                if hasAIConsent {
                    AskAnimatedInputBar(
                        text: $viewModel.inputText,
                        isLoading: viewModel.isLoading,
                        isFocused: $isInputFocused,
                        anchorRange: viewModel.anchorRange,
                        onSend: {
                            Task {
                                await viewModel.sendMessage()
                            }
                        },
                        onVersePicker: {
                            viewModel.showVersePicker = true
                        },
                        onSearch: {
                            showSearch = true
                        },
                        onClearAnchor: {
                            viewModel.clearAnchor()
                        }
                    )
                } else {
                    ConsentRequiredBar {
                        showConsentSheet = true
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Close button (only shown in modal presentation)
                if showCloseButton {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            HapticService.shared.lightTap()
                            onClose?()
                        } label: {
                            Image(systemName: "xmark")
                                .font(Typography.UI.body.weight(.medium))
                                .foregroundStyle(Color.secondaryText)
                        }
                        .accessibilityLabel("Close")
                        .accessibilityHint("Dismisses the Ask chat")
                        .disabled(viewModel.isLoading)
                        .opacity(viewModel.isLoading ? AppTheme.Opacity.disabled : 1.0)
                    }
                }

                // Trailing menu
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.startNewChat()
                        } label: {
                            Label("New Chat", systemImage: "plus")
                        }

                        Button {
                            viewModel.showHistory = true
                        } label: {
                            Label("History", systemImage: "clock")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showHistory) {
                ChatHistorySheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showVersePicker) {
                VersePickerSheet { range in
                    viewModel.setAnchor(range)
                }
            }
            .sheet(isPresented: $showSearch) {
                NavigationStack {
                    SearchView(onNavigate: { range in
                        // When user selects a verse from search, set it as anchor
                        viewModel.setAnchor(range)
                    })
                }
            }
            .sheet(isPresented: $showConsentSheet, onDismiss: {}) {
                AIConsentView(
                    onConsent: {},
                    onDecline: {}
                )
                .interactiveDismissDisabled()
            }
            .alert(
                viewModel.errorAlertTitle,
                isPresented: $viewModel.showError,
                presenting: viewModel.errorMessage
            ) { _ in
                errorAlertButtons
            } message: { message in
                Text(message)
            }
            .onAppear {
                checkAIConsent()
                startEntranceAnimation()
            }
        }
    }

    // MARK: - Entrance Animation

    private func startEntranceAnimation() {
        // Skip animation if already appeared or reduce motion is enabled
        guard !contentAppeared else { return }

        if respectsReducedMotion {
            contentOffset = 0
            contentAppeared = true
            return
        }

        // Content unfurls with spring animation
        withAnimation(AppTheme.Animation.unfurl) {
            contentOffset = 0
            contentAppeared = true
        }
    }

    // MARK: - Error Alert Buttons

    @ViewBuilder
    private var errorAlertButtons: some View {
        if viewModel.canRetry {
            Button("Retry") {
                Task {
                    await viewModel.retryLastMessage()
                }
            }
        }
        Button("Dismiss", role: .cancel) {
            viewModel.dismissError()
        }
    }

    // MARK: - Consent Check

    private func checkAIConsent() {
        if !hasAIConsent {
            showConsentSheet = true
        }
    }

    // MARK: - Empty State

    private var askEmptyState: some View {
        WarmAskLandingView(
            onSelectQuestion: { question in
                // Only auto-send if user has consented
                guard hasAIConsent else {
                    showConsentSheet = true
                    return
                }
                viewModel.inputText = question
                HapticService.shared.softTap()
                Task {
                    await viewModel.sendMessage()
                }
            },
            onRequestConsent: {
                showConsentSheet = true
            }
        )
    }
}

// MARK: - Chat History Sheet
// Enhanced with date sections and manuscript styling

struct ChatHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AskViewModel

    // Group threads by date section
    private var groupedThreads: [(section: HistorySection, threads: [ChatThread])] {
        let today = Calendar.current.startOfDay(for: Date())
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today) ?? today

        var todayThreads: [ChatThread] = []
        var thisWeekThreads: [ChatThread] = []
        var earlierThreads: [ChatThread] = []

        for thread in viewModel.threads {
            let threadDay = Calendar.current.startOfDay(for: thread.updatedAt)
            if threadDay == today {
                todayThreads.append(thread)
            } else if threadDay >= weekAgo {
                thisWeekThreads.append(thread)
            } else {
                earlierThreads.append(thread)
            }
        }

        var result: [(section: HistorySection, threads: [ChatThread])] = []
        if !todayThreads.isEmpty {
            result.append((.today, todayThreads))
        }
        if !thisWeekThreads.isEmpty {
            result.append((.thisWeek, thisWeekThreads))
        }
        if !earlierThreads.isEmpty {
            result.append((.earlier, earlierThreads))
        }
        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.threads.isEmpty {
                    emptyHistoryState
                } else {
                    historyList
                }
            }
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - History List

    private var historyList: some View {
        List {
            ForEach(groupedThreads, id: \.section) { group in
                Section {
                    ForEach(group.threads) { thread in
                        HistoryThreadRow(thread: thread) {
                            viewModel.selectThread(thread)
                            dismiss()
                        }
                        .listRowBackground(Color.surfaceBackground)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteThread(group.threads[index])
                        }
                    }
                } header: {
                    HistorySectionHeader(section: group.section)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }

    // MARK: - Empty State

    private var emptyHistoryState: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "book.closed")
                .font(.system(size: Typography.Scale.xxxl, weight: .light, design: .serif))
                .foregroundStyle(Color.divineGold.opacity(AppTheme.Opacity.medium))

            Text("No Conversations Yet")
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)

            Text("Your chat history will appear here")
                .font(Typography.UI.body)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

// MARK: - History Section

private enum HistorySection: Hashable {
    case today
    case thisWeek
    case earlier

    var title: String {
        switch self {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .earlier: return "Earlier"
        }
    }

    var icon: String {
        switch self {
        case .today: return "sun.max"
        case .thisWeek: return "calendar"
        case .earlier: return "clock.arrow.circlepath"
        }
    }
}

// MARK: - Section Header

private struct HistorySectionHeader: View {
    let section: HistorySection

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: section.icon)
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.divineGold)

            Text(section.title)
                .font(Typography.Illuminated.footnote)
                .foregroundStyle(Color.secondaryText)
                .textCase(nil)

            // Golden divider line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.divineGold.opacity(AppTheme.Opacity.light),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: AppTheme.Divider.thin)
        }
        .padding(.top, AppTheme.Spacing.sm)
    }
}

// MARK: - Thread Row

private struct HistoryThreadRow: View {
    let thread: ChatThread
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Golden book icon
                ZStack {
                    Circle()
                        .fill(Color.divineGold.opacity(AppTheme.Opacity.subtle))
                        .frame(width: 40, height: 40)

                    Image(systemName: "book.closed.fill")
                        .font(Typography.UI.body)
                        .foregroundStyle(Color.divineGold)
                }

                // Thread content
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(thread.displayTitle)
                        .font(Typography.UI.bodyBold)
                        .foregroundStyle(Color.primaryText)
                        .lineLimit(1)

                    if let lastMessage = thread.lastMessage {
                        Text(lastMessage.content)
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.secondaryText)
                            .lineLimit(2)
                    }

                    // Time indicator
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "clock")
                            .font(Typography.UI.caption2)
                            .foregroundStyle(Color.divineGold.opacity(AppTheme.Opacity.medium))

                        Text(thread.updatedAt.formatted(.relative(presentation: .named)))
                            .font(Typography.UI.caption2)
                            .foregroundStyle(Color.tertiaryText)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(.vertical, AppTheme.Spacing.xs)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Verse Picker Sheet

struct VersePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (VerseRange) -> Void

    var body: some View {
        // BookPickerView provides its own NavigationStack, title, and Cancel button
        BookPickerView(currentBookId: 1, currentChapter: 1) { bookId, chapter in
            let range = VerseRange(bookId: bookId, chapter: chapter, verseStart: 1, verseEnd: 99)
            onSelect(range)
            dismiss()
        }
    }
}

// MARK: - Previews

#Preview {
    AskTabView()
        .environment(AppState())
}

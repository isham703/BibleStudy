import SwiftUI

// MARK: - Memorization Queue View
// Shows all memorization items with due dates and mastery levels

struct MemorizationQueueView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var memorizationService = MemorizationService.shared
    @State private var selectedItem: MemorizationItem?
    @State private var showingPractice = false
    @State private var selectedFilter: MasteryFilter = .all

    // Celebration state
    @State private var showCelebration = false
    @State private var currentCelebration: CelebrationType = .correctAnswer
    @State private var pendingNextItem: MemorizationItem?
    @State private var shouldDismissAfterCelebration = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats header
                statsHeader

                // Filter tabs
                filterTabs

                // Content
                if memorizationService.isLoading {
                    loadingView
                } else if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    itemsList
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Memorization")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if memorizationService.dueCount > 0 {
                        Button {
                            startPracticeSession()
                        } label: {
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: "play.fill")
                                Text("Practice")
                            }
                            .font(Typography.Command.subheadline)
                            .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentIndigo)
                    }
                }
            }
            .task {
                await memorizationService.loadItems()
            }
            .sheet(isPresented: $showingPractice) {
                if let item = selectedItem {
                    NavigationStack {
                        MemorizeView(
                            item: item,
                            onComplete: { quality in
                                handleReviewComplete(item: item, quality: quality)
                            },
                            onSkip: {
                                moveToNextItem()
                            }
                        )
                        .celebrationOverlay(isPresented: $showCelebration, celebration: currentCelebration)
                    }
                }
            }
            .onChange(of: showCelebration) { _, isShowing in
                if !isShowing {
                    handleCelebrationComplete()
                }
            }
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: Theme.Spacing.lg) {
            statCard(
                icon: "flame.fill",
                value: "\(memorizationService.dueCount)",
                label: "Due Today",
                color: memorizationService.dueCount > 0 ? Color.accentIndigo : .secondaryText
            )

            statCard(
                icon: "checkmark.seal.fill",
                value: "\(memorizationService.masteredCount)",
                label: "Mastered",
                color: .success
            )

            statCard(
                icon: "book.pages.fill",
                value: "\(memorizationService.totalItems)",
                label: "Total",
                color: Color.accentIndigo
            )
        }
        .padding()
        .background(Color.elevatedBackground)
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(Typography.Command.title2)
                .foregroundStyle(color)

            Text(value)
                .font(Typography.Command.headline.monospacedDigit())
                .foregroundStyle(Color.primaryText)

            Text(label)
                .font(Typography.Command.meta)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(MasteryFilter.allCases, id: \.self) { filter in
                    filterTab(filter)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .background(Color.surfaceBackground)
    }

    private func filterTab(_ filter: MasteryFilter) -> some View {
        let count = countForFilter(filter)

        return Button {
            withAnimation {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Text(filter.displayName)
                if count > 0 {
                    Text("\(count)")
                        .font(Typography.Command.meta.monospacedDigit())
                        .padding(.horizontal, Theme.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter ? Color.white.opacity(Theme.Opacity.medium) : Color.tertiaryText.opacity(Theme.Opacity.lightMedium))
                        )
                }
            }
            .font(Typography.Command.subheadline)
            .foregroundStyle(selectedFilter == filter ? .white : Color.secondaryText)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                Capsule()
                    .fill(selectedFilter == filter ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(selectedFilter == filter ? Color.clear : Color.cardBorder, lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }

    private func countForFilter(_ filter: MasteryFilter) -> Int {
        switch filter {
        case .all: return memorizationService.totalItems
        case .due: return memorizationService.dueCount
        case .learning: return memorizationService.learningCount
        case .reviewing: return memorizationService.reviewingCount
        case .mastered: return memorizationService.masteredCount
        }
    }

    private var filteredItems: [MemorizationItem] {
        switch selectedFilter {
        case .all: return memorizationService.items
        case .due: return memorizationService.dueItems
        case .learning: return memorizationService.getItems(masteryLevel: .learning)
        case .reviewing: return memorizationService.getItems(masteryLevel: .reviewing)
        case .mastered: return memorizationService.getItems(masteryLevel: .mastered)
        }
    }

    // MARK: - Items List

    private var itemsList: some View {
        List {
            ForEach(filteredItems) { item in
                MemorizationItemRow(item: item)
                    .listRowBackground(Color.surfaceBackground)
                    .listRowSeparator(.hidden)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedItem = item
                        showingPractice = true
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            Task {
                                try? await memorizationService.removeItem(item)
                            }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(
            icon: emptyStateIcon,
            title: emptyStateTitle,
            message: emptyStateMessage,
            animation: emptyStateAnimation
        )
    }

    private var emptyStateIcon: String {
        switch selectedFilter {
        case .all: return "brain.head.profile"
        case .due: return "checkmark.circle"
        case .learning: return "book.pages"
        case .reviewing: return "arrow.clockwise"
        case .mastered: return "checkmark.seal.fill"
        }
    }

    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all: return "No Verses to Memorize"
        case .due: return "All Caught Up!"
        case .learning: return "No New Verses"
        case .reviewing: return "No Verses in Review"
        case .mastered: return "No Mastered Verses Yet"
        }
    }

    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all: return "Select verses from the reader and tap 'Memorize' to start building your memorization queue."
        case .due: return "Great job! You've completed all your reviews for today. Check back tomorrow."
        case .learning: return "All verses have progressed past the initial learning phase."
        case .reviewing: return "Verses move here after the initial learning phase."
        case .mastered: return "Keep reviewing! Verses become mastered after consistent correct recalls."
        }
    }

    private var emptyStateAnimation: EmptyStateAnimationType {
        switch selectedFilter {
        case .all: return .noVersesToMemorize
        case .due: return .allCaughtUp
        case .learning, .reviewing, .mastered: return .noVersesToMemorize
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.05)
            Text("Loading...")
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color.secondaryText)
                .padding(.top)
            Spacer()
        }
    }

    // MARK: - Practice Session

    private func startPracticeSession() {
        if let firstDue = memorizationService.getNextDueItem() {
            selectedItem = firstDue
            showingPractice = true
        }
    }

    private func moveToNextItem() {
        if let nextItem = memorizationService.getNextDueItem(), nextItem.id != selectedItem?.id {
            selectedItem = nextItem
        } else {
            showingPractice = false
            selectedItem = nil
        }
    }

    // MARK: - Celebration Handling

    private func handleReviewComplete(item: MemorizationItem, quality: ReviewQuality) {
        Task {
            // Get the state before the review
            let previousMasteryLevel = item.masteryLevel
            let previousMasteredCount = memorizationService.masteredCount
            let previousRepetitions = item.repetitions

            // Record the review
            try? await memorizationService.recordReview(item: item, quality: quality)

            // Get updated item
            let updatedItem = memorizationService.items.first { $0.id == item.id }
            let newMasteryLevel = updatedItem?.masteryLevel ?? item.masteryLevel
            let newRepetitions = updatedItem?.repetitions ?? item.repetitions
            _ = memorizationService.masteredCount // Track mastered count for future celebration features

            // Determine which celebration to show (priority order)
            await MainActor.run {
                // Prepare next item info
                if let nextItem = memorizationService.getNextDueItem(), nextItem.id != item.id {
                    pendingNextItem = nextItem
                    shouldDismissAfterCelebration = false
                } else {
                    pendingNextItem = nil
                    shouldDismissAfterCelebration = true
                }

                // Check for first verse mastered (highest priority)
                if newMasteryLevel == .mastered && previousMasteryLevel != .mastered && previousMasteredCount == 0 {
                    currentCelebration = .firstVerseMastered
                    showCelebration = true
                    return
                }

                // Check for level up (verse mastery level change)
                if newMasteryLevel != previousMasteryLevel {
                    currentCelebration = .levelUp(from: previousMasteryLevel, to: newMasteryLevel)
                    showCelebration = true
                    return
                }

                // Check for streak milestones (3, 7, 14, 21, 30, etc.)
                let streakMilestones = [3, 7, 14, 21, 30, 50, 100]
                if quality.isCorrect && streakMilestones.contains(newRepetitions) && newRepetitions > previousRepetitions {
                    currentCelebration = .streak(newRepetitions)
                    showCelebration = true
                    return
                }

                // Show correct/incorrect feedback for regular answers
                if quality.isCorrect {
                    currentCelebration = .correctAnswer
                    showCelebration = true
                } else {
                    currentCelebration = .wrongAnswer
                    showCelebration = true
                }
            }
        }
    }

    private func handleCelebrationComplete() {
        // Move to next item after celebration finishes
        if shouldDismissAfterCelebration {
            showingPractice = false
            selectedItem = nil
        } else if let nextItem = pendingNextItem {
            selectedItem = nextItem
        }
        pendingNextItem = nil
        shouldDismissAfterCelebration = false
    }
}

// MARK: - Mastery Filter

enum MasteryFilter: String, CaseIterable {
    case all
    case due
    case learning
    case reviewing
    case mastered

    var displayName: String {
        switch self {
        case .all: return "All"
        case .due: return "Due"
        case .learning: return "Learning"
        case .reviewing: return "Reviewing"
        case .mastered: return "Mastered"
        }
    }
}

// MARK: - Memorization Item Row

struct MemorizationItemRow: View {
    let item: MemorizationItem

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header with reference and mastery
            HStack {
                Text(item.reference)
                    .font(Typography.Command.headline)
                    .foregroundStyle(Color.primaryText)

                Spacer()

                masteryBadge
            }

            // Verse preview
            Text(item.verseText)
                .font(Typography.Command.body)
                .foregroundStyle(Color.secondaryText)
                .lineLimit(2)

            // Footer with due date and stats
            HStack {
                // Due date
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: item.isDueForReview ? "bell.fill" : "calendar")
                        .font(Typography.Command.caption)
                    Text(dueDateText)
                        .font(Typography.Command.caption)
                }
                .foregroundStyle(item.isDueForReview ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Color.tertiaryText)

                Spacer()

                // Stats
                HStack(spacing: Theme.Spacing.sm) {
                    miniStat(icon: "checkmark", value: "\(item.totalReviews)")
                    miniStat(icon: "percent", value: "\(Int(item.accuracy * 100))")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.elevatedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(item.isDueForReview ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.heavy) : Color.cardBorder, lineWidth: Theme.Stroke.hairline)
        )
        .padding(.horizontal)
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var masteryBadge: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: item.masteryLevel.icon)
            Text(item.masteryLevel.displayName)
        }
        .font(Typography.Command.meta)
        .foregroundStyle(masteryColor)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(masteryColor.opacity(Theme.Opacity.light))
        )
    }

    private var masteryColor: Color {
        switch item.masteryLevel {
        case .learning: return Color.accentIndigo
        case .reviewing: return Color.accentIndigo
        case .mastered: return .success
        }
    }

    private var dueDateText: String {
        if item.isDueForReview {
            return "Due now"
        } else if item.daysUntilReview == 1 {
            return "Due tomorrow"
        } else {
            return "Due in \(item.daysUntilReview) days"
        }
    }

    private func miniStat(icon: String, value: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(Typography.Command.meta)
            Text(value)
                .font(Typography.Command.meta.monospacedDigit())
        }
        .foregroundStyle(Color.tertiaryText)
    }
}

// MARK: - Preview

#Preview {
    MemorizationQueueView()
}

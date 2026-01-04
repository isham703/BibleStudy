import SwiftUI

// MARK: - Home Tab View
// Personalized gateway to the Bible study experience

struct HomeTabView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showSettings = false
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    // Header: Greeting + Streak
                    headerSection

                    // Discover (Stories & Topics)
                    discoverSection

                    // Today's Practice (Memorization)
                    practiceSection

                    // Today's Reading (Plans)
                    readingSection

                    // For You (AI Insights)
                    insightsSection
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.lg)
            }
            .background(Color.appBackground)
            .refreshable {
                await viewModel.refresh()
            }
            .navigationDestination(isPresented: $viewModel.showMemorizationQueue) {
                MemorizationQueueView()
            }
            .navigationDestination(isPresented: $viewModel.showAllStories) {
                StoryExplorerView()
            }
            .navigationDestination(isPresented: $viewModel.showAllTopics) {
                TopicExplorerView()
            }
            .sheet(isPresented: $viewModel.showPlanDetail) {
                if let plan = viewModel.todaysPlan {
                    PlanDetailSheet(plan: plan, viewModel: PlansViewModel())
                }
            }
            .sheet(isPresented: $viewModel.showPlanPicker) {
                PlanPickerSheet(onSelect: { plan in
                    viewModel.addPlan(plan)
                })
            }
            .navigationDestination(isPresented: $viewModel.showStoryDetail) {
                if let story = viewModel.selectedStory {
                    StoryReaderView(story: story)
                }
            }
            .sheet(item: $viewModel.selectedTopic) { topic in
                TopicDetailView(topic: topic)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            GreetingHeader(userName: viewModel.userName)

            Spacer()

            // Settings button
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(Typography.UI.iconLg.weight(.medium))
                    .foregroundStyle(Color.accentGold)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.accentGold.opacity(AppTheme.Opacity.subtle + 0.02))
                    )
            }
            .accessibilityLabel("Settings")

            StreakBadge_Legacy(
                currentStreak: viewModel.currentStreak,
                graceDayUsed: false
            )
        }
    }

    // MARK: - Practice Section

    @ViewBuilder
    private var practiceSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HomeSectionHeader(title: "Today's Practice")

            if !viewModel.hasPracticeItems {
                // Empty state - no verses yet
                TodaysPracticeEmptyCard(onAddVerse: viewModel.openMemorizationQueue)
            } else if viewModel.dueCount == 0 {
                // All caught up
                TodaysPracticeCaughtUpCard(masteredCount: viewModel.masteredCount)
            } else {
                // Has items due
                TodaysPracticeCard(
                    dueCount: viewModel.dueCount,
                    learningCount: viewModel.learningCount,
                    reviewingCount: viewModel.reviewingCount,
                    estimatedMinutes: viewModel.estimatedPracticeMinutes,
                    onPractice: viewModel.openMemorizationQueue
                )
            }
        }
    }

    // MARK: - Reading Section

    @ViewBuilder
    private var readingSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HomeSectionHeader(title: "Today's Reading")

            if let plan = viewModel.todaysPlan {
                TodaysReadingCard(
                    planTitle: plan.title,
                    currentDay: plan.currentDay,
                    totalDays: plan.totalDays,
                    todayReference: plan.todayReading?.reference ?? "",
                    progressPercentage: plan.progressPercentage,
                    onContinue: viewModel.openPlanDetail
                )
            } else {
                TodaysReadingEmptyCard(onBrowsePlans: { viewModel.showPlanPicker = true })
            }
        }
    }

    // MARK: - Discover Section

    private var discoverSection: some View {
        DiscoverSection(
            stories: viewModel.featuredStories,
            topics: viewModel.featuredTopics,
            onStoryTap: viewModel.openStory,
            onTopicTap: viewModel.openTopic,
            onSeeAllStories: viewModel.openAllStories,
            onSeeAllTopics: viewModel.openAllTopics
        )
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        ForYouSection(
            insight: viewModel.currentInsight,
            onSeeAll: viewModel.openAllInsights,
            onDismiss: viewModel.dismissInsight,
            onExplore: viewModel.exploreInsight
        )
    }
}

// MARK: - Previews

#Preview("Home Tab - Full") {
    HomeTabView()
        .environment(AppState())
}

#Preview("Home Tab - Empty State") {
    HomeTabView()
        .environment(AppState())
}

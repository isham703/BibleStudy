import SwiftUI
import Combine

// MARK: - Home View Model
// Aggregates data from multiple services for the personalized Home screen

@MainActor
@Observable
final class HomeViewModel {
    // MARK: - Dependencies
    private let memorizationService = MemorizationService.shared
    private let progressService = ProgressService.shared
    private let storyService = StoryService.shared
    private let topicService = TopicService.shared

    // MARK: - State
    var isLoading = false
    var error: Error?

    // MARK: - User Data
    var userName: String? {
        UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.userName)
    }

    // MARK: - Streak Data
    var currentStreak: Int {
        progressService.currentStreak
    }

    var longestStreak: Int {
        progressService.longestStreak
    }

    // MARK: - Memorization Data
    var dueItems: [MemorizationItem] {
        memorizationService.dueItems
    }

    var dueCount: Int {
        memorizationService.dueCount
    }

    var masteredCount: Int {
        memorizationService.masteredCount
    }

    var learningCount: Int {
        memorizationService.learningCount
    }

    var reviewingCount: Int {
        memorizationService.reviewingCount
    }

    var estimatedPracticeMinutes: Int {
        // ~2 minutes per due item
        max(1, dueCount * 2)
    }

    var hasPracticeItems: Bool {
        memorizationService.totalItems > 0
    }

    // MARK: - Reading Plans Data
    var activePlans: [PlanWithProgress] = []

    var todaysPlan: PlanWithProgress? {
        activePlans.first { !$0.isCompleted }
    }

    var hasActivePlan: Bool {
        todaysPlan != nil
    }

    // MARK: - Discover Data
    var featuredStories: [Story] {
        Array(storyService.prebuiltStories.prefix(5))
    }

    var featuredTopics: [Topic] {
        let topics = topicService.topics.isEmpty
            ? topicService.getSampleTopics()
            : topicService.topics
        return Array(topics.prefix(4))
    }

    // MARK: - AI Insights
    var currentInsight: PersonalizedInsight?

    // MARK: - Navigation State
    var showMemorizationQueue = false
    var showPlanDetail = false
    var showPlanPicker = false
    var showStoryDetail = false
    var showTopicDetail = false
    var showAllStories = false
    var showAllTopics = false
    var showAllInsights = false

    var selectedStory: Story?
    var selectedTopic: Topic?

    // MARK: - Initialization

    init() {
        // Load user preferences
        loadUserPreferences()
    }

    private func loadUserPreferences() {
        // Load saved plans from PlansViewModel pattern
        // This would connect to persistence in production
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        error = nil

        // Load all services in parallel
        await progressService.loadProgress()
        await memorizationService.loadItems()
        await storyService.loadStories()
        await topicService.loadTopics()

        // Generate personalized insight
        await generateInsight()

        isLoading = false
    }

    func refresh() async {
        await loadData()
    }

    // MARK: - Plans Management
    // Note: Plans are managed by PlansViewModel; this provides read-only access

    func addPlan(_ plan: ReadingPlan) {
        let planWithProgress = PlanWithProgress(plan: plan, progress: [])
        activePlans.append(planWithProgress)
    }

    // MARK: - AI Insight Generation

    private func generateInsight() async {
        // Generate personalized insight based on reading history
        // In production, this would use ReadingAnalyticsService and AI

        guard memorizationService.totalItems > 0 || !storyService.inProgressStories.isEmpty else {
            currentInsight = nil
            return
        }

        // Sample insight based on memorization activity
        if memorizationService.masteredCount > 0 {
            currentInsight = PersonalizedInsight(
                type: .themeFromReading,
                title: "Your Memorization Journey",
                content: "You've mastered \(memorizationService.masteredCount) verse\(memorizationService.masteredCount == 1 ? "" : "s"). The practice of hiding God's word in your heart connects you to a tradition stretching back millennia.",
                relatedVerses: dueItems.prefix(3).map { $0.range }
            )
        } else if !storyService.inProgressStories.isEmpty {
            let story = storyService.inProgressStories.first!
            currentInsight = PersonalizedInsight(
                type: .connectionDiscovered,
                title: "Continue Your Story",
                content: "You're in the middle of \"\(story.title)\". Biblical narratives reveal deeper truths when we immerse ourselves fully in them.",
                relatedVerses: story.verseAnchors
            )
        }
    }

    func dismissInsight() {
        withAnimation(AppTheme.Animation.standard) {
            currentInsight = nil
        }
    }

    // MARK: - Navigation Actions

    func openMemorizationQueue() {
        showMemorizationQueue = true
    }

    func openPlanDetail() {
        guard todaysPlan != nil else { return }
        showPlanDetail = true
    }

    func openStory(_ story: Story) {
        selectedStory = story
        showStoryDetail = true
    }

    func openTopic(_ topic: Topic) {
        selectedTopic = topic
        showTopicDetail = true
    }

    func openAllStories() {
        showAllStories = true
    }

    func openAllTopics() {
        showAllTopics = true
    }

    func openAllInsights() {
        showAllInsights = true
    }

    func exploreInsight() {
        guard let insight = currentInsight else { return }

        // Navigate based on insight type
        switch insight.type {
        case .themeFromReading:
            // Could open a theme exploration view
            break
        case .connectionDiscovered:
            // Could open cross-reference view
            break
        case .reflectionPrompt:
            // Could open journal/notes
            break
        case .topicSuggestion:
            // Could open topic detail
            break
        }
    }
}

// MARK: - UserDefaults Key Extension

extension AppConfiguration.UserDefaultsKeys {
    static let userName = "userName"
}

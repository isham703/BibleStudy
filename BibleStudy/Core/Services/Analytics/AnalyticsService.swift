import Foundation

// MARK: - Analytics Service
// Tracks user events for funnel analysis and conversion optimization
// Provider-agnostic: can log locally or send to Mixpanel/Amplitude

@MainActor
@Observable
final class AnalyticsService {
    // MARK: - Singleton
    static let shared = AnalyticsService()

    // MARK: - Configuration
    private var isEnabled: Bool = true
    private var userId: String?

    // Local event log (for debugging/testing)
    private(set) var recentEvents: [AnalyticsEvent] = []
    private let maxRecentEvents = 100

    // MARK: - Initialization

    private init() {
        // Load user ID if exists
        userId = UserDefaults.standard.string(forKey: "analytics_user_id")

        // Generate anonymous ID if needed
        if userId == nil {
            userId = UUID().uuidString
            UserDefaults.standard.set(userId, forKey: "analytics_user_id")
        }
    }

    // MARK: - User Identification

    func identify(userId: String) {
        self.userId = userId
        UserDefaults.standard.set(userId, forKey: "analytics_user_id")

        // TODO: Send to analytics provider
        // Mixpanel.mainInstance().identify(distinctId: userId)
        // Amplitude.instance().setUserId(userId)
    }

    func setUserProperty(_ key: String, value: Any) {
        // TODO: Send to analytics provider
        // Mixpanel.mainInstance().people.set(property: key, to: value)

        logEvent(.userPropertySet, properties: [key: "\(value)"])
    }

    // MARK: - Event Tracking

    func track(_ event: AnalyticsEventType, properties: [String: Any]? = nil) {
        guard isEnabled else { return }

        let analyticsEvent = AnalyticsEvent(
            type: event,
            properties: properties,
            timestamp: Date(),
            userId: userId
        )

        // Store locally
        recentEvents.append(analyticsEvent)
        if recentEvents.count > maxRecentEvents {
            recentEvents.removeFirst()
        }

        // Log for debugging
        #if DEBUG
        print("📊 Analytics: \(event.rawValue) \(properties ?? [:])")
        #endif

        // TODO: Send to analytics provider
        // Mixpanel.mainInstance().track(event: event.rawValue, properties: properties as? [String: MixpanelType])
        // Amplitude.instance().logEvent(event.rawValue, withEventProperties: properties)
    }

    // MARK: - Convenience Methods

    private func logEvent(_ event: AnalyticsEventType, properties: [String: Any]? = nil) {
        track(event, properties: properties)
    }

    // MARK: - Enable/Disable

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
}

// MARK: - Analytics Event Types

enum AnalyticsEventType: String {
    // MARK: - Onboarding Funnel
    case onboardingStarted = "onboarding_started"
    case onboardingValuePropsViewed = "onboarding_value_props_viewed"
    case onboardingQuizStarted = "onboarding_quiz_started"
    case onboardingQuizQuestion1 = "onboarding_quiz_q1_answered"
    case onboardingQuizQuestion2 = "onboarding_quiz_q2_answered"
    case onboardingQuizQuestion3 = "onboarding_quiz_q3_answered"
    case onboardingQuizCompleted = "onboarding_quiz_completed"
    case onboardingPersonalizationViewed = "onboarding_personalization_viewed"
    case onboardingCompleted = "onboarding_completed"
    case onboardingSkipped = "onboarding_skipped"

    // MARK: - First Experience
    case firstChapterViewed = "first_chapter_viewed"
    case firstVerseTapped = "first_verse_tapped"
    case firstInsightViewed = "first_insight_viewed"
    case insightHintShown = "insight_hint_shown"
    case insightHintDismissed = "insight_hint_dismissed"

    // MARK: - Paywall Funnel
    case paywallShown = "paywall_shown"
    case paywallDismissed = "paywall_dismissed"
    case trialStarted = "trial_started"
    case subscriptionPurchased = "subscription_purchased"
    case subscriptionRestored = "subscription_restored"
    case subscriptionCanceled = "subscription_canceled"

    // MARK: - Engagement
    case sessionStarted = "session_started"
    case sessionEnded = "session_ended"
    case chapterRead = "chapter_read"
    case verseSelected = "verse_selected"
    case insightViewed = "insight_viewed"
    case noteCreated = "note_created"
    case highlightCreated = "highlight_created"
    case verseMemorized = "verse_memorized"
    case memorizationReviewCompleted = "memorization_review_completed"

    // MARK: - Retention
    case dailyGoalCompleted = "daily_goal_completed"
    case streakContinued = "streak_continued"
    case streakBroken = "streak_broken"
    case graceDayUsed = "grace_day_used"
    case achievementUnlocked = "achievement_unlocked"
    case levelUp = "level_up"

    // MARK: - Features
    case searchPerformed = "search_performed"
    case crossReferenceViewed = "cross_reference_viewed"
    case wordStudyViewed = "word_study_viewed"
    case translationSwitched = "translation_switched"
    case themeChanged = "theme_changed"
    case fontSizeChanged = "font_size_changed"

    // MARK: - Notifications
    case notificationPermissionRequested = "notification_permission_requested"
    case notificationPermissionGranted = "notification_permission_granted"
    case notificationPermissionDenied = "notification_permission_denied"
    case notificationTapped = "notification_tapped"

    // MARK: - Widget
    case widgetInstalled = "widget_installed"
    case widgetTapped = "widget_tapped"

    // MARK: - Internal
    case userPropertySet = "user_property_set"
    case appLaunched = "app_launched"
    case appBackgrounded = "app_backgrounded"
}

// MARK: - Analytics Event Model

struct AnalyticsEvent: Identifiable {
    let id = UUID()
    let type: AnalyticsEventType
    let properties: [String: Any]?
    let timestamp: Date
    let userId: String?

    var displayProperties: String {
        guard let props = properties else { return "" }
        return props.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
    }
}

// MARK: - Convenience Extensions

extension AnalyticsService {
    // MARK: - Onboarding Tracking

    func trackOnboardingStarted() {
        track(.onboardingStarted)
    }

    func trackOnboardingQuizAnswer(question: Int, answer: String) {
        let event: AnalyticsEventType
        switch question {
        case 1: event = .onboardingQuizQuestion1
        case 2: event = .onboardingQuizQuestion2
        case 3: event = .onboardingQuizQuestion3
        default: return
        }
        track(event, properties: ["answer": answer])
    }

    func trackOnboardingCompleted(mode: String, dailyGoal: Int) {
        track(.onboardingCompleted, properties: [
            "mode": mode,
            "daily_goal_minutes": dailyGoal
        ])
        setUserProperty("app_mode", value: mode)
        setUserProperty("daily_goal_minutes", value: dailyGoal)
    }

    func trackOnboardingSkipped() {
        track(.onboardingSkipped)
    }

    // MARK: - Paywall Tracking

    func trackPaywallShown(trigger: String) {
        track(.paywallShown, properties: ["trigger": trigger])
    }

    func trackPaywallDismissed(trigger: String) {
        track(.paywallDismissed, properties: ["trigger": trigger])
    }

    func trackTrialStarted(productId: String) {
        track(.trialStarted, properties: ["product_id": productId])
    }

    func trackSubscriptionPurchased(productId: String, price: Decimal) {
        track(.subscriptionPurchased, properties: [
            "product_id": productId,
            "price": "\(price)"
        ])
        setUserProperty("subscription_tier", value: productId)
    }

    // MARK: - Session Tracking

    func trackSessionStart() {
        track(.sessionStarted)
    }

    func trackSessionEnd() {
        track(.sessionEnded)
    }

    // MARK: - Engagement Tracking

    func trackChapterRead(book: String, chapter: Int) {
        track(.chapterRead, properties: [
            "book": book,
            "chapter": chapter
        ])
    }

    func trackInsightViewed(reference: String, type: String) {
        track(.insightViewed, properties: [
            "reference": reference,
            "insight_type": type
        ])
    }

    func trackNoteCreated(reference: String, template: String) {
        track(.noteCreated, properties: [
            "reference": reference,
            "template": template
        ])
    }

    func trackHighlightCreated(reference: String, color: String) {
        track(.highlightCreated, properties: [
            "reference": reference,
            "color": color
        ])
    }

    func trackVerseMemorized(reference: String, mastered: Bool) {
        track(.verseMemorized, properties: [
            "reference": reference,
            "mastered": mastered
        ])
    }

    // MARK: - Retention Tracking

    func trackStreakUpdate(result: String, streak: Int) {
        let event: AnalyticsEventType
        switch result {
        case "continued": event = .streakContinued
        case "broken": event = .streakBroken
        case "grace_day": event = .graceDayUsed
        default: return
        }
        track(event, properties: ["streak_days": streak])
    }

    func trackAchievementUnlocked(achievementId: String, xp: Int) {
        track(.achievementUnlocked, properties: [
            "achievement_id": achievementId,
            "xp_reward": xp
        ])
    }

    func trackLevelUp(newLevel: String, totalXP: Int) {
        track(.levelUp, properties: [
            "new_level": newLevel,
            "total_xp": totalXP
        ])
        setUserProperty("user_level", value: newLevel)
    }
}

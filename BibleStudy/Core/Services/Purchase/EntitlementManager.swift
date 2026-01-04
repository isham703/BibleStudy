import Foundation
import SwiftUI

// MARK: - Entitlement Manager
// Tracks feature usage and gates premium features

@MainActor
@Observable
final class EntitlementManager {
    // MARK: - Singleton
    static let shared = EntitlementManager()

    // MARK: - Dependencies
    private let storeManager = StoreManager.shared

    // MARK: - Usage Tracking (resets daily)
    private(set) var aiInsightsUsedToday: Int = 0
    private(set) var highlightsUsedToday: Int = 0
    private(set) var notesUsedToday: Int = 0
    private(set) var lastResetDate: Date?

    // MARK: - Paywall State
    var shouldShowPaywall: Bool = false
    var paywallTrigger: PaywallTrigger = .manual
    /// Prevents repeated paywall appearances after user dismisses once per session
    private var paywallDismissedForAIInsights: Bool = false

    // MARK: - UserDefaults Keys
    private enum Keys {
        static let aiInsightsUsedToday = "aiInsightsUsedToday"
        static let highlightsUsedToday = "highlightsUsedToday"
        static let notesUsedToday = "notesUsedToday"
        static let lastResetDate = "lastResetDate"
    }

    // MARK: - Initialization

    private init() {
        loadUsage()
        resetIfNewDay()
    }

    // MARK: - Persistence

    private func loadUsage() {
        aiInsightsUsedToday = UserDefaults.standard.integer(forKey: Keys.aiInsightsUsedToday)
        highlightsUsedToday = UserDefaults.standard.integer(forKey: Keys.highlightsUsedToday)
        notesUsedToday = UserDefaults.standard.integer(forKey: Keys.notesUsedToday)
        lastResetDate = UserDefaults.standard.object(forKey: Keys.lastResetDate) as? Date
    }

    private func saveUsage() {
        UserDefaults.standard.set(aiInsightsUsedToday, forKey: Keys.aiInsightsUsedToday)
        UserDefaults.standard.set(highlightsUsedToday, forKey: Keys.highlightsUsedToday)
        UserDefaults.standard.set(notesUsedToday, forKey: Keys.notesUsedToday)
        UserDefaults.standard.set(lastResetDate, forKey: Keys.lastResetDate)
    }

    // MARK: - Daily Reset

    func resetIfNewDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastReset = lastResetDate {
            let lastResetDay = calendar.startOfDay(for: lastReset)
            if today > lastResetDay {
                resetDailyUsage()
            }
        } else {
            lastResetDate = today
            saveUsage()
        }
    }

    private func resetDailyUsage() {
        aiInsightsUsedToday = 0
        highlightsUsedToday = 0
        notesUsedToday = 0
        lastResetDate = Calendar.current.startOfDay(for: Date())
        saveUsage()
    }

    // MARK: - Feature Access Checks

    /// Check if user can access a feature, optionally triggering paywall
    func canAccess(_ feature: PremiumFeature, triggerPaywall: Bool = true) -> Bool {
        // Premium users have full access
        if storeManager.isPremiumOrHigher {
            return true
        }

        // Check feature-specific limits
        let hasAccess: Bool
        let trigger: PaywallTrigger
        var alreadyDismissed: Bool = false

        switch feature {
        case .aiInsights:
            hasAccess = aiInsightsUsedToday < FreeTierLimits.dailyAIInsights
            trigger = .aiInsightsLimit
            alreadyDismissed = paywallDismissedForAIInsights

        case .memorization:
            // Check memorization verse count from MemorizationService
            hasAccess = true  // Will be checked by MemorizationService
            trigger = .memorizationLimit

        case .allTranslations:
            hasAccess = false  // Always requires premium
            trigger = .translationLimit

        case .unlimitedHighlights:
            // Highlights are now free for all users
            hasAccess = true
            trigger = .highlightLimit

        case .unlimitedNotes:
            hasAccess = notesUsedToday < FreeTierLimits.maxNotesPerDay
            trigger = .noteLimit

        case .hebrewGreek:
            hasAccess = storeManager.isScholar
            trigger = .manual

        case .audioBible:
            hasAccess = storeManager.isScholar
            trigger = .manual

        case .visualCards:
            hasAccess = storeManager.isScholar
            trigger = .manual
        }

        // Trigger paywall if needed (but respect dismissed flag)
        if !hasAccess && triggerPaywall && !alreadyDismissed {
            paywallTrigger = trigger
            shouldShowPaywall = true
        }

        return hasAccess
    }

    // MARK: - Usage Recording

    /// Record AI insight usage, returns true if allowed
    /// Only triggers paywall when actually denied (not on last allowed use)
    @discardableResult
    func recordAIInsightUsage() -> Bool {
        resetIfNewDay()

        if storeManager.isPremiumOrHigher {
            return true
        }

        if aiInsightsUsedToday < FreeTierLimits.dailyAIInsights {
            aiInsightsUsedToday += 1
            saveUsage()
            // Allow the usage - don't show paywall on successful use
            return true
        }

        // User over limit - only show paywall if not already dismissed this session
        if !paywallDismissedForAIInsights {
            paywallTrigger = .aiInsightsLimit
            shouldShowPaywall = true
        }
        return false
    }

    /// Check if user can use AI insights without side effects
    var canUseAIInsights: Bool {
        if storeManager.isPremiumOrHigher { return true }
        return aiInsightsUsedToday < FreeTierLimits.dailyAIInsights
    }

    /// Called when paywall is dismissed to prevent repeated appearances
    func dismissPaywallForAIInsights() {
        paywallDismissedForAIInsights = true
        shouldShowPaywall = false
    }

    /// Record highlight usage, returns true if allowed
    /// Highlights are now unlimited for all users (no longer gated)
    @discardableResult
    func recordHighlightUsage() -> Bool {
        resetIfNewDay()

        // Highlights are free for everyone - always return true
        // Still track usage for analytics purposes
        highlightsUsedToday += 1
        saveUsage()
        return true
    }

    /// Record note usage, returns true if allowed
    @discardableResult
    func recordNoteUsage() -> Bool {
        resetIfNewDay()

        if storeManager.isPremiumOrHigher {
            return true
        }

        if notesUsedToday < FreeTierLimits.maxNotesPerDay {
            notesUsedToday += 1
            saveUsage()
            return true
        }

        paywallTrigger = .noteLimit
        shouldShowPaywall = true
        return false
    }

    // MARK: - Remaining Usage

    var remainingAIInsights: Int {
        if storeManager.isPremiumOrHigher { return Int.max }
        return max(0, FreeTierLimits.dailyAIInsights - aiInsightsUsedToday)
    }

    var remainingHighlights: Int {
        // Highlights are unlimited for all users
        return Int.max
    }

    var remainingNotes: Int {
        if storeManager.isPremiumOrHigher { return Int.max }
        return max(0, FreeTierLimits.maxNotesPerDay - notesUsedToday)
    }

    // MARK: - Translation Check

    func isTranslationAvailable(_ translationCode: String) -> Bool {
        if storeManager.isPremiumOrHigher {
            return true
        }
        return FreeTierLimits.freeTranslations.contains(translationCode)
    }

    // MARK: - Paywall Helpers

    func dismissPaywall() {
        shouldShowPaywall = false
    }

    func showPaywall(trigger: PaywallTrigger = .manual) {
        paywallTrigger = trigger
        shouldShowPaywall = true
    }
}

// MARK: - Premium Features

enum PremiumFeature {
    case aiInsights
    case memorization
    case allTranslations
    case unlimitedHighlights
    case unlimitedNotes
    case hebrewGreek
    case audioBible
    case visualCards
}

// MARK: - Entitlement Error

enum EntitlementError: LocalizedError {
    case limitReached(PremiumFeature)

    var errorDescription: String? {
        switch self {
        case .limitReached(let feature):
            switch feature {
            case .aiInsights:
                return "You've reached your daily AI insight limit. Upgrade to Premium for unlimited access."
            case .unlimitedHighlights:
                return "You've reached your daily highlight limit. Upgrade to Premium for unlimited highlights."
            case .unlimitedNotes:
                return "You've reached your daily note limit. Upgrade to Premium for unlimited notes."
            case .memorization:
                return "You've reached your memorization verse limit. Upgrade to Premium for unlimited memorization."
            case .allTranslations:
                return "This translation requires Premium. Upgrade to access all Bible translations."
            default:
                return "This feature requires Premium. Upgrade to unlock all features."
            }
        }
    }
}

// MARK: - View Modifier for Paywall

struct PaywallModifier: ViewModifier {
    @State private var entitlementManager = EntitlementManager.shared

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $entitlementManager.shouldShowPaywall, onDismiss: {
                // Mark as dismissed to prevent repeated appearances this session
                if entitlementManager.paywallTrigger == .aiInsightsLimit {
                    entitlementManager.dismissPaywallForAIInsights()
                }
            }) {
                PaywallView(trigger: entitlementManager.paywallTrigger)
            }
    }
}

extension View {
    func withPaywall() -> some View {
        modifier(PaywallModifier())
    }
}

// MARK: - Premium Feature Lock View

struct PremiumFeatureLock: View {
    let feature: String
    let icon: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "lock.fill")
                .font(Typography.UI.title2)
                .foregroundStyle(Color.tertiaryText)

            Text("\(feature) requires Premium")
                .font(Typography.UI.subheadline)
                .foregroundStyle(Color.secondaryText)

            Button("Upgrade") {
                EntitlementManager.shared.showPaywall()
            }
            .font(Typography.UI.buttonLabel)
            .foregroundStyle(.white)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(Color.scholarAccent)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.xl)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
    }
}

// MARK: - Usage Badge

struct UsageBadge: View {
    let remaining: Int
    let total: Int

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            Image(systemName: "sparkle")
                .font(Typography.UI.caption2)

            Text("\(remaining)/\(total)")
                .font(Typography.UI.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(remaining > 0 ? Color.scholarAccent : Color.error)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xxs)
        .background(
            Capsule()
                .fill(remaining > 0 ? Color.scholarAccent.opacity(AppTheme.Opacity.subtle) : Color.error.opacity(AppTheme.Opacity.subtle))
        )
    }
}

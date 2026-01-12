import Foundation
import GRDB
import Auth
import WidgetKit

// MARK: - Progress Service
// Manages user progress including streaks, XP, levels, and achievements

@MainActor
@Observable
final class ProgressService {
    // MARK: - Singleton
    // nonisolated(unsafe) allows use as default parameter in @MainActor inits
    nonisolated(unsafe) static let shared = ProgressService()

    // MARK: - Properties
    private let supabase = SupabaseManager.shared
    private let db = DatabaseManager.shared

    var progress: UserProgress?
    var isLoading: Bool = false
    var error: Error?

    // Convenience computed properties
    var currentStreak: Int { progress?.currentStreak ?? 0 }
    var longestStreak: Int { progress?.longestStreak ?? 0 }
    var totalXP: Int { progress?.totalXP ?? 0 }
    var level: UserLevel { progress?.level ?? .novice }
    var graceDaysRemaining: Int { progress?.graceDaysRemaining ?? 1 }

    // MARK: - Initialization
    // Note: nonisolated to allow initialization from nonisolated(unsafe) static let shared
    private nonisolated init() {}

    // MARK: - Load Progress

    func loadProgress() async {
        guard let userId = supabase.currentUser?.id else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Try to load from local cache first
            if let cached = try await loadFromCache(userId: userId) {
                progress = cached

                // Reset daily counters if needed
                progress?.resetDailyCountersIfNeeded()

                // Refresh Grace Days if needed (check monthly)
                let isPremium = await checkPremiumStatus()
                progress?.refreshGraceDaysIfNeeded(isPremium: isPremium)

                // Save any updates
                try await saveToCache()
            } else {
                // Create new progress for user
                progress = UserProgress(userId: userId)
                try await saveToCache()
            }
        } catch {
            self.error = error
        }
    }

    // MARK: - Cache Operations

    private func loadFromCache(userId: UUID) async throws -> UserProgress? {
        guard let dbQueue = db.dbQueue else { return nil }

        return try await Task.detached {
            try dbQueue.read { db in
                try UserProgress
                    .filter(UserProgress.Columns.userId == userId.uuidString)
                    .fetchOne(db)
            }
        }.value
    }

    private func saveToCache() async throws {
        guard let progress = progress,
              let dbQueue = db.dbQueue else { return }

        let progressToSave = progress
        try await Task.detached {
            try dbQueue.write { db in
                try progressToSave.save(db)
            }
        }.value
    }

    // MARK: - Streak Operations

    /// Records daily activity and updates streak
    /// Call this when user completes any qualifying activity
    @discardableResult
    func recordActivity() async throws -> UserProgress.StreakUpdateResult {
        guard progress != nil else {
            throw ProgressError.notLoaded
        }

        let result = progress!.updateStreak()

        // Check for streak milestones and award bonus XP
        if result.shouldCelebrate {
            let bonuses = progress!.checkStreakMilestones()
            for bonus in bonuses {
                print("Streak milestone bonus: +\(bonus.rawValue) XP")
            }
        }

        try await saveToCache()

        // Sync streak to widget
        WidgetService.shared.updateStreak(progress!.currentStreak)

        return result
    }

    /// Gets the streak feedback message for display
    func getStreakFeedback() -> String {
        guard let lastResult = lastStreakResult else {
            return "Welcome! Start your journey today."
        }
        return lastResult.feedbackMessage
    }

    // Track last result for feedback
    private var lastStreakResult: UserProgress.StreakUpdateResult?

    // MARK: - XP Operations

    /// Awards XP for an action
    @discardableResult
    func awardXP(_ award: XPAward) async throws -> Bool {
        guard progress != nil else {
            throw ProgressError.notLoaded
        }

        let previousLevel = progress!.level
        let leveledUp = progress!.awardXP(award)
        try await saveToCache()

        if leveledUp {
            // Post notification for level up celebration
            NotificationCenter.default.post(
                name: .userLeveledUp,
                object: nil,
                userInfo: [
                    "level": progress!.level,
                    "previousLevel": previousLevel
                ]
            )
        }

        return leveledUp
    }

    /// Awards custom XP amount
    @discardableResult
    func awardXP(amount: Int) async throws -> Bool {
        guard progress != nil else {
            throw ProgressError.notLoaded
        }

        let previousLevel = progress!.level
        let leveledUp = progress!.awardXP(amount: amount)
        try await saveToCache()

        if leveledUp {
            // Post notification for level up celebration
            NotificationCenter.default.post(
                name: .userLeveledUp,
                object: nil,
                userInfo: [
                    "level": progress!.level,
                    "previousLevel": previousLevel
                ]
            )
        }

        return leveledUp
    }

    // MARK: - Daily Tracking

    /// Records reading time
    func recordReadingTime(minutes: Int) async throws {
        guard progress != nil else {
            throw ProgressError.notLoaded
        }

        progress!.dailyReadingMinutes += minutes

        // Check if daily goal was just completed
        let wasCompleted = progress!.dailyReadingMinutes - minutes < progress!.dailyGoalMinutes
        let isNowCompleted = progress!.dailyReadingMinutes >= progress!.dailyGoalMinutes

        if wasCompleted == false && isNowCompleted {
            // Just completed daily goal - award bonus XP
            _ = try await awardXP(.completeDailyGoal)
            NotificationCenter.default.post(name: .dailyGoalCompleted, object: nil)
        }

        try await saveToCache()

        // Sync reading progress to widget
        WidgetService.shared.updateReadingProgress(progress!.dailyGoalProgress)
    }

    /// Records chapter read
    func recordChapterRead() async throws {
        guard progress != nil else {
            throw ProgressError.notLoaded
        }

        progress!.chaptersReadToday += 1
        _ = try await awardXP(.readChapter)
        try await saveToCache()
    }

    /// Records verse reviewed (memorization)
    func recordVerseReviewed(mastered: Bool) async throws {
        guard progress != nil else {
            throw ProgressError.notLoaded
        }

        progress!.versesReviewedToday += 1
        _ = try await awardXP(.completeMemorizationReview)

        if mastered {
            _ = try await awardXP(.masterVerse)
        }

        try await saveToCache()
    }

    /// Updates daily goal setting
    func setDailyGoal(minutes: Int) async throws {
        guard progress != nil else {
            throw ProgressError.notLoaded
        }

        progress!.dailyGoalMinutes = max(5, min(60, minutes))
        try await saveToCache()
    }

    // MARK: - Achievement Operations

    /// Unlocks an achievement
    @discardableResult
    func unlockAchievement(_ achievementId: String) async throws -> Bool {
        guard progress != nil else {
            throw ProgressError.notLoaded
        }

        let wasUnlocked = progress!.unlockAchievement(achievementId)

        if wasUnlocked {
            try await saveToCache()
            NotificationCenter.default.post(
                name: .achievementUnlocked,
                object: nil,
                userInfo: ["achievementId": achievementId]
            )
        }

        return wasUnlocked
    }

    /// Checks if user has an achievement
    func hasAchievement(_ achievementId: String) -> Bool {
        progress?.hasAchievement(achievementId) ?? false
    }

    // MARK: - Premium Status

    private func checkPremiumStatus() async -> Bool {
        // TODO: Integrate with StoreKit 2 for premium status check
        // For now, return false (free tier)
        return false
    }

    // MARK: - Reset (for testing)

    #if DEBUG
    func resetProgress() async throws {
        guard let userId = supabase.currentUser?.id else { return }

        progress = UserProgress(userId: userId)
        try await saveToCache()
    }
    #endif
}

// MARK: - Progress Errors

enum ProgressError: Error, LocalizedError {
    case notLoaded
    case notAuthenticated
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .notLoaded:
            return "Progress data has not been loaded"
        case .notAuthenticated:
            return "You must be signed in to track progress"
        case .saveFailed(let message):
            return "Failed to save progress: \(message)"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userLeveledUp = Notification.Name("userLeveledUp")
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
    static let dailyGoalCompleted = Notification.Name("dailyGoalCompleted")
    static let streakUpdated = Notification.Name("streakUpdated")
}

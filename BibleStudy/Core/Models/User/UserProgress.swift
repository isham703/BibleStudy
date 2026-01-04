import Foundation
import GRDB

// MARK: - User Level
// XP-based progression system for gamification

enum UserLevel: String, Codable, CaseIterable, Sendable {
    case novice      // 0-99 XP
    case apprentice  // 100-499 XP
    case scholar     // 500-1999 XP
    case master      // 2000-4999 XP
    case sage        // 5000+ XP

    var displayName: String {
        switch self {
        case .novice: return "Novice"
        case .apprentice: return "Apprentice"
        case .scholar: return "Scholar"
        case .master: return "Master"
        case .sage: return "Sage"
        }
    }

    var icon: String {
        switch self {
        case .novice: return "leaf"
        case .apprentice: return "book"
        case .scholar: return "graduationcap"
        case .master: return "crown"
        case .sage: return "sparkles"
        }
    }

    var minXP: Int {
        switch self {
        case .novice: return 0
        case .apprentice: return 100
        case .scholar: return 500
        case .master: return 2000
        case .sage: return 5000
        }
    }

    var maxXP: Int {
        switch self {
        case .novice: return 99
        case .apprentice: return 499
        case .scholar: return 1999
        case .master: return 4999
        case .sage: return Int.max
        }
    }

    static func level(for xp: Int) -> UserLevel {
        switch xp {
        case 0..<100: return .novice
        case 100..<500: return .apprentice
        case 500..<2000: return .scholar
        case 2000..<5000: return .master
        default: return .sage
        }
    }

    var nextLevel: UserLevel? {
        switch self {
        case .novice: return .apprentice
        case .apprentice: return .scholar
        case .scholar: return .master
        case .master: return .sage
        case .sage: return nil
        }
    }
}

// MARK: - XP Award Types
// Points awarded for different actions

enum XPAward: Int {
    case readChapter = 10
    case completeMemorizationReview = 25
    case masterVerse = 75
    case createNote = 15
    case dailyStreakMaintained = 20
    case completeDailyGoal = 30
    case firstInsight = 5
    case completeReadingPlan = 100
    case weekStreak = 50           // Bonus for 7-day streak
    case monthStreak = 200         // Bonus for 30-day streak
}

// MARK: - User Progress
// Tracks streaks, XP, levels, and achievements with Grace Day support

struct UserProgress: Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID

    // Streak tracking
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date?

    // Grace Day system (spiritual framing for streak recovery)
    var graceDaysRemaining: Int      // 1 per month for free, 3 for premium
    var graceDayUsedThisStreak: Bool
    var lastGraceDayRefresh: Date?   // Track monthly refresh

    // XP and leveling
    var totalXP: Int
    var level: UserLevel

    // Achievements
    var achievementsUnlocked: [String]

    // Daily activity tracking
    var dailyReadingMinutes: Int
    var dailyGoalMinutes: Int
    var chaptersReadToday: Int
    var versesReviewedToday: Int

    // Timestamps
    var createdAt: Date
    var updatedAt: Date

    // Computed properties
    var xpToNextLevel: Int {
        guard let next = level.nextLevel else { return 0 }
        return next.minXP - totalXP
    }

    var levelProgress: Double {
        guard let next = level.nextLevel else { return 1.0 }
        let levelRange = next.minXP - level.minXP
        let progress = totalXP - level.minXP
        return Double(progress) / Double(levelRange)
    }

    var dailyGoalProgress: Double {
        guard dailyGoalMinutes > 0 else { return 0 }
        return min(1.0, Double(dailyReadingMinutes) / Double(dailyGoalMinutes))
    }

    var hasCompletedDailyGoal: Bool {
        dailyReadingMinutes >= dailyGoalMinutes
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastActiveDate: Date? = nil,
        graceDaysRemaining: Int = 1,
        graceDayUsedThisStreak: Bool = false,
        lastGraceDayRefresh: Date? = nil,
        totalXP: Int = 0,
        level: UserLevel = .novice,
        achievementsUnlocked: [String] = [],
        dailyReadingMinutes: Int = 0,
        dailyGoalMinutes: Int = 10,
        chaptersReadToday: Int = 0,
        versesReviewedToday: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActiveDate = lastActiveDate
        self.graceDaysRemaining = graceDaysRemaining
        self.graceDayUsedThisStreak = graceDayUsedThisStreak
        self.lastGraceDayRefresh = lastGraceDayRefresh
        self.totalXP = totalXP
        self.level = level
        self.achievementsUnlocked = achievementsUnlocked
        self.dailyReadingMinutes = dailyReadingMinutes
        self.dailyGoalMinutes = dailyGoalMinutes
        self.chaptersReadToday = chaptersReadToday
        self.versesReviewedToday = versesReviewedToday
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Streak Logic with Grace Day

extension UserProgress {
    /// Result of updating streak
    enum StreakUpdateResult: Equatable {
        case continued           // Consecutive day, streak incremented
        case sameDay             // Already active today
        case graceDayUsed        // Missed a day but Grace Day saved streak
        case streakBroken(Int)   // Streak broken, previous streak value
        case firstActivity       // First ever activity
    }

    /// Updates streak based on current activity
    /// Uses UTC for consistent cross-timezone behavior
    mutating func updateStreak() -> StreakUpdateResult {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let lastActive = lastActiveDate else {
            // First activity ever
            currentStreak = 1
            lastActiveDate = today
            graceDayUsedThisStreak = false
            updatedAt = Date()
            return .firstActivity
        }

        let lastActiveDay = calendar.startOfDay(for: lastActive)
        let daysSinceLastActive = calendar.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0

        switch daysSinceLastActive {
        case 0:
            // Same day, no change to streak
            return .sameDay

        case 1:
            // Consecutive day, increment streak
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
            lastActiveDate = today
            updatedAt = Date()
            return .continued

        case 2:
            // Missed one day - offer Grace Day
            if graceDaysRemaining > 0 && !graceDayUsedThisStreak {
                // Auto-apply Grace Day, preserve streak
                graceDaysRemaining -= 1
                graceDayUsedThisStreak = true
                currentStreak += 1  // Count today
                longestStreak = max(longestStreak, currentStreak)
                lastActiveDate = today
                updatedAt = Date()
                return .graceDayUsed
            } else {
                // No grace available, streak broken
                return resetStreak(previousStreak: currentStreak)
            }

        default:
            // More than 2 days missed - streak broken
            return resetStreak(previousStreak: currentStreak)
        }
    }

    /// Resets streak with encouragement messaging
    private mutating func resetStreak(previousStreak: Int) -> StreakUpdateResult {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let oldStreak = currentStreak
        currentStreak = 1
        lastActiveDate = today
        graceDayUsedThisStreak = false
        updatedAt = Date()
        return .streakBroken(oldStreak)
    }

    /// Checks and refreshes Grace Days monthly
    mutating func refreshGraceDaysIfNeeded(isPremium: Bool) {
        let calendar = Calendar.current
        let now = Date()

        if let lastRefresh = lastGraceDayRefresh {
            let monthsSinceRefresh = calendar.dateComponents([.month], from: lastRefresh, to: now).month ?? 0
            if monthsSinceRefresh >= 1 {
                graceDaysRemaining = isPremium ? 3 : 1
                lastGraceDayRefresh = now
                updatedAt = now
            }
        } else {
            // First time setup
            graceDaysRemaining = isPremium ? 3 : 1
            lastGraceDayRefresh = now
            updatedAt = now
        }
    }

    /// Resets daily counters (call at midnight or app launch on new day)
    mutating func resetDailyCountersIfNeeded() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastActive = lastActiveDate {
            let lastActiveDay = calendar.startOfDay(for: lastActive)
            if today > lastActiveDay {
                dailyReadingMinutes = 0
                chaptersReadToday = 0
                versesReviewedToday = 0
            }
        }
    }
}

// MARK: - XP Operations

extension UserProgress {
    /// Awards XP and updates level if needed
    mutating func awardXP(_ award: XPAward) -> Bool {
        return awardXP(amount: award.rawValue)
    }

    /// Awards custom XP amount and returns true if level up occurred
    mutating func awardXP(amount: Int) -> Bool {
        let previousLevel = level
        totalXP += amount
        level = UserLevel.level(for: totalXP)
        updatedAt = Date()
        return level != previousLevel
    }

    /// Checks and awards streak milestone bonuses
    mutating func checkStreakMilestones() -> [XPAward] {
        var bonuses: [XPAward] = []

        if currentStreak == 7 {
            _ = awardXP(.weekStreak)
            bonuses.append(.weekStreak)
        }

        if currentStreak == 30 {
            _ = awardXP(.monthStreak)
            bonuses.append(.monthStreak)
        }

        // Additional milestones: 100, 365 days could be added

        return bonuses
    }
}

// MARK: - Achievement Operations

extension UserProgress {
    mutating func unlockAchievement(_ achievementId: String) -> Bool {
        guard !achievementsUnlocked.contains(achievementId) else {
            return false
        }
        achievementsUnlocked.append(achievementId)
        updatedAt = Date()
        return true
    }

    func hasAchievement(_ achievementId: String) -> Bool {
        achievementsUnlocked.contains(achievementId)
    }
}

// MARK: - GRDB Support

extension UserProgress: FetchableRecord, PersistableRecord {
    nonisolated static var databaseTableName: String { "user_progress" }

    enum Columns: String, ColumnExpression {
        case id
        case userId = "user_id"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastActiveDate = "last_active_date"
        case graceDaysRemaining = "grace_days_remaining"
        case graceDayUsedThisStreak = "grace_day_used_this_streak"
        case lastGraceDayRefresh = "last_grace_day_refresh"
        case totalXP = "total_xp"
        case level
        case achievementsUnlocked = "achievements_unlocked"
        case dailyReadingMinutes = "daily_reading_minutes"
        case dailyGoalMinutes = "daily_goal_minutes"
        case chaptersReadToday = "chapters_read_today"
        case versesReviewedToday = "verses_reviewed_today"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    nonisolated init(row: Row) throws {
        id = row[Columns.id]
        userId = row[Columns.userId]
        currentStreak = row[Columns.currentStreak]
        longestStreak = row[Columns.longestStreak]
        lastActiveDate = row[Columns.lastActiveDate]
        graceDaysRemaining = row[Columns.graceDaysRemaining]
        graceDayUsedThisStreak = row[Columns.graceDayUsedThisStreak]
        lastGraceDayRefresh = row[Columns.lastGraceDayRefresh]
        totalXP = row[Columns.totalXP]
        level = UserLevel(rawValue: row[Columns.level]) ?? .novice

        // Decode achievements from JSON string
        if let achievementsData = (row[Columns.achievementsUnlocked] as String?)?.data(using: .utf8) {
            achievementsUnlocked = (try? JSONDecoder().decode([String].self, from: achievementsData)) ?? []
        } else {
            achievementsUnlocked = []
        }

        dailyReadingMinutes = row[Columns.dailyReadingMinutes]
        dailyGoalMinutes = row[Columns.dailyGoalMinutes]
        chaptersReadToday = row[Columns.chaptersReadToday]
        versesReviewedToday = row[Columns.versesReviewedToday]
        createdAt = row[Columns.createdAt]
        updatedAt = row[Columns.updatedAt]
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.userId] = userId
        container[Columns.currentStreak] = currentStreak
        container[Columns.longestStreak] = longestStreak
        container[Columns.lastActiveDate] = lastActiveDate
        container[Columns.graceDaysRemaining] = graceDaysRemaining
        container[Columns.graceDayUsedThisStreak] = graceDayUsedThisStreak
        container[Columns.lastGraceDayRefresh] = lastGraceDayRefresh
        container[Columns.totalXP] = totalXP
        container[Columns.level] = level.rawValue

        // Encode achievements as JSON string
        if let achievementsData = try? JSONEncoder().encode(achievementsUnlocked),
           let achievementsString = String(data: achievementsData, encoding: .utf8) {
            container[Columns.achievementsUnlocked] = achievementsString
        } else {
            container[Columns.achievementsUnlocked] = "[]"
        }

        container[Columns.dailyReadingMinutes] = dailyReadingMinutes
        container[Columns.dailyGoalMinutes] = dailyGoalMinutes
        container[Columns.chaptersReadToday] = chaptersReadToday
        container[Columns.versesReviewedToday] = versesReviewedToday
        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt
    }
}

// MARK: - Encouragement Messages

extension UserProgress.StreakUpdateResult {
    var feedbackMessage: String {
        switch self {
        case .continued:
            return "Keep it up! Your streak continues."
        case .sameDay:
            return "You're on a roll today!"
        case .graceDayUsed:
            return "Grace Day used - your streak is safe! 🙏"
        case .streakBroken(let previousStreak):
            return "You made it \(previousStreak) days! Life happens. Start fresh today. 🌅"
        case .firstActivity:
            return "Welcome! Your journey begins today."
        }
    }

    var shouldCelebrate: Bool {
        switch self {
        case .continued, .graceDayUsed, .firstActivity:
            return true
        case .sameDay, .streakBroken:
            return false
        }
    }
}

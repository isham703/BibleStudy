import Foundation
import GRDB

// MARK: - Achievement Service
// Manages achievement tracking, unlocking, and persistence

@MainActor
@Observable
final class AchievementService {
    // MARK: - Singleton
    static let shared = AchievementService()

    // MARK: - Properties
    private let db = DatabaseManager.shared

    // All achievements with their current state
    private(set) var achievements: [Achievement] = []

    // Recently unlocked (for celebration animation)
    private(set) var recentlyUnlocked: Achievement?

    // Loading state
    private(set) var isLoading = false

    // MARK: - Computed Properties

    var unlockedAchievements: [Achievement] {
        achievements.filter { $0.isUnlocked }
    }

    var lockedAchievements: [Achievement] {
        achievements.filter { !$0.isUnlocked && !$0.isSecret }
    }

    var totalXPFromAchievements: Int {
        unlockedAchievements.reduce(0) { $0 + $1.xpReward }
    }

    var completionPercentage: Double {
        let visibleAchievements = achievements.filter { !$0.isSecret || $0.isUnlocked }
        guard !visibleAchievements.isEmpty else { return 0 }
        let unlocked = visibleAchievements.filter { $0.isUnlocked }.count
        return Double(unlocked) / Double(visibleAchievements.count)
    }

    // MARK: - Initialization

    private init() {
        loadAchievements()
    }

    // MARK: - Load Achievements

    func loadAchievements() {
        isLoading = true
        defer { isLoading = false }

        // Start with all predefined achievements
        var allAchievements = AchievementID.allCases.map { $0.achievement }

        // Load unlocked achievements from database
        Task {
            let unlockedRecords = await loadUnlockedFromDB()

            // Mark unlocked achievements
            for (index, achievement) in allAchievements.enumerated() {
                if let record = unlockedRecords.first(where: { $0.id == achievement.id }) {
                    allAchievements[index].isUnlocked = true
                    allAchievements[index].unlockedAt = record.unlockedAt
                }
            }

            await MainActor.run {
                self.achievements = allAchievements
            }
        }
    }

    private func loadUnlockedFromDB() async -> [AchievementRecord] {
        guard let dbQueue = db.dbQueue else { return [] }

        do {
            return try await Task.detached {
                try dbQueue.read { db in
                    try AchievementRecord.fetchAll(db)
                }
            }.value
        } catch {
            print("Failed to load achievements: \(error)")
            return []
        }
    }

    // MARK: - Unlock Achievement

    @discardableResult
    func unlock(_ achievementID: AchievementID) async -> Achievement? {
        guard let index = achievements.firstIndex(where: { $0.id == achievementID.rawValue }) else {
            return nil
        }

        // Already unlocked
        if achievements[index].isUnlocked {
            return nil
        }

        // Unlock
        let now = Date()
        achievements[index].isUnlocked = true
        achievements[index].unlockedAt = now

        let achievement = achievements[index]

        // Save to database
        await saveUnlockToDB(achievementID: achievementID.rawValue, unlockedAt: now)

        // Award XP
        _ = try? await ProgressService.shared.awardXP(amount: achievement.xpReward)

        // Set as recently unlocked (for celebration)
        recentlyUnlocked = achievement

        // Post notification
        NotificationCenter.default.post(
            name: .achievementUnlocked,
            object: nil,
            userInfo: ["achievement": achievement]
        )

        return achievement
    }

    private func saveUnlockToDB(achievementID: String, unlockedAt: Date) async {
        guard let dbQueue = db.dbQueue else { return }

        let record = AchievementRecord(id: achievementID, unlockedAt: unlockedAt)

        do {
            try await Task.detached {
                try dbQueue.write { db in
                    try record.save(db)
                }
            }.value
        } catch {
            print("Failed to save achievement: \(error)")
        }
    }

    // MARK: - Clear Recently Unlocked

    func clearRecentlyUnlocked() {
        recentlyUnlocked = nil
    }

    // MARK: - Progress Tracking

    func updateProgress(for achievementID: AchievementID, progress: Int) async {
        guard let index = achievements.firstIndex(where: { $0.id == achievementID.rawValue }) else {
            return
        }

        // Already unlocked
        if achievements[index].isUnlocked {
            return
        }

        achievements[index].currentProgress = progress

        // Check if should unlock
        if progress >= achievements[index].requiredProgress {
            await unlock(achievementID)
        }
    }

    // MARK: - Check Specific Achievements

    func checkStreakAchievements(streak: Int) async {
        if streak >= 7 {
            await unlock(.weekStreak)
        }
        if streak >= 30 {
            await unlock(.monthStreak)
        }
        if streak >= 100 {
            await unlock(.hundredDayStreak)
        }
        if streak >= 365 {
            await unlock(.yearStreak)
        }
    }

    func checkLevelAchievements(level: UserLevel) async {
        switch level {
        case .apprentice:
            await unlock(.reachApprentice)
        case .scholar:
            await unlock(.reachScholar)
        case .master:
            await unlock(.reachMaster)
        default:
            break
        }
    }

    func checkReadingAchievements(chaptersRead: Int) async {
        await updateProgress(for: .firstChapter, progress: chaptersRead)
        await updateProgress(for: .tenChapters, progress: chaptersRead)
        await updateProgress(for: .fiftyChapters, progress: chaptersRead)
    }

    func checkMemorizationAchievements(versesAdded: Int, versesMastered: Int) async {
        await updateProgress(for: .firstVerse, progress: versesAdded)
        await updateProgress(for: .tenVerses, progress: versesAdded)
        await updateProgress(for: .masterVerse, progress: versesMastered)
        await updateProgress(for: .memoryMaster, progress: versesMastered)
    }

    // MARK: - Get Achievement by ID

    func achievement(for id: AchievementID) -> Achievement? {
        achievements.first { $0.id == id.rawValue }
    }

    // MARK: - Get Achievements by Category

    func achievements(in category: AchievementCategory) -> [Achievement] {
        achievements.filter { $0.category == category }
    }
}

// MARK: - Achievement Migration

extension DatabaseMigrator {
    mutating func registerAchievementMigration() {
        registerMigration("v19_achievements") { db in
            try db.create(table: "achievements", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("unlocked_at", .datetime).notNull()
            }
        }
    }
}

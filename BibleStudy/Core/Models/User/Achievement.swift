import Foundation
import GRDB

// MARK: - Achievement
// Represents an unlockable achievement for gamification

struct Achievement: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let xpReward: Int
    let isSecret: Bool  // Hidden until unlocked
    let requiredProgress: Int  // For progressive achievements

    // Runtime state
    var isUnlocked: Bool = false
    var unlockedAt: Date?
    var currentProgress: Int = 0
}

// MARK: - Achievement Category

enum AchievementCategory: String, Codable, CaseIterable, Sendable {
    case reading
    case memorization
    case streaks
    case study
    case milestones

    var displayName: String {
        switch self {
        case .reading: return "Reading"
        case .memorization: return "Memorization"
        case .streaks: return "Streaks"
        case .study: return "Study"
        case .milestones: return "Milestones"
        }
    }

    var icon: String {
        switch self {
        case .reading: return "book.fill"
        case .memorization: return "brain.head.profile"
        case .streaks: return "flame.fill"
        case .study: return "lightbulb.fill"
        case .milestones: return "trophy.fill"
        }
    }
}

// MARK: - Predefined Achievements

enum AchievementID: String, CaseIterable {
    // Reading
    case firstChapter = "first_chapter"
    case tenChapters = "ten_chapters"
    case fiftyChapters = "fifty_chapters"
    case readNewTestament = "read_new_testament"

    // Memorization
    case firstVerse = "first_verse"
    case tenVerses = "ten_verses"
    case masterVerse = "master_verse"
    case memoryMaster = "memory_master"

    // Streaks
    case weekStreak = "week_streak"
    case monthStreak = "month_streak"
    case hundredDayStreak = "hundred_day_streak"
    case yearStreak = "year_streak"

    // Study
    case firstNote = "first_note"
    case firstHighlight = "first_highlight"
    case firstInsight = "first_insight"
    case wordStudy = "word_study"

    // Milestones
    case completeOnboarding = "complete_onboarding"
    case reachApprentice = "reach_apprentice"
    case reachScholar = "reach_scholar"
    case reachMaster = "reach_master"
}

extension AchievementID {
    var achievement: Achievement {
        switch self {
        // Reading
        case .firstChapter:
            return Achievement(
                id: rawValue,
                title: "First Steps",
                description: "Read your first chapter",
                icon: "book",
                category: .reading,
                xpReward: 25,
                isSecret: false,
                requiredProgress: 1
            )
        case .tenChapters:
            return Achievement(
                id: rawValue,
                title: "Getting Started",
                description: "Read 10 chapters",
                icon: "books.vertical",
                category: .reading,
                xpReward: 50,
                isSecret: false,
                requiredProgress: 10
            )
        case .fiftyChapters:
            return Achievement(
                id: rawValue,
                title: "Dedicated Reader",
                description: "Read 50 chapters",
                icon: "text.book.closed.fill",
                category: .reading,
                xpReward: 150,
                isSecret: false,
                requiredProgress: 50
            )
        case .readNewTestament:
            return Achievement(
                id: rawValue,
                title: "New Testament Complete",
                description: "Read all 260 chapters of the New Testament",
                icon: "checkmark.seal.fill",
                category: .reading,
                xpReward: 500,
                isSecret: false,
                requiredProgress: 260
            )

        // Memorization
        case .firstVerse:
            return Achievement(
                id: rawValue,
                title: "Memory Keeper",
                description: "Add your first verse to memorize",
                icon: "brain",
                category: .memorization,
                xpReward: 25,
                isSecret: false,
                requiredProgress: 1
            )
        case .tenVerses:
            return Achievement(
                id: rawValue,
                title: "Growing Collection",
                description: "Add 10 verses to memorize",
                icon: "brain.head.profile",
                category: .memorization,
                xpReward: 75,
                isSecret: false,
                requiredProgress: 10
            )
        case .masterVerse:
            return Achievement(
                id: rawValue,
                title: "First Mastery",
                description: "Master your first verse",
                icon: "star.fill",
                category: .memorization,
                xpReward: 100,
                isSecret: false,
                requiredProgress: 1
            )
        case .memoryMaster:
            return Achievement(
                id: rawValue,
                title: "Memory Master",
                description: "Master 10 verses",
                icon: "crown.fill",
                category: .memorization,
                xpReward: 300,
                isSecret: false,
                requiredProgress: 10
            )

        // Streaks
        case .weekStreak:
            return Achievement(
                id: rawValue,
                title: "Week Warrior",
                description: "Maintain a 7-day streak",
                icon: "flame",
                category: .streaks,
                xpReward: 50,
                isSecret: false,
                requiredProgress: 7
            )
        case .monthStreak:
            return Achievement(
                id: rawValue,
                title: "Month of Dedication",
                description: "Maintain a 30-day streak",
                icon: "flame.fill",
                category: .streaks,
                xpReward: 200,
                isSecret: false,
                requiredProgress: 30
            )
        case .hundredDayStreak:
            return Achievement(
                id: rawValue,
                title: "Century Club",
                description: "Maintain a 100-day streak",
                icon: "100.circle.fill",
                category: .streaks,
                xpReward: 500,
                isSecret: false,
                requiredProgress: 100
            )
        case .yearStreak:
            return Achievement(
                id: rawValue,
                title: "Year of Faith",
                description: "Maintain a 365-day streak",
                icon: "star.circle.fill",
                category: .streaks,
                xpReward: 1000,
                isSecret: true,
                requiredProgress: 365
            )

        // Study
        case .firstNote:
            return Achievement(
                id: rawValue,
                title: "Note Taker",
                description: "Create your first note",
                icon: "note.text",
                category: .study,
                xpReward: 15,
                isSecret: false,
                requiredProgress: 1
            )
        case .firstHighlight:
            return Achievement(
                id: rawValue,
                title: "Highlighter",
                description: "Highlight your first verse",
                icon: "highlighter",
                category: .study,
                xpReward: 10,
                isSecret: false,
                requiredProgress: 1
            )
        case .firstInsight:
            return Achievement(
                id: rawValue,
                title: "Curious Mind",
                description: "Get your first AI insight",
                icon: "lightbulb.fill",
                category: .study,
                xpReward: 20,
                isSecret: false,
                requiredProgress: 1
            )
        case .wordStudy:
            return Achievement(
                id: rawValue,
                title: "Word Scholar",
                description: "Study a Hebrew or Greek word",
                icon: "character.book.closed.fill",
                category: .study,
                xpReward: 30,
                isSecret: false,
                requiredProgress: 1
            )

        // Milestones
        case .completeOnboarding:
            return Achievement(
                id: rawValue,
                title: "Welcome",
                description: "Complete the onboarding",
                icon: "hand.wave.fill",
                category: .milestones,
                xpReward: 10,
                isSecret: false,
                requiredProgress: 1
            )
        case .reachApprentice:
            return Achievement(
                id: rawValue,
                title: "Apprentice",
                description: "Reach the Apprentice level",
                icon: "book.fill",
                category: .milestones,
                xpReward: 50,
                isSecret: false,
                requiredProgress: 100
            )
        case .reachScholar:
            return Achievement(
                id: rawValue,
                title: "Scholar",
                description: "Reach the Scholar level",
                icon: "graduationcap.fill",
                category: .milestones,
                xpReward: 100,
                isSecret: false,
                requiredProgress: 500
            )
        case .reachMaster:
            return Achievement(
                id: rawValue,
                title: "Master",
                description: "Reach the Master level",
                icon: "crown.fill",
                category: .milestones,
                xpReward: 200,
                isSecret: false,
                requiredProgress: 2000
            )
        }
    }
}

// MARK: - Achievement Record (for persistence)

struct AchievementRecord: Identifiable, Hashable, Sendable {
    let id: String
    let unlockedAt: Date

    init(id: String, unlockedAt: Date = Date()) {
        self.id = id
        self.unlockedAt = unlockedAt
    }
}

// MARK: - GRDB Support for AchievementRecord

extension AchievementRecord: FetchableRecord, PersistableRecord {
    nonisolated static var databaseTableName: String { "achievements" }

    enum Columns: String, ColumnExpression {
        case id
        case unlockedAt = "unlocked_at"
    }

    nonisolated init(row: Row) throws {
        id = row[Columns.id]
        unlockedAt = row[Columns.unlockedAt]
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.unlockedAt] = unlockedAt
    }
}

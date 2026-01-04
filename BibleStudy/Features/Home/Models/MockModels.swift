import Foundation

// MARK: - Mock Models
// Data structures for placeholder content in the showcase

// MARK: - User Data

struct MockUserData {
    let userName: String?
    let currentStreak: Int
    let graceDayUsed: Bool
}

// MARK: - Daily Verse

struct MockDailyVerse {
    let reference: String
    let text: String
    let theme: String
}

// MARK: - Reading Plan

struct MockReadingPlan {
    let title: String
    let currentDay: Int
    let totalDays: Int
    let todayReference: String
    let todayTitle: String
    let previewQuote: String
    let progress: Double

    var progressPercentage: Int {
        Int(progress * 100)
    }
}

// MARK: - Practice Data

struct MockPracticeData {
    let dueCount: Int
    let learningCount: Int
    let reviewingCount: Int
    let estimatedMinutes: Int
    let hasPracticeItems: Bool

    var isCaughtUp: Bool {
        hasPracticeItems && dueCount == 0
    }
}

// MARK: - AI Insight

struct MockAIInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let summary: String
    let relatedVerses: [String]

    enum InsightType {
        case theme
        case connection
        case reflection
    }
}

// MARK: - Discovery Item

struct MockDiscoveryItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let type: DiscoveryType
    let estimatedMinutes: Int

    enum DiscoveryType: String {
        case story = "Story"
        case topic = "Topic"
        case character = "Character"

        var iconName: String {
            switch self {
            case .story: return "book.fill"
            case .topic: return "tag.fill"
            case .character: return "person.fill"
            }
        }
    }
}

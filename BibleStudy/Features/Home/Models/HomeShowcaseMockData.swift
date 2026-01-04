import Foundation

// MARK: - Home Showcase Mock Data
// Hardcoded placeholder content for visual mockups

enum HomeShowcaseMockData {

    // MARK: - User Data

    static let userData = MockUserData(
        userName: "Sarah",
        currentStreak: 14,
        graceDayUsed: false
    )

    // MARK: - Daily Verse

    static let dailyVerse = MockDailyVerse(
        reference: "Psalm 119:105",
        text: "Your word is a lamp to my feet and a light to my path.",
        theme: "Guidance"
    )

    // MARK: - Reading Plan

    static let activePlan = MockReadingPlan(
        title: "Gospel of John",
        currentDay: 8,
        totalDays: 21,
        todayReference: "John 8:1-59",
        todayTitle: "The Woman Caught in Adultery",
        previewQuote: "Neither do I condemn you; go, and sin no more.",
        progress: 0.38
    )

    // MARK: - Practice Data

    static let practiceData = MockPracticeData(
        dueCount: 5,
        learningCount: 2,
        reviewingCount: 3,
        estimatedMinutes: 10,
        hasPracticeItems: true
    )

    // MARK: - AI Insights

    static let currentInsight = MockAIInsight(
        type: .theme,
        title: "Theme in Your Reading",
        summary: "You've been drawn to passages about faith and trust this week. Consider exploring how these themes connect across the Old and New Testaments.",
        relatedVerses: ["Hebrews 11:1", "Romans 5:1", "Proverbs 3:5"]
    )

    static let allInsights: [MockAIInsight] = [
        currentInsight,
        MockAIInsight(
            type: .connection,
            title: "Connection Discovered",
            summary: "The story of Joseph in Genesis mirrors themes in the Prodigal Son parable.",
            relatedVerses: ["Genesis 45:4-5", "Luke 15:20"]
        ),
        MockAIInsight(
            type: .reflection,
            title: "Reflection Prompt",
            summary: "How has God's faithfulness shown up in your own journey?",
            relatedVerses: ["Lamentations 3:22-23"]
        )
    ]

    // MARK: - Featured Stories

    static let featuredStories: [MockDiscoveryItem] = [
        MockDiscoveryItem(
            title: "The Prodigal Son",
            subtitle: "Luke 15:11-32",
            type: .story,
            estimatedMinutes: 8
        ),
        MockDiscoveryItem(
            title: "David and Goliath",
            subtitle: "1 Samuel 17",
            type: .story,
            estimatedMinutes: 12
        ),
        MockDiscoveryItem(
            title: "The Good Samaritan",
            subtitle: "Luke 10:25-37",
            type: .story,
            estimatedMinutes: 6
        ),
        MockDiscoveryItem(
            title: "Daniel in the Lion's Den",
            subtitle: "Daniel 6",
            type: .story,
            estimatedMinutes: 10
        )
    ]

    // MARK: - Featured Topics

    static let featuredTopics: [MockDiscoveryItem] = [
        MockDiscoveryItem(
            title: "Grace",
            subtitle: "Unmerited divine favor",
            type: .topic,
            estimatedMinutes: 15
        ),
        MockDiscoveryItem(
            title: "Faith",
            subtitle: "Trusting in the unseen",
            type: .topic,
            estimatedMinutes: 12
        ),
        MockDiscoveryItem(
            title: "Redemption",
            subtitle: "The act of being saved",
            type: .topic,
            estimatedMinutes: 18
        ),
        MockDiscoveryItem(
            title: "Covenant",
            subtitle: "God's promises to His people",
            type: .topic,
            estimatedMinutes: 20
        )
    ]

    // MARK: - All Discovery Items (Combined)

    static var allDiscoveryItems: [MockDiscoveryItem] {
        featuredStories + featuredTopics
    }

    // MARK: - Greeting

    static var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }

    static var fullGreeting: String {
        if let name = userData.userName {
            return "\(greetingText), \(name)"
        }
        return greetingText
    }

    // MARK: - Date Formatting

    static var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}

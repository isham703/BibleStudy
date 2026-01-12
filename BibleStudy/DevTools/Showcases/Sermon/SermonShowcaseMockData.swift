import Foundation

// MARK: - Sermon Showcase Mock Data

/// Provides realistic sermon data for showcase previews.
enum SermonShowcaseMockData {
    // MARK: - Sermon Metadata

    static let sermonTitle = "The Discipline of Contentment"
    static let speakerName = "Pastor David Chen"
    static let churchName = "Grace Reformed Church"
    static let sermonDate = "January 5, 2026"
    static let duration: TimeInterval = 2340 // 39 minutes
    static let currentTime: TimeInterval = 847 // 14:07
    static let status = "In Progress"

    static var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    static var formattedCurrentTime: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    static var formattedRemaining: String {
        let remaining = duration - currentTime
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "-%d:%02d", minutes, seconds)
    }

    static var progress: Double {
        currentTime / duration
    }

    // MARK: - Transcript Segments

    static let transcriptSegments: [ShowcaseTranscriptSegment] = [
        ShowcaseTranscriptSegment(
            id: "seg-1",
            text: "Good morning, church. Today we turn our attention to one of the most countercultural virtues a Christian can cultivate: contentment. In a world that constantly tells us we need more, that satisfaction lies just beyond our reach, the Apostle Paul offers us a radically different perspective.",
            timestamp: "0:00",
            startTime: 0
        ),
        ShowcaseTranscriptSegment(
            id: "seg-2",
            text: "Turn with me to Philippians chapter four, verses eleven through thirteen. Paul writes from prison—not from a place of comfort, but from chains. And yet, listen to what he says.",
            timestamp: "0:42",
            startTime: 42
        ),
        ShowcaseTranscriptSegment(
            id: "seg-3",
            text: "\"I have learned to be content whatever the circumstances. I know what it is to be in need, and I know what it is to have plenty. I have learned the secret of being content in any and every situation, whether well fed or hungry, whether living in plenty or in want.\"",
            timestamp: "1:18",
            startTime: 78
        ),
        ShowcaseTranscriptSegment(
            id: "seg-4",
            text: "Notice Paul doesn't say contentment came naturally to him. He says he learned it. This is crucial for us to understand. Contentment is not a personality trait—it's a discipline. It's something we practice, something we grow into through intentional spiritual formation.",
            timestamp: "2:05",
            startTime: 125
        ),
        ShowcaseTranscriptSegment(
            id: "seg-5",
            text: "The Stoics had a word for this inner tranquility: ataraxia. But Paul goes beyond mere philosophical calm. His contentment is rooted in Christ. 'I can do all things through him who strengthens me.' This isn't self-sufficiency—it's Christ-sufficiency.",
            timestamp: "3:12",
            startTime: 192
        ),
        ShowcaseTranscriptSegment(
            id: "seg-6",
            text: "So how do we cultivate this discipline? Let me offer three practices that have shaped my own journey toward contentment. First, we must practice gratitude daily. Not as a positive-thinking exercise, but as an act of worship.",
            timestamp: "4:28",
            startTime: 268
        )
    ]

    // MARK: - Key Takeaways

    static let keyTakeaways: [String] = [
        "Contentment is learned through spiritual discipline, not acquired by circumstance",
        "Paul's secret: finding sufficiency in Christ rather than in external conditions",
        "Gratitude is worship—a daily practice that reorients the heart",
        "True contentment frees us to give generously and live purposefully"
    ]

    // MARK: - Scripture References

    static let scriptureReferences: [ScriptureRef] = [
        ScriptureRef(
            reference: "Philippians 4:11-13",
            text: "I have learned to be content whatever the circumstances...",
            isVerified: true,
            isPrimary: true
        ),
        ScriptureRef(
            reference: "1 Timothy 6:6-8",
            text: "But godliness with contentment is great gain...",
            isVerified: true,
            isPrimary: false
        ),
        ScriptureRef(
            reference: "Hebrews 13:5",
            text: "Keep your lives free from the love of money and be content with what you have...",
            isVerified: true,
            isPrimary: false
        ),
        ScriptureRef(
            reference: "Matthew 6:25-34",
            text: "Therefore I tell you, do not worry about your life...",
            isVerified: true,
            isPrimary: false
        ),
        ScriptureRef(
            reference: "Psalm 23:1",
            text: "The Lord is my shepherd, I lack nothing.",
            isVerified: false,
            isPrimary: false
        )
    ]

    // MARK: - AI Insights

    static let aiSummary = "Pastor Chen explores Paul's teaching on contentment from Philippians 4, distinguishing biblical contentment from Stoic philosophy. The sermon emphasizes that contentment is a learned discipline rooted in Christ's sufficiency, not circumstances. Three practical applications are offered: daily gratitude as worship, reframing wants versus needs, and intentional simplicity."

    static let aiThemes: [ThemeItem] = [
        ThemeItem(theme: "Spiritual Discipline", description: "Contentment as practiced virtue"),
        ThemeItem(theme: "Christ-Sufficiency", description: "Source of true contentment"),
        ThemeItem(theme: "Counter-Cultural Living", description: "Resisting consumerism"),
        ThemeItem(theme: "Gratitude", description: "Worship through thanksgiving")
    ]

    static let aiOutline: [ShowcaseOutlineSection] = [
        ShowcaseOutlineSection(
            title: "Introduction",
            timestamp: "0:00",
            points: ["The cultural challenge of contentment", "Paul's counter-cultural witness"]
        ),
        ShowcaseOutlineSection(
            title: "The Text: Philippians 4:11-13",
            timestamp: "1:18",
            points: ["Context: Paul writes from prison", "Key phrase: 'I have learned'"]
        ),
        ShowcaseOutlineSection(
            title: "Contentment as Discipline",
            timestamp: "2:05",
            points: ["Not personality, but practice", "Stoic ataraxia vs. Christian contentment"]
        ),
        ShowcaseOutlineSection(
            title: "Three Practices",
            timestamp: "4:28",
            points: ["1. Daily gratitude as worship", "2. Reframing wants and needs", "3. Intentional simplicity"]
        )
    ]

    static let discussionQuestions: [DiscussionQuestion] = [
        DiscussionQuestion(
            question: "How does Paul's situation (writing from prison) affect how we understand his teaching on contentment?",
            type: .comprehension
        ),
        DiscussionQuestion(
            question: "What is the difference between Stoic detachment and Christian contentment as described in the sermon?",
            type: .interpretation
        ),
        DiscussionQuestion(
            question: "Which of the three practices (gratitude, reframing, simplicity) do you find most challenging? Why?",
            type: .application
        ),
        DiscussionQuestion(
            question: "In what specific area of your life is God calling you to cultivate greater contentment this week?",
            type: .reflection
        )
    ]

    static let crossReferences: [ShowcaseCrossReference] = [
        ShowcaseCrossReference(
            reference: "Ecclesiastes 5:10",
            connection: "The futility of wealth to satisfy"
        ),
        ShowcaseCrossReference(
            reference: "Proverbs 30:8-9",
            connection: "Prayer for contentment with enough"
        ),
        ShowcaseCrossReference(
            reference: "Luke 12:15",
            connection: "Jesus on guarding against greed"
        )
    ]

    // MARK: - Study Guide

    static let reflectionPrompts: [String] = [
        "Reflect on a time when you experienced true contentment. What circumstances surrounded that experience?",
        "What 'more' are you currently chasing that may be hindering your contentment?",
        "How might practicing gratitude as worship change your daily perspective?"
    ]

    static let applicationPoints: [String] = [
        "Begin a gratitude journal this week, writing three things you're thankful for each morning",
        "Identify one area where you've confused a 'want' with a 'need' and consider how to address it",
        "Practice a media fast for one day to create space for contentment"
    ]

    // MARK: - Notes

    static let userNotes: [UserNote] = [
        UserNote(
            id: "note-1",
            text: "Contentment is learned, not inherited—this challenges my excuses",
            timestamp: "2:05",
            createdAt: Date()
        ),
        UserNote(
            id: "note-2",
            text: "Look up the Greek word for 'learned' here—autarkēs?",
            timestamp: "4:28",
            createdAt: Date()
        )
    ]

    // MARK: - Recent Sermons (for library)

    static let recentSermons: [RecentSermon] = [
        RecentSermon(
            title: "The Discipline of Contentment",
            speaker: "Pastor David Chen",
            date: "Jan 5, 2026",
            duration: "39:00",
            isInProgress: true
        ),
        RecentSermon(
            title: "Walking in Wisdom",
            speaker: "Pastor David Chen",
            date: "Dec 29, 2025",
            duration: "42:15",
            isInProgress: false
        ),
        RecentSermon(
            title: "The Advent of Hope",
            speaker: "Rev. Sarah Mitchell",
            date: "Dec 22, 2025",
            duration: "35:48",
            isInProgress: false
        )
    ]
}

// MARK: - Supporting Types

struct ShowcaseTranscriptSegment: Identifiable {
    let id: String
    let text: String
    let timestamp: String
    let startTime: TimeInterval
}

struct ScriptureRef: Identifiable {
    let id = UUID()
    let reference: String
    let text: String
    let isVerified: Bool
    let isPrimary: Bool
}

struct ThemeItem: Identifiable {
    let id = UUID()
    let theme: String
    let description: String
}

struct ShowcaseOutlineSection: Identifiable {
    let id = UUID()
    let title: String
    let timestamp: String
    let points: [String]
}

struct DiscussionQuestion: Identifiable {
    let id = UUID()
    let question: String
    let type: QuestionType

    enum QuestionType: String {
        case comprehension = "Comprehension"
        case interpretation = "Interpretation"
        case application = "Application"
        case reflection = "Reflection"
    }
}

struct ShowcaseCrossReference: Identifiable {
    let id = UUID()
    let reference: String
    let connection: String
}

struct UserNote: Identifiable {
    let id: String
    let text: String
    let timestamp: String
    let createdAt: Date
}

struct RecentSermon: Identifiable {
    let id = UUID()
    let title: String
    let speaker: String
    let date: String
    let duration: String
    let isInProgress: Bool
}

import Foundation

// MARK: - AI Service Protocol
// Abstraction layer for AI providers (OpenAI, Anthropic, etc.)

protocol AIServiceProtocol {
    /// Generate a quick 1-2 sentence insight for ambient AI display
    func generateQuickInsight(verseRange: VerseRange, verseText: String) async throws -> QuickInsightOutput

    /// Generate an explanation for a verse range
    func generateExplanation(input: ExplanationInput) async throws -> ExplanationOutput

    /// Generate a "why linked" explanation for cross-references
    func generateWhyLinked(source: VerseRange, target: VerseRange, context: String?) async throws -> String

    /// Generate an explanation for a Hebrew/Greek term in context
    func generateTermExplanation(lemma: String, morph: String, verseContext: String) async throws -> String

    /// Generate an interpretation with multiple perspectives
    func generateInterpretation(input: InterpretationInput) async throws -> InterpretationOutput

    /// Generate embeddings for semantic search
    func embedText(text: String) async throws -> [Float]

    // MARK: - Comprehension Features (Phase 5)

    /// Simplify a passage for a specific reading level
    func simplifyPassage(verseRange: VerseRange, verseText: String, level: ReadingLevel) async throws -> SimplifiedPassageOutput

    /// Summarize a passage in one sentence
    func summarizePassage(verseRange: VerseRange, verseText: String) async throws -> PassageSummaryOutput

    /// Generate comprehension questions for a passage
    func generateComprehensionQuestions(verseRange: VerseRange, verseText: String, passageType: PassageType) async throws -> ComprehensionQuestionsOutput

    /// Clarify a specific phrase or word in context
    func clarifyPhrase(phrase: String, verseRange: VerseRange, verseText: String) async throws -> PhraseClarificationOutput

    // MARK: - Narrative Cards (Phase Stories)

    /// Generate a biblical narrative story from a passage
    func generateStory(input: StoryGenerationInput) async throws -> StoryGenerationOutput

    // MARK: - Chat (Ask Tab)

    /// Send a chat message and receive a structured response
    func sendChatMessage(input: ChatMessageInput) async throws -> ChatMessageOutput

    // MARK: - Prayer Generation (Prayers from the Deep)

    /// Generate a prayer in a specified tradition based on user's context
    func generatePrayer(input: PrayerGenerationInput) async throws -> PrayerGenerationOutput

    // MARK: - Sermon Analysis

    /// Generate a study guide from a sermon transcript
    func generateSermonStudyGuide(input: SermonStudyGuideInput) async throws -> SermonStudyGuideOutput

    /// Check if the service is available
    var isAvailable: Bool { get }
}

// MARK: - Quick Insight Output
// Compact insight for ambient AI display above selection toolbar

struct QuickInsightOutput: Codable {
    let summary: String           // 1-2 sentence main insight
    let keyTerm: String?          // Optional key Hebrew/Greek term
    let keyTermMeaning: String?   // Meaning of the key term
    let suggestedAction: QuickInsightAction?  // What to explore next

    /// Sources used to generate this insight (for trust UX)
    var groundingSources: [String] {
        var sources: [String] = ["Selected passage text"]
        if keyTerm != nil { sources.append("Original language lexicon") }
        return sources
    }
}

enum QuickInsightAction: String, Codable {
    case explainMore = "explain"
    case understand = "understand"  // Phase 5: Comprehension
    case showContext = "context"
    case viewLanguage = "language"
    case seeCrossRefs = "crossRefs"

    var buttonTitle: String {
        switch self {
        case .explainMore: return "Explain"
        case .understand: return "Understand"
        case .showContext: return "Context"
        case .viewLanguage: return "Language"
        case .seeCrossRefs: return "Cross-refs"
        }
    }

    var icon: String {
        switch self {
        case .explainMore: return "sparkles"
        case .understand: return "graduationcap"
        case .showContext: return "text.alignleft"
        case .viewLanguage: return "character.book.closed"
        case .seeCrossRefs: return "arrow.triangle.branch"
        }
    }
}

// MARK: - Explanation Input/Output

struct ExplanationInput {
    let verseRange: VerseRange
    let verseText: String
    let surroundingContext: String?
    let mode: ExplanationMode
    let translation: String

    init(
        verseRange: VerseRange,
        verseText: String,
        surroundingContext: String? = nil,
        mode: ExplanationMode = .plain,
        translation: String = "KJV"
    ) {
        self.verseRange = verseRange
        self.verseText = verseText
        self.surroundingContext = surroundingContext
        self.mode = mode
        self.translation = translation
    }
}

enum ExplanationMode: String, Codable {
    case plain
    case detailed
    case scholarly
}

struct ExplanationOutput: Codable {
    let explanation: String
    let keyPoints: [String]?
    let relatedVerses: [String]?
    let historicalContext: String?
    let applicationPoints: [String]?
    let uncertaintyNotes: String?

    // Trust UX: "Show why" reasoning
    let reasoning: [ReasoningPoint]?

    // Trust UX: Translation context notes
    let translationNotes: [TranslationNote]?

    var promptHash: String {
        // Generate a hash for caching
        let data = (explanation + (keyPoints?.joined() ?? "")).data(using: .utf8) ?? Data()
        return data.base64EncodedString().prefix(16).description
    }

    /// Sources used to generate this explanation (for trust UX)
    var groundingSources: [String] {
        var sources: [String] = ["Selected passage text"]
        if relatedVerses != nil && !(relatedVerses?.isEmpty ?? true) {
            sources.append("Cross-reference database")
        }
        if historicalContext != nil {
            sources.append("Historical context")
        }
        if translationNotes != nil && !(translationNotes?.isEmpty ?? true) {
            sources.append("Translation comparison")
        }
        return sources
    }
}

/// A note explaining translation differences
struct TranslationNote: Codable, Identifiable {
    let id: String
    let phrase: String           // The phrase in question
    let translations: [String]   // e.g., ["KJV: love", "ESV: charity"]
    let explanation: String      // Why they differ

    init(id: String = UUID().uuidString, phrase: String, translations: [String], explanation: String) {
        self.id = id
        self.phrase = phrase
        self.translations = translations
        self.explanation = explanation
    }
}

/// A single point of reasoning explaining WHY the AI reached a conclusion
struct ReasoningPoint: Codable, Identifiable {
    let id: String
    let phrase: String        // The phrase from the text this refers to
    let explanation: String   // Why this phrase supports the conclusion

    init(id: String = UUID().uuidString, phrase: String, explanation: String) {
        self.id = id
        self.phrase = phrase
        self.explanation = explanation
    }
}

// MARK: - Interpretation Input/Output

struct InterpretationInput {
    let verseRange: VerseRange
    let verseText: String
    let surroundingContext: String?
    let mode: InterpretationViewMode
    let includeReflection: Bool
    let translation: String

    init(
        verseRange: VerseRange,
        verseText: String,
        surroundingContext: String? = nil,
        mode: InterpretationViewMode = .plain,
        includeReflection: Bool = true,
        translation: String = "KJV"
    ) {
        self.verseRange = verseRange
        self.verseText = verseText
        self.surroundingContext = surroundingContext
        self.mode = mode
        self.includeReflection = includeReflection
        self.translation = translation
    }
}

enum InterpretationViewMode: String, Codable, CaseIterable {
    case plain
    case historical
    case literary
    case devotional
}

struct InterpretationOutput: Codable {
    let plainMeaning: String
    let context: String
    let keyTerms: [String]
    let crossReferences: [String]
    let interpretationNotes: String
    let reflectionPrompt: String?
    let hasDebatedInterpretations: Bool
    let uncertaintyIndicators: [String]?

    // Trust UX: "Show why" reasoning
    let reasoning: [ReasoningPoint]?

    // Trust UX: "Different views" for interpretive content
    let alternativeViews: [AlternativeView]?

    /// Sources used to generate this interpretation (for trust UX)
    var groundingSources: [String] {
        var sources: [String] = ["Selected passage text"]
        if !keyTerms.isEmpty { sources.append("Original language lexicon") }
        if !crossReferences.isEmpty { sources.append("Cross-reference database") }
        if hasDebatedInterpretations { sources.append("Scholarly commentary traditions") }
        return sources
    }
}

/// An alternative interpretive view for showing multiple perspectives
struct AlternativeView: Codable, Identifiable {
    let id: String
    let viewName: String      // e.g., "Literal interpretation", "Allegorical reading"
    let summary: String       // Brief summary of this view
    let traditions: [String]? // Which traditions hold this view

    init(id: String = UUID().uuidString, viewName: String, summary: String, traditions: [String]? = nil) {
        self.id = id
        self.viewName = viewName
        self.summary = summary
        self.traditions = traditions
    }
}

// MARK: - Comprehension Outputs (Phase 5)

/// Simplified passage for reading level adaptation
struct SimplifiedPassageOutput: Codable {
    let simplified: String
    let keyTermsExplained: [KeyTermExplanation]?
    let oneLineSummary: String

    struct KeyTermExplanation: Codable, Identifiable {
        var id: String { term }
        let term: String
        let explanation: String
    }
}

/// One-sentence passage summary
struct PassageSummaryOutput: Codable {
    let summary: String
    let theme: String
    let whatHappened: String?
}

/// AI-generated comprehension questions
struct ComprehensionQuestionsOutput: Codable {
    let questions: [ComprehensionQuestion]
    let passageType: String

    struct ComprehensionQuestion: Codable, Identifiable {
        let id: String
        let question: String
        let type: String  // "observation", "interpretation", "application"
        let hint: String?

        var questionType: QuestionType {
            QuestionType(rawValue: type) ?? .observation
        }
    }

    enum QuestionType: String, Codable {
        case observation
        case interpretation
        case application

        var displayName: String {
            switch self {
            case .observation: return "What does it say?"
            case .interpretation: return "What does it mean?"
            case .application: return "How does it apply?"
            }
        }

        var icon: String {
            switch self {
            case .observation: return "eye"
            case .interpretation: return "lightbulb"
            case .application: return "heart"
            }
        }

        var color: String {
            switch self {
            case .observation: return "accentBlue"
            case .interpretation: return "accentGold"
            case .application: return "accentRose"
            }
        }
    }
}

/// Clarification of a specific phrase
struct PhraseClarificationOutput: Codable {
    let clarification: String
    let simpleVersion: String
    let whyItMatters: String
}

// MARK: - Story Generation Input/Output

/// Input for generating a biblical narrative story
struct StoryGenerationInput {
    let verseRange: VerseRange
    let verseText: String
    let storyType: StoryType
    let readingLevel: StoryReadingLevel
    let title: String?  // Optional custom title

    init(
        verseRange: VerseRange,
        verseText: String,
        storyType: StoryType = .narrative,
        readingLevel: StoryReadingLevel = .adult,
        title: String? = nil
    ) {
        self.verseRange = verseRange
        self.verseText = verseText
        self.storyType = storyType
        self.readingLevel = readingLevel
        self.title = title
    }
}

/// Output from AI story generation
struct StoryGenerationOutput: Codable {
    let title: String
    let subtitle: String?
    let description: String
    let estimatedMinutes: Int
    let segments: [GeneratedSegment]
    let characters: [GeneratedCharacter]?

    struct GeneratedSegment: Codable {
        let order: Int
        let title: String
        let content: String
        let verseAnchor: GeneratedVerseAnchor?
        let timelineLabel: String?
        let location: String?
        let mood: String?
        let reflectionQuestion: String?
        let keyTerm: GeneratedKeyTerm?

        enum CodingKeys: String, CodingKey {
            case order, title, content
            case verseAnchor = "verse_anchor"
            case timelineLabel = "timeline_label"
            case location, mood
            case reflectionQuestion = "reflection_question"
            case keyTerm = "key_term"
        }
    }

    struct GeneratedVerseAnchor: Codable {
        let bookId: Int
        let chapter: Int
        let verseStart: Int
        let verseEnd: Int

        enum CodingKeys: String, CodingKey {
            case bookId = "book_id"
            case chapter
            case verseStart = "verse_start"
            case verseEnd = "verse_end"
        }

        func toVerseRange() -> VerseRange {
            VerseRange(bookId: bookId, chapter: chapter, verseStart: verseStart, verseEnd: verseEnd)
        }
    }

    struct GeneratedKeyTerm: Codable {
        let term: String
        let originalWord: String?
        let briefMeaning: String

        enum CodingKeys: String, CodingKey {
            case term
            case originalWord = "original_word"
            case briefMeaning = "brief_meaning"
        }

        func toKeyTermHighlight() -> KeyTermHighlight {
            KeyTermHighlight(term: term, originalWord: originalWord, briefMeaning: briefMeaning)
        }
    }

    struct GeneratedCharacter: Codable {
        let name: String
        let title: String?
        let description: String
        let role: String
        let iconName: String?

        enum CodingKeys: String, CodingKey {
            case name, title, description, role
            case iconName = "icon_name"
        }

        func toStoryCharacter() -> StoryCharacter {
            StoryCharacter(
                name: name,
                title: title,
                description: description,
                role: CharacterRole(rawValue: role) ?? .supporting,
                iconName: iconName
            )
        }
    }

    enum CodingKeys: String, CodingKey {
        case title, subtitle, description
        case estimatedMinutes = "estimated_minutes"
        case segments, characters
    }

    /// Convert to Story model
    func toStory(
        verseAnchors: [VerseRange],
        storyType: StoryType,
        readingLevel: StoryReadingLevel,
        modelId: String
    ) -> Story {
        let storyId = UUID()

        let storySegments = segments.map { seg in
            StorySegment(
                storyId: storyId,
                order: seg.order,
                title: seg.title,
                content: seg.content,
                verseAnchor: seg.verseAnchor?.toVerseRange(),
                timelineLabel: seg.timelineLabel,
                location: seg.location,
                keyCharacters: [],
                mood: seg.mood.flatMap { SegmentMood(rawValue: $0) },
                reflectionQuestion: seg.reflectionQuestion,
                keyTerm: seg.keyTerm?.toKeyTermHighlight()
            )
        }

        let storyCharacters = characters?.map { $0.toStoryCharacter() } ?? []

        return Story(
            id: storyId,
            slug: "ai-\(UUID().uuidString.prefix(8).lowercased())",
            title: title,
            subtitle: subtitle,
            description: description,
            type: storyType,
            readingLevel: readingLevel,
            isPrebuilt: false,
            verseAnchors: verseAnchors,
            estimatedMinutes: estimatedMinutes,
            userId: nil,
            isPublic: false,
            generationMode: .ai,
            modelId: modelId,
            promptVersion: 1,
            schemaVersion: 1,
            generatedAt: Date(),
            sourcePassageIds: verseAnchors.map { $0.reference },
            segments: storySegments,
            characters: storyCharacters
        )
    }
}

// MARK: - Prayer Generation Input/Output

/// Input for generating a prayer in a tradition or category
struct PrayerGenerationInput {
    let userContext: String        // What the user is praying about
    let tradition: PrayerTradition? // Which prayer tradition to use (legacy)
    let category: PrayerCategory?   // Which intention category to use (new)

    /// Initialize with tradition (legacy)
    init(userContext: String, tradition: PrayerTradition) {
        self.userContext = userContext
        self.tradition = tradition
        self.category = nil
    }

    /// Initialize with category (new intention-based)
    init(userContext: String, category: PrayerCategory) {
        self.userContext = userContext
        self.tradition = nil
        self.category = category
    }
}

/// Output from AI prayer generation
struct PrayerGenerationOutput: Codable {
    let content: String   // The prayer text (multiple lines/stanzas)
    let amen: String      // Tradition-appropriate closing
}

// MARK: - Sermon Study Guide Input/Output

/// Input for generating a sermon study guide
struct SermonStudyGuideInput {
    let transcript: String                    // Full transcript text
    let title: String?                        // Optional sermon title
    let speakerName: String?                  // Optional speaker name
    let durationMinutes: Int?                 // Sermon length for context
    let explicitReferences: [String]          // Verse references detected in transcript

    // MARK: - Enrichment Fields (Phase: Cross-Reference Integration)

    /// Pre-built enrichment context with verified cross-refs and insights
    let enrichmentContext: SermonEnrichmentContext?

    /// Parsed verse ranges from explicit references
    let parsedVerseRanges: [VerseRange]?

    /// Whether enrichment data is available (controls AI behavior)
    let hasEnrichmentData: Bool

    init(
        transcript: String,
        title: String? = nil,
        speakerName: String? = nil,
        durationMinutes: Int? = nil,
        explicitReferences: [String] = [],
        enrichmentContext: SermonEnrichmentContext? = nil,
        parsedVerseRanges: [VerseRange]? = nil,
        hasEnrichmentData: Bool = false
    ) {
        self.transcript = transcript
        self.title = title
        self.speakerName = speakerName
        self.durationMinutes = durationMinutes
        self.explicitReferences = explicitReferences
        self.enrichmentContext = enrichmentContext
        self.parsedVerseRanges = parsedVerseRanges
        self.hasEnrichmentData = hasEnrichmentData
    }
}

/// Output from sermon study guide generation
struct SermonStudyGuideOutput: Codable {
    let title: String
    let summary: String
    let keyThemes: [String]

    // Navigation and grounding
    let outline: [SermonOutlineSection]?
    let notableQuotes: [SermonQuote]?
    let bibleReferencesMentioned: [AIVerseReference]
    let bibleReferencesSuggested: [AIVerseReference]

    // Study prompts
    let discussionQuestions: [AIStudyQuestion]
    let reflectionPrompts: [String]
    let applicationPoints: [String]

    // Diagnostics
    let confidenceNotes: [String]?
    let promptVersion: String

    enum CodingKeys: String, CodingKey {
        case title, summary, outline
        case keyThemes = "key_themes"
        case notableQuotes = "notable_quotes"
        case bibleReferencesMentioned = "bible_references_mentioned"
        case bibleReferencesSuggested = "bible_references_suggested"
        case discussionQuestions = "discussion_questions"
        case reflectionPrompts = "reflection_prompts"
        case applicationPoints = "application_points"
        case confidenceNotes = "confidence_notes"
        case promptVersion = "prompt_version"
    }
}

/// An outline section from a sermon
struct SermonOutlineSection: Codable, Hashable, Sendable, Identifiable {
    var id: String { title }
    let title: String
    let startSeconds: Double?
    let endSeconds: Double?
    let summary: String?

    enum CodingKeys: String, CodingKey {
        case title, summary
        case startSeconds = "start_seconds"
        case endSeconds = "end_seconds"
    }
}

/// A notable quote from a sermon
struct SermonQuote: Codable, Hashable, Sendable, Identifiable {
    var id: String { text }
    let text: String
    let timestampSeconds: Double?
    let context: String?

    enum CodingKeys: String, CodingKey {
        case text, context
        case timestampSeconds = "timestamp_seconds"
    }
}

/// A verse reference from AI analysis
struct AIVerseReference: Codable, Hashable, Sendable, Identifiable {
    var id: String { reference }
    let reference: String           // e.g., "John 3:16"
    let bookId: Int?
    let chapter: Int?
    let verseStart: Int?
    let verseEnd: Int?
    let isMentioned: Bool           // Explicitly mentioned vs AI-suggested
    let rationale: String?          // Why this reference is relevant
    let timestampSeconds: Double?   // When mentioned in sermon

    // MARK: - Enrichment Hints (from AI for post-processing)

    /// Hint from AI: "crossref_db", "ai_only", etc.
    let verificationHint: String?

    /// Source canonical IDs from AI (if it found cross-ref match)
    let verifiedBy: [String]?

    enum CodingKeys: String, CodingKey {
        case reference
        case bookId = "book_id"
        case chapter
        case verseStart = "verse_start"
        case verseEnd = "verse_end"
        case isMentioned = "is_mentioned"
        case rationale
        case timestampSeconds = "timestamp_seconds"
        case verificationHint = "verification_hint"
        case verifiedBy = "verified_by"
    }
}

// MARK: - AIVerseReference → SermonVerseReference Conversion

extension AIVerseReference {
    /// Convert to SermonVerseReference for storage
    func toSermonVerseReference(isMentioned: Bool) -> SermonVerseReference {
        SermonVerseReference(
            reference: reference,
            bookId: bookId,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd,
            isMentioned: isMentioned,
            rationale: rationale,
            timestampSeconds: timestampSeconds
        )
    }
}

/// A study question from AI analysis
struct AIStudyQuestion: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let question: String
    let type: AIQuestionType
    let relatedVerses: [String]?
    let discussionHint: String?

    enum CodingKeys: String, CodingKey {
        case id, question, type
        case relatedVerses = "related_verses"
        case discussionHint = "discussion_hint"
    }

    init(
        id: String = UUID().uuidString,
        question: String,
        type: AIQuestionType,
        relatedVerses: [String]? = nil,
        discussionHint: String? = nil
    ) {
        self.id = id
        self.question = question
        self.type = type
        self.relatedVerses = relatedVerses
        self.discussionHint = discussionHint
    }
}

/// Question type for AI-generated study questions
enum AIQuestionType: String, Codable, Sendable, CaseIterable {
    case comprehension
    case interpretation
    case application
    case discussion

    var displayName: String {
        switch self {
        case .comprehension: return "Comprehension"
        case .interpretation: return "Interpretation"
        case .application: return "Application"
        case .discussion: return "Discussion"
        }
    }

    var icon: String {
        switch self {
        case .comprehension: return "book"
        case .interpretation: return "lightbulb"
        case .application: return "hand.raised"
        case .discussion: return "bubble.left.and.bubble.right"
        }
    }
}

// MARK: - Prayer Generation Errors

enum PrayerGenerationError: Error, LocalizedError {
    case inputEmpty
    case inputTooLong
    case contentFlagged           // OpenAI moderation flagged the input
    case selfHarmDetected         // Self-harm content detected (show crisis modal)
    case moderationUnavailable    // Content safety check unavailable (network/API error)
    case networkError(Error)
    case rateLimited
    case generationFailed(Error)

    var errorDescription: String? {
        switch self {
        case .inputEmpty:
            return "Please share what's on your heart."
        case .inputTooLong:
            return "Please try a shorter message (500 characters max)."
        case .contentFlagged:
            return "Unable to verify safety. Please try again or rephrase your request."
        case .selfHarmDetected:
            return nil  // Handled by crisis modal
        case .moderationUnavailable:
            return "Unable to verify content safety. Please try again."
        case .networkError:
            return "Unable to connect. Please check your internet and try again."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .generationFailed:
            return "Something went wrong. Please try again."
        }
    }

    /// Whether this error should trigger the crisis help modal
    var isCrisis: Bool {
        if case .selfHarmDetected = self { return true }
        return false
    }

    /// Whether this error can be resolved by retrying
    var isRetryable: Bool {
        switch self {
        case .networkError, .rateLimited, .generationFailed, .moderationUnavailable:
            return true
        case .inputEmpty, .inputTooLong, .contentFlagged, .selfHarmDetected:
            return false
        }
    }
}

// MARK: - AI Service Errors

enum AIServiceError: Error, LocalizedError {
    case notConfigured
    case networkError(Error)
    case rateLimited
    case invalidResponse
    case contentFiltered
    case quotaExceeded
    case modelUnavailable
    case moderationUnavailable  // Content safety check unavailable (network/API error)
    case circuitOpen(retryAfter: TimeInterval?)  // Service temporarily unavailable due to repeated failures

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI service is not configured. Please add your API key."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .invalidResponse:
            return "Received an invalid response from the AI service."
        case .contentFiltered:
            return "The request was filtered for safety reasons."
        case .quotaExceeded:
            return "AI usage quota exceeded. Please try again later."
        case .modelUnavailable:
            return "The AI model is currently unavailable."
        case .moderationUnavailable:
            return "Unable to verify content safety. Please try again."
        case .circuitOpen(let retryAfter):
            if let seconds = retryAfter {
                return "Service temporarily unavailable. Please try again in \(Int(seconds)) seconds."
            }
            return "Service temporarily unavailable. Please try again later."
        }
    }
}

// MARK: - Rate Limiter

actor RateLimiter {
    private let maxRequests: Int
    private let timeWindow: TimeInterval
    private var requestTimestamps: [Date] = []

    init(maxRequests: Int, timeWindow: TimeInterval) {
        self.maxRequests = maxRequests
        self.timeWindow = timeWindow
    }

    func checkLimit() async throws {
        let now = Date()
        let windowStart = now.addingTimeInterval(-timeWindow)

        // Remove old timestamps
        requestTimestamps = requestTimestamps.filter { $0 > windowStart }

        // Check if we're at the limit
        if requestTimestamps.count >= maxRequests {
            throw AIServiceError.rateLimited
        }

        // Record this request
        requestTimestamps.append(now)
    }

    func remainingRequests() -> Int {
        let now = Date()
        let windowStart = now.addingTimeInterval(-timeWindow)
        let recentCount = requestTimestamps.filter { $0 > windowStart }.count
        return max(0, maxRequests - recentCount)
    }
}

// MARK: - Chat Message Input/Output

/// Input for sending a chat message
struct ChatMessageInput {
    let question: String
    let conversationHistory: [ChatHistoryMessage]
    let anchoredVerse: VerseRange?
    let anchoredVerseText: String?
    let mode: ChatMode
    let retrievedVerses: [RetrievedVerse]?  // For retrieval-first grounding

    init(
        question: String,
        conversationHistory: [ChatHistoryMessage] = [],
        anchoredVerse: VerseRange? = nil,
        anchoredVerseText: String? = nil,
        mode: ChatMode = .general,
        retrievedVerses: [RetrievedVerse]? = nil
    ) {
        self.question = question
        self.conversationHistory = conversationHistory
        self.anchoredVerse = anchoredVerse
        self.anchoredVerseText = anchoredVerseText
        self.mode = mode
        self.retrievedVerses = retrievedVerses
    }
}

/// A message in the conversation history (for context windowing)
struct ChatHistoryMessage: Codable {
    let role: String  // "user" or "assistant"
    let content: String
}

/// A verse retrieved for grounding (retrieval-first architecture)
struct RetrievedVerse: Codable {
    let reference: String
    let text: String
    let bookId: Int
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int

    func toVerseRange() -> VerseRange {
        VerseRange(bookId: bookId, chapter: chapter, verseStart: verseStart, verseEnd: verseEnd)
    }
}

/// Response type classification for guardrails
enum ResponseType: String, Codable {
    case answer = "answer"                 // In-scope, safe question
    case offTopic = "off_topic"            // Not related to faith/Bible
    case clarification = "clarification"   // Need more details
    case refusalSafety = "refusal_safety"  // Harmful content refused
    case crisisSupport = "crisis_support"  // Self-harm detected
}

// MARK: - Content Moderation

/// Result from OpenAI Moderation API (FREE endpoint)
struct ModerationResult {
    let flagged: Bool
    let selfHarmFlagged: Bool
    let categories: ModerationCategories
}

/// Detailed moderation category flags
struct ModerationCategories {
    let hate: Bool
    let hateThreatening: Bool
    let harassment: Bool
    let harassmentThreatening: Bool
    let selfHarm: Bool
    let selfHarmIntent: Bool
    let selfHarmInstructions: Bool
    let sexual: Bool
    let sexualMinors: Bool
    let violence: Bool
    let violenceGraphic: Bool

    /// Fail-safe state when moderation API is unavailable.
    /// Returns all categories as false (non-flagged) but the overall
    /// ModerationResult.flagged should be set to true to block content.
    static var allClear: ModerationCategories {
        ModerationCategories(
            hate: false,
            hateThreatening: false,
            harassment: false,
            harassmentThreatening: false,
            selfHarm: false,
            selfHarmIntent: false,
            selfHarmInstructions: false,
            sexual: false,
            sexualMinors: false,
            violence: false,
            violenceGraphic: false
        )
    }
}

/// Output from a chat message (structured for trust UX)
struct ChatMessageOutput: Codable {
    let content: String
    let responseType: ResponseType
    let citations: [ChatCitation]?
    let uncertaintyLevel: UncertaintyLevel
    let suggestedFollowUps: [String]?

    // Token usage for cost tracking
    let tokensIn: Int
    let tokensOut: Int
    let modelUsed: String

    /// Sources used to generate this response (for trust UX)
    var groundingSources: [String] {
        var sources: [String] = []
        if let citations = citations, !citations.isEmpty {
            sources.append("Scripture passages (\(citations.count) cited)")
        }
        sources.append("Biblical scholarship")
        return sources
    }
}

/// A citation in a chat response
struct ChatCitation: Codable, Identifiable {
    let id: String
    let reference: String
    let bookId: Int
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int
    let relevance: String?  // Brief explanation of why this verse is relevant

    init(
        id: String = UUID().uuidString,
        reference: String,
        bookId: Int,
        chapter: Int,
        verseStart: Int,
        verseEnd: Int,
        relevance: String? = nil
    ) {
        self.id = id
        self.reference = reference
        self.bookId = bookId
        self.chapter = chapter
        self.verseStart = verseStart
        self.verseEnd = verseEnd
        self.relevance = relevance
    }

    func toVerseRange() -> VerseRange {
        VerseRange(bookId: bookId, chapter: chapter, verseStart: verseStart, verseEnd: verseEnd)
    }
}

/// Uncertainty level for trust UX indicators
enum UncertaintyLevel: String, Codable {
    case low        // Clear, well-established interpretation
    case medium     // Some scholarly debate exists
    case high       // Significant interpretive disagreement

    var displayText: String {
        switch self {
        case .low: return "Well-established"
        case .medium: return "Interpretations vary"
        case .high: return "Significant debate exists"
        }
    }

    var shouldShowIndicator: Bool {
        self != .low
    }
}

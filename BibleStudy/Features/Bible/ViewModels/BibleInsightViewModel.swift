import SwiftUI

// MARK: - Bible Insight Tab
// Tab options for insight sheet navigation

enum BibleInsightTab: String, CaseIterable {
    case insight    // Merged: Explain + Understand + Interpretation (with mode selector)
    case context    // Merged: Context + Cross-refs
    case compare    // Unchanged: Translation comparison
    case language   // Promoted: Hebrew/Greek analysis (high engagement value)

    var title: String {
        switch self {
        case .insight: return "Insight"
        case .context: return "Context"
        case .compare: return "Compare"
        case .language: return "Language"
        }
    }

    var icon: String {
        switch self {
        case .insight: return "sparkles"
        case .context: return "text.alignleft"
        case .compare: return "doc.on.doc"
        case .language: return "character.book.closed"
        }
    }

    /// All tabs are now primary - no more hidden "Advanced" section
    static var allTabs: [BibleInsightTab] {
        [.insight, .context, .compare, .language]
    }
}

// MARK: - Bible Insight Mode
// Sub-modes within Insight tab

enum BibleInsightMode: String, CaseIterable {
    case explain        // AI explanation with summary, key points
    case understand     // Reading comprehension tools
    case views          // Different interpretations/perspectives

    var title: String {
        switch self {
        case .explain: return "Explain"
        case .understand: return "Understand"
        case .views: return "Views"
        }
    }
}

// MARK: - Bible Insight View Model
// Manages state for the Insight Sheet

private let analytics = AnalyticsService.shared

@Observable
@MainActor
final class BibleInsightViewModel {
    // MARK: - Dependencies
    private let crossRefService = CrossRefService.shared
    private let languageService = LanguageService.shared
    private let bibleService = BibleService.shared
    private let aiService: AIServiceProtocol = OpenAIProvider.shared
    private let aiCache = AIResponseCache.shared
    private let entitlementManager = EntitlementService.shared

    // MARK: - Properties
    let verseRange: VerseRange
    private(set) var verseText: String = ""

    // Loading States
    var isLoadingExplain: Bool = false
    var isLoadingContext: Bool = false
    var isLoadingCrossRefs: Bool = false
    var isLoadingLanguage: Bool = false
    var isLoadingInterpretation: Bool = false
    var isLoadingComprehension: Bool = false  // Phase 5

    // Content
    var explanation: String?
    var structuredExplanation: StructuredExplanation?  // Parsed structured format
    var explanationReasoning: [ReasoningPoint]?
    var explanationTranslationNotes: [TranslationNote]?
    var explanationGroundingSources: [String] = []
    var contextInfo: ContextInfo?
    var crossRefs: [CrossReferenceDisplay] = []
    var languageTokens: [LanguageTokenDisplay] = []
    var interpretation: InterpretationResult?

    // Phase 5: Comprehension
    var passageSummary: PassageSummaryOutput?

    // Errors
    var error: Error?
    var errorMessage: String?

    // AI availability
    var isAIAvailable: Bool {
        aiService.isAvailable
    }

    // MARK: - Limit Reached State

    /// Returns true when user has hit their daily AI insight limit.
    /// When limit is reached, no AI content is shown (including cached content).
    /// The UI displays an upgrade prompt instead.
    var isLimitReached: Bool {
        !entitlementManager.canUseAIInsights
    }

    // MARK: - Initialization
    init(verseRange: VerseRange) {
        self.verseRange = verseRange
        Task {
            await loadVerseText()
        }
    }

    // MARK: - Load Verse Text
    private func loadVerseText() async {
        do {
            let verses = try await bibleService.getVerses(range: verseRange)
            verseText = verses.map { $0.text }.joined(separator: " ")
        } catch {
            print("Failed to load verse text: \(error)")
        }
    }

    // MARK: - Consolidated Tab Loading (4-tab structure)
    // Used by the new consolidated InsightSheetView
    func loadContentForConsolidatedTab(_ tab: BibleInsightTab) async {
        switch tab {
        case .insight:
            // Insight tab auto-loads explanation by default (mode selector handles other modes)
            if explanation == nil {
                await loadExplanation()
            }
        case .context:
            // Context tab loads both context info and cross-refs in parallel
            async let contextTask: () = loadContextIfNeeded()
            async let crossRefsTask: () = loadCrossRefsIfNeeded()
            _ = await (contextTask, crossRefsTask)
        case .compare:
            // Compare tab handles its own loading via TranslationComparisonView
            break
        case .language:
            if languageTokens.isEmpty {
                await loadLanguageTokens()
            }
        }
    }

    private func loadContextIfNeeded() async {
        if contextInfo == nil {
            await loadContext()
        }
    }

    private func loadCrossRefsIfNeeded() async {
        if crossRefs.isEmpty {
            await loadCrossRefs()
        }
    }

    // MARK: - Explain
    func loadExplanation(forceRefresh: Bool = false) async {
        // Skip if we already have content and not forcing refresh
        if !forceRefresh && explanation != nil {
            return
        }

        isLoadingExplain = true
        error = nil
        errorMessage = nil

        // Ensure we have verse text
        if verseText.isEmpty {
            await loadVerseText()
        }

        let translationId = bibleService.currentTranslationId
        let currentTranslation = bibleService.currentTranslation

        // Check if user can use AI insights FIRST (before cache)
        // When limit is reached, we show the limit reached UI instead of any content
        guard entitlementManager.canUseAIInsights else {
            // User at limit - don't show cached content, show limit reached UI
            // Note: isLimitReached computed property will return true
            isLoadingExplain = false
            return
        }

        // User has quota - check cache to avoid unnecessary API calls
        if let cached = aiCache.getExplanation(for: verseRange, translationId: translationId, mode: ExplanationMode.plain) {
            explanation = cached.explanation
            structuredExplanation = StructuredExplanation.parse(cached.explanation, keyPoints: cached.keyPoints)
            explanationReasoning = cached.reasoning
            explanationTranslationNotes = cached.translationNotes
            explanationGroundingSources = cached.groundingSources
            isLoadingExplain = false
            return
        }

        // No cache available - need to make API call

        // Check if AI is available
        guard aiService.isAvailable else {
            // Fall back to sample response when API key not configured
            setSampleExplanation()
            isLoadingExplain = false
            return
        }

        // Record usage (will trigger paywall if this was the last allowed use)
        guard entitlementManager.recordAIInsightUsage() else {
            // User just hit limit - paywall will be shown
            // Don't set sample data, let isLimitReached handle UI
            isLoadingExplain = false
            return
        }

        do {
            let input = ExplanationInput(
                verseRange: verseRange,
                verseText: verseText,
                surroundingContext: nil,
                mode: .plain,
                translation: currentTranslation?.abbreviation ?? "KJV"
            )

            let output = try await aiService.generateExplanation(input: input)
            explanation = output.explanation
            structuredExplanation = StructuredExplanation.parse(output.explanation, keyPoints: output.keyPoints)
            explanationReasoning = output.reasoning
            explanationTranslationNotes = output.translationNotes
            explanationGroundingSources = output.groundingSources

            // Cache the result
            aiCache.cacheExplanation(output, for: verseRange, translationId: translationId, mode: ExplanationMode.plain)

            // Track insight viewed
            analytics.trackInsightViewed(reference: verseRange.reference, type: "explanation")
        } catch let aiError as AIServiceError {
            self.error = aiError
            self.errorMessage = aiError.errorDescription
            // Fall back to sample on error
            setSampleExplanation()
        } catch {
            self.error = error
            self.errorMessage = error.localizedDescription
            setSampleExplanation()
        }

        isLoadingExplain = false
    }

    private func setSampleExplanation() {
        let sampleText = """
        This passage describes the foundational moment of creation where God speaks light into existence. \
        The Hebrew phrase "יְהִי אוֹר" (yehi 'or) uses the jussive form, expressing a divine command or decree.

        **Key observations:**
        • The creation of light precedes the creation of the sun (verse 14), suggesting this is divine light or the light of God's presence.
        • The pattern of "God said... and it was so" establishes God's word as the means of creation.
        • The separation of light from darkness establishes the first boundary in creation.

        This verse connects thematically to John 1:4-5, where Jesus is described as "the light of men" that "shines in the darkness."

        *(Sample explanation - configure API key for live AI responses)*
        """
        explanation = sampleText
        structuredExplanation = StructuredExplanation.parse(sampleText)

        explanationReasoning = [
            ReasoningPoint(
                phrase: "יְהִי אוֹר (yehi 'or)",
                explanation: "The jussive form indicates a divine command, showing God's word has creative power."
            ),
            ReasoningPoint(
                phrase: "and there was light",
                explanation: "Immediate fulfillment demonstrates the effectiveness of God's spoken word."
            )
        ]

        explanationTranslationNotes = [
            TranslationNote(
                phrase: "Let there be light",
                translations: ["KJV: Let there be light", "ESV: Let there be light", "NIV: Let there be light"],
                explanation: "Most translations agree on this phrase. The Hebrew 'yehi' is a jussive form expressing divine command."
            )
        ]

        explanationGroundingSources = ["Selected passage text", "Original language lexicon", "Translation comparison"]
    }

    // MARK: - Context
    func loadContext() async {
        isLoadingContext = true
        error = nil

        do {
            // Get verses before the selected range
            let beforeRange = VerseRange(
                bookId: verseRange.bookId,
                chapter: verseRange.chapter,
                verseStart: max(1, verseRange.verseStart - 2),
                verseEnd: max(1, verseRange.verseStart - 1)
            )

            // Get verses after the selected range
            let afterRange = VerseRange(
                bookId: verseRange.bookId,
                chapter: verseRange.chapter,
                verseStart: verseRange.verseEnd + 1,
                verseEnd: verseRange.verseEnd + 2
            )

            let beforeVerses = try await bibleService.getVerses(range: beforeRange)
            let afterVerses = try await bibleService.getVerses(range: afterRange)

            let beforeText = beforeVerses.isEmpty
                ? "(Beginning of chapter)"
                : beforeVerses.map { "v.\($0.verse): \($0.text)" }.joined(separator: " ")

            let afterText = afterVerses.isEmpty
                ? "(End of chapter)"
                : afterVerses.map { "v.\($0.verse): \($0.text)" }.joined(separator: " ")

            contextInfo = ContextInfo(
                before: beforeText,
                after: afterText,
                keyPeople: nil,
                keyPlaces: nil
            )
        } catch {
            // Fall back to sample context
            contextInfo = ContextInfo(
                before: "(Unable to load preceding verses)",
                after: "(Unable to load following verses)",
                keyPeople: nil,
                keyPlaces: nil
            )
        }

        isLoadingContext = false
    }

    // MARK: - Cross References
    func loadCrossRefs() async {
        isLoadingCrossRefs = true
        error = nil

        var outgoingRefs: [CrossReferenceDisplay] = []
        var incomingRefs: [CrossReferenceDisplay] = []

        do {
            // Load outgoing cross-references (this verse references others)
            let refs = try await crossRefService.getCrossReferencesWithText(for: verseRange)
            outgoingRefs = refs.map { ref in
                CrossReferenceDisplay(
                    id: "out-\(ref.crossRef.id)",
                    reference: ref.targetReference,
                    preview: ref.targetText ?? "",
                    weight: ref.crossRef.weight,
                    whyLinked: ref.explanation,
                    targetRange: ref.targetRange,
                    isIncoming: false
                )
            }

            // Load incoming cross-references (other verses reference this)
            let incoming = try crossRefService.getIncomingCrossReferences(for: verseRange)
            for inRef in incoming {
                // Fetch source verse text
                var sourceText = ""
                if let verses = try? await bibleService.getVerses(range: inRef.sourceRange) {
                    sourceText = verses.map { $0.text }.joined(separator: " ")
                }
                incomingRefs.append(CrossReferenceDisplay(
                    id: "in-\(inRef.id)",
                    reference: inRef.sourceRange.reference,
                    preview: sourceText,
                    weight: inRef.weight,
                    whyLinked: nil,
                    targetRange: inRef.sourceRange,
                    isIncoming: true
                ))
            }
        } catch {
            print("Failed to load cross-refs from database: \(error)")
            // Fall back to sample data
            let refs = crossRefService.getSampleCrossReferences(for: verseRange)
            outgoingRefs = refs.map { ref in
                CrossReferenceDisplay(
                    id: "out-\(ref.crossRef.id)",
                    reference: ref.targetReference,
                    preview: ref.targetText ?? "",
                    weight: ref.crossRef.weight,
                    whyLinked: ref.explanation,
                    targetRange: ref.targetRange,
                    isIncoming: false
                )
            }
        }

        // Combine outgoing and incoming, with outgoing first
        crossRefs = outgoingRefs + incomingRefs

        // If still no cross-refs found, provide default samples
        if crossRefs.isEmpty {
            crossRefs = [
                CrossReferenceDisplay(
                    id: "1",
                    reference: "John 1:4-5",
                    preview: "In him was life; and the life was the light of men.",
                    weight: 0.95,
                    whyLinked: nil,
                    targetRange: VerseRange(bookId: 43, chapter: 1, verseStart: 4, verseEnd: 5),
                    isIncoming: false
                ),
                CrossReferenceDisplay(
                    id: "2",
                    reference: "2 Corinthians 4:6",
                    preview: "For God, who commanded the light to shine out of darkness...",
                    weight: 0.88,
                    whyLinked: nil,
                    targetRange: VerseRange(bookId: 47, chapter: 4, verseStart: 6, verseEnd: 6),
                    isIncoming: false
                )
            ]
        }

        isLoadingCrossRefs = false
    }

    // MARK: - Language
    func loadLanguageTokens() async {
        isLoadingLanguage = true
        error = nil

        var tokens: [LanguageToken] = []

        do {
            // Try to load from database first
            tokens = try languageService.getTokens(for: verseRange)
        } catch {
            print("Failed to load language tokens from database: \(error)")
            // Fall back to sample data
            tokens = languageService.getSampleTokens(for: verseRange)
        }

        // Convert to display tokens with plain English morphology
        languageTokens = tokens.map { LanguageTokenDisplay(from: $0) }

        // If no tokens found, provide default samples with plain English morphology
        if languageTokens.isEmpty {
            languageTokens = [
                LanguageTokenDisplay(
                    id: "1",
                    surface: "יְהִי",
                    transliteration: "yehi",
                    lemma: "הָיָה",
                    gloss: "let there be",
                    morph: "V-Qal-Jussive-3ms",
                    language: "hebrew",
                    strongsNumber: "H1961",
                    partOfSpeech: "Verb",
                    plainEnglishMorph: "Command form ('let it be'), third person singular",
                    grammaticalSignificance: "Expresses a divine command—something that should happen."
                ),
                LanguageTokenDisplay(
                    id: "2",
                    surface: "אוֹר",
                    transliteration: "'or",
                    lemma: "אוֹר",
                    gloss: "light",
                    morph: "N-ms",
                    language: "hebrew",
                    strongsNumber: "H216",
                    partOfSpeech: "Noun",
                    plainEnglishMorph: "A masculine, singular noun",
                    grammaticalSignificance: "Names the thing being created."
                )
            ]
        }

        isLoadingLanguage = false
    }

    // MARK: - Term Explanation

    /// Generate AI-powered contextual explanation for a language token
    func explainTermInContext(token: LanguageTokenDisplay) async -> String {
        // Check if AI is available
        guard aiService.isAvailable else {
            return generateSampleTermExplanation(token: token)
        }

        // Check entitlement (will trigger paywall if limit reached)
        guard entitlementManager.recordAIInsightUsage() else {
            return generateSampleTermExplanation(token: token)
        }

        do {
            let explanation = try await aiService.generateTermExplanation(
                lemma: token.lemma,
                morph: token.morph,
                verseContext: verseText
            )
            return explanation
        } catch {
            print("Failed to generate term explanation: \(error)")
            return generateSampleTermExplanation(token: token)
        }
    }

    /// Generate a sample explanation when AI is unavailable
    private func generateSampleTermExplanation(token: LanguageTokenDisplay) -> String {
        let languageName = token.language == "hebrew" ? "Hebrew" : "Greek"

        var explanation = "The \(languageName) word \"\(token.surface)\" (\(token.transliteration)) means \"\(token.gloss)\" in this context."

        if !token.plainEnglishMorph.isEmpty {
            explanation += " Grammatically, it is \(token.plainEnglishMorph.lowercased())."
        }

        if !token.grammaticalSignificance.isEmpty {
            explanation += " \(token.grammaticalSignificance)"
        }

        explanation += "\n\n*(Sample explanation—configure API key for AI-powered analysis)*"

        return explanation
    }

    // MARK: - Interpretation
    func loadInterpretation() async {
        isLoadingInterpretation = true
        error = nil
        errorMessage = nil

        // Ensure we have verse text
        if verseText.isEmpty {
            await loadVerseText()
        }

        let translationId = bibleService.currentTranslationId
        let currentTranslation = bibleService.currentTranslation

        // Check cache first
        if let cached = aiCache.getInterpretation(for: verseRange, translationId: translationId, mode: InterpretationViewMode.plain) {
            interpretation = convertToInterpretationResult(cached)
            isLoadingInterpretation = false
            return
        }

        // Check if AI is available
        guard aiService.isAvailable else {
            // Fall back to sample response when API key not configured
            interpretation = getSampleInterpretation()
            isLoadingInterpretation = false
            return
        }

        // Check entitlement (will trigger paywall if limit reached)
        guard entitlementManager.recordAIInsightUsage() else {
            interpretation = getSampleInterpretation()
            isLoadingInterpretation = false
            return
        }

        do {
            let input = InterpretationInput(
                verseRange: verseRange,
                verseText: verseText,
                surroundingContext: nil,
                mode: .plain,
                includeReflection: true,
                translation: currentTranslation?.abbreviation ?? "KJV"
            )

            let output = try await aiService.generateInterpretation(input: input)

            interpretation = convertToInterpretationResult(output)

            // Cache the result
            aiCache.cacheInterpretation(output, for: verseRange, translationId: translationId, mode: InterpretationViewMode.plain)

            // Track insight viewed
            analytics.trackInsightViewed(reference: verseRange.reference, type: "interpretation")
        } catch let aiError as AIServiceError {
            self.error = aiError
            self.errorMessage = aiError.errorDescription
            interpretation = getSampleInterpretation()
        } catch {
            self.error = error
            self.errorMessage = error.localizedDescription
            interpretation = getSampleInterpretation()
        }

        isLoadingInterpretation = false
    }

    private func convertToInterpretationResult(_ output: InterpretationOutput) -> InterpretationResult {
        InterpretationResult(
            plainMeaning: output.plainMeaning,
            context: output.context,
            keyTerms: output.keyTerms,
            crossRefs: output.crossReferences,
            interpretationNotes: output.interpretationNotes,
            reflectionPrompt: output.reflectionPrompt,
            hasUncertainty: output.hasDebatedInterpretations,
            reasoning: output.reasoning,
            alternativeViews: output.alternativeViews
        )
    }

    private func getSampleInterpretation() -> InterpretationResult {
        InterpretationResult(
            plainMeaning: "God spoke and light came into existence, demonstrating His power over creation.",
            context: "This is the first of God's creative acts in Genesis, establishing the pattern of divine speech bringing about reality.",
            keyTerms: ["Light (אוֹר)", "Let there be (יְהִי)"],
            crossRefs: ["John 1:4-5", "2 Cor 4:6", "Isa 45:7"],
            interpretationNotes: "Interpretations vary on whether this 'light' is the same as sunlight (created in v.14) or represents divine/spiritual light. Some scholars see this as cosmic light, others as the light of God's presence.\n\n*(Sample interpretation - configure API key for live AI responses)*",
            reflectionPrompt: "How does the image of God speaking light into darkness speak to your own experience of God's work in your life?",
            hasUncertainty: true,
            reasoning: [
                ReasoningPoint(
                    phrase: "Let there be light",
                    explanation: "The jussive form (יְהִי) indicates divine command, not a wish. God's word has creative power."
                ),
                ReasoningPoint(
                    phrase: "and there was light",
                    explanation: "Immediate fulfillment shows the effectiveness of God's word - creation responds instantly to divine speech."
                )
            ],
            alternativeViews: [
                AlternativeView(
                    viewName: "Cosmic Light View",
                    summary: "This light is distinct from sunlight (created on Day 4), representing a primordial cosmic light or divine radiance.",
                    traditions: ["Many Church Fathers", "Some modern commentators"]
                ),
                AlternativeView(
                    viewName: "Functional Light View",
                    summary: "The sun existed but began 'functioning' as a light-bearer on Day 4. Day 1 describes light as a phenomenon.",
                    traditions: ["Some evangelical scholars"]
                )
            ]
        )
    }

    // MARK: - Comprehension (Phase 5)

    func loadPassageSummary() async {
        isLoadingComprehension = true
        error = nil

        // Ensure we have verse text
        if verseText.isEmpty {
            await loadVerseText()
        }

        // Check if AI is available
        guard aiService.isAvailable else {
            // Fall back to sample response
            passageSummary = PassageSummaryOutput(
                summary: "This passage describes God's first act of creation—speaking light into existence.",
                theme: "Creation",
                whatHappened: "God commanded light to appear, and it did. *(Sample—configure API key for live AI)*"
            )
            isLoadingComprehension = false
            return
        }

        // Check entitlement (will trigger paywall if limit reached)
        guard entitlementManager.recordAIInsightUsage() else {
            passageSummary = PassageSummaryOutput(
                summary: "This passage describes God's first act of creation—speaking light into existence.",
                theme: "Creation",
                whatHappened: "God commanded light to appear, and it did. *(Upgrade to Premium for unlimited AI insights)*"
            )
            isLoadingComprehension = false
            return
        }

        do {
            passageSummary = try await aiService.summarizePassage(
                verseRange: verseRange,
                verseText: verseText
            )
        } catch {
            self.error = error
            // Provide fallback on error
            passageSummary = PassageSummaryOutput(
                summary: "Unable to generate summary. Please try again.",
                theme: "—",
                whatHappened: nil
            )
        }

        isLoadingComprehension = false
    }

    // MARK: - Why Linked
    func loadWhyLinked(for crossRef: CrossReferenceDisplay) async -> String {
        // Check if AI is available
        guard aiService.isAvailable else {
            return "Both passages share thematic connections. *(Configure API key for AI-powered analysis)*"
        }

        // Check entitlement (will trigger paywall if limit reached)
        guard entitlementManager.recordAIInsightUsage() else {
            return "Both passages share thematic connections. *(Upgrade to Premium for unlimited AI insights)*"
        }

        // Parse the target reference to create a VerseRange
        // For now, use a simple approach - in production, use a proper reference parser
        let targetRange = VerseRange(
            bookId: 43, // Default to John for demo
            chapter: 1,
            verseStart: 4,
            verseEnd: 5
        )

        do {
            let result = try await aiService.generateWhyLinked(
                source: verseRange,
                target: targetRange,
                context: verseText
            )
            return result
        } catch {
            return "Both passages share thematic connections. *(Unable to load AI analysis)*"
        }
    }
}

// MARK: - Supporting Types

struct ContextInfo {
    let before: String
    let after: String
    let keyPeople: [String]?
    let keyPlaces: [String]?
}

struct CrossReferenceDisplay: Identifiable {
    let id: String
    let reference: String
    let preview: String
    let weight: Double
    var whyLinked: String?
    var targetRange: VerseRange?
    var isIncoming: Bool = false  // True if this references the current verse
}

struct LanguageTokenDisplay: Identifiable {
    let id: String
    let surface: String
    let transliteration: String
    let lemma: String
    let gloss: String
    let morph: String              // Technical morphology code
    let language: String
    let strongsNumber: String?     // Strong's concordance number (H1234 or G5678)

    // Plain English morphology (Phase 3 enhancement)
    let partOfSpeech: String           // "Verb", "Noun", etc.
    let plainEnglishMorph: String      // "Completed action, third person singular"
    let grammaticalSignificance: String // "The action is viewed as complete."

    /// Creates a display token with plain English morphology from a LanguageToken
    init(from token: LanguageToken) {
        self.id = String(token.id)
        self.surface = token.surface
        self.transliteration = PlainEnglishMorphology.transliterate(token.surface, language: token.language)
        self.lemma = token.lemma ?? token.surface
        self.gloss = token.gloss ?? ""
        self.morph = token.morphDescription ?? token.morph ?? ""
        self.language = token.language.rawValue
        self.strongsNumber = token.strongId

        // Generate plain English morphology
        let morphDesc = PlainEnglishMorphology.describe(token.morph ?? "", language: token.language)
        self.partOfSpeech = morphDesc.partOfSpeech
        self.plainEnglishMorph = morphDesc.plainDescription
        self.grammaticalSignificance = morphDesc.grammaticalSignificance
    }

    /// Manual initializer for backward compatibility and previews
    init(
        id: String,
        surface: String,
        transliteration: String,
        lemma: String,
        gloss: String,
        morph: String,
        language: String,
        strongsNumber: String? = nil,
        partOfSpeech: String = "",
        plainEnglishMorph: String = "",
        grammaticalSignificance: String = ""
    ) {
        self.id = id
        self.surface = surface
        self.transliteration = transliteration
        self.lemma = lemma
        self.gloss = gloss
        self.morph = morph
        self.language = language
        self.strongsNumber = strongsNumber
        self.partOfSpeech = partOfSpeech
        self.plainEnglishMorph = plainEnglishMorph
        self.grammaticalSignificance = grammaticalSignificance
    }
}

struct InterpretationResult {
    let plainMeaning: String
    let context: String
    let keyTerms: [String]
    let crossRefs: [String]
    let interpretationNotes: String
    let reflectionPrompt: String?
    let hasUncertainty: Bool

    // Trust UX fields
    let reasoning: [ReasoningPoint]?
    let alternativeViews: [AlternativeView]?

    /// Sources used to generate this interpretation (for trust UX)
    var groundingSources: [String] {
        var sources: [String] = ["Selected passage text"]
        if !keyTerms.isEmpty { sources.append("Original language lexicon") }
        if !crossRefs.isEmpty { sources.append("Cross-reference database") }
        if hasUncertainty { sources.append("Scholarly commentary traditions") }
        return sources
    }
}

// MARK: - Structured Explanation
// Parsed format for better scannability

struct StructuredExplanation {
    let summary: String           // 1-2 sentence overview
    let keyPoints: [String]       // Bullet points
    let details: String?          // Extended explanation (shown on expand)
    let hasMoreContent: Bool      // Whether there's content beyond summary + key points

    /// Parse raw explanation text into structured format
    /// - Parameters:
    ///   - text: The explanation text to parse
    ///   - keyPoints: Optional pre-extracted key points from JSON response
    static func parse(_ text: String, keyPoints: [String]? = nil) -> StructuredExplanation {
        let lines = text.components(separatedBy: "\n")
        var summary = ""
        var extractedKeyPoints: [String] = keyPoints ?? []
        var details = ""
        var inKeyPoints = false
        var afterKeyPoints = false

        // Only parse for bullet points if we don't already have them from JSON
        if extractedKeyPoints.isEmpty {
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                // Detect key points section header
                if trimmed.lowercased().contains("key observation") ||
                   trimmed.lowercased().contains("key point") ||
                   trimmed.lowercased().contains("**key") {
                    inKeyPoints = true
                    continue
                }

                // Detect bullet points
                if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") || trimmed.hasPrefix("*") {
                    if inKeyPoints || extractedKeyPoints.isEmpty {
                        inKeyPoints = true
                        // Clean up the bullet point
                        var point = trimmed
                        point.removeFirst()
                        point = point.trimmingCharacters(in: .whitespaces)
                        if !point.isEmpty {
                            extractedKeyPoints.append(point)
                        }
                    } else {
                        details += line + "\n"
                    }
                    continue
                }

                // Empty line after key points signals end of that section
                if inKeyPoints && trimmed.isEmpty {
                    inKeyPoints = false
                    afterKeyPoints = true
                    continue
                }

                // Non-bullet content
                if inKeyPoints {
                    // Still in key points but not a bullet - end section
                    inKeyPoints = false
                    afterKeyPoints = true
                    details += line + "\n"
                } else if afterKeyPoints || !extractedKeyPoints.isEmpty {
                    // After key points - goes to details
                    details += line + "\n"
                } else if summary.isEmpty && !trimmed.isEmpty {
                    // First paragraph is summary
                    summary = trimmed
                } else if !trimmed.isEmpty && !summary.isEmpty {
                    // Second paragraph before key points - add to summary or start details
                    if summary.count < 200 && !trimmed.hasPrefix("**") {
                        summary += " " + trimmed
                    } else {
                        details += line + "\n"
                    }
                }
            }
        } else {
            // We have keyPoints from JSON, just extract summary and details
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                if summary.isEmpty && !trimmed.isEmpty {
                    summary = trimmed
                } else if !trimmed.isEmpty {
                    if summary.count < 200 {
                        summary += " " + trimmed
                    } else {
                        details += line + "\n"
                    }
                }
            }
        }

        // Clean up details
        details = details.trimmingCharacters(in: .whitespacesAndNewlines)

        // If no key points found, try to extract from the summary
        if extractedKeyPoints.isEmpty && summary.count > 150 {
            // Long summary with no key points - keep as is but note it
        }

        // If no summary, use first key point or first sentence
        if summary.isEmpty {
            if let firstPoint = extractedKeyPoints.first {
                summary = firstPoint
                extractedKeyPoints.removeFirst()
            } else {
                // Take first sentence from details
                let sentences = text.components(separatedBy: ". ")
                if let first = sentences.first {
                    summary = first + (first.hasSuffix(".") ? "" : ".")
                }
            }
        }

        let hasMore = !details.isEmpty || extractedKeyPoints.count > 3

        return StructuredExplanation(
            summary: summary,
            keyPoints: Array(extractedKeyPoints.prefix(5)), // Limit to 5 key points
            details: details.isEmpty ? nil : details,
            hasMoreContent: hasMore
        )
    }
}

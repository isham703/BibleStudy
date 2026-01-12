import Foundation
import GRDB

// MARK: - Cross-Reference Background Provider Protocol
// Protocol for background cross-reference operations (nonisolated)

protocol CrossRefBackgroundProviding: Sendable {
    /// Get outgoing cross-references for a verse range (background-safe)
    nonisolated func getOutgoingCrossRefsBackground(for range: VerseRange) throws -> [CrossReference]

    /// Build verification index from cross-reference database
    nonisolated func buildVerificationIndex(
        for sourceRanges: [VerseRange]
    ) throws -> (outgoing: [String: Set<String>], incoming: [String: Set<String>])
}

// MARK: - Default Implementation (Direct Database Access)

/// Provides background cross-ref operations without MainActor dependency
/// Uses DatabaseManager directly since GRDB handles thread safety internally
struct CrossRefBackgroundProvider: CrossRefBackgroundProviding, Sendable {
    // nonisolated(unsafe) allows use as default parameter in nonisolated init
    nonisolated(unsafe) static let shared = CrossRefBackgroundProvider()

    private init() {}

    nonisolated func getOutgoingCrossRefsBackground(for range: VerseRange) throws -> [CrossReference] {
        guard let dbQueue = DatabaseManager.backgroundDBQueue else {
            throw DatabaseError.notInitialized
        }

        return try dbQueue.read { db in
            try CrossReference
                .filter(CrossReference.Columns.sourceBookId == range.bookId)
                .filter(CrossReference.Columns.sourceChapter == range.chapter)
                .filter(CrossReference.Columns.sourceVerseStart <= range.verseEnd)
                .filter(CrossReference.Columns.sourceVerseEnd >= range.verseStart)
                .order(CrossReference.Columns.weight.desc)
                .fetchAll(db)
        }
    }

    nonisolated func buildVerificationIndex(
        for sourceRanges: [VerseRange]
    ) throws -> (outgoing: [String: Set<String>], incoming: [String: Set<String>]) {
        guard let dbQueue = DatabaseManager.backgroundDBQueue else {
            throw DatabaseError.notInitialized
        }

        var outgoingMap: [String: Set<String>] = [:]
        var incomingMap: [String: Set<String>] = [:]

        for range in sourceRanges {
            let sourceId = ReferenceParser.canonicalId(
                bookId: range.bookId,
                chapter: range.chapter,
                verseStart: range.verseStart,
                verseEnd: range.verseEnd
            )

            // Get outgoing cross-refs (source → targets)
            let outgoing = try dbQueue.read { db in
                try CrossReference
                    .filter(CrossReference.Columns.sourceBookId == range.bookId)
                    .filter(CrossReference.Columns.sourceChapter == range.chapter)
                    .filter(CrossReference.Columns.sourceVerseStart <= range.verseEnd)
                    .filter(CrossReference.Columns.sourceVerseEnd >= range.verseStart)
                    .fetchAll(db)
            }

            for crossRef in outgoing {
                let targetId = ReferenceParser.canonicalId(
                    bookId: crossRef.targetBookId,
                    chapter: crossRef.targetChapter,
                    verseStart: crossRef.targetVerseStart,
                    verseEnd: crossRef.targetVerseEnd
                )
                outgoingMap[sourceId, default: []].insert(targetId)
                incomingMap[targetId, default: []].insert(sourceId)
            }
        }

        return (outgoingMap, incomingMap)
    }
}

// MARK: - Sermon Enrichment Service
// Handles pre-AI context building and post-AI classification/enrichment
// for sermon study guide Bible reference verification

actor SermonEnrichmentService {
    // MARK: - Dependencies

    private let crossRefProvider: CrossRefBackgroundProviding
    private let insightProvider: any InsightProviding

    // MARK: - Configuration

    struct ContextConfig: Sendable {
        let maxExplicitRefs: Int
        let maxCrossRefsPerRef: Int
        let maxGlobalCrossRefs: Int
        let maxInsightsPerRef: Int
        let maxPromptContextChars: Int

        static let `default` = ContextConfig(
            maxExplicitRefs: 10,
            maxCrossRefsPerRef: 5,
            maxGlobalCrossRefs: 30,
            maxInsightsPerRef: 2,
            maxPromptContextChars: 2000
        )
    }

    // MARK: - Initialization

    init(
        crossRefProvider: CrossRefBackgroundProviding = CrossRefBackgroundProvider.shared,
        insightProvider: any InsightProviding = NullInsightProvider.shared
    ) {
        self.crossRefProvider = crossRefProvider
        self.insightProvider = insightProvider
    }

    // MARK: - Parse and Validate References

    /// Parse reference strings into validated VerseRanges
    /// - Parameter refs: Array of reference strings (e.g., "John 3:16", "Romans 8:28-30")
    /// - Returns: Array of successfully parsed VerseRanges
    nonisolated func parseAndValidateReferences(_ refs: [String]) -> [VerseRange] {
        refs.compactMap { ref -> VerseRange? in
            switch ReferenceParser.parseFlexible(ref) {
            case .success(let parsed):
                return VerseRange(
                    bookId: parsed.book.id,
                    chapter: parsed.chapter,
                    verseStart: parsed.verseStart ?? 1,
                    verseEnd: parsed.verseEnd ?? parsed.verseStart ?? 1
                )
            case .failure:
                return nil
            }
        }
    }

    // MARK: - Build Enrichment Context (Pre-AI)

    /// Build enrichment context for AI prompt and post-AI verification
    /// - Parameters:
    ///   - sourceRanges: Verse ranges mentioned in the sermon
    ///   - config: Context configuration with caps
    /// - Returns: Enrichment context with prompt text and verification index
    func buildEnrichmentContext(
        for sourceRanges: [VerseRange],
        config: ContextConfig = .default
    ) async throws -> SermonEnrichmentContext {
        // Cap the number of refs to process
        let cappedRanges = Array(sourceRanges.prefix(config.maxExplicitRefs))

        // Build verification index (full set, not capped)
        let verificationIndex = try buildVerificationIndex(for: cappedRanges)

        // Build prompt context (capped for token budget)
        let promptContext = try await buildPromptContext(
            for: cappedRanges,
            config: config
        )

        return SermonEnrichmentContext(
            promptContext: promptContext,
            verificationIndex: verificationIndex
        )
    }

    // MARK: - Build Verification Index

    /// Build verification index from cross-reference database
    /// - Parameter sourceRanges: Verse ranges mentioned in the sermon
    /// - Returns: VerificationIndex with outgoing and incoming maps
    private func buildVerificationIndex(for sourceRanges: [VerseRange]) throws -> VerificationIndex {
        let (outgoing, incoming) = try crossRefProvider.buildVerificationIndex(for: sourceRanges)

        // Check if we have partial data (sample DB)
        // In production, always full data. In DEBUG, check if cross-refs are sparse.
        let isPartialData: Bool
        #if DEBUG
        // Simple heuristic: if we have fewer than 10 outgoing entries total, likely sample data
        isPartialData = outgoing.values.flatMap { $0 }.count < 10
        #else
        isPartialData = false
        #endif

        return VerificationIndex(
            outgoingMap: outgoing,
            incomingMap: incoming,
            isPartialData: isPartialData
        )
    }

    // MARK: - Build Prompt Context

    /// Build prompt context with capped cross-refs and insights
    private func buildPromptContext(
        for sourceRanges: [VerseRange],
        config: ContextConfig
    ) async throws -> PromptContext {
        var items: [PromptContext.ContextItem] = []
        var totalCrossRefs = 0

        for range in sourceRanges {
            // Get cross-refs (capped per ref and globally)
            let remainingGlobal = config.maxGlobalCrossRefs - totalCrossRefs
            guard remainingGlobal > 0 else { break }

            let crossRefs = try crossRefProvider.getOutgoingCrossRefsBackground(for: range)
            let cappedCrossRefs = Array(crossRefs.prefix(min(config.maxCrossRefsPerRef, remainingGlobal)))
            totalCrossRefs += cappedCrossRefs.count

            // Get insights (titles only, capped)
            let insights = try await insightProvider.getInsightSummaries(
                bookId: range.bookId,
                chapter: range.chapter,
                verseStart: range.verseStart,
                verseEnd: range.verseEnd
            )
            let cappedInsights = Array(insights.prefix(config.maxInsightsPerRef))

            // Build context item
            let enrichedCrossRefs = cappedCrossRefs.map { crossRef in
                EnrichedCrossRef(
                    canonicalId: ReferenceParser.canonicalId(
                        bookId: crossRef.targetBookId,
                        chapter: crossRef.targetChapter,
                        verseStart: crossRef.targetVerseStart,
                        verseEnd: crossRef.targetVerseEnd
                    ),
                    displayRef: crossRef.targetRange.reference,
                    weight: Int(crossRef.weight * 100)
                )
            }

            let enrichedInsights = cappedInsights.map { insight in
                EnrichedInsight(
                    id: insight.id,
                    title: insight.title,
                    type: insight.insightType
                )
            }

            items.append(PromptContext.ContextItem(
                sourceRange: range,
                crossRefs: enrichedCrossRefs,
                insights: enrichedInsights
            ))
        }

        return PromptContext(items: items, maxChars: config.maxPromptContextChars)
    }

    // MARK: - Classify and Enrich References (Post-AI)

    /// Classify and enrich references after AI generation
    /// - Parameters:
    ///   - refs: References from AI output
    ///   - context: Enrichment context built pre-AI
    ///   - classification: Whether these are mentioned or suggested refs
    /// - Returns: Enriched references with verification status
    nonisolated func classifyAndEnrich(
        _ refs: [SermonVerseReference],
        context: SermonEnrichmentContext?,
        classification: RefClassification
    ) -> [SermonVerseReference] {
        refs.map { ref in
            classifySingleRef(ref, context: context, classification: classification)
        }
    }

    /// Classify a single reference
    private nonisolated func classifySingleRef(
        _ ref: SermonVerseReference,
        context: SermonEnrichmentContext?,
        classification: RefClassification
    ) -> SermonVerseReference {
        var enriched = ref

        switch classification {
        case .mentioned:
            // Mentioned refs are inherently verified - no status needed
            enriched.enrichmentSources = [.transcript]

        case .suggested:
            // Parse and validate the reference
            let parseResult = ReferenceParser.parseFlexible(ref.reference)

            switch parseResult {
            case .failure:
                // Unparseable reference
                enriched.verificationStatus = .unverified
                enriched.enrichmentSources = [.aiOnly]
                enriched.verificationNotes = ["Unrecognized reference format; please verify."]

            case .success(let parsed):
                let suggestedCanonicalId = ReferenceParser.canonicalId(for: parsed)
                enriched.canonicalId = suggestedCanonicalId

                guard let context = context else {
                    // No context available - mark as partial
                    enriched.verificationStatus = .partial
                    enriched.enrichmentSources = [.aiOnly]
                    return enriched
                }

                // Check verification index
                let verificationResult = verifyAgainstIndex(
                    suggestedCanonicalId: suggestedCanonicalId,
                    index: context.verificationIndex
                )

                enriched.verificationStatus = verificationResult.status
                enriched.enrichmentSources = verificationResult.sources
                enriched.verifiedBy = verificationResult.verifiedBy
                enriched.verificationNotes = verificationResult.notes

                // Attach cross-ref summaries if available
                if let crossRefs = findCrossRefSummaries(for: suggestedCanonicalId, in: context) {
                    enriched.crossReferences = crossRefs
                }
            }
        }

        enriched.enrichmentVersion = "1"
        return enriched
    }

    /// Verify a suggested reference against the verification index
    private nonisolated func verifyAgainstIndex(
        suggestedCanonicalId: String,
        index: VerificationIndex
    ) -> VerificationResult {
        // Check for outgoing match (explicit ref → suggested ref)
        for (explicitId, targets) in index.outgoingMap {
            if targets.contains(suggestedCanonicalId) {
                return VerificationResult(
                    status: .verified,
                    sources: [.crossRefDB],
                    verifiedBy: [explicitId],
                    notes: nil
                )
            }
        }

        // Check for incoming match (suggested ref → explicit ref)
        if let sources = index.incomingMap[suggestedCanonicalId], !sources.isEmpty {
            return VerificationResult(
                status: .partial,
                sources: [.crossRefDB],
                verifiedBy: Array(sources),
                notes: ["Supported by reverse cross-reference in database"]
            )
        }

        // Valid reference but no cross-ref connection
        if index.isPartialData {
            return VerificationResult(
                status: .unknown,
                sources: [.aiOnly],
                verifiedBy: nil,
                notes: nil
            )
        }

        return VerificationResult(
            status: .partial,
            sources: [.aiOnly],
            verifiedBy: nil,
            notes: ["Valid reference, not in cross-reference database"]
        )
    }

    /// Find cross-reference summaries for a canonical ID
    private nonisolated func findCrossRefSummaries(
        for canonicalId: String,
        in context: SermonEnrichmentContext
    ) -> [EnrichedCrossRefSummary]? {
        // Look up cross-refs from prompt context items
        for item in context.promptContext.items {
            let itemCanonicalId = ReferenceParser.canonicalId(
                bookId: item.sourceRange.bookId,
                chapter: item.sourceRange.chapter,
                verseStart: item.sourceRange.verseStart,
                verseEnd: item.sourceRange.verseEnd
            )

            if itemCanonicalId == canonicalId {
                return item.crossRefs.map { crossRef in
                    EnrichedCrossRefSummary(
                        canonicalId: crossRef.canonicalId,
                        displayRef: crossRef.displayRef,
                        weight: crossRef.weight
                    )
                }
            }
        }
        return nil
    }
}

// MARK: - Supporting Types

/// Classification type for references
enum RefClassification: Sendable {
    case mentioned  // Explicitly mentioned in transcript
    case suggested  // AI-suggested reference
}

/// Result of verification check
private struct VerificationResult: Sendable {
    let status: VerificationStatus
    let sources: [EnrichmentSource]
    let verifiedBy: [String]?
    let notes: [String]?
}

// MARK: - Sermon Enrichment Context

/// Context for sermon enrichment (prompt + verification)
struct SermonEnrichmentContext: Sendable {
    let promptContext: PromptContext
    let verificationIndex: VerificationIndex
}

// MARK: - Prompt Context

/// Context formatted for AI prompt (capped for token budget)
struct PromptContext: Sendable {
    let items: [ContextItem]
    let maxChars: Int

    struct ContextItem: Sendable {
        let sourceRange: VerseRange
        let crossRefs: [EnrichedCrossRef]
        let insights: [EnrichedInsight]
    }

    /// Format context for inclusion in AI prompt
    func formatForPrompt() -> String {
        guard !items.isEmpty else { return "" }

        var lines: [String] = ["VERIFIED CROSS-REFERENCES (choose from these when suggesting):"]

        for item in items {
            guard !item.crossRefs.isEmpty else { continue }

            let sourceRef = item.sourceRange.reference
            let targets = item.crossRefs.map { $0.displayRef }.joined(separator: ", ")
            lines.append("  \(sourceRef) → \(targets)")
        }

        let result = lines.joined(separator: "\n")

        // Truncate if over limit
        if result.count > maxChars {
            return String(result.prefix(maxChars - 3)) + "..."
        }
        return result
    }
}

// MARK: - Verification Index

/// Full verification index for post-AI classification
struct VerificationIndex: Sendable {
    /// Outgoing: source canonical ID → target canonical IDs
    let outgoingMap: [String: Set<String>]
    /// Incoming: target canonical ID → source canonical IDs
    let incomingMap: [String: Set<String>]
    /// True if using sample/partial data (DEBUG mode)
    let isPartialData: Bool

    /// Check if explicit ref has outgoing cross-ref to suggested ref
    func hasOutgoing(from explicit: String, to suggested: String) -> Bool {
        outgoingMap[explicit]?.contains(suggested) ?? false
    }

    /// Check if suggested ref has incoming cross-ref from explicit ref
    func hasIncoming(from suggested: String, to explicit: String) -> Bool {
        incomingMap[suggested]?.contains(explicit) ?? false
    }

    /// Get evidence (source refs) for a target canonical ID
    func evidence(for canonicalId: String) -> [String] {
        Array(incomingMap[canonicalId] ?? [])
    }
}

// MARK: - Enriched Types (for prompt context)

/// Enriched cross-reference for prompt context
struct EnrichedCrossRef: Sendable {
    let canonicalId: String
    let displayRef: String
    let weight: Int?
}

/// Enriched insight for prompt context
struct EnrichedInsight: Sendable {
    let id: String
    let title: String
    let type: String
}

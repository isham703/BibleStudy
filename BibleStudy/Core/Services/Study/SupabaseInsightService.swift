import Foundation
import Supabase

// MARK: - Supabase Insight Service
// Fetches pre-generated insights from Supabase
// Replaces bundled CommentaryData.sqlite with cloud-hosted data

@MainActor
final class SupabaseInsightService: InsightProviding, Sendable {
    // MARK: - Singleton

    static let shared = SupabaseInsightService()

    // MARK: - Dependencies

    private let supabase: SupabaseManager

    // MARK: - Cache

    private var insightCache: [String: [BibleInsightDTO]] = [:]
    private var crossRefCache: [String: [CrossRefExplanationDTO]] = [:]
    private var cacheVersion: Int = 0

    // MARK: - State

    var isLoading: Bool = false
    var error: Error?

    // MARK: - Initialization

    private init() {
        self.supabase = .shared
    }

    // MARK: - Public API

    /// Get all insights for a chapter
    func getInsights(bookId: Int, chapter: Int) async throws -> [BibleInsight] {
        let cacheKey = "\(bookId)-\(chapter)"

        // Check cache first
        if let cached = insightCache[cacheKey] {
            print("SupabaseInsightService: Cache hit for \(cacheKey), returning \(cached.count) insights")
            return cached.map { $0.toBibleInsight() }
        }

        print("SupabaseInsightService: Fetching insights for book \(bookId), chapter \(chapter)")

        // Fetch from Supabase
        do {
            let dtos: [BibleInsightDTO] = try await supabase.client
                .from("bible_insights")
                .select()
                .eq("book_id", value: bookId)
                .eq("chapter", value: chapter)
                .order("verse_start", ascending: true)
                .order("segment_start_char", ascending: true)
                .execute()
                .value

            print("SupabaseInsightService: Fetched \(dtos.count) insights from Supabase")

            // Cache and return
            insightCache[cacheKey] = dtos
            return dtos.map { $0.toBibleInsight() }
        } catch {
            print("SupabaseInsightService: Error fetching insights - \(error)")
            throw error
        }
    }

    /// Get insights for a specific verse
    func getInsights(bookId: Int, chapter: Int, verse: Int) async throws -> [BibleInsight] {
        // Use chapter cache for efficiency
        let chapterInsights = try await getInsights(bookId: bookId, chapter: chapter)
        return chapterInsights.filter { $0.verseStart <= verse && $0.verseEnd >= verse }
    }

    /// Get insights filtered by type
    func getInsights(bookId: Int, chapter: Int, types: Set<BibleInsightType>) async throws -> [BibleInsight] {
        let chapterInsights = try await getInsights(bookId: bookId, chapter: chapter)
        return chapterInsights.filter { types.contains($0.insightType) }
    }

    /// Get insights grouped by verse
    func getInsightsGroupedByVerse(bookId: Int, chapter: Int) async throws -> [Int: [BibleInsight]] {
        let allInsights = try await getInsights(bookId: bookId, chapter: chapter)

        var grouped: [Int: [BibleInsight]] = [:]
        for insight in allInsights {
            grouped[insight.verseStart, default: []].append(insight)
        }
        return grouped
    }

    /// Get insight counts per verse for Reading Mode indicators
    func getInsightCountsByVerse(
        bookId: Int,
        chapter: Int,
        types: Set<BibleInsightType>? = nil
    ) async throws -> [Int: Int] {
        var insights = try await getInsights(bookId: bookId, chapter: chapter)

        if let types = types {
            insights = insights.filter { types.contains($0.insightType) }
        }

        var counts: [Int: Int] = [:]
        for insight in insights {
            counts[insight.verseStart, default: 0] += 1
        }
        return counts
    }

    // MARK: - Cross-Reference Explanations

    /// Get all cross-reference explanations for a verse
    func getCrossRefExplanations(
        bookId: Int,
        chapter: Int,
        verse: Int
    ) async throws -> [CrossRefExplanation] {
        let cacheKey = "\(bookId)-\(chapter)"

        // Check cache first
        var chapterCrossRefs: [CrossRefExplanationDTO]
        if let cached = crossRefCache[cacheKey] {
            chapterCrossRefs = cached
        } else {
            // Fetch all crossrefs for chapter
            chapterCrossRefs = try await supabase.client
                .from("crossref_explanations")
                .select()
                .eq("source_book_id", value: bookId)
                .eq("source_chapter", value: chapter)
                .order("weight", ascending: false)
                .execute()
                .value

            crossRefCache[cacheKey] = chapterCrossRefs
        }

        // Filter for specific verse
        let verseRefs = chapterCrossRefs.filter { $0.sourceVerse == verse }
        return verseRefs.map { $0.toCrossRefExplanation() }
    }

    // MARK: - Cache Management

    /// Clear all caches
    func clearCache() {
        insightCache.removeAll()
        crossRefCache.removeAll()
    }

    /// Check if content version has changed (call periodically)
    func checkContentVersion() async throws -> Bool {
        struct ContentVersion: Decodable {
            let insightsVersion: Int
            let crossrefsVersion: Int

            enum CodingKeys: String, CodingKey {
                case insightsVersion = "insights_version"
                case crossrefsVersion = "crossrefs_version"
            }
        }

        let versions: [ContentVersion] = try await supabase.client
            .from("content_versions")
            .select()
            .limit(1)
            .execute()
            .value

        guard let version = versions.first else { return true }
        let serverVersion = version.insightsVersion + version.crossrefsVersion

        if serverVersion != cacheVersion {
            cacheVersion = serverVersion
            clearCache()
            return false
        }
        return true
    }

    /// Prefetch insights for adjacent chapters
    func prefetchChapter(bookId: Int, chapter: Int) async {
        do {
            _ = try await getInsights(bookId: bookId, chapter: chapter)
        } catch {
            // Silent prefetch failure is OK
            print("Prefetch failed for \(bookId):\(chapter): \(error)")
        }
    }

    // MARK: - InsightProviding Protocol

    /// Whether commentary data is available (always true for Supabase service)
    nonisolated var hasCommentaryData: Bool { true }

    /// Get insight summaries for a specific verse (InsightProviding protocol)
    func getInsightSummaries(bookId: Int, chapter: Int, verse: Int) async throws -> [InsightSummary] {
        let insights = try await getInsights(bookId: bookId, chapter: chapter, verse: verse)
        return insights.map { $0.toInsightSummary() }
    }

    /// Get insight summaries for a verse range (InsightProviding protocol)
    func getInsightSummaries(bookId: Int, chapter: Int, verseStart: Int, verseEnd: Int) async throws -> [InsightSummary] {
        let chapterInsights = try await getInsights(bookId: bookId, chapter: chapter)
        let rangeInsights = chapterInsights.filter {
            $0.verseStart <= verseEnd && $0.verseEnd >= verseStart
        }
        return rangeInsights.map { $0.toInsightSummary() }
    }
}

// MARK: - DTOs

/// Supabase bible_insights row
struct BibleInsightDTO: Decodable {
    let id: UUID
    let bookId: Int
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int
    let translationId: String?
    let segmentText: String
    let segmentStartChar: Int
    let segmentEndChar: Int
    let insightType: String
    let title: String
    let content: String
    let icon: String
    let sources: [InsightSource]?
    let qualityTier: String
    let isInterpretive: Bool
    let promptVersion: String?
    let model: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case bookId = "book_id"
        case chapter
        case verseStart = "verse_start"
        case verseEnd = "verse_end"
        case translationId = "translation_id"
        case segmentText = "segment_text"
        case segmentStartChar = "segment_start_char"
        case segmentEndChar = "segment_end_char"
        case insightType = "insight_type"
        case title
        case content
        case icon
        case sources
        case qualityTier = "quality_tier"
        case isInterpretive = "is_interpretive"
        case promptVersion = "prompt_version"
        case model
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Convert to app's BibleInsight model
    func toBibleInsight() -> BibleInsight {
        BibleInsight(
            id: id.uuidString,
            bookId: bookId,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd,
            segmentText: segmentText,
            segmentStartChar: segmentStartChar,
            segmentEndChar: segmentEndChar,
            insightType: BibleInsightType(rawValue: insightType) ?? .connection,
            title: title,
            content: content,
            icon: icon,
            sources: sources ?? [],
            contentVersion: 1,
            promptVersion: promptVersion ?? "",
            modelVersion: model ?? "",
            createdAt: createdAt,
            qualityTier: QualityTier(rawValue: qualityTier) ?? .standard,
            isInterpretive: isInterpretive
        )
    }
}

/// Supabase crossref_explanations row
struct CrossRefExplanationDTO: Decodable {
    let id: UUID
    let sourceBookId: Int
    let sourceChapter: Int
    let sourceVerse: Int
    let targetBookId: Int
    let targetChapter: Int
    let targetVerseStart: Int
    let targetVerseEnd: Int
    let anchorPhrase: String?
    let title: String
    let content: String
    let connectionType: String
    let weight: Double
    let promptVersion: String?
    let model: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sourceBookId = "source_book_id"
        case sourceChapter = "source_chapter"
        case sourceVerse = "source_verse"
        case targetBookId = "target_book_id"
        case targetChapter = "target_chapter"
        case targetVerseStart = "target_verse_start"
        case targetVerseEnd = "target_verse_end"
        case anchorPhrase = "anchor_phrase"
        case title
        case content
        case connectionType = "connection_type"
        case weight
        case promptVersion = "prompt_version"
        case model
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toCrossRefExplanation() -> CrossRefExplanation {
        CrossRefExplanation(
            id: id,
            targetRange: VerseRange(
                bookId: targetBookId,
                chapter: targetChapter,
                verseStart: targetVerseStart,
                verseEnd: targetVerseEnd
            ),
            anchorPhrase: anchorPhrase,
            title: title,
            content: content,
            connectionType: ConnectionType(rawValue: connectionType) ?? .theme,
            weight: weight
        )
    }
}

// MARK: - App Models

/// Rich cross-reference explanation for display
struct CrossRefExplanation: Identifiable, Hashable, Sendable {
    let id: UUID
    let targetRange: VerseRange
    let anchorPhrase: String?
    let title: String
    let content: String
    let connectionType: ConnectionType
    let weight: Double

    var targetReference: String {
        targetRange.reference
    }

    var targetBook: Book? {
        Book.find(byId: targetRange.bookId)
    }
}

/// Types of connections between passages
enum ConnectionType: String, Codable, Sendable {
    case quotation      // Direct quote or allusion
    case theme          // Shared theological theme
    case typology       // OT type/NT antitype
    case prophecy       // Prophecy/fulfillment
    case parallel       // Similar narrative/teaching
    case keyword        // Shared significant term
    case other

    var label: String {
        switch self {
        case .quotation: return "Quotation"
        case .theme: return "Theme"
        case .typology: return "Typology"
        case .prophecy: return "Prophecy"
        case .parallel: return "Parallel"
        case .keyword: return "Keyword"
        case .other: return "Connection"
        }
    }

    var icon: String {
        switch self {
        case .quotation: return "quote.bubble"
        case .theme: return "sparkles"
        case .typology: return "arrow.triangle.swap"
        case .prophecy: return "star.fill"
        case .parallel: return "arrow.left.arrow.right"
        case .keyword: return "textformat.abc"
        case .other: return "link"
        }
    }
}


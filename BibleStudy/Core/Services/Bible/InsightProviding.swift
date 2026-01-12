import Foundation

// MARK: - Insight Providing Protocol
/// Protocol for Bible insight services to enable dependency injection
/// and avoid Core → Features layer inversion
///
/// Conformers: BibleInsightService (in Features/Bible/Services)
protocol InsightProviding: Sendable {
    /// Whether commentary data is available
    var hasCommentaryData: Bool { get }

    /// Get insights for a specific verse
    /// - Parameters:
    ///   - bookId: Book ID (e.g., 43 for John)
    ///   - chapter: Chapter number
    ///   - verse: Verse number
    /// - Returns: Array of insight summaries for sermon enrichment
    func getInsightSummaries(bookId: Int, chapter: Int, verse: Int) async throws -> [InsightSummary]

    /// Get insights for a verse range
    /// - Parameters:
    ///   - bookId: Book ID
    ///   - chapter: Chapter number
    ///   - verseStart: Starting verse number
    ///   - verseEnd: Ending verse number (inclusive)
    /// - Returns: Array of insight summaries for sermon enrichment
    func getInsightSummaries(bookId: Int, chapter: Int, verseStart: Int, verseEnd: Int) async throws -> [InsightSummary]
}

// MARK: - Insight Summary
/// Minimal insight data for sermon enrichment (decoupled from full BibleInsight model)
struct InsightSummary: Sendable, Identifiable, Hashable {
    let id: String
    let bookId: Int
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int
    let title: String
    let insightType: String  // Raw type string for flexibility
}

// MARK: - Null Implementation
/// Default implementation that returns no insights (for when service is unavailable)
final class NullInsightProvider: InsightProviding, Sendable {
    // nonisolated(unsafe) allows use as default parameter in nonisolated init
    nonisolated(unsafe) static let shared = NullInsightProvider()

    var hasCommentaryData: Bool { false }

    func getInsightSummaries(bookId: Int, chapter: Int, verse: Int) async throws -> [InsightSummary] {
        return []
    }

    func getInsightSummaries(bookId: Int, chapter: Int, verseStart: Int, verseEnd: Int) async throws -> [InsightSummary] {
        return []
    }
}

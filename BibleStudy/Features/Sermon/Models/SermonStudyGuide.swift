import Foundation
import GRDB

// MARK: - Sermon Study Guide
// AI-generated study guide with discussion questions, themes, and cross-references
struct SermonStudyGuide: Identifiable, Hashable, Sendable {
    let id: UUID
    let sermonId: UUID
    var content: StudyGuideContent
    var modelUsed: String?
    var promptVersion: String
    var transcriptHash: String?
    let createdAt: Date
    var updatedAt: Date
    var needsSync: Bool

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        sermonId: UUID,
        content: StudyGuideContent,
        modelUsed: String? = nil,
        promptVersion: String = "1",
        transcriptHash: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        needsSync: Bool = false
    ) {
        self.id = id
        self.sermonId = sermonId
        self.content = content
        self.modelUsed = modelUsed
        self.promptVersion = promptVersion
        self.transcriptHash = transcriptHash
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.needsSync = needsSync
    }
}

// MARK: - Study Guide Content
// The structured content of a study guide
// Note: nonisolated to prevent MainActor inference on Codable conformance and init
nonisolated struct StudyGuideContent: Codable, Hashable, Sendable {
    var title: String
    var summary: String
    var keyThemes: [String]

    // Navigation/grounding
    var outline: [OutlineSection]?
    var notableQuotes: [Quote]?
    var bibleReferencesMentioned: [SermonVerseReference]
    var bibleReferencesSuggested: [SermonVerseReference]

    // Study prompts
    var discussionQuestions: [StudyQuestion]
    var reflectionPrompts: [String]
    var applicationPoints: [String]

    // Diagnostics
    var confidenceNotes: [String]?

    init(
        title: String = "",
        summary: String = "",
        keyThemes: [String] = [],
        outline: [OutlineSection]? = nil,
        notableQuotes: [Quote]? = nil,
        bibleReferencesMentioned: [SermonVerseReference] = [],
        bibleReferencesSuggested: [SermonVerseReference] = [],
        discussionQuestions: [StudyQuestion] = [],
        reflectionPrompts: [String] = [],
        applicationPoints: [String] = [],
        confidenceNotes: [String]? = nil
    ) {
        self.title = title
        self.summary = summary
        self.keyThemes = keyThemes
        self.outline = outline
        self.notableQuotes = notableQuotes
        self.bibleReferencesMentioned = bibleReferencesMentioned
        self.bibleReferencesSuggested = bibleReferencesSuggested
        self.discussionQuestions = discussionQuestions
        self.reflectionPrompts = reflectionPrompts
        self.applicationPoints = applicationPoints
        self.confidenceNotes = confidenceNotes
    }
}

// MARK: - Outline Section
nonisolated struct OutlineSection: Codable, Hashable, Sendable, Identifiable {
    var id: String { title }
    let title: String
    let startSeconds: Double?
    let endSeconds: Double?
    let summary: String?
}

// MARK: - Quote
nonisolated struct Quote: Codable, Hashable, Sendable, Identifiable {
    var id: String { text }
    let text: String
    let timestampSeconds: Double?
    let context: String?
}

// MARK: - Verification Status
/// Indicates how a suggested Bible reference was verified
/// Uses unknown-safe decoding for forward compatibility
enum VerificationStatus: String, Codable, Sendable {
    case verified      // Outgoing cross-ref match in database
    case partial       // Incoming-only match OR valid ref but no cross-ref connection
    case unverified    // Unparseable or invalid reference
    case unknown       // DEBUG mode with sample data, or pipeline error/timeout

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = VerificationStatus(rawValue: value) ?? .unknown
    }
}

// MARK: - Enrichment Source
/// Where the enrichment data came from
enum EnrichmentSource: String, Codable, Sendable {
    case transcript    // Explicitly mentioned in sermon
    case crossRefDB    // Found in CrossRefService
    case insightDB     // Found in BibleInsightService
    case aiOnly        // AI-generated, not in database
    case unknown       // Source not determined

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = EnrichmentSource(rawValue: value) ?? .unknown
    }
}

// MARK: - Enriched Cross-Reference Summary
/// Minimal cross-reference data stored with study guide (full content fetched on-demand)
nonisolated struct EnrichedCrossRefSummary: Codable, Hashable, Sendable, Identifiable {
    var id: String { canonicalId }
    let canonicalId: String    // e.g., "43.3.16" (bookId.chapter.verse)
    let displayRef: String     // e.g., "John 3:16" (for UI display)
    let weight: Int?           // Cross-reference weight/relevance score
}

// MARK: - Enriched Insight Summary
/// Minimal insight data stored with study guide (full content fetched on-demand)
nonisolated struct EnrichedInsightSummary: Codable, Hashable, Sendable, Identifiable {
    var id: Int { insightId }
    let insightId: Int         // Database ID for lazy fetch
    let title: String          // Title only (not full content)
}

// MARK: - Sermon Verse Reference
nonisolated struct SermonVerseReference: Codable, Hashable, Sendable, Identifiable {
    // Fix: Use stored UUID to avoid SwiftUI list collisions when same reference appears multiple times
    let id: UUID
    let reference: String           // e.g., "John 3:16"
    let bookId: Int?
    let chapter: Int?
    let verseStart: Int?
    let verseEnd: Int?
    let isMentioned: Bool           // Explicitly mentioned vs AI-suggested
    let rationale: String?          // Why this reference is relevant
    let timestampSeconds: Double?   // When mentioned in sermon

    // MARK: - Enrichment Fields (Optional)

    /// Verification status (only set for suggested refs; mentioned refs are inherently verified)
    var verificationStatus: VerificationStatus?

    /// Sources that contributed to this reference's enrichment
    var enrichmentSources: [EnrichmentSource]?

    /// Canonical IDs of source refs that verify this (e.g., ["43.3.16"] for "John 3:16")
    var verifiedBy: [String]?

    /// Notes explaining verification status (e.g., "Supported by reverse cross-reference")
    var verificationNotes: [String]?

    /// Summary of related cross-references (IDs + display refs only)
    var crossReferences: [EnrichedCrossRefSummary]?

    /// Summary of related insights (IDs + titles only)
    var insights: [EnrichedInsightSummary]?

    /// Canonical ID for stable lookup (e.g., "43.3.16")
    var canonicalId: String?

    /// Version of enrichment pipeline that processed this (for future re-enrichment)
    var enrichmentVersion: String?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        reference: String,
        bookId: Int? = nil,
        chapter: Int? = nil,
        verseStart: Int? = nil,
        verseEnd: Int? = nil,
        isMentioned: Bool,
        rationale: String? = nil,
        timestampSeconds: Double? = nil,
        verificationStatus: VerificationStatus? = nil,
        enrichmentSources: [EnrichmentSource]? = nil,
        verifiedBy: [String]? = nil,
        verificationNotes: [String]? = nil,
        crossReferences: [EnrichedCrossRefSummary]? = nil,
        insights: [EnrichedInsightSummary]? = nil,
        canonicalId: String? = nil,
        enrichmentVersion: String? = nil
    ) {
        self.id = id
        self.reference = reference
        self.bookId = bookId
        self.chapter = chapter
        self.verseStart = verseStart
        self.verseEnd = verseEnd
        self.isMentioned = isMentioned
        self.rationale = rationale
        self.timestampSeconds = timestampSeconds
        self.verificationStatus = verificationStatus
        self.enrichmentSources = enrichmentSources
        self.verifiedBy = verifiedBy
        self.verificationNotes = verificationNotes
        self.crossReferences = crossReferences
        self.insights = insights
        self.canonicalId = canonicalId
        self.enrichmentVersion = enrichmentVersion
    }

    // MARK: - Coding Keys (for backward compatibility)

    enum CodingKeys: String, CodingKey {
        case id
        case reference
        case bookId = "book_id"
        case chapter
        case verseStart = "verse_start"
        case verseEnd = "verse_end"
        case isMentioned = "is_mentioned"
        case rationale
        case timestampSeconds = "timestamp_seconds"
        case verificationStatus = "verification_status"
        case enrichmentSources = "enrichment_sources"
        case verifiedBy = "verified_by"
        case verificationNotes = "verification_notes"
        case crossReferences = "cross_references"
        case insights
        case canonicalId = "canonical_id"
        case enrichmentVersion = "enrichment_version"
    }

    // MARK: - Custom Decoding (backward compatibility)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle backward compatibility: old data may not have id field
        if let existingId = try container.decodeIfPresent(UUID.self, forKey: .id) {
            self.id = existingId
        } else {
            self.id = UUID()
        }

        self.reference = try container.decode(String.self, forKey: .reference)
        self.bookId = try container.decodeIfPresent(Int.self, forKey: .bookId)
        self.chapter = try container.decodeIfPresent(Int.self, forKey: .chapter)
        self.verseStart = try container.decodeIfPresent(Int.self, forKey: .verseStart)
        self.verseEnd = try container.decodeIfPresent(Int.self, forKey: .verseEnd)
        self.isMentioned = try container.decodeIfPresent(Bool.self, forKey: .isMentioned) ?? false
        self.rationale = try container.decodeIfPresent(String.self, forKey: .rationale)
        self.timestampSeconds = try container.decodeIfPresent(Double.self, forKey: .timestampSeconds)

        // New enrichment fields (all optional)
        self.verificationStatus = try container.decodeIfPresent(VerificationStatus.self, forKey: .verificationStatus)
        self.enrichmentSources = try container.decodeIfPresent([EnrichmentSource].self, forKey: .enrichmentSources)
        self.verifiedBy = try container.decodeIfPresent([String].self, forKey: .verifiedBy)
        self.verificationNotes = try container.decodeIfPresent([String].self, forKey: .verificationNotes)
        self.crossReferences = try container.decodeIfPresent([EnrichedCrossRefSummary].self, forKey: .crossReferences)
        self.insights = try container.decodeIfPresent([EnrichedInsightSummary].self, forKey: .insights)
        self.canonicalId = try container.decodeIfPresent(String.self, forKey: .canonicalId)
        self.enrichmentVersion = try container.decodeIfPresent(String.self, forKey: .enrichmentVersion)
    }
}

// MARK: - SermonVerseReference Extensions

extension SermonVerseReference {
    /// Convert to VerseRange for database lookups
    func toVerseRange() -> VerseRange? {
        guard let bookId = bookId,
              let chapter = chapter,
              let verseStart = verseStart else {
            return nil
        }
        return VerseRange(
            bookId: bookId,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd ?? verseStart
        )
    }
}

// MARK: - Study Question
nonisolated struct StudyQuestion: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let question: String
    let type: QuestionType
    let relatedVerses: [String]?
    let discussionHint: String?

    init(
        id: String = UUID().uuidString,
        question: String,
        type: QuestionType,
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

// MARK: - Question Type
enum QuestionType: String, Codable, Sendable, CaseIterable {
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

// MARK: - GRDB Support
// Note: nonisolated to prevent MainActor inference from -default-isolation=MainActor
nonisolated extension SermonStudyGuide: FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "sermon_study_guides" }

    enum Columns: String, ColumnExpression {
        case id
        case sermonId = "sermon_id"
        case content
        case modelUsed = "model_used"
        case promptVersion = "prompt_version"
        case transcriptHash = "transcript_hash"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case needsSync = "needs_sync"
    }

    nonisolated init(row: Row) {
        id = row[Columns.id]
        sermonId = row[Columns.sermonId]

        if let contentString: String = row[Columns.content],
           let data = contentString.data(using: .utf8) {
            content = (try? JSONDecoder().decode(StudyGuideContent.self, from: data)) ?? StudyGuideContent()
        } else {
            content = StudyGuideContent()
        }

        modelUsed = row[Columns.modelUsed]
        promptVersion = row[Columns.promptVersion] ?? "1"
        transcriptHash = row[Columns.transcriptHash]
        createdAt = row[Columns.createdAt]
        updatedAt = row[Columns.updatedAt]
        needsSync = row[Columns.needsSync]
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.sermonId] = sermonId

        if let data = try? JSONEncoder().encode(content),
           let jsonString = String(data: data, encoding: .utf8) {
            container[Columns.content] = jsonString
        } else {
            container[Columns.content] = "{}"
        }

        container[Columns.modelUsed] = modelUsed
        container[Columns.promptVersion] = promptVersion
        container[Columns.transcriptHash] = transcriptHash
        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt
        container[Columns.needsSync] = needsSync
    }
}

// MARK: - DTO for Supabase Sync
struct SermonStudyGuideDTO: Codable {
    let id: UUID
    let sermonId: UUID
    let content: StudyGuideContent
    let modelUsed: String?
    let promptVersion: String
    let transcriptHash: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sermonId = "sermon_id"
        case content
        case modelUsed = "model_used"
        case promptVersion = "prompt_version"
        case transcriptHash = "transcript_hash"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Conversion
extension SermonStudyGuide {
    init(from dto: SermonStudyGuideDTO) {
        self.id = dto.id
        self.sermonId = dto.sermonId
        self.content = dto.content
        self.modelUsed = dto.modelUsed
        self.promptVersion = dto.promptVersion
        self.transcriptHash = dto.transcriptHash
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
        self.needsSync = false
    }

    func toDTO() -> SermonStudyGuideDTO {
        SermonStudyGuideDTO(
            id: id,
            sermonId: sermonId,
            content: content,
            modelUsed: modelUsed,
            promptVersion: promptVersion,
            transcriptHash: transcriptHash,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

import Foundation
import GRDB
import CryptoKit

// MARK: - Engagement Type

enum EngagementType: String, Codable, Sendable {
    case applicationCommit = "application_commit"
    case favoriteInsight = "favorite_insight"
    case favoriteQuote = "favorite_quote"
    case journalEntry = "journal_entry"
}

// MARK: - Sermon Engagement
// User engagement with sermon content (commits, favorites, journal entries).
// Uses content fingerprint for targetId to ensure stability across app launches.

struct SermonEngagement: Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let sermonId: UUID
    let engagementType: EngagementType
    let targetId: String
    var content: String?
    var metadata: String?
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var needsSync: Bool

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        userId: UUID,
        sermonId: UUID,
        engagementType: EngagementType,
        targetId: String,
        content: String? = nil,
        metadata: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        needsSync: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.sermonId = sermonId
        self.engagementType = engagementType
        self.targetId = targetId
        self.content = content
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.needsSync = needsSync
    }

    // MARK: - Mutations

    mutating func markDeleted() {
        deletedAt = Date()
        updatedAt = Date()
        needsSync = true
    }

    mutating func restore() {
        deletedAt = nil
        updatedAt = Date()
        needsSync = true
    }

    mutating func updateContent(_ newContent: String?) {
        content = newContent
        updatedAt = Date()
        needsSync = true
    }

    /// Whether this engagement is currently active (not soft-deleted)
    var isActive: Bool {
        deletedAt == nil
    }

    // MARK: - Content Fingerprint

    /// Generates a deterministic targetId from content fields.
    /// Stable across app launches even when model IDs are random UUIDs.
    static func fingerprint(sermonId: UUID, type: EngagementType, content: String...) -> String {
        let normalized = content.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        let input = "\(sermonId.uuidString)|\(type.rawValue)|\(normalized.joined(separator: "|"))"
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.prefix(16).map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - GRDB Support
// Note: nonisolated to prevent MainActor inference from -default-isolation=MainActor
nonisolated extension SermonEngagement: FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "sermon_engagements" }

    enum Columns: String, ColumnExpression {
        case id
        case userId = "user_id"
        case sermonId = "sermon_id"
        case engagementType = "engagement_type"
        case targetId = "target_id"
        case content
        case metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case needsSync = "needs_sync"
    }

    nonisolated init(row: Row) {
        id = row[Columns.id]
        userId = row[Columns.userId]
        sermonId = row[Columns.sermonId]

        if let typeString: String = row[Columns.engagementType] {
            engagementType = EngagementType(rawValue: typeString) ?? .favoriteInsight
        } else {
            engagementType = .favoriteInsight
        }

        targetId = row[Columns.targetId]
        content = row[Columns.content]
        metadata = row[Columns.metadata]
        createdAt = row[Columns.createdAt]
        updatedAt = row[Columns.updatedAt]
        deletedAt = row[Columns.deletedAt]
        needsSync = row[Columns.needsSync]
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.userId] = userId
        container[Columns.sermonId] = sermonId
        container[Columns.engagementType] = engagementType.rawValue
        container[Columns.targetId] = targetId
        container[Columns.content] = content
        container[Columns.metadata] = metadata
        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt
        container[Columns.deletedAt] = deletedAt
        container[Columns.needsSync] = needsSync
    }
}

// MARK: - DTO for Supabase Sync

struct SermonEngagementDTO: Codable {
    let id: UUID
    let userId: UUID
    let sermonId: UUID
    let engagementType: String
    let targetId: String
    let content: String?
    let metadata: String?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sermonId = "sermon_id"
        case engagementType = "engagement_type"
        case targetId = "target_id"
        case content
        case metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

// MARK: - Conversion

extension SermonEngagement {
    init(from dto: SermonEngagementDTO) {
        self.id = dto.id
        self.userId = dto.userId
        self.sermonId = dto.sermonId
        self.engagementType = EngagementType(rawValue: dto.engagementType) ?? .favoriteInsight
        self.targetId = dto.targetId
        self.content = dto.content
        self.metadata = dto.metadata
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
        self.deletedAt = dto.deletedAt
        self.needsSync = false
    }

    func toDTO() -> SermonEngagementDTO {
        SermonEngagementDTO(
            id: id,
            userId: userId,
            sermonId: sermonId,
            engagementType: engagementType.rawValue,
            targetId: targetId,
            content: content,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}

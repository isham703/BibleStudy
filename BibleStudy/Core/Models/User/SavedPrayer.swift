import Foundation
import GRDB

// MARK: - Saved Prayer
// User-saved AI-generated prayer with sync support

struct SavedPrayer: Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let tradition: PrayerTradition
    let content: String
    let amen: String
    let userContext: String
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    // Sync tracking
    var needsSync: Bool = false
    var lastSyncedAt: Date?
    var syncRetryCount: Int = 0
    var syncError: String?

    var preview: String {
        let maxLength = 100
        if content.count <= maxLength {
            return content
        }
        return String(content.prefix(maxLength)) + "..."
    }

    var lines: [String] {
        content
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
    }

    var words: [String] {
        content
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        tradition: PrayerTradition,
        content: String,
        amen: String,
        userContext: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        needsSync: Bool = false,
        lastSyncedAt: Date? = nil,
        syncRetryCount: Int = 0,
        syncError: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.tradition = tradition
        self.content = content
        self.amen = amen
        self.userContext = userContext
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.needsSync = needsSync
        self.lastSyncedAt = lastSyncedAt
        self.syncRetryCount = syncRetryCount
        self.syncError = syncError
    }

    /// Create SavedPrayer from Prayer model (for saving)
    init(from prayer: Prayer, userId: UUID) {
        self.init(
            id: prayer.id,
            userId: userId,
            tradition: prayer.tradition,
            content: prayer.content,
            amen: prayer.amen,
            userContext: prayer.userContext,
            createdAt: prayer.createdAt,
            needsSync: true
        )
    }

    mutating func markDeleted() {
        deletedAt = Date()
        updatedAt = Date()
        needsSync = true
    }
}

// MARK: - PrayerDisplayable Conformance
extension SavedPrayer: PrayerDisplayable {}

// MARK: - GRDB Support
extension SavedPrayer: FetchableRecord, PersistableRecord {
    nonisolated static var databaseTableName: String { "saved_prayers" }

    enum Columns: String, ColumnExpression {
        case id
        case userId = "user_id"
        case tradition
        case content
        case amen
        case userContext = "user_context"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case needsSync = "needs_sync"
        case lastSyncedAt = "last_synced_at"
        case syncRetryCount = "sync_retry_count"
        case syncError = "sync_error"
    }

    nonisolated init(row: Row) {
        id = row[Columns.id]
        userId = row[Columns.userId]
        if let traditionString: String = row[Columns.tradition] {
            tradition = PrayerTradition(rawValue: traditionString) ?? .psalmicLament
        } else {
            tradition = .psalmicLament
        }
        content = row[Columns.content]
        amen = row[Columns.amen]
        userContext = row[Columns.userContext]
        createdAt = row[Columns.createdAt]
        updatedAt = row[Columns.updatedAt]
        deletedAt = row[Columns.deletedAt]
        needsSync = row[Columns.needsSync]
        lastSyncedAt = row[Columns.lastSyncedAt]
        syncRetryCount = row[Columns.syncRetryCount]
        syncError = row[Columns.syncError]
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.userId] = userId
        container[Columns.tradition] = tradition.rawValue
        container[Columns.content] = content
        container[Columns.amen] = amen
        container[Columns.userContext] = userContext
        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt
        container[Columns.deletedAt] = deletedAt
        container[Columns.needsSync] = needsSync
        container[Columns.lastSyncedAt] = lastSyncedAt
        container[Columns.syncRetryCount] = syncRetryCount
        container[Columns.syncError] = syncError
    }
}

// MARK: - DTO for Supabase Sync
struct SavedPrayerDTO: Codable {
    let id: UUID
    let userId: UUID
    let tradition: String
    let content: String
    let amen: String
    let userContext: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case tradition
        case content
        case amen
        case userContext = "user_context"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Conversion from DTO
extension SavedPrayer {
    nonisolated init(from dto: SavedPrayerDTO) {
        self.id = dto.id
        self.userId = dto.userId
        self.tradition = PrayerTradition(rawValue: dto.tradition) ?? .psalmicLament
        self.content = dto.content
        self.amen = dto.amen
        self.userContext = dto.userContext
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
        self.deletedAt = nil
        self.needsSync = false
        self.lastSyncedAt = Date()  // Just synced from server
        self.syncRetryCount = 0
        self.syncError = nil
    }

    func toDTO() -> SavedPrayerDTO {
        SavedPrayerDTO(
            id: id,
            userId: userId,
            tradition: tradition.rawValue,
            content: content,
            amen: amen,
            userContext: userContext,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

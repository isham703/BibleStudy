import Foundation
import GRDB
import Auth

// MARK: - Prayer Service
// Manages saved prayers with offline-first sync

@MainActor
@Observable
final class PrayerService {
    // MARK: - Singleton
    static let shared = PrayerService()

    // MARK: - Properties
    private let supabase = SupabaseManager.shared
    private let db = DatabaseStore.shared

    var savedPrayers: [SavedPrayer] = []
    var isLoading: Bool = false
    var error: Error?

    // MARK: - Initialization
    private init() {}

    // MARK: - Load Content

    func loadPrayers() async {
        guard let userId = supabase.currentUser?.id else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Load from local cache first
            try loadFromCache(userId: userId)

            // Then sync with remote
            try await syncWithRemote()
        } catch {
            self.error = error
        }
    }

    private nonisolated func fetchPrayersFromCache(userId: UUID, dbQueue: DatabaseQueue) throws -> [SavedPrayer] {
        return try dbQueue.read { db in
            try SavedPrayer
                .filter(SavedPrayer.Columns.userId == userId)
                .filter(SavedPrayer.Columns.deletedAt == nil)
                .order(SavedPrayer.Columns.createdAt.desc)
                .fetchAll(db)
        }
    }

    private func loadFromCache(userId: UUID) throws {
        guard let dbQueue = db.dbQueue else { return }
        savedPrayers = try fetchPrayersFromCache(userId: userId, dbQueue: dbQueue)
    }

    private nonisolated func savePrayersToCache(_ dtos: [SavedPrayerDTO], dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            for dto in dtos {
                let prayer = SavedPrayer(from: dto)
                try prayer.save(db)
            }
        }
    }

    private func syncWithRemote() async throws {
        // Fetch from Supabase
        let remotePrayers = try await supabase.getSavedPrayers()

        // Update local cache
        guard let dbQueue = db.dbQueue else { return }
        try savePrayersToCache(remotePrayers, dbQueue: dbQueue)

        // Reload from cache
        if let userId = supabase.currentUser?.id {
            try loadFromCache(userId: userId)
        }

        // Push local changes
        try await pushLocalChanges()
    }

    private nonisolated func fetchPrayersNeedingSync(dbQueue: DatabaseQueue) throws -> [SavedPrayer] {
        return try dbQueue.read { db in
            try SavedPrayer
                .filter(SavedPrayer.Columns.needsSync == true)
                .fetchAll(db)
        }
    }

    private nonisolated func markPrayerSynced(_ prayer: SavedPrayer, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            var updated = prayer
            updated.needsSync = false
            try updated.update(db)
        }
    }

    private func pushLocalChanges() async throws {
        guard let dbQueue = db.dbQueue else { return }

        let prayersToSync = try fetchPrayersNeedingSync(dbQueue: dbQueue)

        for prayer in prayersToSync {
            if prayer.deletedAt != nil {
                try await supabase.deleteSavedPrayer(id: prayer.id.uuidString)
            } else {
                try await supabase.createSavedPrayer(prayer.toDTO())
            }

            try markPrayerSynced(prayer, dbQueue: dbQueue)
        }
    }

    // MARK: - Prayer DB Helpers

    private nonisolated func savePrayerToDB(_ prayer: SavedPrayer, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try prayer.save(db)
        }
    }

    private nonisolated func updatePrayerInDB(_ prayer: SavedPrayer, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try prayer.update(db)
        }
    }

    private nonisolated func softDeletePrayerInDB(_ prayer: SavedPrayer, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            var updated = prayer
            updated.deletedAt = Date()
            updated.needsSync = true
            try updated.update(db)
        }
    }

    // MARK: - CRUD Operations

    func savePrayer(_ prayer: Prayer) async throws {
        guard let userId = supabase.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        guard let dbQueue = db.dbQueue else { return }

        var savedPrayer = SavedPrayer(from: prayer, userId: userId)

        // Save locally
        try savePrayerToDB(savedPrayer, dbQueue: dbQueue)
        savedPrayers.insert(savedPrayer, at: 0)

        // Sync to remote
        do {
            try await supabase.createSavedPrayer(savedPrayer.toDTO())
            savedPrayer.needsSync = false
            try updatePrayerInDB(savedPrayer, dbQueue: dbQueue)
        } catch {
            // Will sync later
            self.error = error
        }
    }

    func deletePrayer(_ prayer: SavedPrayer) async throws {
        guard let dbQueue = db.dbQueue else { return }

        // Soft delete locally
        try softDeletePrayerInDB(prayer, dbQueue: dbQueue)
        savedPrayers.removeAll { $0.id == prayer.id }

        // Sync to remote
        do {
            try await supabase.deleteSavedPrayer(id: prayer.id.uuidString)
        } catch {
            self.error = error
        }
    }

    // MARK: - Queries

    func getPrayers(for tradition: PrayerTradition) -> [SavedPrayer] {
        savedPrayers.filter { $0.tradition == tradition }
    }

    func getRecentPrayers(limit: Int = 10) -> [SavedPrayer] {
        Array(savedPrayers.prefix(limit))
    }

    /// Search prayers using FTS5 full-text search
    /// Falls back to in-memory filtering if FTS5 query fails
    func searchPrayers(query: String) -> [SavedPrayer] {
        guard !query.isEmpty else { return savedPrayers }
        guard let userId = supabase.currentUser?.id,
              let dbQueue = db.dbQueue else {
            return fallbackSearch(query: query)
        }

        do {
            return try searchPrayersFTS5(query: query, userId: userId, dbQueue: dbQueue)
        } catch {
            // FTS5 failed (table not yet created, malformed query, etc.)
            // Fall back to in-memory search
            print("⚠️ PrayerService: FTS5 search failed, using fallback: \(error)")
            return fallbackSearch(query: query)
        }
    }

    /// FTS5 full-text search - returns matching prayers ordered by relevance
    private nonisolated func searchPrayersFTS5(
        query: String,
        userId: UUID,
        dbQueue: DatabaseQueue
    ) throws -> [SavedPrayer] {
        // Sanitize query for FTS5 (escape special characters)
        let sanitizedQuery = sanitizeFTS5Query(query)

        return try dbQueue.read { db in
            // Use FTS5 MATCH with JOIN to get full SavedPrayer records
            // bm25() provides relevance ranking (lower = more relevant)
            let sql = """
                SELECT saved_prayers.*
                FROM saved_prayers
                INNER JOIN saved_prayers_fts ON saved_prayers.rowid = saved_prayers_fts.rowid
                WHERE saved_prayers_fts MATCH ?
                  AND saved_prayers.user_id = ?
                  AND saved_prayers.deleted_at IS NULL
                ORDER BY bm25(saved_prayers_fts) ASC
                LIMIT 100
                """

            return try SavedPrayer.fetchAll(db, sql: sql, arguments: [sanitizedQuery, userId])
        }
    }

    /// Sanitize user input for FTS5 MATCH query
    /// Escapes special FTS5 operators and wraps terms in quotes for phrase matching
    private nonisolated func sanitizeFTS5Query(_ query: String) -> String {
        // Remove FTS5 special characters that could cause syntax errors
        let specialChars = CharacterSet(charactersIn: "\"*():-^")
        let cleaned = query.unicodeScalars
            .filter { !specialChars.contains($0) }
            .map { Character($0) }

        // Split into words and join with OR for broad matching
        let terms = String(cleaned)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        // Use prefix matching (*) for partial word matches
        return terms.map { "\($0)*" }.joined(separator: " OR ")
    }

    /// In-memory fallback search when FTS5 is unavailable
    private func fallbackSearch(query: String) -> [SavedPrayer] {
        savedPrayers.filter { prayer in
            prayer.content.localizedCaseInsensitiveContains(query) ||
            prayer.userContext.localizedCaseInsensitiveContains(query)
        }
    }
}

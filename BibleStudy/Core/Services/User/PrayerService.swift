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
    private let db = DatabaseManager.shared

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

    func searchPrayers(query: String) -> [SavedPrayer] {
        guard !query.isEmpty else { return savedPrayers }
        return savedPrayers.filter { prayer in
            prayer.content.localizedCaseInsensitiveContains(query) ||
            prayer.userContext.localizedCaseInsensitiveContains(query)
        }
    }
}

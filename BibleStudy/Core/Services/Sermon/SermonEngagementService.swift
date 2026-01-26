import Foundation

// MARK: - Sermon Engagement Service
// Manages user engagements with sermon content (commits, favorites, journal entries).
// UI-facing API on @MainActor, DB reads/writes dispatched off-main.

@MainActor
@Observable
final class SermonEngagementService {
    static let shared = SermonEngagementService()

    // MARK: - State

    /// In-memory cache of active engagements for the loaded sermon
    private(set) var engagements: [SermonEngagement] = []
    private var loadedSermonId: UUID?

    // MARK: - Loading

    func loadEngagements(sermonId: UUID) async {
        guard sermonId != loadedSermonId else { return }
        loadedSermonId = sermonId
        do {
            let fetched = try await Task.detached {
                try SermonRepository.shared.fetchEngagements(sermonId: sermonId)
            }.value
            // Only apply if we're still the current load (prevents stale overwrites)
            guard loadedSermonId == sermonId else { return }
            self.engagements = fetched
        } catch {
            print("[SermonEngagementService] Failed to load engagements: \(error)")
            // Only clear if we're still the current load (enables retry)
            if loadedSermonId == sermonId {
                loadedSermonId = nil
                self.engagements = []
            }
        }
    }

    /// Reset state (call on sign-out or sermon change)
    func reset() {
        engagements = []
        loadedSermonId = nil
    }

    // MARK: - Query

    func isCommitted(targetId: String) -> Bool {
        engagements.contains { $0.engagementType == .applicationCommit && $0.targetId == targetId && $0.isActive }
    }

    func isFavorited(type: EngagementType, targetId: String) -> Bool {
        engagements.contains { $0.engagementType == type && $0.targetId == targetId && $0.isActive }
    }

    func journalEntry(targetId: String) -> SermonEngagement? {
        engagements.first { $0.engagementType == .journalEntry && $0.targetId == targetId && $0.isActive }
    }

    // MARK: - Toggle Commit

    func toggleCommit(userId: UUID, sermonId: UUID, targetId: String) async {
        await toggle(userId: userId, sermonId: sermonId, type: .applicationCommit, targetId: targetId)
    }

    // MARK: - Toggle Favorite

    func toggleFavorite(userId: UUID, sermonId: UUID, type: EngagementType, targetId: String) async {
        await toggle(userId: userId, sermonId: sermonId, type: type, targetId: targetId)
    }

    // MARK: - Journal

    func saveJournalEntry(userId: UUID, sermonId: UUID, targetId: String, content: String) async {
        do {
            if var existing = try await findExisting(sermonId: sermonId, type: .journalEntry, targetId: targetId) {
                // Update existing journal entry
                existing.updateContent(content)
                if !existing.isActive { existing.restore() }
                try await persist(existing)
                updateCache(existing)
            } else {
                // Create new journal entry
                let engagement = SermonEngagement(
                    userId: userId,
                    sermonId: sermonId,
                    engagementType: .journalEntry,
                    targetId: targetId,
                    content: content,
                    needsSync: true
                )
                try await persist(engagement)
                engagements.append(engagement)
            }
        } catch {
            print("[SermonEngagementService] Failed to save journal: \(error)")
        }
    }

    // MARK: - Private

    private func toggle(userId: UUID, sermonId: UUID, type: EngagementType, targetId: String) async {
        do {
            if var existing = try await findExisting(sermonId: sermonId, type: type, targetId: targetId) {
                // Toggle soft-delete
                if existing.isActive {
                    existing.markDeleted()
                } else {
                    existing.restore()
                }
                try await persist(existing)
                updateCache(existing)
            } else {
                // Create new
                let engagement = SermonEngagement(
                    userId: userId,
                    sermonId: sermonId,
                    engagementType: type,
                    targetId: targetId,
                    needsSync: true
                )
                try await persist(engagement)
                engagements.append(engagement)
            }
        } catch {
            print("[SermonEngagementService] Failed to toggle \(type): \(error)")
        }
    }

    private func findExisting(sermonId: UUID, type: EngagementType, targetId: String) async throws -> SermonEngagement? {
        try await Task.detached {
            try SermonRepository.shared.findEngagement(sermonId: sermonId, type: type, targetId: targetId)
        }.value
    }

    private func persist(_ engagement: SermonEngagement) async throws {
        try await Task.detached {
            try SermonRepository.shared.upsertEngagement(engagement)
        }.value
    }

    private func updateCache(_ engagement: SermonEngagement) {
        if let index = engagements.firstIndex(where: { $0.id == engagement.id }) {
            if engagement.isActive {
                engagements[index] = engagement
            } else {
                engagements.remove(at: index)
            }
        } else if engagement.isActive {
            engagements.append(engagement)
        }
    }
}

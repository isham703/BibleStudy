//
//  SermonPinService.swift
//  BibleStudy
//
//  Manages pinned/favorite sermons
//  Stores pinned IDs in UserDefaults for simplicity
//  Can be enhanced with Supabase sync in future
//

import Foundation
import Combine

// MARK: - Sermon Pin Service

@MainActor
@Observable
final class SermonPinService {

    static let shared = SermonPinService()

    // MARK: - Properties

    private(set) var pinnedIds: Set<UUID> = []

    private let userDefaultsKey = "sermon_pinned_ids"

    // MARK: - Initialization

    private init() {
        loadPinnedIds()
    }

    // MARK: - Public API

    /// Check if a sermon is pinned
    func isPinned(_ sermonId: UUID) -> Bool {
        pinnedIds.contains(sermonId)
    }

    /// Toggle pin state for a sermon
    func togglePin(_ sermonId: UUID) {
        if pinnedIds.contains(sermonId) {
            unpin(sermonId)
        } else {
            pin(sermonId)
        }
    }

    /// Pin a sermon
    func pin(_ sermonId: UUID) {
        pinnedIds.insert(sermonId)
        savePinnedIds()
        HapticService.shared.selectionChanged()
    }

    /// Unpin a sermon
    func unpin(_ sermonId: UUID) {
        pinnedIds.remove(sermonId)
        savePinnedIds()
        HapticService.shared.selectionChanged()
    }

    /// Get pinned sermons from a list, maintaining pin order
    func pinnedSermons(from sermons: [Sermon]) -> [Sermon] {
        sermons.filter { pinnedIds.contains($0.id) }
    }

    /// Get unpinned sermons from a list
    func unpinnedSermons(from sermons: [Sermon]) -> [Sermon] {
        sermons.filter { !pinnedIds.contains($0.id) }
    }

    /// Clean up pins for deleted sermons
    func cleanupDeletedSermons(existingIds: Set<UUID>) {
        let orphanedPins = pinnedIds.subtracting(existingIds)
        if !orphanedPins.isEmpty {
            pinnedIds.subtract(orphanedPins)
            savePinnedIds()
        }
    }

    // MARK: - Persistence

    private func loadPinnedIds() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) else {
            pinnedIds = []
            return
        }
        pinnedIds = ids
    }

    private func savePinnedIds() {
        guard let data = try? JSONEncoder().encode(pinnedIds) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
}

// MARK: - Sermon Extension

extension Sermon {
    /// Check if this sermon is pinned
    var isPinned: Bool {
        SermonPinService.shared.isPinned(id)
    }
}

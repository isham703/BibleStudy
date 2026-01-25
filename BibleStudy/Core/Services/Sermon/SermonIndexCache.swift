//
//  SermonIndexCache.swift
//  BibleStudy
//
//  Lightweight index cache for fast sermon grouping
//  Builds index when sermons become Ready
//  Enables <100ms grouping for 500+ sermons
//

import Foundation
import GRDB

// MARK: - Sermon Index Cache

@MainActor
final class SermonIndexCache {

    static let shared = SermonIndexCache()

    private let db = DatabaseStore.shared

    private init() {}

    // MARK: - Index Building

    /// Build index entry for a single sermon
    func buildIndex(for sermon: Sermon) throws {
        let entry = SermonIndexEntry(from: sermon)
        try db.write { database in
            try entry.save(database)
        }
    }

    /// Rebuild index for multiple sermons
    func rebuildIndex(for sermons: [Sermon]) throws {
        try db.write { database in
            for sermon in sermons {
                let entry = SermonIndexEntry(from: sermon)
                try entry.save(database)
            }
        }
    }

    /// Remove index entry for a deleted sermon
    func removeIndex(for sermonId: UUID) throws {
        try db.write { database in
            try database.execute(
                sql: "DELETE FROM sermon_index WHERE id = ?",
                arguments: [sermonId]
            )
        }
    }

    /// Check if index needs update (sermon updated since last index)
    func needsUpdate(for sermon: Sermon) throws -> Bool {
        guard let entry = try fetchEntry(for: sermon.id) else {
            return true
        }
        return sermon.updatedAt > entry.sermonUpdatedAt
    }

    // MARK: - Index Queries

    /// Fetch single index entry
    func fetchEntry(for sermonId: UUID) throws -> SermonIndexEntry? {
        try db.read { database in
            try SermonIndexEntry.fetchOne(database, key: sermonId)
        }
    }

    /// Fetch all index entries
    func fetchAllEntries() throws -> [SermonIndexEntry] {
        try db.read { database in
            try SermonIndexEntry.fetchAll(database)
        }
    }

    /// Fetch entries sorted by date (newest first)
    func fetchEntriesByDate() throws -> [SermonIndexEntry] {
        try db.read { database in
            try SermonIndexEntry
                .order(SermonIndexEntry.Columns.recordedAt.desc)
                .fetchAll(database)
        }
    }

    /// Fetch entries grouped by speaker
    func fetchEntriesGroupedBySpeaker() throws -> [String: [SermonIndexEntry]] {
        let entries = try fetchAllEntries()
        var groups: [String: [SermonIndexEntry]] = [:]

        for entry in entries {
            let speaker = entry.speakerName ?? "Unknown Speaker"
            groups[speaker, default: []].append(entry)
        }

        return groups
    }

    /// Fetch entries grouped by scripture book
    func fetchEntriesGroupedByBook() throws -> [String: [SermonIndexEntry]] {
        let entries = try fetchAllEntries()
        var groups: [String: [SermonIndexEntry]] = [:]

        for entry in entries {
            if let primaryBook = entry.primaryBook {
                groups[primaryBook, default: []].append(entry)
            } else {
                groups["Other", default: []].append(entry)
            }
        }

        return groups
    }

    /// Get unique speaker names
    func fetchUniqueSpeakers() throws -> [String] {
        try db.read { database in
            let rows = try Row.fetchAll(database, sql: """
                SELECT DISTINCT speaker_name FROM sermon_index
                WHERE speaker_name IS NOT NULL
                ORDER BY speaker_name
            """)
            return rows.compactMap { $0["speaker_name"] as String? }
        }
    }

    /// Get unique scripture books
    func fetchUniqueBooks() throws -> [String] {
        let entries = try fetchAllEntries()
        var books = Set<String>()

        for entry in entries {
            for book in entry.parsedBooks {
                books.insert(book)
            }
        }

        return Array(books).sorted { book1, book2 in
            let order1 = ScriptureReferenceParser.bookOrder.firstIndex(of: book1) ?? 999
            let order2 = ScriptureReferenceParser.bookOrder.firstIndex(of: book2) ?? 999
            return order1 < order2
        }
    }

    // MARK: - Bulk Operations

    /// Clear all index entries
    func clearIndex() throws {
        try db.write { database in
            try database.execute(sql: "DELETE FROM sermon_index")
        }
    }

    /// Get count of indexed sermons
    func indexCount() throws -> Int {
        try db.read { database in
            try SermonIndexEntry.fetchCount(database)
        }
    }

    /// Sync index with current sermons (add missing, remove orphaned)
    func syncIndex(with sermons: [Sermon]) throws {
        let readySermons = sermons.filter { $0.isComplete }
        let currentIds = Set(readySermons.map { $0.id })

        try db.write { database in
            // Get existing index IDs
            let existingIds = try UUID.fetchAll(database, sql: """
                SELECT id FROM sermon_index
            """)
            let existingIdSet = Set(existingIds)

            // Remove orphaned entries (sermons deleted or no longer ready)
            let orphanedIds = existingIdSet.subtracting(currentIds)
            for id in orphanedIds {
                try database.execute(
                    sql: "DELETE FROM sermon_index WHERE id = ?",
                    arguments: [id]
                )
            }

            // Add/update entries for ready sermons
            for sermon in readySermons {
                let entry = SermonIndexEntry(from: sermon)
                try entry.save(database)
            }
        }
    }
}


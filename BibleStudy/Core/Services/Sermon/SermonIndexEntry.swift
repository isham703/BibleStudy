//
//  SermonIndexEntry.swift
//  BibleStudy
//
//  Lightweight index entry for fast sermon grouping
//  Cached metadata extracted when sermon becomes Ready
//

import Foundation
import GRDB

// MARK: - Sermon Index Entry

/// Lightweight cached metadata for fast sermon grouping/filtering
/// Built when sermon status changes to Ready, avoiding full study guide loads
struct SermonIndexEntry: Identifiable, Hashable, Sendable {
    let id: UUID // Same as sermon ID
    let speakerName: String?
    let parsedBooks: [String] // Canonical book names: ["Romans", "John"]
    let recordedAt: Date
    let durationSeconds: Int
    let displayTitle: String

    // Timestamps for cache invalidation
    let indexedAt: Date
    let sermonUpdatedAt: Date

    // MARK: - Initialization

    init(
        id: UUID,
        speakerName: String? = nil,
        parsedBooks: [String] = [],
        recordedAt: Date,
        durationSeconds: Int = 0,
        displayTitle: String,
        indexedAt: Date = Date(),
        sermonUpdatedAt: Date
    ) {
        self.id = id
        self.speakerName = speakerName
        self.parsedBooks = parsedBooks
        self.recordedAt = recordedAt
        self.durationSeconds = durationSeconds
        self.displayTitle = displayTitle
        self.indexedAt = indexedAt
        self.sermonUpdatedAt = sermonUpdatedAt
    }

    /// Create index entry from a sermon
    init(from sermon: Sermon) {
        self.id = sermon.id
        self.speakerName = sermon.speakerName
        self.parsedBooks = sermon.scriptureBooks
        self.recordedAt = sermon.recordedAt
        self.durationSeconds = sermon.durationSeconds
        self.displayTitle = sermon.displayTitle
        self.indexedAt = Date()
        self.sermonUpdatedAt = sermon.updatedAt
    }

    // MARK: - Computed Properties

    var primaryBook: String? {
        parsedBooks.first
    }

    var formattedDuration: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60
        let seconds = durationSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - GRDB Support

nonisolated extension SermonIndexEntry: FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "sermon_index" }

    enum Columns: String, ColumnExpression {
        case id
        case speakerName = "speaker_name"
        case parsedBooks = "parsed_books"
        case recordedAt = "recorded_at"
        case durationSeconds = "duration_seconds"
        case displayTitle = "display_title"
        case indexedAt = "indexed_at"
        case sermonUpdatedAt = "sermon_updated_at"
    }

    init(row: Row) {
        id = row[Columns.id]
        speakerName = row[Columns.speakerName]
        recordedAt = row[Columns.recordedAt]
        durationSeconds = row[Columns.durationSeconds]
        displayTitle = row[Columns.displayTitle]
        indexedAt = row[Columns.indexedAt]
        sermonUpdatedAt = row[Columns.sermonUpdatedAt]

        // Decode JSON array for parsed books
        if let booksString: String = row[Columns.parsedBooks],
           let data = booksString.data(using: .utf8),
           let books = try? JSONDecoder().decode([String].self, from: data) {
            parsedBooks = books
        } else {
            parsedBooks = []
        }
    }

    func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.speakerName] = speakerName
        container[Columns.recordedAt] = recordedAt
        container[Columns.durationSeconds] = durationSeconds
        container[Columns.displayTitle] = displayTitle
        container[Columns.indexedAt] = indexedAt
        container[Columns.sermonUpdatedAt] = sermonUpdatedAt

        // Encode parsed books as JSON array
        if let data = try? JSONEncoder().encode(parsedBooks),
           let jsonString = String(data: data, encoding: .utf8) {
            container[Columns.parsedBooks] = jsonString
        } else {
            container[Columns.parsedBooks] = "[]"
        }
    }
}

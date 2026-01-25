//
//  SermonThemeAssignment.swift
//  BibleStudy
//
//  GRDB model for sermon theme assignments.
//  Stores normalized themes with confidence and override state.
//

import Foundation
@preconcurrency import GRDB

// MARK: - Sermon Theme Assignment

struct SermonThemeAssignment: Identifiable, Hashable, Sendable {
    /// Composite ID from sermon and theme
    var id: String { "\(sermonId.uuidString)-\(theme)" }

    let sermonId: UUID
    let theme: String                       // NormalizedTheme.rawValue
    var confidence: Double
    var overrideState: ThemeOverrideState
    var sourceThemes: [String]              // Original AI theme strings
    var matchType: ThemeMatchType
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Initialization

    init(
        sermonId: UUID,
        theme: String,
        confidence: Double,
        overrideState: ThemeOverrideState = .auto,
        sourceThemes: [String],
        matchType: ThemeMatchType
    ) {
        self.sermonId = sermonId
        self.theme = theme
        self.confidence = confidence
        self.overrideState = overrideState
        self.sourceThemes = sourceThemes
        self.matchType = matchType
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Convenience

    /// Get the NormalizedTheme enum value
    var normalizedTheme: NormalizedTheme? {
        NormalizedTheme(rawValue: theme)
    }

    /// Whether this assignment should be visible in UI
    var isVisible: Bool {
        overrideState.isVisible
    }

    /// Primary source theme for display
    var primarySourceTheme: String? {
        sourceThemes.first
    }
}

// MARK: - GRDB Support

nonisolated extension SermonThemeAssignment: FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "sermon_themes" }

    enum Columns: String, ColumnExpression {
        case sermonId = "sermon_id"
        case theme
        case confidence
        case overrideState = "override_state"
        case sourceThemes = "source_themes"
        case matchType = "match_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(row: Row) throws {
        sermonId = try row[Columns.sermonId]
        theme = try row[Columns.theme]
        confidence = try row[Columns.confidence]
        overrideState = ThemeOverrideState(rawValue: row[Columns.overrideState]) ?? .auto
        matchType = ThemeMatchType(rawValue: row[Columns.matchType] ?? "exact") ?? .exact
        createdAt = try row[Columns.createdAt]
        updatedAt = try row[Columns.updatedAt]

        // Decode JSON array for source themes
        if let jsonString: String = row[Columns.sourceThemes],
           let data = jsonString.data(using: .utf8),
           let themes = try? JSONDecoder().decode([String].self, from: data) {
            sourceThemes = themes
        } else {
            sourceThemes = []
        }
    }

    func encode(to container: inout PersistenceContainer) throws {
        container[Columns.sermonId] = sermonId
        container[Columns.theme] = theme
        container[Columns.confidence] = confidence
        container[Columns.overrideState] = overrideState.rawValue
        container[Columns.matchType] = matchType.rawValue
        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt

        // Encode source themes as JSON
        if let data = try? JSONEncoder().encode(sourceThemes),
           let jsonString = String(data: data, encoding: .utf8) {
            container[Columns.sourceThemes] = jsonString
        } else {
            container[Columns.sourceThemes] = "[]"
        }
    }
}

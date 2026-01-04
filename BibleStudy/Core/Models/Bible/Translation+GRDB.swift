import Foundation
import GRDB

// MARK: - GRDB Support for Translation
// Separated into its own file to avoid circular reference issues with Swift 6 concurrency

extension Translation: FetchableRecord, PersistableRecord {
    nonisolated static var databaseTableName: String { "translations" }

    // Use ColumnExpression for GRDB compatibility
    enum DatabaseColumns: String, ColumnExpression {
        case id
        case name
        case abbreviation
        case language
        case translationInfo = "description"
        case copyright
        case isDefault = "is_default"
        case sortOrder = "sort_order"
        case isAvailable = "is_available"
    }

    nonisolated init(row: Row) {
        self.init(
            id: row[DatabaseColumns.id],
            name: row[DatabaseColumns.name],
            abbreviation: row[DatabaseColumns.abbreviation],
            language: row[DatabaseColumns.language],
            translationInfo: row[DatabaseColumns.translationInfo],
            copyright: row[DatabaseColumns.copyright],
            isDefault: row[DatabaseColumns.isDefault],
            sortOrder: row[DatabaseColumns.sortOrder],
            isAvailable: row[DatabaseColumns.isAvailable] ?? true
        )
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[DatabaseColumns.id] = id
        container[DatabaseColumns.name] = name
        container[DatabaseColumns.abbreviation] = abbreviation
        container[DatabaseColumns.language] = language
        container[DatabaseColumns.translationInfo] = translationInfo
        container[DatabaseColumns.copyright] = copyright
        container[DatabaseColumns.isDefault] = isDefault
        container[DatabaseColumns.sortOrder] = sortOrder
        container[DatabaseColumns.isAvailable] = isAvailable
    }
}

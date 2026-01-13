import Foundation

// MARK: - Highlight Library ViewModel
// Manages filtering, sorting, and grouping of highlights

@MainActor
@Observable
final class HighlightLibraryViewModel {
    // MARK: - Dependencies
    private let userContentService = UserContentService.shared
    private let bibleService = BibleService.shared

    // MARK: - Filter State
    var selectedColorFilter: HighlightColor? = nil {
        didSet { invalidateCache() }
    }
    var selectedCategoryFilter: HighlightCategory? = nil {
        didSet { invalidateCache() }
    }
    var sortOption: SortOption = .dateDescending {
        didSet { invalidateCache() }
    }
    var groupOption: GroupOption = .none {
        didSet { invalidateCache() }
    }
    var searchQuery: String = "" {
        didSet { invalidateCache() }
    }

    // MARK: - Cached Results (Performance Optimization)
    // These are recalculated only when filters change, not on every view access

    private var cachedFilteredHighlights: [Highlight]?
    private var cachedGroupedHighlights: [HighlightGroup]?
    private var cachedStats: HighlightStats?
    private var lastHighlightCount: Int = 0

    // MARK: - Computed Properties

    var allHighlights: [Highlight] {
        userContentService.highlights
    }

    var filteredHighlights: [Highlight] {
        // Invalidate cache if source data changed
        if allHighlights.count != lastHighlightCount {
            invalidateCache()
            lastHighlightCount = allHighlights.count
        }

        if let cached = cachedFilteredHighlights {
            return cached
        }

        var results = allHighlights

        // Apply color filter
        if let color = selectedColorFilter {
            results = results.filter { $0.color == color }
        }

        // Apply category filter
        if let category = selectedCategoryFilter {
            results = results.filter { $0.category == category }
        }

        // Apply search query
        if !searchQuery.isEmpty {
            results = results.filter { highlight in
                highlight.reference.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        // Apply sorting
        results = sort(results)

        cachedFilteredHighlights = results
        return results
    }

    var groupedHighlights: [HighlightGroup] {
        if let cached = cachedGroupedHighlights {
            return cached
        }

        let highlights = filteredHighlights
        let result: [HighlightGroup]

        switch groupOption {
        case .none:
            result = [HighlightGroup(title: nil, highlights: highlights)]

        case .book:
            let grouped = Dictionary(grouping: highlights) { $0.bookId }
            result = grouped.keys.sorted().compactMap { bookId in
                guard let book = Book.find(byId: bookId) else { return nil }
                return HighlightGroup(
                    title: book.name,
                    highlights: sort(grouped[bookId] ?? [])
                )
            }

        case .color:
            let grouped = Dictionary(grouping: highlights) { $0.color }
            result = HighlightColor.allCases.compactMap { color in
                guard let items = grouped[color], !items.isEmpty else { return nil }
                return HighlightGroup(
                    title: color.displayName,
                    color: color,
                    highlights: sort(items)
                )
            }

        case .category:
            let grouped = Dictionary(grouping: highlights) { $0.category }
            result = HighlightCategory.allCases.compactMap { category in
                guard let items = grouped[category], !items.isEmpty else { return nil }
                return HighlightGroup(
                    title: category.displayName,
                    category: category,
                    highlights: sort(items)
                )
            }

        case .date:
            let calendar = Calendar.current
            let grouped = Dictionary(grouping: highlights) { highlight in
                calendar.startOfDay(for: highlight.createdAt)
            }
            result = grouped.keys.sorted(by: >).map { date in
                HighlightGroup(
                    title: formatDate(date),
                    highlights: sort(grouped[date] ?? [])
                )
            }
        }

        cachedGroupedHighlights = result
        return result
    }

    var isEmpty: Bool {
        allHighlights.isEmpty
    }

    var hasActiveFilters: Bool {
        selectedColorFilter != nil || selectedCategoryFilter != nil || !searchQuery.isEmpty
    }

    // MARK: - Stats

    var highlightStats: HighlightStats {
        // Invalidate cache if source data changed
        if allHighlights.count != lastHighlightCount {
            invalidateCache()
            lastHighlightCount = allHighlights.count
        }

        if let cached = cachedStats {
            return cached
        }

        let highlights = allHighlights
        let stats = HighlightStats(
            total: highlights.count,
            byColor: Dictionary(grouping: highlights) { $0.color }.mapValues { $0.count },
            byCategory: Dictionary(grouping: highlights) { $0.category }.mapValues { $0.count }
        )
        cachedStats = stats
        return stats
    }

    // MARK: - Cache Management

    private func invalidateCache() {
        cachedFilteredHighlights = nil
        cachedGroupedHighlights = nil
        cachedStats = nil
    }

    // MARK: - Actions

    func clearFilters() {
        selectedColorFilter = nil
        selectedCategoryFilter = nil
        searchQuery = ""
    }

    func toggleColorFilter(_ color: HighlightColor) {
        if selectedColorFilter == color {
            selectedColorFilter = nil
        } else {
            selectedColorFilter = color
        }
    }

    func toggleCategoryFilter(_ category: HighlightCategory) {
        if selectedCategoryFilter == category {
            selectedCategoryFilter = nil
        } else {
            selectedCategoryFilter = category
        }
    }

    func deleteHighlight(_ highlight: Highlight) async {
        try? await userContentService.deleteHighlight(highlight)
    }

    // MARK: - Private Helpers

    private func sort(_ highlights: [Highlight]) -> [Highlight] {
        switch sortOption {
        case .dateDescending:
            return highlights.sorted { $0.createdAt > $1.createdAt }
        case .dateAscending:
            return highlights.sorted { $0.createdAt < $1.createdAt }
        case .bookOrder:
            return highlights.sorted {
                if $0.bookId != $1.bookId {
                    return $0.bookId < $1.bookId
                }
                if $0.chapter != $1.chapter {
                    return $0.chapter < $1.chapter
                }
                return $0.verseStart < $1.verseStart
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return date.formatted(.dateTime.weekday(.wide))
        } else {
            return date.formatted(.dateTime.month().day().year())
        }
    }
}

// MARK: - Supporting Types

enum SortOption: String, CaseIterable {
    case dateDescending = "Newest First"
    case dateAscending = "Oldest First"
    case bookOrder = "Book Order"

    var icon: String {
        switch self {
        case .dateDescending: return "arrow.down"
        case .dateAscending: return "arrow.up"
        case .bookOrder: return "book"
        }
    }
}

enum GroupOption: String, CaseIterable {
    case none = "None"
    case book = "Book"
    case color = "Color"
    case category = "Category"
    case date = "Date"

    var icon: String {
        switch self {
        case .none: return "list.bullet"
        case .book: return "book.closed"
        case .color: return "paintpalette"
        case .category: return "tag"
        case .date: return "calendar"
        }
    }
}

struct HighlightGroup: Identifiable {
    // Stable ID computed from grouping properties (not random UUID)
    // This prevents SwiftUI from recreating views when cache is invalidated
    let id: String
    let title: String?
    var color: HighlightColor?
    var category: HighlightCategory?
    let highlights: [Highlight]

    init(title: String?, color: HighlightColor? = nil, category: HighlightCategory? = nil, highlights: [Highlight]) {
        // Generate stable ID from grouping properties
        let colorPart = color?.rawValue ?? "none"
        let categoryPart = category?.rawValue ?? "none"
        let titlePart = title ?? "ungrouped"
        self.id = "group-\(titlePart)-\(colorPart)-\(categoryPart)"

        self.title = title
        self.color = color
        self.category = category
        self.highlights = highlights
    }
}

struct HighlightStats {
    let total: Int
    let byColor: [HighlightColor: Int]
    let byCategory: [HighlightCategory: Int]
}

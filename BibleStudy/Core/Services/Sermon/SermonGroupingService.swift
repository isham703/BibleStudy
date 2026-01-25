//
//  SermonGroupingService.swift
//  BibleStudy
//
//  Groups sermons by various criteria (date, scripture book, speaker)
//  Optimized for <100ms grouping of 500+ sermons
//  Uses SermonIndexCache for fast metadata access
//

import Foundation

// MARK: - Sermon Grouping Service

@MainActor
final class SermonGroupingService {

    static let shared = SermonGroupingService()

    private let indexCache = SermonIndexCache.shared

    private init() {}

    // MARK: - Index Management

    /// Ensure index is up-to-date with given sermons
    func syncIndex(with sermons: [Sermon]) {
        do {
            try indexCache.syncIndex(with: sermons)
        } catch {
            print("Failed to sync sermon index: \(error)")
        }
    }

    /// Update index for a single sermon (call when status changes to Ready)
    func updateIndex(for sermon: Sermon) {
        guard sermon.isComplete else { return }
        do {
            try indexCache.buildIndex(for: sermon)
        } catch {
            print("Failed to update sermon index: \(error)")
        }
    }

    /// Remove sermon from index (call when deleted)
    func removeFromIndex(sermonId: UUID) {
        do {
            try indexCache.removeIndex(for: sermonId)
        } catch {
            print("Failed to remove sermon from index: \(error)")
        }
    }

    // MARK: - Dependencies

    private let themeService = ThemeNormalizationService.shared

    // MARK: - Grouping

    /// Group sermons by the specified option
    func group(
        _ sermons: [Sermon],
        by option: SermonGroupOption,
        sortedBy sortOption: SermonSortOption = .newest,
        userId: UUID? = nil
    ) -> [SermonGroup] {
        // First sort the sermons
        let sorted = sort(sermons, by: sortOption)

        // Then group
        switch option {
        case .none:
            return [SermonGroup(id: "all", title: "All Sermons", sermons: sorted)]

        case .date:
            return groupByDate(sorted)

        case .book:
            return groupByScriptureBook(sorted)

        case .speaker:
            return groupBySpeaker(sorted)

        case .theme:
            return groupByTheme(sorted, userId: userId)
        }
    }

    // MARK: - Sorting

    /// Sort sermons by the specified option
    func sort(_ sermons: [Sermon], by option: SermonSortOption) -> [Sermon] {
        switch option {
        case .newest:
            return sermons.sorted { $0.recordedAt > $1.recordedAt }

        case .oldest:
            return sermons.sorted { $0.recordedAt < $1.recordedAt }

        case .title:
            return sermons.sorted { $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending }

        case .duration:
            return sermons.sorted { $0.durationSeconds > $1.durationSeconds }
        }
    }

    // MARK: - Date Grouping

    private func groupByDate(_ sermons: [Sermon]) -> [SermonGroup] {
        var groups: [String: [Sermon]] = [:]
        var groupOrder: [String] = []

        for sermon in sermons {
            let key = dateGroupKey(for: sermon.recordedAt)

            if groups[key] == nil {
                groupOrder.append(key)
                groups[key] = []
            }
            groups[key]?.append(sermon)
        }

        return groupOrder.compactMap { key in
            guard let sermons = groups[key], !sermons.isEmpty else { return nil }
            return SermonGroup(id: key, title: key, sermons: sermons)
        }
    }

    private func dateGroupKey(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return "This Week"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .month) {
            return "This Month"
        } else {
            // Check if last month
            if let lastMonth = calendar.date(byAdding: .month, value: -1, to: now),
               calendar.isDate(date, equalTo: lastMonth, toGranularity: .month) {
                return "Last Month"
            }

            // Use month and year for older dates
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
    }

    // MARK: - Scripture Book Grouping

    private func groupByScriptureBook(_ sermons: [Sermon]) -> [SermonGroup] {
        var groups: [String: [Sermon]] = [:]
        var ungrouped: [Sermon] = []

        for sermon in sermons {
            if let book = sermon.primaryScriptureBook {
                if groups[book] == nil {
                    groups[book] = []
                }
                groups[book]?.append(sermon)
            } else {
                ungrouped.append(sermon)
            }
        }

        // Sort groups by canonical book order
        var result: [SermonGroup] = ScriptureReferenceParser.bookOrder.compactMap { book in
            guard let sermons = groups[book], !sermons.isEmpty else { return nil }
            return SermonGroup(id: book, title: book, sermons: sermons)
        }

        // Add ungrouped at the end
        if !ungrouped.isEmpty {
            result.append(SermonGroup(
                id: "ungrouped",
                title: "Other",
                sermons: ungrouped
            ))
        }

        return result
    }

    // MARK: - Speaker Grouping

    private func groupBySpeaker(_ sermons: [Sermon]) -> [SermonGroup] {
        var groups: [String: [Sermon]] = [:]
        var groupOrder: [String] = []

        for sermon in sermons {
            let speaker = sermon.speakerName ?? "Unknown Speaker"

            if groups[speaker] == nil {
                groupOrder.append(speaker)
                groups[speaker] = []
            }
            groups[speaker]?.append(sermon)
        }

        // Sort by speaker name alphabetically
        let sortedKeys = groupOrder.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }

        return sortedKeys.compactMap { speaker in
            guard let sermons = groups[speaker], !sermons.isEmpty else { return nil }
            return SermonGroup(id: speaker, title: speaker, sermons: sermons)
        }
    }

    // MARK: - Theme Grouping

    /// Primary-only grouping: each sermon appears in ONE theme group
    private func groupByTheme(_ sermons: [Sermon], userId: UUID?) -> [SermonGroup] {
        // Trigger lazy backfill if we have a userId
        if let userId = userId, !themeService.isBackfilling {
            themeService.triggerBackfillIfNeeded(userId: userId)
        }

        var groups: [NormalizedTheme: [Sermon]] = [:]
        var ungrouped: [Sermon] = []

        for sermon in sermons {
            let themes = themeService.themes(for: sermon.id)

            // Primary-only: use first (highest confidence) theme
            if let primaryTheme = themes.first {
                groups[primaryTheme, default: []].append(sermon)
            } else {
                ungrouped.append(sermon)
            }
        }

        // Sort groups by sermon count (most popular first)
        var result = groups.map { theme, sermons in
            SermonGroup(
                id: theme.rawValue,
                title: theme.displayName,
                icon: theme.icon,
                sermons: sermons
            )
        }.sorted { $0.sermons.count > $1.sermons.count }

        // Add ungrouped at end (if any)
        if !ungrouped.isEmpty {
            result.append(SermonGroup(
                id: "ungrouped",
                title: "Uncategorized",
                icon: "questionmark.circle",
                sermons: ungrouped
            ))
        }

        return result
    }

    // MARK: - Statistics

    /// Get counts for each group option (for UI display)
    func groupCounts(for sermons: [Sermon]) -> [SermonGroupOption: Int] {
        var counts: [SermonGroupOption: Int] = [:]

        // Date groups
        var dateKeys = Set<String>()
        for sermon in sermons {
            dateKeys.insert(dateGroupKey(for: sermon.recordedAt))
        }
        counts[.date] = dateKeys.count

        // Book groups
        var bookKeys = Set<String>()
        for sermon in sermons {
            if let book = sermon.primaryScriptureBook {
                bookKeys.insert(book)
            }
        }
        counts[.book] = bookKeys.count

        // Speaker groups
        var speakerKeys = Set<String>()
        for sermon in sermons {
            speakerKeys.insert(sermon.speakerName ?? "Unknown Speaker")
        }
        counts[.speaker] = speakerKeys.count

        // Theme groups
        var themeKeys = Set<NormalizedTheme>()
        for sermon in sermons {
            if let theme = themeService.primaryTheme(for: sermon.id) {
                themeKeys.insert(theme)
            }
        }
        counts[.theme] = themeKeys.count

        return counts
    }

    // MARK: - Fast Index-Based Queries

    /// Get group counts from index cache (faster than loading full sermons)
    func cachedGroupCounts() -> [SermonGroupOption: Int] {
        var counts: [SermonGroupOption: Int] = [:]

        do {
            let entries = try indexCache.fetchAllEntries()

            // Date groups
            var dateKeys = Set<String>()
            for entry in entries {
                dateKeys.insert(dateGroupKey(for: entry.recordedAt))
            }
            counts[.date] = dateKeys.count

            // Book groups
            var bookKeys = Set<String>()
            for entry in entries {
                if let book = entry.primaryBook {
                    bookKeys.insert(book)
                }
            }
            counts[.book] = bookKeys.count

            // Speaker groups
            var speakerKeys = Set<String>()
            for entry in entries {
                speakerKeys.insert(entry.speakerName ?? "Unknown Speaker")
            }
            counts[.speaker] = speakerKeys.count

        } catch {
            print("Failed to get cached group counts: \(error)")
        }

        return counts
    }

    /// Get unique speakers from index cache
    func cachedSpeakers() -> [String] {
        do {
            return try indexCache.fetchUniqueSpeakers()
        } catch {
            print("Failed to get cached speakers: \(error)")
            return []
        }
    }

    /// Get unique scripture books from index cache
    func cachedBooks() -> [String] {
        do {
            return try indexCache.fetchUniqueBooks()
        } catch {
            print("Failed to get cached books: \(error)")
            return []
        }
    }

    /// Get total indexed sermon count
    func indexedSermonCount() -> Int {
        do {
            return try indexCache.indexCount()
        } catch {
            print("Failed to get indexed sermon count: \(error)")
            return 0
        }
    }
}

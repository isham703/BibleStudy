import SwiftUI

// MARK: - Notes Library View Model
// Manages state for the notes library with filtering, sorting, and grouping
// Provides hierarchical organization (Book > Chapter > Notes)

@Observable
@MainActor
final class NotesLibraryViewModel {
    // MARK: - Dependencies
    private let userContentService: UserContentService

    // MARK: - State
    var notes: [Note] = []
    var isLoading: Bool = false
    var error: Error?

    // MARK: - Filter/Sort Options
    var selectedTemplateFilter: NoteTemplate? {
        didSet { invalidateCache() }
    }
    var sortOption: NoteSortOption = .recentlyUpdated {
        didSet { invalidateCache() }
    }
    var groupOption: NoteGroupOption = .book {
        didSet { invalidateCache() }
    }
    var searchQuery: String = "" {
        didSet { invalidateCache() }
    }

    // MARK: - Cache
    private var cachedFilteredNotes: [Note]?
    private var cachedGroupedNotes: [NoteGroup]?

    // MARK: - Computed Properties

    /// Filtered notes based on template and search query
    var filteredNotes: [Note] {
        if let cached = cachedFilteredNotes {
            return cached
        }

        var result = notes

        // Apply template filter
        if let template = selectedTemplateFilter {
            result = result.filter { $0.template == template }
        }

        // Apply search query
        if !searchQuery.isEmpty {
            result = result.filter { note in
                note.reference.localizedCaseInsensitiveContains(searchQuery) ||
                note.content.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        // Apply sorting
        result = sortNotes(result)

        cachedFilteredNotes = result
        return result
    }

    /// Notes grouped by book (hierarchical: Book > Chapter > Notes)
    var groupedNotes: [NoteGroup] {
        if let cached = cachedGroupedNotes {
            return cached
        }

        let notes = filteredNotes

        switch groupOption {
        case .none:
            let group = NoteGroup(title: nil, template: nil, chapters: nil, notes: notes)
            cachedGroupedNotes = [group]
            return [group]

        case .book:
            let grouped = Dictionary(grouping: notes) { $0.bookId }
            let groups = grouped.map { bookId, bookNotes -> NoteGroup in
                let book = Book.find(byId: bookId)
                let chapters = Dictionary(grouping: bookNotes) { $0.chapter }
                    .map { chapter, chapterNotes -> ChapterSubgroup in
                        ChapterSubgroup(chapter: chapter, notes: chapterNotes)
                    }
                    .sorted { $0.chapter < $1.chapter }
                return NoteGroup(
                    title: book?.name ?? "Unknown Book",
                    template: nil,
                    chapters: chapters,
                    notes: bookNotes
                )
            }
            .sorted { ($0.notes.first?.bookId ?? 0) < ($1.notes.first?.bookId ?? 0) }
            cachedGroupedNotes = groups
            return groups

        case .template:
            let grouped = Dictionary(grouping: notes) { $0.template }
            let groups = grouped.map { template, templateNotes -> NoteGroup in
                NoteGroup(
                    title: template.displayName,
                    template: template,
                    chapters: nil,
                    notes: templateNotes
                )
            }
            .sorted { $0.title ?? "" < $1.title ?? "" }
            cachedGroupedNotes = groups
            return groups

        case .date:
            // Group by month
            let calendar = Calendar.current
            let grouped = Dictionary(grouping: notes) { note -> String in
                let components = calendar.dateComponents([.year, .month], from: note.updatedAt)
                let date = calendar.date(from: components) ?? note.updatedAt
                return date.formatted(.dateTime.month(.wide).year())
            }
            let groups = grouped.map { dateString, dateNotes -> NoteGroup in
                NoteGroup(title: dateString, template: nil, chapters: nil, notes: dateNotes)
            }
            .sorted { group1, group2 in
                (group1.notes.first?.updatedAt ?? Date.distantPast) > (group2.notes.first?.updatedAt ?? Date.distantPast)
            }
            cachedGroupedNotes = groups
            return groups
        }
    }

    /// Statistics for template counts (for filter chips)
    var noteStats: NoteStats {
        var stats = NoteStats()
        for note in notes {
            stats.total += 1
            switch note.template {
            case .freeform: stats.freeform += 1
            case .observation: stats.observation += 1
            case .application: stats.application += 1
            case .questions: stats.questions += 1
            case .exegesis: stats.exegesis += 1
            case .prayer: stats.prayer += 1
            }
        }
        return stats
    }

    var isEmpty: Bool {
        notes.isEmpty
    }

    var isSearchEmpty: Bool {
        !searchQuery.isEmpty && filteredNotes.isEmpty
    }

    // MARK: - Initialization

    init(userContentService: UserContentService? = nil) {
        self.userContentService = userContentService ?? UserContentService.shared
    }

    // MARK: - Loading

    func load() async {
        isLoading = true
        error = nil

        await userContentService.loadContent()
        notes = userContentService.notes
        invalidateCache()

        isLoading = false
    }

    // MARK: - Actions

    func deleteNote(_ note: Note) async {
        do {
            try await userContentService.deleteNote(note)
            notes.removeAll { $0.id == note.id }
            invalidateCache()
        } catch {
            self.error = error
        }
    }

    // MARK: - Helpers

    private func invalidateCache() {
        cachedFilteredNotes = nil
        cachedGroupedNotes = nil
    }

    private func sortNotes(_ notes: [Note]) -> [Note] {
        switch sortOption {
        case .recentlyUpdated:
            return notes.sorted { $0.updatedAt > $1.updatedAt }
        case .recentlyCreated:
            return notes.sorted { $0.createdAt > $1.createdAt }
        case .bookOrder:
            return notes.sorted { note1, note2 in
                if note1.bookId != note2.bookId {
                    return note1.bookId < note2.bookId
                }
                if note1.chapter != note2.chapter {
                    return note1.chapter < note2.chapter
                }
                return note1.verseStart < note2.verseStart
            }
        }
    }
}

// MARK: - Sort Option

enum NoteSortOption: String, CaseIterable {
    case recentlyUpdated = "Recently Updated"
    case recentlyCreated = "Recently Created"
    case bookOrder = "Book Order"

    var icon: String {
        switch self {
        case .recentlyUpdated: return "clock.arrow.circlepath"
        case .recentlyCreated: return "calendar"
        case .bookOrder: return "book"
        }
    }
}

// MARK: - Group Option

enum NoteGroupOption: String, CaseIterable {
    case none = "None"
    case book = "By Book"
    case template = "By Template"
    case date = "By Date"

    var icon: String {
        switch self {
        case .none: return "list.bullet"
        case .book: return "book"
        case .template: return "doc.text"
        case .date: return "calendar"
        }
    }
}

// MARK: - Note Group

struct NoteGroup: Identifiable {
    let id = UUID()
    let title: String?
    var template: NoteTemplate?
    var chapters: [ChapterSubgroup]?
    let notes: [Note]
}

// MARK: - Chapter Subgroup

struct ChapterSubgroup: Identifiable {
    var id: Int { chapter }
    let chapter: Int
    let notes: [Note]
}

// MARK: - Note Stats

struct NoteStats {
    var total: Int = 0
    var freeform: Int = 0
    var observation: Int = 0
    var application: Int = 0
    var questions: Int = 0
    var exegesis: Int = 0
    var prayer: Int = 0

    func count(for template: NoteTemplate?) -> Int {
        guard let template = template else { return total }
        switch template {
        case .freeform: return freeform
        case .observation: return observation
        case .application: return application
        case .questions: return questions
        case .exegesis: return exegesis
        case .prayer: return prayer
        }
    }
}

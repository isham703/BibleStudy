//
//  SermonNotesViewModel.swift
//  BibleStudy
//
//  Manages search, filter, and quick recap state for sermon notes.
//  Filter-in-place: sections are shown/hidden based on current filter + search.
//

import SwiftUI

// MARK: - Sermon Notes View Model

@Observable
@MainActor
final class SermonNotesViewModel {
    // MARK: - State

    var searchQuery: String = "" {
        didSet { scheduleSearch() }
    }
    var selectedFilter: SermonSectionFilter = .all
    var isQuickRecapMode: Bool = false

    // MARK: - Internal

    private var debouncedQuery: String = ""
    private var searchTask: Task<Void, Never>?

    // MARK: - Data Sources

    private(set) var studyGuide: SermonStudyGuide?

    // MARK: - Initialization

    init(studyGuide: SermonStudyGuide? = nil) {
        self.studyGuide = studyGuide
    }

    // MARK: - Computed

    /// Sections currently visible based on filter, search, and recap mode.
    var visibleSections: Set<SermonSectionID> {
        computeVisibleSections()
    }

    /// Whether a search is actively filtering content.
    var isSearchActive: Bool { !debouncedQuery.isEmpty }

    /// Sections available for jump bar (only those currently visible).
    var jumpBarSections: [SermonSectionID] {
        SermonSectionID.allCases.filter { visibleSections.contains($0) }
    }

    /// Number of sections matching the current search query.
    var matchingSectionCount: Int {
        guard isSearchActive else { return 0 }
        return visibleSections.count
    }

    // MARK: - Update

    func update(studyGuide: SermonStudyGuide) {
        self.studyGuide = studyGuide
    }

    func clearSearch() {
        searchQuery = ""
        debouncedQuery = ""
        searchTask?.cancel()
    }

    // MARK: - Section Visibility Check

    func isSectionVisible(_ section: SermonSectionID) -> Bool {
        visibleSections.contains(section)
    }

    // MARK: - Private

    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }
            debouncedQuery = searchQuery
        }
    }

    private func computeVisibleSections() -> Set<SermonSectionID> {
        guard let guide = studyGuide else { return [] }
        let content = guide.content

        // Quick recap: curated subset (still apply search filtering)
        if isQuickRecapMode {
            var sections = computeRecapSections(content)
            if !debouncedQuery.isEmpty {
                sections = sections.filter { sectionMatchesQuery($0, content: content, query: debouncedQuery) }
            }
            return sections
        }

        // Start with all sections that have content
        var sections = availableSections(content)

        // Apply section filter
        if selectedFilter != .all {
            sections = sections.intersection(selectedFilter.sectionIDs)
        }

        // Apply search query
        if !debouncedQuery.isEmpty {
            sections = sections.filter { sectionMatchesQuery($0, content: content, query: debouncedQuery) }
        }

        return sections
    }

    private func availableSections(_ content: StudyGuideContent) -> Set<SermonSectionID> {
        var sections: Set<SermonSectionID> = [.summary]

        if let t = content.keyTakeaways, !t.isEmpty { sections.insert(.keyTakeaways) }
        if let q = content.notableQuotes, !q.isEmpty { sections.insert(.notableQuotes) }
        if !content.bibleReferencesMentioned.isEmpty || !content.bibleReferencesSuggested.isEmpty {
            sections.insert(.scriptureReferences)
        }
        if let a = content.theologicalAnnotations, !a.isEmpty { sections.insert(.theologicalDepth) }
        if !content.discussionQuestions.isEmpty { sections.insert(.discussionQuestions) }
        if !content.reflectionPrompts.isEmpty { sections.insert(.reflectionPrompts) }
        if !content.applicationPoints.isEmpty ||
            content.anchoredApplicationPoints.map({ !$0.isEmpty }) == true {
            sections.insert(.applicationPoints)
        }

        return sections
    }

    private func computeRecapSections(_ content: StudyGuideContent) -> Set<SermonSectionID> {
        var sections: Set<SermonSectionID> = [.summary]
        if let takeaways = content.keyTakeaways, !takeaways.isEmpty { sections.insert(.keyTakeaways) }
        if let q = content.notableQuotes, !q.isEmpty { sections.insert(.notableQuotes) }
        if !content.applicationPoints.isEmpty ||
            content.anchoredApplicationPoints.map({ !$0.isEmpty }) == true {
            sections.insert(.applicationPoints)
        }
        return sections
    }

    // MARK: - Search Matching

    private func sectionMatchesQuery(_ section: SermonSectionID, content: StudyGuideContent, query: String) -> Bool {
        switch section {
        case .summary:
            return content.title.localizedCaseInsensitiveContains(query) ||
                content.summary.localizedCaseInsensitiveContains(query) ||
                content.centralThesis?.localizedCaseInsensitiveContains(query) == true ||
                content.keyThemes.contains { $0.localizedCaseInsensitiveContains(query) }
        case .keyTakeaways:
            return content.keyTakeaways?.contains {
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.insight.localizedCaseInsensitiveContains(query)
            } == true
        case .notableQuotes:
            return content.notableQuotes?.contains {
                $0.text.localizedCaseInsensitiveContains(query) ||
                $0.context?.localizedCaseInsensitiveContains(query) == true
            } == true
        case .scriptureReferences:
            return content.bibleReferencesMentioned.contains {
                $0.reference.localizedCaseInsensitiveContains(query)
            } ||
            content.bibleReferencesSuggested.contains {
                $0.reference.localizedCaseInsensitiveContains(query)
            }
        case .theologicalDepth:
            return content.theologicalAnnotations?.contains {
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.insight.localizedCaseInsensitiveContains(query)
            } == true
        case .discussionQuestions:
            return content.discussionQuestions.contains {
                $0.question.localizedCaseInsensitiveContains(query)
            }
        case .reflectionPrompts:
            return content.reflectionPrompts.contains {
                $0.localizedCaseInsensitiveContains(query)
            }
        case .applicationPoints:
            return content.applicationPoints.contains {
                $0.localizedCaseInsensitiveContains(query)
            } ||
            content.anchoredApplicationPoints?.contains {
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.insight.localizedCaseInsensitiveContains(query)
            } == true
        }
    }
}

// MARK: - Section Filter

enum SermonSectionFilter: String, CaseIterable, Identifiable {
    case all
    case takeaways
    case quotes
    case scripture
    case questions
    case prompts
    case actions
    case theological

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .all: return "All"
        case .takeaways: return "Takeaways"
        case .quotes: return "Quotes"
        case .scripture: return "Scripture"
        case .questions: return "Questions"
        case .prompts: return "Prompts"
        case .actions: return "Actions"
        case .theological: return "Theology"
        }
    }

    /// Maps this filter to the section IDs it includes.
    var sectionIDs: Set<SermonSectionID> {
        switch self {
        case .all: return Set(SermonSectionID.allCases)
        case .takeaways: return [.keyTakeaways]
        case .quotes: return [.notableQuotes]
        case .scripture: return [.scriptureReferences]
        case .questions: return [.discussionQuestions]
        case .prompts: return [.reflectionPrompts]
        case .actions: return [.applicationPoints]
        case .theological: return [.theologicalDepth]
        }
    }
}

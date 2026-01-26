//
//  SermonSectionID.swift
//  BibleStudy
//
//  Section identifiers for sermon notes navigation.
//  Used by SectionJumpBar for scroll-to navigation.
//

import SwiftUI

// MARK: - Sermon Section ID

enum SermonSectionID: String, CaseIterable, Identifiable {
    case summary
    case keyTakeaways
    case notableQuotes
    case scriptureReferences
    case theologicalDepth
    case discussionQuestions
    case reflectionPrompts
    case applicationPoints

    var id: String { rawValue }

    /// Short display label for jump bar chips
    var displayLabel: String {
        switch self {
        case .summary: return "Summary"
        case .keyTakeaways: return "Takeaways"
        case .notableQuotes: return "Quotes"
        case .scriptureReferences: return "Scripture"
        case .theologicalDepth: return "Theology"
        case .discussionQuestions: return "Questions"
        case .reflectionPrompts: return "Prompts"
        case .applicationPoints: return "Actions"
        }
    }

    /// SF Symbol icon for jump bar chips
    var icon: String {
        switch self {
        case .summary: return "doc.text"
        case .keyTakeaways: return "lightbulb"
        case .notableQuotes: return "quote.opening"
        case .scriptureReferences: return "book.closed"
        case .theologicalDepth: return "building.columns"
        case .discussionQuestions: return "bubble.left.and.bubble.right"
        case .reflectionPrompts: return "heart.text.square"
        case .applicationPoints: return "hand.raised"
        }
    }
}

// MARK: - Section Visibility Tracking

/// Preference value for tracking section scroll positions.
struct SectionVisibilityPreference: Equatable {
    let sectionID: SermonSectionID
    let minY: CGFloat
}

/// PreferenceKey for collecting section visibility data during scroll.
struct SectionVisibilityPreferenceKey: PreferenceKey {
    static var defaultValue: [SectionVisibilityPreference] = []

    static func reduce(value: inout [SectionVisibilityPreference], nextValue: () -> [SectionVisibilityPreference]) {
        value.append(contentsOf: nextValue())
    }
}

// MARK: - Section Tracking Modifier

extension View {
    /// Reports this view's scroll position for section tracking.
    func trackSectionVisibility(_ sectionID: SermonSectionID, in coordinateSpace: String) -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: SectionVisibilityPreferenceKey.self,
                    value: [SectionVisibilityPreference(
                        sectionID: sectionID,
                        minY: geo.frame(in: .named(coordinateSpace)).minY
                    )]
                )
            }
        )
    }
}

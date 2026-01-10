import SwiftUI

// MARK: - Trust UX Components
// Components for displaying AI reasoning and grounding to build user trust

// MARK: - Show Why Expander
/// Expandable section that shows the reasoning behind AI-generated insights
struct ShowWhyExpander: View {
    @Environment(\.colorScheme) private var colorScheme
    let reasoning: [ReasoningPoint]
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Expand/Collapse Button
            Button {
                withAnimation(Theme.Animation.fade) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    Text("Why this interpretation?")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .buttonStyle(.plain)

            // Reasoning Content
            if isExpanded {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    ForEach(reasoning) { point in
                        ReasoningPointView(point: point)
                    }
                }
                .padding(Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(Color.surfaceBackground)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Reasoning Point View
struct ReasoningPointView: View {
    @Environment(\.colorScheme) private var colorScheme
    let point: ReasoningPoint

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // The phrase from the text
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "text.quote")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                Text("\"\(point.phrase)\"")
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(Color.primaryText)
                    .italic()
            }

            // Why it's significant
            Text(point.explanation)
                .font(Typography.Command.caption)
                .foregroundStyle(Color.secondaryText)
                .padding(.leading, Theme.Spacing.lg)
        }
    }
}

// MARK: - Different Views Section
/// Collapsible section showing alternative interpretive views
struct DifferentViewsSection: View {
    let views: [AlternativeView]
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header with expand toggle
            Button {
                withAnimation(Theme.Animation.fade) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundStyle(Color.info)
                    Text("Different interpretive views")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.info)
                    Spacer()
                    Text("\(views.count)")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.tertiaryText)
                        .padding(.horizontal, Theme.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.info.opacity(Theme.Opacity.lightMedium))
                        )
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .buttonStyle(.plain)

            // Views Content
            if isExpanded {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    ForEach(views) { view in
                        AlternativeViewCard(view: view)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Alternative View Card
struct AlternativeViewCard: View {
    let view: AlternativeView

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // View name
            Text(view.viewName)
                .font(Typography.Command.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primaryText)

            // Summary
            Text(view.summary)
                .font(Typography.Command.body)
                .foregroundStyle(Color.secondaryText)

            // Traditions (if available)
            if let traditions = view.traditions, !traditions.isEmpty {
                HStack(spacing: Theme.Spacing.xs) {
                    Text("Traditions:")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.tertiaryText)
                    Text(traditions.joined(separator: ", "))
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.secondaryText)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .stroke(Color.cardBorder, lineWidth: Theme.Stroke.hairline)
        )
    }
}

// MARK: - Translation Notes Section
/// Collapsible section showing translation differences
struct TranslationNotesSection: View {
    @Environment(\.colorScheme) private var colorScheme
    let notes: [TranslationNote]
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header with expand toggle
            Button {
                withAnimation(Theme.Animation.fade) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "character.book.closed")
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    Text("Translation differences")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    Spacer()
                    Text("\(notes.count)")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.tertiaryText)
                        .padding(.horizontal, Theme.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium))
                        )
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .buttonStyle(.plain)

            // Notes Content
            if isExpanded {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    ForEach(notes) { note in
                        TranslationNoteCard(note: note)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Translation Note Card
struct TranslationNoteCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let note: TranslationNote

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // The phrase
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "text.quote")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                Text("\"\(note.phrase)\"")
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(Color.primaryText)
                    .italic()
            }

            // Translation variants
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                ForEach(note.translations, id: \.self) { translation in
                    HStack(spacing: Theme.Spacing.xs) {
                        Circle()
                            .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                            .frame(width: 6, height: 6)
                        Text(translation)
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color.secondaryText)
                    }
                }
            }
            .padding(.leading, Theme.Spacing.md)

            // Explanation
            Text(note.explanation)
                .font(Typography.Command.caption)
                .foregroundStyle(Color.tertiaryText)
                .padding(.leading, Theme.Spacing.md)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .stroke(Color.cardBorder, lineWidth: Theme.Stroke.hairline)
        )
    }
}

// MARK: - Grounding Sources Row
/// Displays the sources used to generate AI content (for trust UX)
struct GroundingSourcesRow: View {
    let sources: [String]

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "checkmark.shield")
                .font(Typography.Command.meta)
            Text("Based on: \(sources.joined(separator: ", "))")
                .font(Typography.Command.meta)
        }
        .foregroundStyle(Color.tertiaryText)
    }
}

// MARK: - Previews
#Preview("Show Why Expander") {
    VStack(spacing: Theme.Spacing.xl) {
        ShowWhyExpander(reasoning: [
            ReasoningPoint(
                phrase: "Let there be light",
                explanation: "The jussive form indicates a divine command, not a wish. God's word has creative power."
            ),
            ReasoningPoint(
                phrase: "and there was light",
                explanation: "The immediate fulfillment shows the effectiveness of God's word - creation responds instantly."
            )
        ])
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Different Views Section") {
    VStack(spacing: Theme.Spacing.xl) {
        DifferentViewsSection(views: [
            AlternativeView(
                viewName: "Literal Day View",
                summary: "The six days of creation were literal 24-hour periods.",
                traditions: ["Young Earth Creationism", "Many Protestant traditions"]
            ),
            AlternativeView(
                viewName: "Day-Age View",
                summary: "Each 'day' represents a long period of time, possibly millions of years.",
                traditions: ["Old Earth Creationism", "Some Catholic theologians"]
            ),
            AlternativeView(
                viewName: "Literary Framework View",
                summary: "The creation account is structured poetically, not chronologically.",
                traditions: ["Some Reformed scholars", "Academic theologians"]
            )
        ])
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Grounding Sources") {
    GroundingSourcesRow(sources: ["Selected passage text", "Cross-reference database", "Original language lexicon"])
        .padding()
        .background(Color.appBackground)
}

#Preview("Translation Notes") {
    VStack(spacing: Theme.Spacing.xl) {
        TranslationNotesSection(notes: [
            TranslationNote(
                phrase: "charity",
                translations: ["KJV: charity", "ESV: love", "NIV: love"],
                explanation: "The Greek word 'agape' can be translated as either 'love' or 'charity'. Older translations used 'charity' to distinguish divine love from other types."
            ),
            TranslationNote(
                phrase: "faith without works",
                translations: ["KJV: faith without works is dead", "ESV: faith apart from works is useless"],
                explanation: "Different translations emphasize the relationship between faith and works differently, though the core meaning is preserved."
            )
        ])
    }
    .padding()
    .background(Color.appBackground)
}

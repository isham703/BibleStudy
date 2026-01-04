import SwiftUI

// MARK: - Trust UX Components
// Components for displaying AI reasoning and grounding to build user trust

// MARK: - Show Why Expander
/// Expandable section that shows the reasoning behind AI-generated insights
struct ShowWhyExpander: View {
    let reasoning: [ReasoningPoint]
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Expand/Collapse Button
            Button {
                withAnimation(AppTheme.Animation.quick) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(Color.accentBlue)
                    Text("Why this interpretation?")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.accentBlue)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .buttonStyle(.plain)

            // Reasoning Content
            if isExpanded {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    ForEach(reasoning) { point in
                        ReasoningPointView(point: point)
                    }
                }
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(Color.surfaceBackground)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Reasoning Point View
struct ReasoningPointView: View {
    let point: ReasoningPoint

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            // The phrase from the text
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "text.quote")
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.scholarAccent)
                Text("\"\(point.phrase)\"")
                    .font(Typography.UI.caption1Bold)
                    .foregroundStyle(Color.primaryText)
                    .italic()
            }

            // Why it's significant
            Text(point.explanation)
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)
                .padding(.leading, AppTheme.Spacing.lg)
        }
    }
}

// MARK: - Different Views Section
/// Collapsible section showing alternative interpretive views
struct DifferentViewsSection: View {
    let views: [AlternativeView]
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Header with expand toggle
            Button {
                withAnimation(AppTheme.Animation.quick) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundStyle(Color.info)
                    Text("Different interpretive views")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.info)
                    Spacer()
                    Text("\(views.count)")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)
                        .padding(.horizontal, AppTheme.Spacing.xs)
                        .padding(.vertical, AppTheme.Spacing.xxs)
                        .background(
                            Capsule()
                                .fill(Color.info.opacity(AppTheme.Opacity.lightMedium))
                        )
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .buttonStyle(.plain)

            // Views Content
            if isExpanded {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // View name
            Text(view.viewName)
                .font(Typography.UI.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primaryText)

            // Summary
            Text(view.summary)
                .font(Typography.UI.body)
                .foregroundStyle(Color.secondaryText)

            // Traditions (if available)
            if let traditions = view.traditions, !traditions.isEmpty {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Text("Traditions:")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)
                    Text(traditions.joined(separator: ", "))
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.secondaryText)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
        )
    }
}

// MARK: - Translation Notes Section
/// Collapsible section showing translation differences
struct TranslationNotesSection: View {
    let notes: [TranslationNote]
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Header with expand toggle
            Button {
                withAnimation(AppTheme.Animation.quick) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "character.book.closed")
                        .foregroundStyle(Color.scholarAccent)
                    Text("Translation differences")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.scholarAccent)
                    Spacer()
                    Text("\(notes.count)")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)
                        .padding(.horizontal, AppTheme.Spacing.xs)
                        .padding(.vertical, AppTheme.Spacing.xxs)
                        .background(
                            Capsule()
                                .fill(Color.scholarAccent.opacity(AppTheme.Opacity.lightMedium))
                        )
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .buttonStyle(.plain)

            // Notes Content
            if isExpanded {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
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
    let note: TranslationNote

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // The phrase
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "text.quote")
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.scholarAccent)
                Text("\"\(note.phrase)\"")
                    .font(Typography.UI.caption1Bold)
                    .foregroundStyle(Color.primaryText)
                    .italic()
            }

            // Translation variants
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                ForEach(note.translations, id: \.self) { translation in
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Circle()
                            .fill(Color.scholarAccent)
                            .frame(width: AppTheme.ComponentSize.dot, height: AppTheme.ComponentSize.dot)
                        Text(translation)
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.secondaryText)
                    }
                }
            }
            .padding(.leading, AppTheme.Spacing.md)

            // Explanation
            Text(note.explanation)
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.tertiaryText)
                .padding(.leading, AppTheme.Spacing.md)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
        )
    }
}

// MARK: - Grounding Sources Row
/// Displays the sources used to generate AI content (for trust UX)
struct GroundingSourcesRow: View {
    let sources: [String]

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "checkmark.shield")
                .font(Typography.UI.caption2)
            Text("Based on: \(sources.joined(separator: ", "))")
                .font(Typography.UI.caption2)
        }
        .foregroundStyle(Color.tertiaryText)
    }
}

// MARK: - Previews
#Preview("Show Why Expander") {
    VStack(spacing: AppTheme.Spacing.xl) {
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
    VStack(spacing: AppTheme.Spacing.xl) {
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
    VStack(spacing: AppTheme.Spacing.xl) {
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

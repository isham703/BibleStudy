import SwiftUI

// MARK: - Sources Sheet (Stacked)
// Separate surface for viewing all sources/citations
// Opens from InsightSheet footer, not inline

struct SourcesSheet: View {
    let verse: Verse
    let sources: [InsightSource]
    let onDismiss: () -> Void         // Back to InsightSheet

    // MARK: - Environment
    @Environment(\.insightSheetState) private var sheetState

    // MARK: - State
    @State private var selectedSource: InsightSource?

    /// Verse reference
    private var verseReference: String {
        guard let book = Book.find(byId: verse.bookId) else { return "Verse \(verse.verse)" }
        return "\(book.name) \(verse.chapter):\(verse.verse)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with Back/Close navigation
            HStack(spacing: Theme.Spacing.md) {
                // Back button (returns to InsightSheet)
                Button {
                    HapticService.shared.lightTap()
                    onDismiss()
                } label: {
                    HStack(spacing: Theme.Spacing.xxs) {
                        Image(systemName: "chevron.left")
                            .font(Typography.Icon.xs.weight(.semibold))
                        Text("Back")
                            .font(Typography.Command.caption.weight(.medium))
                    }
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
                }
                .buttonStyle(.plain)

                Spacer()

                // Title
                // swiftlint:disable:next hardcoded_stack_spacing
                VStack(spacing: 1) {  // Tight title/subtitle spacing
                    Text("Sources")
                        .font(Typography.Scripture.footnote.weight(.medium))
                        .foregroundStyle(Color.bibleInsightText)

                    Text("\(sources.count) citation\(sources.count == 1 ? "" : "s")")
                        .font(Typography.Icon.xxs)
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
                }

                Spacer()

                // Close button (dismisses entire stack)
                Button {
                    HapticService.shared.lightTap()
                    sheetState?.dismissAll()
                } label: {
                    Image(systemName: "xmark")
                        .font(Typography.Icon.xxs.weight(.medium))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                        .padding(Theme.Spacing.xs)
                        .background(Circle().fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle / 2)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)

            Rectangle()
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle))
                .frame(height: 0.5)

            // Sources list
            if sources.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.md) {
                        ForEach(sources, id: \.reference) { source in
                            sourceRow(source)
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
        }
        .background(Color.bibleInsightCardBackground)
        .sheet(item: $selectedSource) { source in
            SourceDetailSheet(
                verse: verse,
                source: source,
                onDismiss: { selectedSource = nil }
            )
            .environment(\.insightSheetState, sheetState)
            .presentationDetents([.fraction(0.55), .fraction(0.95)])
            .presentationDragIndicator(.visible)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "text.quote")
                .font(Typography.Icon.xxl)
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.selectionBackground))

            Text("No sources available")
                .font(Typography.Scripture.footnote)
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, Theme.Spacing.xxl + 8)
    }

    private func sourceRow(_ source: InsightSource) -> some View {
        Button {
            HapticService.shared.lightTap()
            selectedSource = source
        } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Header row: icon + formatted title + chevron
                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    // Type icon with colored background
                    source.type.icon
                        .font(Typography.Icon.xs.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.input)
                                .fill(source.type.color)
                        )

                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        // Formatted title based on type
                        Text(formattedTitle(for: source))
                            .font(Typography.Command.caption.weight(.semibold))
                            .foregroundStyle(Color.bibleInsightText)

                        // Type badge inline
                        Text(source.type.label)
                            .font(Typography.Icon.xxxs)
                            .foregroundStyle(source.type.color)
                            .textCase(.uppercase)
                            .tracking(Typography.Editorial.labelTracking)
                    }

                    Spacer()

                    // Navigation chevron (consistent with Connections)
                    Image(systemName: "chevron.right")
                        .font(Typography.Icon.xs.weight(.semibold))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.focusStroke))
                }

                // "Cited for" rationale
                if let description = source.description {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        Text("Cited for")
                            .font(Typography.Icon.xxxs.weight(.semibold))
                            .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                            .textCase(.uppercase)
                            .tracking(Typography.Editorial.labelTracking)

                        Text(description)
                            .font(Typography.Scripture.footnote)
                            .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.pressed))
                            .lineSpacing(Typography.Command.metaLineSpacing)
                    }
                    .padding(.leading, Theme.Spacing.xxl + Theme.Spacing.md)  // Align with title
                }
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle / 2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(source.type.color.opacity(Theme.Opacity.subtle), lineWidth: Theme.Stroke.hairline)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Format title based on source type for explicit display
    private func formattedTitle(for source: InsightSource) -> String {
        switch source.type {
        case .strongs:
            // e.g., "Strong's G3056" → "Strong's Greek Lexicon (G3056)"
            // Extract the number part (G3056 or H1234)
            let pattern = /([GH]\d+)/
            if let match = source.reference.firstMatch(of: pattern) {
                let number = String(match.output.1)
                if number.hasPrefix("G") {
                    return "Strong's Greek Lexicon (\(number))"
                } else if number.hasPrefix("H") {
                    return "Strong's Hebrew Lexicon (\(number))"
                }
            }
            return source.reference
        case .crossReference:
            return source.reference
        case .commentary:
            return source.reference
        case .lexicon:
            return source.reference
        }
    }
}

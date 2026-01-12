import SwiftUI

// MARK: - Source Detail Sheet
// Shows expanded detail for a source (Strong's lexicon, cross-reference text, etc.)

struct SourceDetailSheet: View {
    let verse: Verse
    let source: InsightSource
    let onDismiss: () -> Void

    // MARK: - Environment
    @Environment(\.insightSheetState) private var sheetState

    // MARK: - State
    @State private var verseText: String?
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Rectangle()
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle))
                .frame(height: 0.5)

            // Content based on source type
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    sourceContent
                }
                .padding(Theme.Spacing.lg)
            }

            // Action button for cross-references
            if source.type == .crossReference {
                actionButton
            }
        }
        .background(Color.bibleInsightCardBackground)
        .task {
            await loadSourceContent()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Back button
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

            // Title with icon
            HStack(spacing: Theme.Spacing.sm) {
                source.type.icon
                    .font(Typography.Icon.sm.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.input)
                            .fill(source.type.color)
                    )

                Text(source.type.label)
                    .font(Typography.Scripture.footnote.weight(.medium))
                    .foregroundStyle(Color.bibleInsightText)
            }

            Spacer()

            // Close button (dismisses entire sheet stack)
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
    }

    // MARK: - Source Content

    @ViewBuilder
    private var sourceContent: some View {
        switch source.type {
        case .crossReference:
            crossReferenceContent
        case .strongs:
            strongsContent
        case .commentary:
            commentaryContent
        case .lexicon:
            lexiconContent
        }
    }

    private var crossReferenceContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Reference title
            Text(source.reference)
                .font(Typography.Scripture.heading.weight(.medium))
                .foregroundStyle(Color.bibleInsightText)

            // Description (why cited)
            if let description = source.description {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Connection")
                        .font(Typography.Icon.xxs.weight(.semibold))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                        .textCase(.uppercase)
                        .tracking(Typography.Editorial.labelTracking)

                    Text(description)
                        .font(Typography.Command.subheadline)
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.pressed))
                        .lineSpacing(Typography.Scripture.footnoteLineSpacing)
                }
            }

            // Verse text (loaded async)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Text")
                    .font(Typography.Icon.xxs.weight(.semibold))
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                    .textCase(.uppercase)
                    .tracking(Typography.Editorial.labelTracking)

                if isLoading {
                    HStack(spacing: Theme.Spacing.sm) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading verse...")
                            .font(Typography.Scripture.footnote)
                            .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
                    }
                } else if let text = verseText {
                    Text(text)
                        .font(Typography.Scripture.body)
                        .foregroundStyle(Color.bibleInsightText)
                        .lineSpacing(Typography.Scripture.footnoteLineSpacing)
                        .italic()
                } else {
                    Text("Verse text not available")
                        .font(Typography.Scripture.footnote)
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
                }
            }
            .padding(.top, Theme.Spacing.sm)
        }
    }

    private var strongsContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Strong's number title
            Text(formattedStrongsTitle)
                .font(Typography.Scripture.heading.weight(.medium))
                .foregroundStyle(Color.bibleInsightText)

            // Gloss/Description
            if let description = source.description {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Gloss")
                        .font(Typography.Icon.xxs.weight(.semibold))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                        .textCase(.uppercase)
                        .tracking(Typography.Editorial.labelTracking)

                    Text(description)
                        .font(Typography.Scripture.body.weight(.semibold))
                        .foregroundStyle(Color.bibleInsightText)
                }
            }

            // Placeholder for additional lexicon data
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Definition")
                    .font(Typography.Icon.xxs.weight(.semibold))
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                    .textCase(.uppercase)
                    .tracking(Typography.Editorial.labelTracking)

                if isLoading {
                    HStack(spacing: Theme.Spacing.sm) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading lexicon entry...")
                            .font(Typography.Scripture.footnote)
                            .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
                    }
                } else {
                    Text("The lexicon entry shows the original word's meaning, etymology, and usage across Scripture.")
                        .font(Typography.Command.subheadline)
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.pressed))
                        .lineSpacing(Typography.Scripture.footnoteLineSpacing)
                }
            }
            .padding(.top, Theme.Spacing.sm)
        }
    }

    private var commentaryContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(source.reference)
                .font(Typography.Scripture.heading.weight(.medium))
                .foregroundStyle(Color.bibleInsightText)

            if let description = source.description {
                Text(description)
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.pressed))
                    .lineSpacing(Typography.Scripture.footnoteLineSpacing)
            }
        }
    }

    private var lexiconContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(source.reference)
                .font(Typography.Scripture.heading.weight(.medium))
                .foregroundStyle(Color.bibleInsightText)

            if let description = source.description {
                Text(description)
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.pressed))
                    .lineSpacing(Typography.Scripture.footnoteLineSpacing)
            }
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle))
                .frame(height: 0.5)

            Button {
                HapticService.shared.mediumTap()
                sheetState?.navigateToReference(source.reference)
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(Typography.Icon.sm)
                    Text("Go to \(source.reference)")
                        .font(Typography.Command.caption.weight(.medium))
                }
                .foregroundStyle(Color("FeedbackWarning"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md + 2)
            }
            .buttonStyle(.plain)
        }
        .background(Color.bibleInsightCardBackground)
    }

    // MARK: - Helpers

    private var formattedStrongsTitle: String {
        let pattern = /([GH]\d+)/
        if let match = source.reference.firstMatch(of: pattern) {
            let number = String(match.output.1)
            if number.hasPrefix("G") {
                return "Greek Word (\(number))"
            } else if number.hasPrefix("H") {
                return "Hebrew Word (\(number))"
            }
        }
        return source.reference
    }

    private func loadSourceContent() async {
        // For cross-references, try to load the verse text
        if source.type == .crossReference {
            let result = ReferenceParser.parse(source.reference)
            if case .success(let parsed) = result {
                // Create verse range for the target verse
                let verseNum = parsed.verseStart ?? 1
                let range = VerseRange(
                    bookId: parsed.book.id,
                    chapter: parsed.chapter,
                    verseStart: verseNum,
                    verseEnd: parsed.verseEnd ?? verseNum
                )

                // Load verse from BibleService
                do {
                    let verses = try await BibleService.shared.getVerses(range: range)
                    if let foundVerse = verses.first {
                        verseText = foundVerse.text
                    }
                } catch {
                    verseText = nil
                }
            }
        }

        isLoading = false
    }
}

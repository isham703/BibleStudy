import SwiftUI

// MARK: - Connection Detail View
// Shows both verses side-by-side with connection rationale before navigating

struct ConnectionDetailView: View {
    let sourceVerse: Verse
    let connection: BibleInsight
    let onDismiss: () -> Void

    // MARK: - Environment
    @Environment(\.insightSheetState) private var sheetState

    // MARK: - State
    @State private var targetVerseText: String?
    @State private var isLoading = true
    @State private var showSources = false

    // MARK: - Computed Properties

    private var targetReference: String? {
        connection.sources
            .first { $0.type == .crossReference }?
            .reference
    }

    private var sourceReference: String {
        guard let book = Book.find(byId: sourceVerse.bookId) else {
            return "Verse \(sourceVerse.verse)"
        }
        return "\(book.name) \(sourceVerse.chapter):\(sourceVerse.verse)"
    }

    private var connectionType: String {
        // Determine connection type from sources or content
        if connection.content.lowercased().contains("echo") ||
           connection.content.lowercased().contains("allusion") {
            return "Echo / Allusion"
        } else if connection.content.lowercased().contains("fulfil") ||
                  connection.content.lowercased().contains("prophec") {
            return "Prophecy Fulfillment"
        } else if connection.content.lowercased().contains("parallel") {
            return "Parallel Passage"
        } else if connection.content.lowercased().contains("contrast") {
            return "Contrast"
        } else {
            return "Thematic Connection"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Rectangle()
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle))
                .frame(height: 0.5)

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    // Source verse (current reading location)
                    verseCard(
                        reference: sourceReference,
                        text: sourceVerse.text,
                        label: "Current Passage",
                        color: Color("FeedbackSuccess")
                    )

                    // Connection indicator
                    connectionIndicator

                    // Target verse (cross-reference)
                    if let ref = targetReference {
                        verseCard(
                            reference: ref,
                            text: targetVerseText,
                            label: "Connected Passage",
                            color: Color("AccentBronze"),
                            isLoading: isLoading
                        )
                    }

                    // Rationale
                    rationaleSection
                }
                .padding(Theme.Spacing.lg)
            }

            // Action button
            if targetReference != nil {
                actionButton
            }
        }
        .background(Color.bibleInsightCardBackground)
        .task {
            await loadTargetVerse()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            // Top bar with Back and Done buttons
            HStack {
                // Back button
                Button {
                    HapticService.shared.lightTap()
                    onDismiss()
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(Typography.Icon.xs.weight(.semibold))
                        Text("Map")
                            .font(Typography.Command.caption.weight(.medium))
                    }
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.pressed))
                }
                .buttonStyle(.plain)

                Spacer()

                // Done button dismisses entire sheet stack
                Button {
                    HapticService.shared.lightTap()
                    sheetState?.dismissAll()
                } label: {
                    Text("Done")
                        .font(Typography.Command.body.weight(.medium))
                        .foregroundStyle(Color("FeedbackWarning"))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.sm)

            // Title area: "John 1:1 ↔ Genesis 1:1"
            VStack(spacing: Theme.Spacing.xs) {
                // References with bidirectional arrow
                HStack(spacing: Theme.Spacing.sm) {
                    Text(sourceReference)
                        .font(Typography.Scripture.body.weight(.medium))
                        .foregroundStyle(Color("FeedbackSuccess"))

                    Image(systemName: "arrow.left.arrow.right")
                        .font(Typography.Icon.xs.weight(.medium))
                        .foregroundStyle(Color("FeedbackWarning"))

                    if let ref = targetReference {
                        Text(ref)
                            .font(Typography.Scripture.body.weight(.medium))
                            .foregroundStyle(Color("FeedbackWarning"))
                    }
                }

                // Connection type as subtitle
                Text(connectionType)
                    .font(Typography.Icon.xs)
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
            }
            .padding(.bottom, Theme.Spacing.md)
        }
    }

    // MARK: - Verse Card

    private func verseCard(
        reference: String,
        text: String?,
        label: String,
        color: Color,
        isLoading: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Label
            Text(label)
                .font(Typography.Icon.xxs.weight(.semibold))
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                .textCase(.uppercase)
                .tracking(Typography.Editorial.labelTracking)

            // Card
            VStack(alignment: .leading, spacing: Theme.Spacing.md - 2) {
                // Reference
                HStack(spacing: Theme.Spacing.sm) {
                    Circle()
                        .fill(color)
                        .frame(width: Theme.Spacing.sm, height: Theme.Spacing.sm)

                    Text(reference)
                        .font(Typography.Scripture.footnote.weight(.medium))
                        .foregroundStyle(Color.bibleInsightText)
                }

                // Text
                if isLoading {
                    HStack(spacing: Theme.Spacing.sm) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading verse...")
                            .font(Typography.Scripture.footnote)
                            .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
                    }
                } else if let verseText = text {
                    Text(verseText)
                        .font(Typography.Scripture.body)
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textPrimary))
                        .lineSpacing(Typography.Scripture.footnoteLineSpacing)
                        .italic()
                } else {
                    Text("Verse text not available")
                        .font(Typography.Scripture.footnote)
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
                }
            }
            .padding(Theme.Spacing.md + 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle / 2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(color.opacity(Theme.Opacity.selectionBackground), lineWidth: Theme.Stroke.hairline)
            )
        }
    }

    // MARK: - Connection Indicator (Simplified Divider)

    private var connectionIndicator: some View {
        HStack(spacing: Theme.Spacing.md) {
            Rectangle()
                .fill(Color("FeedbackWarning").opacity(Theme.Opacity.selectionBackground))
                .frame(height: Theme.Stroke.hairline)

            Image(systemName: "link")
                .font(Typography.Icon.xxs.weight(.medium))
                .foregroundStyle(Color("FeedbackWarning").opacity(Theme.Opacity.disabled))

            Rectangle()
                .fill(Color("FeedbackWarning").opacity(Theme.Opacity.selectionBackground))
                .frame(height: Theme.Stroke.hairline)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    // MARK: - Rationale Section

    /// Extract a key idea (thesis) from the connection title
    private var keyIdea: String {
        // Use the title as the key idea - it's typically a concise summary
        connection.title
    }

    /// Sources count for this connection
    private var sourceCount: Int {
        connection.sources.count
    }

    private var rationaleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Label
            Text("Why Connected")
                .font(Typography.Icon.xxs.weight(.semibold))
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                .textCase(.uppercase)
                .tracking(Typography.Editorial.labelTracking)

            // Key idea (thesis line) - scannable summary
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                Text("Key idea:")
                    .font(Typography.Command.label.weight(.semibold))
                    .foregroundStyle(Color("FeedbackWarning"))

                Text(keyIdea)
                    .font(Typography.Command.label.weight(.semibold))
                    .foregroundStyle(Color.bibleInsightText)
            }

            // Full rationale (optional depth)
            Text(connection.content)
                .font(Typography.Scripture.footnote)
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
                .lineSpacing(Typography.Scripture.footnoteLineSpacing)

            // Sources row (future-proof slot)
            if sourceCount > 0 {
                sourcesRow
            }
        }
        .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - Sources Row

    private var sourcesRow: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs + 2) {
            Button {
                HapticService.shared.lightTap()
                withAnimation(Theme.Animation.settle) {
                    showSources.toggle()
                }
            } label: {
                HStack(spacing: Theme.Spacing.xs + 2) {
                    Text("Sources (\(sourceCount))")
                        .font(Typography.Icon.xxs.weight(.medium))

                    Image(systemName: showSources ? "chevron.down" : "chevron.right")
                        .font(Typography.Icon.xxs.weight(.semibold))
                }
                .foregroundStyle(Color("AppAccentAction"))
            }
            .buttonStyle(.plain)

            if showSources {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    ForEach(connection.sources, id: \.reference) { source in
                        HStack(alignment: .top, spacing: Theme.Spacing.xs + 2) {
                            source.type.icon
                                .font(Typography.Icon.xxxs)
                                .foregroundStyle(source.type.color)
                                .frame(width: Theme.Spacing.md)

                            // swiftlint:disable:next hardcoded_stack_spacing
                            VStack(alignment: .leading, spacing: 1) {  // Tight ref/verse spacing
                                Text(source.reference)
                                    .font(Typography.Icon.xxs.weight(.medium))
                                    .foregroundStyle(Color.bibleInsightText)

                                if let description = source.description {
                                    Text(description)
                                        .font(Typography.Icon.xxs)
                                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.pressed))
                                }
                            }
                        }
                    }
                }
                .padding(.leading, Theme.Spacing.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, Theme.Spacing.xs)
    }

    // MARK: - Action Button

    private var actionButton: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle))
                .frame(height: 0.5)

            // Primary CTA: Open connected passage
            Button {
                HapticService.shared.mediumTap()
                if let reference = targetReference {
                    sheetState?.navigateToReference(reference)
                }
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(Typography.Icon.sm)
                    if let ref = targetReference {
                        Text("Open \(ref)")
                            .font(Typography.Icon.sm.weight(.medium))
                    }
                }
                .foregroundStyle(Color("FeedbackWarning"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
            }
            .buttonStyle(.plain)

            // Secondary CTA: Open source passage (neutral label)
            Button {
                HapticService.shared.lightTap()
                sheetState?.navigateToReference(sourceReference)
            } label: {
                HStack(spacing: Theme.Spacing.xs + 2) {
                    Image(systemName: "book.pages")
                        .font(Typography.Command.meta)
                    Text("Open \(sourceReference)")
                        .font(Typography.Icon.xs.weight(.medium))
                }
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
                .padding(.vertical, Theme.Spacing.sm)
            }
            .buttonStyle(.plain)
        }
        .background(Color.bibleInsightCardBackground)
    }

    // MARK: - Load Target Verse

    private func loadTargetVerse() async {
        guard let reference = targetReference else {
            isLoading = false
            return
        }

        let result = ReferenceParser.parse(reference)
        if case .success(let parsed) = result {
            let verseNum = parsed.verseStart ?? 1
            let range = VerseRange(
                bookId: parsed.book.id,
                chapter: parsed.chapter,
                verseStart: verseNum,
                verseEnd: parsed.verseEnd ?? verseNum
            )

            do {
                let verses = try await BibleService.shared.getVerses(range: range)
                if let foundVerse = verses.first {
                    targetVerseText = foundVerse.text
                }
            } catch {
                targetVerseText = nil
            }
        }

        isLoading = false
    }
}

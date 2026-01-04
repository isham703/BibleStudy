import SwiftUI

// MARK: - Deep Study Sheet (Scholar's Codex)
// A continuous scroll sheet styled like an ancient scholar's reference book
// Design: No tabs - chapters unfurl progressively as user scrolls
// Contains: Illumination, Original Language, Translations, Cross-refs

struct DeepStudySheet: View {
    // MARK: - Properties

    let verseRange: VerseRange
    @Bindable var viewModel: InsightViewModel
    var onNavigate: ((VerseRange) -> Void)?
    var onDismiss: (() -> Void)?

    // MARK: - State

    @State private var isHeaderRevealed = false
    @State private var illuminationRevealed = false
    @State private var languageRevealed = false
    @State private var translationsRevealed = false
    @State private var crossRefsRevealed = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Illuminated Header (verse text in decorative frame)
                    codexHeader
                        .opacity(isHeaderRevealed ? 1 : 0)
                        .offset(y: isHeaderRevealed ? 0 : 20)

                    CodexDivider()

                    // Chapter I: Illumination (Hero Insight)
                    illuminationChapter
                        .opacity(illuminationRevealed ? 1 : 0)
                        .offset(y: illuminationRevealed ? 0 : 20)

                    CodexDivider()

                    // Chapter II: Original Language
                    languageChapter
                        .opacity(languageRevealed ? 1 : 0)
                        .offset(y: languageRevealed ? 0 : 20)

                    CodexDivider()

                    // Chapter III: Translations Compared
                    translationsChapter
                        .opacity(translationsRevealed ? 1 : 0)
                        .offset(y: translationsRevealed ? 0 : 20)

                    CodexDivider()

                    // Chapter IV: Cross-References
                    crossRefsChapter
                        .opacity(crossRefsRevealed ? 1 : 0)
                        .offset(y: crossRefsRevealed ? 0 : 20)

                    // Colophon (footer)
                    codexColophon

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
            }
            .background(Color.surfaceBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Deep Study")
                        .font(Typography.Display.headline)
                        .foregroundStyle(Color.primaryText)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticService.shared.lightTap()
                        onDismiss?()
                    } label: {
                        Image(systemName: "xmark")
                            .font(Typography.UI.iconSm)
                            .foregroundStyle(Color.secondaryText)
                            .frame(width: AppTheme.IconContainer.medium, height: AppTheme.IconContainer.medium)
                            .background(Color.elevatedBackground)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .onAppear {
            // Heavy haptic for opening a "tome"
            HapticService.shared.heavyTap()

            // Staggered reveal animation
            withAnimation(AppTheme.Animation.luminous) {
                isHeaderRevealed = true
            }
            withAnimation(AppTheme.Animation.unfurl.delay(0.3)) {
                illuminationRevealed = true
            }
            withAnimation(AppTheme.Animation.unfurl.delay(0.5)) {
                languageRevealed = true
            }
            withAnimation(AppTheme.Animation.unfurl.delay(0.7)) {
                translationsRevealed = true
            }
            withAnimation(AppTheme.Animation.unfurl.delay(0.9)) {
                crossRefsRevealed = true
            }
        }
        .task {
            // Load content if not already loaded
            // Don't force refresh here since InlineInsightCard already loaded fresh content
            if viewModel.explanation == nil {
                await viewModel.loadExplanation(forceRefresh: true)
            }
        }
    }

    // MARK: - Codex Header

    private var codexHeader: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Decorative top line
            Rectangle()
                .fill(Color.divineGold.opacity(AppTheme.Opacity.heavy))
                .frame(height: AppTheme.Divider.medium)
                .padding(.horizontal, AppTheme.Spacing.xxl + AppTheme.Spacing.sm)

            // Verse reference in blackletter style
            Text(verseRange.reference)
                .font(Typography.Codex.verseReference)
                .foregroundStyle(Color.primaryText)

            // Verse text
            Text(viewModel.verseText.isEmpty ? "Loading..." : viewModel.verseText)
                .font(Typography.Codex.body)
                .foregroundStyle(Color.primaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(Typography.Codex.heroLineSpacing)
                .padding(.horizontal, AppTheme.Spacing.lg)

            // Decorative bottom line
            Rectangle()
                .fill(Color.divineGold.opacity(AppTheme.Opacity.heavy))
                .frame(height: AppTheme.Divider.medium)
                .padding(.horizontal, AppTheme.Spacing.xxl + AppTheme.Spacing.sm)
        }
        .padding(.vertical, AppTheme.Spacing.xl)
    }

    // MARK: - Chapter I: Illumination

    private var illuminationChapter: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            CodexChapterHeader(symbol: "✦", title: "ILLUMINATION")

            if viewModel.isLoadingExplain {
                ProgressView("Illuminating...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.xl)
            } else if let structured = viewModel.structuredExplanation {
                // Hero summary
                Text(structured.summary)
                    .font(Typography.Codex.body)
                    .foregroundStyle(Color.primaryText)
                    .lineSpacing(Typography.Codex.bodyLineSpacing)

                // Key concepts as cards
                if !structured.keyPoints.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppTheme.Spacing.md) {
                            ForEach(Array(structured.keyPoints.prefix(4).enumerated()), id: \.offset) { _, point in
                                KeyConceptCard(concept: point)
                            }
                        }
                    }
                }
            } else if let explanation = viewModel.explanation {
                Text(explanation)
                    .font(Typography.Codex.body)
                    .foregroundStyle(Color.primaryText)
                    .lineSpacing(Typography.Codex.captionLineSpacing)
            }
        }
        .padding(.vertical, AppTheme.Spacing.md)
    }

    // MARK: - Chapter II: Original Language

    private var languageChapter: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            CodexChapterHeader(symbol: "𝔏", title: "ORIGINAL LANGUAGE")

            if viewModel.isLoadingLanguage {
                ProgressView("Loading word analysis...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.lg)
            } else if viewModel.languageTokens.isEmpty {
                // Load on appear
                Button {
                    Task { await viewModel.loadLanguageTokens() }
                } label: {
                    HStack {
                        Image(systemName: "character.book.closed")
                        Text("Load Word Analysis")
                    }
                    .font(Typography.Codex.emphasis)
                    .foregroundStyle(Color.divineGold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(Color.divineGold.opacity(AppTheme.Opacity.subtle))
                    )
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: AppTheme.Spacing.md) {
                    // Show first 5 tokens, rest in expandable section
                    ForEach(Array(viewModel.languageTokens.prefix(5)), id: \.id) { token in
                        CompactLanguageTermCard(
                            originalText: token.surface,
                            transliteration: token.transliteration,
                            translation: token.gloss,
                            grammar: token.plainEnglishMorph
                        )
                    }

                    // Show "more" button if there are additional tokens
                    if viewModel.languageTokens.count > 5 {
                        DisclosureGroup {
                            VStack(spacing: AppTheme.Spacing.md) {
                                ForEach(Array(viewModel.languageTokens.dropFirst(5)), id: \.id) { token in
                                    CompactLanguageTermCard(
                                        originalText: token.surface,
                                        transliteration: token.transliteration,
                                        translation: token.gloss,
                                        grammar: token.plainEnglishMorph
                                    )
                                }
                            }
                        } label: {
                            HStack {
                                Text("+ \(viewModel.languageTokens.count - 5) more words")
                                    .font(Typography.Codex.caption)
                                    .foregroundStyle(Color.divineGold)
                            }
                        }
                        .tint(Color.divineGold)
                    }
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.md)
        .task {
            if viewModel.languageTokens.isEmpty {
                await viewModel.loadLanguageTokens()
            }
        }
    }

    // MARK: - Chapter III: Translations

    private var translationsChapter: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            CodexChapterHeader(symbol: "𝔗", title: "TRANSLATIONS COMPARED")

            // Embedded translation comparison
            TranslationComparisonView(verseRange: verseRange)
                .frame(minHeight: 200)
        }
        .padding(.vertical, AppTheme.Spacing.md)
    }

    // MARK: - Chapter IV: Cross-References

    private var crossRefsChapter: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            CodexChapterHeader(symbol: "ℭ", title: "CROSS-REFERENCES")

            if viewModel.isLoadingCrossRefs {
                ProgressView("Loading references...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.lg)
            } else if viewModel.crossRefs.isEmpty {
                Button {
                    Task { await viewModel.loadCrossRefs() }
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.branch")
                        Text("Load Cross-References")
                    }
                    .font(Typography.Codex.emphasis)
                    .foregroundStyle(Color.divineGold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(Color.divineGold.opacity(AppTheme.Opacity.subtle))
                    )
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: AppTheme.Spacing.md) {
                    // Show first 5 cross-references
                    ForEach(Array(viewModel.crossRefs.prefix(5)), id: \.id) { crossRef in
                        CrossReferenceCard(
                            reference: crossRef.reference,
                            preview: crossRef.preview,
                            whyLinked: crossRef.whyLinked
                        ) {
                            if let targetRange = crossRef.targetRange {
                                onNavigate?(targetRange)
                                onDismiss?()
                            }
                        }
                    }

                    // Show "more" button if there are additional cross-refs
                    if viewModel.crossRefs.count > 5 {
                        DisclosureGroup {
                            VStack(spacing: AppTheme.Spacing.md) {
                                ForEach(Array(viewModel.crossRefs.dropFirst(5)), id: \.id) { crossRef in
                                    CrossReferenceCard(
                                        reference: crossRef.reference,
                                        preview: crossRef.preview,
                                        whyLinked: crossRef.whyLinked
                                    ) {
                                        if let targetRange = crossRef.targetRange {
                                            onNavigate?(targetRange)
                                            onDismiss?()
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("+ \(viewModel.crossRefs.count - 5) more references")
                                    .font(Typography.Codex.caption)
                                    .foregroundStyle(Color.divineGold)
                            }
                        }
                        .tint(Color.divineGold)
                    }
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.md)
        .task {
            if viewModel.crossRefs.isEmpty {
                await viewModel.loadCrossRefs()
            }
        }
    }

    // MARK: - Colophon

    private var codexColophon: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Decorative flourish
            HStack(spacing: AppTheme.Spacing.md) {
                Rectangle()
                    .fill(Color.divineGold.opacity(AppTheme.Opacity.medium))
                    .frame(height: AppTheme.Divider.thin)

                Text("✧ COLOPHON ✧")
                    .font(Typography.Codex.colophon)
                    .tracking(Typography.Codex.headerTracking)
                    .foregroundStyle(Color.divineGold.opacity(AppTheme.Opacity.strong))

                Rectangle()
                    .fill(Color.divineGold.opacity(AppTheme.Opacity.medium))
                    .frame(height: AppTheme.Divider.thin)
            }

            // Sources and report issue
            HStack(spacing: AppTheme.Spacing.xl) {
                if !viewModel.explanationGroundingSources.isEmpty {
                    Button {
                        // Show sources
                    } label: {
                        Text("Sources")
                            .font(Typography.Codex.caption)
                            .foregroundStyle(Color.secondaryText)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    // Report issue
                } label: {
                    Text("Report Issue")
                        .font(Typography.Codex.caption)
                        .foregroundStyle(Color.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xl)
    }
}

// MARK: - Codex Chapter Header

struct CodexChapterHeader: View {
    let symbol: String
    let title: String

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.sm) {
            // Illuminated capital (decorative drop cap) - smaller size
            Text(symbol)
                .font(Typography.Codex.chapterSymbol)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.burnishedGold,
                            Color.divineGold
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.divineGold.opacity(AppTheme.Opacity.medium), radius: AppTheme.Blur.subtle)

            Text(title)
                .font(Typography.Codex.chapterTitle)
                .tracking(Typography.Codex.titleTracking)
                .foregroundStyle(Color.primaryText)
        }
    }
}

// MARK: - Codex Divider

struct CodexDivider: View {
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Left ornament line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.divineGold.opacity(AppTheme.Opacity.strong)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: AppTheme.Divider.thin)

            // Center ornament (fleuron)
            Image(systemName: "sparkle")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.divineGold)

            // Right ornament line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.divineGold.opacity(AppTheme.Opacity.strong), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: AppTheme.Divider.thin)
        }
        .padding(.vertical, AppTheme.Spacing.xl)
    }
}

// MARK: - Key Concept Card

struct KeyConceptCard: View {
    let concept: String
    @State private var isExpanded: Bool = false

    var body: some View {
        Button {
            withAnimation(AppTheme.Animation.sacredSpring) {
                isExpanded.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                // Extract first word/phrase as title (split on " - " or take first 2 words)
                let parts = extractTitleAndDescription(from: concept)

                Text(parts.title)
                    .font(Typography.Codex.captionBold)
                    .foregroundStyle(Color.primaryText)
                    .multilineTextAlignment(.leading)

                Rectangle()
                    .fill(Color.divineGold.opacity(AppTheme.Opacity.heavy))
                    .frame(height: AppTheme.Divider.thin)

                if !parts.description.isEmpty {
                    Text(parts.description)
                        .font(Typography.Codex.captionSmall)
                        .foregroundStyle(Color.secondaryText)
                        .lineSpacing(Typography.Codex.captionLineSpacing)
                        .lineLimit(isExpanded ? nil : 4)
                        .multilineTextAlignment(.leading)
                }

                // Expand indicator if text is long
                if parts.description.count > 80 {
                    HStack {
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(Typography.UI.iconXxs)
                            .foregroundStyle(Color.divineGold)
                    }
                }
            }
            .frame(width: 150)
            .padding(AppTheme.Spacing.md)
            .background(Color.elevatedBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
        }
        .buttonStyle(.plain)
    }

    private func extractTitleAndDescription(from text: String) -> (title: String, description: String) {
        // Try splitting on " - " first (common pattern: "Cornerstone - Christ Jesus himself")
        if let dashRange = text.range(of: " - ") {
            let title = String(text[..<dashRange.lowerBound])
            let description = String(text[dashRange.upperBound...])
            return (title, description)
        }

        // Otherwise take first 2-3 words as title
        let words = text.split(separator: " ")
        if words.count <= 3 {
            return (text, "")
        }

        let titleWords = words.prefix(2).joined(separator: " ")
        let descWords = words.dropFirst(2).joined(separator: " ")
        return (titleWords, descWords)
    }
}

// MARK: - Compact Language Term Card (for list display)

struct CompactLanguageTermCard: View {
    let originalText: String
    let transliteration: String
    let translation: String
    let grammar: String

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
            // Gold accent bar
            Rectangle()
                .fill(Color.divineGold.opacity(AppTheme.Opacity.strong))
                .frame(width: AppTheme.Border.thick)

            // Original text
            Text(originalText)
                .font(Typography.Codex.greek)
                .foregroundStyle(Color.primaryText)
                .frame(minWidth: 50, alignment: .leading)

            // Transliteration and translation
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(transliteration)
                    .font(Typography.Codex.italicSmall)
                    .foregroundStyle(Color.secondaryText)

                Text(translation)
                    .font(Typography.Codex.gloss)
                    .foregroundStyle(Color.divineGold)
            }

            Spacer()

            // Grammar (abbreviated)
            if !grammar.isEmpty {
                Text(grammar)
                    .font(Typography.Codex.captionSmall)
                    .foregroundStyle(Color.tertiaryText)
                    .lineLimit(1)
                    .frame(maxWidth: 100, alignment: .trailing)
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .padding(.horizontal, AppTheme.Spacing.md)
        .background(Color.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
    }
}

// MARK: - Original Language Term Card (detailed view)

struct OriginalLanguageTermCard: View {
    let originalText: String
    let transliteration: String
    let translation: String
    let grammar: String
    let definition: String
    let onExplain: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Original script + transliteration on same line
            HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
                Text(originalText)
                    .font(Typography.Codex.greek)
                    .foregroundStyle(Color.primaryText)

                Text("(\(transliteration))")
                    .font(Typography.Codex.transliteration)
                    .foregroundStyle(Color.secondaryText)
            }

            // English translation
            Text(translation.uppercased())
                .font(Typography.Codex.captionSmall)
                .tracking(Typography.Codex.titleTracking)
                .foregroundStyle(Color.divineGold)

            if !grammar.isEmpty || !definition.isEmpty {
                Divider()

                // Grammar info
                if !grammar.isEmpty {
                    Text(grammar)
                        .font(Typography.Codex.captionSmall)
                        .foregroundStyle(Color.secondaryText)
                }

                // Definition
                if !definition.isEmpty {
                    Text(definition)
                        .font(Typography.Codex.caption)
                        .foregroundStyle(Color.primaryText)
                        .lineSpacing(Typography.Codex.captionLineSpacing)
                }
            }

            // Contextual explanation button
            Button {
                Task { await onExplain() }
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "sparkle")
                    Text("Explain in Context")
                }
                .font(Typography.Codex.captionSmall)
                .foregroundStyle(Color.divineGold)
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
        )
        .overlay(
            // Gold accent bar on left
            Rectangle()
                .fill(Color.divineGold)
                .frame(width: AppTheme.Border.thick)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: AppTheme.CornerRadius.medium,
                        bottomLeadingRadius: AppTheme.CornerRadius.medium,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                ),
            alignment: .leading
        )
    }
}

// MARK: - Cross Reference Card

struct CrossReferenceCard: View {
    let reference: String
    let preview: String
    let whyLinked: String?
    let onNavigate: () -> Void

    var body: some View {
        Button(action: onNavigate) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                // Gold left bar
                Rectangle()
                    .fill(Color.divineGold.opacity(AppTheme.Opacity.heavy))
                    .frame(width: AppTheme.Border.thick)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(reference)
                        .font(Typography.Codex.reference)
                        .foregroundStyle(Color.divineGold)

                    Text("\"\(preview)\"")
                        .font(Typography.Codex.quotePreview)
                        .foregroundStyle(Color.primaryText)
                        .lineLimit(3)

                    if let why = whyLinked, !why.isEmpty {
                        Text(why)
                            .font(Typography.Codex.captionSmall)
                            .foregroundStyle(Color.secondaryText)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(AppTheme.Spacing.md)
            .background(Color.elevatedBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Deep Study Sheet") {
    DeepStudySheet(
        verseRange: VerseRange(bookId: 49, chapter: 2, verseStart: 20, verseEnd: 20),
        viewModel: InsightViewModel(verseRange: VerseRange(bookId: 49, chapter: 2, verseStart: 20, verseEnd: 20)),
        onNavigate: { _ in },
        onDismiss: {}
    )
}

#Preview("Codex Components") {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.xl) {
            CodexChapterHeader(symbol: "✦", title: "ILLUMINATION")

            CodexDivider()

            CodexChapterHeader(symbol: "𝔏", title: "ORIGINAL LANGUAGE")

            OriginalLanguageTermCard(
                originalText: "θεμελίῳ",
                transliteration: "themelíō",
                translation: "Foundation",
                grammar: "Noun, Dative Singular",
                definition: "From θεμέλιος: that which is laid down, a base. Used metaphorically for fundamental principles."
            ) {
                print("Explain tapped")
            }

        }
        .padding()
    }
    .background(Color.surfaceBackground)
}

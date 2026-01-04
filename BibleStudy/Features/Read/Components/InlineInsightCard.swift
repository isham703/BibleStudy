import SwiftUI
import UIKit

// MARK: - Inline Insight Card
// Primary component for displaying AI insights inline below the selected verse
// Design: Gold left accent bar, hero summary, expandable chips, deep study button
// Animation: Unfurls from top using sacred motion timing

struct InlineInsightCard: View {
    // MARK: - Properties

    let verseRange: VerseRange
    @Bindable var viewModel: InsightViewModel
    @Binding var isVisible: Bool
    let onOpenDeepStudy: () -> Void
    let onDismiss: () -> Void
    /// Callback to request scrolling when a section expands
    var onRequestScroll: ((String) -> Void)?
    /// Callback for copy action
    var onCopy: (() -> Void)?
    /// Callback for share action
    var onShare: (() -> Void)?
    /// Existing highlight color on the verse (if any)
    var existingHighlightColor: HighlightColor?
    /// Callback for highlight color selection
    var onSelectHighlightColor: ((HighlightColor) -> Void)?
    /// Callback to remove highlight
    var onRemoveHighlight: (() -> Void)?

    // MARK: - State

    @State private var isRevealed = false
    @State private var expandedSection: InsightSection?
    @State private var chipsRevealed = false

    /// ID for scrolling to expanded content
    private var expandedContentId: String {
        "insight-expanded-\(verseRange.verseEnd)"
    }

    // MARK: - Expanded Section Enum

    enum InsightSection: String, CaseIterable {
        case keyPoints = "Key Points"
        case context = "Context"
        case words = "Words"
        case crossRefs = "Cross-refs"

        var icon: String {
            switch self {
            case .keyPoints: return "list.bullet"
            case .context: return "text.alignleft"
            case .words: return "character.book.closed"
            case .crossRefs: return "arrow.triangle.branch"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Gold left accent bar (illuminated margin)
            goldAccentBar

            // Main content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                // Header with title and dismiss
                headerSection

                // Hero summary (2-3 lines) or limit reached message
                heroSummarySection

                // Hide all AI features when limit is reached
                if !viewModel.isLimitReached {
                    // Expandable chips row (Key Points, Context, Words, Cross-refs)
                    if chipsRevealed {
                        chipsSection
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Expanded section content (accordion)
                    if let section = expandedSection {
                        expandedContent(for: section)
                            .id(expandedContentId)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Deep study button
                    deepStudyButton
                }

                // Bottom action bar (icons + highlight colors) - always visible regardless of limit
                if isRevealed {
                    bottomActionBar
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .shadow(AppTheme.Shadow.medium)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.sm)
        .unfurlTransition(isActive: isRevealed)
        .onAppear {
            // Staggered reveal animation
            withAnimation(AppTheme.Animation.unfurl) {
                isRevealed = true
            }
            // Chips appear after main card
            withAnimation(AppTheme.Animation.sacredSpring.delay(0.5)) {
                chipsRevealed = true
            }
        }
    }

    // MARK: - Gold Accent Bar

    private var goldAccentBar: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.burnishedGold,
                        Color.divineGold,
                        Color.illuminatedGold
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 4)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: AppTheme.CornerRadius.card,
                    bottomLeadingRadius: AppTheme.CornerRadius.card,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
            )
            .shadow(color: Color.divineGold.opacity(AppTheme.Opacity.heavy), radius: AppTheme.Blur.medium, x: 0, y: 0)
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        Color.elevatedBackground
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            // Illuminated sparkle + title
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "sparkle")
                    .font(Typography.UI.iconXs)
                    .foregroundStyle(Color.divineGold)

                Text("ILLUMINATED INSIGHT")
                    .font(Typography.Codex.illuminatedHeader)
                    .tracking(Typography.Codex.headerTracking)
                    .foregroundStyle(Color.divineGold)
            }

            Spacer()

            // Dismiss button
            Button {
                HapticService.shared.lightTap()
                withAnimation(AppTheme.Animation.quick) {
                    isRevealed = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onDismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(Typography.UI.iconXs)
                    .foregroundStyle(Color.tertiaryText)
                    .frame(width: AppTheme.IconSize.medium + 8, height: AppTheme.IconSize.medium + 8)
                    .background(Color.surfaceBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Icon-only action buttons
            HStack(spacing: AppTheme.Spacing.sm) {
                // Copy button
                iconButton(
                    icon: "doc.on.doc",
                    accessibilityLabel: "Copy verse"
                ) {
                    if let onCopy = onCopy {
                        onCopy()
                    } else {
                        copyVerseToClipboard()
                    }
                }

                // Share button
                iconButton(
                    icon: "square.and.arrow.up",
                    accessibilityLabel: "Share verse"
                ) {
                    if let onShare = onShare {
                        onShare()
                    } else {
                        shareVerse()
                    }
                }
            }

            // Divider
            Rectangle()
                .fill(Color.divider)
                .frame(width: 1, height: 20)

            // Highlight color picker
            highlightColorsRow
        }
        .padding(.top, AppTheme.Spacing.sm)
    }

    // MARK: - Icon Button Helper

    private func iconButton(
        icon: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticService.shared.lightTap()
            action()
        } label: {
            Image(systemName: icon)
                .font(Typography.UI.iconMd)
                .foregroundStyle(Color.secondaryText)
                .frame(width: AppTheme.IconSize.xl + 4, height: AppTheme.IconSize.xl + 4)
                .background(
                    Circle()
                        .fill(Color.surfaceBackground)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Highlight Colors Row

    private var highlightColorsRow: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(HighlightColor.allCases, id: \.self) { color in
                highlightColorCircle(for: color)
            }
        }
    }

    private func highlightColorCircle(for color: HighlightColor) -> some View {
        let isSelected = existingHighlightColor == color

        return Button {
            HapticService.shared.verseHighlighted()
            onSelectHighlightColor?(color)
        } label: {
            Circle()
                .fill(color.color)
                .frame(width: AppTheme.IconSize.large, height: AppTheme.IconSize.large)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(Typography.UI.iconXxs)
                            .foregroundStyle(.white)
                    }
                }
                .overlay {
                    if isSelected {
                        Circle()
                            .stroke(Color.primaryText, lineWidth: AppTheme.Border.medium)
                            .frame(width: AppTheme.IconSize.medium + 8, height: AppTheme.IconSize.medium + 8)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Highlight \(color.displayName)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Copy/Share Helpers

    private func copyVerseToClipboard() {
        let text = "\"\(viewModel.verseText)\"\n— \(verseRange.reference)"
        UIPasteboard.general.string = text
        HapticService.shared.success()
    }

    private func shareVerse() {
        let text = "\"\(viewModel.verseText)\"\n\n— \(verseRange.reference)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    // MARK: - Hero Summary Section

    @ViewBuilder
    private var heroSummarySection: some View {
        if viewModel.isLimitReached {
            // Limit reached - show upgrade prompt
            limitReachedSection
        } else if viewModel.isLoadingExplain {
            // Loading state
            HStack(spacing: AppTheme.Spacing.sm) {
                ProgressView()
                    .scaleEffect(AppTheme.Scale.reduced)
                    .tint(Color.divineGold)

                Text("Illuminating this passage...")
                    .font(Typography.Codex.italic)
                    .foregroundStyle(Color.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AppTheme.Spacing.sm)
        } else if let structured = viewModel.structuredExplanation {
            // Hero summary text
            Text(structured.summary)
                .font(Typography.Codex.heroSummary)
                .foregroundStyle(Color.primaryText)
                .lineSpacing(Typography.Codex.heroLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        } else if let explanation = viewModel.explanation {
            // Fallback to first few sentences of explanation
            Text(extractHeroSummary(from: explanation))
                .font(Typography.Codex.heroSummary)
                .foregroundStyle(Color.primaryText)
                .lineSpacing(Typography.Codex.heroLineSpacing)
                .lineLimit(4)
        } else {
            // No content yet
            Text("Tap to explore this passage")
                .font(Typography.Codex.italic)
                .foregroundStyle(Color.secondaryText)
        }
    }

    // MARK: - Limit Reached Section

    private var limitReachedSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "lock.circle.fill")
                    .font(Typography.UI.iconXl)
                    .foregroundStyle(Color.divineGold)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text("Daily AI Insights Limit Reached")
                        .font(Typography.Codex.emphasis)
                        .foregroundStyle(Color.primaryText)

                    Text("You've used all 3 free insights today")
                        .font(Typography.Codex.caption)
                        .foregroundStyle(Color.secondaryText)
                }
            }

            // Upgrade button
            Button {
                HapticService.shared.lightTap()
                EntitlementManager.shared.showPaywall(trigger: .aiInsightsLimit)
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "sparkles")
                        .font(Typography.UI.iconXs)

                    Text("Upgrade for Unlimited Insights")
                        .font(Typography.Codex.emphasis)

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(Typography.UI.iconXs)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(Color.divineGold)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    // MARK: - Chips Section

    private var chipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(InsightSection.allCases, id: \.self) { section in
                    InsightChip(
                        title: section.rawValue,
                        icon: section.icon,
                        isSelected: expandedSection == section
                    ) {
                        withAnimation(AppTheme.Animation.sacredSpring) {
                            HapticService.shared.lightTap()
                            if expandedSection == section {
                                expandedSection = nil
                            } else {
                                expandedSection = section
                                loadSectionContent(section)
                                // Request scroll after a brief delay to allow content to appear
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onRequestScroll?(expandedContentId)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private func expandedContent(for section: InsightSection) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            switch section {
            case .keyPoints:
                keyPointsContent

            case .context:
                contextContent

            case .words:
                wordsContent

            case .crossRefs:
                crossRefsContent
            }
        }
        .padding(.top, AppTheme.Spacing.sm)
    }

    // MARK: - Key Points Content

    @ViewBuilder
    private var keyPointsContent: some View {
        if let structured = viewModel.structuredExplanation, !structured.keyPoints.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(Array(structured.keyPoints.enumerated()), id: \.offset) { _, point in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                        Circle()
                            .fill(Color.divineGold)
                            .frame(width: AppTheme.ComponentSize.dotSmall, height: AppTheme.ComponentSize.dotSmall)
                            .padding(.top, AppTheme.Spacing.xs + 2)

                        Text(point)
                            .font(Typography.Codex.body)
                            .foregroundStyle(Color.primaryText)
                            .lineSpacing(Typography.Codex.bodyLineSpacing)
                    }
                }
            }
        } else {
            Text("Key points will appear here")
                .font(Typography.Codex.caption)
                .foregroundStyle(Color.tertiaryText)
        }
    }

    // MARK: - Context Content

    @ViewBuilder
    private var contextContent: some View {
        if viewModel.isLoadingContext {
            ProgressView("Loading context...")
                .font(Typography.Codex.caption)
        } else if let context = viewModel.contextInfo {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                if !context.before.isEmpty {
                    contextBlock(title: "Before", text: context.before)
                }
                if !context.after.isEmpty {
                    contextBlock(title: "After", text: context.after)
                }
            }
        } else {
            Text("Context information unavailable")
                .font(Typography.Codex.caption)
                .foregroundStyle(Color.tertiaryText)
        }
    }

    private func contextBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
            Text(title.uppercased())
                .font(Typography.Codex.captionBold)
                .tracking(Typography.Codex.titleTracking)
                .foregroundStyle(Color.secondaryText)

            Text(text)
                .font(Typography.Codex.caption)
                .foregroundStyle(Color.primaryText)
                .lineLimit(3)
        }
    }

    // MARK: - Words Content

    @ViewBuilder
    private var wordsContent: some View {
        if viewModel.isLoadingLanguage {
            ProgressView("Loading word analysis...")
                .font(Typography.Codex.caption)
        } else if !viewModel.languageTokens.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(Array(viewModel.languageTokens.prefix(3)), id: \.id) { token in
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text(token.surface)
                            .font(Typography.Codex.greekSmall)
                            .foregroundStyle(Color.primaryText)

                        Text("(\(token.transliteration))")
                            .font(Typography.Codex.transliteration)
                            .foregroundStyle(Color.secondaryText)

                        Text("—")
                            .foregroundStyle(Color.tertiaryText)

                        Text(token.gloss)
                            .font(Typography.Codex.gloss)
                            .foregroundStyle(Color.divineGold)
                    }
                }

                if viewModel.languageTokens.count > 3 {
                    Text("+ \(viewModel.languageTokens.count - 3) more words")
                        .font(Typography.Codex.captionSmall)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
        } else {
            Text("No language data available")
                .font(Typography.Codex.caption)
                .foregroundStyle(Color.tertiaryText)
        }
    }

    // MARK: - Cross Refs Content

    @ViewBuilder
    private var crossRefsContent: some View {
        if viewModel.isLoadingCrossRefs {
            ProgressView("Loading cross-references...")
                .font(Typography.Codex.caption)
        } else if !viewModel.crossRefs.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(Array(viewModel.crossRefs.prefix(3)), id: \.id) { crossRef in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                        Rectangle()
                            .fill(Color.divineGold.opacity(AppTheme.Opacity.heavy))
                            .frame(width: AppTheme.Border.regular)

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                            Text(crossRef.reference)
                                .font(Typography.Codex.reference)
                                .foregroundStyle(Color.divineGold)

                            Text(crossRef.preview)
                                .font(Typography.Codex.caption)
                                .foregroundStyle(Color.primaryText)
                                .lineLimit(2)
                        }
                    }
                }

                if viewModel.crossRefs.count > 3 {
                    Text("+ \(viewModel.crossRefs.count - 3) more references")
                        .font(Typography.Codex.captionSmall)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
        } else {
            Text("No cross-references found")
                .font(Typography.Codex.caption)
                .foregroundStyle(Color.tertiaryText)
        }
    }

    // MARK: - Deep Study Button

    private var deepStudyButton: some View {
        Button {
            HapticService.shared.heavyTap()
            onOpenDeepStudy()
        } label: {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "book.pages")
                    .font(Typography.UI.iconSm)

                Text("Open Full Study Mode")
                    .font(Typography.Codex.emphasis)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.UI.iconXs)
            }
            .foregroundStyle(Color.divineGold)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(Color.divineGold.opacity(AppTheme.Opacity.subtle))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(Color.divineGold.opacity(AppTheme.Opacity.light), lineWidth: AppTheme.Border.thin)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Methods

    private func extractHeroSummary(from text: String) -> String {
        // Extract first 2-3 sentences for hero summary
        let sentences = text.components(separatedBy: ". ")
        let heroSentences = sentences.prefix(2)
        return heroSentences.joined(separator: ". ") + (heroSentences.count >= 2 ? "." : "")
    }

    private func loadSectionContent(_ section: InsightSection) {
        Task {
            switch section {
            case .keyPoints:
                // Already loaded with explanation
                break
            case .context:
                if viewModel.contextInfo == nil {
                    await viewModel.loadContext()
                }
            case .words:
                if viewModel.languageTokens.isEmpty {
                    await viewModel.loadLanguageTokens()
                }
            case .crossRefs:
                if viewModel.crossRefs.isEmpty {
                    await viewModel.loadCrossRefs()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Inline Insight Card") {
    struct PreviewContainer: View {
        @State private var isVisible = true

        var body: some View {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Simulated verse before
                    Text("19 So then you are no longer strangers and aliens, but you are fellow citizens with the saints and members of the household of God,")
                        .font(Typography.Illuminated.body())
                        .padding(.horizontal)

                    // Selected verse (highlighted)
                    Text("20 built on the foundation of the apostles and prophets, Christ Jesus himself being the cornerstone,")
                        .font(Typography.Illuminated.body())
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .stroke(Color.divineGold, lineWidth: AppTheme.Border.regular)
                        )
                        .padding(.horizontal)

                    // Inline insight card
                    if isVisible {
                        InlineInsightCard(
                            verseRange: VerseRange(bookId: 49, chapter: 2, verseStart: 20, verseEnd: 20),
                            viewModel: InsightViewModel(verseRange: VerseRange(bookId: 49, chapter: 2, verseStart: 20, verseEnd: 20)),
                            isVisible: $isVisible,
                            onOpenDeepStudy: { print("Open deep study") },
                            onDismiss: { isVisible = false }
                        )
                    }

                    // Simulated verse after
                    Text("21 in whom the whole structure, being joined together, grows into a holy temple in the Lord.")
                        .font(Typography.Illuminated.body())
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.appBackground)
        }
    }

    return PreviewContainer()
}

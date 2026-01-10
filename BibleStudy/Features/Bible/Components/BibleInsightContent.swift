import SwiftUI
import UIKit

struct BibleInsightContent: View {
    let verseRange: VerseRange
    @Bindable var viewModel: BibleInsightViewModel
    let onOpenDeepStudy: () -> Void
    let onDismiss: () -> Void

    var onRequestScroll: ((String) -> Void)?
    var onCopy: (() -> Void)?
    var onShare: (() -> Void)?
    var existingHighlightColor: HighlightColor?
    var onSelectHighlightColor: ((HighlightColor) -> Void)?
    var onRemoveHighlight: (() -> Void)?

    var accentBarWidth: CGFloat = 4
    var cornerRadius: CGFloat = Theme.Radius.card

    @Environment(\.colorScheme) private var colorScheme
    @State private var isRevealed = false
    @State private var expandedSection: InsightSection?
    @State private var chipsRevealed = false

    private var expandedContentId: String {
        "scholar-insight-\(verseRange.verseEnd)"
    }

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

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if accentBarWidth > 0 {
                indigoAccentBar
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                headerSection
                heroSummarySection

                if !viewModel.isLimitReached {
                    if chipsRevealed {
                        chipsSection
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if let section = expandedSection {
                        expandedContent(for: section)
                            .id(expandedContentId)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    deepStudyButton
                }

                if isRevealed {
                    bottomActionBar
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .opacity(isRevealed ? 1 : 0)
        .scaleEffect(y: isRevealed ? 1 : 0.97, anchor: .top)
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isRevealed = true
            }
            withAnimation(Theme.Animation.settle.delay(0.4)) {
                chipsRevealed = true
            }
        }
    }

    private var indigoAccentBar: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.decorativeGold, Color.accentBronze],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: accentBarWidth)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: cornerRadius,
                    bottomLeadingRadius: cornerRadius,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
            )
    }

    private var headerSection: some View {
        HStack {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "sparkle")
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                Text("SCHOLARLY INSIGHT")
                    .editorialLabel()
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            }

            Spacer()

            Button {
                HapticService.shared.lightTap()
                withAnimation(Theme.Animation.fade) {
                    isRevealed = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onDismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.tertiaryText)
                    .frame(width: 28, height: 28)
                    .background(Color.surfaceBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var heroSummarySection: some View {
        if viewModel.isLimitReached {
            limitReachedSection
        } else if viewModel.isLoadingExplain {
            HStack(spacing: Theme.Spacing.sm) {
                ProgressView()
                    // swiftlint:disable:next hardcoded_scale_effect
                    .scaleEffect(0.8)
                    .tint(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                Text("Analyzing passage...")
                    .insightItalic()
                    .foregroundStyle(Color.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Theme.Spacing.sm)
        } else if let structured = viewModel.structuredExplanation {
            Text(structured.summary)
                .insightHeroSummary()
                .foregroundStyle(Color.white)
                .fixedSize(horizontal: false, vertical: true)
        } else if let explanation = viewModel.explanation {
            Text(BibleInsightSummary.heroSummary(from: explanation))
                .insightHeroSummary()
                .foregroundStyle(Color.white)
                .lineLimit(4)
        } else {
            Text("Tap to explore this passage")
                .insightItalic()
                .foregroundStyle(Color.tertiaryText)
        }
    }

    private var limitReachedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "lock.circle.fill")
                    .font(Typography.Command.body)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Limit Reached")
                        .font(Typography.Command.label.weight(.semibold))
                        .foregroundStyle(Color.primaryText)

                    Text("Upgrade for unlimited insights")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.tertiaryText)
                }
            }

            Button {
                HapticService.shared.lightTap()
                EntitlementManager.shared.showPaywall(trigger: .aiInsightsLimit)
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "sparkles")
                        .font(Typography.Command.caption)

                    Text("Unlock Unlimited")
                        .font(Typography.Command.caption.weight(.semibold))

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(Typography.Command.caption)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }

    private var chipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(InsightSection.allCases, id: \.self) { section in
                    BibleChip(
                        title: section.rawValue,
                        icon: section.icon,
                        isSelected: expandedSection == section
                    ) {
                        withAnimation(Theme.Animation.settle) {
                            HapticService.shared.lightTap()
                            if expandedSection == section {
                                expandedSection = nil
                            } else {
                                expandedSection = section
                                loadSectionContent(section)
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

    @ViewBuilder
    private func expandedContent(for section: InsightSection) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
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
        .padding(.top, Theme.Spacing.sm)
    }

    @ViewBuilder
    private var keyPointsContent: some View {
        if let structured = viewModel.structuredExplanation, !structured.keyPoints.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ForEach(Array(structured.keyPoints.enumerated()), id: \.offset) { _, point in
                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        Circle()
                            .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                            // swiftlint:disable:next hardcoded_indicator_size
                            .frame(width: 5, height: 5)
                            // swiftlint:disable:next hardcoded_padding_edge
                            .padding(.top, 7)

                        Text(point)
                            .insightBody()
                            .foregroundStyle(Color.primaryText)
                    }
                }
            }
        } else {
            Text("Key points will appear here")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.tertiaryText)
        }
    }

    @ViewBuilder
    private var contextContent: some View {
        if viewModel.isLoadingContext {
            ProgressView("Loading context...")
                .font(Typography.Command.caption)
        } else if let context = viewModel.contextInfo {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                if !context.before.isEmpty {
                    contextBlock(title: "Before", text: context.before)
                }
                if !context.after.isEmpty {
                    contextBlock(title: "After", text: context.after)
                }
            }
        } else {
            Text("Context information unavailable")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.tertiaryText)
        }
    }

    private func contextBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .editorialLabel()
                .foregroundStyle(Color.tertiaryText)

            Text(text)
                .insightBody()
                .foregroundStyle(Color.primaryText)
                .lineLimit(3)
        }
    }

    @ViewBuilder
    private var wordsContent: some View {
        if viewModel.isLoadingLanguage {
            ProgressView("Loading word analysis...")
                .font(Typography.Command.caption)
        } else if !viewModel.languageTokens.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ForEach(Array(viewModel.languageTokens.prefix(3)), id: \.id) { token in
                    HStack(spacing: Theme.Spacing.sm) {
                        Text(token.surface)
                            .font(Typography.Command.body.weight(.medium))
                            .foregroundStyle(Color.navyDeep)

                        Text("(\(token.transliteration))")
                            .font(Typography.Command.caption)
                            .italic()
                            .foregroundStyle(Color.tertiaryText)

                        Text("—")
                            .foregroundStyle(Color.tertiaryText)

                        Text(token.gloss)
                            .font(Typography.Command.caption.weight(.medium))
                            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    }
                }

                if viewModel.languageTokens.count > 3 {
                    Text("+ \(viewModel.languageTokens.count - 3) more words")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
        } else {
            Text("No language data available")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.tertiaryText)
        }
    }

    @ViewBuilder
    private var crossRefsContent: some View {
        if viewModel.isLoadingCrossRefs {
            ProgressView("Loading cross-references...")
                .font(Typography.Command.caption)
        } else if !viewModel.crossRefs.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ForEach(Array(viewModel.crossRefs.prefix(3)), id: \.id) { crossRef in
                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        Rectangle()
                            .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.strong))
                            .frame(width: Theme.Stroke.control)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(crossRef.reference)
                                .font(Typography.Command.caption.weight(.semibold))
                                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                            Text(crossRef.preview)
                                .insightBody()
                                .foregroundStyle(Color.primaryText)
                                .lineLimit(2)
                        }
                    }
                }

                if viewModel.crossRefs.count > 3 {
                    Text("+ \(viewModel.crossRefs.count - 3) more references")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
        } else {
            Text("No cross-references found")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.tertiaryText)
        }
    }

    private var deepStudyButton: some View {
        Button {
            HapticService.shared.heavyTap()
            onOpenDeepStudy()
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "book.pages")
                    .font(Typography.Command.caption)

                Text("Open Full Study")
                    .font(Typography.Command.caption.weight(.semibold))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption)
            }
            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .stroke(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light), lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }

    private var bottomActionBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                scholarIconButton(icon: "doc.on.doc", label: "Copy") {
                    if let onCopy = onCopy {
                        onCopy()
                    } else {
                        copyVerseToClipboard()
                    }
                }

                scholarIconButton(icon: "square.and.arrow.up", label: "Share") {
                    if let onShare = onShare {
                        onShare()
                    } else {
                        shareVerse()
                    }
                }
            }

        }
        .padding(.top, Theme.Spacing.sm)
    }

    private func scholarIconButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticService.shared.lightTap()
            action()
        } label: {
            Image(systemName: icon)
                .font(Typography.Command.body)
                .foregroundStyle(Color.tertiaryText)
                .frame(width: 36, height: 36)
                .background(Color.surfaceBackground)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }


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

    private func loadSectionContent(_ section: InsightSection) {
        Task {
            switch section {
            case .keyPoints:
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

private struct BibleChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(Typography.Command.caption)

                Text(title)
                    .font(Typography.Command.caption.weight(isSelected ? .semibold : .regular))

                if isSelected {
                    Image(systemName: "chevron.down")
                        .font(Typography.Command.caption)
                }
            }
            .foregroundStyle(isSelected ? Color.white : Color.tertiaryText)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentBronze : Color.gray.opacity(Theme.Opacity.light))
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.medium) : Color.clear,
                        lineWidth: Theme.Stroke.hairline
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            // swiftlint:disable:next hardcoded_animation_spring
            withAnimation(Theme.Animation.settle) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel("\(title) section")
        .accessibilityHint(isSelected ? "Currently expanded" : "Double tap to expand")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

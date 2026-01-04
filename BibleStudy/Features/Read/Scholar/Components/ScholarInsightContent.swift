import SwiftUI
import UIKit

struct ScholarInsightContent: View {
    let verseRange: VerseRange
    @Bindable var viewModel: InsightViewModel
    let onOpenDeepStudy: () -> Void
    let onDismiss: () -> Void

    var onRequestScroll: ((String) -> Void)?
    var onCopy: (() -> Void)?
    var onShare: (() -> Void)?
    var existingHighlightColor: HighlightColor?
    var onSelectHighlightColor: ((HighlightColor) -> Void)?
    var onRemoveHighlight: (() -> Void)?

    var accentBarWidth: CGFloat = 4
    var cornerRadius: CGFloat = AppTheme.CornerRadius.card

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

            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
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
            .padding(AppTheme.Spacing.lg)
        }
        .opacity(isRevealed ? 1 : 0)
        .scaleEffect(y: isRevealed ? 1 : 0.97, anchor: .top)
        .onAppear {
            withAnimation(AppTheme.Animation.cardUnfurl) {
                isRevealed = true
            }
            withAnimation(AppTheme.Animation.chipExpand.delay(0.4)) {
                chipsRevealed = true
            }
        }
    }

    private var indigoAccentBar: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: AppTheme.InsightCard.barGradient,
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
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "sparkle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.scholarIndigo)

                Text("SCHOLARLY INSIGHT")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(Color.scholarIndigo)
            }

            Spacer()

            Button {
                HapticService.shared.lightTap()
                withAnimation(AppTheme.Animation.selection) {
                    isRevealed = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onDismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.footnoteGray)
                    .frame(width: 28, height: 28)
                    .background(Color.scholarElevatedPaper)
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
            HStack(spacing: AppTheme.Spacing.sm) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(Color.scholarIndigo)

                Text("Analyzing passage...")
                    .font(.custom("CormorantGaramond-Regular", size: 15))
                    .italic()
                    .foregroundStyle(Color.footnoteGray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AppTheme.Spacing.sm)
        } else if let structured = viewModel.structuredExplanation {
            Text(structured.summary)
                .font(.custom("CormorantGaramond-Regular", size: 17))
                .foregroundStyle(AppTheme.InsightCard.heroText)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        } else if let explanation = viewModel.explanation {
            Text(ScholarInsightSummary.heroSummary(from: explanation))
                .font(.custom("CormorantGaramond-Regular", size: 17))
                .foregroundStyle(AppTheme.InsightCard.heroText)
                .lineSpacing(5)
                .lineLimit(4)
        } else {
            Text("Tap to explore this passage")
                .font(.custom("CormorantGaramond-Regular", size: 15))
                .italic()
                .foregroundStyle(Color.footnoteGray)
        }
    }

    private var limitReachedSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.scholarIndigo)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Limit Reached")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.scholarInk)

                    Text("Upgrade for unlimited insights")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.footnoteGray)
                }
            }

            Button {
                HapticService.shared.lightTap()
                EntitlementManager.shared.showPaywall(trigger: .aiInsightsLimit)
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .medium))

                    Text("Unlock Unlimited")
                        .font(.system(size: 13, weight: .semibold))

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(Color.scholarIndigo)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    private var chipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(InsightSection.allCases, id: \.self) { section in
                    ScholarChip(
                        title: section.rawValue,
                        icon: section.icon,
                        isSelected: expandedSection == section
                    ) {
                        withAnimation(AppTheme.Animation.chipExpand) {
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

    @ViewBuilder
    private var keyPointsContent: some View {
        if let structured = viewModel.structuredExplanation, !structured.keyPoints.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(Array(structured.keyPoints.enumerated()), id: \.offset) { _, point in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                        Circle()
                            .fill(Color.scholarIndigo)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)

                        Text(point)
                            .font(.custom("CormorantGaramond-Regular", size: 15))
                            .foregroundStyle(Color.scholarInk)
                            .lineSpacing(4)
                    }
                }
            }
        } else {
            Text("Key points will appear here")
                .font(.system(size: 13))
                .foregroundStyle(Color.footnoteGray)
        }
    }

    @ViewBuilder
    private var contextContent: some View {
        if viewModel.isLoadingContext {
            ProgressView("Loading context...")
                .font(.system(size: 13))
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
                .font(.system(size: 13))
                .foregroundStyle(Color.footnoteGray)
        }
    }

    private func contextBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundStyle(Color.footnoteGray)

            Text(text)
                .font(.custom("CormorantGaramond-Regular", size: 14))
                .foregroundStyle(Color.scholarInk)
                .lineLimit(3)
        }
    }

    @ViewBuilder
    private var wordsContent: some View {
        if viewModel.isLoadingLanguage {
            ProgressView("Loading word analysis...")
                .font(.system(size: 13))
        } else if !viewModel.languageTokens.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(Array(viewModel.languageTokens.prefix(3)), id: \.id) { token in
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text(token.surface)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.greekBlue)

                        Text("(\(token.transliteration))")
                            .font(.system(size: 13))
                            .italic()
                            .foregroundStyle(Color.footnoteGray)

                        Text("—")
                            .foregroundStyle(Color.footnoteGray)

                        Text(token.gloss)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.scholarIndigo)
                    }
                }

                if viewModel.languageTokens.count > 3 {
                    Text("+ \(viewModel.languageTokens.count - 3) more words")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.footnoteGray)
                }
            }
        } else {
            Text("No language data available")
                .font(.system(size: 13))
                .foregroundStyle(Color.footnoteGray)
        }
    }

    @ViewBuilder
    private var crossRefsContent: some View {
        if viewModel.isLoadingCrossRefs {
            ProgressView("Loading cross-references...")
                .font(.system(size: 13))
        } else if !viewModel.crossRefs.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(Array(viewModel.crossRefs.prefix(3)), id: \.id) { crossRef in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                        Rectangle()
                            .fill(Color.scholarIndigo.opacity(0.6))
                            .frame(width: 2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(crossRef.reference)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.scholarIndigo)

                            Text(crossRef.preview)
                                .font(.custom("CormorantGaramond-Regular", size: 14))
                                .foregroundStyle(Color.scholarInk)
                                .lineLimit(2)
                        }
                    }
                }

                if viewModel.crossRefs.count > 3 {
                    Text("+ \(viewModel.crossRefs.count - 3) more references")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.footnoteGray)
                }
            }
        } else {
            Text("No cross-references found")
                .font(.system(size: 13))
                .foregroundStyle(Color.footnoteGray)
        }
    }

    private var deepStudyButton: some View {
        Button {
            HapticService.shared.heavyTap()
            onOpenDeepStudy()
        } label: {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "book.pages")
                    .font(.system(size: 13, weight: .medium))

                Text("Open Full Study")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(Color.scholarIndigo)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(Color.scholarIndigoSubtle)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(Color.scholarIndigo.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var bottomActionBar: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
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
        .padding(.top, AppTheme.Spacing.sm)
    }

    private func scholarIconButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticService.shared.lightTap()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.footnoteGray)
                .frame(width: 36, height: 36)
                .background(Color.scholarElevatedPaper)
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

private struct ScholarChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))

                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))

                if isSelected {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .medium))
                }
            }
            .foregroundStyle(isSelected ? AppTheme.InsightCard.chipText : Color.footnoteGray)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? AppTheme.InsightCard.chipSelected : AppTheme.InsightCard.chipBackground)
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.scholarIndigo.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel("\(title) section")
        .accessibilityHint(isSelected ? "Currently expanded" : "Double tap to expand")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

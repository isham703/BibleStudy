//
//  UnifiedContextMenu.swift
//  BibleStudy
//
//  Unified floating context menu for verse selection across all readers.
//  Combines IlluminatedContextMenu (insight-first) and ScholarContextMenu (actions-first)
//  into a single component with mode switching.
//
//  Design Philosophy:
//  - One component, two modes: insightFirst (Read tab) and actionsFirst (Scholar tab)
//  - Consistent gesture vocabulary: tap verse → menu appears
//  - NO double-tap gestures (removed for clarity)
//  - Accent color adapts to mode: gold (insight) vs indigo (actions)
//

import SwiftUI

// MARK: - Menu Mode

/// Determines the presentation style of the unified context menu
enum UnifiedMenuMode {
    /// Read tab: Insight is the hero element, actions below
    case insightFirst
    /// Scholar tab: Actions only, no insight preview
    case actionsFirst

    /// Accent color for this mode
    var accentColor: Color {
        switch self {
        case .insightFirst: return Color("AccentBronze")
        case .actionsFirst: return Color("AppAccentAction")
        }
    }

    /// Standardized menu width for both modes
    var menuWidth: CGFloat { 300 }
}

// MARK: - Unified Context Menu

/// A unified floating context menu for selected verses.
/// Supports two modes: insight-first (Read tab) and actions-first (Scholar tab).
struct UnifiedContextMenu: View {

    // MARK: - Properties

    /// Menu presentation mode
    let mode: UnifiedMenuMode

    let verseRange: VerseRange
    let selectionBounds: CGRect
    let containerBounds: CGRect
    let safeAreaInsets: EdgeInsets
    let existingHighlightColor: HighlightColor?

    // MARK: - Insight Properties (insightFirst mode only)

    let insight: QuickInsightOutput?
    let isInsightLoading: Bool
    let isLimitReached: Bool

    // MARK: - Action Callbacks

    let onCopy: () -> Void
    let onShare: () -> Void
    let onNote: () -> Void
    let onHighlight: (HighlightColor) -> Void
    let onRemoveHighlight: () -> Void
    let onStudy: () -> Void
    let onDismiss: () -> Void

    /// Callback for opening inline insight card (insightFirst mode)
    var onOpenInlineInsight: (() -> Void)?

    // MARK: - Animation State

    @State private var isAppearing = false
    @State private var insightRevealed = false
    @State private var measuredHeight: CGFloat?
    private var keyboardObserver: KeyboardHeightObserver { .shared }
    @State private var highlightExpanded = false

    @Environment(\.colorScheme) private var colorScheme

    // Audio service for pause/resume during insight viewing
    private let audioService = AudioService.shared

    // MARK: - Positioning

    private var positionCalculator: MenuPositionCalculator {
        MenuPositionCalculator(
            selectionBounds: selectionBounds,
            containerBounds: containerBounds,
            safeAreaInsets: safeAreaInsets,
            keyboardHeight: keyboardObserver.keyboardHeight
        )
    }

    private var menuPosition: IlluminatedMenuPosition {
        let defaultHeight: CGFloat = mode == .insightFirst ? 180 : 140
        return positionCalculator.calculatePosition(menuHeight: measuredHeight ?? defaultHeight)
    }

    // MARK: - Body

    var body: some View {
        let position = menuPosition

        ZStack(alignment: .topLeading) {
            menuCard
                .background(measurementBackground)
                .position(
                    x: position.origin.x + mode.menuWidth / 2,
                    y: position.origin.y + (measuredHeight ?? 180) / 2
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Pause audio if playing (insightFirst mode only)
            if mode == .insightFirst {
                audioService.pauseForInterruption()
            }

            withAnimation(Theme.Animation.settle) {
                isAppearing = true
            }

            // Staggered insight reveal (insightFirst mode only)
            if mode == .insightFirst {
                withAnimation(Theme.Animation.slowFade.delay(0.15)) {
                    insightRevealed = true
                }
            }
        }
        .onDisappear {
            // Resume audio if it was playing before insight appeared
            if mode == .insightFirst {
                audioService.resumeAfterInterruption()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Verse actions for \(verseRange.reference)")
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - Menu Card

    private var menuCard: some View {
        VStack(spacing: 0) {
            // HERO: Insight section (insightFirst mode only)
            if mode == .insightFirst {
                insightSection
                thinDivider
            }

            // Action bar
            switch mode {
            case .insightFirst:
                compactActionBar
            case .actionsFirst:
                scholarActionRow
                scholarDivider
                highlightRow
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .overlay(cardBorder)
        .shadow(
            color: .black.opacity(colorScheme == .dark ? Theme.Opacity.textSecondary : Theme.Opacity.selectionBackground),
            radius: 20,
            x: 0,
            y: 8
        )
        .frame(width: mode.menuWidth)
        .opacity(isAppearing ? 1 : 0)
        .scaleEffect(isAppearing ? 1 : 0.92)
        .offset(y: isAppearing ? 0 : (menuPosition.arrowDirection == .up ? -10 : 10))
    }

    // MARK: - Card Background & Border

    private var cardBackground: some View {
        Color.appSurface
    }

    private var cardBorder: some View {
        // Simple hairline border (no gradient - per design system "authority over decoration")
        return RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
            .stroke(
                Color.appDivider,
                lineWidth: Theme.Stroke.hairline
            )
    }

    // MARK: - Dividers

    private var thinDivider: some View {
        return Rectangle()
            .fill(mode.accentColor.opacity(Theme.Opacity.selectionBackground))
            .frame(height: Theme.Stroke.hairline)
            .padding(.horizontal, Theme.Spacing.sm)
    }

    private var scholarDivider: some View {
        Rectangle()
            .fill(Color.appDivider)
            .frame(height: Theme.Stroke.hairline)
            .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - HERO: Insight Section (insightFirst mode)

    private var insightSection: some View {
        Button {
            HapticService.shared.lightTap()
            // Use inline insight callback if available, otherwise fall back to legacy sheet
            if let openInline = onOpenInlineInsight {
                // Dismiss context menu first, then open inline card
                withAnimation(Theme.Animation.fade) {
                    isAppearing = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    onDismiss()
                    openInline()
                }
            } else {
                onStudy()
            }
        } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                if isLimitReached {
                    limitReachedView
                } else if isInsightLoading {
                    loadingInsightView
                } else if let insight = insight {
                    fullInsightView(insight)
                } else {
                    noInsightView
                }
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Loading Insight View

    private var loadingInsightView: some View {
        return HStack(spacing: Theme.Spacing.sm) {
            ProgressView()
                .scaleEffect(0.98)
                .tint(Color("AccentBronze"))

            Text("Illuminating this passage...")
                .font(Typography.Scripture.quote)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Full Insight View

    @ViewBuilder
    private func fullInsightView(_ insight: QuickInsightOutput) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkle")
                .font(Typography.Icon.sm.weight(.semibold))
                .foregroundStyle(Color("AccentBronze"))
                .padding(.top, 2 + 1)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs + 2) {
                Text(insight.summary)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineSpacing(Typography.Scripture.bodyLineSpacing)
                    .lineLimit(5)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(insightRevealed ? 1 : 0)

                // Key term (if present)
                if let term = insight.keyTerm, let meaning = insight.keyTermMeaning {
                    keyTermView(term: term, meaning: meaning)
                        .opacity(insightRevealed ? 1 : 0)
                        .offset(y: insightRevealed ? 0 : Theme.Spacing.xs)
                }
            }

            Spacer(minLength: 0)

            // Chevron for "tap for more"
            Image(systemName: "chevron.right")
                .font(Typography.Icon.xs)
                .foregroundStyle(Color("TertiaryText"))
                .padding(.top, Theme.Spacing.xs)
        }
    }

    // MARK: - Key Term View

    private func keyTermView(term: String, meaning: String) -> some View {
        return HStack(spacing: Theme.Spacing.xs + 2) {
            Text(term)
                .font(Typography.Command.caption)
                .foregroundStyle(Color("AccentBronze"))

            Text("—")
                .font(Typography.Scripture.footnote)
                .foregroundStyle(Color("TertiaryText"))

            Text(meaning)
                .font(Typography.Scripture.footnote)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)
        }
        .padding(.top, 2)
    }

    // MARK: - No Insight View

    private var noInsightView: some View {
        return HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkle")
                .font(Typography.Icon.sm)
                .foregroundStyle(Color("AccentBronze"))

            Text("Tap to explore this passage")
                .font(Typography.Scripture.quote)
                .foregroundStyle(Color("AppTextSecondary"))

            Spacer()

            Image(systemName: "chevron.right")
                .font(Typography.Icon.xxs)
                .foregroundStyle(Color("TertiaryText"))
        }
    }

    // MARK: - Limit Reached View

    private var limitReachedView: some View {
        return HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "lock.fill")
                .font(Typography.Icon.sm)
                .foregroundStyle(Color("AccentBronze"))

            VStack(alignment: .leading, spacing: 2) {
                Text("Daily limit reached")
                    .font(Typography.Scripture.quote)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text("Upgrade for unlimited insights")
                    .font(Typography.Scripture.footnote)
                    .foregroundStyle(Color("AppTextSecondary"))
            }

            Spacer()

            Image(systemName: "arrow.right.circle.fill")
                .font(Typography.Icon.lg)
                .foregroundStyle(Color("AccentBronze"))
        }
        .opacity(insightRevealed ? 1 : 0)
    }

    // MARK: - Compact Action Bar (insightFirst mode)

    private var compactActionBar: some View {
        return HStack(spacing: Theme.Spacing.md) {
            // Quick action icons - using shared component
            HStack(spacing: Theme.Spacing.xs) {
                ContextMenuActionButton.compact(icon: "doc.on.doc", label: "Copy") {
                    HapticService.shared.success()
                    onCopy()
                }

                ContextMenuActionButton.compact(icon: "square.and.arrow.up", label: "Share") {
                    HapticService.shared.lightTap()
                    onShare()
                }

                ContextMenuActionButton.compact(icon: "note.text", label: "Note") {
                    HapticService.shared.lightTap()
                    onNote()
                }
            }

            // Subtle vertical separator
            Rectangle()
                .fill(mode.accentColor.opacity(Theme.Opacity.selectionBackground))
                .frame(width: Theme.Stroke.hairline, height: Theme.Spacing.xl)

            // Color palette - using shared component
            HStack(spacing: Theme.Spacing.xs + 2) {
                ForEach(HighlightColor.allCases, id: \.self) { color in
                    ContextMenuColorDot.compact(
                        color: color,
                        isSelected: existingHighlightColor == color,
                        accentColor: mode.accentColor
                    ) {
                        HapticService.shared.verseHighlighted()
                        onHighlight(color)
                    }
                }

                if existingHighlightColor != nil {
                    Button {
                        HapticService.shared.lightTap()
                        onRemoveHighlight()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(Typography.Icon.lg)
                            .foregroundStyle(Color("TertiaryText"))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.sm + 2)
    }

    // MARK: - Scholar Action Row (actionsFirst mode)

    private var scholarActionRow: some View {
        HStack(spacing: Theme.Spacing.xs) {
            // Action buttons - using shared component
            ContextMenuActionButton.standard(icon: "doc.on.doc", label: "Copy") {
                HapticService.shared.success()
                onCopy()
            }

            ContextMenuActionButton.standard(icon: "square.and.arrow.up", label: "Share") {
                HapticService.shared.lightTap()
                onShare()
            }

            ContextMenuActionButton.standard(icon: "note.text", label: "Note") {
                HapticService.shared.lightTap()
                onNote()
            }

            // Vertical separator - using semantic color per design system
            Rectangle()
                .fill(Color("AppDivider"))
                .frame(width: Theme.Stroke.hairline, height: 32)

            // Study button with indigo accent - using shared component
            ContextMenuActionButton.accented(icon: "book", label: "Study") {
                HapticService.shared.mediumTap()
                onStudy()
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Highlight Row (actionsFirst mode)
    // 2-tap progressive disclosure: "Highlight..." → color picker
    // CRITICAL: Fixed-width layout to prevent drift on expansion
    // All elements use identical frame constraints regardless of state

    private var highlightRow: some View {
        // Fixed-width container - never changes regardless of content
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            if highlightExpanded || existingHighlightColor != nil {
                // Label above dots
                Text("Choose color")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Expanded: show color dots in fixed 44pt slots - using shared component
                // Tap selected dot again to remove highlight
                HStack(spacing: 0) {
                    ForEach(HighlightColor.allCases, id: \.self) { color in
                        ContextMenuColorDot.standard(
                            color: color,
                            isSelected: existingHighlightColor == color
                        ) {
                            if existingHighlightColor == color {
                                HapticService.shared.lightTap()
                                onRemoveHighlight()
                            } else {
                                HapticService.shared.verseHighlighted()
                                onHighlight(color)
                            }
                        }
                    }
                    // Spacer fills remaining width to keep layout stable
                    Spacer(minLength: 0)
                }
            } else {
                // Collapsed: "Highlight..." row with identical frame constraints
                Button {
                    HapticService.shared.lightTap()
                    withAnimation(Theme.Animation.fade) {
                        highlightExpanded = true
                    }
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text("Highlight…")
                            .font(Typography.Command.meta)
                            .foregroundStyle(Color("AppTextSecondary"))

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(Typography.Icon.xxs)
                            .foregroundStyle(Color("TertiaryText"))
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        // Fixed frame constraints - identical for all states
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm + 2)
        // Animate only opacity/content, not layout
        .animation(Theme.Animation.fade, value: highlightExpanded)
    }

    // MARK: - Measurement

    private var measurementBackground: some View {
        GeometryReader { geo in
            Color.clear.onAppear { measuredHeight = geo.size.height }
                .onChange(of: geo.size.height) { _, h in measuredHeight = h }
        }
    }
}

// MARK: - Previews
// Note: Legacy button/color dot components have been moved to shared files:
// - ContextMenuActionButton.swift
// - ContextMenuColorDot.swift

#Preview("Unified Menu - Insight First (Read Tab)") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()

        VStack {
            Text("10  For we are his workmanship, created in Christ Jesus unto good works.")
                .font(Typography.Scripture.body)
                .padding()
                .background(Color.yellow.opacity(Theme.Opacity.divider))
                .padding(.top, 200)

            Spacer()
        }

        UnifiedContextMenu(
            mode: .insightFirst,
            verseRange: VerseRange(bookId: 49, chapter: 2, verseStart: 10, verseEnd: 10),
            selectionBounds: CGRect(x: 20, y: 100, width: 350, height: 80),
            containerBounds: CGRect(x: 0, y: 0, width: 393, height: 852),
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0),
            existingHighlightColor: nil,
            insight: QuickInsightOutput(
                summary: "We are designed by God for purposeful living, emphasizing that our good works are part of His plan.",
                keyTerm: "workmanship",
                keyTermMeaning: "refers to being crafted",
                suggestedAction: .viewLanguage
            ),
            isInsightLoading: false,
            isLimitReached: false,
            onCopy: {},
            onShare: {},
            onNote: {},
            onHighlight: { _ in },
            onRemoveHighlight: {},
            onStudy: {},
            onDismiss: {}
        )
    }
}

#Preview("Unified Menu - Actions First (Scholar Tab)") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()

        VStack {
            Text("10  For we are his workmanship, created in Christ Jesus unto good works.")
                .font(Typography.Scripture.body)
                .padding()
                .background(Color("AppAccentAction").opacity(Theme.Opacity.overlay))
                .padding(.top, 180)

            Spacer()
        }

        UnifiedContextMenu(
            mode: .actionsFirst,
            verseRange: VerseRange(bookId: 49, chapter: 2, verseStart: 10, verseEnd: 10),
            selectionBounds: CGRect(x: 20, y: 100, width: 350, height: 60),
            containerBounds: CGRect(x: 0, y: 0, width: 393, height: 852),
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0),
            existingHighlightColor: nil,
            insight: nil,
            isInsightLoading: false,
            isLimitReached: false,
            onCopy: {},
            onShare: {},
            onNote: {},
            onHighlight: { _ in },
            onRemoveHighlight: {},
            onStudy: {},
            onDismiss: {}
        )
    }
}

#Preview("Unified Menu - Loading Insight") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()

        UnifiedContextMenu(
            mode: .insightFirst,
            verseRange: VerseRange(bookId: 1, chapter: 1, verseStart: 3, verseEnd: 3),
            selectionBounds: CGRect(x: 50, y: 200, width: 300, height: 40),
            containerBounds: CGRect(x: 0, y: 0, width: 393, height: 852),
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0),
            existingHighlightColor: nil,
            insight: nil,
            isInsightLoading: true,
            isLimitReached: false,
            onCopy: {},
            onShare: {},
            onNote: {},
            onHighlight: { _ in },
            onRemoveHighlight: {},
            onStudy: {},
            onDismiss: {}
        )
    }
}

#Preview("Unified Menu - With Highlight (Scholar)") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()

        UnifiedContextMenu(
            mode: .actionsFirst,
            verseRange: VerseRange(bookId: 1, chapter: 1, verseStart: 1, verseEnd: 3),
            selectionBounds: CGRect(x: 50, y: 300, width: 300, height: 100),
            containerBounds: CGRect(x: 0, y: 0, width: 393, height: 852),
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0),
            existingHighlightColor: .blue,
            insight: nil,
            isInsightLoading: false,
            isLimitReached: false,
            onCopy: {},
            onShare: {},
            onNote: {},
            onHighlight: { _ in },
            onRemoveHighlight: {},
            onStudy: {},
            onDismiss: {}
        )
    }
}

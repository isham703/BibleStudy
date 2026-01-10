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

    /// Accent color for this mode (theme-aware)
    func accentColor(for mode: ThemeMode) -> Color {
        switch self {
        case .insightFirst: return Colors.Semantic.accentSeal(for: mode)
        case .actionsFirst: return Colors.Semantic.accentAction(for: mode)
        }
    }

    /// Menu width varies by mode
    var menuWidth: CGFloat {
        switch self {
        case .insightFirst: return 300
        case .actionsFirst: return 280
        }
    }
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
    @State private var keyboardObserver = KeyboardHeightObserver()

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
        GeometryReader { _ in
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
        }
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
            color: .black.opacity(colorScheme == .dark ? Theme.Opacity.heavy : Theme.Opacity.light),
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
        Colors.Surface.surface(for: ThemeMode.current(from: colorScheme))
    }

    private var cardBorder: some View {
        let mode = ThemeMode.current(from: colorScheme)
        return RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        self.mode.accentColor(for: mode).opacity(Theme.Opacity.heavy),
                        self.mode.accentColor(for: mode).opacity(Theme.Opacity.quarter)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: Theme.Stroke.hairline
            )
    }

    // MARK: - Dividers

    private var thinDivider: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        return Rectangle()
            .fill(mode.accentColor(for: themeMode).opacity(Theme.Opacity.lightMedium))
            .frame(height: Theme.Stroke.hairline)
            .padding(.horizontal, 12)
    }

    private var scholarDivider: some View {
        Rectangle()
            .fill(Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)))
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
            .padding(.horizontal, 12)
            .padding(.vertical, Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Loading Insight View

    private var loadingInsightView: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        return HStack(spacing: Theme.Spacing.sm) {
            ProgressView()
                .scaleEffect(0.98)
                .tint(Colors.Semantic.accentSeal(for: themeMode))

            Text("Illuminating this passage...")
                .font(Typography.Scripture.quote)
                .foregroundStyle(Colors.Surface.textSecondary(for: themeMode))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Full Insight View

    @ViewBuilder
    private func fullInsightView(_ insight: QuickInsightOutput) -> some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkle")
                .font(Typography.Icon.sm.weight(.semibold))
                .foregroundStyle(Colors.Semantic.accentSeal(for: themeMode))
                .padding(.top, 2 + 1)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs + 2) {
                Text(insight.summary)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Colors.Surface.textPrimary(for: themeMode))
                    .lineSpacing(Typography.Scripture.bodyLineSpacing)
                    .lineLimit(5)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(insightRevealed ? 1 : 0)
                    .blur(radius: insightRevealed ? 0 : Theme.Spacing.xs)

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
                .foregroundStyle(Colors.Surface.textTertiary(for: themeMode))
                .padding(.top, Theme.Spacing.xs)
        }
    }

    // MARK: - Key Term View

    private func keyTermView(term: String, meaning: String) -> some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        return HStack(spacing: Theme.Spacing.xs + 2) {
            Text(term)
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Semantic.accentSeal(for: themeMode))

            Text("—")
                .font(Typography.Scripture.footnote)
                .foregroundStyle(Colors.Surface.textTertiary(for: themeMode))

            Text(meaning)
                .font(Typography.Scripture.footnote)
                .foregroundStyle(Colors.Surface.textSecondary(for: themeMode))
                .lineLimit(1)
        }
        .padding(.top, 2)
    }

    // MARK: - No Insight View

    private var noInsightView: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        return HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkle")
                .font(Typography.Icon.sm)
                .foregroundStyle(Colors.Semantic.accentSeal(for: themeMode))

            Text("Tap to explore this passage")
                .font(Typography.Scripture.quote)
                .foregroundStyle(Colors.Surface.textSecondary(for: themeMode))

            Spacer()

            Image(systemName: "chevron.right")
                .font(Typography.Icon.xxs)
                .foregroundStyle(Colors.Surface.textTertiary(for: themeMode))
        }
    }

    // MARK: - Limit Reached View

    private var limitReachedView: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        return HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "lock.fill")
                .font(Typography.Icon.sm)
                .foregroundStyle(Colors.Semantic.accentSeal(for: themeMode))

            VStack(alignment: .leading, spacing: 2) {
                Text("Daily limit reached")
                    .font(Typography.Scripture.quote)
                    .foregroundStyle(Colors.Surface.textPrimary(for: themeMode))

                Text("Upgrade for unlimited insights")
                    .font(Typography.Scripture.footnote)
                    .foregroundStyle(Colors.Surface.textSecondary(for: themeMode))
            }

            Spacer()

            Image(systemName: "arrow.right.circle.fill")
                .font(Typography.Icon.lg)
                .foregroundStyle(Colors.Semantic.accentSeal(for: themeMode))
        }
        .opacity(insightRevealed ? 1 : 0)
    }

    // MARK: - Compact Action Bar (insightFirst mode)

    private var compactActionBar: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        return HStack(spacing: Theme.Spacing.md) {
            // Quick action icons
            HStack(spacing: Theme.Spacing.xs) {
                MiniActionIcon(icon: "doc.on.doc", label: "Copy") {
                    HapticService.shared.success()
                    onCopy()
                }

                MiniActionIcon(icon: "square.and.arrow.up", label: "Share") {
                    HapticService.shared.lightTap()
                    onShare()
                }

                MiniActionIcon(icon: "note.text", label: "Note") {
                    HapticService.shared.lightTap()
                    onNote()
                }
            }

            // Subtle vertical separator
            Rectangle()
                .fill(mode.accentColor(for: themeMode).opacity(Theme.Opacity.lightMedium))
                .frame(width: Theme.Stroke.hairline, height: Theme.Spacing.xl)

            // Color palette
            HStack(spacing: Theme.Spacing.xs + 2) {
                ForEach(HighlightColor.allCases, id: \.self) { color in
                    CompactColorDot(
                        color: color,
                        isSelected: existingHighlightColor == color,
                        accentColor: mode.accentColor(for: themeMode)
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
                            .foregroundStyle(Colors.Surface.textTertiary(for: themeMode))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, Theme.Spacing.sm + 2)
    }

    // MARK: - Scholar Action Row (actionsFirst mode)

    private var scholarActionRow: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ScholarActionButton(icon: "doc.on.doc", label: "Copy") {
                HapticService.shared.success()
                onCopy()
            }

            ScholarActionButton(icon: "square.and.arrow.up", label: "Share") {
                HapticService.shared.lightTap()
                onShare()
            }

            ScholarActionButton(icon: "note.text", label: "Note") {
                HapticService.shared.lightTap()
                onNote()
            }

            // Vertical separator
            Rectangle()
                .fill(Color.gray.opacity(Theme.Opacity.light))
                .frame(width: 1, height: 32)

            // Study button with indigo accent
            ScholarStudyButton {
                HapticService.shared.mediumTap()
                onStudy()
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Highlight Row (actionsFirst mode)

    private var highlightRow: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        return HStack(spacing: Theme.Spacing.sm) {
            ForEach(HighlightColor.allCases, id: \.self) { color in
                ScholarColorDot(
                    color: color,
                    isSelected: existingHighlightColor == color
                ) {
                    HapticService.shared.verseHighlighted()
                    onHighlight(color)
                }
            }

            Spacer()

            // Remove highlight button (only if highlighted)
            if existingHighlightColor != nil {
                Button {
                    HapticService.shared.lightTap()
                    onRemoveHighlight()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(Typography.Icon.lg)
                        .foregroundStyle(Colors.Surface.textTertiary(for: themeMode))
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm + 2)
    }

    // MARK: - Measurement

    private var measurementBackground: some View {
        GeometryReader { geo in
            Color.clear.onAppear { measuredHeight = geo.size.height }
                .onChange(of: geo.size.height) { _, h in measuredHeight = h }
        }
    }
}

// MARK: - Mini Action Icon (insightFirst mode)

private struct MiniActionIcon: View {
    let icon: String
    let label: String
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(Typography.Icon.md)
                    .foregroundStyle(Colors.Surface.textSecondary(for: themeMode))

                Text(label)
                    .font(Typography.Icon.xxxs.weight(.medium))
                    .foregroundStyle(Colors.Surface.textTertiary(for: themeMode))
            }
            .frame(width: 44, height: 40)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { p in
            withAnimation(Theme.Animation.fade) { isPressed = p }
        }, perform: {})
    }
}

// MARK: - Compact Color Dot

private struct CompactColorDot: View {
    let color: HighlightColor
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            Circle()
                .fill(color.color)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(isSelected ? accentColor : Color.clear, lineWidth: Theme.Stroke.control)
                        .padding(-2)
                )
                .overlay(
                    isSelected ?
                    Image(systemName: "checkmark")
                        .font(Typography.Icon.xxxs.weight(.bold))
                        .foregroundStyle(.white)
                    : nil
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Scholar Action Button (actionsFirst mode)

private struct ScholarActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xs - 2) {
                Image(systemName: icon)
                    .font(Typography.Command.headline)
                    .foregroundStyle(Colors.Surface.textPrimary(for: themeMode).opacity(Theme.Opacity.overlay))

                Text(label)
                    .font(Typography.Icon.xxs)
                    .foregroundStyle(Colors.Surface.textTertiary(for: themeMode))
            }
            .frame(width: 48, height: 44)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(Theme.Animation.fade) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Scholar Study Button

private struct ScholarStudyButton: View {
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "sparkle")
                    .font(Typography.Icon.sm.weight(.semibold))

                Text("Study")
                    .font(Typography.Command.caption.weight(.semibold))
            }
            .foregroundStyle(Colors.Semantic.accentAction(for: themeMode))
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                Capsule()
                    .fill(Colors.Semantic.accentAction(for: themeMode).opacity(Theme.Opacity.subtle))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(Theme.Animation.fade) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Scholar Color Dot

private struct ScholarColorDot: View {
    let color: HighlightColor
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        Button {
            onTap()
        } label: {
            Circle()
                .fill(color.color)
                .frame(width: Theme.Size.iconSize, height: Theme.Size.iconSize)
                .overlay(
                    Circle()
                        .stroke(
                            isSelected ? Colors.Semantic.accentAction(for: themeMode) : Color.clear,
                            lineWidth: Theme.Stroke.control
                        )
                        .padding(-2 - 1)
                )
                .overlay(
                    isSelected ?
                    Image(systemName: "checkmark")
                        .font(Typography.Icon.xxs.weight(.bold))
                        .foregroundStyle(.white)
                    : nil
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(color.accessibilityName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Previews

#Preview("Unified Menu - Insight First (Read Tab)") {
    ZStack {
        Colors.Surface.background(for: .light).ignoresSafeArea()

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
        Colors.Surface.background(for: .dark).ignoresSafeArea()

        VStack {
            Text("10  For we are his workmanship, created in Christ Jesus unto good works.")
                .font(Typography.Scripture.body)
                .padding()
                .background(Colors.Semantic.accentAction(for: .dark).opacity(Theme.Opacity.overlay))
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
        Colors.Surface.background(for: .dark).ignoresSafeArea()

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
        Colors.Surface.background(for: .dark).ignoresSafeArea()

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

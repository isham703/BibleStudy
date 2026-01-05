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
        case .insightFirst: return Color.divineGold
        case .actionsFirst: return Color.scholarIndigo
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

            withAnimation(AppTheme.Animation.spring) {
                isAppearing = true
            }

            // Staggered insight reveal (insightFirst mode only)
            if mode == .insightFirst {
                withAnimation(AppTheme.Animation.luminous.delay(0.15)) {
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
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.menu, style: .continuous))
        .overlay(cardBorder)
        .shadow(
            color: .black.opacity(colorScheme == .dark ? AppTheme.Opacity.heavy : AppTheme.Opacity.light),
            radius: AppTheme.Shadow.menu.radius,
            x: AppTheme.Shadow.menu.x,
            y: AppTheme.Shadow.menu.y
        )
        .frame(width: mode.menuWidth)
        .opacity(isAppearing ? 1 : 0)
        .scaleEffect(isAppearing ? 1 : 0.92)
        .offset(y: isAppearing ? 0 : (menuPosition.arrowDirection == .up ? -10 : 10))
    }

    // MARK: - Card Background & Border

    private var cardBackground: some View {
        Group {
            if colorScheme == .dark {
                Color.Menu.backgroundDark
            } else {
                Color.Menu.backgroundLight
            }
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.menu, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        mode.accentColor.opacity(AppTheme.Opacity.heavy),
                        mode.accentColor.opacity(AppTheme.Opacity.quarter)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: AppTheme.Border.thin
            )
    }

    // MARK: - Dividers

    private var thinDivider: some View {
        Rectangle()
            .fill(mode.accentColor.opacity(AppTheme.Opacity.lightMedium))
            .frame(height: AppTheme.Border.hairline)
            .padding(.horizontal, AppTheme.CornerRadius.menu)
    }

    private var scholarDivider: some View {
        Rectangle()
            .fill(AppTheme.Menu.divider)
            .frame(height: 1)
            .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - HERO: Insight Section (insightFirst mode)

    private var insightSection: some View {
        Button {
            HapticService.shared.lightTap()
            // Use inline insight callback if available, otherwise fall back to legacy sheet
            if let openInline = onOpenInlineInsight {
                // Dismiss context menu first, then open inline card
                withAnimation(AppTheme.Animation.quick) {
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
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
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
            .padding(.horizontal, AppTheme.CornerRadius.menu)
            .padding(.vertical, AppTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Loading Insight View

    private var loadingInsightView: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ProgressView()
                .scaleEffect(AppTheme.Scale.small)
                .tint(Color.divineGold)

            Text("Illuminating this passage...")
                .font(Typography.Codex.italic)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    // MARK: - Full Insight View

    @ViewBuilder
    private func fullInsightView(_ insight: QuickInsightOutput) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: "sparkle")
                .font(Typography.UI.iconSm.weight(.semibold))
                .foregroundStyle(Color.divineGold)
                .padding(.top, AppTheme.Spacing.xxs + 1)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs + 2) {
                Text(insight.summary)
                    .font(Typography.Codex.body)
                    .foregroundStyle(Color.primaryText)
                    .lineSpacing(Typography.Codex.bodyLineSpacing)
                    .lineLimit(5)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(insightRevealed ? 1 : 0)
                    .blur(radius: insightRevealed ? 0 : AppTheme.Spacing.xs)

                // Key term (if present)
                if let term = insight.keyTerm, let meaning = insight.keyTermMeaning {
                    keyTermView(term: term, meaning: meaning)
                        .opacity(insightRevealed ? 1 : 0)
                        .offset(y: insightRevealed ? 0 : AppTheme.Spacing.xs)
                }
            }

            Spacer(minLength: 0)

            // Chevron for "tap for more"
            Image(systemName: "chevron.right")
                .font(Typography.UI.iconXs)
                .foregroundStyle(Color.tertiaryText)
                .padding(.top, AppTheme.Spacing.xs)
        }
    }

    // MARK: - Key Term View

    private func keyTermView(term: String, meaning: String) -> some View {
        HStack(spacing: AppTheme.Spacing.xs + 2) {
            Text(term)
                .font(Typography.Codex.gloss)
                .foregroundStyle(Color.divineGold)

            Text("—")
                .font(Typography.Codex.captionSmall)
                .foregroundStyle(Color.tertiaryText)

            Text(meaning)
                .font(Typography.Codex.caption)
                .foregroundStyle(Color.secondaryText)
                .lineLimit(1)
        }
        .padding(.top, AppTheme.Spacing.xxs)
    }

    // MARK: - No Insight View

    private var noInsightView: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "sparkle")
                .font(Typography.UI.iconSm)
                .foregroundStyle(Color.divineGold)

            Text("Tap to explore this passage")
                .font(Typography.Codex.italic)
                .foregroundStyle(Color.secondaryText)

            Spacer()

            Image(systemName: "chevron.right")
                .font(Typography.UI.iconXxs)
                .foregroundStyle(Color.tertiaryText)
        }
    }

    // MARK: - Limit Reached View

    private var limitReachedView: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "lock.fill")
                .font(Typography.UI.iconSm)
                .foregroundStyle(Color.divineGold)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text("Daily limit reached")
                    .font(Typography.Codex.emphasis)
                    .foregroundStyle(Color.primaryText)

                Text("Upgrade for unlimited insights")
                    .font(Typography.Codex.caption)
                    .foregroundStyle(Color.secondaryText)
            }

            Spacer()

            Image(systemName: "arrow.right.circle.fill")
                .font(Typography.UI.iconLg)
                .foregroundStyle(Color.divineGold)
        }
        .opacity(insightRevealed ? 1 : 0)
    }

    // MARK: - Compact Action Bar (insightFirst mode)

    private var compactActionBar: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Quick action icons
            HStack(spacing: AppTheme.Spacing.xs) {
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
                .fill(Color.divineGold.opacity(AppTheme.Opacity.lightMedium))
                .frame(width: AppTheme.Border.thin, height: AppTheme.Spacing.xl)

            // Color palette
            HStack(spacing: AppTheme.Spacing.xs + 2) {
                ForEach(HighlightColor.allCases, id: \.self) { color in
                    CompactColorDot(
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
                            .font(Typography.UI.iconLg)
                            .foregroundStyle(Color.tertiaryText)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppTheme.CornerRadius.menu)
        .padding(.vertical, AppTheme.Spacing.sm + 2)
    }

    // MARK: - Scholar Action Row (actionsFirst mode)

    private var scholarActionRow: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
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
                .fill(AppTheme.Menu.divider)
                .frame(width: 1, height: 32)

            // Study button with indigo accent
            ScholarStudyButton {
                HapticService.shared.mediumTap()
                onStudy()
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    // MARK: - Highlight Row (actionsFirst mode)

    private var highlightRow: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
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
                        .font(Typography.UI.iconLg)
                        .foregroundStyle(Color.tertiaryText)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.sm + 2)
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

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.xxs) {
                Image(systemName: icon)
                    .font(Typography.UI.iconMd)
                    .foregroundStyle(Color.secondaryText)

                Text(label)
                    .font(Typography.UI.iconXxxs.weight(.medium))
                    .foregroundStyle(Color.tertiaryText)
            }
            .frame(width: AppTheme.TouchTarget.minimum, height: 40)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? AppTheme.Scale.pressed : 1)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { p in
            withAnimation(AppTheme.Animation.quick) { isPressed = p }
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
                .frame(width: AppTheme.ComponentSize.badge, height: AppTheme.ComponentSize.badge)
                .overlay(
                    Circle()
                        .stroke(isSelected ? accentColor : Color.clear, lineWidth: AppTheme.Border.regular)
                        .padding(-AppTheme.Spacing.xxs)
                )
                .overlay(
                    isSelected ?
                    Image(systemName: "checkmark")
                        .font(Typography.UI.iconXxxs.weight(.bold))
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

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.xs - 2) {
                Image(systemName: icon)
                    .font(Typography.UI.headline)
                    .foregroundStyle(Color.primaryText.opacity(AppTheme.Opacity.overlay))

                Text(label)
                    .font(Typography.UI.iconXxs)
                    .foregroundStyle(Color.tertiaryText)
            }
            .frame(width: AppTheme.TouchTarget.comfortable, height: AppTheme.TouchTarget.minimum)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? AppTheme.Scale.pressed : 1)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(AppTheme.Animation.quick) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Scholar Study Button

private struct ScholarStudyButton: View {
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "sparkle")
                    .font(Typography.UI.iconSm.weight(.semibold))

                Text("Study")
                    .font(Typography.UI.caption1Bold)
            }
            .foregroundStyle(Color.scholarIndigo)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(Color.scholarIndigo.opacity(AppTheme.Opacity.subtle))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? AppTheme.Scale.pressed : 1)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(AppTheme.Animation.quick) {
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

    var body: some View {
        Button(action: onTap) {
            Circle()
                .fill(color.color)
                .frame(width: AppTheme.ComponentSize.icon, height: AppTheme.ComponentSize.icon)
                .overlay(
                    Circle()
                        .stroke(
                            isSelected ? Color.scholarIndigo : Color.clear,
                            lineWidth: AppTheme.Border.regular
                        )
                        .padding(-AppTheme.Spacing.xxs - 1)
                )
                .overlay(
                    isSelected ?
                    Image(systemName: "checkmark")
                        .font(Typography.UI.iconXxs.weight(.bold))
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
        Color.freshVellum.ignoresSafeArea()

        VStack {
            Text("10  For we are his workmanship, created in Christ Jesus unto good works.")
                .font(Typography.Scripture.body())
                .padding()
                .background(Color.yellow.opacity(0.15))
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
        Color.appBackground.ignoresSafeArea()

        VStack {
            Text("10  For we are his workmanship, created in Christ Jesus unto good works.")
                .font(Typography.Scripture.body())
                .padding()
                .background(Color.scholarIndigo.opacity(0.08))
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
        Color.appBackground.ignoresSafeArea()

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
        Color.appBackground.ignoresSafeArea()

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

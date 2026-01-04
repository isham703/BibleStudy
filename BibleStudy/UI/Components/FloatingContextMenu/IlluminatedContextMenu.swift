//
//  IlluminatedContextMenu.swift
//  BibleStudy
//
//  Insight-First Context Menu for verse selection.
//  Design Philosophy: The AI insight IS the value - make it the hero.
//
//  Layout: Insight dominates (4-5 lines) → Compact action bar below
//  Target height: ~170-190pt with full insight visibility
//

import SwiftUI

// MARK: - Illuminated Context Menu

/// An insight-first floating context menu for selected verses.
/// The AI-generated insight is the hero element, not an afterthought.
struct IlluminatedContextMenu: View {

    // MARK: - Properties

    let verseRange: VerseRange
    let selectionBounds: CGRect
    let containerBounds: CGRect
    let safeAreaInsets: EdgeInsets
    let existingHighlightColor: HighlightColor?
    let insight: QuickInsightOutput?
    let isInsightLoading: Bool
    /// True when user has reached their daily AI insight limit
    let isLimitReached: Bool

    // MARK: - Action Callbacks

    let onCopy: () -> Void
    let onHighlight: (HighlightColor) -> Void
    let onStudy: () -> Void
    /// New callback for opening inline insight card (new UX)
    var onOpenInlineInsight: (() -> Void)?
    let onShare: () -> Void
    let onNote: () -> Void
    let onAddToCollection: () -> Void
    let onRemoveHighlight: () -> Void
    let onDismiss: () -> Void

    // MARK: - Animation State

    @State private var isAppearing = false
    @State private var insightRevealed = false
    @State private var measuredHeight: CGFloat?
    @State private var keyboardObserver = KeyboardHeightObserver()

    @Environment(\.colorScheme) private var colorScheme

    // Audio service for pause/resume during insight viewing
    private let audioService = AudioService.shared

    // MARK: - Constants

    private let menuWidth: CGFloat = 300

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
        positionCalculator.calculatePosition(menuHeight: measuredHeight ?? 180)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { _ in
            let position = menuPosition

            ZStack(alignment: .topLeading) {
                menuCard
                    .background(measurementBackground)
                    .position(
                        x: position.origin.x + menuWidth / 2,
                        y: position.origin.y + (measuredHeight ?? 180) / 2
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            // Pause audio if playing (will remember state for resume)
            audioService.pauseForInterruption()

            withAnimation(AppTheme.Animation.spring) {
                isAppearing = true
            }
            // Staggered insight reveal
            withAnimation(AppTheme.Animation.luminous.delay(0.15)) {
                insightRevealed = true
            }
        }
        .onDisappear {
            // Resume audio if it was playing before insight appeared
            audioService.resumeAfterInterruption()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Verse actions for \(verseRange.reference)")
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - Menu Card

    // Design Decision: No arrow pointer
    // Illuminated manuscripts used proximity, not arrows, to associate marginalia with text.
    // The floating card adjacent to the verse is clear enough. Removing the arrow creates
    // a cleaner, more premium look that's truer to the manuscript aesthetic.

    private var menuCard: some View {
        VStack(spacing: 0) {
            // HERO: Insight section (dominant element)
            insightSection

            thinDivider

            // Compact unified action bar
            compactActionBar
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
        .frame(width: menuWidth)
        .opacity(isAppearing ? 1 : 0)
        .scaleEffect(isAppearing ? 1 : 0.92)
        .offset(y: isAppearing ? 0 : (menuPosition.arrowDirection == .up ? -10 : 10))
    }

    // MARK: - Card Background

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
                        Color.divineGold.opacity(AppTheme.Opacity.heavy),
                        Color.divineGold.opacity(AppTheme.Opacity.quarter)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: AppTheme.Border.thin
            )
    }

    // MARK: - Thin Divider

    private var thinDivider: some View {
        Rectangle()
            .fill(Color.divineGold.opacity(AppTheme.Opacity.lightMedium))
            .frame(height: AppTheme.Border.hairline)
            .padding(.horizontal, AppTheme.CornerRadius.menu)
    }

    // MARK: - HERO: Insight Section

    private var insightSection: some View {
        Button {
            HapticService.shared.lightTap()
            // Use inline insight callback if available (new UX), otherwise fall back to legacy sheet
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
                    // Limit reached - show upgrade prompt
                    limitReachedView
                } else if isInsightLoading {
                    // Loading state with shimmer
                    loadingInsightView
                } else if let insight = insight {
                    // Full insight display
                    fullInsightView(insight)
                } else {
                    // No insight yet - prompt to study
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

    // MARK: - Full Insight View (Hero)

    @ViewBuilder
    private func fullInsightView(_ insight: QuickInsightOutput) -> some View {
        // Main insight summary - THE HERO
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

    // MARK: - Compact Action Bar

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
                        onTap: {
                            HapticService.shared.verseHighlighted()
                            onHighlight(color)
                        }
                    )
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

    // MARK: - Measurement

    private var measurementBackground: some View {
        GeometryReader { geo in
            Color.clear.onAppear { measuredHeight = geo.size.height }
                .onChange(of: geo.size.height) { _, h in measuredHeight = h }
        }
    }
}

// MARK: - Mini Action Icon (Compact with label)

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

// MARK: - Compact Action Button

private struct CompactActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.xxs) {
                Image(systemName: icon)
                    .font(Typography.UI.iconMd)
                    .foregroundStyle(Color.divineGold)

                Text(label)
                    .font(Typography.UI.iconXxs)
                    .foregroundStyle(Color.secondaryText)
            }
            .frame(maxWidth: .infinity)
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
                        .stroke(isSelected ? Color.divineGold : Color.clear, lineWidth: AppTheme.Border.regular)
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

// MARK: - Secondary Text Button

private struct SecondaryTextButton: View {
    let label: String
    let onTap: () -> Void

    var body: some View {
        Button {
            HapticService.shared.lightTap()
            onTap()
        } label: {
            Text(label)
                .font(Typography.UI.iconSm.weight(.medium))
                .foregroundStyle(Color.tertiaryText)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews

#Preview("Compact Menu - Light") {
    ZStack {
        Color.freshVellum.ignoresSafeArea()

        VStack {
            Text("10  For we are his workmanship, created in Christ Jesus unto good works, which God hath before ordained that we should walk in them.")
                .font(Typography.Scripture.body())
                .padding()
                .background(Color.yellow.opacity(AppTheme.Opacity.lightMedium))
                .padding(.top, AppTheme.Spacing.xxxl * 2 + 4)

            Spacer()
        }
        .padding(.horizontal)

        IlluminatedContextMenu(
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
            onHighlight: { _ in },
            onStudy: {},
            onShare: {},
            onNote: {},
            onAddToCollection: {},
            onRemoveHighlight: {},
            onDismiss: {}
        )
    }
}

#Preview("Compact Menu - Dark") {
    ZStack {
        Color.black.ignoresSafeArea()

        IlluminatedContextMenu(
            verseRange: VerseRange(bookId: 1, chapter: 1, verseStart: 1, verseEnd: 1),
            selectionBounds: CGRect(x: 50, y: 300, width: 300, height: 40),
            containerBounds: CGRect(x: 0, y: 0, width: 393, height: 852),
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0),
            existingHighlightColor: .amber,
            insight: nil,
            isInsightLoading: false,
            isLimitReached: false,
            onCopy: {},
            onHighlight: { _ in },
            onStudy: {},
            onShare: {},
            onNote: {},
            onAddToCollection: {},
            onRemoveHighlight: {},
            onDismiss: {}
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Compact Menu - Loading") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        IlluminatedContextMenu(
            verseRange: VerseRange(bookId: 1, chapter: 1, verseStart: 3, verseEnd: 3),
            selectionBounds: CGRect(x: 50, y: 200, width: 300, height: 40),
            containerBounds: CGRect(x: 0, y: 0, width: 393, height: 852),
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0),
            existingHighlightColor: nil,
            insight: nil,
            isInsightLoading: true,
            isLimitReached: false,
            onCopy: {},
            onHighlight: { _ in },
            onStudy: {},
            onShare: {},
            onNote: {},
            onAddToCollection: {},
            onRemoveHighlight: {},
            onDismiss: {}
        )
    }
}

#Preview("Compact Menu - Limit Reached") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        IlluminatedContextMenu(
            verseRange: VerseRange(bookId: 1, chapter: 1, verseStart: 3, verseEnd: 3),
            selectionBounds: CGRect(x: 50, y: 200, width: 300, height: 40),
            containerBounds: CGRect(x: 0, y: 0, width: 393, height: 852),
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0),
            existingHighlightColor: nil,
            insight: nil,
            isInsightLoading: false,
            isLimitReached: true,
            onCopy: {},
            onHighlight: { _ in },
            onStudy: {},
            onShare: {},
            onNote: {},
            onAddToCollection: {},
            onRemoveHighlight: {},
            onDismiss: {}
        )
    }
}

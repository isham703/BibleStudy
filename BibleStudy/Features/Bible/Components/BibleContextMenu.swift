import SwiftUI

// MARK: - Scholar Context Menu
// Floating context menu for verse selection in Bible reader
// Clean editorial aesthetic with indigo accents and refined typography
// Reuses MenuPositionCalculator for optimal positioning

struct BibleContextMenu: View {

    // MARK: - Properties

    let verseRange: VerseRange
    let selectionBounds: CGRect
    let containerBounds: CGRect
    let safeAreaInsets: EdgeInsets
    let existingHighlightColor: HighlightColor?

    // MARK: - Action Callbacks

    let onCopy: () -> Void
    let onShare: () -> Void
    let onNote: () -> Void
    let onHighlight: (HighlightColor) -> Void
    let onRemoveHighlight: () -> Void
    let onStudy: () -> Void
    let onDismiss: () -> Void

    // MARK: - Animation State

    @Environment(\.colorScheme) private var colorScheme
    @State private var isAppearing = false
    @State private var measuredHeight: CGFloat?
    @State private var keyboardObserver = KeyboardHeightObserver()

    // MARK: - Constants

    private let menuWidth: CGFloat = 280

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
        positionCalculator.calculatePosition(menuHeight: measuredHeight ?? 140)
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
                        y: position.origin.y + (measuredHeight ?? 140) / 2
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            withAnimation(Theme.Animation.fade) {
                isAppearing = true
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Verse actions for \(verseRange.reference)")
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - Menu Card

    private var menuCard: some View {
        VStack(spacing: 0) {
            // Action row: Copy, Share, Note, Study
            actionRow

            scholarDivider

            // Highlight palette row
            highlightRow
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .overlay(cardBorder)
        // swiftlint:disable:next hardcoded_shadow_params
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
        .frame(width: menuWidth)
        .opacity(isAppearing ? 1 : 0)
        .scaleEffect(isAppearing ? 1 : 0.92)
        .offset(y: isAppearing ? 0 : (menuPosition.arrowDirection == .up ? -8 : 8))
    }

    // MARK: - Card Background & Border

    private var cardBackground: some View {
        Color.surfaceRaised
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium + 0.05),
                        Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: Theme.Stroke.hairline
            )
    }

    // MARK: - Divider

    private var scholarDivider: some View {
        Rectangle()
            .fill(Color.gray.opacity(Theme.Opacity.light))
            .frame(height: Theme.Stroke.hairline)
            .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Action Row

    private var actionRow: some View {
        HStack(spacing: Theme.Spacing.xs) {
            BibleActionButton(
                icon: "doc.on.doc",
                label: "Copy"
            ) {
                HapticService.shared.success()
                onCopy()
            }

            BibleActionButton(
                icon: "square.and.arrow.up",
                label: "Share"
            ) {
                HapticService.shared.lightTap()
                onShare()
            }

            BibleActionButton(
                icon: "note.text",
                label: "Note"
            ) {
                HapticService.shared.lightTap()
                onNote()
            }

            // Vertical separator
            Rectangle()
                .fill(Color.gray.opacity(Theme.Opacity.light))
                .frame(width: 1, height: 32)

            // Study button with indigo accent
            BibleStudyButton {
                HapticService.shared.mediumTap()
                onStudy()
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Highlight Row

    private var highlightRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(HighlightColor.allCases, id: \.self) { color in
                BibleColorDot(
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
                        .foregroundStyle(Color.tertiaryText)
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

// MARK: - Scholar Action Button

private struct BibleActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xs - 2) {
                Image(systemName: icon)
                    .font(Typography.Icon.md.weight(.medium))
                    .foregroundStyle(Color.primaryText.opacity(Theme.Opacity.overlay))

                Text(label)
                    .font(Typography.Icon.xxs.weight(.medium))
                    .foregroundStyle(Color.tertiaryText)
            }
            .frame(width: 48, height: 44)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.94 : 1)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(Theme.Animation.settle) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Scholar Study Button

private struct BibleStudyButton: View {
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "sparkle")
                    .font(Typography.Icon.sm.weight(.semibold))

                Text("Study")
                    .font(Typography.Command.caption.weight(.semibold))
            }
            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                Capsule()
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.94 : 1)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(Theme.Animation.settle) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Scholar Color Dot

private struct BibleColorDot: View {
    let color: HighlightColor
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            Circle()
                .fill(color.color)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(
                            isSelected ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Color.clear,
                            lineWidth: Theme.Stroke.control
                        )
                        .padding(-3)
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

// MARK: - Preview

#Preview("Bible Context Menu") {
    @Previewable @Environment(\.colorScheme) var colorScheme
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack {
            Text("10  For we are his workmanship, created in Christ Jesus unto good works.")
                .readingVerse(size: .medium, font: .newYork)
                .padding()
                .background(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint))
                // swiftlint:disable:next hardcoded_padding_edge
                .padding(.top, 180)

            Spacer()
        }

        BibleContextMenu(
            verseRange: VerseRange(bookId: 49, chapter: 2, verseStart: 10, verseEnd: 10),
            selectionBounds: CGRect(x: 20, y: 100, width: 350, height: 60),
            containerBounds: CGRect(x: 0, y: 0, width: 393, height: 852),
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0),
            existingHighlightColor: nil,
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

#Preview("Bible Context Menu - With Highlight") {
    @Previewable @Environment(\.colorScheme) var colorScheme
    ZStack {
        Color.appBackground.ignoresSafeArea()

        BibleContextMenu(
            verseRange: VerseRange(bookId: 1, chapter: 1, verseStart: 1, verseEnd: 3),
            selectionBounds: CGRect(x: 50, y: 300, width: 300, height: 100),
            containerBounds: CGRect(x: 0, y: 0, width: 393, height: 852),
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0),
            existingHighlightColor: HighlightColor.blue,
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

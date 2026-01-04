import SwiftUI

// MARK: - Scholar Context Menu
// Floating context menu for verse selection in Scholar reader
// Clean editorial aesthetic with indigo accents and refined typography
// Reuses MenuPositionCalculator for optimal positioning

struct ScholarContextMenu: View {

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
            withAnimation(AppTheme.Animation.menuAppear) {
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
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.menu, style: .continuous))
        .overlay(cardBorder)
        .shadow(color: AppTheme.Shadow.menuColor, radius: 16, x: 0, y: 6)
        .frame(width: menuWidth)
        .opacity(isAppearing ? 1 : 0)
        .scaleEffect(isAppearing ? 1 : 0.92)
        .offset(y: isAppearing ? 0 : (menuPosition.arrowDirection == .up ? -8 : 8))
    }

    // MARK: - Card Background & Border

    private var cardBackground: some View {
        AppTheme.Menu.background
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.menu, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.scholarIndigo.opacity(0.25),
                        Color.scholarIndigo.opacity(0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
    }

    // MARK: - Divider

    private var scholarDivider: some View {
        Rectangle()
            .fill(AppTheme.Menu.divider)
            .frame(height: 1)
            .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - Action Row

    private var actionRow: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            ScholarActionButton(
                icon: "doc.on.doc",
                label: "Copy"
            ) {
                HapticService.shared.success()
                onCopy()
            }

            ScholarActionButton(
                icon: "square.and.arrow.up",
                label: "Share"
            ) {
                HapticService.shared.lightTap()
                onShare()
            }

            ScholarActionButton(
                icon: "note.text",
                label: "Note"
            ) {
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

    // MARK: - Highlight Row

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
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.footnoteGray)
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

// MARK: - Scholar Action Button

private struct ScholarActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.xs - 2) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.scholarInk.opacity(0.7))

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.footnoteGray)
            }
            .frame(width: 48, height: 44)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.94 : 1)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
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
                    .font(.system(size: 14, weight: .semibold))

                Text("Study")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Color.scholarIndigo)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(Color.scholarIndigoSubtle)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.94 : 1)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
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
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(
                            isSelected ? Color.scholarIndigo : Color.clear,
                            lineWidth: 2
                        )
                        .padding(-3)
                )
                .overlay(
                    isSelected ?
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
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

#Preview("Scholar Context Menu") {
    ZStack {
        Color.vellumCream.ignoresSafeArea()

        VStack {
            Text("10  For we are his workmanship, created in Christ Jesus unto good works.")
                .font(.custom("CormorantGaramond-Regular", size: 18))
                .padding()
                .background(Color.scholarIndigo.opacity(0.08))
                .padding(.top, 180)

            Spacer()
        }

        ScholarContextMenu(
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

#Preview("Scholar Context Menu - With Highlight") {
    ZStack {
        Color.vellumCream.ignoresSafeArea()

        ScholarContextMenu(
            verseRange: VerseRange(bookId: 1, chapter: 1, verseStart: 1, verseEnd: 3),
            selectionBounds: CGRect(x: 50, y: 300, width: 300, height: 100),
            containerBounds: CGRect(x: 0, y: 0, width: 393, height: 852),
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0),
            existingHighlightColor: .blue,
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

import SwiftUI

// MARK: - Vellum Scroll Toast
// Premium undo toast with illuminated manuscript aesthetics
// Feels like a scroll of vellum unfurling from the bottom of the screen

struct VellumScrollToast: View {
    let toast: ToastItem
    let onDismiss: () -> Void
    let onUndo: () -> Void

    // MARK: - Animation State

    @State private var borderProgress: CGFloat = 0
    @State private var isBreathing = false
    @State private var showUndoConfirmation = false
    @State private var undoButtonPressed = false
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Layout Constants

    private let cornerRadius: CGFloat = AppTheme.CornerRadius.xl
    private let borderWidth: CGFloat = 1.0
    private let shadowRadius: CGFloat = 24
    private let shadowOpacity: Double = 0.2

    // MARK: - Computed Properties

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color.chapelShadow
            : Color.monasteryStone
    }

    private var textColor: Color {
        colorScheme == .dark
            ? Color.moonlitParchment
            : Color.monasteryBlack
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark
            ? Color.fadedMoonlight
            : Color.agedInk
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Sparkle icon
            Image(systemName: toast.type.icon)
                .font(Typography.UI.iconSm.weight(.semibold))
                .foregroundStyle(toast.type.accentColor)

            // Content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                messageText
                referenceText
            }

            Spacer(minLength: AppTheme.Spacing.sm)

            // Undo button (if action available)
            if toast.undoAction != nil {
                undoButton
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(toastBackground)
        .overlay(goldBorderOverlay)
        .shadow(
            color: .black.opacity(shadowOpacity),
            radius: shadowRadius,
            x: 0,
            y: 8
        )
        .scaleEffect(isBreathing ? 1.008 : 1.0)
        .onAppear {
            animateEntrance()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(toast.undoAction != nil ? "Double tap to undo" : "")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            if toast.undoAction != nil {
                onUndo()
            } else {
                onDismiss()
            }
        }
    }

    // MARK: - Message Text

    @ViewBuilder
    private var messageText: some View {
        switch toast.type {
        case .highlight(let color, _):
            HStack(spacing: AppTheme.Spacing.xs) {
                Text("Highlighted in")
                    .font(Typography.Codex.emphasis)
                    .foregroundStyle(textColor)

                // Color dot
                Circle()
                    .fill(color.solidColor)
                    .frame(width: 12, height: 12)

                Text(color.displayName)
                    .font(Typography.Codex.emphasis)
                    .foregroundStyle(color.solidColor)
            }

        case .success(let message), .info(let message):
            Text(message)
                .font(Typography.Codex.emphasis)
                .foregroundStyle(textColor)

        case .bookmark:
            Text("Bookmarked")
                .font(Typography.Codex.emphasis)
                .foregroundStyle(textColor)

        case .note:
            Text("Note saved")
                .font(Typography.Codex.emphasis)
                .foregroundStyle(textColor)
        }
    }

    // MARK: - Reference Text

    @ViewBuilder
    private var referenceText: some View {
        switch toast.type {
        case .highlight(_, let reference),
             .bookmark(let reference),
             .note(let reference):
            Text(reference)
                .font(Typography.Codex.caption)
                .foregroundStyle(secondaryTextColor)

        case .success, .info:
            EmptyView()
        }
    }

    // MARK: - Undo Button

    private var undoButton: some View {
        Button(action: {
            withAnimation(AppTheme.Animation.quick) {
                undoButtonPressed = true
            }
            HapticService.shared.lightTap()

            // Brief delay for visual feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onUndo()
            }
        }) {
            Text("Undo")
                .font(Typography.UI.buttonLabel)
                .foregroundStyle(Color.divineGold)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(Color.divineGold.opacity(AppTheme.Opacity.subtle))
                )
                .scaleEffect(undoButtonPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .frame(minWidth: AppTheme.TouchTarget.minimum, minHeight: AppTheme.TouchTarget.minimum)
        .contentShape(Rectangle())
    }

    // MARK: - Toast Background

    private var toastBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(backgroundColor)
            .overlay(
                // Subtle gold glow in background
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.divineGold.opacity(AppTheme.Opacity.faint),
                                .clear
                            ],
                            center: .leading,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
            )
    }

    // MARK: - Gold Border Overlay

    private var goldBorderOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                AngularGradient(
                    colors: [
                        Color.divineGold,
                        Color.burnishedGold,
                        Color.illuminatedGold,
                        Color.divineGold
                    ],
                    center: .center,
                    angle: .degrees(45)
                ),
                lineWidth: borderWidth
            )
            .opacity(borderProgress)
    }

    // MARK: - Animation

    private func animateEntrance() {
        // Border draws in
        withAnimation(AppTheme.Animation.luminous.delay(0.3)) {
            borderProgress = 1.0
        }

        // Start subtle breathing after entrance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(AppTheme.Animation.contemplative) {
                isBreathing = true
            }
        }

        // Haptic feedback on appearance
        HapticService.shared.lightTap()
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        switch toast.type {
        case .highlight(let color, let reference):
            return "Highlighted \(reference) in \(color.displayName)"
        case .success(let message):
            return message
        case .info(let message):
            return message
        case .bookmark(let reference):
            return "Bookmarked \(reference)"
        case .note(let reference):
            return "Note saved for \(reference)"
        }
    }
}

// MARK: - Preview

#Preview("Highlight Toast") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VellumScrollToast(
            toast: ToastItem(
                id: UUID(),
                type: .highlight(color: .amber, reference: "Ephesians 2:10"),
                undoAction: { print("Undo tapped") },
                duration: 4.0
            ),
            onDismiss: {},
            onUndo: {}
        )
        .padding()
    }
}

#Preview("Success Toast") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VellumScrollToast(
            toast: ToastItem(
                id: UUID(),
                type: .success(message: "Copied to clipboard"),
                undoAction: nil,
                duration: 4.0
            ),
            onDismiss: {},
            onUndo: {}
        )
        .padding()
    }
}

#Preview("Dark Mode") {
    ZStack {
        Color.candlelitStone.ignoresSafeArea()

        VellumScrollToast(
            toast: ToastItem(
                id: UUID(),
                type: .highlight(color: .blue, reference: "John 3:16"),
                undoAction: { print("Undo tapped") },
                duration: 4.0
            ),
            onDismiss: {},
            onUndo: {}
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}

import SwiftUI

// MARK: - App Toast View
// Premium undo toast with app-wide styling
// Displays feedback messages with undo capability

struct AppToastView: View {
    let toast: ToastItem
    let onDismiss: () -> Void
    let onUndo: () -> Void

    // MARK: - Animation State

    @State private var borderProgress: CGFloat = 0
    @State private var isBreathing = false
    @State private var showUndoConfirmation = false
    @State private var undoButtonPressed = false

    // MARK: - Layout Constants

    private let cornerRadius: CGFloat = 20
    private let borderWidth: CGFloat = 1.0
    private let shadowRadius: CGFloat = 24
    private let shadowOpacity: Double = 0.2

    // MARK: - Computed Properties

    private var backgroundColor: Color {
        Color.appSurface
    }

    private var textColor: Color {
        Color("AppTextPrimary")
    }

    private var secondaryTextColor: Color {
        Color("AppTextSecondary")
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Sparkle icon
            Image(systemName: toast.type.icon)
                .font(Typography.Icon.sm.weight(.semibold))
                .foregroundStyle(toast.type.accentColor)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                messageText
                referenceText
            }

            Spacer(minLength: Theme.Spacing.sm)

            // Undo button (if action available)
            if toast.undoAction != nil {
                undoButton
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
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
            HStack(spacing: Theme.Spacing.xs) {
                Text("Highlighted in")
                    .font(Typography.Scripture.quote)
                    .foregroundStyle(textColor)

                // Color dot
                Circle()
                    .fill(color.solidColor)
                    .frame(width: 12, height: 12)

                Text(color.displayName)
                    .font(Typography.Scripture.quote)
                    .foregroundStyle(color.solidColor)
            }

        case .success(let message), .info(let message):
            Text(message)
                .font(Typography.Scripture.quote)
                .foregroundStyle(textColor)

        case .bookmark:
            Text("Bookmarked")
                .font(Typography.Scripture.quote)
                .foregroundStyle(textColor)

        case .note:
            Text("Note saved")
                .font(Typography.Scripture.quote)
                .foregroundStyle(textColor)

        case .sermonDeleted(let title):
            Text("Deleted \"\(title)\"")
                .font(Typography.Scripture.quote)
                .foregroundStyle(textColor)
                .lineLimit(1)

        case .sermonsDeleted(let count):
            Text("Deleted \(count) sermons")
                .font(Typography.Scripture.quote)
                .foregroundStyle(textColor)

        case .deleteError(let message):
            Text(message)
                .font(Typography.Scripture.quote)
                .foregroundStyle(Color("FeedbackError"))
                .lineLimit(2)
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
                .font(Typography.Scripture.footnote)
                .foregroundStyle(secondaryTextColor)

        case .success, .info, .sermonDeleted, .sermonsDeleted, .deleteError:
            EmptyView()
        }
    }

    // MARK: - Undo Button

    private var undoButton: some View {
        Button(action: {
            withAnimation(Theme.Animation.fade) {
                undoButtonPressed = true
            }
            HapticService.shared.lightTap()

            // Brief delay for visual feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onUndo()
            }
        }) {
            Text("Undo")
                .font(Typography.Command.cta)
                .foregroundStyle(Color("AccentBronze"))
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(Color("AccentBronze").opacity(Theme.Opacity.subtle))
                )
                .scaleEffect(undoButtonPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
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
                                Color("AccentBronze").opacity(Theme.Opacity.subtle),
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
            .stroke(Color("AccentBronze"), lineWidth: borderWidth)
            .opacity(borderProgress)
    }

    // MARK: - Animation

    private func animateEntrance() {
        // Border draws in
        withAnimation(Theme.Animation.slowFade.delay(0.3)) {
            borderProgress = 1.0
        }

        // Start subtle breathing after entrance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(Theme.Animation.slowFade) {
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
        case .sermonDeleted(let title):
            return "Deleted sermon: \(title)"
        case .sermonsDeleted(let count):
            return "Deleted \(count) sermons"
        case .deleteError(let message):
            return "Delete error: \(message)"
        }
    }
}

// MARK: - Preview

#Preview("Highlight Toast") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        AppToastView(
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

        AppToastView(
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
        Color("AppBackground").ignoresSafeArea()

        AppToastView(
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

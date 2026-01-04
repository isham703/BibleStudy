//
//  InlineHighlightColorRow.swift
//  BibleStudy
//
//  Inline highlight color selection row for the floating context menu
//  Follows Fitts's Law with 28pt circles and 8pt spacing for easy acquisition
//

import SwiftUI

// MARK: - Inline Highlight Color Row

/// A horizontal row of color circles for quick highlight selection
/// First circle is empty (remove highlight), followed by 5 highlight colors
struct InlineHighlightColorRow: View {
    /// Currently applied highlight color (nil if no highlight)
    let existingColor: HighlightColor?

    /// Called when user taps a color circle
    let onSelectColor: (HighlightColor) -> Void

    /// Called when user taps the empty circle to remove highlight
    let onRemove: () -> Void

    /// Called when user long-presses a color to open category picker
    var onLongPress: ((HighlightColor) -> Void)?

    @State private var pressedColor: HighlightColor?
    @State private var isRemovePressed = false

    // Scaled dimensions for Dynamic Type support
    @ScaledMetric(relativeTo: .body) private var circleSize: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var checkmarkSize: CGFloat = 12

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            // Empty circle (remove highlight)
            removeCircle

            // Color circles
            ForEach(HighlightColor.allCases, id: \.self) { color in
                colorCircle(for: color)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xs)
    }

    // MARK: - Subviews

    /// Empty circle button to remove existing highlight
    private var removeCircle: some View {
        Button {
            HapticService.shared.lightTap()
            onRemove()
        } label: {
            Circle()
                .strokeBorder(
                    existingColor == nil
                        ? Color.secondaryText.opacity(AppTheme.Opacity.heavy)
                        : Color.primaryText,
                    style: existingColor == nil
                        ? StrokeStyle(lineWidth: AppTheme.Border.thin, dash: [3, 2])
                        : StrokeStyle(lineWidth: AppTheme.Border.regular)
                )
                .frame(width: circleSize, height: circleSize)
                .overlay {
                    // Show X icon when there's an existing highlight to remove
                    if existingColor != nil {
                        Image(systemName: "xmark")
                            .font(Typography.UI.iconXs.weight(.medium))
                            .foregroundStyle(Color.primaryText)
                    }
                }
                .scaleEffect(isRemovePressed ? AppTheme.Scale.pressed : 1.0)
        }
        .buttonStyle(.plain)
        .frame(minWidth: AppTheme.TouchTarget.minimum, minHeight: AppTheme.TouchTarget.minimum)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(AppTheme.Animation.quick) {
                        isRemovePressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(AppTheme.Animation.quick) {
                        isRemovePressed = false
                    }
                }
        )
        .accessibilityLabel("Remove highlight")
        .accessibilityHint(existingColor != nil
            ? "Double tap to remove the existing highlight"
            : "No highlight applied"
        )
        .accessibilityAddTraits(existingColor != nil ? .isButton : [])
    }

    /// Color circle button for applying a highlight color
    private func colorCircle(for color: HighlightColor) -> some View {
        let isSelected = existingColor == color
        let isPressed = pressedColor == color

        return Button {
            // Use color-specific haptic for VoiceOver users
            if UIAccessibility.isVoiceOverRunning {
                HapticService.shared.highlightColorAnnouncement(color)
            } else {
                HapticService.shared.verseHighlighted()
            }
            onSelectColor(color)
        } label: {
            Circle()
                .fill(color.color)
                .frame(width: circleSize, height: circleSize)
                .overlay {
                    // Checkmark for currently applied color (accessibility: not color alone)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(Typography.UI.iconXs.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                .overlay {
                    // Selection ring
                    if isSelected {
                        Circle()
                            .stroke(Color.primaryText, lineWidth: AppTheme.Border.regular)
                            .frame(width: circleSize + 4, height: circleSize + 4)
                    }
                }
                .scaleEffect(isPressed ? AppTheme.Scale.pressed : 1.0)
        }
        .buttonStyle(.plain)
        .frame(minWidth: AppTheme.TouchTarget.minimum, minHeight: AppTheme.TouchTarget.minimum)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(AppTheme.Animation.quick) {
                        pressedColor = color
                    }
                }
                .onEnded { _ in
                    withAnimation(AppTheme.Animation.quick) {
                        pressedColor = nil
                    }
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: AppTheme.Gesture.longPressDuration)
                .onEnded { _ in
                    HapticService.shared.selectionChanged()
                    onLongPress?(color)
                }
        )
        .accessibilityLabel("Highlight \(color.accessibilityName)")
        .accessibilityHint(isSelected
            ? "Currently applied. Double tap to keep, or choose another color."
            : "Double tap to apply \(color.displayName) highlight. Long press to assign a category."
        )
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(named: "Assign category") {
            onLongPress?(color)
        }
    }
}

// MARK: - Preview

#Preview("No Existing Highlight") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: AppTheme.Spacing.xl) {
            InlineHighlightColorRow(
                existingColor: nil,
                onSelectColor: { color in
                    print("Selected: \(color.displayName)")
                },
                onRemove: {
                    print("Remove tapped")
                }
            )
            .padding()
            .background(Color.elevatedBackground)
            .clipShape(Capsule())

            Text("No highlight applied")
                .foregroundStyle(Color.secondaryText)
        }
    }
}

#Preview("Gold Highlight Applied") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: AppTheme.Spacing.xl) {
            InlineHighlightColorRow(
                existingColor: .amber,
                onSelectColor: { color in
                    print("Selected: \(color.displayName)")
                },
                onRemove: {
                    print("Remove tapped")
                }
            )
            .padding()
            .background(Color.elevatedBackground)
            .clipShape(Capsule())

            Text("Gold highlight applied")
                .foregroundStyle(Color.secondaryText)
        }
    }
}

#Preview("All Colors") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: AppTheme.Spacing.lg) {
            ForEach(HighlightColor.allCases, id: \.self) { color in
                HStack {
                    Text(color.displayName)
                        .foregroundStyle(Color.primaryText)
                        .frame(width: 60, alignment: .leading)

                    InlineHighlightColorRow(
                        existingColor: color,
                        onSelectColor: { _ in },
                        onRemove: { }
                    )
                }
            }
        }
        .padding()
    }
}

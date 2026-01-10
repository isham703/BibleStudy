import SwiftUI

// MARK: - Pattern Selector

/// Horizontal list of selectable breathing patterns.
struct PatternSelector: View {
    @Binding var selectedPattern: BreathingPattern
    let patterns: [BreathingPattern]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            // swiftlint:disable:next hardcoded_stack_spacing
            HStack(spacing: 5) {  // Tight spacing for compact pattern cards
                ForEach(patterns) { pattern in
                    PatternCard(
                        pattern: pattern,
                        isSelected: selectedPattern.id == pattern.id
                    ) {
                        // swiftlint:disable:next hardcoded_animation_spring
                        withAnimation(Theme.Animation.settle) {
                            selectedPattern = pattern
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.sm + 2)
        }
    }
}

// MARK: - Pattern Card

/// A single pattern card with press animation and selection highlighting.
struct PatternCard: View {
    let pattern: BreathingPattern
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.sm + 2) {
                ZStack {
                    Circle()
                        .fill(pattern.color.opacity(isSelected ? Theme.Opacity.medium : Theme.Opacity.subtle))
                        .frame(width: 50, height: 50)

                    Image(systemName: pattern.icon)
                        .font(Typography.Icon.lg)
                        .foregroundStyle(isSelected ? pattern.color : .white.opacity(Theme.Opacity.strong))
                }

                Text(pattern.name)
                    .font(Typography.Command.caption.weight(isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .white : .white.opacity(Theme.Opacity.strong))
            }
            .padding(.vertical, Theme.Spacing.lg)
            .padding(.horizontal, Theme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                    // swiftlint:disable:next hardcoded_opacity
                    .fill(isSelected ? pattern.color.opacity(Theme.Opacity.lightMedium) : .white.opacity(Theme.Opacity.faint))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                            .stroke(
                                isSelected ? pattern.color.opacity(Theme.Opacity.heavy) : .white.opacity(Theme.Opacity.subtle),
                                lineWidth: Theme.Stroke.hairline
                            )
                    )
                    // swiftlint:disable:next hardcoded_padding_edge
                    .padding(.horizontal, 5)  // Tight decorative padding
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    // swiftlint:disable:next hardcoded_animation_spring
                    withAnimation(Theme.Animation.settle) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    // swiftlint:disable:next hardcoded_animation_spring
                    withAnimation(Theme.Animation.settle) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Preview

#Preview("Pattern Selector") {
    struct PreviewWrapper: View {
        @State private var selected = BreathingPattern.sleep

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                PatternSelector(
                    selectedPattern: $selected,
                    patterns: BreathingPattern.patterns
                )
            }
        }
    }

    return PreviewWrapper()
}

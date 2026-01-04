import SwiftUI

// MARK: - Insight Chip
// Reusable chip button for expandable sections in InlineInsightCard
// Design: Gold accent when selected, subtle border when unselected
// Animation: Uses sacredSpring for selection transitions

struct InsightChip: View {
    // MARK: - Properties

    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    // MARK: - State

    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(Typography.UI.iconXs)

                Text(title)
                    .font(Typography.UI.caption1)
                    .fontWeight(isSelected ? .semibold : .regular)

                if isSelected {
                    Image(systemName: "chevron.down")
                        .font(Typography.UI.iconXxs)
                }
            }
            .foregroundStyle(isSelected ? Color.divineGold : Color.secondaryText)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(chipBackground)
            .clipShape(Capsule())
            .overlay(chipBorder)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(AppTheme.Animation.quick) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel("\(title) section")
        .accessibilityHint(isSelected ? "Currently expanded. Double tap to collapse." : "Double tap to expand.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Background

    private var chipBackground: some View {
        Group {
            if isSelected {
                Color.divineGold.opacity(AppTheme.Opacity.light)
            } else {
                Color.surfaceBackground
            }
        }
    }

    // MARK: - Border

    private var chipBorder: some View {
        Capsule()
            .stroke(
                isSelected ? Color.divineGold.opacity(AppTheme.Opacity.medium) : Color.cardBorder,
                lineWidth: AppTheme.Border.thin
            )
    }
}

// MARK: - Insight Chip Row
// Convenience view for displaying a row of chips with consistent spacing

struct InsightChipRow<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                content()
            }
        }
    }
}

// MARK: - Preview

#Preview("Insight Chips") {
    struct PreviewContainer: View {
        @State private var selectedChip: String?

        var body: some View {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Unselected state
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Unselected")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(.secondary)

                    HStack(spacing: AppTheme.Spacing.sm) {
                        InsightChip(title: "Key Points", icon: "list.bullet", isSelected: false) {}
                        InsightChip(title: "Context", icon: "text.alignleft", isSelected: false) {}
                        InsightChip(title: "Words", icon: "character.book.closed", isSelected: false) {}
                    }
                }

                // Selected state
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Selected")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(.secondary)

                    HStack(spacing: AppTheme.Spacing.sm) {
                        InsightChip(title: "Key Points", icon: "list.bullet", isSelected: true) {}
                        InsightChip(title: "Context", icon: "text.alignleft", isSelected: false) {}
                        InsightChip(title: "Words", icon: "character.book.closed", isSelected: false) {}
                    }
                }

                // Interactive
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Interactive (tap to toggle)")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(.secondary)

                    HStack(spacing: AppTheme.Spacing.sm) {
                        InsightChip(
                            title: "Key Points",
                            icon: "list.bullet",
                            isSelected: selectedChip == "keyPoints"
                        ) {
                            withAnimation(AppTheme.Animation.spring) {
                                selectedChip = selectedChip == "keyPoints" ? nil : "keyPoints"
                            }
                        }

                        InsightChip(
                            title: "Context",
                            icon: "text.alignleft",
                            isSelected: selectedChip == "context"
                        ) {
                            withAnimation(AppTheme.Animation.spring) {
                                selectedChip = selectedChip == "context" ? nil : "context"
                            }
                        }

                        InsightChip(
                            title: "Cross-refs",
                            icon: "arrow.triangle.branch",
                            isSelected: selectedChip == "crossRefs"
                        ) {
                            withAnimation(AppTheme.Animation.spring) {
                                selectedChip = selectedChip == "crossRefs" ? nil : "crossRefs"
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.appBackground)
        }
    }

    return PreviewContainer()
}

import SwiftUI

// MARK: - Highlight Color Filter Chip
// Tappable filter chip for highlight colors
// Shows color dot, name, and count badge

struct HighlightColorFilterChip: View {
    let color: HighlightColor?  // nil = "All"
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    private var displayColor: Color {
        if let color = color {
            return color.solidColor
        }
        return Color("AppAccentAction")
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xxs) {
                // Color dot (only for specific colors)
                if let color = color {
                    Circle()
                        .fill(color.solidColor)
                        .frame(width: 8, height: 8)
                }

                Text(color?.displayName ?? "All")
                    .font(Typography.Command.caption)

                if count > 0 {
                    Text("\(count)")
                        .font(Typography.Command.meta.monospacedDigit())
                        .foregroundStyle(isSelected ? Color("AppTextPrimary") : Color("TertiaryText"))
                }
            }
            .foregroundStyle(isSelected ? Color("AppTextPrimary") : Color("AppTextSecondary"))
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? displayColor.opacity(Theme.Opacity.selectionBackground) : Color("AppSurface"))
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? displayColor : Color("AppDivider"),
                        lineWidth: Theme.Stroke.hairline
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let colorName = color?.displayName ?? "All"
        let selectedState = isSelected ? "Selected" : ""
        return "\(colorName) filter, \(count) highlights \(selectedState)"
    }
}

// MARK: - Preview

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: Theme.Spacing.sm) {
            HighlightColorFilterChip(color: nil, count: 42, isSelected: true, action: {})
            HighlightColorFilterChip(color: .blue, count: 12, isSelected: false, action: {})
            HighlightColorFilterChip(color: .green, count: 8, isSelected: false, action: {})
            HighlightColorFilterChip(color: .amber, count: 15, isSelected: false, action: {})
            HighlightColorFilterChip(color: .rose, count: 5, isSelected: false, action: {})
            HighlightColorFilterChip(color: .purple, count: 2, isSelected: false, action: {})
        }
        .padding()
    }
    .background(Color("AppBackground"))
}

import SwiftUI

// MARK: - Category Chip
// Selectable chip for prayer intention categories
// Portico-style blue capsule design with accessibility support

struct CategoryChip: View {
    let category: PrayerCategory
    let isSelected: Bool
    let action: () -> Void

    /// Accent color for selected state - defaults to warm bronze for prayer flow harmony
    var accentColor: Color = Color("AccentBronze")

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed Styles

    /// Unselected text: full contrast in dark mode, slightly muted in light mode
    private var unselectedTextColor: Color {
        colorScheme == .dark
            ? Color("AppTextPrimary")  // Full contrast for dark mode readability
            : Color("AppTextPrimary").opacity(0.75)  // Slightly quieter in light mode
    }

    /// Unselected border: subtle in light mode, more visible in dark mode
    private var unselectedBorderColor: Color {
        colorScheme == .dark
            ? Color("AppTextPrimary").opacity(0.30)  // Visible but not competing
            : Color("AppTextPrimary").opacity(0.18)  // Quieter so selection stands out
    }

    var body: some View {
        Button(action: {
            HapticService.shared.selectionChanged()
            action()
        }) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: category.icon)
                    .font(Typography.Icon.sm)
                Text(category.rawValue)
                    .font(Typography.Command.label.weight(isSelected ? .semibold : .regular))
            }
            // 3-state hierarchy: Selected = prominent, Unselected = clearly tappable
            // Selected: white text on warm accent fill (harmonizes with candlelit palette)
            // Unselected: mode-aware contrast (darker in dark mode, quieter in light)
            .foregroundStyle(isSelected ? .white : unselectedTextColor)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? accentColor : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? accentColor : unselectedBorderColor,
                        lineWidth: isSelected ? Theme.Stroke.control : Theme.Stroke.hairline
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.rawValue) prayer category")
        .accessibilityHint(category.description)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
    }
}

// MARK: - Preview

#Preview("Category Chips") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.md) {
                ForEach(PrayerCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: category == .gratitude,
                        action: {}
                    )
                }
            }
            .padding()
        }
    }
}

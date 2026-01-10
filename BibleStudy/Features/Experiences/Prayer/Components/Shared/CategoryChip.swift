import SwiftUI

// MARK: - Category Chip
// Selectable chip for prayer intention categories
// Features gold/parchment styling with accessibility support

struct CategoryChip: View {
    let category: PrayerCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticService.shared.selectionChanged()
            action()
        }) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: category.icon)
                    .font(Typography.Icon.xs)
                Text(category.rawValue)
                    .font(Typography.Scripture.heading)
            }
            .foregroundColor(isSelected ? Color.surfaceParchment : Color.accentBronze)
            .padding(.horizontal, Theme.Spacing.lg)
            // swiftlint:disable:next hardcoded_padding_edge
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentBronze : Color.surfaceRaised)
                    .overlay(
                        Capsule()
                            .stroke(
                                Color.accentBronze.opacity(isSelected ? 0 : Theme.Opacity.medium),
                                lineWidth: Theme.Stroke.hairline
                            )
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
        Color.surfaceParchment.ignoresSafeArea()

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

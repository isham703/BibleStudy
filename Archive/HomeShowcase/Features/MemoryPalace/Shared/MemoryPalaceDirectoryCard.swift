import SwiftUI

// MARK: - Memory Palace Directory Card
// Card component for the Memory Palace section in ContentView
// Follows the DirectoryCard pattern but adapted for MemoryPalaceVariant

struct MemoryPalaceDirectoryCard: View {
    let variant: MemoryPalaceVariant

    var body: some View {
        VStack(alignment: .leading, spacing: HomeShowcaseTheme.Spacing.md) {
            // Header with icon and title
            HStack(spacing: HomeShowcaseTheme.Spacing.md) {
                // Icon with gradient background
                Image(systemName: variant.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(variant.accentColor)
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.card)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        variant.accentColor.opacity(0.2),
                                        variant.accentColor.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.card)
                            .stroke(variant.accentColor.opacity(0.3), lineWidth: 0.5)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(variant.title)
                        .font(HomeShowcaseTypography.UI.headline)
                        .foregroundStyle(Color.showcasePrimaryText)

                    // Subtitle/aesthetic
                    Text(variant.subtitle)
                        .font(HomeShowcaseTypography.UI.captionSmall)
                        .foregroundStyle(variant.accentColor.opacity(0.8))
                }

                Spacer()

                // Mode indicator
                VStack(spacing: 4) {
                    // Light/Dark mode indicator
                    Circle()
                        .fill(variant.backgroundStyle == .light ? Color.white : Color.black)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.showcaseTertiaryText.opacity(0.3), lineWidth: 1)
                        )

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.showcaseTertiaryText)
                }
            }

            // Description
            Text(variant.description)
                .font(HomeShowcaseTypography.UI.body)
                .foregroundStyle(Color.showcaseSecondaryText)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            // Preview strip showing color palette
            HStack(spacing: HomeShowcaseTheme.Spacing.xs) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(variant.paletteColor(index))
                        .frame(height: 6)
                }
            }
            .padding(.top, HomeShowcaseTheme.Spacing.xs)
        }
        .padding(HomeShowcaseTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.large)
                .fill(Color.showcaseSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.large)
                .stroke(
                    LinearGradient(
                        colors: [
                            variant.accentColor.opacity(0.4),
                            Color.showcaseTertiaryText.opacity(0.15),
                            variant.accentColor.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: variant.accentColor.opacity(0.25), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.showcaseBackground.ignoresSafeArea()

        VStack(spacing: 16) {
            ForEach(MemoryPalaceVariant.allCases) { variant in
                NavigationLink(destination: variant.page) {
                    MemoryPalaceDirectoryCard(variant: variant)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}

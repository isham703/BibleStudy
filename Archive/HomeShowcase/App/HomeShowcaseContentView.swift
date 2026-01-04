import SwiftUI

// MARK: - Home Showcase Content View
// Main directory listing all home page variants

struct HomeShowcaseContentView: View {
    @State private var isVisible = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HomeShowcaseTheme.Spacing.xl) {
                    // Header
                    headerSection

                    // Variant Cards
                    ForEach(Array(HomePageVariant.allCases.enumerated()), id: \.element.id) { index, variant in
                        NavigationLink(destination: variant.page) {
                            DirectoryCard(variant: variant)
                        }
                        .buttonStyle(.plain)
                        .staggeredEntrance(index: index, isVisible: isVisible)
                    }

                    // Memory Palace Section
                    memoryPalaceSection

                    // Footer
                    footerSection
                }
                .padding(.horizontal, HomeShowcaseTheme.Spacing.lg)
                .padding(.vertical, HomeShowcaseTheme.Spacing.xxl)
            }
            .background(Color.showcaseBackground)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    isVisible = true
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: HomeShowcaseTheme.Spacing.sm) {
            Text("HOME")
                .font(HomeShowcaseTypography.Minimalist.sectionHeader)
                .tracking(3)
                .foregroundStyle(Color.divineGold)

            Text("Page Options")
                .font(HomeShowcaseTypography.UI.largeTitle)
                .foregroundStyle(Color.showcasePrimaryText)

            Text("Explore different design approaches for the Home experience")
                .font(HomeShowcaseTypography.UI.body)
                .foregroundStyle(Color.showcaseSecondaryText)
                .padding(.top, HomeShowcaseTheme.Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, HomeShowcaseTheme.Spacing.md)
    }

    // MARK: - Memory Palace Section

    private var memoryPalaceSection: some View {
        VStack(alignment: .leading, spacing: HomeShowcaseTheme.Spacing.lg) {
            // Section Header
            HStack(spacing: HomeShowcaseTheme.Spacing.sm) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.celestialPurple)

                Text("MEMORY PALACE")
                    .font(HomeShowcaseTypography.Minimalist.sectionHeader)
                    .tracking(3)
                    .foregroundStyle(Color.celestialPurple)
            }
            .padding(.top, HomeShowcaseTheme.Spacing.xl)

            Text("Memorize Psalm 23:1")
                .font(HomeShowcaseTypography.UI.headline)
                .foregroundStyle(Color.showcasePrimaryText)

            Text("3 visual styles for scripture memorization")
                .font(HomeShowcaseTypography.UI.captionSmall)
                .foregroundStyle(Color.showcaseSecondaryText)

            // Memory Palace Variant Cards
            ForEach(Array(MemoryPalaceVariant.allCases.enumerated()), id: \.element.id) { index, variant in
                NavigationLink(destination: variant.page) {
                    MemoryPalaceDirectoryCard(variant: variant)
                }
                .buttonStyle(.plain)
                .staggeredEntrance(index: index + HomePageVariant.allCases.count, isVisible: isVisible)
            }
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: HomeShowcaseTheme.Spacing.sm) {
            Divider()
                .background(Color.showcaseTertiaryText.opacity(0.3))

            Text("Tap a card to preview the full page design")
                .font(HomeShowcaseTypography.UI.captionSmall)
                .foregroundStyle(Color.showcaseTertiaryText)
                .padding(.top, HomeShowcaseTheme.Spacing.sm)
        }
        .padding(.top, HomeShowcaseTheme.Spacing.xl)
    }
}

// MARK: - Directory Card

struct DirectoryCard: View {
    let variant: HomePageVariant

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
                    HStack(spacing: 8) {
                        Text(variant.title)
                            .font(HomeShowcaseTypography.UI.headline)
                            .foregroundStyle(Color.showcasePrimaryText)

                        // Badge for special features
                        if let badge = variant.badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(variant.accentColor)
                                )
                        }
                    }

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
    HomeShowcaseContentView()
        .preferredColorScheme(.dark)
}

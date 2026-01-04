import SwiftUI

// MARK: - Living Scripture Directory
// Main entry point listing 3 immersive narrative design variations

struct LivingScriptureDirectory: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HomeShowcaseTheme.Spacing.xl) {
                    // Header
                    headerSection

                    // Variant Cards
                    ForEach(Array(LivingScriptureVariant.allCases.enumerated()), id: \.element.id) { index, variant in
                        NavigationLink(destination: variant.page) {
                            LivingScriptureDirectoryCard(variant: variant)
                        }
                        .buttonStyle(.plain)
                        .staggeredEntrance(index: index, isVisible: isVisible)
                    }

                    // Footer
                    footerSection
                }
                .padding(.horizontal, HomeShowcaseTheme.Spacing.lg)
                .padding(.vertical, HomeShowcaseTheme.Spacing.xxl)
            }
            .background(Color.showcaseBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.showcaseSecondaryText)
                    }
                }
            }
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
            Text("LIVING")
                .font(HomeShowcaseTypography.Minimalist.sectionHeader)
                .tracking(3)
                .foregroundStyle(Color(hex: "EC4899"))

            Text("Scripture")
                .font(HomeShowcaseTypography.UI.largeTitle)
                .foregroundStyle(Color.showcasePrimaryText)

            Text("Step inside biblical narratives as a first-person immersive experience")
                .font(HomeShowcaseTypography.UI.body)
                .foregroundStyle(Color.showcaseSecondaryText)
                .padding(.top, HomeShowcaseTheme.Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, HomeShowcaseTheme.Spacing.md)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: HomeShowcaseTheme.Spacing.sm) {
            Divider()
                .background(Color.showcaseTertiaryText.opacity(0.3))

            Text("Each variation presents the Prodigal Son story with unique visual aesthetics")
                .font(HomeShowcaseTypography.UI.captionSmall)
                .foregroundStyle(Color.showcaseTertiaryText)
                .multilineTextAlignment(.center)
                .padding(.top, HomeShowcaseTheme.Spacing.sm)
        }
        .padding(.top, HomeShowcaseTheme.Spacing.xl)
    }
}

// MARK: - Living Scripture Directory Card

struct LivingScriptureDirectoryCard: View {
    let variant: LivingScriptureVariant
    @State private var isPressed = false

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
        .shadow(
            color: variant.accentColor.opacity(isPressed ? 0.15 : 0.25),
            radius: isPressed ? 6 : 12,
            x: 0,
            y: 4
        )
        .pressEffect(isPressed: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
            if pressing {
                HomeShowcaseHaptics.cardPress()
            }
        }, perform: {})
    }
}

// MARK: - Preview

#Preview {
    LivingScriptureDirectory()
        .preferredColorScheme(.dark)
}

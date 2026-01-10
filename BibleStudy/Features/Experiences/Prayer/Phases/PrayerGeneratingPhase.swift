import SwiftUI

// MARK: - Prayer Generating Phase
// Displays animated loading state while prayer is being generated
// Features illuminated "P" initial with pulsing glow

struct PrayerGeneratingPhase: View {
    let selectedCategory: PrayerCategory
    let illuminationPhase: CGFloat
    let reduceMotion: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated illuminated initial
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        // swiftlint:disable:next hardcoded_gradient_colors
                        RadialGradient(
                            colors: [
                                Color.accentBronze.opacity(Theme.Opacity.disabled),
                                Color.accentBronze.opacity(Theme.Opacity.subtle),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 100
                        )
                    )
                    // swiftlint:disable:next hardcoded_frame_size
                    .frame(width: 200, height: 200)
                    // swiftlint:disable:next hardcoded_scale_effect
                    .scaleEffect(reduceMotion ? 1 : 1 + illuminationPhase * 0.15)

                // Inner circle
                Circle()
                    .fill(Color.surfaceRaised)
                    // swiftlint:disable:next hardcoded_frame_size
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(
                                // swiftlint:disable:next hardcoded_gradient_colors
                                LinearGradient(
                                    colors: [
                                        Color.decorativeGold.opacity(0.15),
                                        Color.accentBronze,
                                        Color.feedbackWarning
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: Theme.Stroke.control
                            )
                    )

                // Letter P
                Text("P")
                    .font(Typography.Scripture.display)
                    .foregroundStyle(
                        // swiftlint:disable:next hardcoded_gradient_colors
                        LinearGradient(
                            colors: [Color.decorativeGold.opacity(0.15), Color.accentBronze],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            // swiftlint:disable:next hardcoded_frame_size
            .frame(width: 240, height: 240) // Reserve space for scaled glow

            // Status text
            Text("Crafting your prayer...")
                .font(Typography.Scripture.body)
                .foregroundColor(Color.textSecondary)
                .padding(.top, Theme.Spacing.xxl)

            // Category indicator
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: selectedCategory.icon)
                    .font(Typography.Icon.xs)
                Text(selectedCategory.rawValue)
                    .font(Typography.Scripture.heading)
            }
            .foregroundColor(Color.accentBronze)
            .padding(.top, Theme.Spacing.md)

            Spacer()
        }
        .containerRelativeFrame(.vertical) // Fill screen height so Spacer() works
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Creating your \(selectedCategory.rawValue.lowercased()) prayer. Please wait.")
        .accessibilityAddTraits(.updatesFrequently)
        .transition(.opacity)
    }
}

// MARK: - Preview

#Preview("Generating Phase") {
    ZStack {
        Color.surfaceParchment.ignoresSafeArea()
        PrayerGeneratingPhase(
            selectedCategory: .gratitude,
            illuminationPhase: 0.5,
            reduceMotion: false
        )
    }
}

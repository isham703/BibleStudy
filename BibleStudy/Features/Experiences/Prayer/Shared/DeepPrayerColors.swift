import SwiftUI

// MARK: - Deep Prayer Colors
// Dark theme palette for Prayers from the Deep showcase
// Rose (#f43f5e) on Sacred Navy (#0a0d1a) with warm candlelight glow

enum DeepPrayerColors {
    // MARK: - Primary Colors

    /// Deep sacred blue-black background
    static let sacredNavy = Color(hex: "0a0d1a")

    /// Primary rose accent
    static let roseAccent = Color(hex: "f43f5e")

    /// Warm candlelight glow
    static let candlelightGlow = Color(hex: "ffefd5")

    /// Secondary gold accent
    static let goldAccent = Color(hex: "d4a853")

    // MARK: - Text Colors

    /// Primary text on dark background
    static let primaryText = Color.white

    /// Secondary/muted text
    static let secondaryText = Color.white.opacity(0.6)

    /// Tertiary/subtle text
    static let tertiaryText = Color.white.opacity(0.4)

    /// Placeholder text
    static let placeholderText = Color.white.opacity(0.3)

    // MARK: - Surface Colors

    /// Elevated surface (cards, inputs)
    static let surfaceElevated = Color.white.opacity(0.08)

    /// Surface border
    static let surfaceBorder = Color.white.opacity(0.12)

    /// Rose-tinted surface for selected states
    static let roseHighlight = roseAccent.opacity(0.3)

    /// Rose border for focus states
    static let roseBorder = roseAccent.opacity(0.4)

    // MARK: - Glow Colors

    /// Rose glow for breathing animation
    static func roseGlow(phase: CGFloat) -> Color {
        roseAccent.opacity(0.08 + phase * 0.04)
    }

    /// Gold glow for accent areas
    static let goldGlow = goldAccent.opacity(0.05)

    // MARK: - Gradients

    /// Main background gradient with breathing rose glow
    static func backgroundGradient(breathePhase: CGFloat = 0) -> some View {
        ZStack {
            sacredNavy

            // Rose breathing glow from center
            RadialGradient(
                colors: [
                    roseGlow(phase: breathePhase),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )

            // Subtle gold accent from top-trailing
            RadialGradient(
                colors: [
                    goldGlow,
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 300
            )
        }
    }

    /// Button gradient
    static let buttonGradient = LinearGradient(
        colors: [roseAccent, roseAccent.opacity(0.9)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Preview

#Preview("Deep Prayer Colors") {
    ScrollView {
        VStack(spacing: 24) {
            // Background preview
            ZStack {
                DeepPrayerColors.backgroundGradient(breathePhase: 0.5)

                VStack(spacing: 16) {
                    Text("Prayers from the Deep")
                        .font(.system(size: 24, weight: .medium, design: .serif))
                        .foregroundStyle(DeepPrayerColors.primaryText)

                    Text("Rose on Sacred Navy")
                        .font(.system(size: 14))
                        .foregroundStyle(DeepPrayerColors.secondaryText)
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Color swatches
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                colorSwatch("Sacred Navy", DeepPrayerColors.sacredNavy)
                colorSwatch("Rose Accent", DeepPrayerColors.roseAccent)
                colorSwatch("Candlelight", DeepPrayerColors.candlelightGlow)
                colorSwatch("Gold Accent", DeepPrayerColors.goldAccent)
            }
            .padding()
        }
    }
    .background(Color.black)
}

private func colorSwatch(_ name: String, _ color: Color) -> some View {
    VStack(spacing: 8) {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(height: 60)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )

        Text(name)
            .font(.system(size: 12))
            .foregroundStyle(.white.opacity(0.7))
    }
}

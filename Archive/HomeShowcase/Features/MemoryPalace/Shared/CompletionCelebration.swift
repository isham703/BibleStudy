import SwiftUI

// MARK: - Completion Celebration
// Success screen shown after completing all 5 rooms
// Displays trophy, full verse, and action buttons

struct CompletionCelebration: View {
    @Environment(\.dismiss) private var dismiss
    let accentColor: Color
    let style: CompletionStyle
    let floatPhase: CGFloat
    let onWalkAgain: () -> Void

    enum CompletionStyle {
        case candlelit
        case scholarly
        case celestial
    }

    var body: some View {
        VStack(spacing: HomeShowcaseTheme.Spacing.xxl) {
            Spacer()

            // Trophy icon
            trophyView

            // Success message
            successMessage

            // Full verse display
            verseCard

            Spacer()

            // Action buttons
            actionButtons
        }
    }

    // MARK: - Trophy View

    @ViewBuilder
    private var trophyView: some View {
        switch style {
        case .candlelit:
            candlelitTrophy
        case .scholarly:
            scholarlyTrophy
        case .celestial:
            celestialTrophy
        }
    }

    private var candlelitTrophy: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(accentColor.opacity(0.2))
                .frame(width: 160, height: 160)
                .scaleEffect(1 + floatPhase * 0.1)

            // Inner glow
            Circle()
                .fill(accentColor.opacity(0.3))
                .frame(width: 120, height: 120)

            // Icon
            Image(systemName: "brain.head.profile")
                .font(.system(size: 56))
                .foregroundStyle(accentColor)
                .shadow(color: accentColor.opacity(0.5), radius: 10)
        }
    }

    private var scholarlyTrophy: some View {
        VStack(spacing: HomeShowcaseTheme.Spacing.md) {
            // Simple checkmark that draws itself
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(accentColor)

            // Decorative rule
            Rectangle()
                .fill(accentColor)
                .frame(width: 60, height: 2)
        }
    }

    private var celestialTrophy: some View {
        ZStack {
            // Constellation effect - 5 dots representing completed rooms
            ForEach(0..<5, id: \.self) { index in
                let angle = Double(index) * (2 * .pi / 5) - .pi / 2
                let radius: CGFloat = 80

                Circle()
                    .fill(PalaceRoom.psalm23Rooms[index].primaryColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: PalaceRoom.psalm23Rooms[index].primaryColor.opacity(0.6), radius: 6)
                    .offset(
                        x: cos(angle) * radius,
                        y: sin(angle) * radius
                    )
            }

            // Center trophy
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.celestialPurple, .celestialPink, .celestialCyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .celestialPurple.opacity(0.5), radius: 10)
        }
        .frame(width: 200, height: 200)
    }

    // MARK: - Success Message

    private var successMessage: some View {
        VStack(spacing: HomeShowcaseTheme.Spacing.sm) {
            Text("Memory Anchored!")
                .font(successTitleFont)
                .foregroundStyle(style == .scholarly ? Color.scholarInk : Color.white)

            Text("You've walked through all 5 rooms")
                .font(.system(size: 15))
                .foregroundStyle(style == .scholarly ? Color.footnoteGray : Color.white.opacity(0.6))
        }
    }

    private var successTitleFont: Font {
        switch style {
        case .candlelit, .celestial:
            return .custom("Cinzel-Regular", size: 28, relativeTo: .title)
        case .scholarly:
            return .system(size: 28, weight: .bold, design: .serif)
        }
    }

    // MARK: - Verse Card

    private var verseCard: some View {
        VStack(spacing: HomeShowcaseTheme.Spacing.lg) {
            Text("\u{201C}\(PalaceRoom.fullVerse)\u{201D}")
                .font(verseFont)
                .foregroundStyle(style == .scholarly ? Color.scholarInk : Color.white)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, HomeShowcaseTheme.Spacing.xxl)

            Text(PalaceRoom.verseReference)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(accentColor)
        }
        .padding(.vertical, HomeShowcaseTheme.Spacing.xl)
        .padding(.horizontal, HomeShowcaseTheme.Spacing.lg)
        .background(verseCardBackground)
        .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)
    }

    private var verseFont: Font {
        switch style {
        case .candlelit, .celestial:
            return .custom("CormorantGaramond-Regular", size: 18, relativeTo: .body)
        case .scholarly:
            return .system(size: 18, weight: .regular, design: .serif)
        }
    }

    @ViewBuilder
    private var verseCardBackground: some View {
        switch style {
        case .candlelit:
            RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.large)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.large)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        case .scholarly:
            RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.card)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.card)
                        .stroke(Color.scholarInk.opacity(0.1), lineWidth: 1)
                )
        case .celestial:
            RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.large)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.large)
                        .stroke(
                            LinearGradient(
                                colors: [.celestialPurple.opacity(0.5), .celestialPink.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: HomeShowcaseTheme.Spacing.xl) {
            // Walk Again
            Button(action: onWalkAgain) {
                HStack(spacing: HomeShowcaseTheme.Spacing.sm) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Walk Again")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(style == .scholarly ? Color.footnoteGray : Color.white.opacity(0.7))
            }

            // Done
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(style == .scholarly ? .white : .black)
                    .padding(.horizontal, HomeShowcaseTheme.Spacing.xxl)
                    .padding(.vertical, HomeShowcaseTheme.Spacing.md)
                    .background(
                        Capsule()
                            .fill(accentColor)
                    )
            }
        }
        .padding(.bottom, HomeShowcaseTheme.Spacing.huge)
    }
}

// MARK: - Preview

#Preview("Completion Celebrations") {
    TabView {
        // Candlelit
        ZStack {
            Color(hex: "030308")
            CompletionCelebration(
                accentColor: .candleAmber,
                style: .candlelit,
                floatPhase: 0.5,
                onWalkAgain: {}
            )
        }
        .tabItem { Text("Candlelit") }

        // Scholarly
        ZStack {
            Color.vellumCream
            CompletionCelebration(
                accentColor: .scholarIndigo,
                style: .scholarly,
                floatPhase: 0,
                onWalkAgain: {}
            )
        }
        .tabItem { Text("Scholarly") }

        // Celestial
        ZStack {
            Color.celestialDeep
            CompletionCelebration(
                accentColor: .celestialPurple,
                style: .celestial,
                floatPhase: 0.5,
                onWalkAgain: {}
            )
        }
        .tabItem { Text("Celestial") }
    }
    .ignoresSafeArea()
}

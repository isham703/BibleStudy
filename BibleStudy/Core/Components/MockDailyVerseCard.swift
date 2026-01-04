import SwiftUI

// MARK: - Mock Daily Verse Card
// Displays the daily verse with three style variants

enum VerseCardStyle {
    case minimal      // Hairline dividers, centered text, no background
    case standard     // Glass card with gradient
    case narrative    // Large decorative quote, dramatic typography
}

struct MockDailyVerseCard: View {
    let verse: MockDailyVerse
    let style: VerseCardStyle

    @State private var isVisible = false

    var body: some View {
        switch style {
        case .minimal:
            minimalStyle
        case .standard:
            standardStyle
        case .narrative:
            narrativeStyle
        }
    }

    // MARK: - Minimal Style

    private var minimalStyle: some View {
        VStack(spacing: SanctuaryTheme.Spacing.xl) {
            // Top hairline
            goldHairline

            // Verse text
            Text("\"\(verse.text)\"")
                .font(SanctuaryTypography.Minimalist.verse)
                .foregroundStyle(Color.moonlitParchment)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.3), value: isVisible)

            // Reference
            Text("— \(verse.reference)")
                .font(SanctuaryTypography.Minimalist.reference)
                .tracking(3)
                .foregroundStyle(Color.divineGold)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.6), value: isVisible)

            // Bottom hairline
            goldHairline
        }
        .padding(.vertical, SanctuaryTheme.Spacing.xxl)
        .onAppear {
            isVisible = true
        }
    }

    private var goldHairline: some View {
        Rectangle()
            .fill(Color.divineGold)
            .frame(width: 80, height: 1)
            .scaleEffect(x: isVisible ? 1 : 0, anchor: .center)
            .animation(.easeOut(duration: 0.6), value: isVisible)
    }

    // MARK: - Standard Style

    private var standardStyle: some View {
        VStack(alignment: .leading, spacing: SanctuaryTheme.Spacing.md) {
            Text("\"\(verse.text)\"")
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundStyle(Color.moonlitParchment)
                .lineSpacing(4)

            Text(verse.reference)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.divineGold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SanctuaryTheme.Spacing.lg)
        .glassCard()
    }

    // MARK: - Narrative Style

    private var narrativeStyle: some View {
        VStack(spacing: SanctuaryTheme.Spacing.lg) {
            // Decorative open quote
            Text("❝")
                .font(SanctuaryTypography.Narrative.decorativeQuote)
                .foregroundStyle(Color.divineGold.opacity(0.3))
                .offset(y: 10)

            // Verse text with glow
            Text(verse.text)
                .font(SanctuaryTypography.Narrative.verse)
                .foregroundStyle(Color.moonlitParchment)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .shadow(color: Color.divineGold.opacity(0.2), radius: 2)

            // Divider
            Rectangle()
                .fill(Color.divineGold.opacity(0.5))
                .frame(width: 60, height: 1)

            // Reference
            Text(verse.reference)
                .font(SanctuaryTypography.Narrative.sectionHeader)
                .tracking(4)
                .foregroundStyle(Color.divineGold)
        }
        .padding(.vertical, SanctuaryTheme.Spacing.xxl)
    }
}

// MARK: - Preview

#Preview("Minimal") {
    ZStack {
        Color.deepVellumBlack.ignoresSafeArea()

        MockDailyVerseCard(
            verse: HomeShowcaseMockData.dailyVerse,
            style: .minimal
        )
        .padding()
    }
}

#Preview("Standard") {
    ZStack {
        Color.candlelitStone.ignoresSafeArea()

        MockDailyVerseCard(
            verse: HomeShowcaseMockData.dailyVerse,
            style: .standard
        )
        .padding()
    }
}

#Preview("Narrative") {
    ZStack {
        Color.candlelitStone.ignoresSafeArea()

        MockDailyVerseCard(
            verse: HomeShowcaseMockData.dailyVerse,
            style: .narrative
        )
        .padding()
    }
}

import SwiftUI

// MARK: - Daily Verse Card
// Displays the daily verse with flat styling
// Stoic-Existential Renaissance design

struct DailyVerseCard: View {
    let verse: MockDailyVerse
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Verse text (serif for contemplation)
            Text("\"\(verse.text)\"")
                .font(Typography.Scripture.body)
                .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
                .lineSpacing(6)

            // Reference (sans for metadata)
            Text(verse.reference)
                .font(Typography.Command.meta)
                .tracking(1.5)
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(
                    Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)),
                    lineWidth: Theme.Stroke.hairline
                )
        )
    }
}

// MARK: - Preview

#Preview("Daily Verse Card") {
    @Previewable @Environment(\.colorScheme) var colorScheme
    let themeMode = ThemeMode.current(from: colorScheme)

    ZStack {
        Colors.Surface.background(for: themeMode).ignoresSafeArea()

        DailyVerseCard(verse: SanctuaryMockData.dailyVerse)
            .padding()
    }
}

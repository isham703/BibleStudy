import SwiftUI

// MARK: - Daily Verse Card
// Displays the daily verse with flat styling
// Stoic-Existential Renaissance design

struct DailyVerseCard: View {
    let verse: MockDailyVerse

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Verse text (serif for contemplation)
            Text("\"\(verse.text)\"")
                .font(Typography.Scripture.body)
                .foregroundStyle(Color("AppTextPrimary"))
                .lineSpacing(6)

            // Reference (sans for metadata)
            Text(verse.reference)
                .font(Typography.Command.meta)
                .tracking(1.5)
                .foregroundStyle(Color("AccentBronze"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.appSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(
                    Color.appDivider,
                    lineWidth: Theme.Stroke.hairline
                )
        )
    }
}

// MARK: - Preview

#Preview("Daily Verse Card") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        DailyVerseCard(verse: SanctuaryMockData.dailyVerse)
            .padding()
    }
}

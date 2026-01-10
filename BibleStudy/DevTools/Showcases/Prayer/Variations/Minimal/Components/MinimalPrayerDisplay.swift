import SwiftUI

// MARK: - Minimal Prayer Display
// Simple, elegant prayer text display

struct MinimalPrayerDisplay: View {
    let prayer: any PrayerDisplayable
    let tradition: PrayerTradition

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 24) {
            // Simple cross ornament
            Text("+")
                .font(Typography.Icon.xl.weight(.light))
                .foregroundStyle(DeepPrayerColors.roseAccent.opacity(Theme.Opacity.medium))
                .opacity(hasAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: hasAppeared)

            // Prayer text
            Text(prayer.content)
                .font(Typography.Scripture.body)
                .foregroundStyle(DeepPrayerColors.primaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .opacity(hasAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: hasAppeared)

            // Amen
            Text(prayer.amen)
                .font(Typography.Scripture.footnote)
                .foregroundStyle(DeepPrayerColors.secondaryText)
                .italic()
                .opacity(hasAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: hasAppeared)

            // Simple divider
            HStack(spacing: 12) {
                Rectangle()
                    .fill(DeepPrayerColors.roseAccent.opacity(Theme.Opacity.light))
                    .frame(width: 30, height: 1)
                Circle()
                    .fill(DeepPrayerColors.roseAccent.opacity(Theme.Opacity.subtle))
                    .frame(width: 4, height: 4)
                Rectangle()
                    .fill(DeepPrayerColors.roseAccent.opacity(Theme.Opacity.light))
                    .frame(width: 30, height: 1)
            }
            .opacity(hasAppeared ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.35), value: hasAppeared)

            // Tradition attribution
            Text("In the tradition of \(tradition.rawValue)")
                .font(Typography.Icon.xs)
                .foregroundStyle(DeepPrayerColors.tertiaryText)
                .opacity(hasAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.4), value: hasAppeared)
        }
        .onAppear {
            hasAppeared = true
        }
    }
}

// MARK: - Preview

#Preview("Minimal Prayer Display") {
    ScrollView {
        MinimalPrayerDisplay(
            prayer: MockPrayer.psalmicLament,
            tradition: .psalmicLament
        )
        .padding()
    }
    .background(DeepPrayerColors.sacredNavy)
}

#Preview("Celtic Prayer") {
    ScrollView {
        MinimalPrayerDisplay(
            prayer: MockPrayer.celtic,
            tradition: .celtic
        )
        .padding()
    }
    .background(DeepPrayerColors.sacredNavy)
}

import SwiftUI

// MARK: - Prayer Display View
// Prayer text renderer with Sacred Manuscript typography

struct PrayerDisplayView: View {
    let prayer: any PrayerDisplayable
    let tradition: PrayerTradition

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            // Cross ornament
            Text("✝")
                .font(Typography.Icon.xl)
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.strong))

            // Prayer with drop cap
            ManuscriptPrayerText(prayer: prayer, colorScheme: colorScheme)

            // Ornamental divider
            PrayerOrnamentalDivider(colorScheme: colorScheme)
                .frame(width: 120)

            // Tradition note
            Text("In the tradition of \(tradition.rawValue)")
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 13, weight: .regular, design: .serif).italic())
                .foregroundStyle(Color.tertiaryText.opacity(Theme.Opacity.overlay))

            // Amen
            Text(prayer.amen)
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 14, weight: .medium, design: .serif))
                // swiftlint:disable:next hardcoded_tracking
                .tracking(6)
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
        }
    }
}

// MARK: - Manuscript Prayer Text (with Drop Cap)

private struct ManuscriptPrayerText: View {
    let prayer: any PrayerDisplayable
    let colorScheme: ColorScheme
    @State private var showDropCap = false

    var body: some View {
        let firstLetter = String(prayer.content.prefix(1))
        let restOfText = String(prayer.content.dropFirst())

        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Drop cap
            Text(firstLetter)
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 72, weight: .medium, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)), .tertiaryText],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .primaryText.opacity(Theme.Opacity.medium), radius: 2, x: 1, y: 2)
                .scaleEffect(showDropCap ? 1 : 0)
                // swiftlint:disable:next hardcoded_animation_spring
                .animation(Theme.Animation.settle, value: showDropCap)

            // Rest of prayer
            Text(restOfText)
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Color.primaryText)
                // swiftlint:disable:next hardcoded_line_spacing
                .lineSpacing(10)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showDropCap = true
            }
        }
    }
}

// MARK: - Ornamental Divider

private struct PrayerOrnamentalDivider: View {
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Left line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme))],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: Theme.Stroke.hairline)

            // Center ornament
            Circle()
                .fill(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
                .frame(width: 6, height: 6)

            // Right line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: Theme.Stroke.hairline)
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            PrayerDisplayView(
                prayer: MockPrayer.psalmicLament,
                tradition: .psalmicLament
            )
            .padding()
        }
    }
}

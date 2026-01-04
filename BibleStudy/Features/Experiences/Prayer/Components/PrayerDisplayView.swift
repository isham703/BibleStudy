import SwiftUI

// MARK: - Prayer Display View
// Prayer text renderer with Sacred Manuscript typography

struct PrayerDisplayView: View {
    let prayer: any PrayerDisplayable
    let tradition: PrayerTradition

    var body: some View {
        VStack(spacing: 24) {
            // Cross ornament
            Text("✝")
                .font(.system(size: 28))
                .foregroundStyle(Color.divineGold.opacity(0.6))

            // Prayer with drop cap
            ManuscriptPrayerText(prayer: prayer)

            // Ornamental divider
            PrayerOrnamentalDivider()
                .frame(width: 120)

            // Tradition note
            Text("In the tradition of \(tradition.rawValue)")
                .font(.custom("CormorantGaramond-Italic", size: 13))
                .foregroundStyle(Color.tertiaryText.opacity(0.7))

            // Amen
            Text(prayer.amen)
                .font(.custom("Cinzel-Regular", size: 14))
                .tracking(6)
                .foregroundStyle(Color.vermillion)
        }
    }
}

// MARK: - Manuscript Prayer Text (with Drop Cap)

private struct ManuscriptPrayerText: View {
    let prayer: any PrayerDisplayable
    @State private var showDropCap = false

    var body: some View {
        let firstLetter = String(prayer.content.prefix(1))
        let restOfText = String(prayer.content.dropFirst())

        HStack(alignment: .top, spacing: 8) {
            // Drop cap
            Text(firstLetter)
                .font(.custom("Cinzel-Regular", size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.divineGold, .tertiaryText],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .primaryText.opacity(0.3), radius: 2, x: 1, y: 2)
                .scaleEffect(showDropCap ? 1 : 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showDropCap)

            // Rest of prayer
            Text(restOfText)
                .font(.custom("CormorantGaramond-SemiBold", size: 20))
                .foregroundStyle(Color.primaryText)
                .lineSpacing(10)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 20)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showDropCap = true
            }
        }
    }
}

// MARK: - Ornamental Divider

private struct PrayerOrnamentalDivider: View {
    var body: some View {
        HStack(spacing: 8) {
            // Left line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .divineGold],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Center ornament
            Circle()
                .fill(Color.divineGold)
                .frame(width: 6, height: 6)

            // Right line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.divineGold, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
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

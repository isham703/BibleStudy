import SwiftUI

// MARK: - Mock Streak Badge
// Displays current reading streak with flame icon and glow effect

struct MockStreakBadge: View {
    let count: Int
    @State private var isPulsing = false

    private var streakColor: Color {
        switch count {
        case 0..<7:
            return .orange
        case 7..<30:
            return .divineGold
        case 30..<100:
            return .illuminatedGold
        default:
            return .goldLeafShimmer
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(streakColor)
                .scaleEffect(isPulsing ? 1.05 : 1.0)

            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.showcasePrimaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(streakColor.opacity(0.15))
        )
        .shadow(color: streakColor.opacity(0.4), radius: isPulsing ? 10 : 6)
        .onAppear {
            withAnimation(SanctuaryTheme.Animation.pulse) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.candlelitStone.ignoresSafeArea()

        VStack(spacing: 20) {
            MockStreakBadge(count: 5)
            MockStreakBadge(count: 14)
            MockStreakBadge(count: 45)
            MockStreakBadge(count: 120)
        }
    }
}

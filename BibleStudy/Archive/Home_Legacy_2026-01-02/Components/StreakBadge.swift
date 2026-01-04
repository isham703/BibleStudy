import SwiftUI

// MARK: - Streak Badge
// Displays current streak with color progression and subtle pulse animation

struct StreakBadge: View {
    let currentStreak: Int
    let graceDayUsed: Bool

    // Streak color based on milestones
    private var streakColor: Color {
        switch currentStreak {
        case 0...6:
            return .accentGold
        case 7...29:
            return .malachite
        case 30...99:
            return .lapisLazuli
        default:
            return .amethyst
        }
    }

    // Check if at a milestone for pulse effect
    private var isMilestone: Bool {
        [7, 14, 21, 30, 50, 100, 365].contains(currentStreak)
    }

    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            // Flame icon
            Image(systemName: "flame.fill")
                .font(Typography.UI.subheadline)
                .foregroundStyle(streakColor)
                .shadow(color: streakColor.opacity(AppTheme.Opacity.heavy), radius: 4, x: 0, y: 0)

            // Streak count
            Text("\(currentStreak)")
                .font(Typography.UI.subheadline.monospacedDigit())
                .fontWeight(.semibold)
                .foregroundStyle(Color.primaryText)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            streakColor.opacity(AppTheme.Opacity.light),
                            streakColor.opacity(AppTheme.Opacity.faint)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            Capsule()
                .stroke(streakColor.opacity(AppTheme.Opacity.quarter), lineWidth: AppTheme.Border.thin)
        )
        // Subtle pulse glow for milestones
        .overlay(
            Capsule()
                .stroke(streakColor.opacity(isPulsing ? 0.6 : 0), lineWidth: AppTheme.Border.regular)
                .scaleEffect(isPulsing ? 1.1 : 1.0)
        )
        // Inner highlight
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(AppTheme.Opacity.medium), lineWidth: AppTheme.Border.thin)
                .padding(AppTheme.Border.thin)
        )
        .shadow(color: streakColor.opacity(AppTheme.Opacity.light), radius: 8, x: 0, y: 2)
        .onAppear {
            if isMilestone {
                withAnimation(
                    AppTheme.Animation.contemplative
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Low Streak") {
    StreakBadge(currentStreak: 3, graceDayUsed: false)
        .padding()
        .background(Color.appBackground)
}

#Preview("Week Milestone") {
    StreakBadge(currentStreak: 7, graceDayUsed: false)
        .padding()
        .background(Color.appBackground)
}

#Preview("Month Streak") {
    StreakBadge(currentStreak: 42, graceDayUsed: true)
        .padding()
        .background(Color.appBackground)
}

#Preview("High Streak") {
    StreakBadge(currentStreak: 120, graceDayUsed: false)
        .padding()
        .background(Color.appBackground)
}

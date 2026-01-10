import SwiftUI

// MARK: - Mock Streak Badge
// Displays current reading streak with flame icon and glow effect

struct StreakBadge: View {
    @Environment(\.colorScheme) private var colorScheme
    let count: Int
    @State private var isPulsing = false

    private var streakColor: Color {
        let themeMode = ThemeMode.current(from: colorScheme)
        switch count {
        case 0..<7:
            return .orange
        case 7..<30:
            return Colors.Semantic.accentSeal(for: themeMode)
        case 30..<100:
            return Colors.Semantic.accentSeal(for: themeMode)
        default:
            return Colors.Semantic.accentSeal(for: themeMode)
        }
    }

    var body: some View {
        let themeMode = ThemeMode.current(from: colorScheme)
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "flame.fill")
                // swiftlint:disable:next hardcoded_font_system
                .font(Typography.Icon.sm)
                .foregroundStyle(streakColor)
                // swiftlint:disable:next hardcoded_scale_effect
                .scaleEffect(isPulsing ? 1.05 : 1.0)

            Text("\(count)")
                // swiftlint:disable:next hardcoded_font_system
                .font(Typography.Command.caption.weight(.bold))
                .foregroundStyle(Colors.Surface.textPrimary(for: themeMode))
        }
        // swiftlint:disable:next hardcoded_padding_edge
        .padding(.horizontal, 10)  // Tight badge padding
        // swiftlint:disable:next hardcoded_padding_edge
        .padding(.vertical, 6)  // Tight badge padding
        .background(
            Capsule()
                .fill(streakColor.opacity(Theme.Opacity.light))
        )
        // swiftlint:disable:next hardcoded_shadow_radius
        .shadow(color: streakColor.opacity(Theme.Opacity.disabled), radius: isPulsing ? 10 : 6)
        .onAppear {
            withAnimation(Theme.Animation.fade) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @Environment(\.colorScheme) var colorScheme
    let themeMode = ThemeMode.current(from: colorScheme)

    ZStack {
        Colors.Surface.background(for: themeMode).ignoresSafeArea()

        VStack(spacing: Theme.Spacing.xl) {
            StreakBadge(count: 5)
            StreakBadge(count: 14)
            StreakBadge(count: 45)
            StreakBadge(count: 120)
        }
    }
}

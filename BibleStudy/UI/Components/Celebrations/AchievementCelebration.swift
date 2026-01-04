import SwiftUI

// MARK: - Achievement Celebration
// Displays when user unlocks a new achievement

struct AchievementCelebration: View {
    let achievement: Achievement
    var onComplete: (() -> Void)?

    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showXP = false
    @State private var showPulse = false
    @State private var iconRotation: Double = -10
    @State private var iconScale: CGFloat = 0.5

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Achievement badge with pulse
            ZStack {
                // Pulse rings
                if showPulse {
                    RippleEffect(color: categoryColor, rippleCount: 2, maxScale: 2)
                        .frame(width: 80, height: 80)
                }

                // Badge background
                Circle()
                    .fill(categoryColor.opacity(AppTheme.Opacity.lightMedium))
                    .frame(width: 80, height: 80)

                // Icon
                if showIcon {
                    Image(systemName: achievement.icon)
                        // swiftlint:disable:next hardcoded_font_system
                        .font(.system(size: AppTheme.IconSize.celebration, weight: .medium))
                        .foregroundStyle(categoryColor)
                        .rotationEffect(.degrees(iconRotation))
                        .scaleEffect(iconScale)
                }
            }

            // Achievement title
            if showTitle {
                VStack(spacing: AppTheme.Spacing.xs) {
                    Text("Achievement Unlocked!")
                        .font(Typography.UI.warmSubheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.secondaryText)

                    Text(achievement.title)
                        .font(Typography.Display.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.primaryText)
                        .multilineTextAlignment(.center)

                    Text(achievement.description)
                        .font(Typography.UI.warmSubheadline)
                        .foregroundStyle(Color.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .transition(.scale.combined(with: .opacity))
            }

            // XP Reward
            if showXP {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "star.fill")
                        .font(Typography.UI.subheadline)
                        .foregroundStyle(Color.scholarAccent)

                    Text("+\(achievement.xpReward) XP")
                        .font(Typography.UI.headline.monospacedDigit())
                        .fontWeight(.bold)
                        .foregroundStyle(Color.scholarAccent)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(Color.scholarAccent.opacity(AppTheme.Opacity.subtle))
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 280)
        .onAppear {
            animate()
        }
    }

    private var categoryColor: Color {
        switch achievement.category {
        case .reading: return .accentBlue
        case .memorization: return .highlightPurple
        case .streaks: return .orange
        case .study: return .scholarAccent
        case .milestones: return .highlightGreen
        }
    }

    private func animate() {
        if respectsReducedMotion {
            showIcon = true
            showTitle = true
            showXP = true
            iconRotation = 0
            iconScale = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onComplete?()
            }
            return
        }

        // Pulse first
        showPulse = true

        // Icon bounces in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showIcon = true
            withAnimation(AppTheme.Animation.celebrationBounce) {
                iconRotation = 0
                iconScale = 1.2
            }

            // Scale back down
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(AppTheme.Animation.celebrationSettle) {
                    iconScale = 1
                }
            }
        }

        // Title slides in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(AppTheme.Animation.spring) {
                showTitle = true
            }
        }

        // XP badge pops in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(AppTheme.Animation.spring) {
                showXP = true
            }
        }

        // Callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            onComplete?()
        }
    }
}

// MARK: - User Level Up Celebration
// Displays when user reaches a new XP level

struct UserLevelUpCelebration: View {
    let fromLevel: UserLevel
    let toLevel: UserLevel
    var onComplete: (() -> Void)?

    @State private var showOldLevel = false
    @State private var showArrow = false
    @State private var showNewLevel = false
    @State private var showPulse = false
    @State private var showCongrats = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Level Up Text
            if showCongrats {
                Text("Level Up!")
                    .font(Typography.UI.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [toLevel.color, toLevel.color.opacity(AppTheme.Opacity.strong)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .transition(.scale.combined(with: .opacity))
            }

            // Level transition
            HStack(spacing: AppTheme.Spacing.lg) {
                // Old level
                if showOldLevel {
                    LevelBadge(level: fromLevel, isActive: false)
                        .opacity(AppTheme.Opacity.disabled)
                }

                // Arrow
                if showArrow {
                    Image(systemName: "arrow.right")
                        .font(Typography.UI.title2)
                        .foregroundStyle(Color.secondaryText)
                        .transition(.scale.combined(with: .opacity))
                }

                // New level with pulse
                if showNewLevel {
                    ZStack {
                        if showPulse {
                            RippleEffect(color: toLevel.color, rippleCount: 3, maxScale: 2.5)
                                .frame(width: 60, height: 60)
                        }

                        LevelBadge(level: toLevel, isActive: true)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }

            // New level description
            if showNewLevel {
                VStack(spacing: AppTheme.Spacing.xs) {
                    Text("You are now a")
                        .font(Typography.UI.subheadline)
                        .foregroundStyle(Color.secondaryText)

                    Text(toLevel.displayName)
                        .font(Typography.UI.title1)
                        .fontWeight(.bold)
                        .foregroundStyle(toLevel.color)

                    Text(toLevel.celebrationDescription)
                        .font(Typography.UI.footnote)
                        .foregroundStyle(Color.tertiaryText)
                        .multilineTextAlignment(.center)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(width: 300)
        .onAppear {
            animate()
        }
    }

    private func animate() {
        if respectsReducedMotion {
            showOldLevel = true
            showArrow = true
            showNewLevel = true
            showPulse = true
            showCongrats = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onComplete?()
            }
            return
        }

        // Old level appears
        withAnimation(AppTheme.Animation.standard) {
            showOldLevel = true
        }

        // Arrow
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(AppTheme.Animation.spring) {
                showArrow = true
            }
        }

        // New level with pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showPulse = true
            withAnimation(AppTheme.Animation.spring) {
                showNewLevel = true
            }
        }

        // Congrats text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(AppTheme.Animation.spring) {
                showCongrats = true
            }
        }

        // Callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            onComplete?()
        }
    }
}

// MARK: - Level Badge
private struct LevelBadge: View {
    let level: UserLevel
    let isActive: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxs) {
            ZStack {
                Circle()
                    .fill(isActive ? level.color.opacity(AppTheme.Opacity.lightMedium) : Color.surfaceBackground)
                    .frame(width: 50, height: 50)

                Image(systemName: level.icon)
                    .font(Typography.UI.title2)
                    .foregroundStyle(isActive ? level.color : Color.tertiaryText)
            }

            Text(level.displayName)
                .font(Typography.UI.caption2)
                .foregroundStyle(isActive ? level.color : Color.tertiaryText)
        }
    }
}

// MARK: - UserLevel Extensions
extension UserLevel {
    var color: Color {
        switch self {
        case .novice: return .secondaryText
        case .apprentice: return .accentBlue
        case .scholar: return .scholarAccent
        case .master: return .highlightPurple
        case .sage: return .highlightGreen
        }
    }

    var celebrationDescription: String {
        switch self {
        case .novice: return "Just getting started"
        case .apprentice: return "Building a foundation"
        case .scholar: return "Growing in wisdom"
        case .master: return "Deep understanding"
        case .sage: return "Walking in the light"
        }
    }
}

// MARK: - Preview

#Preview("Achievement Celebration") {
    VStack {
        AchievementCelebration(
            achievement: Achievement(
                id: "first_chapter",
                title: "First Steps",
                description: "Read your first chapter",
                icon: "book",
                category: .reading,
                xpReward: 25,
                isSecret: false,
                requiredProgress: 1,
                isUnlocked: true,
                unlockedAt: Date()
            )
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.appBackground)
}

#Preview("Level Up Celebration") {
    VStack {
        UserLevelUpCelebration(
            fromLevel: .novice,
            toLevel: .apprentice
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.appBackground)
}

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
    @Environment(\.colorScheme) private var colorScheme

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Achievement badge with pulse
            ZStack {
                // Pulse rings
                if showPulse {
                    RippleEffect(color: categoryColor, rippleCount: 2, maxScale: 2)
                        .frame(width: 80, height: 80)
                }

                // Badge background
                Circle()
                    .fill(categoryColor.opacity(Theme.Opacity.selectionBackground))
                    .frame(width: 80, height: 80)

                // Icon
                if showIcon {
                    Image(systemName: achievement.icon)
                        // swiftlint:disable:next hardcoded_font_system
                        .font(Typography.Icon.hero.weight(.medium))
                        .foregroundStyle(categoryColor)
                        .rotationEffect(.degrees(iconRotation))
                        .scaleEffect(iconScale)
                }
            }

            // Achievement title
            if showTitle {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("Achievement Unlocked!")
                        .font(Typography.Command.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color("AppTextSecondary"))

                    Text(achievement.title)
                        .font(Typography.Scripture.heading)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .multilineTextAlignment(.center)

                    Text(achievement.description)
                        .font(Typography.Command.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .multilineTextAlignment(.center)
                }
                .transition(.scale.combined(with: .opacity))
            }

            // XP Reward
            if showXP {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "star.fill")
                        .font(Typography.Command.subheadline)
                        .foregroundStyle(Color("AppAccentAction"))

                    Text("+\(achievement.xpReward) XP")
                        .font(Typography.Command.headline.monospacedDigit())
                        .fontWeight(.bold)
                        .foregroundStyle(Color("AppAccentAction"))
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(Color("AppAccentAction").opacity(Theme.Opacity.subtle))
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
        case .reading: return Color("AppAccentAction")
        case .memorization: return Color("AppAccentAction")
        case .streaks: return .orange
        case .study: return Color("AppAccentAction")
        case .milestones: return Color("FeedbackSuccess")
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
            withAnimation(Theme.Animation.settle) {
                iconRotation = 0
                iconScale = 1.2
            }

            // Scale back down
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(Theme.Animation.settle) {
                    iconScale = 1
                }
            }
        }

        // Title slides in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(Theme.Animation.settle) {
                showTitle = true
            }
        }

        // XP badge pops in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(Theme.Animation.settle) {
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
        VStack(spacing: Theme.Spacing.lg) {
            // Level Up Text
            if showCongrats {
                Text("Level Up!")
                    .font(Typography.Command.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [toLevel.color, toLevel.color.opacity(Theme.Opacity.pressed)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .transition(.scale.combined(with: .opacity))
            }

            // Level transition
            HStack(spacing: Theme.Spacing.lg) {
                // Old level
                if showOldLevel {
                    LevelBadge(level: fromLevel, isActive: false)
                        .opacity(Theme.Opacity.disabled)
                }

                // Arrow
                if showArrow {
                    Image(systemName: "arrow.right")
                        .font(Typography.Command.title2)
                        .foregroundStyle(Color("AppTextSecondary"))
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
                VStack(spacing: Theme.Spacing.xs) {
                    Text("You are now a")
                        .font(Typography.Command.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))

                    Text(toLevel.displayName)
                        .font(Typography.Command.title1)
                        .fontWeight(.bold)
                        .foregroundStyle(toLevel.color)

                    Text(toLevel.celebrationDescription)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("TertiaryText"))
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
        withAnimation(Theme.Animation.settle) {
            showOldLevel = true
        }

        // Arrow
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(Theme.Animation.settle) {
                showArrow = true
            }
        }

        // New level with pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showPulse = true
            withAnimation(Theme.Animation.settle) {
                showNewLevel = true
            }
        }

        // Congrats text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(Theme.Animation.settle) {
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
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(isActive ? level.color.opacity(Theme.Opacity.selectionBackground) : Color("AppSurface"))
                    .frame(width: 50, height: 50)

                Image(systemName: level.icon)
                    .font(Typography.Command.title2)
                    .foregroundStyle(isActive ? level.color : Color("TertiaryText"))
            }

            Text(level.displayName)
                .font(Typography.Command.meta)
                .foregroundStyle(isActive ? level.color : Color("TertiaryText"))
        }
    }
}

// MARK: - UserLevel Extensions
extension UserLevel {
    var color: Color {
        switch self {
        case .novice: return Color("AppTextSecondary")
        case .apprentice: return Color("AppAccentAction")
        case .scholar: return Color("AppAccentAction")
        case .master: return Color("AppAccentAction")
        case .sage: return Color("FeedbackSuccess")
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

// MARK: - Correct Answer Celebration
// Quick positive feedback for correct memorization answers

struct CorrectAnswerCelebration: View {
    var onComplete: (() -> Void)?

    @State private var showCheck = false
    @State private var checkScale: CGFloat = 0.5
    @State private var showPulse = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            if showPulse {
                RippleEffect(color: Color("FeedbackSuccess"), rippleCount: 2, maxScale: 1.5)
                    .frame(width: 60, height: 60)
            }

            Circle()
                .fill(Color("FeedbackSuccess").opacity(Theme.Opacity.selectionBackground))
                .frame(width: 60, height: 60)

            if showCheck {
                Image(systemName: "checkmark")
                    .font(Typography.Command.title1.weight(.bold))
                    .foregroundStyle(Color("FeedbackSuccess"))
                    .scaleEffect(checkScale)
            }
        }
        .onAppear {
            animate()
        }
    }

    private func animate() {
        if respectsReducedMotion {
            showCheck = true
            checkScale = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete?()
            }
            return
        }

        showPulse = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showCheck = true
            withAnimation(Theme.Animation.settle) {
                checkScale = 1.2
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(Theme.Animation.settle) {
                    checkScale = 1
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onComplete?()
        }
    }
}

// MARK: - Wrong Answer Feedback
// Gentle feedback for incorrect memorization answers

struct WrongAnswerFeedback: View {
    var onComplete: (() -> Void)?

    @State private var showX = false
    @State private var shakeOffset: CGFloat = 0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color("FeedbackError").opacity(Theme.Opacity.selectionBackground))
                .frame(width: 60, height: 60)

            if showX {
                Image(systemName: "xmark")
                    .font(Typography.Command.title1.weight(.bold))
                    .foregroundStyle(Color("FeedbackError"))
                    .offset(x: shakeOffset)
            }
        }
        .onAppear {
            animate()
        }
    }

    private func animate() {
        showX = true

        if respectsReducedMotion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete?()
            }
            return
        }

        // Shake animation
        withAnimation(Theme.Animation.fade) {
            shakeOffset = 8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(Theme.Animation.fade) {
                shakeOffset = -8
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(Theme.Animation.fade) {
                shakeOffset = 4
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(Theme.Animation.fade) {
                shakeOffset = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onComplete?()
        }
    }
}

// MARK: - First Verse Mastered Celebration
// Special celebration for mastering your first verse

struct FirstVerseMasteredCelebration: View {
    var onComplete: (() -> Void)?

    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showPulse = false
    @State private var iconScale: CGFloat = 0.5

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                if showPulse {
                    RippleEffect(color: Color("AppAccentAction"), rippleCount: 3, maxScale: 2)
                        .frame(width: 80, height: 80)
                }

                Circle()
                    .fill(Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground))
                    .frame(width: 80, height: 80)

                if showIcon {
                    Image(systemName: "star.fill")
                        .font(Typography.Icon.hero.weight(.medium))
                        .foregroundStyle(Color("AppAccentAction"))
                        .scaleEffect(iconScale)
                }
            }

            if showTitle {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("First Verse Mastered!")
                        .font(Typography.Scripture.heading)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text("Your journey has begun")
                        .font(Typography.Command.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 280)
        .onAppear {
            animate()
        }
    }

    private func animate() {
        if respectsReducedMotion {
            showIcon = true
            showTitle = true
            iconScale = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onComplete?()
            }
            return
        }

        showPulse = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showIcon = true
            withAnimation(Theme.Animation.settle) {
                iconScale = 1.2
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(Theme.Animation.settle) {
                    iconScale = 1
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(Theme.Animation.settle) {
                showTitle = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            onComplete?()
        }
    }
}

// MARK: - Streak Celebration
// Celebration for streak milestones

struct StreakCelebration: View {
    let streakCount: Int
    var onComplete: (() -> Void)?

    @State private var showFlame = false
    @State private var showCount = false
    @State private var showTitle = false
    @State private var flameScale: CGFloat = 0.5

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(Theme.Opacity.selectionBackground))
                    .frame(width: 80, height: 80)

                if showFlame {
                    Image(systemName: "flame.fill")
                        .font(Typography.Icon.hero.weight(.medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .scaleEffect(flameScale)
                }
            }

            if showCount {
                Text("\(streakCount)")
                    .font(Typography.Command.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.orange)
                    .transition(.scale.combined(with: .opacity))
            }

            if showTitle {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("Day Streak!")
                        .font(Typography.Scripture.heading)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text("Keep the flame alive")
                        .font(Typography.Command.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 280)
        .onAppear {
            animate()
        }
    }

    private func animate() {
        if respectsReducedMotion {
            showFlame = true
            showCount = true
            showTitle = true
            flameScale = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onComplete?()
            }
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showFlame = true
            withAnimation(Theme.Animation.settle) {
                flameScale = 1.3
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(Theme.Animation.settle) {
                    flameScale = 1
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(Theme.Animation.settle) {
                showCount = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(Theme.Animation.settle) {
                showTitle = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            onComplete?()
        }
    }
}

// MARK: - Level Up Celebration (Mastery Level)
// Displays when a memorization item reaches a new mastery level

struct LevelUpCelebration: View {
    let fromLevel: MasteryLevel
    let toLevel: MasteryLevel
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
        VStack(spacing: Theme.Spacing.lg) {
            if showCongrats {
                Text("Level Up!")
                    .font(Typography.Command.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [toLevel.celebrationColor, toLevel.celebrationColor.opacity(Theme.Opacity.pressed)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .transition(.scale.combined(with: .opacity))
            }

            HStack(spacing: Theme.Spacing.lg) {
                if showOldLevel {
                    MasteryLevelBadge(level: fromLevel, isActive: false)
                        .opacity(Theme.Opacity.disabled)
                }

                if showArrow {
                    Image(systemName: "arrow.right")
                        .font(Typography.Command.title2)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .transition(.scale.combined(with: .opacity))
                }

                if showNewLevel {
                    ZStack {
                        if showPulse {
                            RippleEffect(color: toLevel.celebrationColor, rippleCount: 3, maxScale: 2.5)
                                .frame(width: 60, height: 60)
                        }

                        MasteryLevelBadge(level: toLevel, isActive: true)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }

            if showNewLevel {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("Now at")
                        .font(Typography.Command.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))

                    Text(toLevel.displayName)
                        .font(Typography.Command.title1)
                        .fontWeight(.bold)
                        .foregroundStyle(toLevel.celebrationColor)
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

        withAnimation(Theme.Animation.settle) {
            showOldLevel = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(Theme.Animation.settle) {
                showArrow = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showPulse = true
            withAnimation(Theme.Animation.settle) {
                showNewLevel = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(Theme.Animation.settle) {
                showCongrats = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            onComplete?()
        }
    }
}

// MARK: - Mastery Level Badge
private struct MasteryLevelBadge: View {
    let level: MasteryLevel
    let isActive: Bool

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(isActive ? level.celebrationColor.opacity(Theme.Opacity.selectionBackground) : Color("AppSurface"))
                    .frame(width: 50, height: 50)

                Image(systemName: level.icon)
                    .font(Typography.Command.title2)
                    .foregroundStyle(isActive ? level.celebrationColor : Color("TertiaryText"))
            }

            Text(level.displayName)
                .font(Typography.Command.meta)
                .foregroundStyle(isActive ? level.celebrationColor : Color("TertiaryText"))
        }
    }
}

// MARK: - MasteryLevel Extensions
extension MasteryLevel {
    var celebrationColor: Color {
        switch self {
        case .learning: return Color("AppTextSecondary")
        case .reviewing: return Color("AppAccentAction")
        case .mastered: return Color("FeedbackSuccess")
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

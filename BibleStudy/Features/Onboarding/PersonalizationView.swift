import SwiftUI

// MARK: - Personalization View
// Shows loading animation while setting up the personalized experience

struct PersonalizationView: View {
    let onboardingData: OnboardingData
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var showCompletion = false
    @State private var animatedProgress: CGFloat = 0

    private let steps = [
        "Setting up your reading goals",
        "Preparing AI insights",
        "Configuring memorization"
    ]

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.xxl) {
                Spacer()

                // Animated book icon
                PersonalizationAnimation(progress: animatedProgress)
                    .frame(width: 200, height: 200)

                // Loading text
                VStack(spacing: AppTheme.Spacing.lg) {
                    Text("Creating your experience...")
                        .font(Typography.UI.title2)
                        .foregroundStyle(Color.primaryText)

                    // Animated checklist
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            HStack(spacing: AppTheme.Spacing.md) {
                                ZStack {
                                    if index < currentStep {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.accentGold)
                                            .transition(.scale.combined(with: .opacity))
                                    } else if index == currentStep {
                                        ProgressView()
                                            .scaleEffect(AppTheme.Scale.reduced)
                                            .tint(Color.accentGold)
                                    } else {
                                        Circle()
                                            .stroke(Color.cardBorder, lineWidth: AppTheme.Border.regular)
                                            .frame(width: 20, height: 20)
                                    }
                                }
                                .frame(width: 24, height: 24)

                                Text(step)
                                    .font(Typography.UI.body)
                                    .foregroundStyle(index <= currentStep ? Color.primaryText : Color.tertiaryText)
                            }
                            .animation(AppTheme.Animation.spring, value: currentStep)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxl)
                }

                Spacer()

                // Mode assignment result
                if showCompletion {
                    VStack(spacing: AppTheme.Spacing.md) {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: onboardingData.recommendedMode.icon)
                                .foregroundStyle(Color.accentGold)
                            Text(onboardingData.recommendedMode.displayName)
                                .font(Typography.UI.headline)
                                .foregroundStyle(Color.primaryText)
                        }

                        Text(onboardingData.recommendedMode.description)
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.secondaryText)
                            .multilineTextAlignment(.center)

                        Text("You can change this anytime in Settings")
                            .font(Typography.UI.caption2)
                            .foregroundStyle(Color.tertiaryText)
                            .padding(.top, AppTheme.Spacing.xs)
                    }
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.bottom, AppTheme.Spacing.xxl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            startPersonalization()
        }
    }

    private func startPersonalization() {
        if respectsReducedMotion {
            // Skip animation for reduced motion
            currentStep = steps.count
            animatedProgress = 1
            showCompletion = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete()
            }
            return
        }

        // Animate through steps
        for (index, _) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.8) {
                withAnimation(AppTheme.Animation.spring) {
                    currentStep = index + 1
                    animatedProgress = CGFloat(index + 1) / CGFloat(steps.count)
                }
            }
        }

        // Show completion
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps.count) * 0.8 + 0.3) {
            withAnimation(AppTheme.Animation.spring) {
                showCompletion = true
            }
        }

        // Auto-advance
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps.count) * 0.8 + 1.5) {
            onComplete()
        }
    }
}

// MARK: - Personalization Animation

struct PersonalizationAnimation: View {
    let progress: CGFloat

    @State private var rotation: Double = 0
    @State private var particleOpacity: Double = 0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Gold particle effect
            ForEach(0..<8, id: \.self) { index in
                let angle = (2 * .pi / 8) * CGFloat(index)
                let radius: CGFloat = 70 + progress * 20

                Circle()
                    .fill(Color.accentGold.opacity(AppTheme.Opacity.strong * particleOpacity))
                    .frame(width: 8 + progress * 4, height: 8 + progress * 4)
                    .blur(radius: AppTheme.Blur.subtle - 1)
                    .offset(
                        x: cos(angle + rotation / 180 * .pi) * radius,
                        y: sin(angle + rotation / 180 * .pi) * radius
                    )
            }

            // Outer glow
            Circle()
                .fill(Color.accentGold.opacity(AppTheme.Opacity.lightMedium * progress))
                .frame(width: 120, height: 120)
                .blur(radius: AppTheme.Blur.heavy)

            // Book pages effect
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(Color.warmGoldLight.opacity(AppTheme.Opacity.medium + Double(index) * AppTheme.Opacity.lightMedium))
                    .frame(width: 50 - CGFloat(index) * 4, height: 70)
                    .offset(x: CGFloat(index) * 3, y: 0)
                    .rotationEffect(.degrees(Double(index) * 2))
            }

            // Main book
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(
                        LinearGradient(
                            colors: [.warmGold, .warmGoldDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 75)

                // Book spine
                Rectangle()
                    .fill(Color.warmGoldDark.opacity(AppTheme.Opacity.heavy))
                    .frame(width: 4, height: 75)
                    .offset(x: -28)

                // Cross symbol
                Image(systemName: "cross.fill")
                    .font(Typography.UI.title2)
                    .foregroundStyle(.white.opacity(AppTheme.Opacity.high))
            }

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.warmGold, .warmGoldLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: AppTheme.Border.thick + 1, lineCap: .round)
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))
                .animation(AppTheme.Animation.slow, value: progress)
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        if respectsReducedMotion {
            particleOpacity = 1
            return
        }

        withAnimation(AppTheme.Animation.standard) {
            particleOpacity = 1
        }

        withAnimation(AppTheme.Animation.slow.repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
}

// MARK: - Preview

#Preview {
    PersonalizationView(
        onboardingData: OnboardingData(
            primaryFocus: "devotional",
            dailyTimeCommitment: "10",
            experienceLevel: "occasional"
        ),
        onComplete: {}
    )
}

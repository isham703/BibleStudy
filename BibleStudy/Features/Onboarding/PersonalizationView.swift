import SwiftUI

// MARK: - Personalization View
// Shows loading animation while setting up the personalized experience

struct PersonalizationView: View {
    let onboardingData: OnboardingData
    let onComplete: () -> Void

    @Environment(\.colorScheme) private var colorScheme
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

            VStack(spacing: Theme.Spacing.xxl) {
                Spacer()

                // Animated book icon
                PersonalizationAnimation(progress: animatedProgress)
                    .frame(width: 200, height: 200)

                // Loading text
                VStack(spacing: Theme.Spacing.lg) {
                    Text("Creating your experience...")
                        .font(Typography.Command.title2)
                        .foregroundStyle(Color.primaryText)

                    // Animated checklist
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            HStack(spacing: Theme.Spacing.md) {
                                ZStack {
                                    if index < currentStep {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                                            .transition(.scale.combined(with: .opacity))
                                    } else if index == currentStep {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                                    } else {
                                        Circle()
                                            .stroke(Color.cardBorder, lineWidth: Theme.Stroke.control)
                                            .frame(width: 20, height: 20)
                                    }
                                }
                                .frame(width: 24, height: 24)

                                Text(step)
                                    .font(Typography.Command.body)
                                    .foregroundStyle(index <= currentStep ? Color.primaryText : Color.tertiaryText)
                            }
                            .animation(Theme.Animation.settle, value: currentStep)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.xxl)
                }

                Spacer()

                // Mode assignment result
                if showCompletion {
                    VStack(spacing: Theme.Spacing.md) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: onboardingData.recommendedMode.icon)
                                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                            Text(onboardingData.recommendedMode.displayName)
                                .font(Typography.Command.headline)
                                .foregroundStyle(Color.primaryText)
                        }

                        Text(onboardingData.recommendedMode.description)
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color.secondaryText)
                            .multilineTextAlignment(.center)

                        Text("You can change this anytime in Settings")
                            .font(Typography.Command.meta)
                            .foregroundStyle(Color.tertiaryText)
                            .padding(.top, Theme.Spacing.xs)
                    }
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.bottom, Theme.Spacing.xxl)
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
                withAnimation(Theme.Animation.settle) {
                    currentStep = index + 1
                    animatedProgress = CGFloat(index + 1) / CGFloat(steps.count)
                }
            }
        }

        // Show completion
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps.count) * 0.8 + 0.3) {
            withAnimation(Theme.Animation.settle) {
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

    @Environment(\.colorScheme) private var colorScheme
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
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.strong * particleOpacity))
                    .frame(width: 8 + progress * 4, height: 8 + progress * 4)
                    .blur(radius: 4 - 1)
                    .offset(
                        x: cos(angle + rotation / 180 * .pi) * radius,
                        y: sin(angle + rotation / 180 * .pi) * radius
                    )
            }

            // Outer glow
            Circle()
                .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium * progress))
                .frame(width: 120, height: 120)
                .blur(radius: 16)

            // Book pages effect
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.medium + Double(index) * Theme.Opacity.lightMedium))
                    .frame(width: 50 - CGFloat(index) * 4, height: 70)
                    .offset(x: CGFloat(index) * 3, y: 0)
                    .rotationEffect(.degrees(Double(index) * 2))
            }

            // Main book
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
                    .frame(width: 60, height: 75)

                // Book spine
                Rectangle()
                    .fill(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.heavy))
                    .frame(width: 4, height: 75)
                    .offset(x: -28)

                // Cross symbol
                Image(systemName: "cross.fill")
                    .font(Typography.Command.title2)
                    .foregroundStyle(.white.opacity(Theme.Opacity.high))
            }

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)),
                    style: StrokeStyle(lineWidth: Theme.Stroke.control + 1, lineCap: .round)
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))
                .animation(Theme.Animation.slowFade, value: progress)
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

        withAnimation(Theme.Animation.settle) {
            particleOpacity = 1
        }

        withAnimation(Theme.Animation.slowFade.repeatForever(autoreverses: false)) {
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

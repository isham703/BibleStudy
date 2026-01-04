import SwiftUI
import Combine

// MARK: - AI Animations
// Lines & connections themed animations for the AI Ask tab

// MARK: - AI Empty State Animation
// Central question node with dormant connection lines

struct AIEmptyStateAnimation: View {
    @State private var pulsePhase: CGFloat = 0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Dormant connection network
            NetworkGraph(
                nodes: [
                    NetworkNode(id: "center", x: 0.5, y: 0.45, size: 20, state: .pulsing),
                    NetworkNode(id: "n1", x: 0.2, y: 0.25, size: 8, state: .idle),
                    NetworkNode(id: "n2", x: 0.8, y: 0.25, size: 8, state: .idle),
                    NetworkNode(id: "n3", x: 0.15, y: 0.65, size: 8, state: .idle),
                    NetworkNode(id: "n4", x: 0.85, y: 0.65, size: 8, state: .idle),
                    NetworkNode(id: "n5", x: 0.5, y: 0.85, size: 8, state: .idle),
                ],
                connections: [
                    NetworkConnection(from: "center", to: "n1", dashed: true),
                    NetworkConnection(from: "center", to: "n2", dashed: true),
                    NetworkConnection(from: "center", to: "n3", dashed: true),
                    NetworkConnection(from: "center", to: "n4", dashed: true),
                    NetworkConnection(from: "center", to: "n5", dashed: true),
                ],
                animateOnAppear: true,
                staggerDelay: 0.1
            )

            // Question mark in center
            Text("?")
                .font(Typography.UI.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.white)
                .offset(y: -10)
        }
    }
}

// MARK: - AI Thinking Animation
// Question node sends signal through network

struct AIThinkingAnimation: View {
    @State private var flowPhase: Int = 0
    @State private var dotOpacities: [Double] = [1.0, 0.5, 0.3]

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // Neural network visualization
            ZStack {
                // Flowing connections
                NetworkGraph(
                    nodes: [
                        NetworkNode(id: "q", x: 0.15, y: 0.5, size: 14, state: .active),
                        NetworkNode(id: "p1", x: 0.45, y: 0.3, size: 8, state: flowPhase >= 1 ? .pulsing : .idle),
                        NetworkNode(id: "p2", x: 0.45, y: 0.7, size: 8, state: flowPhase >= 1 ? .pulsing : .idle),
                        NetworkNode(id: "a", x: 0.85, y: 0.5, size: 12, state: flowPhase >= 2 ? .pulsing : .idle),
                    ],
                    connections: [
                        NetworkConnection(from: "q", to: "p1", isFlowing: true, flowSpeed: 1.5),
                        NetworkConnection(from: "q", to: "p2", isFlowing: true, flowSpeed: 1.8),
                        NetworkConnection(from: "p1", to: "a", isFlowing: flowPhase >= 1, flowSpeed: 1.5),
                        NetworkConnection(from: "p2", to: "a", isFlowing: flowPhase >= 1, flowSpeed: 1.8),
                    ],
                    animateOnAppear: false
                )
            }
            .frame(width: 100, height: 60)

            // Animated dots
            HStack(spacing: AppTheme.Spacing.xs) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.divineGold)
                        .frame(width: AppTheme.ComponentSize.dotSmall, height: AppTheme.ComponentSize.dotSmall)
                        .opacity(dotOpacities[index])
                }
            }
        }
        .onReceive(timer) { _ in
            guard !respectsReducedMotion else { return }
            animateDots()
            animateFlow()
        }
        .onAppear {
            if respectsReducedMotion {
                dotOpacities = [1.0, 1.0, 1.0]
                flowPhase = 2
            }
        }
    }

    private func animateDots() {
        withAnimation(AppTheme.Animation.standard) {
            let rotated = [dotOpacities[2], dotOpacities[0], dotOpacities[1]]
            dotOpacities = rotated
        }
    }

    private func animateFlow() {
        flowPhase = (flowPhase + 1) % 3
    }
}

// MARK: - AI Response Received Animation
// Connection lines complete to answer node

struct AIResponseReceivedAnimation: View {
    @State private var connectionComplete = false
    @State private var showGlow = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Completed connection
            ConnectionLine(
                start: CGPoint(x: 30, y: 25),
                end: CGPoint(x: 170, y: 25),
                color: .divineGold,
                lineWidth: AppTheme.Border.regular,
                isActive: connectionComplete
            )

            // Source node
            StatefulConnectionNode(size: 12, state: .success)
                .position(x: 30, y: 25)

            // Answer node with glow
            ZStack {
                if showGlow {
                    Circle()
                        .fill(Color.divineGold.opacity(AppTheme.Opacity.medium))
                        .frame(width: 40, height: 40)
                        .blur(radius: AppTheme.Blur.medium)
                }

                StatefulConnectionNode(size: 16, state: connectionComplete ? .success : .idle)
            }
            .position(x: 170, y: 25)
        }
        .frame(width: 200, height: 50)
        .onAppear {
            animate()
        }
    }

    private func animate() {
        if respectsReducedMotion {
            connectionComplete = true
            showGlow = true
            return
        }

        withAnimation(AppTheme.Animation.slow) {
            connectionComplete = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(AppTheme.Animation.standard) {
                showGlow = true
            }
        }
    }
}

// MARK: - AI Inline Loading
// Compact thinking indicator for inline use

struct AIInlineThinking: View {
    @State private var currentDot = 0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    private let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            // Mini network
            HStack(spacing: AppTheme.Spacing.xxs) {
                Circle()
                    .fill(Color.scholarIndigo.opacity(currentDot == 0 ? 1.0 : 0.3))
                    .frame(width: AppTheme.ComponentSize.dot, height: AppTheme.ComponentSize.dot)

                Rectangle()
                    .fill(Color.scholarIndigo.opacity(AppTheme.Opacity.heavy))
                    .frame(width: 8, height: 1)

                Circle()
                    .fill(Color.scholarIndigo.opacity(currentDot == 1 ? 1.0 : 0.3))
                    .frame(width: AppTheme.ComponentSize.dot, height: AppTheme.ComponentSize.dot)

                Rectangle()
                    .fill(Color.scholarIndigo.opacity(AppTheme.Opacity.heavy))
                    .frame(width: 8, height: 1)

                Circle()
                    .fill(Color.scholarIndigo.opacity(currentDot == 2 ? 1.0 : 0.3))
                    .frame(width: AppTheme.ComponentSize.dot, height: AppTheme.ComponentSize.dot)
            }

            Text("Thinking")
                .font(Typography.UI.subheadline)
                .foregroundStyle(Color.secondaryText)
        }
        .onReceive(timer) { _ in
            guard !respectsReducedMotion else { return }
            withAnimation(AppTheme.Animation.quick) {
                currentDot = (currentDot + 1) % 3
            }
        }
    }
}

// MARK: - AI Sparkle Effect
// Decorative sparkle for AI-related content

struct AISparkle: View {
    @State private var sparkleOpacity: Double = 0.5
    @State private var sparkleScale: CGFloat = 0.8

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        Image(systemName: "sparkle")
            .font(Typography.UI.caption1)
            .foregroundStyle(Color.divineGold)
            .opacity(sparkleOpacity)
            .scaleEffect(sparkleScale)
            .onAppear {
                guard !respectsReducedMotion else {
                    sparkleOpacity = 1.0
                    sparkleScale = 1.0
                    return
                }

                withAnimation(
                    AppTheme.Animation.slow
                    .repeatForever(autoreverses: true)
                ) {
                    sparkleOpacity = 1.0
                    sparkleScale = 1.1
                }
            }
    }
}

// MARK: - Preview
#Preview("AI Animations") {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.xxxl) {
            Text("Empty State").font(Typography.UI.headline)
            AIEmptyStateAnimation()
                .frame(width: 200, height: 180)
                .background(Color.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))

            Text("Thinking").font(Typography.UI.headline)
            AIThinkingAnimation()
                .padding()
                .background(Color.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))

            Text("Response Received").font(Typography.UI.headline)
            AIResponseReceivedAnimation()
                .padding()
                .background(Color.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))

            Text("Inline Thinking").font(Typography.UI.headline)
            AIInlineThinking()
                .padding()
                .background(Color.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))

            Text("Sparkle").font(Typography.UI.headline)
            HStack {
                AISparkle()
                Text("AI-powered")
                AISparkle()
            }
            .padding()
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        }
        .padding()
    }
    .background(Color.appBackground)
}

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
                .font(Typography.Command.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.white)
                .offset(y: -10)
        }
    }
}

// MARK: - AI Thinking Animation
// Question node sends signal through network

struct AIThinkingAnimation: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var flowPhase: Int = 0
    @State private var dotOpacities: [Double] = [1.0, 0.5, 0.3]

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: Theme.Spacing.lg) {
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
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color("AccentBronze"))
                        .frame(width: 4, height: 4)
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
        withAnimation(Theme.Animation.settle) {
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
    @Environment(\.colorScheme) private var colorScheme
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
                color: Color("AccentBronze"),
                lineWidth: Theme.Stroke.control,
                isActive: connectionComplete
            )

            // Source node
            StatefulConnectionNode(size: 12, state: .success)
                .position(x: 30, y: 25)

            // Answer node with glow
            ZStack {
                if showGlow {
                    Circle()
                        .fill(Color("AccentBronze").opacity(Theme.Opacity.focusStroke))
                        .frame(width: 40, height: 40)
                        .blur(radius: 8)
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

        withAnimation(Theme.Animation.slowFade) {
            connectionComplete = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(Theme.Animation.settle) {
                showGlow = true
            }
        }
    }
}

// MARK: - AI Inline Loading
// Compact thinking indicator for inline use

struct AIInlineThinking: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentDot = 0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    private let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Mini network
            HStack(spacing: 2) {
                Circle()
                    .fill(Color("AppAccentAction").opacity(currentDot == 0 ? 1.0 : 0.3))
                    .frame(width: 6, height: 6)

                Rectangle()
                    .fill(Color("AppAccentAction").opacity(Theme.Opacity.textSecondary))
                    .frame(width: 8, height: 1)

                Circle()
                    .fill(Color("AppAccentAction").opacity(currentDot == 1 ? 1.0 : 0.3))
                    .frame(width: 6, height: 6)

                Rectangle()
                    .fill(Color("AppAccentAction").opacity(Theme.Opacity.textSecondary))
                    .frame(width: 8, height: 1)

                Circle()
                    .fill(Color("AppAccentAction").opacity(currentDot == 2 ? 1.0 : 0.3))
                    .frame(width: 6, height: 6)
            }

            Text("Thinking")
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .onReceive(timer) { _ in
            guard !respectsReducedMotion else { return }
            withAnimation(Theme.Animation.fade) {
                currentDot = (currentDot + 1) % 3
            }
        }
    }
}

// MARK: - AI Sparkle Effect
// Decorative sparkle for AI-related content

struct AISparkle: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var sparkleOpacity: Double = 0.5
    @State private var sparkleScale: CGFloat = 0.8

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        Image(systemName: "sparkle")
            .font(Typography.Command.caption)
            .foregroundStyle(Color("AccentBronze"))
            .opacity(sparkleOpacity)
            .scaleEffect(sparkleScale)
            .onAppear {
                guard !respectsReducedMotion else {
                    sparkleOpacity = 1.0
                    sparkleScale = 1.0
                    return
                }

                withAnimation(
                    Theme.Animation.slowFade
                    .repeatForever(autoreverses: true)
                ) {
                    sparkleOpacity = 1.0
                    sparkleScale = 1.1
                }
            }
    }
}

// MARK: - Preview

#if DEBUG
struct AIAnimations_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xxl) {
                Text("Empty State").font(Typography.Command.headline)
                AIEmptyStateAnimation()
                    .frame(width: 200, height: 180)
                    .background(Color("AppSurface"))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))

                Text("Thinking").font(Typography.Command.headline)
                AIThinkingAnimation()
                    .padding()
                    .background(Color("AppSurface"))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))

                Text("Response Received").font(Typography.Command.headline)
                AIResponseReceivedAnimation()
                    .padding()
                    .background(Color("AppSurface"))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))

                Text("Inline Thinking").font(Typography.Command.headline)
                AIInlineThinking()
                    .padding()
                    .background(Color("AppSurface"))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))

                Text("Sparkle").font(Typography.Command.headline)
                HStack {
                    AISparkle()
                    Text("AI-powered")
                    AISparkle()
                }
                .padding()
                .background(Color("AppSurface"))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            }
            .padding()
        }
        .background(Color.appBackground)
        .previewDisplayName("AI Animations")
    }
}
#endif

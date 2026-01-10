import SwiftUI

// MARK: - Node Pulse Effect
// Expanding ring animation for success feedback and attention

struct NodePulse: View {
    var color: Color = Color.accentBronze
    var maxScale: CGFloat = 2.5
    var duration: Double = 0.8
    var ringCount: Int = 1

    @State private var isAnimating = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            ForEach(0..<ringCount, id: \.self) { index in
                Circle()
                    .stroke(color, lineWidth: Theme.Stroke.control)
                    .scaleEffect(isAnimating ? maxScale : 1)
                    .opacity(isAnimating ? 0 : 0.8)
                    .animation(
                        respectsReducedMotion ? nil :
                            Theme.Animation.slowFade
                            .delay(Double(index) * 0.15),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            guard !respectsReducedMotion else { return }
            isAnimating = true
        }
    }
}

// MARK: - Continuous Pulse
// For ambient pulsing effects

struct ContinuousPulse: View {
    var color: Color = Color.accentBronze
    var minScale: CGFloat = 0.8
    var maxScale: CGFloat = 1.2
    var duration: Double = 1.5

    @State private var scale: CGFloat = 1.0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        Circle()
            .fill(color.opacity(Theme.Opacity.medium))
            .scaleEffect(scale)
            .onAppear {
                guard !respectsReducedMotion else { return }
                scale = minScale
                withAnimation(
                    Theme.Animation.slowFade
                    .repeatForever(autoreverses: true)
                ) {
                    scale = maxScale
                }
            }
    }
}

// MARK: - Ripple Effect
// Multiple expanding rings for celebration moments

struct RippleEffect: View {
    var color: Color = Color.accentBronze
    var rippleCount: Int = 3
    var maxScale: CGFloat = 3.0
    var duration: Double = 1.2

    @State private var ripples: [UUID] = []

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            ForEach(ripples, id: \.self) { _ in
                SingleRipple(color: color, maxScale: maxScale, duration: duration)
            }
        }
        .onAppear {
            guard !respectsReducedMotion else { return }
            triggerRipples()
        }
    }

    private func triggerRipples() {
        for i in 0..<rippleCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                ripples.append(UUID())
            }
        }
    }
}

private struct SingleRipple: View {
    let color: Color
    let maxScale: CGFloat
    let duration: Double

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.8

    var body: some View {
        Circle()
            .stroke(color, lineWidth: Theme.Stroke.control)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(Theme.Animation.slowFade) {
                    scale = maxScale
                    opacity = 0
                }
            }
    }
}

// MARK: - Success Burst
// Celebratory burst effect for achievements

struct SuccessBurst: View {
    var color: Color = Color.accentBronze
    var particleCount: Int = 8

    @State private var isAnimating = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Center glow
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
                .scaleEffect(isAnimating ? 1.5 : 1)
                .opacity(isAnimating ? 0 : 1)

            // Radiating lines
            ForEach(0..<particleCount, id: \.self) { index in
                let angle = (2 * .pi / CGFloat(particleCount)) * CGFloat(index)

                Rectangle()
                    .fill(color)
                    .frame(width: 3, height: isAnimating ? 30 : 10)
                    .offset(y: isAnimating ? -50 : -15)
                    .rotationEffect(.radians(angle))
                    .opacity(isAnimating ? 0 : 0.8)
            }
        }
        .onAppear {
            guard !respectsReducedMotion else { return }
            withAnimation(Theme.Animation.slowFade) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Checkmark Animation
// Animated checkmark for completion states

struct AnimatedCheckmark: View {
    var color: Color = Color.feedbackSuccess
    var lineWidth: CGFloat = 3
    var size: CGFloat = 40

    @State private var progress: CGFloat = 0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        Canvas { context, canvasSize in
            let checkPath = Path { p in
                let startX = size * 0.2
                let startY = size * 0.5
                let midX = size * 0.4
                let midY = size * 0.7
                let endX = size * 0.8
                let endY = size * 0.3

                p.move(to: CGPoint(x: startX, y: startY))
                p.addLine(to: CGPoint(x: midX, y: midY))
                p.addLine(to: CGPoint(x: endX, y: endY))
            }

            let trimmedPath = checkPath.trimmedPath(
                from: 0,
                to: respectsReducedMotion ? 1 : progress
            )

            context.stroke(
                trimmedPath,
                with: .color(color),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: size, height: size)
        .onAppear {
            guard !respectsReducedMotion else {
                progress = 1
                return
            }
            withAnimation(Theme.Animation.slowFade.delay(0.1)) {
                progress = 1
            }
        }
    }
}

// MARK: - Preview
#Preview("Pulse Effects") {
    VStack(spacing: Theme.Spacing.xxl + Theme.Spacing.md) {
        Text("Node Pulse").font(Typography.Command.headline)
        ZStack {
            NodePulse(ringCount: 3)
                .frame(width: 40, height: 40)
            Circle()
                .fill(Color.accentBronze)
                .frame(width: 16, height: 16)
        }
        .frame(width: 120, height: 120)

        Text("Continuous Pulse").font(Typography.Command.headline)
        ContinuousPulse()
            .frame(width: 60, height: 60)

        Text("Ripple Effect").font(Typography.Command.headline)
        RippleEffect()
            .frame(width: 150, height: 150)

        Text("Success Burst").font(Typography.Command.headline)
        SuccessBurst()
            .frame(width: 120, height: 120)

        Text("Animated Checkmark").font(Typography.Command.headline)
        AnimatedCheckmark()
    }
    .padding()
    .background(Color.appBackground)
}

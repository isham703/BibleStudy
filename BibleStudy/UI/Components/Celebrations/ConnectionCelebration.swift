import SwiftUI

// MARK: - Connection Celebration
// Lines & connections themed celebration animations for memorization milestones

// MARK: - Correct Answer Feedback
// Quick golden connection pulse

struct CorrectAnswerCelebration: View {
    var color: Color = .accentBronze
    var onComplete: (() -> Void)? = nil

    @State private var showPulse = false
    @State private var showCheckmark = false
    @State private var lineProgress: CGFloat = 0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Connection line drawing across
            Canvas { context, size in
                let path = Path { p in
                    p.move(to: CGPoint(x: 0, y: size.height / 2))
                    p.addLine(to: CGPoint(x: size.width, y: size.height / 2))
                }

                let progress = respectsReducedMotion ? 1.0 : lineProgress
                let trimmed = path.trimmedPath(from: 0, to: progress)

                context.stroke(
                    trimmed,
                    with: .color(color.opacity(Theme.Opacity.strong)),
                    style: StrokeStyle(lineWidth: Theme.Stroke.control, lineCap: .round)
                )
            }

            // Center pulse
            if showPulse {
                NodePulse(color: color, maxScale: 3, duration: 0.6, ringCount: 2)
                    .frame(width: 30, height: 30)
            }

            // Checkmark
            if showCheckmark {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 50, height: 50)

                    AnimatedCheckmark(color: .white, lineWidth: Theme.Stroke.control, size: 30)
                }
            }
        }
        .onAppear {
            animate()
        }
    }

    private func animate() {
        guard !respectsReducedMotion else {
            showCheckmark = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                onComplete?()
            }
            return
        }

        // Line draws across
        withAnimation(Theme.Animation.settle) {
            lineProgress = 1.0
        }

        // Pulse at center
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showPulse = true
        }

        // Checkmark appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(Theme.Animation.settle) {
                showCheckmark = true
            }
        }

        // Callback after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onComplete?()
        }
    }
}

// MARK: - Wrong Answer Feedback
// Brief dim with gentle reconnection

struct WrongAnswerFeedback: View {
    var onComplete: (() -> Void)? = nil

    @State private var lineOpacity: CGFloat = 0.5
    @State private var showReconnect = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Dimming line
            ConnectionLine(
                start: CGPoint(x: 30, y: 40),
                end: CGPoint(x: 170, y: 40),
                color: .tertiaryText,
                lineWidth: Theme.Stroke.control,
                isActive: false
            )
            .opacity(lineOpacity)

            // Reconnection attempt
            if showReconnect {
                CurvedConnectionLine(
                    start: CGPoint(x: 30, y: 40),
                    end: CGPoint(x: 170, y: 40),
                    color: .accentBronze.opacity(Theme.Opacity.disabled),
                    lineWidth: Theme.Stroke.control,
                    isActive: false,
                    curvature: 0.2
                )
            }

            // Node with gentle shake effect
            StatefulConnectionNode(size: 16, state: .dimmed)
                .position(x: 100, y: 40)
        }
        .frame(width: 200, height: 80)
        .onAppear {
            animate()
        }
    }

    private func animate() {
        guard !respectsReducedMotion else {
            onComplete?()
            return
        }

        // Dim the line
        withAnimation(Theme.Animation.settle) {
            lineOpacity = 0.2
        }

        // Start reconnection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(Theme.Animation.settle) {
                showReconnect = true
                lineOpacity = 0.5
            }
        }

        // Callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onComplete?()
        }
    }
}

// MARK: - First Verse Mastered Celebration
// Neural pathway "lights up" - connections spreading outward

struct FirstVerseMasteredCelebration: View {
    var onComplete: (() -> Void)? = nil

    @State private var activeConnections: Set<Int> = []
    @State private var showCenterBurst = false
    @State private var showText = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    private let connectionCount = 8

    var body: some View {
        ZStack {
            // Radiating connections
            ForEach(0..<connectionCount, id: \.self) { index in
                let angle = (2 * .pi / CGFloat(connectionCount)) * CGFloat(index)
                let endX: CGFloat = 150 + cos(angle) * 100
                let endY: CGFloat = 150 + sin(angle) * 100

                Group {
                    if activeConnections.contains(index) {
                        CurvedConnectionLine(
                            start: CGPoint(x: 150, y: 150),
                            end: CGPoint(x: endX, y: endY),
                            color: .accentBronze,
                            lineWidth: Theme.Stroke.control,
                            isActive: true,
                            curvature: 0.1
                        )

                        StatefulConnectionNode(size: 10, state: .success)
                            .position(x: endX, y: endY)
                    }
                }
            }

            // Center burst
            if showCenterBurst {
                ZStack {
                    RippleEffect(color: .accentBronze, rippleCount: 3, maxScale: 2.5)
                        .frame(width: 60, height: 60)

                    StatefulConnectionNode(size: 24, state: .success)
                }
                .position(x: 150, y: 150)
            }

            // Celebration text
            if showText {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("First Verse")
                        .font(Typography.Scripture.heading)
                    Text("Mastered!")
                        .font(Typography.Scripture.heading)
                        .fontWeight(.bold)
                }
                .foregroundStyle(Color.accentBronze)
                .position(x: 150, y: 260)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 300, height: 300)
        .onAppear {
            animate()
        }
    }

    private func animate() {
        if respectsReducedMotion {
            activeConnections = Set(0..<connectionCount)
            showCenterBurst = true
            showText = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onComplete?()
            }
            return
        }

        // Center burst first
        withAnimation(Theme.Animation.settle) {
            showCenterBurst = true
        }

        // Connections light up in sequence
        for i in 0..<connectionCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.1) {
                withAnimation(Theme.Animation.settle) {
                    _ = activeConnections.insert(i)
                }
            }
        }

        // Show text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(Theme.Animation.settle) {
                showText = true
            }
        }

        // Callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            onComplete?()
        }
    }
}

// MARK: - Streak Celebration
// Network of connected nodes illuminating in sequence

struct StreakCelebration: View {
    let streakCount: Int // 7 or 30
    var onComplete: (() -> Void)? = nil

    @State private var litNodes: Set<Int> = []
    @State private var showFlame = false
    @State private var showText = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Node chain (horizontal)
            let displayCount = min(streakCount, 7)
            let spacing: CGFloat = 250 / CGFloat(displayCount + 1)

            ForEach(0..<displayCount, id: \.self) { index in
                let x = spacing * CGFloat(index + 1)

                // Connection to previous
                if index > 0 {
                    ConnectionLine(
                        start: CGPoint(x: spacing * CGFloat(index), y: 100),
                        end: CGPoint(x: x, y: 100),
                        color: litNodes.contains(index) ? .accentBronze : .tertiaryText,
                        lineWidth: Theme.Stroke.control,
                        isActive: litNodes.contains(index)
                    )
                }

                // Node
                StatefulConnectionNode(
                    size: 14,
                    state: litNodes.contains(index) ? .success : .idle
                )
                .position(x: x, y: 100)
            }

            // Flame/fire icon at end
            if showFlame {
                Image(systemName: streakCount >= 30 ? "flame.fill" : "flame")
                    .font(Typography.Command.largeTitle)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .accentBronze],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .position(x: 125, y: 50)
                    .transition(.scale.combined(with: .opacity))
            }

            // Streak text
            if showText {
                VStack(spacing: 2) {
                    Text("\(streakCount)")
                        .font(Typography.Scripture.title.monospacedDigit())
                        .fontWeight(.bold)
                    Text("Day Streak!")
                        .font(Typography.Command.subheadline)
                }
                .foregroundStyle(Color.accentBronze)
                .position(x: 125, y: 160)
            }
        }
        .frame(width: 250, height: 200)
        .onAppear {
            animate()
        }
    }

    private func animate() {
        let displayCount = min(streakCount, 7)

        if respectsReducedMotion {
            litNodes = Set(0..<displayCount)
            showFlame = true
            showText = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onComplete?()
            }
            return
        }

        // Light up nodes in sequence
        for i in 0..<displayCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                withAnimation(Theme.Animation.settle) {
                    _ = litNodes.insert(i)
                }
            }
        }

        // Show flame
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(displayCount) * 0.15 + 0.2) {
            withAnimation(Theme.Animation.settle) {
                showFlame = true
            }
        }

        // Show text
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(displayCount) * 0.15 + 0.4) {
            withAnimation(Theme.Animation.settle) {
                showText = true
            }
        }

        // Callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            onComplete?()
        }
    }
}

// MARK: - Level Up Celebration
// Connection lines strengthening animation

struct LevelUpCelebration: View {
    let fromLevel: MasteryLevel
    let toLevel: MasteryLevel
    var onComplete: (() -> Void)? = nil

    @State private var lineWidth: CGFloat = 1
    @State private var showNewLevel = false
    @State private var showPulse = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Connection strengthening
            ForEach(0..<3, id: \.self) { index in
                let yOffset = CGFloat(index - 1) * 30

                ConnectionLine(
                    start: CGPoint(x: 50, y: 100 + yOffset),
                    end: CGPoint(x: 250, y: 100 + yOffset),
                    color: toLevel.uiColor,
                    lineWidth: lineWidth,
                    isActive: true
                )
            }

            // From level node
            VStack(spacing: Theme.Spacing.xs) {
                StatefulConnectionNode(size: 16, state: .dimmed)
                Text(fromLevel.displayName)
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color.tertiaryText)
            }
            .position(x: 50, y: 150)

            // To level node with pulse
            VStack(spacing: Theme.Spacing.xs) {
                ZStack {
                    if showPulse {
                        NodePulse(color: toLevel.uiColor, maxScale: 2.5, ringCount: 2)
                            .frame(width: 20, height: 20)
                    }

                    if showNewLevel {
                        StatefulConnectionNode(size: 20, state: .success)
                    } else {
                        StatefulConnectionNode(size: 16, state: .idle)
                    }
                }

                Text(toLevel.displayName)
                    .font(Typography.Command.caption)
                    .fontWeight(showNewLevel ? .semibold : .regular)
                    .foregroundStyle(showNewLevel ? toLevel.uiColor : Color.secondaryText)
            }
            .position(x: 250, y: 150)

            // Level up text
            if showNewLevel {
                Text("Level Up!")
                    .font(Typography.Command.headline)
                    .foregroundStyle(toLevel.uiColor)
                    .position(x: 150, y: 50)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 300, height: 200)
        .onAppear {
            animate()
        }
    }

    private func animate() {
        if respectsReducedMotion {
            lineWidth = 4
            showPulse = true
            showNewLevel = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onComplete?()
            }
            return
        }

        // Lines thicken
        withAnimation(Theme.Animation.slowFade) {
            lineWidth = 4
        }

        // Pulse at destination
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showPulse = true
        }

        // New level appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(Theme.Animation.settle) {
                showNewLevel = true
            }
        }

        // Callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            onComplete?()
        }
    }
}

// MARK: - MasteryLevel Extension for SwiftUI Colors
extension MasteryLevel {
    var uiColor: Color {
        switch self {
        case .learning: return Color.accentIndigo
        case .reviewing: return .accentIndigo
        case .mastered: return .success
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ConnectionCelebration_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xxl + Theme.Spacing.md) {
                Text("Correct Answer").font(Typography.Command.headline)
                CorrectAnswerCelebration()
                    .frame(width: 200, height: 80)
                    .background(Color.surfaceBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))

                Text("Wrong Answer").font(Typography.Command.headline)
                WrongAnswerFeedback()
                    .background(Color.surfaceBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))

                Text("First Verse Mastered").font(Typography.Command.headline)
                FirstVerseMasteredCelebration()
                    .background(Color.surfaceBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))

                Text("7-Day Streak").font(Typography.Command.headline)
                StreakCelebration(streakCount: 7)
                    .background(Color.surfaceBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))

                Text("Level Up").font(Typography.Command.headline)
                LevelUpCelebration(fromLevel: .learning, toLevel: .reviewing)
                    .background(Color.surfaceBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            }
            .padding()
        }
        .background(Color.appBackground)
        .previewDisplayName("Connection Celebrations")
    }
}
#endif

import SwiftUI

// MARK: - Onboarding Animations
// Lines & connections themed animations for each onboarding page

// MARK: - Welcome Animation
// App logo with golden connection lines radiating outward

struct WelcomeAnimation: View {
    @State private var showLogo = false
    @State private var showConnections = false
    @State private var connectionProgress: CGFloat = 0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    private let rayCount = 8

    var body: some View {
        ZStack {
            // Radiating connection lines
            ForEach(0..<rayCount, id: \.self) { index in
                let angle = (2 * .pi / CGFloat(rayCount)) * CGFloat(index) - .pi / 2
                let endX: CGFloat = 125 + cos(angle) * 90
                let endY: CGFloat = 125 + sin(angle) * 90

                if showConnections {
                    CurvedConnectionLine(
                        start: CGPoint(x: 125, y: 125),
                        end: CGPoint(x: endX, y: endY),
                        color: .warmGold.opacity(AppTheme.Opacity.strong),
                        lineWidth: AppTheme.Border.regular,
                        isActive: true,
                        curvature: 0.05
                    )

                    StatefulConnectionNode(size: 8, state: .active)
                        .position(x: endX, y: endY)
                        .opacity(connectionProgress)
                }
            }

            // Center logo area
            if showLogo {
                ZStack {
                    // Glow
                    Circle()
                        .fill(Color.warmGold.opacity(AppTheme.Opacity.lightMedium))
                        .frame(width: 100, height: 100)
                        .blur(radius: AppTheme.Blur.heavy)

                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.warmGold, .warmGoldDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)

                    // Book icon
                    Image(systemName: "book.fill")
                        .font(Typography.UI.title1)
                        .foregroundStyle(.white)
                }
                .position(x: 125, y: 125)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 250, height: 250)
        .onAppear {
            animate()
        }
    }

    private func animate() {
        if respectsReducedMotion {
            showLogo = true
            showConnections = true
            connectionProgress = 1
            return
        }

        // Logo appears first
        withAnimation(AppTheme.Animation.spring) {
            showLogo = true
        }

        // Connections radiate outward
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(AppTheme.Animation.slow) {
                showConnections = true
            }
            withAnimation(AppTheme.Animation.slow) {
                connectionProgress = 1
            }
        }
    }
}

// MARK: - Read & Study Animation
// Verse nodes connecting to study nodes

struct ReadStudyAnimation: View {
    @State private var showVerseNode = false
    @State private var showStudyNodes = false
    @State private var activeConnections: Set<String> = []

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Connections
            if activeConnections.contains("highlight") {
                CurvedConnectionLine(
                    start: CGPoint(x: 80, y: 125),
                    end: CGPoint(x: 180, y: 60),
                    color: .highlightGold,
                    isActive: true,
                    curvature: 0.15
                )
            }

            if activeConnections.contains("note") {
                CurvedConnectionLine(
                    start: CGPoint(x: 80, y: 125),
                    end: CGPoint(x: 200, y: 125),
                    color: .softRose,
                    isActive: true,
                    curvature: 0
                )
            }

            if activeConnections.contains("crossref") {
                CurvedConnectionLine(
                    start: CGPoint(x: 80, y: 125),
                    end: CGPoint(x: 180, y: 190),
                    color: .accentBlue,
                    isActive: true,
                    curvature: -0.15
                )
            }

            // Verse node (source)
            if showVerseNode {
                VStack(spacing: AppTheme.Spacing.xs) {
                    ZStack {
                        Circle()
                            .fill(Color.warmGold)
                            .frame(width: 40, height: 40)

                        Image(systemName: "text.book.closed")
                            .font(Typography.UI.headline)
                            .foregroundStyle(.white)
                    }
                    Text("Verse")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.secondaryText)
                }
                .position(x: 80, y: 125)
            }

            // Study nodes (destinations)
            if showStudyNodes {
                // Highlight node
                VStack(spacing: AppTheme.Spacing.xxs) {
                    StatefulConnectionNode(size: 16, state: activeConnections.contains("highlight") ? .active : .idle)
                    Text("Highlight")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)
                }
                .position(x: 180, y: 60)

                // Note node
                VStack(spacing: AppTheme.Spacing.xxs) {
                    StatefulConnectionNode(size: 16, state: activeConnections.contains("note") ? .active : .idle)
                    Text("Note")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)
                }
                .position(x: 200, y: 125)

                // Cross-ref node
                VStack(spacing: AppTheme.Spacing.xxs) {
                    StatefulConnectionNode(size: 16, state: activeConnections.contains("crossref") ? .active : .idle)
                    Text("Cross-Ref")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)
                }
                .position(x: 180, y: 190)
            }
        }
        .frame(width: 250, height: 250)
        .onAppear {
            animate()
        }
    }

    private func animate() {
        if respectsReducedMotion {
            showVerseNode = true
            showStudyNodes = true
            activeConnections = ["highlight", "note", "crossref"]
            return
        }

        withAnimation(AppTheme.Animation.spring) {
            showVerseNode = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(AppTheme.Animation.standard) {
                showStudyNodes = true
            }
        }

        // Animate connections one by one
        let connections = ["highlight", "note", "crossref"]
        for (index, conn) in connections.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + Double(index) * 0.3) {
                withAnimation(AppTheme.Animation.standard) {
                    _ = activeConnections.insert(conn)
                }
            }
        }
    }
}

// MARK: - Memorize Animation
// Neural pathway - nodes strengthening connections over time

struct MemorizeAnimation: View {
    @State private var nodeStrengths: [CGFloat] = [0.3, 0.3, 0.3, 0.3, 0.3]
    @State private var showPathways = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Memory pathways
            if showPathways {
                // Horizontal connections
                ForEach(0..<4, id: \.self) { i in
                    ConnectionLine(
                        start: CGPoint(x: 30 + CGFloat(i) * 50, y: 125),
                        end: CGPoint(x: 80 + CGFloat(i) * 50, y: 125),
                        color: .warmGold,
                        lineWidth: AppTheme.Border.regular + nodeStrengths[i] * AppTheme.Border.regular,
                        isActive: nodeStrengths[i] > 0.5
                    )
                }
            }

            // Memory nodes
            ForEach(0..<5, id: \.self) { i in
                let x: CGFloat = 30 + CGFloat(i) * 50
                let strength = nodeStrengths[i]

                ZStack {
                    // Glow based on strength
                    if strength > 0.5 {
                        Circle()
                            .fill(Color.warmGold.opacity(AppTheme.Opacity.medium * strength))
                            .frame(width: 30 * strength, height: 30 * strength)
                            .blur(radius: AppTheme.Blur.light)
                    }

                    Circle()
                        .fill(Color.warmGold.opacity(AppTheme.Opacity.disabled + strength * AppTheme.Opacity.strong))
                        .frame(width: 12 + strength * 8, height: 12 + strength * 8)
                }
                .position(x: x, y: 125)
            }

            // Labels
            HStack {
                Text("New")
                    .font(Typography.UI.caption2)
                Spacer()
                Text("Mastered")
                    .font(Typography.UI.caption2)
            }
            .foregroundStyle(Color.tertiaryText)
            .padding(.horizontal, AppTheme.Spacing.xl)
            .offset(y: 50)
        }
        .frame(width: 250, height: 250)
        .onAppear {
            animate()
        }
    }

    private func animate() {
        if respectsReducedMotion {
            showPathways = true
            nodeStrengths = [0.3, 0.5, 0.7, 0.9, 1.0]
            return
        }

        withAnimation(AppTheme.Animation.standard) {
            showPathways = true
        }

        // Animate nodes strengthening from left to right
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.4) {
                withAnimation(AppTheme.Animation.standard) {
                    nodeStrengths[i] = 0.3 + CGFloat(i) * 0.175
                }
            }
        }
    }
}

// MARK: - Ask AI Animation
// Question node connecting to answer network

struct AskAIAnimation: View {
    @State private var showQuestion = false
    @State private var flowingLines: Set<Int> = []
    @State private var showAnswer = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    private let processingNodeCount = 3

    var body: some View {
        ZStack {
            // Question to processing connections
            ForEach(0..<processingNodeCount, id: \.self) { i in
                let yOffset: CGFloat = CGFloat(i - 1) * 40
                let midY: CGFloat = 125 + yOffset

                if flowingLines.contains(i) {
                    FlowingConnectionLine(
                        start: CGPoint(x: 50, y: 125),
                        end: CGPoint(x: 140, y: midY),
                        color: .warmGold,
                        flowSpeed: 1.5
                    )
                }

                // Processing nodes
                if flowingLines.contains(i) {
                    StatefulConnectionNode(size: 10, state: .pulsing)
                        .position(x: 140, y: midY)
                }
            }

            // Processing to answer connections
            if showAnswer {
                ForEach(0..<processingNodeCount, id: \.self) { i in
                    let yOffset: CGFloat = CGFloat(i - 1) * 40
                    CurvedConnectionLine(
                        start: CGPoint(x: 140, y: 125 + yOffset),
                        end: CGPoint(x: 210, y: 125),
                        color: .warmGold,
                        isActive: true,
                        curvature: CGFloat(i - 1) * 0.1
                    )
                }
            }

            // Question node
            if showQuestion {
                VStack(spacing: AppTheme.Spacing.xs) {
                    ZStack {
                        Circle()
                            .fill(Color.accentBlue)
                            .frame(width: 36, height: 36)

                        Text("?")
                            .font(Typography.UI.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    Text("Question")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)
                }
                .position(x: 50, y: 125)
            }

            // Answer node
            if showAnswer {
                VStack(spacing: AppTheme.Spacing.xs) {
                    ZStack {
                        // Glow
                        Circle()
                            .fill(Color.warmGold.opacity(AppTheme.Opacity.medium))
                            .frame(width: 50, height: 50)
                            .blur(radius: AppTheme.Blur.medium)

                        Circle()
                            .fill(Color.warmGold)
                            .frame(width: 36, height: 36)

                        Image(systemName: "sparkles")
                            .font(Typography.UI.subheadline)
                            .foregroundStyle(.white)
                    }
                    Text("Answer")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)
                }
                .position(x: 210, y: 125)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 250, height: 250)
        .onAppear {
            animate()
        }
    }

    private func animate() {
        if respectsReducedMotion {
            showQuestion = true
            flowingLines = Set(0..<processingNodeCount)
            showAnswer = true
            return
        }

        // Question appears
        withAnimation(AppTheme.Animation.spring) {
            showQuestion = true
        }

        // Lines start flowing
        for i in 0..<processingNodeCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.15) {
                withAnimation(AppTheme.Animation.standard) {
                    _ = flowingLines.insert(i)
                }
            }
        }

        // Answer appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(AppTheme.Animation.spring) {
                showAnswer = true
            }
        }
    }
}

// MARK: - Preview
#Preview("Onboarding Animations") {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.xxxl) {
            Text("Welcome").font(Typography.UI.headline)
            WelcomeAnimation()
                .background(Color.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl))

            Text("Read & Study").font(Typography.UI.headline)
            ReadStudyAnimation()
                .background(Color.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl))

            Text("Memorize").font(Typography.UI.headline)
            MemorizeAnimation()
                .background(Color.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl))

            Text("Ask AI").font(Typography.UI.headline)
            AskAIAnimation()
                .background(Color.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl))
        }
        .padding()
    }
    .background(Color.appBackground)
}

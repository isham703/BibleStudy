import SwiftUI

// MARK: - Connection Line
// An animated line that connects two points with flow animation
// Supports pulse, flow, and dim states

struct ConnectionLine: View {
    let start: CGPoint
    let end: CGPoint
    var color: Color = .warmGold
    var lineWidth: CGFloat = 2
    var isActive: Bool = false
    var flowProgress: CGFloat? = nil // nil = no flow, 0-1 = flow position
    var dashPattern: [CGFloat]? = nil

    @State private var pulseOpacity: CGFloat = 0.4

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        Canvas { context, size in
            let path = Path { p in
                p.move(to: start)
                p.addLine(to: end)
            }

            // Base line (dimmed)
            context.stroke(
                path,
                with: .color(color.opacity(isActive ? pulseOpacity : 0.2)),
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round,
                    dash: dashPattern ?? []
                )
            )

            // Flow indicator (if flowing)
            if let progress = flowProgress, !respectsReducedMotion {
                let flowLength: CGFloat = 0.15
                let flowStart = max(0, progress - flowLength)
                let flowEnd = min(1, progress)

                let trimmedPath = path.trimmedPath(from: flowStart, to: flowEnd)
                context.stroke(
                    trimmedPath,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: lineWidth * 1.5, lineCap: .round)
                )

                // Glow effect on flow head
                let headPoint = pointOnLine(from: start, to: end, at: progress)
                let glowRect = CGRect(
                    x: headPoint.x - lineWidth * 2,
                    y: headPoint.y - lineWidth * 2,
                    width: lineWidth * 4,
                    height: lineWidth * 4
                )
                context.fill(
                    Circle().path(in: glowRect),
                    with: .color(color.opacity(AppTheme.Opacity.strong))
                )
            }
        }
        .onAppear {
            if isActive && !respectsReducedMotion {
                startPulseAnimation()
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue && !respectsReducedMotion {
                startPulseAnimation()
            } else {
                pulseOpacity = 0.4
            }
        }
    }

    private func pointOnLine(from start: CGPoint, to end: CGPoint, at progress: CGFloat) -> CGPoint {
        CGPoint(
            x: start.x + (end.x - start.x) * progress,
            y: start.y + (end.y - start.y) * progress
        )
    }

    private func startPulseAnimation() {
        withAnimation(AppTheme.Animation.slow.repeatForever(autoreverses: true)) {
            pulseOpacity = 0.8
        }
    }
}

// MARK: - Curved Connection Line
struct CurvedConnectionLine: View {
    let start: CGPoint
    let end: CGPoint
    var color: Color = .warmGold
    var lineWidth: CGFloat = 2
    var isActive: Bool = false
    var curvature: CGFloat = 0.3 // 0 = straight, 1 = very curved

    @State private var drawProgress: CGFloat = 0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    private var controlPoint: CGPoint {
        let midX = (start.x + end.x) / 2
        let midY = (start.y + end.y) / 2
        let dx = end.x - start.x
        let dy = end.y - start.y
        let perpX = -dy * curvature
        let perpY = dx * curvature

        return CGPoint(x: midX + perpX, y: midY + perpY)
    }

    var body: some View {
        Canvas { context, size in
            let path = Path { p in
                p.move(to: start)
                p.addQuadCurve(to: end, control: controlPoint)
            }

            // Draw based on progress
            let trimmedPath = respectsReducedMotion
                ? path
                : path.trimmedPath(from: 0, to: drawProgress)

            context.stroke(
                trimmedPath,
                with: .color(color.opacity(isActive ? 0.8 : 0.3)),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
        }
        .onAppear {
            if respectsReducedMotion {
                drawProgress = 1.0
            } else {
                withAnimation(AppTheme.Animation.slow) {
                    drawProgress = 1.0
                }
            }
        }
    }
}

// MARK: - Animated Flow Line
// A line with continuous flow animation
struct FlowingConnectionLine: View {
    let start: CGPoint
    let end: CGPoint
    var color: Color = .warmGold
    var lineWidth: CGFloat = 2
    var flowSpeed: Double = 2.0 // seconds for full traversal

    @State private var flowProgress: CGFloat = 0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ConnectionLine(
            start: start,
            end: end,
            color: color,
            lineWidth: lineWidth,
            isActive: true,
            flowProgress: respectsReducedMotion ? nil : flowProgress
        )
        .onAppear {
            guard !respectsReducedMotion else { return }
            startFlowAnimation()
        }
    }

    private func startFlowAnimation() {
        flowProgress = 0
        withAnimation(AppTheme.Animation.slow.repeatForever(autoreverses: false)) {
            flowProgress = 1.15 // Overshoot slightly so flow exits cleanly
        }
    }
}

// MARK: - Line State
enum LineState {
    case idle
    case active
    case flowing
    case success
    case dimmed

    var color: Color {
        switch self {
        case .idle: return .warmGold.opacity(AppTheme.Opacity.medium)
        case .active: return .warmGold
        case .flowing: return .warmGold
        case .success: return .highlightGreen
        case .dimmed: return .tertiaryText.opacity(AppTheme.Opacity.medium)
        }
    }
}

// MARK: - Preview
#Preview("Connection Lines") {
    VStack(spacing: AppTheme.Spacing.xxxl + AppTheme.Spacing.md) {
        // Static lines
        ZStack {
            ConnectionLine(
                start: CGPoint(x: 50, y: 50),
                end: CGPoint(x: 200, y: 50),
                isActive: false
            )
            Text("Idle").offset(x: 0, y: 20)
        }
        .frame(width: 250, height: 100)

        ZStack {
            ConnectionLine(
                start: CGPoint(x: 50, y: 50),
                end: CGPoint(x: 200, y: 50),
                isActive: true
            )
            Text("Active (pulsing)").offset(x: 0, y: 20)
        }
        .frame(width: 250, height: 100)

        // Flowing line
        ZStack {
            FlowingConnectionLine(
                start: CGPoint(x: 50, y: 50),
                end: CGPoint(x: 200, y: 50)
            )
            Text("Flowing").offset(x: 0, y: 20)
        }
        .frame(width: 250, height: 100)

        // Curved line
        ZStack {
            CurvedConnectionLine(
                start: CGPoint(x: 50, y: 80),
                end: CGPoint(x: 200, y: 20),
                isActive: true,
                curvature: 0.3
            )
            Text("Curved").offset(x: 0, y: 60)
        }
        .frame(width: 250, height: 100)
    }
    .padding()
    .background(Color.appBackground)
}

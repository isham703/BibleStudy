import SwiftUI
import Combine

// MARK: - Golden Gradient
// Animated gradient using the app's brand colors

struct GoldenGradient: View {
    var startColor: Color = .burnishedGold
    var endColor: Color = .illuminatedGold
    var animationDuration: Double = 3.0

    @State private var animateGradient = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        LinearGradient(
            colors: [startColor, endColor, startColor],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .onAppear {
            guard !respectsReducedMotion else { return }
            withAnimation(
                AppTheme.Animation.slow
                .repeatForever(autoreverses: true)
            ) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Shimmer Effect
// Subtle shimmer animation for loading states

struct ShimmerEffect: View {
    var baseColor: Color = .divineGold.opacity(AppTheme.Opacity.medium)
    var highlightColor: Color = .divineGold.opacity(AppTheme.Opacity.strong)
    var duration: Double = 1.5

    @State private var shimmerOffset: CGFloat = -1

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            ZStack {
                // Base color
                Rectangle()
                    .fill(baseColor)

                // Shimmer highlight
                if !respectsReducedMotion {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    highlightColor,
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: width * 0.5)
                        .offset(x: shimmerOffset * width)
                }
            }
        }
        .onAppear {
            guard !respectsReducedMotion else { return }
            withAnimation(
                AppTheme.Animation.slow
                .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 1.5
            }
        }
    }
}

// MARK: - Glow Effect Modifier
struct GlowModifier: ViewModifier {
    var color: Color = .divineGold
    var radius: CGFloat = 10
    var isActive: Bool = true

    @State private var glowOpacity: Double = 0.5

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isActive ? glowOpacity : 0), radius: radius)
            .shadow(color: color.opacity(isActive ? glowOpacity * 0.5 : 0), radius: radius * 2)
            .onAppear {
                guard isActive && !respectsReducedMotion else { return }
                withAnimation(
                    AppTheme.Animation.slow
                    .repeatForever(autoreverses: true)
                ) {
                    glowOpacity = 0.8
                }
            }
    }
}

extension View {
    func goldenGlow(radius: CGFloat = 10, isActive: Bool = true) -> some View {
        modifier(GlowModifier(color: .divineGold, radius: radius, isActive: isActive))
    }

    func roseGlow(radius: CGFloat = 10, isActive: Bool = true) -> some View {
        modifier(GlowModifier(color: .softRose, radius: radius, isActive: isActive))
    }
}

// MARK: - Radial Pulse Gradient
// Expanding radial gradient for emphasis

struct RadialPulseGradient: View {
    var centerColor: Color = .divineGold
    var edgeColor: Color = .clear
    var minRadius: CGFloat = 0.2
    var maxRadius: CGFloat = 0.8
    var duration: Double = 2.0

    @State private var radius: CGFloat = 0.2

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        RadialGradient(
            colors: [centerColor.opacity(AppTheme.Opacity.strong), centerColor.opacity(AppTheme.Opacity.lightMedium), edgeColor],
            center: .center,
            startRadius: 0,
            endRadius: respectsReducedMotion ? maxRadius * 100 : radius * 100
        )
        .onAppear {
            guard !respectsReducedMotion else { return }
            radius = minRadius
            withAnimation(
                AppTheme.Animation.slow
                .repeatForever(autoreverses: true)
            ) {
                radius = maxRadius
            }
        }
    }
}

// MARK: - Connection Trail
// Fading trail effect for flowing connections

struct ConnectionTrail: View {
    let points: [CGPoint]
    var color: Color = .divineGold
    var trailLength: Int = 5

    @State private var headIndex: Int = 0

    // Use Timer.publish for proper SwiftUI lifecycle management
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        Canvas { context, size in
            guard points.count > 1 else { return }

            let displayIndex = respectsReducedMotion ? points.count - 1 : headIndex

            for i in max(0, displayIndex - trailLength)...displayIndex {
                guard i < points.count - 1 else { continue }

                let opacity = 1.0 - Double(displayIndex - i) / Double(trailLength + 1)
                let lineWidth = 2.0 * opacity

                let path = Path { p in
                    p.move(to: points[i])
                    p.addLine(to: points[i + 1])
                }

                context.stroke(
                    path,
                    with: .color(color.opacity(opacity)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            }

            // Draw head node
            if displayIndex < points.count {
                let headRect = CGRect(
                    x: points[displayIndex].x - 4,
                    y: points[displayIndex].y - 4,
                    width: 8,
                    height: 8
                )
                context.fill(Circle().path(in: headRect), with: .color(color))
            }
        }
        .onReceive(timer) { _ in
            guard !respectsReducedMotion else { return }
            withAnimation(AppTheme.Animation.quick) {
                headIndex += 1
            }
            if headIndex >= points.count {
                headIndex = 0
            }
        }
    }
}

// MARK: - Preview
#Preview("Gradient Effects") {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.xxxl) {
            Text("Golden Gradient").font(Typography.UI.headline)
            GoldenGradient()
                .frame(height: 60)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))

            Text("Shimmer Effect").font(Typography.UI.headline)
            ShimmerEffect()
                .frame(height: 40)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))

            Text("Golden Glow").font(Typography.UI.headline)
            Circle()
                .fill(Color.divineGold)
                .frame(width: 40, height: 40)
                .goldenGlow(radius: 15)

            Text("Radial Pulse").font(Typography.UI.headline)
            RadialPulseGradient()
                .frame(width: 150, height: 150)

            Text("Connection Trail").font(Typography.UI.headline)
            ConnectionTrail(points: [
                CGPoint(x: 50, y: 50),
                CGPoint(x: 100, y: 80),
                CGPoint(x: 150, y: 40),
                CGPoint(x: 200, y: 70),
                CGPoint(x: 250, y: 50),
            ])
            .frame(width: 300, height: 120)
        }
        .padding()
    }
    .background(Color.appBackground)
}

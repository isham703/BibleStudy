import SwiftUI

// MARK: - Atmospheric Effects
// Ambient visual effects for the illuminated manuscript theme
// Includes: golden dust particles, divine light rays, illuminated border

// MARK: - Golden Dust Particle System
// Floating golden motes with twinkle effect

struct GoldenDustView: View {
    enum Intensity {
        case subtle      // 5-10 particles (older devices)
        case ambient     // 15-25 particles (standard)
        case celebration // 40-60 particles (special moments)

        var particleCount: Int {
            switch self {
            case .subtle: return Int.random(in: 5...10)
            case .ambient: return Int.random(in: 15...25)
            case .celebration: return Int.random(in: 40...60)
            }
        }
    }

    let intensity: Intensity
    let color: Color

    @State private var particles: [Particle] = []
    @State private var isAnimating = false

    init(
        intensity: Intensity = .ambient,
        color: Color = Color.divineGold
    ) {
        self.intensity = intensity
        self.color = color
    }

    var body: some View {
        GeometryReader { geometry in
            SwiftUI.TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { _ in
                Canvas { context, size in
                    for particle in particles {
                        let opacity = particle.opacity * (isAnimating ? 1 : 0)
                        context.opacity = opacity

                        let rect = CGRect(
                            x: particle.x * size.width - particle.size / 2,
                            y: particle.y * size.height - particle.size / 2,
                            width: particle.size,
                            height: particle.size
                        )

                        context.fill(
                            Circle().path(in: rect),
                            with: .color(color)
                        )
                    }
                }
            }
            .onAppear {
                guard !AppTheme.Animation.isReduceMotionEnabled else { return }
                initializeParticles(in: geometry.size)
                startAnimation()
            }
            .onChange(of: geometry.size) { _, newSize in
                initializeParticles(in: newSize)
            }
        }
        .allowsHitTesting(false)
    }

    private func initializeParticles(in size: CGSize) {
        particles = (0..<intensity.particleCount).map { _ in
            Particle(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.2...0.6),
                speed: Double.random(in: 0.0005...0.002),
                phase: Double.random(in: 0...(.pi * 2))
            )
        }
    }

    private func startAnimation() {
        withAnimation(AppTheme.Animation.reverent) {
            isAnimating = true
        }

        // Continuous particle movement
        Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            updateParticles()
        }
    }

    private func updateParticles() {
        for i in particles.indices {
            // Gentle upward drift with horizontal sway
            particles[i].y -= particles[i].speed
            particles[i].x += sin(particles[i].phase) * 0.0003
            particles[i].phase += 0.02

            // Twinkle effect
            particles[i].opacity = 0.3 + 0.3 * sin(particles[i].phase * 2)

            // Reset particles that drift off screen
            if particles[i].y < -0.1 {
                particles[i].y = 1.1
                particles[i].x = CGFloat.random(in: 0...1)
            }
        }
    }
}

private struct Particle {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: Double
    var phase: Double
}

// MARK: - Divine Light Rays
// Slow-rotating rays from configurable origin

struct DivineLightRays: View {
    let rayCount: Int
    let color: Color
    let origin: UnitPoint
    let rotationSpeed: Double

    @State private var rotation: Angle = .zero

    init(
        rayCount: Int = 8,
        color: Color = Color.divineGold.opacity(AppTheme.Opacity.subtle),
        origin: UnitPoint = .top,
        rotationSpeed: Double = 60 // seconds per rotation
    ) {
        self.rayCount = rayCount
        self.color = color
        self.origin = origin
        self.rotationSpeed = rotationSpeed
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<rayCount, id: \.self) { index in
                    ray(index: index, size: geometry.size)
                }
            }
            .rotationEffect(rotation, anchor: origin)
        }
        .onAppear {
            guard !AppTheme.Animation.isReduceMotionEnabled else { return }
            withAnimation(
                .linear(duration: rotationSpeed)
                .repeatForever(autoreverses: false)
            ) {
                rotation = .degrees(360)
            }
        }
        .allowsHitTesting(false)
    }

    private func ray(index: Int, size: CGSize) -> some View {
        let angle = Double(index) * (360.0 / Double(rayCount))
        let maxDimension = max(size.width, size.height) * 1.5

        return Rectangle()
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 40, height: maxDimension)
            .rotationEffect(.degrees(angle), anchor: .top)
            .position(x: size.width * origin.x, y: size.height * origin.y)
    }
}

// MARK: - Illuminated Border
// Animated gold shimmer around content

struct IlluminatedBorderModifier: ViewModifier {
    let color: Color
    let lineWidth: CGFloat
    let cornerRadius: CGFloat

    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        AngularGradient(
                            colors: [
                                color.opacity(AppTheme.Opacity.medium),
                                color,
                                color.opacity(AppTheme.Opacity.medium),
                                color.opacity(AppTheme.Opacity.subtle),
                                color.opacity(AppTheme.Opacity.medium)
                            ],
                            center: .center,
                            startAngle: .degrees(phase),
                            endAngle: .degrees(phase + 360)
                        ),
                        lineWidth: lineWidth
                    )
            )
            .onAppear {
                guard !AppTheme.Animation.isReduceMotionEnabled else { return }
                withAnimation(AppTheme.Animation.meditativePulse) {
                    phase = 360
                }
            }
    }
}

extension View {
    /// Add animated illuminated border
    func illuminatedBorder(
        color: Color = Color.divineGold,
        lineWidth: CGFloat = 2,
        cornerRadius: CGFloat = AppTheme.CornerRadius.card
    ) -> some View {
        modifier(IlluminatedBorderModifier(
            color: color,
            lineWidth: lineWidth,
            cornerRadius: cornerRadius
        ))
    }
}

// MARK: - Ambient Glow Background
// Pulsing warm glow effect

struct AmbientGlowBackground: View {
    let color: Color
    let intensity: Double

    @State private var isPulsing = false

    init(
        color: Color = Color.divineGold,
        intensity: Double = 0.15
    ) {
        self.color = color
        self.intensity = intensity
    }

    var body: some View {
        RadialGradient(
            colors: [
                color.opacity(isPulsing ? intensity : intensity * 0.6),
                color.opacity(isPulsing ? intensity * 0.5 : intensity * 0.2),
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 300
        )
        .onAppear {
            guard !AppTheme.Animation.isReduceMotionEnabled else { return }
            withAnimation(AppTheme.Animation.pulse) {
                isPulsing = true
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Celebration Burst
// Radial particle burst for achievements

struct CelebrationBurst: View {
    let color: Color
    let particleCount: Int

    @State private var particles: [BurstParticle] = []
    @State private var isAnimating = false

    init(
        color: Color = Color.divineGold,
        particleCount: Int = 24
    ) {
        self.color = color
        self.particleCount = particleCount
    }

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                ForEach(particles.indices, id: \.self) { index in
                    Circle()
                        .fill(color)
                        .frame(width: particles[index].size, height: particles[index].size)
                        .offset(
                            x: isAnimating ? particles[index].endOffset.width : 0,
                            y: isAnimating ? particles[index].endOffset.height : 0
                        )
                        .opacity(isAnimating ? 0 : particles[index].opacity)
                        .position(center)
                }
            }
        }
        .onAppear {
            initializeParticles()
            triggerBurst()
        }
        .allowsHitTesting(false)
    }

    private func initializeParticles() {
        var newParticles: [BurstParticle] = []
        newParticles.reserveCapacity(particleCount)

        for index in 0..<particleCount {
            let angleInDegrees: Double = Double(index) * (360.0 / Double(particleCount))
            let angleInRadians: Double = angleInDegrees * .pi / 180.0
            let distance: CGFloat = CGFloat.random(in: 80...200)

            let offsetWidth: CGFloat = cos(angleInRadians) * distance
            let offsetHeight: CGFloat = sin(angleInRadians) * distance

            let particle = BurstParticle(
                size: CGFloat.random(in: 4...12),
                opacity: Double.random(in: 0.6...1.0),
                endOffset: CGSize(width: offsetWidth, height: offsetHeight)
            )
            newParticles.append(particle)
        }

        particles = newParticles
    }

    private func triggerBurst() {
        guard !AppTheme.Animation.isReduceMotionEnabled else { return }

        withAnimation(AppTheme.Animation.unfurl) {
            isAnimating = true
        }
    }
}

private struct BurstParticle {
    let size: CGFloat
    let opacity: Double
    let endOffset: CGSize
}

// MARK: - Vignette Effect
// Subtle darkening at edges for focus

struct VignetteModifier: ViewModifier {
    let color: Color
    let intensity: Double

    func body(content: Content) -> some View {
        content
            .overlay(
                RadialGradient(
                    colors: [
                        Color.clear,
                        color.opacity(intensity)
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: 400
                )
                .allowsHitTesting(false)
            )
    }
}

extension View {
    /// Add vignette darkening at edges
    func vignette(
        color: Color = .black,
        intensity: Double = 0.3
    ) -> some View {
        modifier(VignetteModifier(color: color, intensity: intensity))
    }
}

// MARK: - Atmospheric Container
// Combines multiple atmospheric effects

struct AtmosphericContainer<Content: View>: View {
    let showDust: Bool
    let showRays: Bool
    let showGlow: Bool
    let content: () -> Content

    init(
        showDust: Bool = true,
        showRays: Bool = false,
        showGlow: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.showDust = showDust
        self.showRays = showRays
        self.showGlow = showGlow
        self.content = content
    }

    var body: some View {
        ZStack {
            // Background glow
            if showGlow {
                AmbientGlowBackground()
            }

            // Divine light rays
            if showRays {
                DivineLightRays()
            }

            // Main content
            content()

            // Golden dust overlay
            if showDust {
                GoldenDustView(intensity: .subtle)
            }
        }
    }
}

// MARK: - Preview

#Preview("Golden Dust") {
    ZStack {
        Color(.systemBackground)
        GoldenDustView(intensity: .ambient)
    }
    .ignoresSafeArea()
}

#Preview("Divine Light Rays") {
    ZStack {
        Color.black
        DivineLightRays(
            rayCount: 12,
            color: Color.divineGold.opacity(AppTheme.Opacity.light)
        )
    }
    .ignoresSafeArea()
}

#Preview("Illuminated Border") {
    VStack {
        Text("Selected Verse")
            .font(Typography.Scripture.body())
            .padding()
            .background(Color(.systemBackground))
            .illuminatedBorder()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Celebration Burst") {
    ZStack {
        Color(.systemBackground)
        CelebrationBurst()
    }
}

#Preview("Atmospheric Container") {
    AtmosphericContainer(showDust: true, showRays: true, showGlow: true) {
        Text("In the beginning...")
            .font(Typography.Scripture.body())
            .padding()
    }
    .frame(height: 400)
    .background(Color.freshVellum)
}

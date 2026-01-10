import SwiftUI
import Combine

// MARK: - Floating Sanctuary Particles
/// GPU-accelerated particle system using Canvas for smooth performance.
/// Renders "Golden Dust Motes" with subtle glow halos and natural drift.
/// Respects accessibility settings (Reduce Motion).

struct FloatingSanctuaryParticles: View {
    // MARK: - Configuration
    private let particleCount = 20

    // MARK: - State
    @State private var particles: [GoldenParticle] = []
    @State private var timerCancellable: AnyCancellable?

    // Animation tick counter to trigger redraws
    @State private var animationTick: UInt64 = 0

    // Reference time for animation calculations
    @State private var startTime: Date?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Canvas { context, size in
            // animationTick dependency ensures Canvas redraws on timer
            _ = animationTick
            let currentTime = startTime.map { Date().timeIntervalSince($0) } ?? 0
            for particle in particles {
                drawParticle(particle, in: context, size: size, time: currentTime)
            }
        }
        .drawingGroup() // GPU-accelerated rendering
        .onAppear {
            initializeParticles()
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }

    // MARK: - Animation Control

    private func startAnimation() {
        guard !reduceMotion else { return }
        startTime = Date()

        timerCancellable = Timer.publish(every: 1/30, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                // Increment tick to trigger Canvas redraw
                animationTick &+= 1
            }
    }

    private func stopAnimation() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    // MARK: - Initialization

    private func initializeParticles() {
        particles = (0..<particleCount).map { _ in
            GoldenParticle()
        }
    }

    // MARK: - Rendering

    private func drawParticle(_ particle: GoldenParticle, in context: GraphicsContext, size: CGSize, time: Double) {
        // Calculate animated position with sine wave drift
        let xOffset = sin(time * particle.driftSpeed + particle.phase) * particle.driftAmplitude
        let yOffset = cos(time * particle.driftSpeed * 0.7 + particle.phase) * particle.driftAmplitude * 0.5

        let x = (particle.baseX + xOffset) * size.width
        let y = (particle.baseY + yOffset) * size.height

        // Animate brightness with pulsing effect
        let brightnessPhase = sin(time * particle.pulseSpeed + particle.phase)
        let animatedBrightness = particle.baseBrightness * (0.7 + 0.3 * brightnessPhase)

        let center = CGPoint(x: x, y: y)

        // Draw outer glow halo (larger, more transparent)
        let haloRadius = particle.size * 3
        let haloRect = CGRect(
            x: x - haloRadius,
            y: y - haloRadius,
            width: haloRadius * 2,
            height: haloRadius * 2
        )

        let haloGradient = Gradient(colors: [
            Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(animatedBrightness * 0.25),
            Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(animatedBrightness * 0.1),
            Color.clear
        ])

        context.fill(
            Circle().path(in: haloRect),
            with: .radialGradient(
                haloGradient,
                center: center,
                startRadius: 0,
                endRadius: haloRadius
            )
        )

        // Draw core mote (smaller, brighter)
        let coreRect = CGRect(
            x: x - particle.size,
            y: y - particle.size,
            width: particle.size * 2,
            height: particle.size * 2
        )

        let coreGradient = Gradient(colors: [
            Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(animatedBrightness * 0.8),
            Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(animatedBrightness * 0.4),
            Color.clear
        ])

        context.fill(
            Circle().path(in: coreRect),
            with: .radialGradient(
                coreGradient,
                center: center,
                startRadius: 0,
                endRadius: particle.size
            )
        )
    }
}

// MARK: - Golden Particle Model

private struct GoldenParticle {
    // Base position (0-1 normalized)
    let baseX: CGFloat
    let baseY: CGFloat

    // Appearance
    let size: CGFloat         // 2-5pt core radius
    let baseBrightness: Double  // 0.4-0.8

    // Animation parameters
    let driftAmplitude: CGFloat  // How far particles drift (0.01-0.03)
    let driftSpeed: Double       // Speed of drift oscillation (0.3-0.8)
    let pulseSpeed: Double       // Speed of brightness pulse (0.2-0.5)
    let phase: Double            // Phase offset for variation

    init() {
        baseX = CGFloat.random(in: 0...1)
        baseY = CGFloat.random(in: 0...1)
        size = CGFloat.random(in: 2...5)
        baseBrightness = Double.random(in: 0.4...0.8)
        driftAmplitude = CGFloat.random(in: 0.01...0.03)
        driftSpeed = Double.random(in: 0.3...0.8)
        pulseSpeed = Double.random(in: 0.2...0.5)
        phase = Double.random(in: 0...(2 * .pi))
    }
}

// MARK: - Preview

#Preview("Particles on Dark") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        FloatingSanctuaryParticles()
    }
}

#Preview("Particles with Content") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        FloatingSanctuaryParticles()

        VStack {
            Text("Settings")
                .font(.largeTitle)
                .foregroundStyle(.white)
        }
    }
}

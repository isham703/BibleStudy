import SwiftUI

// MARK: - Vespers Background
// Sunset gradient with stars beginning to appear and warm glow at horizon fading
// Animation direction: Downward fades - dimming, transitioning

struct VespersBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var horizonGlow: Double = 0.8
    @State private var starsVisible: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sunset gradient
                Color.vespersSunsetGradient
                    .ignoresSafeArea()

                // Horizon glow (fading sun below horizon)
                horizonGlowEffect(geometry: geometry)
                    .opacity(horizonGlow)

                // Setting sun (partially below horizon)
                SunOrb(position: .setting, size: 80)
                    .position(x: geometry.size.width * 0.7, y: geometry.size.height * 0.95)
                    .opacity(0.7)

                // Emerging stars (fewer than compline)
                if !reduceMotion {
                    VespersStarfield()
                        .opacity(starsVisible ? 1 : 0)
                }

                // Twilight particles
                if !reduceMotion {
                    TwilightParticles()
                        .opacity(0.5)
                }
            }
        }
        .onAppear {
            // Stars fade in as "eyes adjust"
            withAnimation(.easeIn(duration: 2).delay(0.5)) {
                starsVisible = true
            }

            if !reduceMotion {
                // Horizon glow pulses gently
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    horizonGlow = 0.6
                }
            }
        }
    }

    // MARK: - Horizon Glow Effect

    private func horizonGlowEffect(geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            // Warm glow at bottom
            let glowCenter = CGPoint(x: size.width * 0.6, y: size.height * 1.1)

            context.fill(
                Path(ellipseIn: CGRect(
                    x: glowCenter.x - 300,
                    y: glowCenter.y - 200,
                    width: 600,
                    height: 400
                )),
                with: .radialGradient(
                    Gradient(colors: [
                        Color.vespersOrange.opacity(0.4),
                        Color.vespersAmber.opacity(0.2),
                        Color.clear
                    ]),
                    center: glowCenter,
                    startRadius: 50,
                    endRadius: 350
                )
            )
        }
    }
}

// MARK: - Vespers Starfield
// Fewer stars than compline - just beginning to appear

struct VespersStarfield: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct Star: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var baseOpacity: Double
        var twinkleDelay: Double
    }

    @State private var stars: [Star] = []
    @State private var time: Double = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/20, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let currentTime = timeline.date.timeIntervalSinceReferenceDate

                for star in stars {
                    // Gentle twinkling
                    let twinkle = sin(currentTime * 0.5 + star.twinkleDelay) * 0.3 + 0.7
                    let opacity = star.baseOpacity * twinkle

                    let rect = CGRect(
                        x: star.x - star.size / 2,
                        y: star.y - star.size / 2,
                        width: star.size,
                        height: star.size
                    )

                    // Star glow
                    if star.size > 2 {
                        context.fill(
                            Path(ellipseIn: rect.insetBy(dx: -2, dy: -2)),
                            with: .color(Color.vespersText.opacity(opacity * 0.3))
                        )
                    }

                    // Star core
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(Color.vespersText.opacity(opacity))
                    )
                }
            }
        }
        .onAppear {
            // Only 8-12 stars visible in vespers (twilight)
            stars = (0..<Int.random(in: 8...12)).map { _ in
                Star(
                    x: .random(in: 30...370),
                    y: .random(in: 40...300), // Upper portion of screen
                    size: .random(in: 1.5...3.5),
                    baseOpacity: .random(in: 0.3...0.7),
                    twinkleDelay: .random(in: 0...(.pi * 2))
                )
            }
        }
    }
}

// MARK: - Twilight Particles
// Subtle purple-tinted particles floating downward

struct TwilightParticles: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var phase: Double
    }

    @State private var particles: [Particle] = []

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                guard !reduceMotion else { return }

                let time = timeline.date.timeIntervalSinceReferenceDate

                for particle in particles {
                    // Slow downward drift
                    let yOffset = (time * 3 + particle.phase * 50).truncatingRemainder(dividingBy: size.height)
                    let xOffset = sin(time * 0.3 + particle.phase) * 10

                    var finalY = particle.y + yOffset
                    if finalY > size.height {
                        finalY = finalY.truncatingRemainder(dividingBy: size.height)
                    }

                    let rect = CGRect(
                        x: particle.x + xOffset,
                        y: finalY,
                        width: particle.size,
                        height: particle.size
                    )

                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(Color.vespersPurple.opacity(particle.opacity))
                    )
                }
            }
        }
        .onAppear {
            particles = (0..<15).map { _ in
                Particle(
                    x: .random(in: 0...400),
                    y: .random(in: 0...800),
                    size: .random(in: 3...8),
                    opacity: .random(in: 0.1...0.25),
                    phase: .random(in: 0...(.pi * 2))
                )
            }
        }
    }
}

// MARK: - Preview

#Preview("Vespers Background") {
    VespersBackground()
}

#Preview("Vespers Starfield Only") {
    ZStack {
        Color.vespersSky
        VespersStarfield()
    }
}

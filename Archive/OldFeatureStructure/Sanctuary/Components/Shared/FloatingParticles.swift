import SwiftUI

// MARK: - Floating Particles
// Physics-based particle system for Sacred Threshold variant
// Particles float gently and respond to room color changes

struct FloatingParticles: View {
    let roomColor: Color
    let particleCount: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particles: [Particle] = []

    init(roomColor: Color, particleCount: Int = 20) {
        self.roomColor = roomColor
        self.particleCount = particleCount
    }

    var body: some View {
        GeometryReader { geometry in
            if reduceMotion {
                // Static particles for reduced motion
                Canvas { context, size in
                    for particle in particles {
                        let rect = CGRect(
                            x: particle.x,
                            y: particle.y,
                            width: particle.size,
                            height: particle.size
                        )
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(roomColor.opacity(particle.opacity))
                        )
                    }
                }
            } else {
                // Animated particles
                SwiftUI.TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let time = timeline.date.timeIntervalSinceReferenceDate

                        for particle in particles {
                            // Gentle floating motion
                            let yOffset = sin(time * 0.5 + particle.phase) * 15
                            let xOffset = cos(time * 0.3 + particle.phase) * 8

                            let rect = CGRect(
                                x: particle.x + xOffset,
                                y: particle.y + yOffset,
                                width: particle.size,
                                height: particle.size
                            )

                            // Main particle
                            context.fill(
                                Path(ellipseIn: rect),
                                with: .color(roomColor.opacity(particle.opacity))
                            )

                            // Glow for larger particles
                            if particle.size > 8 {
                                let glowRect = rect.insetBy(dx: -4, dy: -4)
                                context.fill(
                                    Path(ellipseIn: glowRect),
                                    with: .color(roomColor.opacity(particle.opacity * 0.3))
                                )
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            generateParticles()
        }
        .allowsHitTesting(false)
    }

    private func generateParticles() {
        particles = (0..<particleCount).map { index in
            let seed = Double(index) * 17.3
            return Particle(
                x: CGFloat((seed * 19.7).truncatingRemainder(dividingBy: 1)) * 350 + 20,
                y: CGFloat((seed * 23.9).truncatingRemainder(dividingBy: 1)) * 300 + 50,
                size: CGFloat((seed * 7.3).truncatingRemainder(dividingBy: 1)) * 9 + 3,
                opacity: (seed * 11.1).truncatingRemainder(dividingBy: 1) * 0.3 + 0.1,
                phase: (seed * 31.7).truncatingRemainder(dividingBy: 1) * .pi * 2
            )
        }
    }
}

// MARK: - Particle Model

private struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var phase: Double
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        FloatingParticles(roomColor: .thresholdPurple)
    }
}

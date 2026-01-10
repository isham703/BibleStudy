import SwiftUI

// MARK: - Aurora Particle

/// A lightweight model for a glowing particle used in the animated background.
struct AuroraParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var hue: Double
    var speed: Double
    var angle: Double
}

// MARK: - Breathing Aurora Background

/// Draws a dynamic aurora-like background using Canvas and TimelineView.
/// Optimized for performance with reduce motion support.
/// Used by breathing exercise features.
struct BreathingAuroraBackground: View {
    let isActive: Bool
    let baseHue: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particles: [AuroraParticle] = []
    @State private var screenSize: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            if reduceMotion {
                // Static gradient for reduced motion
                staticBackground
            } else {
                SwiftUI.TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                    Canvas { context, size in
                        let time = timeline.date.timeIntervalSinceReferenceDate

                        // Draw flowing aurora waves
                        drawAuroraWaves(context: context, size: size, time: time)

                        // Draw floating particles
                        drawParticles(context: context, size: size, time: time)
                    }
                }
                .onAppear {
                    screenSize = geometry.size
                    initializeParticles()
                }
                .onChange(of: geometry.size) { _, newSize in
                    screenSize = newSize
                    initializeParticles()
                }
            }
        }
    }

    // MARK: - Static Background (Reduce Motion)

    private var staticBackground: some View {
        LinearGradient(
            colors: [
                Color(hue: baseHue, saturation: 0.4, brightness: 0.15),
                Color(hue: (baseHue + 0.1).truncatingRemainder(dividingBy: 1.0), saturation: 0.5, brightness: 0.2),
                Color(hue: (baseHue + 0.15).truncatingRemainder(dividingBy: 1.0), saturation: 0.4, brightness: 0.15)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Aurora Waves

    private func drawAuroraWaves(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        for i in 0..<5 {
            let waveY = size.height * (0.3 + Double(i) * 0.15)
            let amplitude = isActive ? 40.0 : 20.0
            let frequency = 0.01 + Double(i) * 0.005
            let speed = 0.5 + Double(i) * 0.2

            var path = Path()
            path.move(to: CGPoint(x: 0, y: waveY))

            for x in stride(from: 0, to: size.width, by: 2) {
                let y = waveY + sin(x * frequency + time * speed) * amplitude
                path.addLine(to: CGPoint(x: x, y: y))
            }

            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height))
            path.closeSubpath()

            let hue = (baseHue + Double(i) * 0.05).truncatingRemainder(dividingBy: 1.0)
            let color = Color(hue: hue, saturation: 0.6, brightness: 0.3)

            context.fill(path, with: .color(color.opacity(isActive ? 0.3 : 0.15)))
        }
    }

    // MARK: - Particles

    private func drawParticles(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        for particle in particles {
            let adjustedY = particle.position.y - CGFloat(time.truncatingRemainder(dividingBy: 20) * particle.speed * 10)
            let finalY = adjustedY < 0 ? adjustedY + size.height : adjustedY.truncatingRemainder(dividingBy: size.height)

            let wobbleX = sin(time * 2 + particle.angle) * 20
            let position = CGPoint(x: particle.position.x + wobbleX, y: finalY)

            let rect = CGRect(
                x: position.x - particle.size / 2,
                y: position.y - particle.size / 2,
                width: particle.size,
                height: particle.size
            )

            let particleColor = Color(hue: particle.hue, saturation: 0.7, brightness: 0.8)

            context.drawLayer { ctx in
                ctx.addFilter(.blur(radius: particle.size / 2))
                ctx.fill(
                    Circle().path(in: rect),
                    with: .color(particleColor.opacity(particle.opacity * (isActive ? 1 : 0.5)))
                )
            }
        }
    }

    // MARK: - Particle Initialization

    private func initializeParticles() {
        let width = max(screenSize.width, 100)
        let height = max(screenSize.height, 100)

        particles = (0..<25).map { _ in
            AuroraParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...width),
                    y: CGFloat.random(in: 0...height)
                ),
                size: CGFloat.random(in: 4...12),
                opacity: Double.random(in: 0.2...0.6),
                hue: baseHue + Double.random(in: -0.1...0.1),
                speed: Double.random(in: 1...3),
                angle: Double.random(in: 0...(.pi * 2))
            )
        }
    }
}

// MARK: - Aurora Background Presets

extension BreathingAuroraBackground {
    /// Night-themed aurora for Compline (indigo base)
    static func compline(isActive: Bool) -> BreathingAuroraBackground {
        BreathingAuroraBackground(isActive: isActive, baseHue: 0.7)
    }

    /// Calm mint-toned aurora
    static func calm(isActive: Bool) -> BreathingAuroraBackground {
        BreathingAuroraBackground(isActive: isActive, baseHue: 0.45)
    }

    /// Cyan-toned aurora for focus
    static func focus(isActive: Bool) -> BreathingAuroraBackground {
        BreathingAuroraBackground(isActive: isActive, baseHue: 0.5)
    }
}

// MARK: - Hue Helpers

extension BreathingAuroraBackground {
    /// Maps a BreathingPattern color to a hue value.
    static func hue(for pattern: BreathingPattern) -> Double {
        switch pattern.color {
        case .mint: return 0.45
        case .cyan: return 0.5
        case .indigo: return 0.7
        default: return 0.5
        }
    }

    /// Creates an aurora background for a breathing pattern.
    static func forPattern(_ pattern: BreathingPattern, isActive: Bool) -> BreathingAuroraBackground {
        BreathingAuroraBackground(isActive: isActive, baseHue: hue(for: pattern))
    }
}

// MARK: - Preview

#Preview("Aurora - Active") {
    BreathingAuroraBackground(isActive: true, baseHue: 0.7)
        .ignoresSafeArea()
}

#Preview("Aurora - Inactive") {
    BreathingAuroraBackground(isActive: false, baseHue: 0.45)
        .ignoresSafeArea()
}

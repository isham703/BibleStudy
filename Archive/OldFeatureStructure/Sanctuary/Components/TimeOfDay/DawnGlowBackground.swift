import SwiftUI

// MARK: - Dawn Glow Background
// Ethereal Aurora aesthetic - cool lavender at top transitioning to warm coral at horizon
// The magical moment when night gives way to day
// Animation direction: Upward, expanding - gentle awakening

struct DawnGlowBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glowPulse: CGFloat = 0
    @State private var mistDrift: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient - ethereal aurora
                Color.dawnSkyGradient
                    .ignoresSafeArea()

                // Horizon glow - warm radiance where sun meets sky
                horizonGlow(geometry: geometry)

                // Soft light rays emanating from horizon
                if !reduceMotion {
                    softRays(geometry: geometry)
                }

                // Sun orb at horizon
                SunOrb(position: .rising, size: 90)
                    .position(x: geometry.size.width / 2, y: geometry.size.height - 60)

                // Delicate mist wisps
                mistWisps(geometry: geometry)
                    .offset(x: reduceMotion ? 0 : mistDrift)

                // Floating aurora particles
                if !reduceMotion {
                    AuroraParticles()
                        .opacity(0.5)
                }
            }
        }
        .onAppear {
            guard !reduceMotion else { return }

            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                glowPulse = 1
            }
            withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                mistDrift = 30
            }
        }
    }

    // MARK: - Horizon Glow

    private func horizonGlow(geometry: GeometryProxy) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color.dawnSunrise.opacity(0.6),
                        Color.dawnApricot.opacity(0.4),
                        Color.dawnPeach.opacity(0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: geometry.size.width * 0.8
                )
            )
            .frame(width: geometry.size.width * 1.5, height: 300)
            .position(x: geometry.size.width / 2, y: geometry.size.height)
            .scaleEffect(1 + glowPulse * 0.1)
    }

    // MARK: - Soft Light Rays

    private func softRays(geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height - 40

            // Create soft, wide rays that fade upward
            for i in 0..<8 {
                let baseAngle = -90.0 // Point upward
                let spread = 80.0 // Total spread angle
                let angle = (baseAngle - spread/2 + Double(i) * (spread / 7.0)) * .pi / 180.0
                let rayLength = size.height * 0.9

                var path = Path()
                path.move(to: CGPoint(x: centerX, y: centerY))

                let endX = centerX + cos(angle) * rayLength
                let endY = centerY + sin(angle) * rayLength

                path.addLine(to: CGPoint(x: endX, y: endY))

                // Alternate between peachy and rosy rays
                let rayColor = i % 2 == 0 ? Color.dawnApricot : Color.dawnRosePink

                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [
                            rayColor.opacity(0.25),
                            rayColor.opacity(0.1),
                            Color.clear
                        ]),
                        startPoint: CGPoint(x: centerX, y: centerY),
                        endPoint: CGPoint(x: endX, y: endY)
                    ),
                    style: StrokeStyle(lineWidth: 60, lineCap: .round)
                )
            }
        }
        .blendMode(.softLight)
    }

    // MARK: - Mist Wisps

    private func mistWisps(geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            // Horizontal wisps of morning mist
            let wisps: [(y: CGFloat, width: CGFloat, opacity: Double)] = [
                (0.45, 0.8, 0.15),
                (0.55, 0.6, 0.12),
                (0.65, 0.9, 0.18),
                (0.75, 0.5, 0.1),
            ]

            for wisp in wisps {
                let rect = CGRect(
                    x: (size.width - size.width * wisp.width) / 2,
                    y: size.height * wisp.y,
                    width: size.width * wisp.width,
                    height: 40
                )

                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(Color.white.opacity(wisp.opacity))
                )
            }
        }
        .blur(radius: 40)
    }
}

// MARK: - Sun Orb Component

struct SunOrb: View {
    enum Position {
        case rising   // Dawn - at horizon
        case setting  // Vespers - below horizon

        var verticalOffset: CGFloat {
            switch self {
            case .rising: return 0
            case .setting: return 20
            }
        }
    }

    let position: Position
    var size: CGFloat = 80

    @State private var breathe: CGFloat = 0
    @State private var innerGlow: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Outermost glow - very soft
            Circle()
                .fill(
                    RadialGradient(
                        colors: outerGlowColors,
                        center: .center,
                        startRadius: size * 0.4,
                        endRadius: size * 2.5
                    )
                )
                .frame(width: size * 4, height: size * 4)
                .scaleEffect(1 + breathe * 0.08)

            // Middle glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: middleGlowColors,
                        center: .center,
                        startRadius: size * 0.3,
                        endRadius: size * 1.2
                    )
                )
                .frame(width: size * 2, height: size * 2)
                .scaleEffect(1 + innerGlow * 0.05)

            // Main sun disc - softer edge
            Circle()
                .fill(
                    RadialGradient(
                        colors: sunDiscColors,
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size, height: size)
                .blur(radius: 2)

            // Bright core
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.4, height: size * 0.4)
                .blur(radius: 8)
        }
        .offset(y: position.verticalOffset)
        .onAppear {
            guard !reduceMotion else { return }

            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                breathe = 1
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                innerGlow = 1
            }
        }
    }

    private var sunDiscColors: [Color] {
        switch position {
        case .rising:
            return [Color.white, Color.dawnSunrise.opacity(0.9), Color.dawnApricot]
        case .setting:
            return [Color.white.opacity(0.9), .vespersAmber, .vespersOrange]
        }
    }

    private var middleGlowColors: [Color] {
        switch position {
        case .rising:
            return [Color.dawnSunrise.opacity(0.5), Color.dawnApricot.opacity(0.2), Color.clear]
        case .setting:
            return [Color.vespersAmber.opacity(0.5), Color.vespersOrange.opacity(0.2), Color.clear]
        }
    }

    private var outerGlowColors: [Color] {
        switch position {
        case .rising:
            return [Color.dawnApricot.opacity(0.3), Color.dawnPeach.opacity(0.15), Color.clear]
        case .setting:
            return [Color.vespersOrange.opacity(0.3), Color.vespersAmber.opacity(0.15), Color.clear]
        }
    }
}

// MARK: - Aurora Particles
// Delicate floating particles in cool-to-warm tones

struct AuroraParticles: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var phase: Double
        var colorIndex: Int // 0 = lavender, 1 = rose, 2 = peach
    }

    @State private var particles: [Particle] = []

    var body: some View {
        SwiftUI.TimelineView(.animation(minimumInterval: 1/30, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                guard !reduceMotion else { return }

                let time = timeline.date.timeIntervalSinceReferenceDate

                for particle in particles {
                    // Gentle upward float
                    let yOffset = -abs(sin(time * 0.2 + particle.phase)) * 20
                    let xOffset = sin(time * 0.15 + particle.phase) * 12

                    // Color based on position (cooler at top, warmer at bottom)
                    let particleColor: Color = {
                        switch particle.colorIndex {
                        case 0: return Color.dawnPeriwinkle
                        case 1: return Color.dawnRosePink
                        default: return Color.dawnApricot
                        }
                    }()

                    let rect = CGRect(
                        x: particle.x + xOffset,
                        y: particle.y + yOffset,
                        width: particle.size,
                        height: particle.size
                    )

                    // Soft glow around particle
                    let glowRect = rect.insetBy(dx: -particle.size * 0.5, dy: -particle.size * 0.5)
                    context.fill(
                        Path(ellipseIn: glowRect),
                        with: .color(particleColor.opacity(particle.opacity * 0.3))
                    )

                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(particleColor.opacity(particle.opacity))
                    )
                }
            }
        }
        .onAppear {
            particles = (0..<20).map { i in
                let yPosition = CGFloat.random(in: 0...700)
                // Color index based on vertical position
                let colorIndex = yPosition < 250 ? 0 : (yPosition < 450 ? 1 : 2)

                return Particle(
                    x: .random(in: 20...380),
                    y: yPosition,
                    size: .random(in: 3...8),
                    opacity: .random(in: 0.2...0.5),
                    phase: .random(in: 0...(.pi * 2)),
                    colorIndex: colorIndex
                )
            }
        }
    }
}

// MARK: - Dawn Mist Particles (Legacy compatibility)

struct DawnMistParticles: View {
    var body: some View {
        AuroraParticles()
    }
}

// MARK: - Preview

#Preview("Dawn Glow Background") {
    DawnGlowBackground()
}

#Preview("Sun Orb - Rising") {
    ZStack {
        Color.dawnSkyGradient
        SunOrb(position: .rising, size: 90)
    }
}

#Preview("Sun Orb - Setting") {
    ZStack {
        Color.vespersSunsetGradient
        SunOrb(position: .setting, size: 80)
    }
}

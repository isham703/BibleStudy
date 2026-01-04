import SwiftUI

// MARK: - Dust Motes
// Warm-colored particles that drift in slanted light beams
// Used primarily for Afternoon Sanctuary
// Movement: Slow, settling, horizontal drift

struct DustMotes: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var moteColor: Color = .afternoonGold
    var moteCount: Int = 30
    var lightAngle: Angle = .degrees(-30) // Light coming from upper right

    struct Mote: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var phase: Double
        var speed: Double
    }

    @State private var motes: [Mote] = []

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                guard !reduceMotion else { return }

                let time = timeline.date.timeIntervalSinceReferenceDate

                for mote in motes {
                    // Slow diagonal drift following light angle
                    let angleRad = lightAngle.radians
                    let driftX = cos(angleRad) * time * mote.speed * 5
                    let driftY = sin(angleRad) * time * mote.speed * 3

                    // Gentle floating motion perpendicular to drift
                    let floatX = sin(time * 0.5 + mote.phase) * 8
                    let floatY = cos(time * 0.3 + mote.phase) * 12

                    // Wrap around screen
                    var finalX = (mote.x + driftX + floatX).truncatingRemainder(dividingBy: size.width)
                    var finalY = (mote.y + driftY + floatY).truncatingRemainder(dividingBy: size.height)

                    if finalX < 0 { finalX += size.width }
                    if finalY < 0 { finalY += size.height }

                    // Sparkle effect - occasional brightness boost
                    let sparkle = sin(time * 2 + mote.phase * 3) > 0.8 ? 1.5 : 1.0

                    let rect = CGRect(
                        x: finalX - mote.size / 2,
                        y: finalY - mote.size / 2,
                        width: mote.size,
                        height: mote.size
                    )

                    // Main mote
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(moteColor.opacity(mote.opacity * sparkle))
                    )

                    // Subtle glow for larger motes
                    if mote.size > 4 {
                        let glowRect = rect.insetBy(dx: -2, dy: -2)
                        context.fill(
                            Path(ellipseIn: glowRect),
                            with: .color(moteColor.opacity(mote.opacity * 0.3))
                        )
                    }
                }
            }
        }
        .onAppear {
            motes = (0..<moteCount).map { _ in
                Mote(
                    x: .random(in: 0...400),
                    y: .random(in: 0...800),
                    size: .random(in: 2...6),
                    opacity: .random(in: 0.2...0.6),
                    phase: .random(in: 0...(.pi * 2)),
                    speed: .random(in: 0.5...1.5)
                )
            }
        }
    }
}

// MARK: - Light Beam Overlay
// Creates slanted light beams for afternoon window effect

struct LightBeams: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shimmer: CGFloat = 0

    var beamCount: Int = 3
    var beamColor: Color = .afternoonGold
    var angle: Angle = .degrees(-25)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<beamCount, id: \.self) { index in
                    lightBeam(
                        index: index,
                        geometry: geometry
                    )
                }
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                shimmer = 1
            }
        }
    }

    private func lightBeam(index: Int, geometry: GeometryProxy) -> some View {
        let width = geometry.size.width
        let height = geometry.size.height
        let beamWidth: CGFloat = 80 + CGFloat(index) * 30
        let spacing = width / CGFloat(beamCount + 1)
        let xOffset = spacing * CGFloat(index + 1)

        return Path { path in
            // Start from top-right, angle down
            let startX = xOffset + 100
            let startY: CGFloat = -50
            let endX = xOffset - 150
            let endY = height + 50

            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: startX + beamWidth, y: startY))
            path.addLine(to: CGPoint(x: endX + beamWidth * 0.7, y: endY))
            path.addLine(to: CGPoint(x: endX, y: endY))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [
                    beamColor.opacity(0.15 + shimmer * 0.05),
                    beamColor.opacity(0.08),
                    beamColor.opacity(0.03)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        )
        .rotationEffect(angle, anchor: .center)
    }
}

// MARK: - Preview

#Preview("Dust Motes - Afternoon") {
    ZStack {
        Color.afternoonParchment
        DustMotes(moteColor: .afternoonGold)
    }
}

#Preview("Dust Motes with Light Beams") {
    ZStack {
        Color.afternoonParchment
        LightBeams()
        DustMotes(moteColor: .afternoonGold)
    }
}

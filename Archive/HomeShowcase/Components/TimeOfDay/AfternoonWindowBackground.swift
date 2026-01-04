import SwiftUI

// MARK: - Afternoon Window Background
// Contemplative Study aesthetic - quiet library with afternoon light
// Soft cream base with elegant diagonal light beams
// Animation direction: Settling, gentle drift - relaxed, meditative

struct AfternoonWindowBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var beamShimmer: CGFloat = 0
    @State private var particleDrift: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Soft cream base
                Color.afternoonBaseGradient
                    .ignoresSafeArea()

                // Subtle paper texture
                AfternoonPaperTexture()
                    .opacity(0.015)

                // Elegant diagonal light beams
                diagonalLightBeams(geometry: geometry)
                    .opacity(0.6 + beamShimmer * 0.15)

                // Soft ambient glow in upper right (implied window)
                ambientGlow(geometry: geometry)

                // Delicate floating dust motes
                if !reduceMotion {
                    AfternoonDustMotes()
                        .opacity(0.5)
                        .offset(x: particleDrift)
                }
            }
        }
        .onAppear {
            guard !reduceMotion else { return }

            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                beamShimmer = 1
            }
            withAnimation(.easeInOut(duration: 25).repeatForever(autoreverses: true)) {
                particleDrift = 20
            }
        }
    }

    // MARK: - Diagonal Light Beams

    private func diagonalLightBeams(geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            // Create 3 elegant diagonal light beams from upper right
            let beams: [(startX: CGFloat, width: CGFloat, opacity: Double)] = [
                (0.7, 120, 0.25),  // Rightmost beam
                (0.45, 90, 0.18),  // Middle beam
                (0.2, 70, 0.12),   // Leftmost beam (faintest)
            ]

            for beam in beams {
                var path = Path()

                // Start from upper right, diagonal down to lower left
                let startX = size.width * beam.startX + 100
                let startY: CGFloat = -50
                let endX = startX - size.height * 0.4
                let endY = size.height + 50

                // Create a parallelogram for the light beam
                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: startX + beam.width, y: startY))
                path.addLine(to: CGPoint(x: endX + beam.width * 0.6, y: endY))
                path.addLine(to: CGPoint(x: endX, y: endY))
                path.closeSubpath()

                // Gradient fill for soft beam
                context.fill(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.afternoonBeam.opacity(beam.opacity),
                            Color.afternoonHoney.opacity(beam.opacity * 0.5),
                            Color.afternoonBeam.opacity(beam.opacity * 0.3)
                        ]),
                        startPoint: CGPoint(x: startX, y: startY),
                        endPoint: CGPoint(x: endX, y: endY)
                    )
                )
            }
        }
        .blur(radius: 30)
    }

    // MARK: - Ambient Glow

    private func ambientGlow(geometry: GeometryProxy) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color.afternoonBeam.opacity(0.2),
                        Color.afternoonHoney.opacity(0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 300
                )
            )
            .frame(width: 500, height: 400)
            .position(x: geometry.size.width - 100, y: 100)
            .blur(radius: 50)
    }
}

// MARK: - Afternoon Paper Texture

private struct AfternoonPaperTexture: View {
    var body: some View {
        Canvas { context, size in
            // Very subtle noise texture
            for _ in 0..<Int(size.width * size.height * 0.0003) {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let gray = CGFloat.random(in: 0.4...0.6)

                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(Color(white: gray, opacity: 0.15))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Afternoon Dust Motes
// Warm-colored particles drifting in light beams

struct AfternoonDustMotes: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct Mote: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var phase: Double
        var inBeam: Bool // Brighter if in light beam
    }

    @State private var motes: [Mote] = []

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                guard !reduceMotion else { return }

                let time = timeline.date.timeIntervalSinceReferenceDate

                for mote in motes {
                    // Slow diagonal drift following light angle
                    let driftX = sin(time * 0.1 + mote.phase) * 15 - time * 2
                    let driftY = cos(time * 0.08 + mote.phase) * 10 + time * 1.5

                    // Wrap around
                    var finalX = (mote.x + driftX).truncatingRemainder(dividingBy: size.width)
                    var finalY = (mote.y + driftY).truncatingRemainder(dividingBy: size.height)
                    if finalX < 0 { finalX += size.width }
                    if finalY < 0 { finalY += size.height }

                    // Sparkle in light
                    let sparkle = mote.inBeam && sin(time * 1.5 + mote.phase) > 0.7 ? 1.4 : 1.0

                    let moteColor = mote.inBeam ? Color.afternoonHoney : Color.afternoonMocha

                    let rect = CGRect(
                        x: finalX - mote.size / 2,
                        y: finalY - mote.size / 2,
                        width: mote.size,
                        height: mote.size
                    )

                    // Soft glow for larger motes
                    if mote.size > 4 {
                        let glowRect = rect.insetBy(dx: -2, dy: -2)
                        context.fill(
                            Path(ellipseIn: glowRect),
                            with: .color(moteColor.opacity(mote.opacity * 0.25 * sparkle))
                        )
                    }

                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(moteColor.opacity(mote.opacity * sparkle))
                    )
                }
            }
        }
        .onAppear {
            motes = (0..<20).map { _ in
                let x = CGFloat.random(in: 0...400)
                // Motes in light beams (right side of screen) are brighter
                let inBeam = x > 200

                return Mote(
                    x: x,
                    y: .random(in: 0...800),
                    size: .random(in: 2...5),
                    opacity: .random(in: 0.15...0.4),
                    phase: .random(in: 0...(.pi * 2)),
                    inBeam: inBeam
                )
            }
        }
    }
}

// MARK: - Preview

#Preview("Afternoon Window Background") {
    AfternoonWindowBackground()
}

#Preview("Afternoon with Content") {
    ZStack {
        AfternoonWindowBackground()

        VStack {
            Spacer()
            Text("Be still, and know that I am God.")
                .font(.custom("CormorantGaramond-Italic", size: 26))
                .foregroundStyle(Color.afternoonEspresso)
                .multilineTextAlignment(.center)
                .padding(40)
            Spacer()
        }
    }
}

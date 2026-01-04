import SwiftUI

// MARK: - Meridian Background
// The Illuminated Scriptorium - golden morning light through library windows
// Warm parchment base with golden light rays and floating illumination motes
// Animation direction: Horizontal, precise - crisp, intentional

struct MeridianBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var beamShimmer: CGFloat = 0
    @State private var motesDrift: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Warm parchment base
                Color.meridianBackgroundGradient
                    .ignoresSafeArea()

                // Subtle parchment texture
                MeridianParchmentTexture()
                    .opacity(0.02)

                // Golden light rays from upper left (morning sun)
                goldenLightRays(geometry: geometry)
                    .opacity(0.7 + beamShimmer * 0.15)

                // Warm ambient glow in upper left corner
                ambientSunGlow(geometry: geometry)

                // Floating golden motes in the light
                if !reduceMotion {
                    MeridianGoldenMotes()
                        .opacity(0.6)
                        .offset(x: motesDrift * 0.5)
                }

                // Subtle gilded border frame
                gildedFrame(geometry: geometry)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }

            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                beamShimmer = 1
            }
            withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                motesDrift = 30
            }
        }
    }

    // MARK: - Golden Light Rays

    private func goldenLightRays(geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            // Create 4 elegant diagonal light beams from upper left
            let beams: [(startY: CGFloat, width: CGFloat, opacity: Double)] = [
                (0.1, 180, 0.22),   // Top beam
                (0.25, 140, 0.18),  // Upper-mid beam
                (0.4, 100, 0.14),   // Mid beam
                (0.55, 70, 0.10),   // Lower beam (faintest)
            ]

            for beam in beams {
                var path = Path()

                // Start from upper left, diagonal down to lower right
                let startX: CGFloat = -50
                let startY = size.height * beam.startY
                let endX = size.width + 100
                let endY = startY + size.height * 0.5

                // Create a parallelogram for the light beam
                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: startX, y: startY + beam.width))
                path.addLine(to: CGPoint(x: endX, y: endY + beam.width * 0.7))
                path.addLine(to: CGPoint(x: endX, y: endY))
                path.closeSubpath()

                // Gradient fill for soft beam
                context.fill(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.meridianBeam.opacity(beam.opacity),
                            Color.meridianGlow.opacity(beam.opacity * 0.6),
                            Color.meridianBeam.opacity(beam.opacity * 0.3)
                        ]),
                        startPoint: CGPoint(x: startX, y: startY),
                        endPoint: CGPoint(x: endX, y: endY)
                    )
                )
            }
        }
        .blur(radius: 40)
    }

    // MARK: - Ambient Sun Glow

    private func ambientSunGlow(geometry: GeometryProxy) -> some View {
        ZStack {
            // Main glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.meridianBeam.opacity(0.35),
                            Color.meridianGlow.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 350
                    )
                )
                .frame(width: 600, height: 500)
                .position(x: -50, y: 50)
                .blur(radius: 60)

            // Inner bright core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.meridianBeam.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 120
                    )
                )
                .frame(width: 200, height: 200)
                .position(x: 30, y: 80)
                .blur(radius: 30)
        }
    }

    // MARK: - Gilded Frame

    private func gildedFrame(geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            let margin: CGFloat = 20
            let cornerRadius: CGFloat = 8

            // Draw subtle gilded corner accents
            let cornerLength: CGFloat = 40

            // Top-left corner
            var topLeft = Path()
            topLeft.move(to: CGPoint(x: margin, y: margin + cornerLength))
            topLeft.addLine(to: CGPoint(x: margin, y: margin + cornerRadius))
            topLeft.addQuadCurve(
                to: CGPoint(x: margin + cornerRadius, y: margin),
                control: CGPoint(x: margin, y: margin)
            )
            topLeft.addLine(to: CGPoint(x: margin + cornerLength, y: margin))

            context.stroke(
                topLeft,
                with: .color(Color.meridianGilded.opacity(0.25)),
                lineWidth: 1.5
            )

            // Top-right corner
            var topRight = Path()
            topRight.move(to: CGPoint(x: size.width - margin - cornerLength, y: margin))
            topRight.addLine(to: CGPoint(x: size.width - margin - cornerRadius, y: margin))
            topRight.addQuadCurve(
                to: CGPoint(x: size.width - margin, y: margin + cornerRadius),
                control: CGPoint(x: size.width - margin, y: margin)
            )
            topRight.addLine(to: CGPoint(x: size.width - margin, y: margin + cornerLength))

            context.stroke(
                topRight,
                with: .color(Color.meridianGilded.opacity(0.25)),
                lineWidth: 1.5
            )

            // Bottom-left corner
            var bottomLeft = Path()
            bottomLeft.move(to: CGPoint(x: margin, y: size.height - margin - cornerLength))
            bottomLeft.addLine(to: CGPoint(x: margin, y: size.height - margin - cornerRadius))
            bottomLeft.addQuadCurve(
                to: CGPoint(x: margin + cornerRadius, y: size.height - margin),
                control: CGPoint(x: margin, y: size.height - margin)
            )
            bottomLeft.addLine(to: CGPoint(x: margin + cornerLength, y: size.height - margin))

            context.stroke(
                bottomLeft,
                with: .color(Color.meridianGilded.opacity(0.2)),
                lineWidth: 1.5
            )

            // Bottom-right corner
            var bottomRight = Path()
            bottomRight.move(to: CGPoint(x: size.width - margin - cornerLength, y: size.height - margin))
            bottomRight.addLine(to: CGPoint(x: size.width - margin - cornerRadius, y: size.height - margin))
            bottomRight.addQuadCurve(
                to: CGPoint(x: size.width - margin, y: size.height - margin - cornerRadius),
                control: CGPoint(x: size.width - margin, y: size.height - margin)
            )
            bottomRight.addLine(to: CGPoint(x: size.width - margin, y: size.height - margin - cornerLength))

            context.stroke(
                bottomRight,
                with: .color(Color.meridianGilded.opacity(0.2)),
                lineWidth: 1.5
            )
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Meridian Parchment Texture

private struct MeridianParchmentTexture: View {
    var body: some View {
        Canvas { context, size in
            // Very subtle noise texture like aged paper
            for _ in 0..<Int(size.width * size.height * 0.0004) {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let warmth = CGFloat.random(in: 0.35...0.55)

                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                    with: .color(Color(red: warmth + 0.1, green: warmth, blue: warmth - 0.05, opacity: 0.2))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Meridian Golden Motes
// Warm golden particles floating in the light beams

struct MeridianGoldenMotes: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct Mote: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var phase: Double
        var inBeam: Bool  // Brighter if in light beam
    }

    @State private var motes: [Mote] = []

    var body: some View {
        SwiftUI.TimelineView(.animation(minimumInterval: 1/30, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                guard !reduceMotion else { return }

                let time = timeline.date.timeIntervalSinceReferenceDate

                for mote in motes {
                    // Slow drift following light angle (diagonal)
                    let driftX = sin(time * 0.08 + mote.phase) * 12 + time * 1.5
                    let driftY = cos(time * 0.06 + mote.phase) * 8 + time * 0.8

                    // Wrap around
                    var finalX = (mote.x + driftX).truncatingRemainder(dividingBy: size.width)
                    var finalY = (mote.y + driftY).truncatingRemainder(dividingBy: size.height)
                    if finalX < 0 { finalX += size.width }
                    if finalY < 0 { finalY += size.height }

                    // Sparkle effect in light beams
                    let sparkle = mote.inBeam && sin(time * 2.0 + mote.phase) > 0.6 ? 1.5 : 1.0

                    let moteColor = mote.inBeam ? Color.meridianGlow : Color.meridianIllumination

                    let rect = CGRect(
                        x: finalX - mote.size / 2,
                        y: finalY - mote.size / 2,
                        width: mote.size,
                        height: mote.size
                    )

                    // Soft glow for larger motes
                    if mote.size > 4 {
                        let glowRect = rect.insetBy(dx: -3, dy: -3)
                        context.fill(
                            Path(ellipseIn: glowRect),
                            with: .color(moteColor.opacity(mote.opacity * 0.3 * sparkle))
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
            motes = (0..<25).map { _ in
                let x = CGFloat.random(in: 0...400)
                let y = CGFloat.random(in: 0...800)
                // Motes in upper-left quadrant (where light beams are) are brighter
                let inBeam = x < 250 && y < 400

                return Mote(
                    x: x,
                    y: y,
                    size: .random(in: 2...6),
                    opacity: .random(in: 0.2...0.5),
                    phase: .random(in: 0...(.pi * 2)),
                    inBeam: inBeam
                )
            }
        }
    }
}

// MARK: - Preview

#Preview("Meridian Background") {
    MeridianBackground()
}

#Preview("Meridian with Content") {
    ZStack {
        MeridianBackground()

        VStack {
            Spacer()
            Text("I am the light of the world.")
                .font(.custom("CormorantGaramond-Italic", size: 26))
                .foregroundStyle(Color.meridianSepia)
                .multilineTextAlignment(.center)
                .padding(40)
            Spacer()
        }
    }
}

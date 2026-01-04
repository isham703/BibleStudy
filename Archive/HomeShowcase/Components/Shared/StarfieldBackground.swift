import SwiftUI

// MARK: - Starfield Background
// Animated starfield for Candlelit Sanctuary variant
// Creates sense of night sky with twinkling stars

struct StarfieldBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let starCount = 25
    private let featureStarCount = 5

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Canvas-based background stars (static positions, less overhead)
                Canvas { context, size in
                    for i in 0..<starCount {
                        // Deterministic random based on index for consistent placement
                        let seed = Double(i) * 13.7
                        let x = CGFloat((seed * 17.3).truncatingRemainder(dividingBy: 1)) * size.width
                        let y = CGFloat((seed * 23.1).truncatingRemainder(dividingBy: 1)) * size.height * 0.6
                        let radius = CGFloat((seed * 7.9).truncatingRemainder(dividingBy: 1)) * 1.5 + 0.5
                        let opacity = (seed * 11.3).truncatingRemainder(dividingBy: 1) * 0.4 + 0.2

                        context.fill(
                            Path(ellipseIn: CGRect(
                                x: x - radius,
                                y: y - radius,
                                width: radius * 2,
                                height: radius * 2
                            )),
                            with: .color(Color.starlight.opacity(opacity))
                        )
                    }
                }

                // Feature stars with twinkling animation
                if !reduceMotion {
                    ForEach(0..<featureStarCount, id: \.self) { index in
                        TwinklingStar(
                            index: index,
                            bounds: geometry.size
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Twinkling Star

private struct TwinklingStar: View {
    let index: Int
    let bounds: CGSize

    @State private var opacity: Double = 0.3
    @State private var scale: Double = 1.0

    private var position: CGPoint {
        // Deterministic positions based on index
        let seed = Double(index) * 31.7
        let x = CGFloat((seed * 19.3).truncatingRemainder(dividingBy: 1)) * (bounds.width - 80) + 40
        let y = CGFloat((seed * 29.1).truncatingRemainder(dividingBy: 1)) * bounds.height * 0.4 + 40
        return CGPoint(x: x, y: y)
    }

    private var animationDuration: Double {
        // Each star has different twinkle speed (3-8 seconds)
        Double(index) * 1.2 + 3.0
    }

    private var animationDelay: Double {
        // Stagger start times
        Double(index) * 0.5
    }

    var body: some View {
        ZStack {
            // Glow layer
            Circle()
                .fill(Color.starlight.opacity(0.3))
                .frame(width: 12, height: 12)
                .blur(radius: 4)

            // Core star
            Circle()
                .fill(Color.starlight)
                .frame(width: 3, height: 3)
        }
        .opacity(opacity)
        .scaleEffect(scale)
        .position(position)
        .onAppear {
            withAnimation(
                .easeInOut(duration: animationDuration)
                .repeatForever(autoreverses: true)
                .delay(animationDelay)
            ) {
                opacity = Double.random(in: 0.5...0.9)
                scale = 1.1
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.nightVoid.ignoresSafeArea()
        StarfieldBackground()
    }
}

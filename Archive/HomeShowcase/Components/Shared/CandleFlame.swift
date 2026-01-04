import SwiftUI

// MARK: - Candle Flame
// Breathing candle flame for Candlelit Sanctuary variant
// Creates meditative ambient effect at bottom of screen

struct CandleFlame: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var breathPhase: CGFloat = 0
    @State private var flickerOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Outer ambient glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.candleAmber.opacity(0.35),
                            Color.candleAmber.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(reduceMotion ? 1.0 : 1 + breathPhase * 0.15)
                .blur(radius: 20)

            // Middle glow ring
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.candleAmber.opacity(0.5),
                            Color.candleAmber.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(reduceMotion ? 1.0 : 1 + breathPhase * 0.1)

            // Inner flame body
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.candleCore,
                            Color.candleAmber,
                            Color.candleAmber.opacity(0.5)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: 14, height: 32)
                .scaleEffect(
                    y: reduceMotion ? 1.0 : 0.9 + breathPhase * 0.2,
                    anchor: .bottom
                )
                .offset(x: reduceMotion ? 0 : flickerOffset)
                .blur(radius: 0.5)

            // Bright flame core
            Ellipse()
                .fill(Color.white.opacity(0.95))
                .frame(width: 5, height: 10)
                .offset(y: 6)
                .blur(radius: 1.5)
                .offset(x: reduceMotion ? 0 : flickerOffset * 0.5)

            // Tiny bright spark at center
            Circle()
                .fill(Color.white)
                .frame(width: 2, height: 2)
                .offset(y: 8)
                .offset(x: reduceMotion ? 0 : flickerOffset * 0.3)
        }
        .onAppear {
            startBreathingAnimation()
            startFlickerAnimation()
        }
    }

    private func startBreathingAnimation() {
        guard !reduceMotion else { return }

        withAnimation(
            .easeInOut(duration: 4)
            .repeatForever(autoreverses: true)
        ) {
            breathPhase = 1
        }
    }

    private func startFlickerAnimation() {
        guard !reduceMotion else { return }

        // Rapid, subtle flicker
        Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.12)) {
                flickerOffset = CGFloat.random(in: -1.5...1.5)
            }
        }
    }
}

// MARK: - Ornamental Divider

struct OrnamentalDivider: View {
    @State private var scaleX: CGFloat = 0

    var body: some View {
        HStack(spacing: 12) {
            // Left ornament
            Image(systemName: "star.fill")
                .font(.system(size: 6))
                .foregroundStyle(Color.vesperGold.opacity(0.6))

            // Center line
            Rectangle()
                .fill(Color.vesperGold)
                .frame(width: 80, height: 1)
                .scaleEffect(x: scaleX, anchor: .center)

            // Right ornament
            Image(systemName: "star.fill")
                .font(.system(size: 6))
                .foregroundStyle(Color.vesperGold.opacity(0.6))
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                scaleX = 1
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.nightVoid.ignoresSafeArea()

        VStack {
            Spacer()

            OrnamentalDivider()
                .padding(.bottom, 40)

            CandleFlame()
                .padding(.bottom, 60)
        }
    }
}

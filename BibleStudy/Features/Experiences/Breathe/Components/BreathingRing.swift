import SwiftUI

// MARK: - Breathing Ring

/// A decorative ring that scales and fades based on the current breathing scale.
/// Uses angular gradient stroke for a subtle rotating sheen effect.
struct BreathingRing: View {
    let scale: CGFloat
    let color: Color
    let ringIndex: Int

    var body: some View {
        Circle()
            .stroke(
                // swiftlint:disable:next hardcoded_gradient_colors
                AngularGradient(
                    colors: [
                        color.opacity(Theme.Opacity.pressed),
                        color.opacity(Theme.Opacity.disabled),
                        color.opacity(Theme.Opacity.selectionBackground),
                        color.opacity(Theme.Opacity.disabled),
                        color.opacity(Theme.Opacity.pressed)
                    ],
                    center: .center
                ),
                // swiftlint:disable:next hardcoded_line_width
                lineWidth: 3 - CGFloat(ringIndex) * 0.5
            )
            // swiftlint:disable:next hardcoded_scale_effect
            .scaleEffect(scale - CGFloat(ringIndex) * 0.1)
            // swiftlint:disable:next hardcoded_opacity
            .opacity(1 - Double(ringIndex) * 0.2)
            // swiftlint:disable:next hardcoded_blur
            .blur(radius: CGFloat(ringIndex) * 2)
    }
}

// MARK: - Multi-Ring Stack

/// A stack of concentric breathing rings for layered visual effect.
struct BreathingRingStack: View {
    let scale: CGFloat
    let color: Color
    let ringCount: Int
    let baseSize: CGFloat

    init(
        scale: CGFloat,
        color: Color,
        ringCount: Int = 4,
        baseSize: CGFloat = 280
    ) {
        self.scale = scale
        self.color = color
        self.ringCount = ringCount
        self.baseSize = baseSize
    }

    var body: some View {
        ZStack {
            ForEach(0..<ringCount, id: \.self) { index in
                BreathingRing(
                    scale: scale,
                    color: color,
                    ringIndex: index
                )
                // swiftlint:disable:next hardcoded_frame_size
                .frame(
                    width: baseSize + CGFloat(index) * 40,
                    height: baseSize + CGFloat(index) * 40
                )
            }
        }
    }
}

// MARK: - Preview

#Preview("Breathing Rings") {
    ZStack {
        Color.black.ignoresSafeArea()

        BreathingRingStack(
            scale: 0.8,
            color: .indigo,
            ringCount: 4,
            baseSize: 200
        )
    }
}

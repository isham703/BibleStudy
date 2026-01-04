import SwiftUI

// MARK: - Sacred Geometry Thinking
// Flower of Life pattern as the AI thinking indicator
// 7 circles arranged in sacred geometry

struct SacredGeometryThinking: View {
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var circleOpacities: [Double] = Array(repeating: 0.4, count: 7)

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    private let circleRadius: CGFloat = 12
    private let patternRadius: CGFloat = 20

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // Flower of Life pattern
            ZStack {
                flowerOfLifePattern
            }
            .frame(width: 60, height: 60)
            .rotationEffect(.degrees(rotationAngle))
            .scaleEffect(pulseScale)

            // Thinking text
            Text("Contemplating...")
                .font(Typography.UI.subheadline)
                .foregroundStyle(ScholarAskPalette.secondaryText)
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Flower of Life Pattern

    private var flowerOfLifePattern: some View {
        ZStack {
            // Center circle
            sacredCircle(at: .zero, index: 0)

            // 6 surrounding circles in hexagonal arrangement
            ForEach(0..<6, id: \.self) { index in
                let angle = Double(index) * 60.0 * .pi / 180.0
                let position = CGPoint(
                    x: patternRadius * cos(angle),
                    y: patternRadius * sin(angle)
                )
                sacredCircle(at: position, index: index + 1)
            }

            // Connection lines (vesica piscis intersections)
            connectionLines
        }
    }

    private func sacredCircle(at position: CGPoint, index: Int) -> some View {
        Circle()
            .stroke(ScholarAskPalette.accent, lineWidth: AppTheme.Border.medium)
            .frame(width: circleRadius * 2, height: circleRadius * 2)
            .opacity(circleOpacities[index])
            .offset(x: position.x, y: position.y)
    }

    private var connectionLines: some View {
        // Subtle connection points at intersections
        ForEach(0..<6, id: \.self) { index in
            let angle = (Double(index) * 60.0 + 30.0) * .pi / 180.0
            let distance = patternRadius * 0.5
            Circle()
                .fill(ScholarAskPalette.accent)
                .frame(width: 3, height: 3)
                .opacity(AppTheme.Opacity.strong)
                .offset(
                    x: distance * cos(angle),
                    y: distance * sin(angle)
                )
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !respectsReducedMotion else {
            circleOpacities = Array(repeating: 0.7, count: 7)
            return
        }

        // Slow rotation (20 seconds per revolution)
        withAnimation(AppTheme.Animation.sacredRotation) {
            rotationAngle = 360
        }

        // Gentle pulse (4 seconds, very subtle)
        withAnimation(AppTheme.Animation.meditativePulse) {
            pulseScale = 1.05
        }

        // Sequential circle illumination
        startCircleWave()
    }

    private func startCircleWave() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            guard !respectsReducedMotion else {
                timer.invalidate()
                return
            }

            withAnimation(AppTheme.Animation.circleWave) {
                // Rotate which circle is brightest
                let brightIndex = Int(Date().timeIntervalSince1970 * 2) % 7
                for i in 0..<7 {
                    circleOpacities[i] = i == brightIndex ? 0.9 : 0.4
                }
            }
        }
    }
}

// MARK: - Compact Sacred Geometry
// Smaller variant for inline use

struct CompactSacredGeometry: View {
    @State private var rotationAngle: Double = 0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Simplified 3-circle pattern (trinity)
            ForEach(0..<3, id: \.self) { index in
                let angle = Double(index) * 120.0 * .pi / 180.0
                Circle()
                    .stroke(ScholarAskPalette.accent, lineWidth: AppTheme.Border.thin)
                    .frame(width: 16, height: 16)
                    .offset(
                        x: 8 * cos(angle),
                        y: 8 * sin(angle)
                    )
            }

            // Center point
            Circle()
                .fill(ScholarAskPalette.accent)
                .frame(width: AppTheme.ComponentSize.dot, height: AppTheme.ComponentSize.dot)
        }
        .frame(width: 32, height: 32)
        .rotationEffect(.degrees(rotationAngle))
        .onAppear {
            guard !respectsReducedMotion else { return }

            withAnimation(AppTheme.Animation.sacredRotationFast) {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - Divine Light Divider
// Decorative separator with sacred geometry motif

struct DivineLightDivider: View {
    @State private var shimmerPosition: CGFloat = 0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            gradientLine
            CompactSacredGeometry()
            gradientLine
        }
        .frame(height: 32)
        .onAppear {
            guard !respectsReducedMotion else { return }

            withAnimation(AppTheme.Animation.shimmer) {
                shimmerPosition = 1
            }
        }
    }

    private var gradientLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        ScholarAskPalette.accent.opacity(0),
                        ScholarAskPalette.accent.opacity(AppTheme.Opacity.medium + shimmerPosition * AppTheme.Opacity.lightMedium),
                        ScholarAskPalette.accent.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: AppTheme.Border.thin)
    }
}

// MARK: - Preview

#Preview("Sacred Geometry Thinking") {
    VStack(spacing: AppTheme.Spacing.xxxl) {
        Text("Full Thinking State")
            .font(Typography.UI.headline)

        SacredGeometryThinking()
            .padding()
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))

        Text("Compact Variant")
            .font(Typography.UI.headline)

        CompactSacredGeometry()
            .padding()
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))

        Text("Divine Light Divider")
            .font(Typography.UI.headline)

        DivineLightDivider()
            .padding(.horizontal)
    }
    .padding()
    .background(Color.appBackground)
}

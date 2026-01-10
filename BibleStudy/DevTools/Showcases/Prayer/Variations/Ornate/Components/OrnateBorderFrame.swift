import SwiftUI

// MARK: - Ornate Border Frame
// Decorative animated border with corner ornaments

struct OrnateBorderFrame: View {
    var breathePhase: CGFloat

    @State private var strokeProgress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let inset: CGFloat = 20
            let cornerRadius: CGFloat = 16

            ZStack {
                // Animated stroke border
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                DeepPrayerColors.goldAccent.opacity(Theme.Opacity.subtle),
                                DeepPrayerColors.roseAccent.opacity(Theme.Opacity.light),
                                DeepPrayerColors.goldAccent.opacity(Theme.Opacity.subtle)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .padding(inset)
                    .opacity(reduceMotion ? 1.0 : 0.6 + breathePhase * 0.4)

                // Glowing inner border
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        DeepPrayerColors.goldAccent.opacity(Theme.Opacity.overlay),
                        lineWidth: 3
                    )
                    .blur(radius: 4)
                    .padding(inset)
                    .opacity(reduceMotion ? 0.5 : breathePhase * 0.5)

                // Corner ornaments
                cornerOrnaments(geometry: geometry, inset: inset)
            }
        }
        .onAppear {
            animateStroke()
        }
    }

    // MARK: - Corner Ornaments

    private func cornerOrnaments(geometry: GeometryProxy, inset: CGFloat) -> some View {
        let offset = inset - 2

        return ZStack {
            // Top-left
            cornerOrnament
                .position(x: offset, y: offset)

            // Top-right
            cornerOrnament
                .position(x: geometry.size.width - offset, y: offset)

            // Bottom-left
            cornerOrnament
                .position(x: offset, y: geometry.size.height - offset)

            // Bottom-right
            cornerOrnament
                .position(x: geometry.size.width - offset, y: geometry.size.height - offset)
        }
    }

    private var cornerOrnament: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(DeepPrayerColors.goldAccent.opacity(Theme.Opacity.lightMedium), lineWidth: 1)
                .frame(width: 12, height: 12)

            // Inner dot
            Circle()
                .fill(DeepPrayerColors.goldAccent.opacity(Theme.Opacity.tertiary))
                .frame(width: 4, height: 4)
        }
    }

    // MARK: - Animation

    private func animateStroke() {
        guard !reduceMotion else {
            strokeProgress = 1
            return
        }
        withAnimation(.easeOut(duration: 1.0)) {
            strokeProgress = 1
        }
    }
}

// MARK: - Ornate Divider

struct OrnateDivider: View {
    var color: Color = DeepPrayerColors.goldAccent

    var body: some View {
        HStack(spacing: 8) {
            line
            diamond
            line
        }
    }

    private var line: some View {
        Rectangle()
            .fill(color.opacity(Theme.Opacity.subtle))
            .frame(width: 40, height: 1)
    }

    private var diamond: some View {
        Image(systemName: "diamond.fill")
            .font(Typography.Icon.xxxs)
            .foregroundStyle(color.opacity(Theme.Opacity.medium))
    }
}

// MARK: - Preview

#Preview("Border Frame") {
    ZStack {
        DeepPrayerColors.sacredNavy.ignoresSafeArea()

        VStack {
            Text("Ornate Border")
                .foregroundStyle(.white)
        }
    }
    .overlay {
        OrnateBorderFrame(breathePhase: 0.5)
    }
}

#Preview("Ornate Divider") {
    ZStack {
        DeepPrayerColors.sacredNavy.ignoresSafeArea()

        VStack(spacing: 20) {
            OrnateDivider()
            OrnateDivider(color: DeepPrayerColors.roseAccent)
        }
    }
}

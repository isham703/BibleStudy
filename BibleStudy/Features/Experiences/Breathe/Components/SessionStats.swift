import SwiftUI

// MARK: - Session Stats

/// Displays live session metrics: cycles completed, elapsed time, and cycle length.
struct SessionStats: View {
    let cyclesCompleted: Int
    let totalTime: TimeInterval
    let pattern: BreathingPattern

    var body: some View {
        HStack(spacing: Theme.Spacing.xxl) {
            StatItem(
                icon: "repeat",
                value: "\(cyclesCompleted)",
                label: "Cycles",
                color: pattern.color
            )

            StatItem(
                icon: "clock.fill",
                value: formatTime(totalTime),
                label: "Duration",
                color: pattern.color
            )

            StatItem(
                icon: "waveform.path",
                value: String(format: "%.0fs", pattern.totalCycle),
                label: "Per Cycle",
                color: pattern.color
            )
        }
        .padding(.vertical, Theme.Spacing.lg)
        .padding(.horizontal, Theme.Spacing.xxl)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                .fill(.ultraThinMaterial.opacity(Theme.Opacity.textSecondary))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                        .stroke(.white.opacity(Theme.Opacity.subtle), lineWidth: Theme.Stroke.hairline)
                )
        )
    }

    /// Formats seconds as m:ss for display.
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Stat Item

/// Compact vertical stat presentation.
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(Typography.Icon.md)
                .foregroundStyle(color)

            Text(value)
                .font(Typography.Command.title2)
                .foregroundStyle(.white)

            Text(label)
                .font(Typography.Command.meta)
                .foregroundStyle(.white.opacity(Theme.Opacity.textSecondary))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Simple Cycle Counter (for Compline)

/// Minimal cycle display for Compline integration.
struct CycleCounter: View {
    let cyclesCompleted: Int
    var targetCycles: Int = 3
    var color: Color = Color("AccentBronze").opacity(0.3)

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(0..<targetCycles, id: \.self) { index in
                Circle()
                    .fill(index < cyclesCompleted ? color : color.opacity(Theme.Opacity.selectionBackground))
                    .frame(width: Theme.Spacing.sm, height: Theme.Spacing.sm)
            }
        }
        .animation(Theme.Animation.settle, value: cyclesCompleted)
    }
}

// MARK: - Preview

#Preview("Session Stats") {
    ZStack {
        Color.black.ignoresSafeArea()

        SessionStats(
            cyclesCompleted: 5,
            totalTime: 185,
            pattern: .sleep
        )
        .padding()
    }
}

#Preview("Cycle Counter") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()

        CycleCounter(cyclesCompleted: 2, targetCycles: 3)
    }
}

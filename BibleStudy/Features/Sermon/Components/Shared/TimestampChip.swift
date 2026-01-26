import SwiftUI

// MARK: - Timestamp Chip
// Tappable chip that displays a timestamp and seeks audio when tapped.
// Used throughout the sermon viewing experience to link content to audio moments.
//
// Usage:
//   TimestampChip(timestamp: 120) { viewModel.seekToTime(120) }
//   TimestampChip(timestamp: 120, isActive: true) { ... }  // Highlighted state
//   TimestampChip(timestamp: 120, showPulseHint: true) { ... }  // First-time hint

struct TimestampChip: View {
    // MARK: - Properties

    let timestamp: TimeInterval
    var isActive: Bool = false
    var showPulseHint: Bool = false
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.0
    @State private var pulseCount = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        Button {
            HapticService.shared.lightTap()
            onTap()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(Typography.Icon.xxs)

                Text(formatTimestamp(timestamp))
                    .font(Typography.Command.meta.monospacedDigit())
            }
            .foregroundStyle(chipColor)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 4)
            .frame(minHeight: Theme.Size.minTapTarget)
            .background(
                Capsule()
                    .fill(chipColor.opacity(Theme.Opacity.subtle))
            )
            .overlay(pulseOverlay)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .opacity(isPressed ? 0.7 : 1.0)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(Theme.Animation.settle, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .onAppear {
            if showPulseHint && !reduceMotion {
                startPulse()
            }
        }
        .accessibilityLabel("Play at \(formatTimestamp(timestamp))")
        .accessibilityHint("Double tap to seek audio")
    }

    // MARK: - Pulse Overlay

    @ViewBuilder
    private var pulseOverlay: some View {
        if showPulseHint && !reduceMotion {
            Capsule()
                .stroke(chipColor, lineWidth: Theme.Stroke.hairline)
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)
        }
    }

    // MARK: - Helpers

    private var chipColor: Color {
        isActive ? Color("AppAccentAction") : Color("FeedbackInfo")
    }

    private func formatTimestamp(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func startPulse() {
        guard pulseCount < 2 else { return }
        pulseScale = 1.0
        pulseOpacity = 0.6

        withAnimation(.easeOut(duration: 0.4)) {
            pulseScale = 1.3
            pulseOpacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            pulseCount += 1
            startPulse()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Theme.Spacing.md) {
        TimestampChip(timestamp: 120, onTap: {})
        TimestampChip(timestamp: 65, isActive: true, onTap: {})
        TimestampChip(timestamp: 2700, showPulseHint: true, onTap: {})
    }
    .padding()
    .background(Color("AppBackground"))
}

import SwiftUI

// MARK: - Timestamp Chip
// Tappable chip that displays a timestamp and seeks audio when tapped.
// Used throughout the sermon viewing experience to link content to audio moments.
//
// Usage:
//   TimestampChip(timestamp: 120) { viewModel.seekToTime(120) }
//   TimestampChip(timestamp: 120, isActive: true) { ... }  // Highlighted state

struct TimestampChip: View {
    // MARK: - Properties

    let timestamp: TimeInterval
    var isActive: Bool = false
    let onTap: () -> Void

    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "waveform")
                .font(Typography.Icon.xxs)

            Text(formatTimestamp(timestamp))
                .font(Typography.Command.meta.monospacedDigit())
        }
        .foregroundStyle(chipColor)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(chipColor.opacity(Theme.Opacity.subtle))
        )
        .opacity(isPressed ? 0.7 : 1.0)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(Theme.Animation.settle, value: isPressed)
        .contentShape(Capsule())
        .onTapGesture {
            HapticService.shared.lightTap()
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityLabel("Jump to \(formatTimestamp(timestamp))")
        .accessibilityHint("Double tap to seek audio")
        .accessibilityAddTraits(.isButton)
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
}

// MARK: - Preview

#Preview {
    VStack(spacing: Theme.Spacing.md) {
        TimestampChip(timestamp: 120, onTap: {})
        TimestampChip(timestamp: 65, isActive: true, onTap: {})
        TimestampChip(timestamp: 2700, onTap: {})
    }
    .padding()
    .background(Color("AppBackground"))
}

import SwiftUI

// MARK: - Sermon Player View
// Extracted audio player controls for sermon viewing

struct SermonPlayerView: View {
    let viewModel: SermonViewingViewModel
    let delay: Double
    let isAwakened: Bool

    var body: some View {
        SermonAtriumCard(delay: delay, isAwakened: isAwakened) {
            VStack(spacing: Theme.Spacing.md) {
                HStack(spacing: Theme.Spacing.md) {
                    // Play/Pause button
                    Button {
                        viewModel.togglePlayPause()
                        HapticService.shared.softTap()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color("AppSurface"))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle()
                                        .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
                                )

                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(Typography.Icon.md)
                                .foregroundStyle(Color("AppTextPrimary"))
                                .offset(x: viewModel.isPlaying ? 0 : 2)
                        }
                    }
                    .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")

                    // Time display
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.currentTimeFormatted) / \(viewModel.durationFormatted)")
                            .font(Typography.Command.body.monospacedDigit())
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)

                        // Playback speed indicator
                        if viewModel.playbackSpeed != 1.0 {
                            Text("\(String(format: "%.1fx", viewModel.playbackSpeed))")
                                .font(Typography.Command.meta)
                                .foregroundStyle(Color("TertiaryText"))
                        }
                    }

                    Spacer()

                    // Skip controls
                    HStack(spacing: Theme.Spacing.sm) {
                        Button {
                            viewModel.seekBackward(15)
                            HapticService.shared.selectionChanged()
                        } label: {
                            Image(systemName: "gobackward.15")
                                .font(Typography.Command.callout)
                                .foregroundStyle(Color("AppTextSecondary"))
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Skip back 15 seconds")

                        Button {
                            viewModel.seekForward(15)
                            HapticService.shared.selectionChanged()
                        } label: {
                            Image(systemName: "goforward.15")
                                .font(Typography.Command.callout)
                                .foregroundStyle(Color("AppTextSecondary"))
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Skip forward 15 seconds")
                    }
                }

                // Progress bar
                progressBar
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color("AppDivider").opacity(0.5))

                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color("AppAccentAction"))
                    .frame(width: geometry.size.width * viewModel.progress)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let progress = max(0, min(1, value.location.x / geometry.size.width))
                        viewModel.seek(to: progress)
                    }
            )
        }
        .frame(height: 4)
        .accessibilityLabel("Playback progress")
        .accessibilityValue("\(Int(viewModel.progress * 100)) percent")
    }
}

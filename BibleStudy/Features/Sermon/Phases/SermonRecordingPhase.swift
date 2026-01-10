import SwiftUI

// MARK: - Sermon Recording Phase
// Live recording interface with waveform visualization

struct SermonRecordingPhase: View {
    @Bindable var flowState: SermonFlowState
    @State private var pulsePhase: CGFloat = 0

    var body: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Spacer()

            // Waveform visualizer
            waveformSection

            // Timer display
            timerSection

            // Status text
            statusSection

            Spacer()

            // Control buttons
            controlsSection

            // Bookmark button
            bookmarkButton
                .padding(.bottom, Theme.Spacing.xxl)
        }
        .padding(.horizontal, Theme.Spacing.xxl)
        .onAppear {
            startPulseAnimation()
        }
    }

    // MARK: - Waveform Section

    private var waveformSection: some View {
        SermonWaveformView(
            audioLevels: flowState.audioLevels,
            currentLevel: flowState.currentAudioLevel,
            isActive: flowState.isRecording && !flowState.isPaused
        )
        .frame(height: 120)
        .padding(.horizontal, Theme.Spacing.lg)
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Recording indicator
            HStack(spacing: Theme.Spacing.sm) {
                Circle()
                    .fill(Color.red)
                    .frame(width: Theme.Spacing.md, height: Theme.Spacing.md)
                    .shadow(color: .red.opacity(Theme.Opacity.strong), radius: 8)
                    .scaleEffect(flowState.isRecording && !flowState.isPaused ? 1 + pulsePhase * 0.2 : 1.0)

                Text(flowState.isPaused ? "PAUSED" : "RECORDING")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(flowState.isPaused ? Color.textSecondary : Color.red)
                    // swiftlint:disable:next hardcoded_tracking
                    .tracking(4)
            }

            // Duration timer
            Text(flowState.formattedDuration)
                .font(Typography.Scripture.display)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentBronze, Color.decorativeGold.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .monospacedDigit()
                .contentTransition(.numericText())
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            if let title = flowState.currentSermon?.title, !title.isEmpty {
                Text(title)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color.textPrimary)
            }

            Text(flowState.isPaused ? "Recording paused" : "Recording sermon...")
                .font(Typography.Scripture.body)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: Theme.Spacing.xxl) {
            // Pause/Resume button
            Button {
                if flowState.isPaused {
                    flowState.resumeRecording()
                } else {
                    flowState.pauseRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.surfaceRaised)
                        .frame(width: 40 + 8, height: 40 + 8)
                        .overlay(
                            Circle()
                                .stroke(Color.accentBronze.opacity(Theme.Opacity.medium), lineWidth: Theme.Stroke.hairline)
                        )

                    Image(systemName: flowState.isPaused ? "play.fill" : "pause.fill")
                        .font(Typography.Icon.xxl)
                        .foregroundStyle(Color.accentBronze)
                }
            }
            .buttonStyle(.plain)

            // Stop button (primary)
            Button {
                Task {
                    await flowState.stopRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentBronze, Color.decorativeGold.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.accentBronze.opacity(Theme.Opacity.disabled), radius: 12, y: 4)

                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .fill(Color.surfaceParchment)
                        .frame(width: Theme.Spacing.xxl, height: Theme.Spacing.xxl)
                }
            }
            .buttonStyle(.plain)

            // Cancel button
            Button {
                flowState.cancelRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.surfaceRaised)
                        .frame(width: 40 + 8, height: 40 + 8)
                        .overlay(
                            Circle()
                                .stroke(Color.red.opacity(Theme.Opacity.medium), lineWidth: Theme.Stroke.hairline)
                        )

                    Image(systemName: "xmark")
                        .font(Typography.Icon.xxl)
                        .foregroundStyle(Color.red.opacity(Theme.Opacity.pressed))
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Bookmark Button

    private var bookmarkButton: some View {
        Button {
            Task {
                await flowState.addBookmark(label: .keyPoint)
            }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "bookmark.fill")
                    .font(Typography.Icon.md)

                Text("Bookmark Moment")
                    .font(Typography.Scripture.heading)
            }
            .foregroundStyle(Color.accentBronze)
            .padding(.horizontal, Theme.Spacing.xxl)
            .padding(.vertical, Theme.Spacing.md)
            .background(Color.surfaceRaised.opacity(Theme.Opacity.pressed))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.accentBronze.opacity(Theme.Opacity.medium), lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Animation

    private func startPulseAnimation() {
        // swiftlint:disable:next hardcoded_animation_ease
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulsePhase = 1
        }
    }
}

// MARK: - Sermon Waveform View

struct SermonWaveformView: View {
    let audioLevels: [Float]
    let currentLevel: Float
    let isActive: Bool

    private let barCount = 40
    private let barWidth: CGFloat = 4
    private let spacing: CGFloat = 3

    var body: some View {
        Canvas { context, size in
            let totalBars = barCount
            let maxHeight = size.height * 0.8

            for i in 0..<totalBars {
                // Get level from array or use current level for recent bars
                let level: CGFloat
                if i < audioLevels.count {
                    level = CGFloat(audioLevels[i])
                } else if i == audioLevels.count && isActive {
                    level = CGFloat(currentLevel)
                } else {
                    level = 0.1
                }

                let height = max(4, level * maxHeight)
                let x = CGFloat(i) * (barWidth + spacing)
                let y = (size.height - height) / 2

                let rect = CGRect(x: x, y: y, width: barWidth, height: height)

                // Gold gradient per bar
                let gradient = Gradient(colors: [
                    Color(red: 0.91, green: 0.79, blue: 0.47), // Gold light
                    Color(red: 0.83, green: 0.66, blue: 0.33)  // Gold
                ])

                context.fill(
                    RoundedRectangle(cornerRadius: Theme.Radius.xs).path(in: rect),
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: rect.midX, y: rect.minY),
                        endPoint: CGPoint(x: rect.midX, y: rect.maxY)
                    )
                )
            }
        }
        .background(Color.surfaceRaised.opacity(Theme.Opacity.heavy))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color.accentBronze.opacity(Theme.Opacity.lightMedium), lineWidth: Theme.Stroke.hairline)
        )
    }
}

#Preview {
    SermonRecordingPhase(flowState: {
        let state = SermonFlowState()
        state.isRecording = true
        state.audioLevels = (0..<40).map { _ in Float.random(in: 0.1...0.8) }
        return state
    }())
    .preferredColorScheme(.dark)
}

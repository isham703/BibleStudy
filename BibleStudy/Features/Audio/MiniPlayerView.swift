import SwiftUI

// MARK: - Mini Player View
// Persistent bottom bar showing audio playback status

struct MiniPlayerView: View {
    let audioService: AudioService
    let onTap: () -> Void
    let onClose: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Play/Pause button OR Loading indicator
            if audioService.isLoading {
                IlluminatedLoadingIndicator(progress: audioService.generationProgress)
                    .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
            } else {
                Button(action: {
                    HapticService.shared.lightTap()
                    audioService.togglePlayPause()
                }) {
                    Image(systemName: audioService.isPlaying ? "pause.fill" : "play.fill")
                        .font(Typography.Command.title3.weight(.semibold))
                        .foregroundStyle(Color("AppAccentAction"))
                        .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                }
                .accessibilityLabel(audioService.isPlaying ? "Pause" : "Play")
                .accessibilityHint("Double tap to toggle playback")
            }

            // Chapter info and progress
            VStack(alignment: .leading, spacing: 2) {
                if let chapter = audioService.currentChapter {
                    Text("\(chapter.bookName) \(chapter.chapterNumber)")
                        .font(Typography.Command.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)

                    if audioService.isLoading {
                        // Show generation progress during loading
                        HStack(spacing: Theme.Spacing.xs) {
                            Text("Preparing scripture")
                                .font(Typography.Command.meta)
                                .foregroundStyle(Color("AppTextSecondary"))

                            Text("•")
                                .font(Typography.Command.meta)
                                .foregroundStyle(Color("TertiaryText"))
                                .accessibilityHidden(true)

                            Text("\(Int(audioService.generationProgress * 100))%")
                                .font(Typography.Command.meta.monospacedDigit())
                                .foregroundStyle(Color("AppAccentAction"))
                                .accessibilityAddTraits(.updatesFrequently)
                        }
                        .lineLimit(1)
                    } else {
                        Text("\(audioService.formattedCurrentTime) / \(audioService.formattedDuration)")
                            .font(Typography.Command.meta.monospacedDigit())
                            .foregroundStyle(Color("TertiaryText"))
                            .lineLimit(1)
                            .accessibilityAddTraits(.updatesFrequently)
                            .accessibilityLabel("Time: \(audioService.formattedCurrentTime) of \(audioService.formattedDuration)")
                    }
                } else {
                    Text("Loading...")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(chapterAccessibilityLabel)
            .accessibilityHint("Double tap to open full audio player")

            // Skip backward - 44pt minimum touch target per HIG
            Button(action: {
                HapticService.shared.lightTap()
                audioService.skipBackward()
            }) {
                Image(systemName: "gobackward.15")
                    .font(Typography.Command.callout)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
            }
            .accessibilityLabel("Skip backward 15 seconds")

            // Skip forward - 44pt minimum touch target per HIG
            Button(action: {
                HapticService.shared.lightTap()
                audioService.skipForward()
            }) {
                Image(systemName: "goforward.15")
                    .font(Typography.Command.callout)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
            }
            .accessibilityLabel("Skip forward 15 seconds")

            // Close button - 44pt minimum touch target per HIG
            Button(action: {
                HapticService.shared.lightTap()
                onClose()
            }) {
                Image(systemName: "xmark")
                    .font(Typography.Command.caption.weight(.medium))
                    .foregroundStyle(Color("TertiaryText"))
                    .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
            }
            .accessibilityLabel("Close audio player")
            .accessibilityHint("Stops playback and hides the player")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface"))
                .shadow(color: .black.opacity(Theme.Opacity.selectionBackground), radius: 8, y: -2)
        }
        .overlay(alignment: .bottom) {
            // Progress bar
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color("AppAccentAction"))
                    .frame(width: geometry.size.width * audioService.progress, height: 2)
            }
            .frame(height: 2)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    // MARK: - Accessibility Helpers

    private var chapterAccessibilityLabel: String {
        if let chapter = audioService.currentChapter {
            return "\(chapter.bookName) Chapter \(chapter.chapterNumber), \(audioService.formattedCurrentTime) of \(audioService.formattedDuration)"
        }
        return "Loading audio"
    }
}

// MARK: - Audio Player Container
// DEPRECATED: MainTabView now manages mini player directly in its VStack layout.
// Kept for potential future use or backward compatibility.
// Wrapper to manage mini player visibility and full player sheet

@available(*, deprecated, message: "Use direct mini player integration in MainTabView instead")
struct AudioPlayerContainer<Content: View>: View {
    @State private var audioService = AudioService.shared
    @State private var showFullPlayer = false

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            content

            // Mini player (shown when audio is active)
            if audioService.playbackState != .idle {
                VStack(spacing: 0) {
                    Spacer()

                    MiniPlayerView(
                        audioService: audioService,
                        onTap: {
                            showFullPlayer = true
                        },
                        onClose: {
                            withAnimation(Theme.Animation.fade) {
                                audioService.stop()
                            }
                        }
                    )
                    .padding(.bottom, Theme.Spacing.sm)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(Theme.Animation.settle, value: audioService.playbackState)
            }
        }
        .sheet(isPresented: $showFullPlayer) {
            AudioPlayerSheet(audioService: audioService)
        }
    }
}

// MARK: - Scholar Loading Indicator
// Editorial aesthetic with indigo radiance and breathing animation

private struct IlluminatedLoadingIndicator: View {
    let progress: Double
    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerOffset: CGFloat = -1.0

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Outer indigo ring - orbital accent
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground),
                            Color("AppAccentAction").opacity(Theme.Opacity.disabled),
                            Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: Theme.Stroke.control
                )
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(Theme.Animation.fade) {
                        rotation = 360
                    }
                }

            // Progress arc - indigo completion
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color("AppAccentAction"),
                    style: StrokeStyle(lineWidth: Theme.Stroke.control + 0.5, lineCap: .round)
                )
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(-90))
                .animation(Theme.Animation.slowFade, value: progress)

            // Inner radiant glow - subtle shimmer
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color("AppAccentAction").opacity(Theme.Opacity.focusStroke),
                            Color("AppAccentAction").opacity(Theme.Opacity.subtle),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 15
                    )
                )
                .frame(width: 30, height: 30)
                .scaleEffect(pulseScale)
                .onAppear {
                    withAnimation(Theme.Animation.fade) {
                        pulseScale = 1.15
                    }
                }

            // Center icon - waveform symbol
            Image(systemName: "waveform")
                .font(Typography.Icon.sm.weight(.light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color("AppAccentAction"),
                            Color("AppAccentAction").opacity(Theme.Opacity.overlay)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    // Shimmer effect - subtle light sweep
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(Theme.Opacity.focusStroke),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 50)
                    .offset(x: shimmerOffset * 60)
                    .mask(
                        Image(systemName: "waveform")
                            .font(Typography.Icon.sm.weight(.light))
                    )
                    .onAppear {
                        withAnimation(Theme.Animation.fade) {
                            shimmerOffset = 1.0
                        }
                    }
                }

            // Ornamental details - progress indicators
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(Color("AppAccentAction").opacity(Theme.Opacity.disabled))
                    .frame(width: 2, height: 2)
                    .offset(y: -20)
                    .rotationEffect(.degrees(Double(index) * 90))
                    .opacity(progress > Double(index) / 4.0 ? 1 : Theme.Opacity.selectionBackground)
                    .animation(Theme.Animation.slowFade.delay(Double(index) * 0.1), value: progress)
            }
        }
        .padding(Theme.Spacing.xs)
        .accessibilityLabel("Preparing audio")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()

        MiniPlayerView(
            audioService: AudioService.shared,
            onTap: {},
            onClose: {}
        )
        .padding(.bottom, Theme.Spacing.xxl)
    }
    .background(Color.appBackground)
}

#Preview("Loading Indicator") {
    VStack(spacing: Theme.Spacing.xxl) {
        IlluminatedLoadingIndicator(progress: 0.3)
        IlluminatedLoadingIndicator(progress: 0.7)
        IlluminatedLoadingIndicator(progress: 1.0)
    }
    .padding()
    .background(Color("AppSurface"))
}

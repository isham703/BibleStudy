import SwiftUI

// MARK: - Mini Player View
// Persistent bottom bar showing audio playback status

struct MiniPlayerView: View {
    let audioService: AudioService
    let onTap: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Play/Pause button OR Loading indicator
            if audioService.isLoading {
                IlluminatedLoadingIndicator(progress: audioService.generationProgress)
                    .frame(width: 44, height: 44)
            } else {
                Button(action: {
                    HapticService.shared.lightTap()
                    audioService.togglePlayPause()
                }) {
                    Image(systemName: audioService.isPlaying ? "pause.fill" : "play.fill")
                        .font(Typography.UI.title3.weight(.semibold))
                        .foregroundStyle(Color.Semantic.accent)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(audioService.isPlaying ? "Pause" : "Play")
                .accessibilityHint("Double tap to toggle playback")
            }

            // Chapter info and progress
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                if let chapter = audioService.currentChapter {
                    Text("\(chapter.bookName) \(chapter.chapterNumber)")
                        .font(Typography.UI.caption1)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primaryText)
                        .lineLimit(1)

                    if audioService.isLoading {
                        // Show generation progress during loading
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Text("Preparing scripture")
                                .font(Typography.UI.caption2)
                                .foregroundStyle(Color.secondaryText)

                            Text("•")
                                .font(Typography.UI.caption2)
                                .foregroundStyle(Color.tertiaryText)
                                .accessibilityHidden(true)

                            Text("\(Int(audioService.generationProgress * 100))%")
                                .font(Typography.UI.caption2.monospacedDigit())
                                .foregroundStyle(Color.Semantic.accent)
                                .accessibilityAddTraits(.updatesFrequently)
                        }
                    } else {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            if let verse = audioService.currentVerse {
                                Text("Verse \(verse)")
                                    .font(Typography.UI.caption2.monospacedDigit())
                                    .foregroundStyle(Color.secondaryText)
                                    .accessibilityAddTraits(.updatesFrequently)
                            }

                            Text("•")
                                .font(Typography.UI.caption2)
                                .foregroundStyle(Color.tertiaryText)
                                .accessibilityHidden(true)

                            Text("\(audioService.formattedCurrentTime) / \(audioService.formattedDuration)")
                                .font(Typography.UI.caption2.monospacedDigit())
                                .foregroundStyle(Color.tertiaryText)
                                .accessibilityAddTraits(.updatesFrequently)
                                .accessibilityLabel("Time: \(audioService.formattedCurrentTime) of \(audioService.formattedDuration)")
                        }
                    }
                } else {
                    Text("Loading...")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.secondaryText)
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
                    .font(Typography.UI.callout)
                    .foregroundStyle(Color.secondaryText)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Skip backward 15 seconds")

            // Skip forward - 44pt minimum touch target per HIG
            Button(action: {
                HapticService.shared.lightTap()
                audioService.skipForward()
            }) {
                Image(systemName: "goforward.15")
                    .font(Typography.UI.callout)
                    .foregroundStyle(Color.secondaryText)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Skip forward 15 seconds")

            // Close button - 44pt minimum touch target per HIG
            Button(action: {
                HapticService.shared.lightTap()
                onClose()
            }) {
                Image(systemName: "xmark")
                    .font(Typography.UI.caption1.weight(.medium))
                    .foregroundStyle(Color.tertiaryText)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close audio player")
            .accessibilityHint("Stops playback and hides the player")
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .fill(Color.elevatedBackground)
                .shadow(color: .black.opacity(AppTheme.Opacity.light), radius: 8, y: -2)
        }
        .overlay(alignment: .bottom) {
            // Progress bar
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.Semantic.accent)
                    .frame(width: geometry.size.width * audioService.progress, height: AppTheme.Divider.medium)
            }
            .frame(height: AppTheme.Divider.medium)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }

    // MARK: - Accessibility Helpers

    private var chapterAccessibilityLabel: String {
        if let chapter = audioService.currentChapter {
            var label = "\(chapter.bookName) Chapter \(chapter.chapterNumber)"
            if let verse = audioService.currentVerse {
                label += ", Verse \(verse)"
            }
            label += ", \(audioService.formattedCurrentTime) of \(audioService.formattedDuration)"
            return label
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
                            withAnimation(AppTheme.Animation.quick) {
                                audioService.stop()
                            }
                        }
                    )
                    .padding(.bottom, AppTheme.Spacing.sm)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(AppTheme.Animation.spring, value: audioService.playbackState)
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

    var body: some View {
        ZStack {
            // Outer indigo ring - orbital accent
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.Semantic.accent.opacity(AppTheme.Opacity.lightMedium),
                            Color.Semantic.accent.opacity(AppTheme.Opacity.disabled),
                            Color.Semantic.accent.opacity(AppTheme.Opacity.lightMedium)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: AppTheme.Border.regular
                )
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(AppTheme.Animation.celestialRotation) {
                        rotation = 360
                    }
                }

            // Progress arc - indigo completion
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.Semantic.accent,
                    style: StrokeStyle(lineWidth: AppTheme.Border.medium + 0.5, lineCap: .round)
                )
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(-90))
                .animation(AppTheme.Animation.luminous, value: progress)

            // Inner radiant glow - subtle shimmer
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.Semantic.accent.opacity(AppTheme.Opacity.medium),
                            Color.Semantic.accent.opacity(AppTheme.Opacity.subtle),
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
                    withAnimation(AppTheme.Animation.breathingPulse) {
                        pulseScale = 1.15
                    }
                }

            // Center icon - waveform symbol
            Image(systemName: "waveform")
                .font(Typography.UI.iconSm.weight(.light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.Semantic.accent,
                            Color.Semantic.accent.opacity(AppTheme.Opacity.overlay)
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
                            Color.white.opacity(AppTheme.Opacity.medium),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 50)
                    .offset(x: shimmerOffset * 60)
                    .mask(
                        Image(systemName: "waveform")
                            .font(Typography.UI.iconSm.weight(.light))
                    )
                    .onAppear {
                        withAnimation(AppTheme.Animation.shimmerContinuous) {
                            shimmerOffset = 1.0
                        }
                    }
                }

            // Ornamental details - progress indicators
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(Color.Semantic.accent.opacity(AppTheme.Opacity.disabled))
                    .frame(width: AppTheme.Spacing.xxs, height: AppTheme.Spacing.xxs)
                    .offset(y: -20)
                    .rotationEffect(.degrees(Double(index) * 90))
                    .opacity(progress > Double(index) / 4.0 ? 1 : AppTheme.Opacity.lightMedium)
                    .animation(AppTheme.Animation.luminous.delay(Double(index) * 0.1), value: progress)
            }
        }
        .padding(AppTheme.Spacing.xs)
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
        .padding(.bottom, AppTheme.Spacing.xxxl)
    }
    .background(Color.appBackground)
}

#Preview("Loading Indicator") {
    VStack(spacing: AppTheme.Spacing.xxxl) {
        IlluminatedLoadingIndicator(progress: 0.3)
        IlluminatedLoadingIndicator(progress: 0.7)
        IlluminatedLoadingIndicator(progress: 1.0)
    }
    .padding()
    .background(Color.elevatedBackground)
}

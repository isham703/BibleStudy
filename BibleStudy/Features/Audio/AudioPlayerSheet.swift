import SwiftUI

// MARK: - Audio Player Sheet
// Full-screen audio player with all controls

struct AudioPlayerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let audioService: AudioService

    @State private var isDraggingSlider = false
    @State private var sliderProgress: Double = 0
    @State private var showSpeedPicker = false
    @State private var showSleepTimer = false
    @State private var showVersePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xl) {
                // Error banner (if applicable)
                if audioService.error != nil {
                    errorBanner
                }

                // Chapter artwork/info
                chapterInfoSection

                Spacer()

                // Progress slider
                progressSection

                // Main controls
                controlsSection

                // Speed control
                speedControlSection

                // Additional options
                optionsSection

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.top, Theme.Spacing.xl)
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(Typography.Command.callout.weight(.semibold))
                            .foregroundStyle(Color("AppTextSecondary"))
                            .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                    }
                    .accessibilityLabel("Dismiss")
                    .accessibilityHint("Close the audio player")
                }

                ToolbarItem(placement: .principal) {
                    Text("Now Playing")
                        .font(Typography.Command.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            sliderProgress = audioService.progress
        }
        .onChange(of: audioService.progress) { _, newValue in
            if !isDraggingSlider {
                sliderProgress = newValue
            }
        }
    }

    // MARK: - Chapter Info Section

    private var chapterInfoSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Book icon/artwork
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.xl)
                    .fill(Color("AppSurface"))
                    .frame(width: 200, height: 200)

                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "book.fill")
                        .font(Typography.Command.largeTitle)
                        .imageScale(.large)
                        .foregroundStyle(Color("AppAccentAction"))
                        .accessibilityHidden(true)

                    if let chapter = audioService.currentChapter {
                        Text(chapter.bookName.uppercased())
                            .font(Typography.Command.meta)
                            .fontWeight(.bold)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .tracking(2)

                        Text("CHAPTER \(chapter.chapterNumber)")
                            .font(Typography.Scripture.title.weight(.bold).monospacedDigit())
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(chapterInfoAccessibilityLabel)

            // Translation badge
            if let chapter = audioService.currentChapter {
                Text(chapter.translation)
                    .font(Typography.Command.meta)
                    .fontWeight(.medium)
                    .foregroundStyle(Color("TertiaryText"))
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background {
                        Capsule()
                            .fill(Color("AppSurface"))
                    }
                    .accessibilityLabel("\(chapter.translation) translation")
            }
        }
    }

    private var chapterInfoAccessibilityLabel: String {
        if let chapter = audioService.currentChapter {
            return "\(chapter.bookName), Chapter \(chapter.chapterNumber)"
        }
        return "Loading chapter"
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Progress slider
            Slider(
                value: $sliderProgress,
                in: 0...1,
                onEditingChanged: { editing in
                    isDraggingSlider = editing
                    if !editing {
                        let seekTime = sliderProgress * audioService.duration
                        audioService.seek(to: seekTime)
                    }
                }
            )
            .tint(Color("AppAccentAction"))
            .accessibilityLabel("Playback progress")
            .accessibilityValue(sliderAccessibilityValue)

            // Time labels
            HStack {
                Text(isDraggingSlider ? formatTime(sliderProgress * audioService.duration) : audioService.formattedCurrentTime)
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("TertiaryText"))
                    .monospacedDigit()
                    .accessibilityAddTraits(.updatesFrequently)
                    .accessibilityLabel("Current time: \(audioService.formattedCurrentTime)")

                Spacer()

                // Current verse
                if let verse = audioService.currentVerse {
                    Text("Verse \(verse)")
                        .font(Typography.Command.meta.monospacedDigit())
                        .fontWeight(.medium)
                        .foregroundStyle(Color("AppAccentAction"))
                        .accessibilityAddTraits(.updatesFrequently)
                        .accessibilityLabel("Currently playing verse \(verse)")
                }

                Spacer()

                Text(audioService.formattedDuration)
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("TertiaryText"))
                    .monospacedDigit()
                    .accessibilityLabel("Total duration: \(audioService.formattedDuration)")
            }
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack {
            Spacer()

            // Previous verse
            Button(action: {
                HapticService.shared.lightTap()
                audioService.previousVerse()
            }) {
                Image(systemName: "backward.end.fill")
                    .font(Typography.Command.title2)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
            }
            .accessibilityLabel("Previous verse")
            .accessibilityHint("Jump to the previous verse")

            Spacer()

            // Skip backward 15s
            Button(action: {
                HapticService.shared.lightTap()
                audioService.skipBackward()
            }) {
                Image(systemName: "gobackward.15")
                    .font(Typography.Command.title1)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
            }
            .accessibilityLabel("Skip backward 15 seconds")

            Spacer()

            // Play/Pause
            Button(action: {
                HapticService.shared.mediumTap()
                audioService.togglePlayPause()
            }) {
                ZStack {
                    Circle()
                        .fill(Color("AppAccentAction"))
                        .frame(width: 72, height: 72)

                    if audioService.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: audioService.isPlaying ? "pause.fill" : "play.fill")
                            .font(Typography.Command.title1.weight(.bold))
                            .foregroundStyle(.white)
                            .offset(x: audioService.isPlaying ? 0 : 2)
                    }
                }
            }
            .disabled(audioService.isLoading)
            .accessibilityLabel(audioService.isLoading ? "Loading" : (audioService.isPlaying ? "Pause" : "Play"))
            .accessibilityHint("Double tap to toggle playback")

            Spacer()

            // Skip forward 15s
            Button(action: {
                HapticService.shared.lightTap()
                audioService.skipForward()
            }) {
                Image(systemName: "goforward.15")
                    .font(Typography.Command.title1)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
            }
            .accessibilityLabel("Skip forward 15 seconds")

            Spacer()

            // Next verse
            Button(action: {
                HapticService.shared.lightTap()
                audioService.nextVerse()
            }) {
                Image(systemName: "forward.end.fill")
                    .font(Typography.Command.title2)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
            }
            .accessibilityLabel("Next verse")
            .accessibilityHint("Jump to the next verse")

            Spacer()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Playback controls")
    }

    // MARK: - Speed Control Section

    private var speedControlSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                    let isSelected = Double(audioService.playbackRate) == speed
                    Button(action: {
                        HapticService.shared.lightTap()
                        audioService.playbackRate = Float(speed)
                    }) {
                        Text(speed == 1.0 ? "1x" : String(format: "%.2gx", speed))
                            .font(Typography.Command.meta.monospacedDigit())
                            .fontWeight(isSelected ? .bold : .medium)
                            .foregroundStyle(isSelected ? Color("AppAccentAction") : Color("AppTextSecondary"))
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.sm)
                    }
                    .accessibilityLabel("\(speed == 1.0 ? "Normal" : String(format: "%.2g times", speed)) speed")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                    .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
                }
            }
            .padding(.horizontal, Theme.Spacing.sm)
        }
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Color("AppSurface"))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Playback speed")
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        HStack(spacing: Theme.Spacing.xl) {
            // Verse list
            AudioOptionButton(
                icon: "list.bullet",
                label: "Verses",
                accessibilityHintText: "Show list of verses to navigate"
            ) {
                showVersePicker = true
            }
            .sheet(isPresented: $showVersePicker) {
                AudioVersePickerSheet(audioService: audioService)
            }

            // Download status / Generation progress
            if let chapter = audioService.currentChapter {
                let isDownloaded = AudioCache.shared.isDownloaded(chapter)

                if audioService.isGeneratingAudio {
                    // Show progress during generation
                    GenerationProgressButton(progress: audioService.generationProgress)
                } else {
                    AudioOptionButton(
                        icon: isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle",
                        label: isDownloaded ? "Downloaded" : "Download",
                        accessibilityHintText: isDownloaded ? "Chapter audio is saved for offline playback" : "Download chapter for offline playback"
                    ) {
                        // Audio is auto-cached, this just shows status
                    }
                    .disabled(true)
                    .accessibilityAddTraits(isDownloaded ? .isSelected : [])
                }
            }

            // Sleep timer
            AudioOptionButton(
                icon: audioService.isSleepTimerActive ? "moon.zzz.fill" : "moon.fill",
                label: sleepTimerLabel,
                accessibilityHintText: audioService.isSleepTimerActive ? "Tap to change or cancel timer" : "Set a sleep timer to stop playback"
            ) {
                showSleepTimer = true
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Additional options")
        .sheet(isPresented: $showSleepTimer) {
            SleepTimerPickerView(audioService: audioService)
        }
    }

    private var sleepTimerLabel: String {
        if audioService.sleepTimerEndOfChapter {
            return "End of Ch."
        } else if audioService.isSleepTimerActive {
            let minutes = Int(audioService.sleepTimerRemaining / 60)
            return "\(minutes)m"
        }
        return "Sleep"
    }

    // MARK: - Error Banner

    private var errorBanner: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(Typography.Command.title3)
                    .foregroundStyle(Color("FeedbackError"))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Audio Error")
                        .font(Typography.Command.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text(audioService.error?.localizedDescription ?? "An error occurred")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                }

                Spacer()

                Button(action: {
                    HapticService.shared.lightTap()
                    retryAudioLoad()
                }) {
                    Text("Retry")
                        .font(Typography.Command.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background {
                            Capsule()
                                .fill(Color("AppAccentAction"))
                        }
                }
                .accessibilityLabel("Retry loading audio")
                .accessibilityHint("Try loading the audio again")
            }
            .padding(Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color("FeedbackError").opacity(Theme.Opacity.subtle))
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .stroke(Color("FeedbackError").opacity(Theme.Opacity.focusStroke), lineWidth: Theme.Stroke.hairline)
                    }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Audio error: \(audioService.error?.localizedDescription ?? "unknown error"). Retry button available.")
    }

    private func retryAudioLoad() {
        guard let chapter = audioService.currentChapter else { return }
        Task {
            await audioService.loadChapter(chapter)
        }
    }

    // MARK: - Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Accessibility Helpers

    private var sliderAccessibilityValue: String {
        let percentage = Int(sliderProgress * 100)
        let currentTime = formatTime(sliderProgress * audioService.duration)
        let totalTime = audioService.formattedDuration
        return "\(percentage) percent, \(currentTime) of \(totalTime)"
    }
}

// MARK: - Audio Option Button

private struct AudioOptionButton: View {
    let icon: String
    let label: String
    var accessibilityHintText: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(Typography.Command.title3)
                    .foregroundStyle(Color("AppTextSecondary"))

                Text(label)
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .frame(width: 72, height: 56)
        }
        .accessibilityLabel(label)
        .accessibilityHint(accessibilityHintText)
    }
}

// MARK: - Generation Progress Button

private struct GenerationProgressButton: View {
    let progress: Double

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color("AppSurface"), lineWidth: Theme.Stroke.control)
                    .frame(width: Theme.Size.iconSize, height: Theme.Size.iconSize)

                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color("AppAccentAction"), style: StrokeStyle(lineWidth: Theme.Stroke.control, lineCap: .round))
                    .frame(width: Theme.Size.iconSize, height: Theme.Size.iconSize)
                    .rotationEffect(.degrees(-90))
                    .animation(Theme.Animation.fade, value: progress)
            }

            Text("\(Int(progress * 100))%")
                .font(Typography.Command.meta)
                .foregroundStyle(Color("AppAccentAction"))
                .monospacedDigit()
        }
        .frame(width: 72, height: 56)
        .accessibilityLabel("Generating audio")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Preview

#Preview {
    AudioPlayerSheet(audioService: AudioService.shared)
}

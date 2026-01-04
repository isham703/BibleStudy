import SwiftUI

// MARK: - Audio Player Sheet
// Full-screen audio player with all controls

struct AudioPlayerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let audioService: AudioService

    @State private var isDraggingSlider = false
    @State private var sliderProgress: Double = 0
    @State private var showSpeedPicker = false
    @State private var showSleepTimer = false
    @State private var showVersePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.xl) {
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
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.top, AppTheme.Spacing.xl)
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(Typography.UI.callout.weight(.semibold))
                            .foregroundStyle(Color.secondaryText)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Dismiss")
                    .accessibilityHint("Close the audio player")
                }

                ToolbarItem(placement: .principal) {
                    Text("Now Playing")
                        .font(Typography.UI.caption1)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.secondaryText)
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
        VStack(spacing: AppTheme.Spacing.lg) {
            // Book icon/artwork
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.sheet)
                    .fill(Color.elevatedBackground)
                    .frame(width: 200, height: 200)

                VStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "book.fill")
                        .font(Typography.UI.largeTitle)
                        .imageScale(.large)
                        .foregroundStyle(Color.Semantic.accent)
                        .accessibilityHidden(true)

                    if let chapter = audioService.currentChapter {
                        Text(chapter.bookName.uppercased())
                            .font(Typography.UI.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.secondaryText)
                            .tracking(2)

                        Text("CHAPTER \(chapter.chapterNumber)")
                            .font(Typography.Scripture.title.weight(.bold).monospacedDigit())
                            .foregroundStyle(Color.primaryText)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(chapterInfoAccessibilityLabel)

            // Translation badge
            if let chapter = audioService.currentChapter {
                Text(chapter.translation)
                    .font(Typography.UI.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.tertiaryText)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background {
                        Capsule()
                            .fill(Color.surfaceBackground)
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
        VStack(spacing: AppTheme.Spacing.sm) {
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
            .tint(Color.Semantic.accent)
            .accessibilityLabel("Playback progress")
            .accessibilityValue(sliderAccessibilityValue)

            // Time labels
            HStack {
                Text(isDraggingSlider ? formatTime(sliderProgress * audioService.duration) : audioService.formattedCurrentTime)
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.tertiaryText)
                    .monospacedDigit()
                    .accessibilityAddTraits(.updatesFrequently)
                    .accessibilityLabel("Current time: \(audioService.formattedCurrentTime)")

                Spacer()

                // Current verse
                if let verse = audioService.currentVerse {
                    Text("Verse \(verse)")
                        .font(Typography.UI.caption2.monospacedDigit())
                        .fontWeight(.medium)
                        .foregroundStyle(Color.Semantic.accent)
                        .accessibilityAddTraits(.updatesFrequently)
                        .accessibilityLabel("Currently playing verse \(verse)")
                }

                Spacer()

                Text(audioService.formattedDuration)
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.tertiaryText)
                    .monospacedDigit()
                    .accessibilityLabel("Total duration: \(audioService.formattedDuration)")
            }
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: AppTheme.Spacing.xxl) {
            // Previous verse
            Button(action: {
                HapticService.shared.lightTap()
                audioService.previousVerse()
            }) {
                Image(systemName: "backward.end.fill")
                    .font(Typography.UI.title2)
                    .foregroundStyle(Color.primaryText)
                    .frame(width: 48, height: 48)
            }
            .accessibilityLabel("Previous verse")
            .accessibilityHint("Jump to the previous verse")

            // Skip backward 15s
            Button(action: {
                HapticService.shared.lightTap()
                audioService.skipBackward()
            }) {
                Image(systemName: "gobackward.15")
                    .font(Typography.UI.title1)
                    .foregroundStyle(Color.primaryText)
                    .frame(width: 48, height: 48)
            }
            .accessibilityLabel("Skip backward 15 seconds")

            // Play/Pause
            Button(action: {
                HapticService.shared.mediumTap()
                audioService.togglePlayPause()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.Semantic.accent)
                        .frame(width: 72, height: 72)

                    if audioService.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: audioService.isPlaying ? "pause.fill" : "play.fill")
                            .font(Typography.UI.title1.weight(.bold))
                            .foregroundStyle(.white)
                            .offset(x: audioService.isPlaying ? 0 : 2)
                    }
                }
            }
            .disabled(audioService.isLoading)
            .accessibilityLabel(audioService.isLoading ? "Loading" : (audioService.isPlaying ? "Pause" : "Play"))
            .accessibilityHint("Double tap to toggle playback")

            // Skip forward 15s
            Button(action: {
                HapticService.shared.lightTap()
                audioService.skipForward()
            }) {
                Image(systemName: "goforward.15")
                    .font(Typography.UI.title1)
                    .foregroundStyle(Color.primaryText)
                    .frame(width: 48, height: 48)
            }
            .accessibilityLabel("Skip forward 15 seconds")

            // Next verse
            Button(action: {
                HapticService.shared.lightTap()
                audioService.nextVerse()
            }) {
                Image(systemName: "forward.end.fill")
                    .font(Typography.UI.title2)
                    .foregroundStyle(Color.primaryText)
                    .frame(width: 48, height: 48)
            }
            .accessibilityLabel("Next verse")
            .accessibilityHint("Jump to the next verse")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Playback controls")
    }

    // MARK: - Speed Control Section

    private var speedControlSection: some View {
        HStack(spacing: 0) {
            ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                let isSelected = Double(audioService.playbackRate) == speed
                Button(action: {
                    HapticService.shared.lightTap()
                    audioService.playbackRate = Float(speed)
                }) {
                    Text(speed == 1.0 ? "1x" : String(format: "%.2gx", speed))
                        .font(Typography.UI.caption2.monospacedDigit())
                        .fontWeight(isSelected ? .bold : .medium)
                        .foregroundStyle(isSelected ? Color.Semantic.accent : Color.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                }
                .accessibilityLabel("\(speed == 1.0 ? "Normal" : String(format: "%.2g times", speed)) speed")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
            }
        }
        .background {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(Color.surfaceBackground)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Playback speed")
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        HStack(spacing: AppTheme.Spacing.xl) {
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
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(Typography.UI.title3)
                    .foregroundStyle(Color.error)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text("Audio Error")
                        .font(Typography.UI.caption1)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primaryText)

                    Text(audioService.error?.localizedDescription ?? "An error occurred")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(2)
                }

                Spacer()

                Button(action: {
                    HapticService.shared.lightTap()
                    retryAudioLoad()
                }) {
                    Text("Retry")
                        .font(Typography.UI.caption1)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background {
                            Capsule()
                                .fill(Color.Semantic.accent)
                        }
                }
                .accessibilityLabel("Retry loading audio")
                .accessibilityHint("Try loading the audio again")
            }
            .padding(AppTheme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(Color.error.opacity(AppTheme.Opacity.subtle))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                            .stroke(Color.error.opacity(AppTheme.Opacity.medium), lineWidth: AppTheme.Border.thin)
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
            VStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(Typography.UI.title3)
                    .foregroundStyle(Color.secondaryText)

                Text(label)
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.tertiaryText)
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

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.surfaceBackground, lineWidth: AppTheme.Border.thick)
                    .frame(width: 24, height: 24)

                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.Semantic.accent, style: StrokeStyle(lineWidth: AppTheme.Border.thick, lineCap: .round))
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(-90))
                    .animation(AppTheme.Animation.quick, value: progress)
            }

            Text("\(Int(progress * 100))%")
                .font(Typography.UI.caption2)
                .foregroundStyle(Color.Semantic.accent)
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

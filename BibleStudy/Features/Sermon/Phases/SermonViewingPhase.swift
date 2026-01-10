import SwiftUI
import AVFoundation

// MARK: - Sermon Viewing Phase
// Display completed sermon with audio player, transcript, and study guide

struct SermonViewingPhase: View {
    @Bindable var flowState: SermonFlowState
    @State private var viewModel = SermonViewingViewModel()
    @State private var showShareSheet = false
    @State private var copiedToClipboard = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // Header
                sermonHeader

                Rectangle()
                    .fill(Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)))
                    .frame(height: Theme.Stroke.hairline)

                // Audio player
                audioPlayerSection

                // Transcript
                transcriptSection

                // Study guide sections
                if let studyGuide = flowState.currentStudyGuide {
                    studyGuideSections(studyGuide.content)
                }

                // Action buttons
                actionButtons

                Spacer(minLength: 40)
            }
            .padding(.horizontal, Theme.Spacing.lg + 4)
            .padding(.top, Theme.Spacing.xl)
        }
        .onAppear {
            setupAudioPlayer()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .overlay(copiedOverlay)
    }

    // MARK: - Sermon Header

    private var sermonHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Category label
            Text("YOUR SERMON")
                // swiftlint:disable:next hardcoded_font_custom
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color.accentBronze)
                // swiftlint:disable:next hardcoded_tracking
                .tracking(4)

            // Title
            Text(flowState.currentSermon?.displayTitle ?? "Untitled Sermon")
                // swiftlint:disable:next hardcoded_font_custom
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            // Metadata
            if let sermon = flowState.currentSermon {
                HStack(spacing: Theme.Spacing.sm) {
                    if let speaker = sermon.speakerName {
                        Text(speaker)
                    }

                    Text("•")
                        .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.heavy))

                    Text(sermon.formattedDuration)

                    Text("•")
                        .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.heavy))

                    Text(sermon.recordedAt.formatted(date: .abbreviated, time: .omitted))
                }
                // swiftlint:disable:next hardcoded_font_custom
                .font(Typography.Scripture.body)
                .foregroundStyle(Color.textSecondary)
            }
        }
    }

    // MARK: - Audio Player Section

    private var audioPlayerSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Waveform scrubber
            SermonWaveformScrubber(
                samples: viewModel.waveformSamples,
                progress: viewModel.progress,
                onSeek: { progress in
                    viewModel.seek(to: progress)
                }
            )

            // Time labels
            HStack {
                Text(viewModel.currentTimeFormatted)
                Spacer()
                Text(viewModel.durationFormatted)
            }
            .font(Typography.Command.meta.weight(.medium).monospaced())
            .foregroundStyle(Color.textSecondary)

            // Playback controls
            // swiftlint:disable:next hardcoded_stack_spacing
            HStack(spacing: 32) {
                // Skip backward
                Button {
                    viewModel.seekBackward(15)
                    HapticService.shared.selectionChanged()
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(Typography.Icon.xl)
                }
                .foregroundStyle(Color.accentBronze)

                // Play/Pause
                Button {
                    viewModel.togglePlayPause()
                    HapticService.shared.softTap()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        // swiftlint:disable:next hardcoded_font_system
                        .font(Typography.Icon.display)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentBronze, Color.decorativeGold.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                // Skip forward
                Button {
                    viewModel.seekForward(15)
                    HapticService.shared.selectionChanged()
                } label: {
                    Image(systemName: "goforward.15")
                        .font(Typography.Icon.xl)
                }
                .foregroundStyle(Color.accentBronze)
            }

            // Playback speed
            HStack {
                Spacer()
                Menu {
                    ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                        Button {
                            viewModel.setPlaybackSpeed(Float(speed))
                        } label: {
                            HStack {
                                Text("\(speed, specifier: "%.2g")x")
                                if viewModel.playbackSpeed == Float(speed) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text("\(viewModel.playbackSpeed, specifier: "%.2g")x")
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(Typography.Scripture.heading)
                        .foregroundStyle(Color.accentBronze)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.xs + 2)
                        .background(Color.surfaceRaised)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(Theme.Spacing.lg + 4)
        .background(Color.surfaceRaised.opacity(Theme.Opacity.pressed))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color.accentBronze.opacity(Theme.Opacity.lightMedium), lineWidth: Theme.Stroke.hairline)
        )
    }

    // MARK: - Transcript Section

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Section header
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundStyle(Color.accentBronze)

                Text("TRANSCRIPT")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color.textPrimary)
                    // swiftlint:disable:next hardcoded_tracking
                    .tracking(2)

                Spacer()

                if let transcript = flowState.currentTranscript {
                    Text("\(transcript.wordCount) words")
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(Typography.Scripture.body)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            // Transcript content
            if let transcript = flowState.currentTranscript {
                TranscriptContentView(
                    segments: transcript.segments,
                    currentSegmentIndex: viewModel.currentSegmentIndex,
                    onSegmentTap: { segment in
                        viewModel.seekToTime(segment.startTime)
                        HapticService.shared.lightTap()
                    }
                )
            } else {
                Text("Transcript not available")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Theme.Spacing.xxl + 8)
            }
        }
        .padding(Theme.Spacing.lg + 4)
        .background(Color.surfaceRaised.opacity(Theme.Opacity.heavy))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color.accentBronze.opacity(Theme.Opacity.light), lineWidth: Theme.Stroke.hairline)
        )
    }

    // MARK: - Study Guide Sections

    @ViewBuilder
    private func studyGuideSections(_ content: StudyGuideContent) -> some View {
        VStack(spacing: 0) {
            // Summary
            if !content.summary.isEmpty {
                StudyGuideSection(
                    title: "Summary",
                    icon: "text.quote",
                    isExpandedByDefault: true
                ) {
                    Text(content.summary)
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(Typography.Scripture.body)
                        .foregroundStyle(Color.textPrimary)
                        // swiftlint:disable:next hardcoded_line_spacing
                        .lineSpacing(6)
                }
            }

            // Key Themes
            if !content.keyThemes.isEmpty {
                StudyGuideSection(title: "Key Themes", icon: "sparkles") {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm + 2) {
                        ForEach(content.keyThemes, id: \.self) { theme in
                            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                                Image(systemName: "diamond.fill")
                                    .font(Typography.Icon.xxs)
                                    .foregroundStyle(Color.accentBronze)
                                    .padding(.top, Theme.Spacing.xs + 2)

                                Text(theme)
                                    // swiftlint:disable:next hardcoded_font_custom
                                    .font(Typography.Scripture.body)
                                    .foregroundStyle(Color.textPrimary)
                            }
                        }
                    }
                }
            }

            // Discussion Questions
            if !content.discussionQuestions.isEmpty {
                StudyGuideSection(title: "Discussion Questions", icon: "bubble.left.and.bubble.right") {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        ForEach(Array(content.discussionQuestions.enumerated()), id: \.element.id) { index, question in
                            DiscussionQuestionCard(question: question, index: index + 1)
                        }
                    }
                }
            }

            // Reflection Prompts
            if !content.reflectionPrompts.isEmpty {
                StudyGuideSection(title: "Reflection Prompts", icon: "heart.text.square") {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        ForEach(content.reflectionPrompts, id: \.self) { prompt in
                            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                                Image(systemName: "arrow.turn.down.right")
                                    .font(Typography.Icon.sm)
                                    .foregroundStyle(Color.accentBronze)
                                    .padding(.top, Theme.Spacing.xs)

                                Text(prompt)
                                    // swiftlint:disable:next hardcoded_font_custom
                                    .font(Typography.Scripture.body)
                                    .foregroundStyle(Color.textPrimary)
                                    .italic()
                            }
                        }
                    }
                }
            }

            // Scripture References
            if !content.bibleReferencesMentioned.isEmpty || !content.bibleReferencesSuggested.isEmpty {
                StudyGuideSectionWithLegend(title: "Scripture References", icon: "book") {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        // Mentioned references
                        if !content.bibleReferencesMentioned.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                Text("Mentioned in sermon")
                                    // swiftlint:disable:next hardcoded_font_custom
                                    .font(Typography.Scripture.heading)
                                    .foregroundStyle(Color.textSecondary)
                                    // swiftlint:disable:next hardcoded_tracking
                                    .tracking(1)

                                SermonFlowLayout(spacing: 8) {
                                    ForEach(content.bibleReferencesMentioned) { ref in
                                        ScriptureReferenceChip(reference: ref, isMentioned: true)
                                    }
                                }
                            }
                        }

                        // Suggested references
                        if !content.bibleReferencesSuggested.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                HStack(spacing: Theme.Spacing.xs + 2) {
                                    Text("AI-suggested")
                                        // swiftlint:disable:next hardcoded_font_custom
                                        .font(Typography.Scripture.heading)
                                        .foregroundStyle(Color.textSecondary)
                                        // swiftlint:disable:next hardcoded_tracking
                                        .tracking(1)

                                    VerificationLegendButton()
                                }

                                SermonFlowLayout(spacing: 8) {
                                    ForEach(content.bibleReferencesSuggested) { ref in
                                        ScriptureReferenceChip(reference: ref, isMentioned: false)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Application Points
            if !content.applicationPoints.isEmpty {
                StudyGuideSection(title: "Application Points", icon: "hand.raised") {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        ForEach(Array(content.applicationPoints.enumerated()), id: \.offset) { index, point in
                            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                                Text("\(index + 1)")
                                    // swiftlint:disable:next hardcoded_font_custom
                                    .font(Typography.Scripture.display)
                                    .foregroundStyle(Color.accentBronze)
                                    // swiftlint:disable:next hardcoded_icon_frame
                                    .frame(width: 24)

                                Text(point)
                                    // swiftlint:disable:next hardcoded_font_custom
                                    .font(Typography.Scripture.body)
                                    .foregroundStyle(Color.textPrimary)
                            }
                        }
                    }
                }
            }
        }
        .background(Color.surfaceRaised.opacity(Theme.Opacity.heavy))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color.accentBronze.opacity(Theme.Opacity.light), lineWidth: Theme.Stroke.hairline)
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Copy transcript
            Button {
                copyTranscript()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(Typography.Scripture.heading)
            }
            .buttonStyle(SermonActionButtonStyle())

            // Share
            Button {
                showShareSheet = true
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(Typography.Scripture.heading)
            }
            .buttonStyle(SermonActionButtonStyle())

            // New recording
            Button {
                flowState.reset()
            } label: {
                Label("New", systemImage: "plus")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(Typography.Scripture.heading)
            }
            .buttonStyle(SermonActionButtonStyle())
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareText = generateShareText() {
                ShareSheet(items: [shareText])
            }
        }
    }

    // MARK: - Copied Overlay

    private var copiedOverlay: some View {
        Group {
            if copiedToClipboard {
                VStack {
                    Spacer()

                    Text("Copied to clipboard")
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(Typography.Scripture.heading)
                        .foregroundStyle(Color.textPrimary)
                        .padding(.horizontal, Theme.Spacing.lg + 4)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Color.surfaceRaised)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(Theme.Opacity.medium), radius: 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                    // swiftlint:disable:next hardcoded_spacer_frame
                    Spacer().frame(height: 100)
                }
            }
        }
        // swiftlint:disable:next hardcoded_animation_spring
        .animation(Theme.Animation.settle, value: copiedToClipboard)
    }

    // MARK: - Helpers

    private func setupAudioPlayer() {
        // Gather waveform samples from chunks
        var allSamples: [Float] = []
        for chunk in flowState.audioChunks {
            if let samples = chunk.waveformSamples {
                allSamples.append(contentsOf: samples)
            }
        }
        viewModel.waveformSamples = allSamples.isEmpty ? Array(repeating: 0.3, count: 100) : allSamples

        // Set duration
        viewModel.duration = Double(flowState.currentSermon?.durationSeconds ?? 0)

        // Load audio URLs
        Task {
            do {
                guard let sermon = flowState.currentSermon else { return }
                let urls = try await SermonSyncService.shared.getChunkURLs(sermonId: sermon.id)
                await MainActor.run {
                    viewModel.loadAudio(urls: urls)
                }
            } catch {
                print("[SermonViewingPhase] Failed to load audio: \(error)")
            }
        }

        // Setup transcript sync
        if let transcript = flowState.currentTranscript {
            viewModel.segments = transcript.segments
        }
    }

    private func copyTranscript() {
        guard let transcript = flowState.currentTranscript else { return }
        UIPasteboard.general.string = transcript.content

        HapticService.shared.success()
        copiedToClipboard = true

        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                copiedToClipboard = false
            }
        }
    }

    private func generateShareText() -> String? {
        guard let sermon = flowState.currentSermon else { return nil }

        var text = """
        \(sermon.displayTitle)
        """

        if let speaker = sermon.speakerName {
            text += "\nBy \(speaker)"
        }

        text += "\nRecorded: \(sermon.recordedAt.formatted(date: .long, time: .omitted))"
        text += "\nDuration: \(sermon.formattedDuration)"

        if let studyGuide = flowState.currentStudyGuide {
            text += "\n\n--- Summary ---\n\(studyGuide.content.summary)"

            if !studyGuide.content.keyThemes.isEmpty {
                text += "\n\n--- Key Themes ---"
                for theme in studyGuide.content.keyThemes {
                    text += "\n• \(theme)"
                }
            }
        }

        if let transcript = flowState.currentTranscript {
            text += "\n\n--- Transcript ---\n\(transcript.content)"
        }

        return text
    }
}

// MARK: - Sermon Viewing ViewModel

@MainActor
@Observable
final class SermonViewingViewModel {
    // Audio state
    var isPlaying: Bool = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var progress: Double = 0
    var playbackSpeed: Float = 1.0

    // Waveform
    var waveformSamples: [Float] = []

    // Transcript sync
    var segments: [TranscriptDisplaySegment] = []
    var currentSegmentIndex: Int?

    // Private
    private var player: AVQueuePlayer?
    private var timeObserver: Any?

    // Computed
    var currentTimeFormatted: String {
        formatTime(currentTime)
    }

    var durationFormatted: String {
        formatTime(duration)
    }

    // MARK: - Audio Loading

    func loadAudio(urls: [URL]) {
        guard !urls.isEmpty else { return }

        let items = urls.map { AVPlayerItem(url: $0) }
        player = AVQueuePlayer(items: items)
        player?.rate = playbackSpeed

        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[SermonViewingViewModel] Audio session error: \(error)")
        }

        // Time observer
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                self?.updateTime(time)
            }
        }
    }

    private func updateTime(_ time: CMTime) {
        currentTime = CMTimeGetSeconds(time)
        progress = duration > 0 ? currentTime / duration : 0

        // Update current segment (binary search)
        updateCurrentSegment()
    }

    private func updateCurrentSegment() {
        guard !segments.isEmpty else { return }

        // Binary search for current segment
        var low = 0
        var high = segments.count - 1
        var result: Int?

        while low <= high {
            let mid = (low + high) / 2
            let segment = segments[mid]

            if currentTime >= segment.startTime && currentTime < segment.endTime {
                result = mid
                break
            } else if currentTime < segment.startTime {
                high = mid - 1
            } else {
                low = mid + 1
            }
        }

        if result != currentSegmentIndex {
            currentSegmentIndex = result
        }
    }

    // MARK: - Playback Controls

    func togglePlayPause() {
        guard let player = player else { return }

        if isPlaying {
            player.pause()
        } else {
            player.play()
            player.rate = playbackSpeed
        }
        isPlaying.toggle()
    }

    func seek(to progress: Double) {
        let targetTime = duration * progress
        seekToTime(targetTime)
    }

    func seekToTime(_ time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
    }

    func seekForward(_ seconds: Double) {
        let targetTime = min(currentTime + seconds, duration)
        seekToTime(targetTime)
    }

    func seekBackward(_ seconds: Double) {
        let targetTime = max(currentTime - seconds, 0)
        seekToTime(targetTime)
    }

    func setPlaybackSpeed(_ speed: Float) {
        playbackSpeed = speed
        if isPlaying {
            player?.rate = speed
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        player?.pause()
        player = nil

        try? AVAudioSession.sharedInstance().setActive(false)
    }

    // MARK: - Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Waveform Scrubber

struct SermonWaveformScrubber: View {
    let samples: [Float]
    let progress: Double
    let onSeek: (Double) -> Void

    @State private var isDragging = false
    @State private var dragProgress: Double = 0

    private var displayProgress: Double {
        isDragging ? dragProgress : progress
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background waveform
                WaveformShape(samples: samples)
                    .fill(Color.surfaceRaised)

                // Played portion
                WaveformShape(samples: samples)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentBronze, Color.decorativeGold.opacity(0.15)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .mask(
                        Rectangle()
                            .frame(width: geo.size.width * displayProgress)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    )

                // Playhead
                Circle()
                    .fill(Color.accentBronze)
                    .frame(width: isDragging ? 20 : 14, height: isDragging ? 20 : 14)
                    .shadow(color: Color.accentBronze.opacity(Theme.Opacity.heavy), radius: isDragging ? 8 : 4)
                    .position(
                        x: geo.size.width * displayProgress,
                        y: geo.size.height / 2
                    )
                    // swiftlint:disable:next hardcoded_animation_spring
                    .animation(Theme.Animation.settle, value: isDragging)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let newProgress = max(0, min(1, value.location.x / geo.size.width))
                        dragProgress = newProgress
                    }
                    .onEnded { value in
                        isDragging = false
                        let finalProgress = max(0, min(1, value.location.x / geo.size.width))
                        onSeek(finalProgress)
                        HapticService.shared.selectionChanged()
                    }
            )
        }
        .frame(height: 48)
    }
}

// MARK: - Waveform Shape

struct WaveformShape: Shape {
    let samples: [Float]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard !samples.isEmpty else { return path }

        let barWidth: CGFloat = 3
        let spacing: CGFloat = 2
        let totalWidth = CGFloat(samples.count) * (barWidth + spacing)
        let scale = rect.width / max(totalWidth, 1)

        for (index, sample) in samples.enumerated() {
            let normalizedSample = CGFloat(min(max(sample, 0), 1))
            let height = max(4, normalizedSample * rect.height * 0.9)
            let x = CGFloat(index) * (barWidth + spacing) * scale
            let y = (rect.height - height) / 2

            let barRect = CGRect(x: x, y: y, width: barWidth * scale, height: height)
            path.addRoundedRect(in: barRect, cornerSize: CGSize(width: 1.5, height: 1.5))
        }

        return path
    }
}

// MARK: - Transcript Content View

struct TranscriptContentView: View {
    let segments: [TranscriptDisplaySegment]
    let currentSegmentIndex: Int?
    let onSegmentTap: (TranscriptDisplaySegment) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Drop cap for first segment
            if let first = segments.first {
                DropCapText(
                    text: first.text,
                    isHighlighted: currentSegmentIndex == 0
                )
                .id("segment-0")
                .onTapGesture { onSegmentTap(first) }
            }

            // Remaining segments
            ForEach(Array(segments.dropFirst().enumerated()), id: \.element.id) { index, segment in
                Text(segment.text)
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color.textPrimary)
                    // swiftlint:disable:next hardcoded_line_spacing
                    .lineSpacing(8)
                    .padding(.vertical, Theme.Spacing.sm)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        currentSegmentIndex == index + 1
                            ? Color.accentBronze.opacity(Theme.Opacity.subtle)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                    .id("segment-\(index + 1)")
                    .onTapGesture { onSegmentTap(segment) }
            }
        }
    }
}

// MARK: - Drop Cap Text

struct DropCapText: View {
    let text: String
    let isHighlighted: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Drop cap letter
            Text(String(text.prefix(1)))
                // swiftlint:disable:next hardcoded_font_custom
                .font(Typography.Scripture.display)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentBronze, Color.decorativeGold.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52, alignment: .center)

            // Remaining text
            Text(String(text.dropFirst()))
                // swiftlint:disable:next hardcoded_font_custom
                .font(Typography.Scripture.body)
                .foregroundStyle(Color.textPrimary)
                // swiftlint:disable:next hardcoded_line_spacing
                .lineSpacing(8)
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isHighlighted
                ? Color.accentBronze.opacity(Theme.Opacity.subtle)
                : Color.surfaceRaised.opacity(Theme.Opacity.medium)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
    }
}

// MARK: - Study Guide Section

struct StudyGuideSection<Content: View>: View {
    let title: String
    let icon: String
    var isExpandedByDefault: Bool = false
    @ViewBuilder let content: () -> Content

    @State private var isExpanded: Bool

    init(
        title: String,
        icon: String,
        isExpandedByDefault: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.isExpandedByDefault = isExpandedByDefault
        self.content = content
        self._isExpanded = State(initialValue: isExpandedByDefault)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (tappable)
            Button {
                withAnimation(Theme.Animation.settle) {
                    isExpanded.toggle()
                }
                HapticService.shared.selectionChanged()
            } label: {
                HStack {
                    Image(systemName: icon)
                        .font(Typography.Icon.md)
                        .foregroundStyle(Color.accentBronze)
                        .frame(width: 24)

                    Text(title.uppercased())
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(Typography.Scripture.heading)
                        .foregroundStyle(Color.textPrimary)
                        // swiftlint:disable:next hardcoded_tracking
                        .tracking(2)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(Typography.Icon.sm.weight(.medium))
                        .foregroundStyle(Color.accentBronze)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(Theme.Spacing.lg)
            }
            .buttonStyle(.plain)

            // Content (animated)
            if isExpanded {
                content()
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.lg)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }

            Divider()
                .background(Color.accentBronze.opacity(Theme.Opacity.light))
        }
    }
}

// MARK: - Study Guide Section With Legend (for Scripture References)

struct StudyGuideSectionWithLegend<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (tappable)
            Button {
                withAnimation(Theme.Animation.settle) {
                    isExpanded.toggle()
                }
                HapticService.shared.selectionChanged()
            } label: {
                HStack {
                    Image(systemName: icon)
                        .font(Typography.Icon.md)
                        .foregroundStyle(Color.accentBronze)
                        .frame(width: 24)

                    Text(title.uppercased())
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(Typography.Scripture.heading)
                        .foregroundStyle(Color.textPrimary)
                        // swiftlint:disable:next hardcoded_tracking
                        .tracking(2)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(Typography.Icon.sm.weight(.medium))
                        .foregroundStyle(Color.accentBronze)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(Theme.Spacing.lg)
            }
            .buttonStyle(.plain)

            // Content (animated)
            if isExpanded {
                content()
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.lg)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }

            Divider()
                .background(Color.accentBronze.opacity(Theme.Opacity.light))
        }
    }
}

// MARK: - Discussion Question Card

struct DiscussionQuestionCard: View {
    let question: StudyQuestion
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Question header
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                // Index
                Text("\(index)")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(Typography.Scripture.display)
                    .foregroundStyle(Color.accentBronze)
                    .frame(width: 28, height: 28)
                    .background(Color.surfaceRaised)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    // Type badge
                    Text(question.type.displayName.uppercased())
                        .font(Typography.Command.meta.weight(.semibold))
                        .foregroundStyle(Color.accentBronze)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(Color.accentBronze.opacity(Theme.Opacity.light))
                        .clipShape(Capsule())

                    // Question text
                    Text(question.question)
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(Typography.Scripture.body)
                        .foregroundStyle(Color.textPrimary)
                }
            }

            // Discussion hint
            if let hint = question.discussionHint {
                Text(hint)
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color.textSecondary)
                    .italic()
                    // swiftlint:disable:next hardcoded_padding_edge
                    .padding(.leading, 40)
            }

            // Related verses
            if let verses = question.relatedVerses, !verses.isEmpty {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "book")
                        .font(Typography.Icon.xxs)
                        .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.overlay))

                    Text(verses.joined(separator: ", "))
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(Typography.Scripture.body)
                        .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.pressed))
                }
                // swiftlint:disable:next hardcoded_padding_edge
                .padding(.leading, 40)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Color.surfaceRaised.opacity(Theme.Opacity.disabled))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
    }
}

// MARK: - Scripture Reference Chip

struct ScriptureReferenceChip: View {
    let reference: SermonVerseReference
    let isMentioned: Bool
    @State private var showDetail = false

    var body: some View {
        Button {
            HapticService.shared.lightTap()
            showDetail = true
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "book.closed")
                    .font(Typography.Icon.xs)

                Text(reference.reference)
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(Typography.Scripture.body)

                // Verification indicator (only for suggested refs with status)
                if !isMentioned, let status = reference.verificationStatus {
                    VerificationStatusIndicator(status: status)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .foregroundStyle(chipForegroundColor)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
            .background(chipBackground)
            .clipShape(Capsule())
            .overlay(chipBorder)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            ScriptureReferenceDetailSheet(reference: reference)
        }
    }

    private var chipForegroundColor: Color {
        if isMentioned { return Color.accentBronze }
        switch reference.verificationStatus {
        case .verified: return Color.accentBronze.opacity(Theme.Opacity.high)
        case .partial: return Color(hex: "6B5844").opacity(Theme.Opacity.pressed)
        case .unverified, .unknown, .none: return Color.textSecondary
        }
    }

    private var chipBackground: some View {
        Group {
            if isMentioned {
                Color.accentBronze.opacity(Theme.Opacity.light)
            } else if reference.verificationStatus == .verified {
                Color.accentBronze.opacity(Theme.Opacity.subtle)
            } else {
                Color.surfaceRaised
            }
        }
    }

    private var chipBorder: some View {
        Capsule().stroke(
            isMentioned ? Color.accentBronze.opacity(Theme.Opacity.medium) :
            reference.verificationStatus == .verified ? Color.accentBronze.opacity(Theme.Opacity.lightMedium) :
            Color.textSecondary.opacity(Theme.Opacity.light),
            lineWidth: Theme.Stroke.hairline
        )
    }
}

// MARK: - Flow Layout

struct SermonFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)

        for (index, placement) in result.placements.enumerated() {
            subviews[index].place(
                at: CGPoint(
                    x: bounds.minX + placement.x,
                    y: bounds.minY + placement.y
                ),
                proposal: ProposedViewSize(placement.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, placements: [Placement]) {
        let maxWidth = proposal.width ?? .infinity

        var placements: [Placement] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            placements.append(Placement(x: currentX, y: currentY, size: size))

            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), placements)
    }

    private struct Placement {
        let x: CGFloat
        let y: CGFloat
        let size: CGSize
    }
}

// MARK: - Sermon Action Button Style

struct SermonActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.accentBronze)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(Color.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(Color.accentBronze.opacity(Theme.Opacity.medium), lineWidth: Theme.Stroke.hairline)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            // swiftlint:disable:next hardcoded_animation_spring
            .animation(Theme.Animation.settle, value: configuration.isPressed)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    let flowState = SermonFlowState()

    // Mock data
    flowState.currentSermon = Sermon(
        userId: UUID(),
        title: "The Power of Grace",
        speakerName: "Pastor John",
        recordedAt: Date(),
        durationSeconds: 2700
    )

    flowState.currentTranscript = SermonTranscript(
        sermonId: flowState.currentSermon!.id,
        content: "So today we're going to be talking about grace. What is grace? Grace is unmerited favor from God. It's something we don't deserve, but God freely gives it to us anyway. In Ephesians 2:8-9, Paul writes, 'For by grace you have been saved through faith, and this is not your own doing; it is the gift of God, not a result of works, so that no one may boast.' This passage reminds us that salvation comes entirely from God's grace, not from anything we could ever do to earn it.",
        wordTimestamps: []
    )

    flowState.currentStudyGuide = SermonStudyGuide(
        sermonId: flowState.currentSermon!.id,
        content: StudyGuideContent(
            title: "The Power of Grace",
            summary: "This sermon explores the foundational Christian concept of grace as unmerited favor from God. Pastor John emphasizes that grace cannot be earned through works but is freely given, as expressed in Ephesians 2:8-9.",
            keyThemes: [
                "Grace as unmerited favor",
                "Salvation through faith alone",
                "The gift of God's love"
            ],
            bibleReferencesMentioned: [
                SermonVerseReference(reference: "Ephesians 2:8-9", bookId: nil, chapter: 2, verseStart: 8, verseEnd: 9, isMentioned: true, rationale: nil, timestampSeconds: 120)
            ],
            bibleReferencesSuggested: [
                SermonVerseReference(
                    reference: "Romans 5:8",
                    bookId: 45, chapter: 5, verseStart: 8, verseEnd: nil,
                    isMentioned: false,
                    rationale: "Related passage on God's love",
                    verificationStatus: .verified,
                    verifiedBy: ["49.2.8"]
                ),
                SermonVerseReference(
                    reference: "Titus 3:5",
                    bookId: 56, chapter: 3, verseStart: 5, verseEnd: nil,
                    isMentioned: false,
                    rationale: "Salvation not by works",
                    verificationStatus: .partial
                ),
                SermonVerseReference(
                    reference: "John 1:17",
                    bookId: 43, chapter: 1, verseStart: 17, verseEnd: nil,
                    isMentioned: false,
                    rationale: "Grace came through Jesus",
                    verificationStatus: .unverified
                )
            ],
            discussionQuestions: [
                StudyQuestion(question: "How does understanding grace as 'unmerited favor' change your relationship with God?", type: .application, relatedVerses: ["Ephesians 2:8-9"], discussionHint: "Consider times when you've felt unworthy of God's love"),
                StudyQuestion(question: "Why do you think Paul emphasizes that salvation is 'not a result of works'?", type: .interpretation)
            ],
            reflectionPrompts: [
                "Take a moment to thank God for His grace in your life today",
                "Consider how you might extend grace to someone who has wronged you"
            ],
            applicationPoints: [
                "Rest in God's grace rather than striving to earn His approval",
                "Share the message of grace with someone who needs to hear it",
                "Practice extending unmerited favor to others in your daily life"
            ]
        )
    )

    return SermonViewingPhase(flowState: flowState)
        .preferredColorScheme(.dark)
}

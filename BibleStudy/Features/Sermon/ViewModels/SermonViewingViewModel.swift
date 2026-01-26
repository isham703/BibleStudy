import SwiftUI
import AVFoundation

// MARK: - Sermon Viewing ViewModel
// Manages audio playback state and transcript synchronization

@MainActor
@Observable
final class SermonViewingViewModel {
    // MARK: - Audio State

    var isPlaying: Bool = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var progress: Double = 0
    var playbackSpeed: Float = 1.0

    // MARK: - Waveform

    var waveformSamples: [Float] = []

    // MARK: - Transcript Sync

    var segments: [TranscriptDisplaySegment] = []
    var currentSegmentIndex: Int?

    // MARK: - Private

    nonisolated(unsafe) private var player: AVQueuePlayer?
    nonisolated(unsafe) private var timeObserver: Any?
    private var isAudioLoaded = false

    // MARK: - Computed Properties

    var currentTimeFormatted: String {
        formatTime(currentTime)
    }

    var durationFormatted: String {
        formatTime(duration)
    }

    // MARK: - Audio Loading

    func loadAudio(urls: [URL]) {
        guard !urls.isEmpty, !isAudioLoaded else { return }

        let items = urls.map { AVPlayerItem(url: $0) }
        player = AVQueuePlayer(items: items)
        // Don't auto-play - wait for user to tap play
        player?.pause()

        // Claim audio session for sermon playback (lower priority than recording)
        if !AudioService.shared.pushAudioSession(mode: .sermonPlayback, owner: "SermonViewingViewModel") {
            print("[SermonViewingViewModel] Warning: Failed to configure audio session for playback")
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

        isAudioLoaded = true
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

    /// Seeks to time and starts playback (used by outline, timestamps, etc.)
    func seekAndPlay(_ time: TimeInterval) {
        seekToTime(time)
        if !isPlaying {
            player?.play()
            player?.rate = playbackSpeed
            isPlaying = true
        }
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
        // Update rate immediately if player is actively playing (rate > 0)
        // Using actual player rate instead of isPlaying state for reliability
        if let player = player, player.rate > 0 {
            player.rate = speed
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        player?.pause()
        player = nil
        isAudioLoaded = false

        // Release audio session claim
        AudioService.shared.popAudioSession(owner: "SermonViewingViewModel")
    }

    deinit {
        // AVPlayer operations are thread-safe
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        player?.pause()

        // AudioService requires MainActor
        Task { @MainActor in
            AudioService.shared.popAudioSession(owner: "SermonViewingViewModel")
        }
    }

    // MARK: - Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        TimestampFormatter.format(time)
    }
}

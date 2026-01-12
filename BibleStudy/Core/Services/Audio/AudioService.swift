import Foundation
import AVFoundation
import MediaPlayer
import Combine
import UIKit

// MARK: - Audio Service
// Manages Bible audio playback with verse synchronization

@MainActor
@Observable
final class AudioService: NSObject {
    // MARK: - Singleton
    static let shared = AudioService()

    // MARK: - Player
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?

    // MARK: - State
    private(set) var playbackState: PlaybackState = .idle
    private(set) var currentChapter: AudioChapter?
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var isLoading: Bool = false
    private(set) var error: AudioError?
    private(set) var generationProgress: Double = 0 // 0.0 to 1.0 during TTS generation
    private(set) var isGeneratingAudio: Bool = false

    // MARK: - Interruption State
    private var wasPlayingBeforeInterruption: Bool = false
    private var boundaryTimeObserver: Any?
    private var nextBoundaryIndex: Int = 0  // Track which boundary will fire next
    private var shouldResumeAfterReload: Bool = false
    private var isReloadingComposition: Bool = false  // Suppress UI updates during reload

    // MARK: - Settings
    var playbackRate: Float = 1.0 {
        didSet {
            player?.rate = playbackState == .playing ? playbackRate : 0
        }
    }

    // MARK: - Sleep Timer
    private var sleepTimer: Timer?
    private(set) var sleepTimerRemaining: TimeInterval = 0
    private(set) var sleepTimerEndOfChapter: Bool = false

    var isSleepTimerActive: Bool {
        sleepTimer != nil || sleepTimerEndOfChapter
    }

    var formattedSleepTimerRemaining: String {
        if sleepTimerEndOfChapter {
            return "End of chapter"
        }
        guard sleepTimerRemaining > 0 else { return "" }
        let minutes = Int(sleepTimerRemaining) / 60
        let seconds = Int(sleepTimerRemaining) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    // MARK: - Computed Properties

    var isPlaying: Bool {
        playbackState == .playing
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    /// Current verse number derived from boundary index
    /// Current verse is the one BEFORE the next boundary (which hasn't fired yet)
    var currentVerse: Int? {
        guard let chapter = currentChapter, !chapter.verseTimings.isEmpty else { return nil }
        // nextBoundaryIndex points to the NEXT boundary that will fire
        // So current verse is at index (nextBoundaryIndex - 1), clamped to valid range
        let verseIndex = max(0, nextBoundaryIndex - 1)
        guard verseIndex < chapter.verseTimings.count else { return nil }
        return chapter.verseTimings[verseIndex].verseNumber
    }

    var formattedCurrentTime: String {
        formatTime(currentTime)
    }

    var formattedDuration: String {
        formatTime(duration)
    }

    // MARK: - State Transitions

    /// Centralized state setter that always posts notifications
    private func setPlaybackState(_ newState: PlaybackState) {
        guard playbackState != newState else { return }
        playbackState = newState
        NotificationCenter.default.post(name: .audioPlaybackStateChanged, object: nil, userInfo: ["state": newState])
    }

    // MARK: - Initialization

    private override init() {
        super.init()
        setupAudioSession()
        setupInterruptionHandling()
        setupRouteChangeHandling()
        setupRemoteCommands()
    }

    // Note: No deinit needed as this is a singleton

    // MARK: - Audio Session

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // Use .spokenAudio mode for continuous spoken audio like podcasts/audiobooks
            // This enables proper background playback and lock screen behavior
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true)
        } catch {
            print("AudioService: Failed to setup audio session: \(error)")
            // Try fallback with minimal configuration
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: [])
                try session.setActive(true)
                print("AudioService: Using fallback audio session configuration")
            } catch {
                print("AudioService: Fallback also failed: \(error)")
            }
        }
    }

    // MARK: - Interruption Handling

    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            // Extract Sendable values before Task to avoid capturing non-Sendable types
            let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            Task { @MainActor [weak self] in
                self?.handleInterruption(typeValue: typeValue, optionsValue: optionsValue)
            }
        }
    }

    private func handleInterruption(typeValue: UInt?, optionsValue: UInt?) {
        guard let typeValue,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            // Save state and pause
            wasPlayingBeforeInterruption = isPlaying
            if isPlaying {
                pause()
            }
        case .ended:
            // Resume if we were playing and system says we should
            if let optionsValue {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) && wasPlayingBeforeInterruption {
                    play()
                }
            }
            wasPlayingBeforeInterruption = false
        @unknown default:
            break
        }
    }

    // MARK: - Route Change Handling

    private func setupRouteChangeHandling() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // Extract Sendable value before Task to avoid capturing non-Sendable types
            let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            Task { @MainActor [weak self] in
                self?.handleRouteChange(reasonValue: reasonValue)
            }
        }
    }

    private func handleRouteChange(reasonValue: UInt?) {
        guard let reasonValue,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        // Pause when headphones are unplugged to avoid surprise speaker playback
        if reason == .oldDeviceUnavailable {
            if isPlaying {
                pause()
            }
        }
    }

    // MARK: - Remote Commands (Lock Screen / Control Center)

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self, self.player != nil else {
                return .noActionableNowPlayingItem
            }
            self.play()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self, self.player != nil else {
                return .noActionableNowPlayingItem
            }
            self.pause()
            return .success
        }

        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            guard let self, self.player != nil else {
                return .noActionableNowPlayingItem
            }
            self.skipForward(seconds: 15)
            return .success
        }

        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            guard let self, self.player != nil else {
                return .noActionableNowPlayingItem
            }
            self.skipBackward(seconds: 15)
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self, self.player != nil else {
                return .noActionableNowPlayingItem
            }
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seek(to: positionEvent.positionTime)
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        guard let chapter = currentChapter else { return }

        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: "\(chapter.bookName) \(chapter.chapterNumber)",
            MPMediaItemPropertyArtist: "Bible Study",
            MPMediaItemPropertyAlbumTitle: chapter.translation,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? playbackRate : 0
        ]

        // Add artwork if available
        if let image = UIImage(named: "AppIcon") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    // MARK: - Playback Control

    /// Load and prepare audio for a chapter using HLS streaming
    func loadChapter(_ chapter: AudioChapter) async {
        // Stop current playback
        stop()

        isLoading = true
        error = nil
        currentChapter = chapter

        // Set state to ready immediately so mini player appears during loading
        setPlaybackState(.ready)

        // Check for cached HLS manifest first (instant playback)
        if AudioCache.shared.hasCompleteHLSManifest(for: chapter),
           let cachedResult = AudioCache.shared.getCachedAudioWithTimings(for: chapter) {
            print("[AudioService] Using cached HLS manifest for \(chapter.bookName) \(chapter.chapterNumber)")

            do {
                try await loadHLSManifest(cachedResult.url, chapter: chapter, timings: cachedResult.timings)
                isLoading = false
                print("[AudioService] Cached HLS manifest loaded successfully")
                return
            } catch {
                // Cached manifest failed to load (possibly old format with absolute URLs)
                print("[AudioService] Cached HLS manifest failed to load: \(error.localizedDescription)")
                print("[AudioService] Invalidating cache and regenerating...")

                // Delete invalid manifest and segments
                try? await getHLSManifestManager().delete(chapter: chapter)

                // Fall through to regeneration
            }
        }

        // If a prefetch is already in progress for this chapter, start from quick-start when ready
        if prefetchingChapterKey == chapter.cacheKey, let task = prefetchTask {
            print("[AudioService] Awaiting prefetch quick-start for \(chapter.bookName) \(chapter.chapterNumber)")
            do {
                let (manifestURL, timings) = try await awaitPrefetchQuickStart(cacheKey: chapter.cacheKey)
                try await loadHLSManifest(manifestURL, chapter: chapter, timings: timings)
                isLoading = false
                shouldResumeAfterReload = true
                play()
                print("[AudioService] Playback started (prefetch quick-start)")

                Task { @MainActor [weak self] in
                    guard let self else { return }
                    do {
                        let result = try await task.value
                        guard self.currentChapter?.cacheKey == chapter.cacheKey else { return }
                        await self.reloadFullComposition(
                            manifestURL: result.manifestURL,
                            chapter: chapter,
                            timings: result.verseTimings
                        )
                    } catch {
                        if !Task.isCancelled {
                            print("[AudioService] Prefetch completion failed: \(error.localizedDescription)")
                        }
                    }
                }

                return
            } catch {
                if !Task.isCancelled {
                    print("[AudioService] Prefetch quick-start failed: \(error.localizedDescription)")
                }
                // Fall through to regular generation
            }
        }

        // Generate HLS segments with progress feedback
        print("[AudioService] Starting HLS generation for \(chapter.bookName) \(chapter.chapterNumber)")

        // Generate with quick-start playback, then reload when full generation completes
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let result = try await self.getHLSGenerator().generateProgressive(
                    chapter: chapter,
                    priority: .interactive,
                    onProgress: { [weak self] progress in
                        guard let self = self else { return }
                        await MainActor.run {
                            self.generationProgress = progress
                        }
                    },
                    onQuickStart: { [weak self] manifestURL, timings in
                        guard let self else { return }
                        await self.startQuickStartPlayback(
                            manifestURL: manifestURL,
                            chapter: chapter,
                            timings: timings
                        )
                    },
                    onProgressiveUpdate: { [weak self] manifestURL, timings in
                        guard let self else { return }
                        await self.reloadProgressively(
                            manifestURL: manifestURL,
                            chapter: chapter,
                            timings: timings
                        )
                    }
                )

                // Generation complete - reload full composition
                print("[AudioService] Generation complete with \(result.verseTimings.count) verses")
                await self.reloadFullComposition(
                    manifestURL: result.manifestURL,
                    chapter: chapter,
                    timings: result.verseTimings
                )
            } catch {
                print("[AudioService] Generation failed: \(error)")
                self.error = .generationFailed
                self.isLoading = false
            }
        }
    }

    @MainActor
    private func startQuickStartPlayback(
        manifestURL: URL,
        chapter: AudioChapter,
        timings: [VerseTiming]
    ) async {
        do {
            try await loadHLSManifest(manifestURL, chapter: chapter, timings: timings)
            isLoading = false
            shouldResumeAfterReload = true
            play()
            print("[AudioService] Quick-start playback started")
        } catch {
            print("[AudioService] Failed to load quick-start manifest: \(error.localizedDescription)")
        }
    }

    /// Load HLS manifest into AVPlayer using AVMutableComposition
    /// Builds composition from segments for reliable local playback
    private func loadHLSManifest(_ url: URL, chapter: AudioChapter, timings: [VerseTiming]) async throws {
        print("[AudioService] Loading HLS segments from manifest: \(url.path)")

        // Parse manifest to get segment URLs
        guard let manifestContent = try? String(contentsOf: url, encoding: .utf8) else {
            throw AudioError.loadFailed("Failed to read manifest file")
        }

        let cacheDirectory = AudioCache.shared.cacheDirectory
        var segmentURLs: [URL] = []

        // Extract segment filenames from manifest (lines without #)
        let lines = manifestContent.components(separatedBy: .newlines)
        for line in lines where !line.hasPrefix("#") && !line.isEmpty {
            let segmentURL = cacheDirectory.appendingPathComponent(line)
            segmentURLs.append(segmentURL)
        }

        guard !segmentURLs.isEmpty else {
            throw AudioError.loadFailed("No segments found in manifest")
        }

        print("[AudioService] Found \(segmentURLs.count) segments in manifest")

        // Create composition by stitching segments together
        let composition = AVMutableComposition()
        guard let audioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw AudioError.loadFailed("Failed to create audio track")
        }

        var currentTime = CMTime.zero

        // Load each segment and append to composition
        for (index, segmentURL) in segmentURLs.enumerated() {
            let asset = AVURLAsset(url: segmentURL)

            // Load tracks and duration
            let (tracks, assetDuration) = try await asset.load(.tracks, .duration)
            guard let assetTrack = tracks.first(where: { $0.mediaType == .audio }) else {
                print("[AudioService] Warning: No audio track in segment \(index + 1)")
                continue
            }

            // Append segment to composition
            let timeRange = CMTimeRange(start: .zero, duration: assetDuration)
            try audioTrack.insertTimeRange(timeRange, of: assetTrack, at: currentTime)
            currentTime = CMTimeAdd(currentTime, assetDuration)

            print("[AudioService] Loaded segment \(index + 1)/\(segmentURLs.count)")
        }

        duration = CMTimeGetSeconds(currentTime)

        // Use exact timings from generation (preserves TTS-calculated durations)
        currentChapter?.setVerseTimings(timings)
        print("[AudioService] Using \(timings.count) verse timings from generation")

        // Create player item and player
        playerItem = AVPlayerItem(asset: composition)
        player = AVPlayer(playerItem: playerItem)
        player?.rate = 0 // Start paused

        // Setup time observer for UI updates (0.25s interval)
        setupTimeObserver()

        // Setup boundary time observer for precise verse transitions
        setupBoundaryTimeObserver()

        setPlaybackState(.ready)
        updateNowPlayingInfo()

        print("[AudioService] Composition loaded - \(segmentURLs.count) segments, \(String(format: "%.1f", duration))s total")
    }

    /// Reload composition with all segments while preserving playback position
    /// Defers reload during active playback to avoid audio glitches
    private func reloadFullComposition(manifestURL: URL, chapter: AudioChapter, timings: [VerseTiming]) async {
        let wasPlaying = isPlaying
        let wasFinished = playbackState == .finished  // Audio ran out but more verses available
        let savedTime = currentTime
        // Resume if was playing, was finished (more verses available), or flag is set
        let shouldResume = shouldResumeAfterReload || wasPlaying || wasFinished
        // CRITICAL: Use actual loaded audio duration, not verse timings
        let actualLoadedDuration = duration
        let remainingBuffer = actualLoadedDuration - savedTime

        shouldResumeAfterReload = false

        // If actively playing with plenty of buffer, defer the reload
        // Just update timings - the full reload will happen when buffer runs low
        // or when user pauses/seeks
        let criticalBufferThreshold: TimeInterval = 10.0
        if wasPlaying && remainingBuffer > criticalBufferThreshold {
            currentChapter?.setVerseTimings(timings)
            pendingFullReload = (manifestURL: manifestURL, chapter: chapter, timings: timings)
            print("[AudioService] Full reload deferred - buffer OK (\(String(format: "%.1f", remainingBuffer))s), timings updated to \(timings.count) verses")
            return
        }

        // Clear any pending reload since we're doing it now
        pendingFullReload = nil

        // Suppress UI updates during reload to prevent glitching
        isReloadingComposition = true

        do {
            try await loadHLSManifest(manifestURL, chapter: chapter, timings: timings)

            // Use async seek to wait for completion before allowing time updates
            if savedTime > 0 {
                await seekAsync(to: savedTime)
            }

            // Restore currentTime explicitly after reload
            currentTime = savedTime

            // Only reset flag AFTER seek completes to prevent glitchy time updates
            isReloadingComposition = false

            if shouldResume {
                play()
                print("[AudioService] Full composition reloaded with \(timings.count) verses, resuming playback")
            } else {
                print("[AudioService] Full composition reloaded with \(timings.count) verses")
            }
        } catch {
            isReloadingComposition = false
            print("[AudioService] Failed to reload full composition: \(error.localizedDescription)")
        }
    }

    /// Pending full reload to apply when safe (paused or buffer low)
    private var pendingFullReload: (manifestURL: URL, chapter: AudioChapter, timings: [VerseTiming])?

    /// Apply pending reload if exists (called when user pauses or buffer gets low)
    private func applyPendingReloadIfNeeded() async {
        guard let pending = pendingFullReload else { return }
        pendingFullReload = nil

        print("[AudioService] Applying deferred full reload...")
        await reloadFullComposition(
            manifestURL: pending.manifestURL,
            chapter: pending.chapter,
            timings: pending.timings
        )
    }

    /// Reload composition progressively during background generation
    /// Only reloads when buffer is critically low to avoid audio glitches
    @MainActor
    private func reloadProgressively(
        manifestURL: URL,
        chapter: AudioChapter,
        timings: [VerseTiming]
    ) async {
        let currentPosition = currentTime
        // CRITICAL: Use actual loaded audio duration, NOT verse timings
        // The `duration` property reflects what's actually loaded in the AVPlayer composition
        // Verse timings can be updated without reloading, but the player can only play what's loaded
        let actualLoadedDuration = duration
        let newBufferEnd = timings.last?.endTime ?? 0

        // Calculate remaining buffer based on ACTUAL loaded audio, not timings
        let remainingBuffer = actualLoadedDuration - currentPosition

        // CRITICAL: Don't reload during active playback unless buffer is nearly exhausted
        // Reloading causes audio glitches, so we only do it when absolutely necessary:
        // 1. Buffer is less than 8 seconds (must reload before audio stops)
        // 2. No current buffer exists (first load)
        // 3. Playback is paused or finished (safe to reload)
        let criticalBufferThreshold: TimeInterval = 8.0
        let isPausedOrFinished = playbackState == .paused || playbackState == .ready || playbackState == .finished

        let shouldReload = remainingBuffer < criticalBufferThreshold || actualLoadedDuration == 0 || isPausedOrFinished

        guard shouldReload else {
            // Just update verse timings metadata without rebuilding player
            // This allows currentVerse to update correctly without audio glitch
            currentChapter?.setVerseTimings(timings)
            // CRITICAL: Store as pending reload so it's applied when playback finishes or buffer runs low
            pendingFullReload = (manifestURL: manifestURL, chapter: chapter, timings: timings)
            print("[AudioService] Progressive update: timings updated to \(timings.count) verses, pending reload stored (actual buffer: \(String(format: "%.1f", remainingBuffer))s)")
            return
        }

        let wasPlaying = isPlaying
        let wasFinished = playbackState == .finished  // Audio ran out but more verses available
        let savedTime = currentPosition

        // Suppress UI updates during reload to prevent visual glitching
        isReloadingComposition = true

        do {
            try await loadHLSManifest(manifestURL, chapter: chapter, timings: timings)

            // Use async seek to wait for completion before allowing time updates
            if savedTime > 0 {
                await seekAsync(to: savedTime)
            }

            // Restore currentTime explicitly after reload
            currentTime = savedTime

            // Only reset flag AFTER seek completes to prevent glitchy time updates
            isReloadingComposition = false

            // Resume if was playing OR if playback finished (more verses are now available)
            if wasPlaying || wasFinished {
                play()
            }

            print("[AudioService] Progressive reload: \(timings.count) verses, position: \(String(format: "%.1f", savedTime))s, new buffer end: \(String(format: "%.1f", newBufferEnd))s, resumed: \(wasPlaying || wasFinished)")
        } catch {
            isReloadingComposition = false
            print("[AudioService] Progressive reload failed: \(error.localizedDescription)")
        }
    }

    /// Setup boundary time observer for precise verse transitions
    /// This is more accurate than polling with threshold comparison
    private func setupBoundaryTimeObserver() {
        guard let chapter = currentChapter, !chapter.verseTimings.isEmpty else { return }

        // Create CMTime values for each verse boundary
        let boundaryTimes = chapter.verseTimings.map { timing in
            CMTime(seconds: timing.startTime, preferredTimescale: 600) as NSValue
        }

        // Prime boundary index based on current playback position
        // This handles the case where AVPlayer doesn't fire the boundary at time 0
        // Find the first boundary that's AHEAD of current time
        let time = player?.currentTime().seconds ?? 0
        nextBoundaryIndex = chapter.verseTimings.firstIndex { timing in
            time < timing.startTime
        } ?? chapter.verseTimings.count

        print("[AudioService] Boundary observer setup - currentTime: \(time)s, nextBoundaryIndex: \(nextBoundaryIndex)")

        boundaryTimeObserver = player?.addBoundaryTimeObserver(
            forTimes: boundaryTimes,
            queue: .main
        ) { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleVerseBoundary()
            }
        }
    }

    /// Handle verse boundary crossing detected by boundary time observer
    /// Boundaries fire in sequential order as playback progresses
    private func handleVerseBoundary() {
        guard let chapter = currentChapter else { return }
        guard nextBoundaryIndex < chapter.verseTimings.count else { return }

        // The boundary that just fired corresponds to nextBoundaryIndex
        let timing = chapter.verseTimings[nextBoundaryIndex]

        // IMPORTANT: Increment BEFORE posting notification
        // This ensures currentVerse computed property returns the correct value
        // when UI components read it in response to the notification
        nextBoundaryIndex += 1

        print("[AudioService] Boundary crossed for verse \(timing.verseNumber) (nextBoundaryIndex now \(nextBoundaryIndex))")

        // Post notification - UI can now safely read currentVerse
        postVerseChanged(verseNumber: timing.verseNumber)
    }

    func play() {
        guard player != nil else { return }

        print("[AudioService] play() called - nextBoundaryIndex: \(nextBoundaryIndex), playbackState: \(playbackState)")

        // On initial playback, post notification for current verse
        if playbackState == .ready || playbackState == .paused {
            if let currentVerse = currentVerse {
                print("[AudioService] Posting initial verse notification: \(currentVerse)")
                postVerseChanged(verseNumber: currentVerse)
            }
        }

        player?.rate = playbackRate
        setPlaybackState(.playing)
        updateNowPlayingInfo()
    }

    func pause() {
        player?.pause()
        shouldResumeAfterReload = false
        setPlaybackState(.paused)
        updateNowPlayingInfo()

        // Apply any pending reload now that playback is paused (safe time)
        if pendingFullReload != nil {
            Task { @MainActor in
                await applyPendingReloadIfNeeded()
            }
        }
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    // MARK: - Temporary Pause (for Insights/Interruptions)

    /// Pause playback temporarily (e.g., when showing insight)
    /// Remembers playback state so it can be resumed later
    func pauseForInterruption() {
        if isPlaying {
            wasPlayingBeforeInterruption = true
            pause()
        } else {
            wasPlayingBeforeInterruption = false
        }
    }

    /// Resume playback if it was paused for an interruption
    /// Only resumes if playback was auto-paused (not user-paused)
    func resumeAfterInterruption() {
        if wasPlayingBeforeInterruption {
            play()
            wasPlayingBeforeInterruption = false
        }
    }

    func stop() {
        removeTimeObserver()
        removeBoundaryTimeObserver()
        cancelSleepTimer()
        player?.pause()
        player = nil
        playerItem = nil
        setPlaybackState(.idle)
        currentTime = 0
        duration = 0
        nextBoundaryIndex = 0
        shouldResumeAfterReload = false
        hasAttemptedPreGeneration = false
        pendingFullReload = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func removeBoundaryTimeObserver() {
        if let observer = boundaryTimeObserver {
            player?.removeTimeObserver(observer)
            boundaryTimeObserver = nil
        }
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
        updateBoundaryIndexAfterSeek(to: time)
        updateNowPlayingInfo()
    }

    /// Async seek that waits for the seek to complete before returning
    /// Used during composition reload to prevent time glitches
    private func seekAsync(to time: TimeInterval) async {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        currentTime = time  // Set immediately to suppress glitchy updates

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                continuation.resume()
            }
        }

        updateBoundaryIndexAfterSeek(to: time)
        updateNowPlayingInfo()
    }

    private func updateBoundaryIndexAfterSeek(to time: TimeInterval) {
        // Recalculate boundary index based on new position
        // Find the first boundary that's ahead of current time
        if let chapter = currentChapter {
            let newBoundaryIndex = chapter.verseTimings.firstIndex { timing in
                time < timing.startTime
            } ?? chapter.verseTimings.count

            if newBoundaryIndex != nextBoundaryIndex {
                print("[AudioService] Seek to \(time)s - adjusting boundary index from \(nextBoundaryIndex) to \(newBoundaryIndex)")
                nextBoundaryIndex = newBoundaryIndex
            }

            // Post notification for new current verse
            if let currentVerse = currentVerse {
                postVerseChanged(verseNumber: currentVerse)
            }
        }
    }

    private func postVerseChanged(verseNumber: Int) {
        guard let chapter = currentChapter else { return }
        NotificationCenter.default.post(
            name: .audioVerseChanged,
            object: nil,
            userInfo: [
                "verse": verseNumber,
                "bookId": chapter.bookId,
                "chapter": chapter.chapterNumber,
                "translation": chapter.translation
            ]
        )
    }

    func skipForward(seconds: TimeInterval = 15) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }

    func skipBackward(seconds: TimeInterval = 15) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }

    /// Jump to a specific verse
    func seekToVerse(_ verseNumber: Int) {
        guard let chapter = currentChapter,
              let timing = chapter.verseTimings.first(where: { $0.verseNumber == verseNumber }) else {
            return
        }
        seek(to: timing.startTime)
    }

    /// Go to next verse
    func nextVerse() {
        guard let chapter = currentChapter else { return }
        // Current verse index is (nextBoundaryIndex - 1), next verse is nextBoundaryIndex
        guard nextBoundaryIndex < chapter.verseTimings.count else { return }
        let nextTiming = chapter.verseTimings[nextBoundaryIndex]
        seek(to: nextTiming.startTime)
    }

    /// Go to previous verse
    func previousVerse() {
        guard let chapter = currentChapter else { return }
        // Current verse index is (nextBoundaryIndex - 1), previous is (nextBoundaryIndex - 2)
        let prevIndex = nextBoundaryIndex - 2
        guard prevIndex >= 0 else { return }
        let prevTiming = chapter.verseTimings[prevIndex]
        seek(to: prevTiming.startTime)
    }

    // MARK: - Sleep Timer

    /// Set a sleep timer for a specific duration in minutes
    func setSleepTimer(minutes: Int) {
        cancelSleepTimer()

        if minutes <= 0 { return }

        sleepTimerRemaining = TimeInterval(minutes * 60)
        sleepTimerEndOfChapter = false

        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }

                self.sleepTimerRemaining -= 1

                if self.sleepTimerRemaining <= 0 {
                    self.pause()
                    self.cancelSleepTimer()
                    NotificationCenter.default.post(name: .sleepTimerFired, object: nil)
                }
            }
        }
    }

    /// Set sleep timer to stop at end of current chapter
    func setSleepTimerEndOfChapter() {
        cancelSleepTimer()
        sleepTimerEndOfChapter = true
        sleepTimerRemaining = 0
    }

    /// Cancel active sleep timer
    func cancelSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        sleepTimerRemaining = 0
        sleepTimerEndOfChapter = false
    }

    // MARK: - Time Observer

    private func setupTimeObserver() {
        // Use 0.25s interval for UI updates (reduced from 0.1s for better performance)
        // This is sufficient for displaying time labels while reducing CPU usage
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            // Extract CMTime value before Task to avoid Sendable issues
            let seconds = CMTimeGetSeconds(time)
            Task { @MainActor [weak self] in
                self?.handleTimeUpdateWithSeconds(seconds)
            }
        }
    }

    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    private func handleTimeUpdateWithSeconds(_ seconds: TimeInterval) {
        // Suppress UI updates during composition reload to prevent glitching
        guard !isReloadingComposition else { return }

        currentTime = seconds
        // Note: Verse updates are handled by the boundary time observer for precise transitions
        // Do NOT call updateCurrentVerse() here - it causes flickering due to race conditions

        // Check if we need to apply a pending reload (buffer getting low)
        // CRITICAL: Use `duration` (actual loaded audio), not verse timings
        if pendingFullReload != nil {
            let remainingBuffer = duration - seconds
            if remainingBuffer < 5.0 {
                Task { @MainActor in
                    await applyPendingReloadIfNeeded()
                }
            }
        }

        // Pre-generation trigger (at 80% playback progress)
        let progress = duration > 0 ? currentTime / duration : 0
        if progress >= 0.8 && !isPreGenerating && currentChapter != nil {
            startPreGenerationIfNeeded()
        }

        // Check for end of playback
        if currentTime >= duration && duration > 0 {
            setPlaybackState(.finished)

            // CRITICAL: If there's a pending reload with more verses, apply it immediately
            // This handles the case where quick-start finished but background generation has more
            if pendingFullReload != nil {
                print("[AudioService] Playback finished with pending verses - triggering reload")
                Task { @MainActor in
                    await applyPendingReloadIfNeeded()
                }
                return  // Don't trigger sleep timer yet - more audio is coming
            }

            // Handle end-of-chapter sleep timer
            if sleepTimerEndOfChapter {
                pause()
                cancelSleepTimer()
                NotificationCenter.default.post(name: .sleepTimerFired, object: nil)
            }
        }
    }

    /// Start pre-generating next chapter during current playback
    private func startPreGenerationIfNeeded() {
        guard let current = currentChapter else { return }

        // Only attempt once per chapter
        if hasAttemptedPreGeneration || isPreGenerating {
            return
        }

        // Determine next chapter
        let nextChapterNumber = current.chapterNumber + 1

        hasAttemptedPreGeneration = true
        isPreGenerating = true

        preGenerationTask = Task { @MainActor [weak self] in
            guard let self = self else { return }

            // Create next chapter (simplified - in production, would need to fetch verse data)
            // For now, just log that we would pre-generate
            print("[AudioService] Would pre-generate \(current.bookName) \(nextChapterNumber)")

            // TODO: Integrate with BibleService to fetch next chapter verses
            // let nextChapter = try? await BibleService.shared.getChapter(...)
            // try? await getHLSGenerator().generateComplete(chapter: nextChapter, priority: .background)

            self.isPreGenerating = false
        }
    }

    // MARK: - Chapter Prefetch

    /// Prefetch task for background generation
    private var prefetchTask: Task<HLSAudioGenerator.GenerationResult, Error>?
    private var prefetchingChapterKey: String?
    private var prefetchQuickStart: (cacheKey: String, manifestURL: URL, timings: [VerseTiming])?
    private var prefetchQuickStartContinuation: CheckedContinuation<(URL, [VerseTiming]), Error>?

    /// Prefetch audio for a chapter in background
    /// Call this when user opens a chapter view (before they tap play)
    /// Audio will be ready for instant playback if/when they tap play
    func prefetchChapter(_ chapter: AudioChapter) {
        let cacheKey = chapter.cacheKey

        // Skip if already cached
        if AudioCache.shared.hasCompleteHLSManifest(for: chapter) {
            print("[AudioService] Prefetch skipped - already cached: \(chapter.bookName) \(chapter.chapterNumber)")
            return
        }

        // Skip if already prefetching this chapter
        if prefetchingChapterKey == cacheKey {
            print("[AudioService] Prefetch already in progress: \(chapter.bookName) \(chapter.chapterNumber)")
            return
        }

        // Cancel any existing prefetch for a different chapter
        prefetchTask?.cancel()
        prefetchingChapterKey = cacheKey
        prefetchQuickStart = nil
        resolvePrefetchQuickStart(with: .failure(CancellationError()))

        print("[AudioService] Starting prefetch: \(chapter.bookName) \(chapter.chapterNumber)")
        generationProgress = 0

        prefetchTask = Task(priority: .background) { [weak self] in
            guard let self else {
                throw CancellationError()
            }

            defer {
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if self.prefetchingChapterKey == cacheKey {
                        self.prefetchingChapterKey = nil
                        self.prefetchTask = nil
                    }
                }
            }

            do {
                // Generate segments progressively in background (low priority)
                let result = try await self.getHLSGenerator().generateProgressive(
                    chapter: chapter,
                    priority: .low,
                    onProgress: { [weak self] progress in
                        guard let self else { return }
                        await MainActor.run {
                            if self.prefetchingChapterKey == cacheKey {
                                self.generationProgress = progress
                            }
                        }
                    },
                    onQuickStart: { [weak self] manifestURL, timings in
                        guard let self else { return }
                        await MainActor.run {
                            self.prefetchQuickStart = (cacheKey: cacheKey, manifestURL: manifestURL, timings: timings)
                            self.resolvePrefetchQuickStart(with: .success((manifestURL, timings)))
                        }
                    }
                )
                print("[AudioService] Prefetch complete: \(chapter.bookName) \(chapter.chapterNumber)")
                return result
            } catch {
                await MainActor.run {
                    self.resolvePrefetchQuickStart(with: .failure(error))
                }
                throw error
            }
        }
    }

    /// Cancel any ongoing prefetch
    func cancelPrefetch() {
        prefetchTask?.cancel()
        prefetchTask = nil
        prefetchingChapterKey = nil
        prefetchQuickStart = nil
        resolvePrefetchQuickStart(with: .failure(CancellationError()))
    }

    private func resolvePrefetchQuickStart(with result: Result<(URL, [VerseTiming]), Error>) {
        guard let continuation = prefetchQuickStartContinuation else { return }
        prefetchQuickStartContinuation = nil
        continuation.resume(with: result)
    }

    private func awaitPrefetchQuickStart(cacheKey: String) async throws -> (URL, [VerseTiming]) {
        if let quickStart = prefetchQuickStart, quickStart.cacheKey == cacheKey {
            return (quickStart.manifestURL, quickStart.timings)
        }
        return try await withCheckedThrowingContinuation { continuation in
            prefetchQuickStartContinuation = continuation
        }
    }

    // MARK: - Audio URL

    /// Result of audio URL retrieval including URL and verse timings
    private struct AudioURLResult {
        let url: URL
        let verseTimings: [VerseTiming]
    }

    private func getAudioURL(for chapter: AudioChapter) async throws -> AudioURLResult {
        // Check cache first (also retrieves cached verse timings)
        // This checks both Edge and local caches, preferring Edge
        if let cachedResult = AudioCache.shared.getCachedAudioWithTimings(for: chapter) {
            generationProgress = 1.0
            isGeneratingAudio = false
            // Determine which source was cached
            if cachedResult.url.pathExtension == "mp3" {
                currentTTSSource = .edge
                print("[AudioService] Using CACHED Edge TTS audio for \(chapter.bookName) \(chapter.chapterNumber)")
            } else {
                currentTTSSource = .local
                print("[AudioService] Using CACHED local TTS audio for \(chapter.bookName) \(chapter.chapterNumber)")
            }
            return AudioURLResult(url: cachedResult.url, verseTimings: cachedResult.timings)
        }

        print("[AudioService] No cache found, generating new audio for \(chapter.bookName) \(chapter.chapterNumber)")

        // Request background task protection for TTS generation (10-30 seconds)
        // This prevents the system from killing the app if user switches away
        // Use a holder class to avoid capturing mutable local var in escaping closure
        let taskHolder = BackgroundTaskHolder()
        taskHolder.taskId = UIApplication.shared.beginBackgroundTask(withName: "AudioGeneration") { [taskHolder] in
            // Cleanup on expiration
            if taskHolder.taskId != .invalid {
                UIApplication.shared.endBackgroundTask(taskHolder.taskId)
                taskHolder.taskId = .invalid
            }
        }

        defer {
            // End background task when done
            if taskHolder.taskId != .invalid {
                UIApplication.shared.endBackgroundTask(taskHolder.taskId)
            }
        }

        // Generate using TTS (verse-by-verse for accurate timings)
        isGeneratingAudio = true
        generationProgress = 0
        let result = try await generateTTSAudio(for: chapter)
        isGeneratingAudio = false
        generationProgress = 1.0

        // Cache audio data and verse timings together
        // Use appropriate cache key based on which TTS source was used
        let cacheKey = currentTTSSource == .edge ? chapter.edgeCacheKey : chapter.localCacheKey
        let fileExtension = currentTTSSource == .edge ? "mp3" : "caf"
        let url = try AudioCache.shared.cacheAudioWithTimings(
            result.audioData,
            timings: result.verseTimings,
            for: chapter,
            cacheKey: cacheKey,
            fileExtension: fileExtension
        )

        return AudioURLResult(url: url, verseTimings: result.verseTimings)
    }

    // Keep synthesizer alive during audio generation
    private var ttsSynthesizer: AVSpeechSynthesizer?

    // MARK: - TTS Source Selection

    /// Available TTS sources with quality/speed tradeoffs
    enum TTSSource: String {
        case edge = "edge"      // Microsoft Edge neural voices (requires network)
        case local = "local"    // AVSpeechSynthesizer (offline, lower quality)

        var displayName: String {
            switch self {
            case .edge: return "Edge Neural (High Quality)"
            case .local: return "Device Voice (Offline)"
            }
        }
    }

    /// Current TTS source - tries Edge first, falls back to local
    private(set) var currentTTSSource: TTSSource = .edge

    /// Edge TTS service instance
    private let edgeTTSService = EdgeTTSService(
        voice: .default,
        rate: "-5%",  // Slightly slower for scripture reading
        pitch: "+0Hz"
    )

    /// HLS audio generation and manifest management
    private let hlsManifestManager = HLSManifestManager(cache: AudioCache.shared)
    private var hlsGenerator: HLSAudioGenerator?

    /// Pre-generation state
    private var preGenerationTask: Task<Void, Never>?
    private(set) var isPreGenerating: Bool = false
    private var hasAttemptedPreGeneration: Bool = false

    /// Get or create HLS generator (lazy initialization)
    private func getHLSGenerator() -> HLSAudioGenerator {
        if let generator = hlsGenerator {
            return generator
        }
        let generator = HLSAudioGenerator(
            edgeTTS: edgeTTSService,
            cache: AudioCache.shared,
            manifestManager: hlsManifestManager
        )
        hlsGenerator = generator
        return generator
    }

    private func getHLSManifestManager() -> HLSManifestManager {
        return hlsManifestManager
    }

    // MARK: - Voice Selection (Local Fallback)

    /// Preferred voice for natural-sounding scripture reading
    /// Prioritizes enhanced/premium voices over basic system voices
    private static var preferredVoice: AVSpeechSynthesisVoice? = {
        let voices = AVSpeechSynthesisVoice.speechVoices()

        // Filter to English voices
        let englishVoices = voices.filter { $0.language.hasPrefix("en-") }

        // Priority 1: Enhanced quality voices (downloaded premium voices)
        // These have identifiers containing "enhanced" or "premium"
        if let enhancedVoice = englishVoices.first(where: {
            $0.identifier.contains("enhanced") || $0.identifier.contains("premium")
        }) {
            return enhancedVoice
        }

        // Priority 2: High-quality voices (quality >= .enhanced)
        if let highQualityVoice = englishVoices.first(where: { $0.quality == .enhanced }) {
            return highQualityVoice
        }

        // Priority 3: US English default voice
        if let usVoice = AVSpeechSynthesisVoice(language: "en-US") {
            return usVoice
        }

        // Fallback: Any English voice
        return englishVoices.first
    }()

    /// Public accessor for cache key generation (local TTS only)
    static var preferredVoiceIdentifier: String {
        preferredVoice?.identifier ?? "default"
    }

    /// TTS source identifier for cache key (includes source type)
    static func ttsIdentifier(source: TTSSource) -> String {
        switch source {
        case .edge:
            return "edge-AriaNeural"
        case .local:
            return "local-\(preferredVoiceIdentifier)"
        }
    }

    /// Result of TTS generation including audio data and verse timings
    private struct TTSGenerationResult {
        let audioData: Data
        let verseTimings: [VerseTiming]
    }

    /// Helper class to hold background task ID without capturing mutable local var
    private class BackgroundTaskHolder: @unchecked Sendable {
        var taskId: UIBackgroundTaskIdentifier = .invalid
    }

    /// Helper class to manage audio file state during verse-by-verse generation
    private class AudioFileManager {
        var audioFile: AVAudioFile?
        var sampleRate: Double = 22050
        let tempURL: URL

        init(tempURL: URL) {
            self.tempURL = tempURL
        }

        func write(buffer: AVAudioPCMBuffer) throws {
            if audioFile == nil {
                audioFile = try AVAudioFile(
                    forWriting: tempURL,
                    settings: buffer.format.settings
                )
                sampleRate = buffer.format.sampleRate
            }
            try audioFile?.write(from: buffer)
        }
    }

    private func generateTTSAudio(for chapter: AudioChapter) async throws -> TTSGenerationResult {
        // Try Edge TTS first (higher quality, faster)
        do {
            return try await generateEdgeTTSAudio(for: chapter)
        } catch {
            // Fall back to local TTS if Edge fails (network unavailable, etc.)
            print("AudioService: Edge TTS failed (\(error.localizedDescription)), falling back to local TTS")
            currentTTSSource = .local
            return try await generateLocalTTSAudio(for: chapter)
        }
    }

    /// Generate audio using Edge TTS (high quality neural voices)
    /// Uses batch synthesis - one WebSocket call for entire chapter for speed
    private func generateEdgeTTSAudio(for chapter: AudioChapter) async throws -> TTSGenerationResult {
        currentTTSSource = .edge
        print("[AudioService] Starting Edge TTS BATCH generation for \(chapter.bookName) \(chapter.chapterNumber) (\(chapter.verses.count) verses)")

        // Combine all verses into single text with verse markers for natural pauses
        let verses = chapter.verses
        let combinedText = verses.map { $0.text }.joined(separator: " ... ")
        let totalWords = verses.reduce(0) { $0 + $1.text.split(separator: " ").count }

        generationProgress = 0.1
        print("[AudioService] Synthesizing \(totalWords) words in single batch...")

        // Single WebSocket call for entire chapter (much faster than verse-by-verse)
        let audioData = try await edgeTTSService.synthesize(text: combinedText, timeout: 60)

        generationProgress = 0.9

        // Estimate total duration from MP3 data size
        // Edge TTS outputs at ~96kbps = 12KB per second
        let totalDuration = Double(audioData.count) / 12000.0

        // Calculate verse timings proportionally based on word count
        var timings: [VerseTiming] = []
        var currentTime: TimeInterval = 0

        for verse in verses {
            let verseWordCount = verse.text.split(separator: " ").count
            let verseProportion = Double(verseWordCount) / Double(totalWords)
            let verseDuration = totalDuration * verseProportion

            timings.append(VerseTiming(
                verseNumber: verse.number,
                startTime: currentTime,
                endTime: currentTime + verseDuration
            ))

            currentTime += verseDuration
        }

        generationProgress = 1.0
        print("[AudioService] Edge TTS BATCH complete! Audio: \(audioData.count) bytes, Duration: \(String(format: "%.1f", totalDuration))s")
        return TTSGenerationResult(audioData: audioData, verseTimings: timings)
    }

    /// Generate audio using local AVSpeechSynthesizer (offline fallback)
    /// Uses a quick-start approach: generates first few verses quickly to start playback fast
    private func generateLocalTTSAudio(for chapter: AudioChapter) async throws -> TTSGenerationResult {
        currentTTSSource = .local
        print("[AudioService] Starting LOCAL TTS generation (fallback) for \(chapter.bookName) \(chapter.chapterNumber)")

        // Create temp file for combined audio output
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("caf")

        // Create synthesizer and keep it alive
        let synthesizer = AVSpeechSynthesizer()
        self.ttsSynthesizer = synthesizer

        // Track verse timings and progress
        var verseTimings: [VerseTiming] = []
        var currentStartTime: TimeInterval = 0
        let audioFileManager = AudioFileManager(tempURL: tempURL)
        let totalVerses = chapter.verses.count

        // Quick-start: Generate first 3 verses with shorter timeout for faster feedback
        let quickStartCount = min(3, totalVerses)

        // Generate audio verse-by-verse for accurate timing boundaries
        for (index, verse) in chapter.verses.enumerated() {
            // Update progress - weight early verses more heavily for perceived speed
            if index < quickStartCount {
                // First few verses: show rapid progress (0-50%)
                generationProgress = Double(index + 1) / Double(quickStartCount) * 0.5
            } else {
                // Remaining verses: slower progress (50-95%)
                generationProgress = 0.5 + (Double(index - quickStartCount) / Double(totalVerses - quickStartCount)) * 0.45
            }

            // Generate audio for this verse (shorter timeout for first verses)
            let timeout: TimeInterval = index < quickStartCount ? 3.0 : 5.0
            let verseFrameCount = try await generateVerseAudioWithTimeout(
                verse: verse,
                synthesizer: synthesizer,
                audioFileManager: audioFileManager,
                timeout: timeout
            )

            // Calculate actual duration from frame count
            let verseDuration = Double(verseFrameCount) / audioFileManager.sampleRate

            // Record timing with actual audio-derived boundaries
            let timing = VerseTiming(
                verseNumber: verse.number,
                startTime: currentStartTime,
                endTime: currentStartTime + verseDuration
            )
            verseTimings.append(timing)

            // Move to next verse start time
            currentStartTime += verseDuration
        }

        // Clean up synthesizer
        self.ttsSynthesizer = nil
        generationProgress = 1.0

        // Read the generated audio file
        let audioData = try Data(contentsOf: tempURL)

        // Clean up temp file
        try? FileManager.default.removeItem(at: tempURL)

        guard !audioData.isEmpty else {
            throw AudioError.generationFailed
        }

        return TTSGenerationResult(audioData: audioData, verseTimings: verseTimings)
    }

    /// Generate audio for a single verse with configurable timeout
    private func generateVerseAudioWithTimeout(
        verse: AudioVerse,
        synthesizer: AVSpeechSynthesizer,
        audioFileManager: AudioFileManager,
        timeout: TimeInterval
    ) async throws -> UInt32 {
        // Capture voice before entering task to avoid main actor isolation issues
        let voice = Self.preferredVoice

        return try await withThrowingTaskGroup(of: UInt32.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UInt32, Error>) in
                    let utterance = AVSpeechUtterance(string: verse.text)

                    // Use premium/enhanced voice for natural-sounding scripture reading
                    utterance.voice = voice

                    // Configure for clear scripture reading - slightly faster for better UX
                    utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95 // Slightly faster
                    utterance.pitchMultiplier = 1.0
                    utterance.preUtteranceDelay = 0.02 // Minimal pause
                    utterance.postUtteranceDelay = 0.25 // Shorter pause between verses

                    var hasResumed = false
                    var localFramesWritten: UInt32 = 0

                    synthesizer.write(utterance) { buffer in
                        guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
                            if !hasResumed {
                                hasResumed = true
                                continuation.resume(returning: localFramesWritten)
                            }
                            return
                        }

                        guard pcmBuffer.frameLength > 0 else {
                            if !hasResumed {
                                hasResumed = true
                                continuation.resume(returning: localFramesWritten)
                            }
                            return
                        }

                        do {
                            try audioFileManager.write(buffer: pcmBuffer)
                            localFramesWritten += pcmBuffer.frameLength
                        } catch {
                            if !hasResumed {
                                hasResumed = true
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                }
            }

            // Configurable timeout per verse
            group.addTask {
                try await Task.sleep(for: .seconds(timeout))
                throw AudioError.generationFailed
            }

            var framesWritten: UInt32 = 0
            do {
                if let result = try await group.next() {
                    framesWritten = result
                }
                group.cancelAll()
            } catch {
                group.cancelAll()
                throw error
            }
            return framesWritten
        }
    }

    /// Generate audio for a single verse and append to the audio file
    /// Returns the number of frames written for this verse
    private func generateVerseAudio(
        verse: AudioVerse,
        synthesizer: AVSpeechSynthesizer,
        audioFileManager: AudioFileManager
    ) async throws -> UInt32 {
        // Capture voice before entering task to avoid main actor isolation issues
        let voice = Self.preferredVoice

        return try await withThrowingTaskGroup(of: UInt32.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UInt32, Error>) in
                    let utterance = AVSpeechUtterance(string: verse.text)

                    // Use premium/enhanced voice for natural-sounding scripture reading
                    utterance.voice = voice

                    // Configure for clear scripture reading
                    utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9 // Natural pace
                    utterance.pitchMultiplier = 1.0 // Natural pitch (enhanced voices sound better at default)
                    utterance.preUtteranceDelay = 0.05 // Small pause before verse
                    utterance.postUtteranceDelay = 0.35 // Pause after verse for natural separation

                    var hasResumed = false
                    var localFramesWritten: UInt32 = 0

                    synthesizer.write(utterance) { buffer in
                        guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
                            // Synthesis complete
                            if !hasResumed {
                                hasResumed = true
                                continuation.resume(returning: localFramesWritten)
                            }
                            return
                        }

                        guard pcmBuffer.frameLength > 0 else {
                            // Empty buffer signals completion
                            if !hasResumed {
                                hasResumed = true
                                continuation.resume(returning: localFramesWritten)
                            }
                            return
                        }

                        do {
                            try audioFileManager.write(buffer: pcmBuffer)
                            localFramesWritten += pcmBuffer.frameLength
                        } catch {
                            if !hasResumed {
                                hasResumed = true
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                }
            }

            // Timeout for single verse (5 seconds should be plenty)
            group.addTask {
                try await Task.sleep(for: .seconds(5))
                throw AudioError.generationFailed
            }

            // Wait for verse generation to complete
            var framesWritten: UInt32 = 0
            do {
                if let result = try await group.next() {
                    framesWritten = result
                }
                group.cancelAll()
            } catch {
                group.cancelAll()
                throw error
            }
            return framesWritten
        }
    }

    // MARK: - Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Playback State

enum PlaybackState: Equatable {
    case idle
    case loading
    case ready
    case playing
    case paused
    case finished
    case error
}

// MARK: - Audio Chapter Model

struct AudioChapter: Identifiable {
    let id: String
    let bookId: Int
    let bookName: String
    let chapterNumber: Int
    let translation: String
    let verses: [AudioVerse]
    var verseTimings: [VerseTiming]

    /// Cache key for Edge TTS (preferred)
    var edgeCacheKey: String {
        return "\(bookId)-\(chapterNumber)-\(translation)-edge-EmmaNeural"
    }

    /// Cache key for local TTS (fallback)
    var localCacheKey: String {
        let voiceId = AudioService.preferredVoiceIdentifier
        let speechRate = String(format: "%.2f", AVSpeechUtteranceDefaultSpeechRate * 0.9)
        return "\(bookId)-\(chapterNumber)-\(translation)-local-\(voiceId)-\(speechRate)"
    }

    /// Primary cache key (used for initial lookup - prefers Edge)
    var cacheKey: String {
        return edgeCacheKey
    }

    init(location: BibleLocation, bookName: String, translation: String, verses: [Verse]) {
        self.id = "\(location.bookId)-\(location.chapter)-\(translation)"
        self.bookId = location.bookId
        self.bookName = bookName
        self.chapterNumber = location.chapter
        self.translation = translation
        self.verses = verses.map { AudioVerse(number: $0.verse, text: $0.text) }

        // Initialize with empty timings - will be populated with actual audio-derived timings
        self.verseTimings = []
    }

    /// Update verse timings with actual audio-derived boundaries
    mutating func setVerseTimings(_ timings: [VerseTiming]) {
        self.verseTimings = timings
    }
}

struct AudioVerse {
    let number: Int
    let text: String
}

struct VerseTiming {
    let verseNumber: Int
    let startTime: TimeInterval
    let endTime: TimeInterval
}

// MARK: - Audio Error

enum AudioError: Error, LocalizedError {
    case loadFailed(String)
    case generationFailed
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .loadFailed(let message):
            return "Failed to load audio: \(message)"
        case .generationFailed:
            return "Failed to generate audio"
        case .notAvailable:
            return "Audio is not available for this content"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let audioVerseChanged = Notification.Name("audioVerseChanged")
    static let audioPlaybackStateChanged = Notification.Name("audioPlaybackStateChanged")
    static let sleepTimerFired = Notification.Name("sleepTimerFired")
}

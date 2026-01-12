//
//  HLSAudioGenerator.swift
//  BibleStudy
//
//  Orchestrates progressive HLS audio generation for Bible chapters.
//  Generates verse segments and creates HLS manifests for streaming playback.
//

import Foundation
import AVFoundation

// MARK: - HLS Audio Generator

/// Orchestrates progressive generation of verse-level audio segments and HLS manifests
actor HLSAudioGenerator {
    // MARK: - Types

    struct GenerationResult: Sendable {
        let manifestURL: URL
        let totalDuration: TimeInterval
        let verseTimings: [VerseTiming]
        let segmentCount: Int
    }

    enum Priority: Sendable {
        case interactive  // User-initiated playback (highest priority)
        case background   // Pre-generation during playback
        case low          // Opportunistic caching

        var taskPriority: TaskPriority {
            switch self {
            case .interactive: return .userInitiated
            case .background: return .utility
            case .low: return .background
            }
        }
    }

    enum GenerationError: Error, LocalizedError {
        case noVerses
        case segmentGenerationFailed(verse: Int, Error)
        case manifestCreationFailed(Error)
        case cachingFailed(Error)

        var errorDescription: String? {
            switch self {
            case .noVerses:
                return "Chapter has no verses to generate"
            case .segmentGenerationFailed(let verse, let error):
                return "Failed to generate verse \(verse): \(error.localizedDescription)"
            case .manifestCreationFailed(let error):
                return "Failed to create manifest: \(error.localizedDescription)"
            case .cachingFailed(let error):
                return "Failed to cache audio: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Properties

    private let edgeTTS: EdgeTTSService
    private let cache: AudioCache
    private let manifestManager: HLSManifestManager

    /// Track active generation to support cancellation
    private var activeGeneration: Task<GenerationResult, Error>?

    /// Current TTS source being used
    private(set) var currentSource: TTSSource = .edge

    enum TTSSource {
        case edge
        case local
    }

    // MARK: - Initialization

    init(edgeTTS: EdgeTTSService, cache: AudioCache, manifestManager: HLSManifestManager) {
        self.edgeTTS = edgeTTS
        self.cache = cache
        self.manifestManager = manifestManager
    }

    // MARK: - Progressive Generation

    /// Generate chapter with progressive playback (quick-start + background completion)
    /// - Parameters:
    ///   - chapter: The chapter to generate
    ///   - priority: Generation priority
    ///   - onProgress: Progress callback (0.0-1.0)
    ///   - onQuickStart: Called when quick-start segments are ready to play, includes manifest URL and verse timings
    ///   - onProgressiveUpdate: Called periodically during background generation to allow progressive composition reload
    /// - Returns: Final generation result when complete
    func generateProgressive(
        chapter: AudioChapter,
        priority: Priority = .interactive,
        onProgress: (@Sendable (Double) async -> Void)? = nil,
        onQuickStart: (@Sendable (URL, [VerseTiming]) async -> Void)? = nil,
        onProgressiveUpdate: (@Sendable (URL, [VerseTiming]) async -> Void)? = nil
    ) async throws -> GenerationResult {
        guard !chapter.verses.isEmpty else {
            throw GenerationError.noVerses
        }

        // Cancel any previous generation
        activeGeneration?.cancel()

        let task = Task(priority: priority.taskPriority) {
            try await performProgressiveGeneration(
                chapter: chapter,
                onProgress: onProgress,
                onQuickStart: onQuickStart,
                onProgressiveUpdate: onProgressiveUpdate
            )
        }

        activeGeneration = task
        return try await task.value
    }

    /// Generate complete chapter (wait for all segments)
    /// Used for pre-caching next chapters
    func generateComplete(
        chapter: AudioChapter,
        priority: Priority = .background,
        onProgress: (@Sendable (Double) async -> Void)? = nil
    ) async throws -> GenerationResult {
        guard !chapter.verses.isEmpty else {
            throw GenerationError.noVerses
        }

        // Cancel any previous generation
        activeGeneration?.cancel()

        let task = Task(priority: priority.taskPriority) {
            try await performCompleteGeneration(chapter: chapter, onProgress: onProgress)
        }

        activeGeneration = task
        return try await task.value
    }

    /// Cancel active generation
    func cancelGeneration() {
        activeGeneration?.cancel()
        activeGeneration = nil
    }

    // MARK: - Private Implementation

    private func performProgressiveGeneration(
        chapter: AudioChapter,
        onProgress: (@Sendable (Double) async -> Void)?,
        onQuickStart: (@Sendable (URL, [VerseTiming]) async -> Void)?,
        onProgressiveUpdate: (@Sendable (URL, [VerseTiming]) async -> Void)?
    ) async throws -> GenerationResult {
        let verses = chapter.verses
        let totalVerses = verses.count

        // Phase 1: Quick-start (first 3 verses for fast ~4 second startup)
        // Remaining verses generate in background while playing
        let quickStartCount = min(3, totalVerses)
        var segments: [HLSManifestManager.SegmentInfo] = []
        var currentStartTime: TimeInterval = 0

        print("[HLS] Starting quick-start generation for \(chapter.bookName) \(chapter.chapterNumber) (verses 1-\(quickStartCount))")

        // Generate quick-start segments sequentially for minimal latency
        for i in 0..<quickStartCount {
            let verse = verses[i]

            let segment = try await generateSegment(
                verse: verse,
                chapter: chapter,
                startTime: currentStartTime
            )

            segments.append(segment)
            currentStartTime = segment.endTime

            // Update progress
            let progress = Double(i + 1) / Double(totalVerses)
            await onProgress?(progress)

            print("[HLS] Generated verse \(verse.number) (\(i + 1)/\(quickStartCount) quick-start)")
        }

        // Create manifest with quick-start segments
        let manifestURL = try await manifestManager.create(chapter: chapter, segments: segments)

        // Build quick-start timings from segments
        let quickStartTimings = segments.map { segment in
            VerseTiming(
                verseNumber: segment.verseNumber,
                startTime: segment.startTime,
                endTime: segment.endTime
            )
        }

        // Notify caller that quick-start is ready with manifest URL and timings
        await onQuickStart?(manifestURL, quickStartTimings)
        print("[HLS] Quick-start ready! Manifest created with \(segments.count) segments")

        // Phase 2: Background completion (remaining verses)
        if totalVerses > quickStartCount {
            print("[HLS] Starting background generation (verses \(quickStartCount + 1)-\(totalVerses))")

            for i in quickStartCount..<totalVerses {
                // Check for cancellation
                try Task.checkCancellation()

                let verse = verses[i]

                let segment = try await generateSegment(
                    verse: verse,
                    chapter: chapter,
                    startTime: currentStartTime
                )

                segments.append(segment)
                currentStartTime = segment.endTime

                // Append to manifest
                try await manifestManager.append(chapter: chapter, segment: segment)

                // Update progress
                let progress = Double(i + 1) / Double(totalVerses)
                await onProgress?(progress)

                print("[HLS] Generated verse \(verse.number) (\(i + 1)/\(totalVerses) total)")

                // Trigger progressive update every 3 verses to keep buffer ahead of playback
                let versesGenerated = i + 1
                if versesGenerated % 3 == 0 {
                    let currentTimings = segments.map { seg in
                        VerseTiming(
                            verseNumber: seg.verseNumber,
                            startTime: seg.startTime,
                            endTime: seg.endTime
                        )
                    }
                    await onProgressiveUpdate?(manifestURL, currentTimings)
                    print("[HLS] Progressive update triggered at \(versesGenerated) verses")
                }
            }
        }

        // Mark manifest as complete
        try await manifestManager.markComplete(chapter: chapter)

        // Build verse timings
        let verseTimings = segments.map { segment in
            VerseTiming(
                verseNumber: segment.verseNumber,
                startTime: segment.startTime,
                endTime: segment.endTime
            )
        }

        print("[HLS] Generation complete for \(chapter.bookName) \(chapter.chapterNumber) - \(segments.count) verses, \(String(format: "%.1f", currentStartTime))s total")

        return GenerationResult(
            manifestURL: manifestURL,
            totalDuration: currentStartTime,
            verseTimings: verseTimings,
            segmentCount: segments.count
        )
    }

    private func performCompleteGeneration(
        chapter: AudioChapter,
        onProgress: (@Sendable (Double) async -> Void)?
    ) async throws -> GenerationResult {
        let verses = chapter.verses
        var segments: [HLSManifestManager.SegmentInfo] = []
        var currentStartTime: TimeInterval = 0

        print("[HLS] Starting complete generation for \(chapter.bookName) \(chapter.chapterNumber) (\(verses.count) verses)")

        // Generate all segments
        for (index, verse) in verses.enumerated() {
            try Task.checkCancellation()

            let segment = try await generateSegment(
                verse: verse,
                chapter: chapter,
                startTime: currentStartTime
            )

            segments.append(segment)
            currentStartTime = segment.endTime

            let progress = Double(index + 1) / Double(verses.count)
            await onProgress?(progress)

            print("[HLS] Generated verse \(verse.number) (\(index + 1)/\(verses.count))")
        }

        // Create complete manifest
        let manifestURL = try await manifestManager.create(chapter: chapter, segments: segments)
        try await manifestManager.markComplete(chapter: chapter)

        let verseTimings = segments.map { segment in
            VerseTiming(
                verseNumber: segment.verseNumber,
                startTime: segment.startTime,
                endTime: segment.endTime
            )
        }

        print("[HLS] Complete generation finished - \(segments.count) verses, \(String(format: "%.1f", currentStartTime))s total")

        return GenerationResult(
            manifestURL: manifestURL,
            totalDuration: currentStartTime,
            verseTimings: verseTimings,
            segmentCount: segments.count
        )
    }

    // MARK: - Segment Generation

    private func generateSegment(
        verse: AudioVerse,
        chapter: AudioChapter,
        startTime: TimeInterval
    ) async throws -> HLSManifestManager.SegmentInfo {
        // Try Edge TTS first
        do {
            currentSource = .edge

            let verseAudio = try await edgeTTS.synthesizeVerse(text: verse.text, timeout: 10)

            // Cache segment
            let segmentURL = await cache.segmentURL(
                for: chapter,
                verse: verse.number,
                fileExtension: "mp3"
            )

            try verseAudio.data.write(to: segmentURL)

            return HLSManifestManager.SegmentInfo(
                url: segmentURL,
                verseNumber: verse.number,
                duration: verseAudio.duration,
                startTime: startTime
            )

        } catch {
            // Fall back to local TTS
            print("[HLS] Edge TTS failed for verse \(verse.number), falling back to local TTS: \(error.localizedDescription)")
            return try await generateLocalSegment(
                verse: verse,
                chapter: chapter,
                startTime: startTime
            )
        }
    }

    private func generateLocalSegment(
        verse: AudioVerse,
        chapter: AudioChapter,
        startTime: TimeInterval
    ) async throws -> HLSManifestManager.SegmentInfo {
        currentSource = .local

        // Use AVSpeechSynthesizer for local TTS
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: verse.text)

        // Configure for scripture reading
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9

        // Generate audio to temp file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("caf")

        let audioFile = try await generateLocalAudio(
            utterance: utterance,
            synthesizer: synthesizer,
            outputURL: tempURL
        )

        // Calculate duration
        let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate

        // Move to cache
        let segmentURL = await cache.segmentURL(
            for: chapter,
            verse: verse.number,
            fileExtension: "caf"
        )

        try FileManager.default.moveItem(at: tempURL, to: segmentURL)

        return HLSManifestManager.SegmentInfo(
            url: segmentURL,
            verseNumber: verse.number,
            duration: duration,
            startTime: startTime
        )
    }

    private func generateLocalAudio(
        utterance: AVSpeechUtterance,
        synthesizer: AVSpeechSynthesizer,
        outputURL: URL
    ) async throws -> AVAudioFile {
        return try await withCheckedThrowingContinuation { continuation in
            var audioFile: AVAudioFile?
            var hasResumed = false

            synthesizer.write(utterance) { buffer in
                guard let pcmBuffer = buffer as? AVAudioPCMBuffer,
                      pcmBuffer.frameLength > 0 else {
                    // Synthesis complete
                    if !hasResumed, let file = audioFile {
                        hasResumed = true
                        continuation.resume(returning: file)
                    }
                    return
                }

                do {
                    if audioFile == nil {
                        audioFile = try AVAudioFile(
                            forWriting: outputURL,
                            settings: pcmBuffer.format.settings
                        )
                    }
                    try audioFile?.write(from: pcmBuffer)
                } catch {
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}

import Foundation

// MARK: - Sermon Configuration
// Centralized configuration constants for the Sermon feature.
// Prevents magic numbers scattered across files and makes tuning easier.

enum SermonConfiguration {
    // MARK: - Recording

    /// Duration per audio chunk for Whisper API (10 minutes)
    /// Whisper has a 25MB limit, so 10 min at 32kbps ≈ 2.4MB is safe
    static let chunkDurationSeconds: TimeInterval = 10 * 60

    /// High-quality chunk duration (5 minutes) for safety margin
    static let highQualityChunkDurationSeconds: TimeInterval = 5 * 60

    // MARK: - Audio Import

    /// Maximum sermon duration for audio file import (30 minutes)
    /// Files longer than this are rejected to prevent excessive processing
    static let maxImportDurationMinutes: Int = 30

    /// Minimum sermon duration in seconds (to filter noise recordings)
    static let minRecordingDurationSeconds: TimeInterval = 5

    // MARK: - Transcription

    /// Target segment duration for transcript display grouping (~12 seconds)
    /// Groups words into readable chunks for UI rendering
    static let transcriptSegmentDurationSeconds: Double = 12.0

    /// Minimum segment duration before allowing punctuation-based breaks
    static let minSegmentDurationForPunctuationBreak: Double = 5.0

    // MARK: - Processing

    /// Maximum processing timeout before giving up (30 minutes)
    /// Prevents indefinite processing states
    static let processingTimeoutSeconds: TimeInterval = 30 * 60

    /// Progress stream polling interval
    static let progressPollIntervalSeconds: TimeInterval = 1.0

    // MARK: - Cache

    /// Maximum entries in TranscriptSegmentCache before LRU eviction
    static let maxCacheEntries: Int = 100

    /// Percentage of cache to evict on memory warning
    static let memoryCacheEvictionPercent: Double = 0.5

    // MARK: - Retry

    /// Maximum retry attempts for failed chunk uploads
    static let maxUploadRetries: Int = 3

    /// Delay between upload retry attempts (exponential backoff base)
    static let uploadRetryBaseDelaySeconds: TimeInterval = 2.0

    // MARK: - Validation

    /// Maximum audio file size in bytes (25MB Whisper limit)
    static let maxChunkFileSizeBytes: Int = 25_000_000

    /// Estimated bytes per minute at standard recording settings (~240KB/min at 32kbps)
    static let estimatedBytesPerMinute: Int = 240_000

    // MARK: - Live Captions

    /// Maximum finalized caption segments before LRU eviction (oldest dropped)
    static let maxLiveCaptionSegments: Int = 200

    /// Maximum retry attempts for speech recognition analyzer errors
    static let maxRecognitionRetries: Int = 3

    /// Base delay for exponential backoff on recognition retries
    static let recognitionRetryBaseDelaySeconds: TimeInterval = 1.0

    /// Gain multiplier applied to audio fed to the transcription engine.
    /// Sermon recordings often capture speech from a distance (phone on pew,
    /// speaker at pulpit). The default mic level (~0.002-0.005 RMS) can be
    /// too quiet for DictationTranscriber's speech detection threshold.
    /// 4x boost brings distant speech into reliable recognition range
    /// without clipping close-range speech (clamped to [-1.0, 1.0]).
    static let transcriptionGainMultiplier: Float = 4.0

    /// RMS threshold to trigger speech activity detection (onset)
    static let speechActivityRMSThreshold: Float = 0.05

    /// RMS threshold to clear speech activity detection (offset — lower for hysteresis)
    static let speechActivitySilenceThreshold: Float = 0.02

    /// Number of buffer callbacks to hold speech state after offset threshold,
    /// preventing flicker during natural pauses
    static let speechActivityHoldFrames: Int = 8
}

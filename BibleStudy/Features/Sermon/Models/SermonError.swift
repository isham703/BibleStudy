import Foundation

// MARK: - Sermon Error
// Domain-specific errors for the Sermon feature
enum SermonError: Error, LocalizedError, Sendable {
    // Recording errors
    case microphonePermissionDenied
    case microphonePermissionRestricted
    case recordingFailed(String)
    case recordingTooShort(durationSeconds: Int, minimumSeconds: Int)
    case recordingInterrupted
    case audioSessionFailed(String)

    // Import errors
    case importFailed(String)
    case unsupportedAudioFormat(String)
    case fileTooLarge(maxMB: Int)
    case fileNotFound

    // Processing errors
    case transcriptionFailed(String)
    case transcriptionTimedOut
    case studyGuideGenerationFailed(String)
    case moderationFailed(String)
    case contentFlagged(String)
    case processingTimeout

    // Upload/sync errors
    case uploadFailed(String)
    case downloadFailed(String)
    case networkUnavailable
    case syncFailed(String)

    // Storage errors
    case storageFull
    case fileCorrupted
    case cacheError(String)

    // Database errors
    case databaseError(String)
    case sermonNotFound
    case chunkNotFound

    // Authentication errors
    case notAuthenticated
    case authorizationFailed

    // Delete errors
    case cannotDeleteWhileProcessing
    case deleteFailed(String)

    // Speech recognition errors (Live Captions)
    case speechRecognitionDenied
    case speechRecognitionUnavailable
    case speechRecognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access was denied. Please enable it in Settings to record sermons."
        case .microphonePermissionRestricted:
            return "Microphone access is restricted on this device."
        case .recordingFailed(let reason):
            return "Recording failed: \(reason)"
        case .recordingTooShort(let duration, let minimum):
            return "Recording is too short (\(duration) seconds). Minimum duration is \(minimum) seconds for quality transcription."
        case .recordingInterrupted:
            return "Recording was interrupted. Your progress has been saved."
        case .audioSessionFailed(let reason):
            return "Audio session error: \(reason)"

        case .importFailed(let reason):
            return "Failed to import audio file: \(reason)"
        case .unsupportedAudioFormat(let format):
            return "Unsupported audio format: \(format). Please use MP3, M4A, or WAV."
        case .fileTooLarge(let maxMB):
            return "File is too large. Maximum size is \(maxMB) MB."
        case .fileNotFound:
            return "Audio file not found."

        case .transcriptionFailed(let reason):
            return "Transcription failed: \(reason)"
        case .transcriptionTimedOut:
            return "Transcription timed out. Please try again."
        case .studyGuideGenerationFailed(let reason):
            return "Study guide generation failed: \(reason)"
        case .moderationFailed(let reason):
            return "Content moderation failed: \(reason)"
        case .contentFlagged(let reason):
            return "Content was flagged and cannot be processed: \(reason)"
        case .processingTimeout:
            return "Processing timed out. The sermon may be too long or the service is busy."

        case .uploadFailed(let reason):
            return "Upload failed: \(reason)"
        case .downloadFailed(let reason):
            return "Download failed: \(reason)"
        case .networkUnavailable:
            return "Network unavailable. Please check your connection."
        case .syncFailed(let reason):
            return "Sync failed: \(reason)"

        case .storageFull:
            return "Storage is full. Please free up space to continue."
        case .fileCorrupted:
            return "Audio file is corrupted."
        case .cacheError(let reason):
            return "Cache error: \(reason)"

        case .databaseError(let reason):
            return "Database error: \(reason)"
        case .sermonNotFound:
            return "Sermon not found."
        case .chunkNotFound:
            return "Audio chunk not found."

        case .notAuthenticated:
            return "Please sign in to record and sync sermons."
        case .authorizationFailed:
            return "Authorization failed. Please sign in again."

        case .cannotDeleteWhileProcessing:
            return "Cannot delete while processing. Please wait for processing to complete."
        case .deleteFailed(let reason):
            return "Failed to delete sermon: \(reason)"

        case .speechRecognitionDenied:
            return "Speech recognition access was denied. Live captions require this permission."
        case .speechRecognitionUnavailable:
            return "Speech recognition is not available on this device."
        case .speechRecognitionFailed(let reason):
            return "Live captions failed: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Go to Settings > Privacy > Microphone to enable access."
        case .recordingInterrupted:
            return "You can resume recording or save what was captured."
        case .recordingTooShort(_, let minimum):
            return "Please record or import audio that is at least \(minimum) seconds long."
        case .fileTooLarge:
            return "Try splitting the sermon into smaller parts."
        case .networkUnavailable:
            return "The sermon will be saved locally and synced when connected."
        case .storageFull:
            return "Delete old sermons or clear the cache in Settings."
        case .notAuthenticated:
            return "Sign in to enable cloud sync and AI features."
        case .cannotDeleteWhileProcessing:
            return "Wait for the transcription and study guide to complete, then try again."
        case .speechRecognitionDenied:
            return "Go to Settings > Privacy > Speech Recognition to enable access."
        case .speechRecognitionFailed:
            return "Recording continues normally. Live captions will be retried automatically."
        default:
            return nil
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .uploadFailed, .downloadFailed,
             .syncFailed, .transcriptionTimedOut, .processingTimeout:
            return true
        default:
            return false
        }
    }

    var shouldShowRetryButton: Bool {
        isRetryable
    }
}

// MARK: - Error Mapping
extension SermonError {
    /// Map a generic Error to a SermonError
    static func from(_ error: Error) -> SermonError {
        if let sermonError = error as? SermonError {
            return sermonError
        }

        let nsError = error as NSError

        // Check for common error domains
        switch nsError.domain {
        case NSURLErrorDomain:
            if nsError.code == NSURLErrorNotConnectedToInternet {
                return .networkUnavailable
            }
            return .syncFailed(error.localizedDescription)

        case "AVFoundationErrorDomain":
            return .recordingFailed(error.localizedDescription)

        default:
            return .databaseError(error.localizedDescription)
        }
    }
}

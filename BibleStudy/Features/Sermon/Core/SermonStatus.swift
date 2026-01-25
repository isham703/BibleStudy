import Foundation

// MARK: - Sermon Status
// Single source of truth for sermon display status.
// Consolidates status logic from Sermon model into a centralized enum.

enum SermonStatus: Equatable, Sendable {
    /// Sermon is pending - not yet started processing
    case pending

    /// Sermon is actively processing (transcription or study guide in progress)
    case processing

    /// Sermon is fully ready - both transcription and study guide succeeded
    case ready

    /// Sermon is viewable in degraded mode - transcription succeeded but study guide failed
    /// User can view transcript and retry study guide generation
    case degraded

    /// Sermon has failed - transcription failed (cannot recover)
    case error

    // MARK: - Factory Method

    /// Derive status from a Sermon model
    /// - Parameter sermon: The sermon to derive status from
    /// - Returns: The appropriate SermonStatus
    static func from(_ sermon: Sermon) -> SermonStatus {
        // Check for transcription failure first (unrecoverable)
        if sermon.transcriptionStatus == .failed {
            return .error
        }

        // Check if still processing
        if sermon.transcriptionStatus == .running || sermon.studyGuideStatus == .running {
            return .processing
        }

        // Check for pending state (neither transcription nor study guide started)
        if sermon.transcriptionStatus == .pending && sermon.studyGuideStatus == .pending {
            return .pending
        }

        // Check for degraded mode (transcription OK, study guide failed)
        if sermon.transcriptionStatus == .succeeded && sermon.studyGuideStatus == .failed {
            return .degraded
        }

        // Check for fully ready
        if sermon.transcriptionStatus == .succeeded && sermon.studyGuideStatus == .succeeded {
            return .ready
        }

        // Partial processing (transcription done, study guide pending/running)
        if sermon.transcriptionStatus == .succeeded {
            return .processing
        }

        // Default to pending for any edge cases
        return .pending
    }

    // MARK: - Computed Properties

    /// Whether the sermon can be viewed (ready or degraded)
    var isViewable: Bool {
        self == .ready || self == .degraded
    }

    /// Whether the sermon is still processing
    var isProcessing: Bool {
        self == .processing
    }

    /// Whether study guide can be retried (only for degraded state)
    var canRetryStudyGuide: Bool {
        self == .degraded
    }

    /// Human-readable status text for display
    var displayText: String {
        switch self {
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .ready:
            return "Ready"
        case .degraded:
            return "Transcript Ready"
        case .error:
            return "Failed"
        }
    }

    /// Short description for accessibility
    var accessibilityLabel: String {
        switch self {
        case .pending:
            return "Sermon pending, waiting to process"
        case .processing:
            return "Sermon is being processed"
        case .ready:
            return "Sermon ready to view"
        case .degraded:
            return "Sermon transcript ready, study guide unavailable"
        case .error:
            return "Sermon processing failed"
        }
    }
}

// MARK: - Sermon Extension

extension Sermon {
    /// Derive status using the centralized SermonStatus logic
    var status: SermonStatus {
        SermonStatus.from(self)
    }
}

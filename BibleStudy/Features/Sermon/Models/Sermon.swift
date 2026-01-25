import Foundation
import GRDB

// MARK: - Processing Status
enum SermonProcessingStatus: String, Codable, Sendable {
    case pending
    case running
    case succeeded
    case failed
}

// MARK: - Sermon
// Main sermon record with metadata and job tracking
struct Sermon: Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    var title: String
    var speakerName: String?
    let recordedAt: Date
    var durationSeconds: Int

    // Audio metadata
    var localAudioPath: String?
    var remoteAudioPath: String?
    var audioFileSize: Int?
    var audioMimeType: String?
    var audioCodec: String?
    var audioBitrateKbps: Int?
    var audioContentHash: String?

    // Processing status (job tracking)
    var transcriptionStatus: SermonProcessingStatus
    var transcriptionError: String?
    var studyGuideStatus: SermonProcessingStatus
    var studyGuideError: String?
    var processingVersion: String

    var scriptureReferences: [String]

    // Sync tracking
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var needsSync: Bool
    var audioNeedsUpload: Bool

    // MARK: - Computed Properties

    var formattedDuration: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60
        let seconds = durationSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var isProcessing: Bool {
        transcriptionStatus == .running || studyGuideStatus == .running
    }

    var isComplete: Bool {
        transcriptionStatus == .succeeded && studyGuideStatus == .succeeded
    }

    var hasError: Bool {
        transcriptionStatus == .failed || studyGuideStatus == .failed
    }

    var displayTitle: String {
        // 1. Use actual title if explicitly set
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed != "Untitled Sermon" {
            return trimmed
        }
        // 2. Use first scripture reference if available
        if let firstRef = scriptureReferences.first {
            return "Sermon — \(firstRef)"
        }
        // 3. Fall back to date-based title
        return "Sermon — \(recordedAt.formatted(date: .abbreviated, time: .omitted))"
    }

    // MARK: - Graceful Degradation Properties

    /// Transcription succeeded, allowing basic viewing even if study guide failed
    var hasSuccessfulTranscription: Bool {
        transcriptionStatus == .succeeded
    }

    /// Study guide specifically failed (not just pending)
    var studyGuideFailed: Bool {
        studyGuideStatus == .failed
    }

    /// Can view sermon in degraded mode (transcript available, study guide may be missing/failed)
    var canViewInDegradedMode: Bool {
        hasSuccessfulTranscription && studyGuideFailed
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        userId: UUID,
        title: String,
        speakerName: String? = nil,
        recordedAt: Date = Date(),
        durationSeconds: Int = 0,
        localAudioPath: String? = nil,
        remoteAudioPath: String? = nil,
        audioFileSize: Int? = nil,
        audioMimeType: String? = nil,
        audioCodec: String? = nil,
        audioBitrateKbps: Int? = nil,
        audioContentHash: String? = nil,
        transcriptionStatus: SermonProcessingStatus = .pending,
        transcriptionError: String? = nil,
        studyGuideStatus: SermonProcessingStatus = .pending,
        studyGuideError: String? = nil,
        processingVersion: String = "1",
        scriptureReferences: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        needsSync: Bool = false,
        audioNeedsUpload: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.speakerName = speakerName
        self.recordedAt = recordedAt
        self.durationSeconds = durationSeconds
        self.localAudioPath = localAudioPath
        self.remoteAudioPath = remoteAudioPath
        self.audioFileSize = audioFileSize
        self.audioMimeType = audioMimeType
        self.audioCodec = audioCodec
        self.audioBitrateKbps = audioBitrateKbps
        self.audioContentHash = audioContentHash
        self.transcriptionStatus = transcriptionStatus
        self.transcriptionError = transcriptionError
        self.studyGuideStatus = studyGuideStatus
        self.studyGuideError = studyGuideError
        self.processingVersion = processingVersion
        self.scriptureReferences = scriptureReferences
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.needsSync = needsSync
        self.audioNeedsUpload = audioNeedsUpload
    }

    // MARK: - Mutations

    mutating func markDeleted() {
        deletedAt = Date()
        updatedAt = Date()
        needsSync = true
    }

    mutating func updateTranscriptionStatus(_ status: SermonProcessingStatus, error: String? = nil) {
        transcriptionStatus = status
        transcriptionError = error
        updatedAt = Date()
        needsSync = true
    }

    mutating func updateStudyGuideStatus(_ status: SermonProcessingStatus, error: String? = nil) {
        studyGuideStatus = status
        studyGuideError = error
        updatedAt = Date()
        needsSync = true
    }
}

// MARK: - GRDB Support
// Note: nonisolated to prevent MainActor inference from -default-isolation=MainActor
nonisolated extension Sermon: FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "sermons" }

    enum Columns: String, ColumnExpression {
        case id
        case userId = "user_id"
        case title
        case speakerName = "speaker_name"
        case recordedAt = "recorded_at"
        case durationSeconds = "duration_seconds"
        case localAudioPath = "local_audio_path"
        case remoteAudioPath = "remote_audio_path"
        case audioFileSize = "audio_file_size"
        case audioMimeType = "audio_mime_type"
        case audioCodec = "audio_codec"
        case audioBitrateKbps = "audio_bitrate_kbps"
        case audioContentHash = "audio_content_hash"
        case transcriptionStatus = "transcription_status"
        case transcriptionError = "transcription_error"
        case studyGuideStatus = "study_guide_status"
        case studyGuideError = "study_guide_error"
        case processingVersion = "processing_version"
        case scriptureReferences = "scripture_references"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case needsSync = "needs_sync"
        case audioNeedsUpload = "audio_needs_upload"
    }

    init(row: Row) {
        id = row[Columns.id]
        userId = row[Columns.userId]
        title = row[Columns.title]
        speakerName = row[Columns.speakerName]
        recordedAt = row[Columns.recordedAt]
        durationSeconds = row[Columns.durationSeconds]
        localAudioPath = row[Columns.localAudioPath]
        remoteAudioPath = row[Columns.remoteAudioPath]
        audioFileSize = row[Columns.audioFileSize]
        audioMimeType = row[Columns.audioMimeType]
        audioCodec = row[Columns.audioCodec]
        audioBitrateKbps = row[Columns.audioBitrateKbps]
        audioContentHash = row[Columns.audioContentHash]

        let transcriptionRaw: String? = row[Columns.transcriptionStatus]
        let studyGuideRaw: String? = row[Columns.studyGuideStatus]

        if let statusString = transcriptionRaw {
            transcriptionStatus = SermonProcessingStatus(rawValue: statusString) ?? .pending
        } else {
            transcriptionStatus = .pending
        }
        transcriptionError = row[Columns.transcriptionError]

        if let statusString = studyGuideRaw {
            studyGuideStatus = SermonProcessingStatus(rawValue: statusString) ?? .pending
        } else {
            studyGuideStatus = .pending
        }
        studyGuideError = row[Columns.studyGuideError]

        processingVersion = row[Columns.processingVersion] ?? "1"

        if let refsString: String = row[Columns.scriptureReferences],
           let data = refsString.data(using: .utf8),
           let refs = try? JSONCodingUtilities.decode([String].self, from: data) {
            scriptureReferences = refs
        } else {
            scriptureReferences = []
        }

        createdAt = row[Columns.createdAt]
        updatedAt = row[Columns.updatedAt]
        deletedAt = row[Columns.deletedAt]
        needsSync = row[Columns.needsSync]
        audioNeedsUpload = row[Columns.audioNeedsUpload]
    }

    func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.userId] = userId
        container[Columns.title] = title
        container[Columns.speakerName] = speakerName
        container[Columns.recordedAt] = recordedAt
        container[Columns.durationSeconds] = durationSeconds
        container[Columns.localAudioPath] = localAudioPath
        container[Columns.remoteAudioPath] = remoteAudioPath
        container[Columns.audioFileSize] = audioFileSize
        container[Columns.audioMimeType] = audioMimeType
        container[Columns.audioCodec] = audioCodec
        container[Columns.audioBitrateKbps] = audioBitrateKbps
        container[Columns.audioContentHash] = audioContentHash
        container[Columns.transcriptionStatus] = transcriptionStatus.rawValue
        container[Columns.transcriptionError] = transcriptionError
        container[Columns.studyGuideStatus] = studyGuideStatus.rawValue
        container[Columns.studyGuideError] = studyGuideError
        container[Columns.processingVersion] = processingVersion

        if let data = try? JSONCodingUtilities.encode(scriptureReferences),
           let jsonString = String(data: data, encoding: .utf8) {
            container[Columns.scriptureReferences] = jsonString
        } else {
            container[Columns.scriptureReferences] = "[]"
        }

        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt
        container[Columns.deletedAt] = deletedAt
        container[Columns.needsSync] = needsSync
        container[Columns.audioNeedsUpload] = audioNeedsUpload
    }
}

// MARK: - DTO for Supabase Sync
struct SermonDTO: Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let speakerName: String?
    let recordedAt: Date
    let durationSeconds: Int
    let localAudioPath: String?
    let remoteAudioPath: String?
    let audioFileSize: Int?
    let audioMimeType: String?
    let audioCodec: String?
    let audioBitrateKbps: Int?
    let audioContentHash: String?
    let transcriptionStatus: String
    let transcriptionError: String?
    let studyGuideStatus: String
    let studyGuideError: String?
    let processingVersion: String
    let scriptureReferences: [String]
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case speakerName = "speaker_name"
        case recordedAt = "recorded_at"
        case durationSeconds = "duration_seconds"
        case localAudioPath = "local_audio_path"
        case remoteAudioPath = "remote_audio_path"
        case audioFileSize = "audio_file_size"
        case audioMimeType = "audio_mime_type"
        case audioCodec = "audio_codec"
        case audioBitrateKbps = "audio_bitrate_kbps"
        case audioContentHash = "audio_content_hash"
        case transcriptionStatus = "transcription_status"
        case transcriptionError = "transcription_error"
        case studyGuideStatus = "study_guide_status"
        case studyGuideError = "study_guide_error"
        case processingVersion = "processing_version"
        case scriptureReferences = "scripture_references"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

// MARK: - Conversion
extension Sermon {
    init(from dto: SermonDTO) {
        self.id = dto.id
        self.userId = dto.userId
        self.title = dto.title
        self.speakerName = dto.speakerName
        self.recordedAt = dto.recordedAt
        self.durationSeconds = dto.durationSeconds
        self.localAudioPath = dto.localAudioPath
        self.remoteAudioPath = dto.remoteAudioPath
        self.audioFileSize = dto.audioFileSize
        self.audioMimeType = dto.audioMimeType
        self.audioCodec = dto.audioCodec
        self.audioBitrateKbps = dto.audioBitrateKbps
        self.audioContentHash = dto.audioContentHash
        self.transcriptionStatus = SermonProcessingStatus(rawValue: dto.transcriptionStatus) ?? .pending
        self.transcriptionError = dto.transcriptionError
        self.studyGuideStatus = SermonProcessingStatus(rawValue: dto.studyGuideStatus) ?? .pending
        self.studyGuideError = dto.studyGuideError
        self.processingVersion = dto.processingVersion
        self.scriptureReferences = dto.scriptureReferences
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
        self.deletedAt = dto.deletedAt
        self.needsSync = false
        self.audioNeedsUpload = false
    }

    func toDTO() -> SermonDTO {
        SermonDTO(
            id: id,
            userId: userId,
            title: title,
            speakerName: speakerName,
            recordedAt: recordedAt,
            durationSeconds: durationSeconds,
            localAudioPath: localAudioPath,
            remoteAudioPath: remoteAudioPath,
            audioFileSize: audioFileSize,
            audioMimeType: audioMimeType,
            audioCodec: audioCodec,
            audioBitrateKbps: audioBitrateKbps,
            audioContentHash: audioContentHash,
            transcriptionStatus: transcriptionStatus.rawValue,
            transcriptionError: transcriptionError,
            studyGuideStatus: studyGuideStatus.rawValue,
            studyGuideError: studyGuideError,
            processingVersion: processingVersion,
            scriptureReferences: scriptureReferences,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}

import Foundation
import GRDB

// MARK: - Upload Status
enum ChunkUploadStatus: String, Codable, Sendable {
    case pending
    case uploading
    case succeeded
    case failed
}

// MARK: - Sermon Audio Chunk
// Individual audio segment for chunked recording/playback
struct SermonAudioChunk: Identifiable, Hashable, Sendable {
    let id: UUID
    let sermonId: UUID
    let chunkIndex: Int
    let startOffsetSeconds: Double
    var durationSeconds: Double

    // Paths
    var localPath: String?
    var remotePath: String?

    // File metadata
    var fileSize: Int?
    var contentHash: String?

    // Upload tracking
    var uploadStatus: ChunkUploadStatus
    var uploadError: String?
    var uploadProgress: Double

    // Transcription tracking (per-chunk)
    var transcriptionStatus: SermonProcessingStatus
    var transcriptionError: String?
    var transcriptSegment: TranscriptSegment?

    // Waveform data (downsampled for UI)
    var waveformSamples: [Float]?

    let createdAt: Date
    var updatedAt: Date
    var needsSync: Bool

    // MARK: - Computed Properties

    var endOffsetSeconds: Double {
        startOffsetSeconds + durationSeconds
    }

    var isUploaded: Bool {
        uploadStatus == .succeeded
    }

    var isTranscribed: Bool {
        transcriptionStatus == .succeeded
    }

    var formattedTimeRange: String {
        let start = formatTime(startOffsetSeconds)
        let end = formatTime(endOffsetSeconds)
        return "\(start) - \(end)"
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        sermonId: UUID,
        chunkIndex: Int,
        startOffsetSeconds: Double,
        durationSeconds: Double = 0,
        localPath: String? = nil,
        remotePath: String? = nil,
        fileSize: Int? = nil,
        contentHash: String? = nil,
        uploadStatus: ChunkUploadStatus = .pending,
        uploadError: String? = nil,
        uploadProgress: Double = 0,
        transcriptionStatus: SermonProcessingStatus = .pending,
        transcriptionError: String? = nil,
        transcriptSegment: TranscriptSegment? = nil,
        waveformSamples: [Float]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        needsSync: Bool = false
    ) {
        self.id = id
        self.sermonId = sermonId
        self.chunkIndex = chunkIndex
        self.startOffsetSeconds = startOffsetSeconds
        self.durationSeconds = durationSeconds
        self.localPath = localPath
        self.remotePath = remotePath
        self.fileSize = fileSize
        self.contentHash = contentHash
        self.uploadStatus = uploadStatus
        self.uploadError = uploadError
        self.uploadProgress = uploadProgress
        self.transcriptionStatus = transcriptionStatus
        self.transcriptionError = transcriptionError
        self.transcriptSegment = transcriptSegment
        self.waveformSamples = waveformSamples
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.needsSync = needsSync
    }

    // MARK: - Mutations

    mutating func updateUploadStatus(_ status: ChunkUploadStatus, progress: Double = 0, error: String? = nil) {
        uploadStatus = status
        uploadProgress = progress
        uploadError = error
        updatedAt = Date()
        needsSync = true
    }

    mutating func updateTranscriptionStatus(_ status: SermonProcessingStatus, error: String? = nil) {
        transcriptionStatus = status
        transcriptionError = error
        updatedAt = Date()
        needsSync = true
    }
}

// MARK: - Transcript Segment
// Transcription result for a single chunk
// Note: nonisolated to prevent MainActor inference on Codable conformance from -default-isolation=MainActor
nonisolated struct TranscriptSegment: Codable, Hashable, Sendable {
    let text: String
    let startTime: Double
    let endTime: Double
    let words: [WordTimestamp]?

    nonisolated struct WordTimestamp: Codable, Hashable, Sendable {
        let word: String
        let start: Double
        let end: Double
    }
}

// MARK: - GRDB Support
// Note: nonisolated to prevent MainActor inference from -default-isolation=MainActor
nonisolated extension SermonAudioChunk: FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "sermon_audio_chunks" }

    enum Columns: String, ColumnExpression {
        case id
        case sermonId = "sermon_id"
        case chunkIndex = "chunk_index"
        case startOffsetSeconds = "start_offset_seconds"
        case durationSeconds = "duration_seconds"
        case localPath = "local_path"
        case remotePath = "remote_path"
        case fileSize = "file_size"
        case contentHash = "content_hash"
        case uploadStatus = "upload_status"
        case uploadError = "upload_error"
        case uploadProgress = "upload_progress"
        case transcriptionStatus = "transcription_status"
        case transcriptionError = "transcription_error"
        case transcriptSegment = "transcript_segment"
        case waveformSamples = "waveform_samples"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case needsSync = "needs_sync"
    }

    nonisolated init(row: Row) {
        id = row[Columns.id]
        sermonId = row[Columns.sermonId]
        chunkIndex = row[Columns.chunkIndex]
        startOffsetSeconds = row[Columns.startOffsetSeconds]
        durationSeconds = row[Columns.durationSeconds]
        localPath = row[Columns.localPath]
        remotePath = row[Columns.remotePath]
        fileSize = row[Columns.fileSize]
        contentHash = row[Columns.contentHash]

        if let statusString: String = row[Columns.uploadStatus] {
            uploadStatus = ChunkUploadStatus(rawValue: statusString) ?? .pending
        } else {
            uploadStatus = .pending
        }
        uploadError = row[Columns.uploadError]
        uploadProgress = row[Columns.uploadProgress] ?? 0

        if let statusString: String = row[Columns.transcriptionStatus] {
            transcriptionStatus = SermonProcessingStatus(rawValue: statusString) ?? .pending
        } else {
            transcriptionStatus = .pending
        }
        transcriptionError = row[Columns.transcriptionError]

        if let segmentString: String = row[Columns.transcriptSegment],
           let data = segmentString.data(using: .utf8) {
            transcriptSegment = try? JSONDecoder().decode(TranscriptSegment.self, from: data)
        } else {
            transcriptSegment = nil
        }

        if let samplesString: String = row[Columns.waveformSamples],
           let data = samplesString.data(using: .utf8) {
            waveformSamples = try? JSONDecoder().decode([Float].self, from: data)
        } else {
            waveformSamples = nil
        }

        createdAt = row[Columns.createdAt]
        updatedAt = row[Columns.updatedAt]
        needsSync = row[Columns.needsSync]
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.sermonId] = sermonId
        container[Columns.chunkIndex] = chunkIndex
        container[Columns.startOffsetSeconds] = startOffsetSeconds
        container[Columns.durationSeconds] = durationSeconds
        container[Columns.localPath] = localPath
        container[Columns.remotePath] = remotePath
        container[Columns.fileSize] = fileSize
        container[Columns.contentHash] = contentHash
        container[Columns.uploadStatus] = uploadStatus.rawValue
        container[Columns.uploadError] = uploadError
        container[Columns.uploadProgress] = uploadProgress
        container[Columns.transcriptionStatus] = transcriptionStatus.rawValue
        container[Columns.transcriptionError] = transcriptionError

        if let segment = transcriptSegment,
           let data = try? JSONEncoder().encode(segment),
           let jsonString = String(data: data, encoding: .utf8) {
            container[Columns.transcriptSegment] = jsonString
        } else {
            container[Columns.transcriptSegment] = nil
        }

        if let samples = waveformSamples,
           let data = try? JSONEncoder().encode(samples),
           let jsonString = String(data: data, encoding: .utf8) {
            container[Columns.waveformSamples] = jsonString
        } else {
            container[Columns.waveformSamples] = nil
        }

        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt
        container[Columns.needsSync] = needsSync
    }
}

// MARK: - DTO for Supabase Sync
struct SermonAudioChunkDTO: Codable {
    let id: UUID
    let sermonId: UUID
    let chunkIndex: Int
    let startOffsetSeconds: Double
    let durationSeconds: Double
    let localPath: String?
    let remotePath: String?
    let fileSize: Int?
    let contentHash: String?
    let uploadStatus: String
    let uploadError: String?
    let uploadProgress: Double
    let transcriptionStatus: String
    let transcriptionError: String?
    let transcriptSegment: TranscriptSegment?
    let waveformSamples: [Float]?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sermonId = "sermon_id"
        case chunkIndex = "chunk_index"
        case startOffsetSeconds = "start_offset_seconds"
        case durationSeconds = "duration_seconds"
        case localPath = "local_path"
        case remotePath = "remote_path"
        case fileSize = "file_size"
        case contentHash = "content_hash"
        case uploadStatus = "upload_status"
        case uploadError = "upload_error"
        case uploadProgress = "upload_progress"
        case transcriptionStatus = "transcription_status"
        case transcriptionError = "transcription_error"
        case transcriptSegment = "transcript_segment"
        case waveformSamples = "waveform_samples"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Conversion
extension SermonAudioChunk {
    init(from dto: SermonAudioChunkDTO) {
        self.id = dto.id
        self.sermonId = dto.sermonId
        self.chunkIndex = dto.chunkIndex
        self.startOffsetSeconds = dto.startOffsetSeconds
        self.durationSeconds = dto.durationSeconds
        self.localPath = dto.localPath
        self.remotePath = dto.remotePath
        self.fileSize = dto.fileSize
        self.contentHash = dto.contentHash
        self.uploadStatus = ChunkUploadStatus(rawValue: dto.uploadStatus) ?? .pending
        self.uploadError = dto.uploadError
        self.uploadProgress = dto.uploadProgress
        self.transcriptionStatus = SermonProcessingStatus(rawValue: dto.transcriptionStatus) ?? .pending
        self.transcriptionError = dto.transcriptionError
        self.transcriptSegment = dto.transcriptSegment
        self.waveformSamples = dto.waveformSamples
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
        self.needsSync = false
    }

    func toDTO() -> SermonAudioChunkDTO {
        SermonAudioChunkDTO(
            id: id,
            sermonId: sermonId,
            chunkIndex: chunkIndex,
            startOffsetSeconds: startOffsetSeconds,
            durationSeconds: durationSeconds,
            localPath: localPath,
            remotePath: remotePath,
            fileSize: fileSize,
            contentHash: contentHash,
            uploadStatus: uploadStatus.rawValue,
            uploadError: uploadError,
            uploadProgress: uploadProgress,
            transcriptionStatus: transcriptionStatus.rawValue,
            transcriptionError: transcriptionError,
            transcriptSegment: transcriptSegment,
            waveformSamples: waveformSamples,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

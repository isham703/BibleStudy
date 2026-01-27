import Foundation
import GRDB

// MARK: - Sermon Transcript
// Full transcription of a sermon with word-level timestamps
struct SermonTranscript: Identifiable, Hashable, Sendable {
    let id: UUID
    let sermonId: UUID
    var content: String
    var language: String
    var wordTimestamps: [WordTimestamp]
    var correctionOverlays: [CorrectionOverlay]
    var modelUsed: String?
    var confidenceScore: Double?
    let createdAt: Date
    var updatedAt: Date
    var needsSync: Bool

    // MARK: - Word Timestamp
    struct WordTimestamp: Codable, Hashable, Sendable {
        let word: String
        let start: Double
        let end: Double
    }

    // MARK: - Computed Properties

    var wordCount: Int {
        content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    /// Content with correction overlays applied for display.
    /// Use this for UI rendering and reference detection.
    var correctedContent: String {
        guard !correctionOverlays.isEmpty, !wordTimestamps.isEmpty else {
            return content
        }
        return BiblicalTermCorrector.applyCorrections(
            to: wordTimestamps,
            corrections: correctionOverlays
        )
    }

    /// Whether this transcript has any corrections applied
    var hasCorrections: Bool {
        !correctionOverlays.isEmpty
    }

    /// Display segments for UI rendering (cached for performance)
    /// Access via MainActor for cached results, or use computeSegments() for direct computation
    @MainActor
    var segments: [TranscriptDisplaySegment] {
        TranscriptSegmentCache.shared.getSegments(for: self) {
            Self.computeSegments(from: wordTimestamps, content: content)
        }
    }

    /// Compute segments directly (O(n) - use cached version when possible)
    static func computeSegments(
        from wordTimestamps: [WordTimestamp],
        content: String
    ) -> [TranscriptDisplaySegment] {
        // Group words into display segments (~10-15 seconds each)
        guard !wordTimestamps.isEmpty else {
            return [TranscriptDisplaySegment(
                text: content,
                startTime: 0,
                endTime: 0,
                wordRange: 0..<0
            )]
        }

        var segments: [TranscriptDisplaySegment] = []
        let segmentDuration: Double = 12.0  // ~12 seconds per segment

        var segmentStart = 0
        var segmentStartTime = wordTimestamps.first?.start ?? 0

        for (index, word) in wordTimestamps.enumerated() {
            let timeSinceSegmentStart = word.end - segmentStartTime

            // Start new segment if we've exceeded duration or hit punctuation
            let shouldBreak = timeSinceSegmentStart >= segmentDuration ||
                              (word.word.hasSuffix(".") && timeSinceSegmentStart >= 5.0)

            if shouldBreak && index > segmentStart {
                let segmentWords = Array(wordTimestamps[segmentStart...index])
                let text = segmentWords.map(\.word).joined(separator: " ")
                let endTime = segmentWords.last?.end ?? word.end

                segments.append(TranscriptDisplaySegment(
                    text: text,
                    startTime: segmentStartTime,
                    endTime: endTime,
                    wordRange: segmentStart..<(index + 1)
                ))

                segmentStart = index + 1
                segmentStartTime = wordTimestamps[safe: index + 1]?.start ?? word.end
            }
        }

        // Add final segment
        if segmentStart < wordTimestamps.count {
            let segmentWords = Array(wordTimestamps[segmentStart...])
            let text = segmentWords.map(\.word).joined(separator: " ")
            let endTime = segmentWords.last?.end ?? 0

            segments.append(TranscriptDisplaySegment(
                text: text,
                startTime: segmentStartTime,
                endTime: endTime,
                wordRange: segmentStart..<wordTimestamps.count
            ))
        }

        return segments
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        sermonId: UUID,
        content: String,
        language: String = "en",
        wordTimestamps: [WordTimestamp] = [],
        correctionOverlays: [CorrectionOverlay] = [],
        modelUsed: String? = nil,
        confidenceScore: Double? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        needsSync: Bool = false
    ) {
        self.id = id
        self.sermonId = sermonId
        self.content = content
        self.language = language
        self.wordTimestamps = wordTimestamps
        self.correctionOverlays = correctionOverlays
        self.modelUsed = modelUsed
        self.confidenceScore = confidenceScore
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.needsSync = needsSync
    }

    // MARK: - Methods

    /// Find the word index at a given timestamp
    func wordIndex(at time: Double) -> Int? {
        wordTimestamps.firstIndex { time >= $0.start && time < $0.end }
    }

    /// Find the segment index containing a given timestamp (uses cached segments)
    @MainActor
    func segmentIndex(at time: Double) -> Int? {
        segments.firstIndex { time >= $0.startTime && time < $0.endTime }
    }
}

// MARK: - Transcript Display Segment
// A segment of transcript for display (grouped words)
struct TranscriptDisplaySegment: Identifiable, Hashable, Sendable {
    let id = UUID()
    let text: String
    let startTime: Double
    let endTime: Double
    let wordRange: Range<Int>

    var duration: Double {
        endTime - startTime
    }
}

// MARK: - Safe Array Access
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - GRDB Support
extension SermonTranscript: FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "sermon_transcripts" }

    enum Columns: String, ColumnExpression {
        case id
        case sermonId = "sermon_id"
        case content
        case language
        case wordTimestamps = "word_timestamps"
        case correctionOverlays = "correction_overlays"
        case modelUsed = "model_used"
        case confidenceScore = "confidence_score"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case needsSync = "needs_sync"
    }

    nonisolated init(row: Row) {
        id = row[Columns.id]
        sermonId = row[Columns.sermonId]
        content = row[Columns.content]
        language = row[Columns.language] ?? "en"

        if let timestampsString: String = row[Columns.wordTimestamps],
           let data = timestampsString.data(using: .utf8) {
            wordTimestamps = (try? JSONCodingUtilities.decode([WordTimestamp].self, from: data)) ?? []
        } else {
            wordTimestamps = []
        }

        if let overlaysString: String = row[Columns.correctionOverlays],
           let data = overlaysString.data(using: .utf8) {
            correctionOverlays = (try? JSONCodingUtilities.decode([CorrectionOverlay].self, from: data)) ?? []
        } else {
            correctionOverlays = []
        }

        modelUsed = row[Columns.modelUsed]
        confidenceScore = row[Columns.confidenceScore]
        createdAt = row[Columns.createdAt]
        updatedAt = row[Columns.updatedAt]
        needsSync = row[Columns.needsSync]
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.sermonId] = sermonId
        container[Columns.content] = content
        container[Columns.language] = language

        if let data = try? JSONCodingUtilities.encode(wordTimestamps),
           let jsonString = String(data: data, encoding: .utf8) {
            container[Columns.wordTimestamps] = jsonString
        } else {
            container[Columns.wordTimestamps] = "[]"
        }

        if let data = try? JSONCodingUtilities.encode(correctionOverlays),
           let jsonString = String(data: data, encoding: .utf8) {
            container[Columns.correctionOverlays] = jsonString
        } else {
            container[Columns.correctionOverlays] = "[]"
        }

        container[Columns.modelUsed] = modelUsed
        container[Columns.confidenceScore] = confidenceScore
        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt
        container[Columns.needsSync] = needsSync
    }
}

// MARK: - DTO for Supabase Sync
struct SermonTranscriptDTO: Codable {
    let id: UUID
    let sermonId: UUID
    let content: String
    let language: String
    let wordTimestamps: [SermonTranscript.WordTimestamp]
    let correctionOverlays: [CorrectionOverlay]?
    let modelUsed: String?
    let confidenceScore: Double?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sermonId = "sermon_id"
        case content
        case language
        case wordTimestamps = "word_timestamps"
        case correctionOverlays = "correction_overlays"
        case modelUsed = "model_used"
        case confidenceScore = "confidence_score"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Conversion
extension SermonTranscript {
    init(from dto: SermonTranscriptDTO) {
        self.id = dto.id
        self.sermonId = dto.sermonId
        self.content = dto.content
        self.language = dto.language
        self.wordTimestamps = dto.wordTimestamps
        self.correctionOverlays = dto.correctionOverlays ?? []
        self.modelUsed = dto.modelUsed
        self.confidenceScore = dto.confidenceScore
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
        self.needsSync = false
    }

    func toDTO() -> SermonTranscriptDTO {
        SermonTranscriptDTO(
            id: id,
            sermonId: sermonId,
            content: content,
            language: language,
            wordTimestamps: wordTimestamps,
            correctionOverlays: correctionOverlays.isEmpty ? nil : correctionOverlays,
            modelUsed: modelUsed,
            confidenceScore: confidenceScore,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

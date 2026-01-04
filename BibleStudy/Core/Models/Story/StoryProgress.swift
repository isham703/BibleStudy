import Foundation
import GRDB

// MARK: - Story Progress
// Tracks user progress through a story

struct StoryProgress: Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let storyId: UUID
    var currentSegmentIndex: Int        // Which segment user is on
    var completedSegmentIds: Set<UUID>  // Segments marked complete
    let startedAt: Date
    var lastReadAt: Date
    var completedAt: Date?
    var reflectionNotes: [UUID: String] // segmentId -> user's reflection

    // Sync tracking
    var needsSync: Bool = false

    // MARK: - Computed Properties

    var isCompleted: Bool {
        completedAt != nil
    }

    var isStarted: Bool {
        !completedSegmentIds.isEmpty || currentSegmentIndex > 0
    }

    func progressPercentage(totalSegments: Int) -> Double {
        guard totalSegments > 0 else { return 0 }
        return Double(completedSegmentIds.count) / Double(totalSegments)
    }

    func segmentsRemaining(totalSegments: Int) -> Int {
        max(0, totalSegments - completedSegmentIds.count)
    }

    // MARK: - Initializers

    init(
        id: UUID = UUID(),
        userId: UUID,
        storyId: UUID,
        currentSegmentIndex: Int = 0,
        completedSegmentIds: Set<UUID> = [],
        startedAt: Date = Date(),
        lastReadAt: Date = Date(),
        completedAt: Date? = nil,
        reflectionNotes: [UUID: String] = [:],
        needsSync: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.storyId = storyId
        self.currentSegmentIndex = currentSegmentIndex
        self.completedSegmentIds = completedSegmentIds
        self.startedAt = startedAt
        self.lastReadAt = lastReadAt
        self.completedAt = completedAt
        self.reflectionNotes = reflectionNotes
        self.needsSync = needsSync
    }

    // MARK: - Mutations

    mutating func markSegmentComplete(_ segmentId: UUID) {
        completedSegmentIds.insert(segmentId)
        lastReadAt = Date()
        needsSync = true
    }

    mutating func advanceToSegment(_ index: Int) {
        currentSegmentIndex = index
        lastReadAt = Date()
        needsSync = true
    }

    mutating func saveReflection(_ text: String, for segmentId: UUID) {
        reflectionNotes[segmentId] = text
        lastReadAt = Date()
        needsSync = true
    }

    mutating func markCompleted() {
        completedAt = Date()
        lastReadAt = Date()
        needsSync = true
    }

    mutating func reset() {
        currentSegmentIndex = 0
        completedSegmentIds = []
        completedAt = nil
        reflectionNotes = [:]
        lastReadAt = Date()
        needsSync = true
    }
}

// MARK: - GRDB Support
extension StoryProgress: FetchableRecord, PersistableRecord {
    nonisolated static var databaseTableName: String { "story_progress" }

    enum Columns: String, ColumnExpression {
        case id
        case userId = "user_id"
        case storyId = "story_id"
        case currentSegmentIndex = "current_segment_index"
        case completedSegmentIds = "completed_segment_ids"
        case startedAt = "started_at"
        case lastReadAt = "last_read_at"
        case completedAt = "completed_at"
        case reflectionNotes = "reflection_notes"
        case needsSync = "needs_sync"
    }

    nonisolated init(row: Row) {
        id = row[Columns.id]
        userId = row[Columns.userId]
        storyId = row[Columns.storyId]
        currentSegmentIndex = row[Columns.currentSegmentIndex]
        startedAt = row[Columns.startedAt]
        lastReadAt = row[Columns.lastReadAt]
        completedAt = row[Columns.completedAt]
        needsSync = row[Columns.needsSync]

        // Decode JSON fields
        if let idsJSON: String = row[Columns.completedSegmentIds],
           let data = idsJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([UUID].self, from: data) {
            completedSegmentIds = Set(decoded)
        } else {
            completedSegmentIds = []
        }

        if let notesJSON: String = row[Columns.reflectionNotes],
           let data = notesJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            // Convert String keys back to UUID keys
            reflectionNotes = Dictionary(
                uniqueKeysWithValues: decoded.compactMap { key, value in
                    guard let uuid = UUID(uuidString: key) else { return nil }
                    return (uuid, value)
                }
            )
        } else {
            reflectionNotes = [:]
        }
    }

    nonisolated func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.userId] = userId
        container[Columns.storyId] = storyId
        container[Columns.currentSegmentIndex] = currentSegmentIndex
        container[Columns.startedAt] = startedAt
        container[Columns.lastReadAt] = lastReadAt
        container[Columns.completedAt] = completedAt
        container[Columns.needsSync] = needsSync

        // Encode JSON fields
        let idsArray = Array(completedSegmentIds)
        if let data = try? JSONEncoder().encode(idsArray),
           let json = String(data: data, encoding: .utf8) {
            container[Columns.completedSegmentIds] = json
        } else {
            container[Columns.completedSegmentIds] = "[]"
        }

        // Convert UUID keys to String keys for JSON encoding
        let notesDict = Dictionary(
            uniqueKeysWithValues: reflectionNotes.map { ($0.key.uuidString, $0.value) }
        )
        if let data = try? JSONEncoder().encode(notesDict),
           let json = String(data: data, encoding: .utf8) {
            container[Columns.reflectionNotes] = json
        } else {
            container[Columns.reflectionNotes] = "{}"
        }
    }
}


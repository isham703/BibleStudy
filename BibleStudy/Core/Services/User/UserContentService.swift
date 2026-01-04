import Foundation
import GRDB
import Auth

// MARK: - User Content Service
// Manages highlights and notes with offline-first sync

@MainActor
@Observable
final class UserContentService {
    // MARK: - Singleton
    static let shared = UserContentService()

    // MARK: - Properties
    private let supabase = SupabaseManager.shared
    private let db = DatabaseManager.shared
    private let entitlementManager = EntitlementManager.shared

    var highlights: [Highlight] = []
    var notes: [Note] = []
    var isLoading: Bool = false
    var error: Error?

    // MARK: - Initialization
    private init() {}

    // MARK: - Load Content

    func loadContent() async {
        guard let userId = supabase.currentUser?.id else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Load from local cache first
            try loadFromCache(userId: userId)

            // Then sync with remote
            try await syncWithRemote()
        } catch {
            self.error = error
        }
    }

    private nonisolated func fetchHighlightsFromCache(userId: UUID, dbQueue: DatabaseQueue) throws -> [Highlight] {
        return try dbQueue.read { db in
            try Highlight
                .filter(Highlight.Columns.userId == userId.uuidString)
                .filter(Highlight.Columns.deletedAt == nil)
                .order(Highlight.Columns.createdAt.desc)
                .fetchAll(db)
        }
    }

    private nonisolated func fetchNotesFromCache(userId: UUID, dbQueue: DatabaseQueue) throws -> [Note] {
        return try dbQueue.read { db in
            try Note
                .filter(Note.Columns.userId == userId.uuidString)
                .filter(Note.Columns.deletedAt == nil)
                .order(Note.Columns.updatedAt.desc)
                .fetchAll(db)
        }
    }

    private func loadFromCache(userId: UUID) throws {
        guard let dbQueue = db.dbQueue else { return }
        highlights = try fetchHighlightsFromCache(userId: userId, dbQueue: dbQueue)
        notes = try fetchNotesFromCache(userId: userId, dbQueue: dbQueue)
    }

    private nonisolated func saveHighlightsToCache(_ dtos: [HighlightDTO], dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            for dto in dtos {
                let highlight = Highlight(from: dto)
                try highlight.save(db)
            }
        }
    }

    private nonisolated func saveNotesToCache(_ dtos: [NoteDTO], dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            for dto in dtos {
                let note = Note(from: dto)
                try note.save(db)
            }
        }
    }

    private func syncWithRemote() async throws {
        // Fetch from Supabase
        let remoteHighlights = try await supabase.getHighlights()
        let remoteNotes = try await supabase.getNotes()

        // Update local cache
        guard let dbQueue = db.dbQueue else { return }
        try saveHighlightsToCache(remoteHighlights, dbQueue: dbQueue)
        try saveNotesToCache(remoteNotes, dbQueue: dbQueue)

        // Reload from cache
        if let userId = supabase.currentUser?.id {
            try loadFromCache(userId: userId)
        }

        // Push local changes
        try await pushLocalChanges()
    }

    private nonisolated func fetchHighlightsNeedingSync(dbQueue: DatabaseQueue) throws -> [Highlight] {
        return try dbQueue.read { db in
            try Highlight
                .filter(Highlight.Columns.needsSync == true)
                .fetchAll(db)
        }
    }

    private nonisolated func fetchNotesNeedingSync(dbQueue: DatabaseQueue) throws -> [Note] {
        return try dbQueue.read { db in
            try Note
                .filter(Note.Columns.needsSync == true)
                .fetchAll(db)
        }
    }

    private nonisolated func markHighlightSynced(_ highlight: Highlight, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            var updated = highlight
            updated.needsSync = false
            try updated.update(db)
        }
    }

    private nonisolated func markNoteSynced(_ note: Note, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            var updated = note
            updated.needsSync = false
            try updated.update(db)
        }
    }

    // MARK: - Highlight DB Helpers

    private nonisolated func saveHighlightToDB(_ highlight: Highlight, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try highlight.save(db)
        }
    }

    private nonisolated func updateHighlightInDB(_ highlight: Highlight, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try highlight.update(db)
        }
    }

    private nonisolated func softDeleteHighlightInDB(_ highlight: Highlight, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            var updated = highlight
            updated.deletedAt = Date()
            updated.needsSync = true
            try updated.update(db)
        }
    }

    // MARK: - Note DB Helpers

    private nonisolated func saveNoteToDB(_ note: Note, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try note.save(db)
        }
    }

    private nonisolated func updateNoteInDB(_ note: Note, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try note.update(db)
        }
    }

    private nonisolated func softDeleteNoteInDB(_ note: Note, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            var updated = note
            updated.deletedAt = Date()
            updated.needsSync = true
            try updated.update(db)
        }
    }

    private func pushLocalChanges() async throws {
        guard let dbQueue = db.dbQueue else { return }

        // Get items needing sync
        let highlightsToSync = try fetchHighlightsNeedingSync(dbQueue: dbQueue)
        let notesToSync = try fetchNotesNeedingSync(dbQueue: dbQueue)

        // Push highlights
        for highlight in highlightsToSync {
            if highlight.deletedAt != nil {
                try await supabase.deleteHighlight(id: highlight.id.uuidString)
            } else {
                try await supabase.createHighlight(highlight.toDTO())
            }

            // Mark as synced
            try markHighlightSynced(highlight, dbQueue: dbQueue)
        }

        // Push notes
        for note in notesToSync {
            if note.deletedAt != nil {
                try await supabase.deleteNote(id: note.id.uuidString)
            } else if try await noteExistsRemote(id: note.id) {
                try await supabase.updateNote(id: note.id.uuidString, content: note.content)
            } else {
                try await supabase.createNote(note.toDTO())
            }

            // Mark as synced
            try markNoteSynced(note, dbQueue: dbQueue)
        }
    }

    private func noteExistsRemote(id: UUID) async throws -> Bool {
        // Check if note exists on server
        // For now, assume new notes don't exist
        return false
    }

    // MARK: - Highlights

    func getHighlights(for range: VerseRange) -> [Highlight] {
        highlights.filter { highlight in
            highlight.bookId == range.bookId &&
            highlight.chapter == range.chapter &&
            highlight.verseStart <= range.verseEnd &&
            highlight.verseEnd >= range.verseStart
        }
    }

    func getHighlights(for chapter: Int, bookId: Int) -> [Highlight] {
        highlights.filter { $0.bookId == bookId && $0.chapter == chapter }
    }

    func createHighlight(
        for range: VerseRange,
        color: HighlightColor,
        category: HighlightCategory = .none
    ) async throws {
        guard let userId = supabase.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        guard let dbQueue = db.dbQueue else { return }

        // Check entitlement (will trigger paywall if limit reached)
        guard entitlementManager.recordHighlightUsage() else {
            throw EntitlementError.limitReached(.unlimitedHighlights)
        }

        var highlight = Highlight(userId: userId, range: range, color: color, category: category)

        // Save locally
        try saveHighlightToDB(highlight, dbQueue: dbQueue)

        highlights.insert(highlight, at: 0)

        // Sync to remote
        do {
            try await supabase.createHighlight(highlight.toDTO())
            highlight.needsSync = false
            try updateHighlightInDB(highlight, dbQueue: dbQueue)
        } catch {
            // Will sync later
            self.error = error
        }
    }

    func deleteHighlight(_ highlight: Highlight) async throws {
        guard let dbQueue = db.dbQueue else { return }

        // Soft delete locally
        try softDeleteHighlightInDB(highlight, dbQueue: dbQueue)

        highlights.removeAll { $0.id == highlight.id }

        // Sync to remote
        do {
            try await supabase.deleteHighlight(id: highlight.id.uuidString)
        } catch {
            self.error = error
        }
    }

    // MARK: - Notes

    func getNotes(for range: VerseRange) -> [Note] {
        notes.filter { note in
            note.bookId == range.bookId &&
            note.chapter == range.chapter &&
            note.verseStart <= range.verseEnd &&
            note.verseEnd >= range.verseStart
        }
    }

    func getNotes(for chapter: Int, bookId: Int) -> [Note] {
        notes.filter { $0.bookId == bookId && $0.chapter == chapter }
    }

    func createNote(for range: VerseRange, content: String, template: NoteTemplate = .freeform, linkedNoteIds: [UUID] = []) async throws {
        guard let userId = supabase.currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        guard let dbQueue = db.dbQueue else { return }

        // Validate content length (applies to all users)
        guard content.count <= Note.maxContentLength else {
            throw ContentError.contentTooLong(limit: Note.maxContentLength)
        }

        // Validate byte size to prevent Unicode exploitation (200KB = 4 bytes/char worst case)
        guard content.utf8.count <= 200000 else {
            throw ContentError.contentTooLarge(byteLimit: 200000)
        }

        var note = Note(
            userId: userId,
            bookId: range.bookId,
            chapter: range.chapter,
            verseStart: range.verseStart,
            verseEnd: range.verseEnd,
            content: content,
            template: template,
            linkedNoteIds: linkedNoteIds,
            needsSync: true
        )

        // Save locally
        try saveNoteToDB(note, dbQueue: dbQueue)

        notes.insert(note, at: 0)

        // Sync to remote
        do {
            try await supabase.createNote(note.toDTO())
            note.needsSync = false
            try updateNoteInDB(note, dbQueue: dbQueue)
        } catch {
            self.error = error
        }
    }

    func updateNote(_ note: Note, content: String) async throws {
        guard let dbQueue = db.dbQueue else { return }

        // Validate content length (applies to all users)
        guard content.count <= Note.maxContentLength else {
            throw ContentError.contentTooLong(limit: Note.maxContentLength)
        }

        // Validate byte size to prevent Unicode exploitation (200KB = 4 bytes/char worst case)
        guard content.utf8.count <= 200000 else {
            throw ContentError.contentTooLarge(byteLimit: 200000)
        }

        var updated = note
        updated.updateContent(content)

        try updateNoteInDB(updated, dbQueue: dbQueue)

        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = updated
        }

        // Sync to remote
        do {
            try await supabase.updateNote(id: note.id.uuidString, content: content, template: note.template.rawValue)
        } catch {
            self.error = error
        }
    }

    func updateNote(_ note: Note) async throws {
        guard let dbQueue = db.dbQueue else { return }

        // Validate content length (applies to all users)
        guard note.content.count <= Note.maxContentLength else {
            throw ContentError.contentTooLong(limit: Note.maxContentLength)
        }

        // Validate byte size to prevent Unicode exploitation (200KB = 4 bytes/char worst case)
        guard note.content.utf8.count <= 200000 else {
            throw ContentError.contentTooLarge(byteLimit: 200000)
        }

        try updateNoteInDB(note, dbQueue: dbQueue)

        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }

        // Sync to remote
        do {
            try await supabase.updateNote(id: note.id.uuidString, content: note.content, template: note.template.rawValue)
        } catch {
            self.error = error
        }
    }

    func deleteNote(_ note: Note) async throws {
        guard let dbQueue = db.dbQueue else { return }

        // Soft delete locally
        try softDeleteNoteInDB(note, dbQueue: dbQueue)

        notes.removeAll { $0.id == note.id }

        // Sync to remote
        do {
            try await supabase.deleteNote(id: note.id.uuidString)
        } catch {
            self.error = error
        }
    }

    // MARK: - Note Linking

    func getNote(by id: UUID) -> Note? {
        notes.first { $0.id == id }
    }

    func getLinkedNotes(for note: Note) -> [Note] {
        note.linkedNoteIds.compactMap { getNote(by: $0) }
    }

    func addNoteLink(from sourceNote: Note, to targetNoteId: UUID) async throws {
        guard sourceNote.id != targetNoteId else { return }
        guard let dbQueue = db.dbQueue else { return }

        var updatedNote = sourceNote
        updatedNote.addLink(to: targetNoteId)

        try updateNoteInDB(updatedNote, dbQueue: dbQueue)

        if let index = notes.firstIndex(where: { $0.id == sourceNote.id }) {
            notes[index] = updatedNote
        }

        // Sync to remote
        do {
            try await supabase.updateNote(id: sourceNote.id.uuidString, content: updatedNote.content, template: updatedNote.template.rawValue)
        } catch {
            self.error = error
        }
    }

    func removeNoteLink(from sourceNote: Note, to targetNoteId: UUID) async throws {
        guard let dbQueue = db.dbQueue else { return }

        var updatedNote = sourceNote
        updatedNote.removeLink(to: targetNoteId)

        try updateNoteInDB(updatedNote, dbQueue: dbQueue)

        if let index = notes.firstIndex(where: { $0.id == sourceNote.id }) {
            notes[index] = updatedNote
        }

        // Sync to remote
        do {
            try await supabase.updateNote(id: sourceNote.id.uuidString, content: updatedNote.content, template: updatedNote.template.rawValue)
        } catch {
            self.error = error
        }
    }

    /// Find all notes that link to the given note (backlinks)
    func getBacklinks(for note: Note) -> [Note] {
        notes.filter { $0.linkedNoteIds.contains(note.id) }
    }

    /// Search notes by content
    func searchNotes(query: String) -> [Note] {
        guard !query.isEmpty else { return notes }
        return notes.filter { note in
            note.content.localizedCaseInsensitiveContains(query) ||
            note.reference.localizedCaseInsensitiveContains(query)
        }
    }
}

import Foundation

// MARK: - Note Index
// Provides O(1) lookup for verse → notes
// Only indexes FIRST verse of multi-verse ranges (per requirement)

struct NoteIndex {
    // Maps each verse number to its notes (supports multiple notes per verse)
    private let verseMap: [Int: [Note]]

    // Store original notes for reference
    private let sourceNotes: [Note]

    // MARK: - Initialization

    /// Build index from notes array
    /// Only indexes the FIRST verse of each note's range (indicator appears on first verse only)
    init(notes: [Note]) {
        var map: [Int: [Note]] = [:]

        for note in notes {
            // Safety: normalize in case verseStart > verseEnd
            let firstVerse = min(note.verseStart, note.verseEnd)

            // Append to array (multiple notes can share same first verse)
            map[firstVerse, default: []].append(note)
        }

        // Sort notes within each verse by updatedAt (most recent first)
        for (verse, noteArray) in map {
            map[verse] = noteArray.sorted { $0.updatedAt > $1.updatedAt }
        }

        self.verseMap = map
        self.sourceNotes = notes
    }

    // MARK: - Lookup

    /// O(1) lookup for notes at a verse
    func notes(for verse: Int) -> [Note] {
        verseMap[verse] ?? []
    }

    /// Check if verse has any note indicator
    func hasNote(for verse: Int) -> Bool {
        verseMap[verse] != nil
    }

    /// Get count of notes at a verse
    func noteCount(for verse: Int) -> Int {
        verseMap[verse]?.count ?? 0
    }

    /// Get first (most recent) note at a verse
    func firstNote(for verse: Int) -> Note? {
        verseMap[verse]?.first
    }

    // MARK: - Template Lookup

    /// Get template of most recent note at a verse (for indicator display)
    func template(for verse: Int) -> NoteTemplate? {
        firstNote(for: verse)?.template
    }

    // MARK: - All Notes

    /// Get all notes covering a verse (includes notes where verse is within range)
    /// Use this for context menu or detailed views
    func allNotesForVerse(_ verse: Int) -> [Note] {
        sourceNotes.filter { $0.verseStart <= verse && verse <= $0.verseEnd }
    }
}

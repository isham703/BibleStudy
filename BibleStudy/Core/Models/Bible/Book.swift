import Foundation

// MARK: - Bible Book
// All 66 books of the Bible with metadata

enum Testament: String, Codable, CaseIterable {
    case old = "OT"
    case new = "NT"

    var displayName: String {
        switch self {
        case .old: return "Old Testament"
        case .new: return "New Testament"
        }
    }
}

enum BookCategory: String, Codable, CaseIterable {
    // Old Testament
    case pentateuch = "Law"
    case historical = "History"
    case wisdom = "Wisdom"
    case prophets = "Prophets"
    case theTwelve = "The Twelve"
    // New Testament
    case gospels = "Gospels"
    case acts = "Acts"
    case paulineEpistles = "Paul's Letters"
    case generalEpistles = "General Letters"
    case revelation = "Revelation"
}

struct Book: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let abbreviation: String
    let testament: Testament
    let category: BookCategory
    let chapters: Int

    var displayName: String { name }

    // Standard OSIS book IDs for reference
    var osisId: String {
        Book.osisIds[id] ?? abbreviation
    }
}

// MARK: - All 66 Books
extension Book {
    // Note: nonisolated(unsafe) is required to allow access from nonisolated functions.
    // The compiler warns this is "unnecessary" but removing it causes @MainActor inference.
    nonisolated(unsafe) static let all: [Book] = [
        // Old Testament - Pentateuch
        Book(id: 1, name: "Genesis", abbreviation: "Gen", testament: .old, category: .pentateuch, chapters: 50),
        Book(id: 2, name: "Exodus", abbreviation: "Exod", testament: .old, category: .pentateuch, chapters: 40),
        Book(id: 3, name: "Leviticus", abbreviation: "Lev", testament: .old, category: .pentateuch, chapters: 27),
        Book(id: 4, name: "Numbers", abbreviation: "Num", testament: .old, category: .pentateuch, chapters: 36),
        Book(id: 5, name: "Deuteronomy", abbreviation: "Deut", testament: .old, category: .pentateuch, chapters: 34),

        // Old Testament - Historical
        Book(id: 6, name: "Joshua", abbreviation: "Josh", testament: .old, category: .historical, chapters: 24),
        Book(id: 7, name: "Judges", abbreviation: "Judg", testament: .old, category: .historical, chapters: 21),
        Book(id: 8, name: "Ruth", abbreviation: "Ruth", testament: .old, category: .historical, chapters: 4),
        Book(id: 9, name: "1 Samuel", abbreviation: "1Sam", testament: .old, category: .historical, chapters: 31),
        Book(id: 10, name: "2 Samuel", abbreviation: "2Sam", testament: .old, category: .historical, chapters: 24),
        Book(id: 11, name: "1 Kings", abbreviation: "1Kgs", testament: .old, category: .historical, chapters: 22),
        Book(id: 12, name: "2 Kings", abbreviation: "2Kgs", testament: .old, category: .historical, chapters: 25),
        Book(id: 13, name: "1 Chronicles", abbreviation: "1Chr", testament: .old, category: .historical, chapters: 29),
        Book(id: 14, name: "2 Chronicles", abbreviation: "2Chr", testament: .old, category: .historical, chapters: 36),
        Book(id: 15, name: "Ezra", abbreviation: "Ezra", testament: .old, category: .historical, chapters: 10),
        Book(id: 16, name: "Nehemiah", abbreviation: "Neh", testament: .old, category: .historical, chapters: 13),
        Book(id: 17, name: "Esther", abbreviation: "Esth", testament: .old, category: .historical, chapters: 10),

        // Old Testament - Wisdom/Poetry
        Book(id: 18, name: "Job", abbreviation: "Job", testament: .old, category: .wisdom, chapters: 42),
        Book(id: 19, name: "Psalms", abbreviation: "Ps", testament: .old, category: .wisdom, chapters: 150),
        Book(id: 20, name: "Proverbs", abbreviation: "Prov", testament: .old, category: .wisdom, chapters: 31),
        Book(id: 21, name: "Ecclesiastes", abbreviation: "Eccl", testament: .old, category: .wisdom, chapters: 12),
        Book(id: 22, name: "Song of Solomon", abbreviation: "Song", testament: .old, category: .wisdom, chapters: 8),

        // Old Testament - Prophets
        Book(id: 23, name: "Isaiah", abbreviation: "Isa", testament: .old, category: .prophets, chapters: 66),
        Book(id: 24, name: "Jeremiah", abbreviation: "Jer", testament: .old, category: .prophets, chapters: 52),
        Book(id: 25, name: "Lamentations", abbreviation: "Lam", testament: .old, category: .prophets, chapters: 5),
        Book(id: 26, name: "Ezekiel", abbreviation: "Ezek", testament: .old, category: .prophets, chapters: 48),
        Book(id: 27, name: "Daniel", abbreviation: "Dan", testament: .old, category: .prophets, chapters: 12),

        // Old Testament - The Twelve (traditionally one scroll)
        Book(id: 28, name: "Hosea", abbreviation: "Hos", testament: .old, category: .theTwelve, chapters: 14),
        Book(id: 29, name: "Joel", abbreviation: "Joel", testament: .old, category: .theTwelve, chapters: 3),
        Book(id: 30, name: "Amos", abbreviation: "Amos", testament: .old, category: .theTwelve, chapters: 9),
        Book(id: 31, name: "Obadiah", abbreviation: "Obad", testament: .old, category: .theTwelve, chapters: 1),
        Book(id: 32, name: "Jonah", abbreviation: "Jonah", testament: .old, category: .theTwelve, chapters: 4),
        Book(id: 33, name: "Micah", abbreviation: "Mic", testament: .old, category: .theTwelve, chapters: 7),
        Book(id: 34, name: "Nahum", abbreviation: "Nah", testament: .old, category: .theTwelve, chapters: 3),
        Book(id: 35, name: "Habakkuk", abbreviation: "Hab", testament: .old, category: .theTwelve, chapters: 3),
        Book(id: 36, name: "Zephaniah", abbreviation: "Zeph", testament: .old, category: .theTwelve, chapters: 3),
        Book(id: 37, name: "Haggai", abbreviation: "Hag", testament: .old, category: .theTwelve, chapters: 2),
        Book(id: 38, name: "Zechariah", abbreviation: "Zech", testament: .old, category: .theTwelve, chapters: 14),
        Book(id: 39, name: "Malachi", abbreviation: "Mal", testament: .old, category: .theTwelve, chapters: 4),

        // New Testament - Gospels
        Book(id: 40, name: "Matthew", abbreviation: "Matt", testament: .new, category: .gospels, chapters: 28),
        Book(id: 41, name: "Mark", abbreviation: "Mark", testament: .new, category: .gospels, chapters: 16),
        Book(id: 42, name: "Luke", abbreviation: "Luke", testament: .new, category: .gospels, chapters: 24),
        Book(id: 43, name: "John", abbreviation: "John", testament: .new, category: .gospels, chapters: 21),

        // New Testament - Acts
        Book(id: 44, name: "Acts", abbreviation: "Acts", testament: .new, category: .acts, chapters: 28),

        // New Testament - Pauline Epistles
        Book(id: 45, name: "Romans", abbreviation: "Rom", testament: .new, category: .paulineEpistles, chapters: 16),
        Book(id: 46, name: "1 Corinthians", abbreviation: "1Cor", testament: .new, category: .paulineEpistles, chapters: 16),
        Book(id: 47, name: "2 Corinthians", abbreviation: "2Cor", testament: .new, category: .paulineEpistles, chapters: 13),
        Book(id: 48, name: "Galatians", abbreviation: "Gal", testament: .new, category: .paulineEpistles, chapters: 6),
        Book(id: 49, name: "Ephesians", abbreviation: "Eph", testament: .new, category: .paulineEpistles, chapters: 6),
        Book(id: 50, name: "Philippians", abbreviation: "Phil", testament: .new, category: .paulineEpistles, chapters: 4),
        Book(id: 51, name: "Colossians", abbreviation: "Col", testament: .new, category: .paulineEpistles, chapters: 4),
        Book(id: 52, name: "1 Thessalonians", abbreviation: "1Thess", testament: .new, category: .paulineEpistles, chapters: 5),
        Book(id: 53, name: "2 Thessalonians", abbreviation: "2Thess", testament: .new, category: .paulineEpistles, chapters: 3),
        Book(id: 54, name: "1 Timothy", abbreviation: "1Tim", testament: .new, category: .paulineEpistles, chapters: 6),
        Book(id: 55, name: "2 Timothy", abbreviation: "2Tim", testament: .new, category: .paulineEpistles, chapters: 4),
        Book(id: 56, name: "Titus", abbreviation: "Titus", testament: .new, category: .paulineEpistles, chapters: 3),
        Book(id: 57, name: "Philemon", abbreviation: "Phlm", testament: .new, category: .paulineEpistles, chapters: 1),

        // New Testament - General Epistles
        Book(id: 58, name: "Hebrews", abbreviation: "Heb", testament: .new, category: .generalEpistles, chapters: 13),
        Book(id: 59, name: "James", abbreviation: "Jas", testament: .new, category: .generalEpistles, chapters: 5),
        Book(id: 60, name: "1 Peter", abbreviation: "1Pet", testament: .new, category: .generalEpistles, chapters: 5),
        Book(id: 61, name: "2 Peter", abbreviation: "2Pet", testament: .new, category: .generalEpistles, chapters: 3),
        Book(id: 62, name: "1 John", abbreviation: "1John", testament: .new, category: .generalEpistles, chapters: 5),
        Book(id: 63, name: "2 John", abbreviation: "2John", testament: .new, category: .generalEpistles, chapters: 1),
        Book(id: 64, name: "3 John", abbreviation: "3John", testament: .new, category: .generalEpistles, chapters: 1),
        Book(id: 65, name: "Jude", abbreviation: "Jude", testament: .new, category: .generalEpistles, chapters: 1),

        // New Testament - Revelation
        Book(id: 66, name: "Revelation", abbreviation: "Rev", testament: .new, category: .revelation, chapters: 22)
    ]

    nonisolated(unsafe) static let byId: [Int: Book] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    nonisolated(unsafe) static let byAbbreviation: [String: Book] = Dictionary(uniqueKeysWithValues: all.map { ($0.abbreviation.lowercased(), $0) })

    nonisolated static func find(byId id: Int) -> Book? {
        byId[id]
    }

    nonisolated static func find(byAbbreviation abbr: String) -> Book? {
        byAbbreviation[abbr.lowercased()]
    }

    nonisolated static func find(byName name: String) -> Book? {
        all.first { $0.name.lowercased() == name.lowercased() }
    }

    // OSIS book IDs for standard reference
    static let osisIds: [Int: String] = [
        1: "Gen", 2: "Exod", 3: "Lev", 4: "Num", 5: "Deut",
        6: "Josh", 7: "Judg", 8: "Ruth", 9: "1Sam", 10: "2Sam",
        11: "1Kgs", 12: "2Kgs", 13: "1Chr", 14: "2Chr", 15: "Ezra",
        16: "Neh", 17: "Esth", 18: "Job", 19: "Ps", 20: "Prov",
        21: "Eccl", 22: "Song", 23: "Isa", 24: "Jer", 25: "Lam",
        26: "Ezek", 27: "Dan", 28: "Hos", 29: "Joel", 30: "Amos",
        31: "Obad", 32: "Jonah", 33: "Mic", 34: "Nah", 35: "Hab",
        36: "Zeph", 37: "Hag", 38: "Zech", 39: "Mal", 40: "Matt",
        41: "Mark", 42: "Luke", 43: "John", 44: "Acts", 45: "Rom",
        46: "1Cor", 47: "2Cor", 48: "Gal", 49: "Eph", 50: "Phil",
        51: "Col", 52: "1Thess", 53: "2Thess", 54: "1Tim", 55: "2Tim",
        56: "Titus", 57: "Phlm", 58: "Heb", 59: "Jas", 60: "1Pet",
        61: "2Pet", 62: "1John", 63: "2John", 64: "3John", 65: "Jude",
        66: "Rev"
    ]
}

// MARK: - Book Groups
extension Book {
    static var oldTestament: [Book] {
        all.filter { $0.testament == .old }
    }

    static var newTestament: [Book] {
        all.filter { $0.testament == .new }
    }

    static func books(inCategory category: BookCategory) -> [Book] {
        all.filter { $0.category == category }
    }

    // Commonly accessed books for quick navigation
    static var genesis: Book { byId[1]! }
    static var psalms: Book { byId[19]! }
    static var proverbs: Book { byId[20]! }
    static var isaiah: Book { byId[23]! }
    static var matthew: Book { byId[40]! }
    static var john: Book { byId[43]! }
    static var romans: Book { byId[45]! }
    static var revelation: Book { byId[66]! }
}

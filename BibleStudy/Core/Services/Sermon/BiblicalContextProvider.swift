//
//  BiblicalContextProvider.swift
//  BibleStudy
//
//  Provides dynamic biblical terminology based on sermon context.
//  Maps Bible books to related proper nouns and terms for improved STT accuracy.
//  Used to customize Whisper prompts and Apple SpeechAnalyzer biasing.
//

import Foundation

// MARK: - Biblical Context Provider

enum BiblicalContextProvider {
    // MARK: - Book-Specific Terms

    /// Maps Bible books to their key proper nouns, places, and theological terms.
    /// Terms are ordered by importance for limited budget allocation.
    static let bookSpecificTerms: [String: [String]] = [
        // Old Testament - Major Prophets
        "Isaiah": [
            "Immanuel", "Hezekiah", "Sennacherib", "Cyrus", "Seraphim",
            "Assyria", "Babylon", "Zion", "Messiah", "Servant"
        ],
        "Jeremiah": [
            "Nebuchadnezzar", "Babylon", "Zedekiah", "Josiah", "Baruch",
            "Jehoiakim", "Gedaliah", "Lamentations", "Chaldeans", "exile"
        ],
        "Ezekiel": [
            "Ezekiel", "Chebar", "cherubim", "Gog", "Magog",
            "Tyre", "Babylon", "Shekinah", "temple", "glory"
        ],
        "Daniel": [
            "Nebuchadnezzar", "Belshazzar", "Darius", "Shadrach", "Meshach",
            "Abednego", "Babylon", "Medes", "Persians", "Ancient of Days"
        ],

        // Old Testament - Minor Prophets
        "Hosea": [
            "Gomer", "Jezreel", "Lo-Ruhamah", "Lo-Ammi", "Ephraim",
            "Assyria", "idolatry", "covenant", "unfaithfulness", "redemption"
        ],
        "Joel": [
            "locusts", "Zion", "Pentecost", "Spirit", "valley of Jehoshaphat",
            "day of the Lord", "restoration", "judgment"
        ],
        "Amos": [
            "Tekoa", "Bethel", "Amaziah", "Jeroboam", "Damascus",
            "Gaza", "Edom", "justice", "righteousness"
        ],
        "Obadiah": [
            "Edom", "Esau", "Jacob", "Zion", "judgment",
            "Mount Seir", "pride", "destruction"
        ],
        "Jonah": [
            "Nineveh", "Tarshish", "Joppa", "whale", "fish",
            "repentance", "compassion", "Assyria"
        ],
        "Micah": [
            "Bethlehem", "Zion", "Samaria", "Moresheth", "Hezekiah",
            "justice", "mercy", "Messiah"
        ],
        "Nahum": [
            "Nineveh", "Assyria", "Elkosh", "Thebes", "judgment",
            "destruction", "vengeance", "comfort"
        ],
        "Habakkuk": [
            "Chaldeans", "Babylonians", "Shigionoth", "watchtower", "righteous",
            "faith", "woe", "judgment", "vision", "appointed time"
        ],
        "Zephaniah": [
            "Josiah", "Cush", "Nineveh", "Philistia", "Moab",
            "Ammon", "Ethiopia", "day of the Lord", "remnant"
        ],
        "Haggai": [
            "Zerubbabel", "Joshua", "Darius", "temple", "second temple",
            "glory", "signet ring", "restoration"
        ],
        "Zechariah": [
            "Zerubbabel", "Joshua", "Messiah", "Zion", "Jerusalem",
            "visions", "angel", "Branch", "Shepherd", "olive trees"
        ],
        "Malachi": [
            "Elijah", "tithe", "covenant", "messenger", "sun of righteousness",
            "Jacob", "Esau", "Levi", "offering"
        ],

        // Old Testament - Historical/Wisdom
        "Genesis": [
            "Adam", "Eve", "Noah", "Abraham", "Isaac", "Jacob", "Joseph",
            "Melchizedek", "Pharaoh", "covenant", "creation"
        ],
        "Exodus": [
            "Moses", "Pharaoh", "Aaron", "Miriam", "Passover", "Sinai",
            "tabernacle", "plagues", "Red Sea", "commandments"
        ],
        "Leviticus": [
            "Aaron", "Levites", "atonement", "sacrifice", "offerings",
            "tabernacle", "holiness", "clean", "unclean"
        ],
        "Numbers": [
            "Moses", "Aaron", "Balaam", "Balak", "Caleb", "Joshua",
            "wilderness", "Korah", "census", "Moab"
        ],
        "Deuteronomy": [
            "Moses", "covenant", "Canaan", "commandments", "Shema",
            "blessings", "curses", "Jordan", "promised land"
        ],
        "Joshua": [
            "Joshua", "Jericho", "Rahab", "Canaan", "Ai",
            "Gibeonites", "Caleb", "inheritance", "Jordan"
        ],
        "Judges": [
            "Deborah", "Gideon", "Samson", "Delilah", "Jephthah",
            "Ehud", "Barak", "Sisera", "Philistines"
        ],
        "Ruth": [
            "Ruth", "Boaz", "Naomi", "Moab", "Bethlehem",
            "kinsman-redeemer", "Elimelech", "Obed"
        ],
        "1 Samuel": [
            "Samuel", "Saul", "David", "Jonathan", "Hannah",
            "Eli", "Goliath", "Philistines", "anointing"
        ],
        "2 Samuel": [
            "David", "Bathsheba", "Nathan", "Absalom", "Joab",
            "Uriah", "Mephibosheth", "covenant", "Jerusalem"
        ],
        "1 Kings": [
            "Solomon", "Elijah", "Ahab", "Jezebel", "temple",
            "Rehoboam", "Jeroboam", "Baal", "Hiram"
        ],
        "2 Kings": [
            "Elisha", "Hezekiah", "Josiah", "Naaman", "Sennacherib",
            "Babylon", "Assyria", "exile", "Nebuchadnezzar"
        ],
        "1 Chronicles": [
            "David", "temple", "Levites", "genealogy", "ark",
            "Solomon", "covenant", "worship"
        ],
        "2 Chronicles": [
            "Solomon", "temple", "Hezekiah", "Josiah", "Rehoboam",
            "Passover", "exile", "restoration"
        ],
        "Ezra": [
            "Ezra", "Zerubbabel", "Cyrus", "temple", "Artaxerxes",
            "Persia", "restoration", "law", "intermarriage"
        ],
        "Nehemiah": [
            "Nehemiah", "Artaxerxes", "Sanballat", "Tobiah", "Jerusalem",
            "walls", "Ezra", "restoration", "covenant"
        ],
        "Esther": [
            "Esther", "Mordecai", "Haman", "Xerxes", "Ahasuerus",
            "Purim", "Susa", "Vashti", "deliverance"
        ],
        "Job": [
            "Job", "Eliphaz", "Bildad", "Zophar", "Elihu",
            "Satan", "Leviathan", "Behemoth", "suffering"
        ],
        "Psalms": [
            "David", "Selah", "Hallelujah", "Zion", "Messiah",
            "shepherd", "praise", "worship", "lament"
        ],
        "Proverbs": [
            "Solomon", "wisdom", "folly", "righteousness", "prudence",
            "Agur", "Lemuel", "fear of the Lord"
        ],
        "Ecclesiastes": [
            "Qoheleth", "Preacher", "vanity", "wisdom", "Solomon",
            "meaning", "futility", "seasons", "eternity"
        ],
        "Song of Solomon": [
            "Shulamite", "Solomon", "beloved", "bridegroom", "Lebanon",
            "vineyard", "love", "beauty"
        ],
        "Lamentations": [
            "Jerusalem", "Zion", "destruction", "exile", "Babylon",
            "mourning", "suffering", "faithfulness"
        ],

        // New Testament - Gospels
        "Matthew": [
            "Jesus", "disciples", "Pharisees", "Sadducees", "Herod",
            "Bethlehem", "Nazareth", "Galilee", "kingdom", "beatitudes"
        ],
        "Mark": [
            "Jesus", "disciples", "Galilee", "Capernaum", "Peter",
            "James", "John", "miracles", "Messiah"
        ],
        "Luke": [
            "Jesus", "Mary", "Elizabeth", "Zechariah", "Simeon",
            "Anna", "parables", "Jerusalem", "Samaritans"
        ],
        "John": [
            "Jesus", "Lazarus", "Martha", "Mary", "Nicodemus",
            "Pilate", "Thomas", "logos", "Comforter", "Advocate"
        ],

        // New Testament - Acts & Epistles
        "Acts": [
            "apostles", "Peter", "Paul", "Stephen", "Philip",
            "Barnabas", "Silas", "Timothy", "Pentecost", "Jerusalem"
        ],
        "Romans": [
            "justification", "sanctification", "propitiation", "righteousness",
            "Abraham", "Adam", "law", "grace", "faith"
        ],
        "1 Corinthians": [
            "Corinth", "Apollos", "Cephas", "Chloe", "tongues",
            "prophecy", "resurrection", "love", "communion"
        ],
        "2 Corinthians": [
            "Corinth", "Titus", "Macedonia", "ministry", "reconciliation",
            "apostleship", "suffering", "grace", "weakness"
        ],
        "Galatians": [
            "Galatia", "Abraham", "Hagar", "Sarah", "circumcision",
            "law", "grace", "freedom", "fruit of the Spirit"
        ],
        "Ephesians": [
            "Ephesus", "mystery", "church", "armor", "principalities",
            "predestination", "grace", "unity", "household"
        ],
        "Philippians": [
            "Philippi", "Epaphroditus", "Euodia", "Syntyche", "joy",
            "humility", "kenosis", "citizenship", "contentment"
        ],
        "Colossians": [
            "Colossae", "Epaphras", "Onesimus", "Christ", "mystery",
            "fullness", "philosophy", "principalities"
        ],
        "1 Thessalonians": [
            "Thessalonica", "Silas", "Timothy", "rapture", "parousia",
            "sanctification", "comfort", "day of the Lord"
        ],
        "2 Thessalonians": [
            "Thessalonica", "Antichrist", "man of lawlessness", "apostasy",
            "day of the Lord", "restrainer", "perseverance"
        ],
        "1 Timothy": [
            "Timothy", "Ephesus", "elders", "deacons", "doctrine",
            "Hymenaeus", "Alexander", "godliness"
        ],
        "2 Timothy": [
            "Timothy", "Lois", "Eunice", "scripture", "ministry",
            "persecution", "crown", "Demas"
        ],
        "Titus": [
            "Titus", "Crete", "elders", "doctrine", "grace",
            "good works", "Zenas", "Apollos"
        ],
        "Philemon": [
            "Philemon", "Onesimus", "Apphia", "Archippus", "slavery",
            "forgiveness", "reconciliation", "brotherhood"
        ],
        "Hebrews": [
            "Melchizedek", "Abraham", "Moses", "Aaron", "covenant",
            "priesthood", "tabernacle", "faith", "rest"
        ],
        "James": [
            "James", "faith", "works", "tongue", "wisdom",
            "trials", "patience", "prayer", "Elijah"
        ],
        "1 Peter": [
            "Peter", "Babylon", "Silvanus", "suffering", "election",
            "priesthood", "submission", "glory"
        ],
        "2 Peter": [
            "Peter", "transfiguration", "false teachers", "Noah", "Lot",
            "day of the Lord", "destruction", "knowledge"
        ],
        "1 John": [
            "Antichrist", "love", "fellowship", "light", "darkness",
            "truth", "sin", "advocate", "eternal life"
        ],
        "2 John": [
            "elder", "elect lady", "truth", "love", "Antichrist",
            "doctrine", "deceivers"
        ],
        "3 John": [
            "Gaius", "Diotrephes", "Demetrius", "truth", "hospitality",
            "elder", "testimony"
        ],
        "Jude": [
            "Jude", "Michael", "Enoch", "Sodom", "Gomorrah",
            "false teachers", "apostasy", "contend"
        ],
        "Revelation": [
            "apocalypse", "Patmos", "churches", "Lamb", "seals",
            "trumpets", "bowls", "dragon", "Babylon", "New Jerusalem"
        ]
    ]

    // MARK: - Base Terms

    /// Core biblical terms always included (low budget cost, high value).
    static let coreTerms: [String] = [
        "Hallelujah", "Selah", "Amen", "Hosanna"
    ]

    /// Commonly misrecognized book names (always prioritized).
    static let hardToRecognizeBooks: [String] = [
        "Habakkuk", "Zephaniah", "Ecclesiastes", "Thessalonians",
        "Philippians", "Colossians", "Ephesians", "Galatians"
    ]

    // MARK: - Dynamic Context Generation

    /// Get contextual strings for Apple SpeechAnalyzer based on detected books.
    /// - Parameters:
    ///   - books: Detected Bible books from sermon title
    ///   - maxTerms: Maximum number of terms to return (budget)
    /// - Returns: Array of contextual strings prioritized for the books
    static func contextualStrings(
        for books: [String],
        maxTerms: Int = 40
    ) -> [String] {
        var terms = Set<String>()

        // 1. Always include hard-to-recognize book names
        terms.formUnion(hardToRecognizeBooks)

        // 2. Add book-specific terms for detected books
        for book in books {
            if let bookTerms = bookSpecificTerms[book] {
                // Add up to 8 terms per detected book
                terms.formUnion(bookTerms.prefix(8))
            }
        }

        // 3. Add core terms
        terms.formUnion(coreTerms)

        // 4. Fill remaining budget with general terms
        let baseTerms = SermonConfiguration.biblicalContextualStrings
        for term in baseTerms where terms.count < maxTerms {
            terms.insert(term)
        }

        // Return as array, sorted for consistency
        return Array(terms).sorted().prefix(maxTerms).map { $0 }
    }

    /// Build a Whisper glossary prompt based on detected books.
    /// - Parameters:
    ///   - books: Detected Bible books from sermon title
    ///   - budgetChars: Maximum characters for the glossary
    /// - Returns: Prose-style glossary prompt optimized for detected books
    static func glossaryPrompt(
        for books: [String],
        budgetChars: Int = SermonConfiguration.glossaryBudgetChars
    ) -> String {
        // If no books detected, use default glossary
        guard !books.isEmpty else {
            return SermonConfiguration.biblicalGlossaryPrompt
        }

        // Build custom glossary prioritizing detected books
        var parts: [String] = []
        var currentLength = 0

        /// Calculate space cost for separator (0 for first part, 1 for subsequent)
        func separatorCost() -> Int {
            parts.isEmpty ? 0 : 1
        }

        // 1. Add detected book names with context
        let bookIntro = "Today we study \(books.joined(separator: " and "))."
        if currentLength + bookIntro.count + separatorCost() <= budgetChars {
            currentLength += bookIntro.count + separatorCost()
            parts.append(bookIntro)
        }

        // 2. Add book-specific terms as prose
        for book in books {
            if let bookTerms = bookSpecificTerms[book] {
                let termsProse = bookTerms.prefix(6).joined(separator: ", ")
                let addition = "In \(book): \(termsProse)."
                if currentLength + addition.count + separatorCost() <= budgetChars {
                    currentLength += addition.count + separatorCost()
                    parts.append(addition)
                }
            }
        }

        // 3. Add hard-to-recognize books not already mentioned
        let unmentionedBooks = hardToRecognizeBooks.filter { !books.contains($0) }
        if !unmentionedBooks.isEmpty {
            let booksList = unmentionedBooks.prefix(4).joined(separator: ", ")
            let addition = "Also \(booksList)."
            if currentLength + addition.count + separatorCost() <= budgetChars {
                currentLength += addition.count + separatorCost()
                parts.append(addition)
            }
        }

        // 4. Fill remaining budget with core terms
        let coreAddition = "Hallelujah. Selah."
        if currentLength + coreAddition.count + separatorCost() <= budgetChars {
            parts.append(coreAddition)
        }

        // Combine parts
        let result = parts.joined(separator: " ")

        // Fallback to default if result is too short (< 50 chars)
        if result.count < 50 {
            return SermonConfiguration.biblicalGlossaryPrompt
        }

        return result
    }

    // MARK: - Convenience Methods

    /// Get contextual strings for a sermon title.
    /// - Parameter title: Sermon title to parse for book references
    /// - Returns: Contextual strings optimized for detected books
    static func contextualStrings(forSermonTitle title: String) -> [String] {
        let books = ScriptureReferenceParser.extractBooks(from: title)
        return contextualStrings(for: books)
    }

    /// Get glossary prompt for a sermon title.
    /// - Parameter title: Sermon title to parse for book references
    /// - Returns: Glossary prompt optimized for detected books
    static func glossaryPrompt(forSermonTitle title: String) -> String {
        let books = ScriptureReferenceParser.extractBooks(from: title)
        return glossaryPrompt(for: books)
    }
}

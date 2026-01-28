import Foundation

/// Canonicalizes scripture references in caption text to standard display form.
/// Transforms "Rom 5 8" → "Romans 5:8" for cleaner display.
/// Also normalizes spoken numbers in explicit scripture patterns:
///   "Matthew chapter twelve verse one" → "Matthew 12:1"
///
/// Supports cross-segment references via carry-forward:
///   Segment 1: "Matthew chapter twelve." → stores pending (Matthew, 12)
///   Segment 2: "And verse one." → completes to "Matthew 12:1."
///
/// Display-only transformation applied at render time for finalized segments.
enum CaptionScriptureFormatter {

    // MARK: - Pending Reference (Cross-Segment Carry)

    /// Holds a partial reference waiting for completion.
    /// Two states:
    /// - chapter == nil: waiting for chapter number (saw "Book chapter")
    /// - chapter != nil: waiting for verse number (saw "Book chapter X")
    struct PendingBookChapter: Equatable {
        let bookName: String      // Original casing from text
        let canonicalBook: String // Proper book name for display
        let chapter: Int?         // nil if awaiting chapter number

        /// Convenience for complete pending (has chapter)
        init(bookName: String, canonicalBook: String, chapter: Int) {
            self.bookName = bookName
            self.canonicalBook = canonicalBook
            self.chapter = chapter
        }

        /// For awaiting chapter number state
        init(bookName: String, canonicalBook: String) {
            self.bookName = bookName
            self.canonicalBook = canonicalBook
            self.chapter = nil
        }
    }

    /// Result of formatting with carry-forward state
    struct FormatResult {
        let text: String
        let pending: PendingBookChapter?
    }

    // MARK: - Precompiled Regexes

    /// Matches "Book chapter X" at end of text (captures book, chapter number/word)
    private static let bookChapterAtEndRegex: NSRegularExpression = {
        let books = #"genesis|gen|exodus|exod|leviticus|lev|numbers|num|deuteronomy|deut|joshua|josh|judges|judg|ruth|samuel|sam|kings|kgs|chronicles|chr|ezra|nehemiah|neh|esther|esth|psalms?|proverbs|prov|ecclesiastes|eccl|isaiah|isa|jeremiah|jer|lamentations|lam|ezekiel|ezek|daniel|dan|hosea|hos|joel|amos|obadiah|obad|jonah|micah|mic|nahum|nah|habakkuk|hab|zephaniah|zeph|haggai|hag|zechariah|zech|malachi|mal|matthew|matt|luke|john|jn|acts|romans|rom|corinthians|cor|galatians|gal|ephesians|eph|philippians|phil|colossians|col|thessalonians|thess|timothy|tim|titus|tit|philemon|phlm|hebrews|heb|james|jas|peter|pet|jude|revelation|rev"#
        let numPhrase = #"(?:\d+|[a-z]+(?:[-\s][a-z]+){0,3})"#
        // Match: Book chapter <num> [punctuation] at end
        let pattern = #"(?i)\b(\#(books))\s+chapter\s+(\#(numPhrase))\s*[.,;:!?]?\s*$"#
        return try! NSRegularExpression(pattern: pattern)
    }()

    /// Matches "(And) verse X" at start of text
    private static let verseAtStartRegex: NSRegularExpression = {
        let numPhrase = #"(?:\d+|[a-z]+(?:[-\s][a-z]+){0,3})"#
        // Match: optional "and/And" + verse + number at start
        let pattern = #"(?i)^(?:and\s+)?verse\s+(\#(numPhrase))\b"#
        return try! NSRegularExpression(pattern: pattern)
    }()

    /// Matches: <Book> chapter <number-phrase> verse <number-phrase>
    private static let chapterVerseAfterBookRegex: NSRegularExpression = {
        let books = #"genesis|gen|exodus|exod|leviticus|lev|numbers|num|deuteronomy|deut|joshua|josh|judges|judg|ruth|samuel|sam|kings|kgs|chronicles|chr|ezra|nehemiah|neh|esther|esth|psalms?|proverbs|prov|ecclesiastes|eccl|isaiah|isa|jeremiah|jer|lamentations|lam|ezekiel|ezek|daniel|dan|hosea|hos|joel|amos|obadiah|obad|jonah|micah|mic|nahum|nah|habakkuk|hab|zephaniah|zeph|haggai|hag|zechariah|zech|malachi|mal|matthew|matt|luke|john|jn|acts|romans|rom|corinthians|cor|galatians|gal|ephesians|eph|philippians|phil|colossians|col|thessalonians|thess|timothy|tim|titus|tit|philemon|phlm|hebrews|heb|james|jas|peter|pet|jude|revelation|rev"#
        let numPhrase = #"(?:\d+|[a-z]+(?:[-\s][a-z]+){0,3})"#
        let pattern = #"(?i)\b(\#(books))\s+chapter\s+(\#(numPhrase))\s+verse\s+(\#(numPhrase))\b"#
        return try! NSRegularExpression(pattern: pattern)
    }()

    /// Matches "Book chapter" WITHOUT a number at end of text (for 3-segment splits)
    private static let bookChapterNoNumberAtEndRegex: NSRegularExpression = {
        let books = #"genesis|gen|exodus|exod|leviticus|lev|numbers|num|deuteronomy|deut|joshua|josh|judges|judg|ruth|samuel|sam|kings|kgs|chronicles|chr|ezra|nehemiah|neh|esther|esth|psalms?|proverbs|prov|ecclesiastes|eccl|isaiah|isa|jeremiah|jer|lamentations|lam|ezekiel|ezek|daniel|dan|hosea|hos|joel|amos|obadiah|obad|jonah|micah|mic|nahum|nah|habakkuk|hab|zephaniah|zeph|haggai|hag|zechariah|zech|malachi|mal|matthew|matt|luke|john|jn|acts|romans|rom|corinthians|cor|galatians|gal|ephesians|eph|philippians|phil|colossians|col|thessalonians|thess|timothy|tim|titus|tit|philemon|phlm|hebrews|heb|james|jas|peter|pet|jude|revelation|rev"#
        // Match: Book chapter at end (NOT followed by a number)
        let pattern = #"(?i)\b(\#(books))\s+chapter\s*$"#
        return try! NSRegularExpression(pattern: pattern)
    }()

    /// Matches a number (spoken or digit) at the start, optionally followed by "verse X"
    /// Used to complete pending "awaiting chapter number" state
    private static let numberAtStartRegex: NSRegularExpression = {
        let numPhrase = #"(?:\d+|[a-z]+(?:[-\s][a-z]+){0,3})"#
        // Capture: (chapter number) optionally followed by "verse" (verse number)
        let pattern = #"(?i)^(\#(numPhrase))(?:\s*[.,]?\s*$|\s+verse\s+(\#(numPhrase))|\s)"#
        return try! NSRegularExpression(pattern: pattern)
    }()

    // MARK: - Main Format Function (Simple)

    /// Canonicalize parseable scripture references to standard display text.
    /// Use this for single-segment formatting without cross-segment carry.
    /// - Parameter text: The raw caption text
    /// - Returns: Text with verse references in canonical form
    static func format(_ text: String) -> String {
        formatWithCarry(text, pending: nil).text
    }

    // MARK: - Format With Carry (Cross-Segment)

    /// Format text with cross-segment carry-forward support.
    /// Handles both 2-segment and 3-segment splits:
    ///   - 2-segment: "Book chapter X" → "verse Y"
    ///   - 3-segment: "Book chapter" → "X" → "verse Y"
    /// - Parameters:
    ///   - text: The raw caption text
    ///   - pending: Optional pending reference from previous segment
    /// - Returns: Formatted text and any new pending reference
    static func formatWithCarry(_ text: String, pending: PendingBookChapter?) -> FormatResult {
        var workingText = text
        var updatedPending: PendingBookChapter? = pending

        // Step 1: Handle pending state from previous segment
        if let pending = pending {
            let result = tryCompletePendingReference(workingText, pending: pending)
            workingText = result.text
            updatedPending = result.updatedPending
        }

        // Step 2: Normalize same-segment "Book chapter X verse Y" patterns
        workingText = normalizeSpokenChapterVerse(workingText)

        // Step 3: Canonicalize any numeric references (e.g., "Rom 5 8" → "Romans 5:8")
        workingText = canonicalizeReferences(workingText)

        // Step 4: Check if this segment creates a new pending state
        // (only if we didn't already establish one from step 1)
        if updatedPending == nil {
            updatedPending = extractPendingFromEnd(workingText)
        }

        return FormatResult(text: workingText, pending: updatedPending)
    }

    // MARK: - Cross-Segment Completion

    /// Result of attempting to complete a pending reference
    private struct PendingCompletionResult {
        let text: String
        let updatedPending: PendingBookChapter?
    }

    /// Try to complete/advance a pending reference based on the current text.
    /// Handles two pending states:
    ///   - chapter == nil: awaiting chapter number → look for number at start
    ///   - chapter != nil: awaiting verse → look for "verse X" at start
    private static func tryCompletePendingReference(
        _ text: String,
        pending: PendingBookChapter
    ) -> PendingCompletionResult {

        // Case 1: Awaiting chapter number (saw "Book chapter" without number)
        if pending.chapter == nil {
            return tryCompleteAwaitingChapterNumber(text, pending: pending)
        }

        // Case 2: Awaiting verse (saw "Book chapter X")
        return tryCompleteAwaitingVerse(text, pending: pending)
    }

    /// Handle pending state where we're waiting for the chapter number
    /// Input segment might be: "twelve." or "fifteen verse five."
    private static func tryCompleteAwaitingChapterNumber(
        _ text: String,
        pending: PendingBookChapter
    ) -> PendingCompletionResult {
        let nsRange = NSRange(text.startIndex..., in: text)

        // Try to match a number at the start, optionally followed by "verse X"
        guard let match = numberAtStartRegex.firstMatch(in: text, range: nsRange),
              let chapterRange = Range(match.range(at: 1), in: text) else {
            // No number found at start - pending expires
            return PendingCompletionResult(text: text, updatedPending: nil)
        }

        let chapterPhrase = String(text[chapterRange])
        guard let chapter = parseSpokenInt(chapterPhrase) else {
            return PendingCompletionResult(text: text, updatedPending: nil)
        }

        // Check if verse is also present: "fifteen verse five."
        if match.range(at: 2).location != NSNotFound,
           let verseRange = Range(match.range(at: 2), in: text) {
            let versePhrase = String(text[verseRange])
            if let verse = parseSpokenInt(versePhrase) {
                // Complete reference! Replace the matched portion
                let canonicalRef = "\(pending.canonicalBook) \(chapter):\(verse)"
                guard let fullRange = Range(match.range, in: text) else {
                    return PendingCompletionResult(text: text, updatedPending: nil)
                }
                var result = text
                result.replaceSubrange(fullRange, with: canonicalRef)
                return PendingCompletionResult(text: result, updatedPending: nil)
            }
        }

        // Got chapter number, now waiting for verse
        let updatedPending = PendingBookChapter(
            bookName: pending.bookName,
            canonicalBook: pending.canonicalBook,
            chapter: chapter
        )
        return PendingCompletionResult(text: text, updatedPending: updatedPending)
    }

    /// Handle pending state where we have book+chapter and are waiting for verse
    private static func tryCompleteAwaitingVerse(
        _ text: String,
        pending: PendingBookChapter
    ) -> PendingCompletionResult {
        guard let chapter = pending.chapter else {
            return PendingCompletionResult(text: text, updatedPending: nil)
        }

        let nsRange = NSRange(text.startIndex..., in: text)

        guard let match = verseAtStartRegex.firstMatch(in: text, range: nsRange),
              let fullRange = Range(match.range, in: text),
              let verseRange = Range(match.range(at: 1), in: text) else {
            // No "verse X" found - pending expires
            return PendingCompletionResult(text: text, updatedPending: nil)
        }

        let versePhrase = String(text[verseRange])
        guard let verse = parseSpokenInt(versePhrase) else {
            return PendingCompletionResult(text: text, updatedPending: nil)
        }

        // Complete reference!
        let canonicalRef = "\(pending.canonicalBook) \(chapter):\(verse)"
        var result = text
        result.replaceSubrange(fullRange, with: canonicalRef)

        return PendingCompletionResult(text: result, updatedPending: nil)
    }

    // MARK: - Pending Extraction

    /// Extract a pending reference from the end of this segment.
    /// Checks for both "Book chapter X" and "Book chapter" (no number)
    private static func extractPendingFromEnd(_ text: String) -> PendingBookChapter? {
        // First try: "Book chapter X" (with number)
        if let pending = extractPendingBookChapterWithNumber(from: text) {
            return pending
        }

        // Second try: "Book chapter" (without number - 3-segment case)
        return extractPendingBookChapterWithoutNumber(from: text)
    }

    /// Extract pending when segment ends with "Book chapter X"
    private static func extractPendingBookChapterWithNumber(from text: String) -> PendingBookChapter? {
        let nsRange = NSRange(text.startIndex..., in: text)

        guard let match = bookChapterAtEndRegex.firstMatch(in: text, range: nsRange),
              let bookRange = Range(match.range(at: 1), in: text),
              let chapterRange = Range(match.range(at: 2), in: text) else {
            return nil
        }

        let bookName = String(text[bookRange])
        let chapterPhrase = String(text[chapterRange])

        // Parse the chapter number
        guard let chapter = parseSpokenInt(chapterPhrase) else {
            return nil
        }

        // Look up canonical book name
        guard let canonicalBook = lookupCanonicalBookName(bookName) else {
            return nil
        }

        return PendingBookChapter(
            bookName: bookName,
            canonicalBook: canonicalBook,
            chapter: chapter
        )
    }

    /// Extract pending when segment ends with "Book chapter" (no number yet)
    /// This handles 3-segment splits: "Book chapter" → "X" → "verse Y"
    private static func extractPendingBookChapterWithoutNumber(from text: String) -> PendingBookChapter? {
        let nsRange = NSRange(text.startIndex..., in: text)

        guard let match = bookChapterNoNumberAtEndRegex.firstMatch(in: text, range: nsRange),
              let bookRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        let bookName = String(text[bookRange])

        // Look up canonical book name
        guard let canonicalBook = lookupCanonicalBookName(bookName) else {
            return nil
        }

        // Return pending with nil chapter (awaiting chapter number)
        return PendingBookChapter(
            bookName: bookName,
            canonicalBook: canonicalBook
        )
    }

    // MARK: - Same-Segment Spoken Number Normalization

    /// Fast guard: only attempt normalization when both keywords are present.
    private static func shouldAttemptSpokenNormalization(_ text: String) -> Bool {
        let lower = text.lowercased()
        return lower.contains("chapter") && lower.contains("verse")
    }

    /// Normalize spoken numbers only in explicit "Book chapter X verse Y" patterns.
    static func normalizeSpokenNumbers(_ text: String) -> String {
        normalizeSpokenChapterVerse(text)
    }

    /// Internal implementation of spoken number normalization.
    private static func normalizeSpokenChapterVerse(_ text: String) -> String {
        guard shouldAttemptSpokenNormalization(text) else { return text }

        var result = text
        let nsRange = NSRange(result.startIndex..., in: result)

        let matches = chapterVerseAfterBookRegex.matches(in: result, range: nsRange).reversed()

        for match in matches {
            guard let fullRange = Range(match.range, in: result),
                  let bookRange = Range(match.range(at: 1), in: result),
                  let chapterRange = Range(match.range(at: 2), in: result),
                  let verseRange = Range(match.range(at: 3), in: result) else { continue }

            let bookName = String(result[bookRange])
            let chapterPhrase = String(result[chapterRange])
            let versePhrase = String(result[verseRange])

            // BOTH must parse to integers (conservative)
            guard let chapter = parseSpokenInt(chapterPhrase),
                  let verse = parseSpokenInt(versePhrase) else { continue }

            // Replace with: Book chapter:verse
            result.replaceSubrange(fullRange, with: "\(bookName) \(chapter):\(verse)")
        }

        return result
    }

    // MARK: - Reference Canonicalization

    /// Canonicalize numeric references using the detector
    private static func canonicalizeReferences(_ text: String) -> String {
        let matches = CaptionReferenceDetector.findRanges(in: text)
        guard !matches.isEmpty else { return text }

        let sorted = matches.sorted { $0.range.lowerBound < $1.range.lowerBound }

        var result = ""
        result.reserveCapacity(text.count + sorted.count * 8)

        var cursor = text.startIndex

        for match in sorted {
            let range = match.range
            let reference = match.reference

            guard range.lowerBound >= cursor else { continue }
            guard reference.displayText.contains(":") else { continue }

            result.append(contentsOf: text[cursor..<range.lowerBound])
            result.append(reference.displayText)
            cursor = range.upperBound
        }

        result.append(contentsOf: text[cursor..<text.endIndex])
        return result
    }

    // MARK: - Book Name Lookup

    /// Look up the canonical book name from a book name or abbreviation
    private static func lookupCanonicalBookName(_ input: String) -> String? {
        // Try parsing a dummy reference to get the canonical book name
        let testRef = "\(input) 1:1"
        if case .success(let parsed) = ReferenceParser.parseFlexible(testRef) {
            return parsed.book.name
        }
        return nil
    }

    // MARK: - Spoken Number Parser

    /// Parse a spoken number phrase to an integer.
    private static func parseSpokenInt(_ raw: String) -> Int? {
        let cleaned = raw
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let n = Int(cleaned) { return n }

        let units: [String: Int] = [
            "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
            "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
            "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14,
            "fifteen": 15, "sixteen": 16, "seventeen": 17, "eighteen": 18,
            "nineteen": 19
        ]

        let tens: [String: Int] = [
            "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50,
            "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90
        ]

        let ordinals: [String: Int] = [
            "first": 1, "second": 2, "third": 3, "fourth": 4, "fifth": 5,
            "sixth": 6, "seventh": 7, "eighth": 8, "ninth": 9, "tenth": 10,
            "eleventh": 11, "twelfth": 12, "thirteenth": 13, "fourteenth": 14,
            "fifteenth": 15, "sixteenth": 16, "seventeenth": 17,
            "eighteenth": 18, "nineteenth": 19, "twentieth": 20
        ]

        let tokens = cleaned.split(separator: " ").map(String.init)
        guard !tokens.isEmpty else { return nil }

        var value = 0
        var current = 0

        for token in tokens {
            if token == "and" { continue }
            if let o = ordinals[token] {
                current += o
                continue
            }
            if let u = units[token] {
                current += u
                continue
            }
            if let t = tens[token] {
                current += t
                continue
            }
            if token == "hundred" {
                current = max(current, 1) * 100
                continue
            }
            return nil
        }

        value += current
        return value > 0 ? value : nil
    }
}

// MARK: - Segment Rendering Helper

extension CaptionScriptureFormatter {

    /// Render an array of segments with cross-segment carry-forward.
    /// Use this in the UI layer to format all segments with proper reference completion.
    static func renderSegments(_ segments: [LiveCaptionSegment]) -> [(id: UUID, displayText: String)] {
        var pending: PendingBookChapter?
        var rendered: [(id: UUID, displayText: String)] = []
        rendered.reserveCapacity(segments.count)

        for segment in segments {
            if !segment.isFinal {
                // Don't format volatile segments
                rendered.append((id: segment.id, displayText: segment.text))
                continue
            }

            let result = formatWithCarry(segment.text, pending: pending)
            pending = result.pending

            rendered.append((id: segment.id, displayText: result.text))
        }

        return rendered
    }
}

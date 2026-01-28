import Testing
@testable import BibleStudy

@Suite("Caption Scripture Formatter")
struct CaptionScriptureFormatterTests {

    @Test("No matches returns unchanged")
    func noMatches() {
        let text = "Hello world, this is a test."
        #expect(CaptionScriptureFormatter.format(text) == text)
    }

    @Test("Space-separated normalizes to colon")
    func spaceSeparatedNormalizes() {
        let text = "Turn to Genesis 1 1 today"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == "Turn to Genesis 1:1 today")
    }

    @Test("Abbreviation expands to full name")
    func abbreviationExpands() {
        let text = "Read Rom 5 8 carefully"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == "Read Romans 5:8 carefully")
    }

    @Test("Casing normalized")
    func casingNormalized() {
        let text = "See john 3 16 here"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == "See John 3:16 here")
    }

    @Test("Already canonical unchanged")
    func alreadyCanonical() {
        let text = "Turn to Genesis 1:1 today"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == "Turn to Genesis 1:1 today")
    }

    @Test("Multiple references normalize all")
    func multipleReferences() {
        let text = "From Rom 5 8 to john 3 16"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == "From Romans 5:8 to John 3:16")
    }

    @Test("Reference at start")
    func referenceAtStart() {
        let text = "Genesis 1 1 says"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == "Genesis 1:1 says")
    }

    @Test("Reference at end")
    func referenceAtEnd() {
        let text = "Turn to Genesis 1 1"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == "Turn to Genesis 1:1")
    }

    @Test("Empty string returns empty")
    func emptyString() {
        #expect(CaptionScriptureFormatter.format("") == "")
    }

    @Test("Chapter-only not formatted (conservative)")
    func chapterOnlyNotFormatted() {
        let text = "Read Genesis 1 for context"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == text)
    }

    @Test("False positive avoided")
    func falsePositiveAvoided() {
        let text = "mark 3 items on the list"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == text)
    }

    // MARK: - Punctuation Boundary Tests

    @Test("Trailing comma preserved")
    func trailingCommaPreserved() {
        let text = "Read Genesis 1 1, then continue."
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == "Read Genesis 1:1, then continue.")
    }

    @Test("Trailing period preserved")
    func trailingPeriodPreserved() {
        let text = "See John 3 16."
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == "See John 3:16.")
    }

    @Test("Parentheses preserved")
    func parenthesesPreserved() {
        let text = "See (John 3 16) for context."
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == "See (John 3:16) for context.")
    }

    @Test("Semicolon preserved")
    func semicolonPreserved() {
        let text = "Rom 5 8; John 3 16"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == "Romans 5:8; John 3:16")
    }

    // MARK: - Spoken Number Tests (Conservative)

    @Test("Book chapter verse spoken numbers")
    func bookChapterVerseSpokenNumbers() {
        let text = "In Matthew chapter twelve verse one we read"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == "In Matthew 12:1 we read")
    }

    @Test("Spoken numbers with full pattern")
    func spokenNumbersFullPattern() {
        let text = "Turn to Genesis chapter one verse one"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == "Turn to Genesis 1:1")
    }

    @Test("Spoken numbers mixed with digits")
    func spokenNumbersMixedWithDigits() {
        let text = "Read John chapter 3 verse sixteen"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == "Read John 3:16")
    }

    @Test("Multiple spoken number references")
    func multipleSpokenNumberReferences() {
        let text = "From Romans chapter five verse eight to John chapter three verse sixteen"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == "From Romans 5:8 to John 3:16")
    }

    @Test("Hyphenated spoken numbers")
    func hyphenatedSpokenNumbers() {
        let text = "Psalm chapter twenty-three verse one"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == "Psalm 23:1")
    }

    @Test("Multi-word chapter numbers")
    func multiWordChapterNumbers() {
        let text = "Read Psalm chapter one hundred nineteen verse one"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == "Read Psalm 119:1")
    }

    @Test("Case insensitive spoken numbers")
    func caseInsensitiveSpokenNumbers() {
        let text = "See JOHN CHAPTER THREE VERSE SIXTEEN"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == "See John 3:16")
    }

    // MARK: - False Positive Prevention Tests

    @Test("Bare chapter not normalized (no verse keyword)")
    func bareChapterNotNormalized() {
        let text = "chapter twelve of our plan"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == text)
    }

    @Test("Bare verse not normalized (no chapter keyword)")
    func bareVerseNotNormalized() {
        let text = "the verse one of this poem"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == text)
    }

    @Test("Book without chapter/verse keywords unchanged")
    func bookWithoutKeywordsUnchanged() {
        // Without "chapter" and "verse" keywords, spoken numbers are not normalized
        let text = "See Matthew twelve one"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == text)
    }

    @Test("mark three items unchanged")
    func markThreeItemsUnchanged() {
        let text = "mark three items on the list"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == text)
    }

    // MARK: - Edge Cases

    @Test("Partial pattern without book unchanged")
    func partialPatternWithoutBook() {
        // "chapter X verse Y" without a book name should not match
        let text = "In chapter twelve verse one we read"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == text)
    }

    @Test("Invalid spoken number in verse position")
    func invalidSpokenNumberInVerse() {
        // "foo" is not a valid number, so this shouldn't normalize
        let text = "Matthew chapter twelve verse foo"
        let result = CaptionScriptureFormatter.format(text)
        #expect(result == text)
    }

    // MARK: - Cross-Segment Carry Tests

    @Test("Cross-segment: Book chapter creates pending")
    func crossSegmentBookChapterCreatesPending() {
        let text = "Matthew chapter twelve."
        let result = CaptionScriptureFormatter.formatWithCarry(text, pending: nil)
        #expect(result.pending != nil)
        #expect(result.pending?.canonicalBook == "Matthew")
        #expect(result.pending?.chapter == 12)
    }

    @Test("Cross-segment: Verse completes pending")
    func crossSegmentVerseCompletesPending() {
        let pending = CaptionScriptureFormatter.PendingBookChapter(
            bookName: "Matthew",
            canonicalBook: "Matthew",
            chapter: 12
        )
        let text = "And verse one."
        let result = CaptionScriptureFormatter.formatWithCarry(text, pending: pending)
        #expect(result.text == "Matthew 12:1.")
    }

    @Test("Cross-segment: Verse without And completes pending")
    func crossSegmentVerseWithoutAndCompletesPending() {
        let pending = CaptionScriptureFormatter.PendingBookChapter(
            bookName: "John",
            canonicalBook: "John",
            chapter: 3
        )
        let text = "verse sixteen today"
        let result = CaptionScriptureFormatter.formatWithCarry(text, pending: pending)
        #expect(result.text == "John 3:16 today")
    }

    @Test("Cross-segment: Spoken chapter number")
    func crossSegmentSpokenChapterNumber() {
        let text = "pick up in Matthew chapter twelve."
        let result = CaptionScriptureFormatter.formatWithCarry(text, pending: nil)
        #expect(result.pending != nil)
        #expect(result.pending?.chapter == 12)
    }

    @Test("Cross-segment: No pending when full reference in segment")
    func crossSegmentNoPendingWhenFullReference() {
        let text = "Matthew chapter twelve verse one says"
        let result = CaptionScriptureFormatter.formatWithCarry(text, pending: nil)
        // Full reference found, no pending needed
        #expect(result.pending == nil)
        #expect(result.text.contains("Matthew 12:1"))
    }

    @Test("Cross-segment: Pending expires if not used")
    func crossSegmentPendingExpiresIfNotUsed() {
        let pending = CaptionScriptureFormatter.PendingBookChapter(
            bookName: "Matthew",
            canonicalBook: "Matthew",
            chapter: 12
        )
        // Text doesn't start with "verse", so pending is not consumed
        let text = "And he said to them"
        let result = CaptionScriptureFormatter.formatWithCarry(text, pending: pending)
        // Text unchanged, but new pending should be nil (expired)
        #expect(result.text == text)
        #expect(result.pending == nil)
    }

    // MARK: - Three-Segment Carry Tests

    @Test("3-segment: Book chapter without number creates awaiting pending")
    func threeSegmentBookChapterWithoutNumber() {
        let text = "Matthew chapter"
        let result = CaptionScriptureFormatter.formatWithCarry(text, pending: nil)
        #expect(result.pending != nil)
        #expect(result.pending?.canonicalBook == "Matthew")
        #expect(result.pending?.chapter == nil) // Awaiting chapter number
    }

    @Test("3-segment: Number advances pending to awaiting verse")
    func threeSegmentNumberAdvancesPending() {
        let pending = CaptionScriptureFormatter.PendingBookChapter(
            bookName: "Matthew",
            canonicalBook: "Matthew"
        )
        let text = "twelve."
        let result = CaptionScriptureFormatter.formatWithCarry(text, pending: pending)
        #expect(result.pending != nil)
        #expect(result.pending?.chapter == 12) // Now has chapter, awaiting verse
    }

    @Test("3-segment: Verse completes after number")
    func threeSegmentVerseCompletesAfterNumber() {
        let pending = CaptionScriptureFormatter.PendingBookChapter(
            bookName: "Matthew",
            canonicalBook: "Matthew",
            chapter: 12
        )
        let text = "Verse one,"
        let result = CaptionScriptureFormatter.formatWithCarry(text, pending: pending)
        #expect(result.text == "Matthew 12:1,")
        #expect(result.pending == nil)
    }

    @Test("3-segment: Number with verse in same segment completes")
    func threeSegmentNumberWithVerseCompletes() {
        let pending = CaptionScriptureFormatter.PendingBookChapter(
            bookName: "Matthew",
            canonicalBook: "Matthew"
        )
        let text = "fifteen verse five."
        let result = CaptionScriptureFormatter.formatWithCarry(text, pending: pending)
        #expect(result.text.contains("Matthew 15:5"))
        #expect(result.pending == nil)
    }

    @Test("3-segment: Full flow simulation")
    func threeSegmentFullFlow() {
        // Simulate: "Matthew chapter" → "twelve." → "Verse one,"
        let seg1 = CaptionScriptureFormatter.formatWithCarry("Matthew chapter", pending: nil)
        #expect(seg1.pending?.chapter == nil)

        let seg2 = CaptionScriptureFormatter.formatWithCarry("twelve.", pending: seg1.pending)
        #expect(seg2.pending?.chapter == 12)

        let seg3 = CaptionScriptureFormatter.formatWithCarry("Verse one,", pending: seg2.pending)
        #expect(seg3.text == "Matthew 12:1,")
        #expect(seg3.pending == nil)
    }
}

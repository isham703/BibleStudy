import Testing
import Foundation
@testable import BibleStudy

// MARK: - Reference Parser Tests
// Tests for Bible reference parsing and extraction

@Suite("ReferenceParser")
struct ReferenceParserTests {

    // MARK: - Single Verse Tests

    @Test("Parse single verse - John 3:16")
    func testParseSingleVerse() throws {
        let result = ReferenceParser.parse("John 3:16")

        guard case .success(let parsed) = result else {
            Issue.record("Expected success, got \(result)")
            return
        }

        #expect(parsed.book.name == "John")
        #expect(parsed.chapter == 3)
        #expect(parsed.verseStart == 16)
        #expect(parsed.verseEnd == nil)
        #expect(parsed.displayText == "John 3:16")
    }

    @Test("Parse single verse - Genesis 1:1")
    func testParseSingleVerse_Genesis() throws {
        let result = ReferenceParser.parse("Genesis 1:1")

        guard case .success(let parsed) = result else {
            Issue.record("Expected success")
            return
        }

        #expect(parsed.book.name == "Genesis")
        #expect(parsed.chapter == 1)
        #expect(parsed.verseStart == 1)
    }

    // MARK: - Verse Range Tests

    @Test("Parse verse range - Romans 8:28-30")
    func testParseVerseRange() throws {
        let result = ReferenceParser.parse("Romans 8:28-30")

        guard case .success(let parsed) = result else {
            Issue.record("Expected success")
            return
        }

        #expect(parsed.book.name == "Romans")
        #expect(parsed.chapter == 8)
        #expect(parsed.verseStart == 28)
        #expect(parsed.verseEnd == 30)
        #expect(parsed.displayText == "Romans 8:28-30")
    }

    @Test("Parse verse range with en-dash - Matthew 5:3–12")
    func testParseVerseRange_EnDash() throws {
        let result = ReferenceParser.parse("Matthew 5:3–12")

        guard case .success(let parsed) = result else {
            Issue.record("Expected success")
            return
        }

        #expect(parsed.verseStart == 3)
        #expect(parsed.verseEnd == 12)
    }

    // MARK: - Chapter Only Tests

    @Test("Parse chapter only - Genesis 1")
    func testParseChapterOnly() throws {
        let result = ReferenceParser.parse("Genesis 1")

        guard case .success(let parsed) = result else {
            Issue.record("Expected success")
            return
        }

        #expect(parsed.book.name == "Genesis")
        #expect(parsed.chapter == 1)
        #expect(parsed.verseStart == nil)
        #expect(parsed.verseEnd == nil)
        #expect(parsed.displayText == "Genesis 1")
    }

    // MARK: - Numbered Book Tests

    @Test("Parse numbered book - 1 Corinthians 13:4-8")
    func testParseNumberedBook() throws {
        let result = ReferenceParser.parse("1 Corinthians 13:4-8")

        guard case .success(let parsed) = result else {
            Issue.record("Expected success")
            return
        }

        #expect(parsed.book.name == "1 Corinthians")
        #expect(parsed.chapter == 13)
        #expect(parsed.verseStart == 4)
        #expect(parsed.verseEnd == 8)
    }

    @Test("Parse numbered book compact - 1Cor 13:4")
    func testParseNumberedBook_Compact() throws {
        let result = ReferenceParser.parse("1Cor 13:4")

        guard case .success(let parsed) = result else {
            Issue.record("Expected success")
            return
        }

        #expect(parsed.book.name == "1 Corinthians")
        #expect(parsed.chapter == 13)
    }

    @Test("Parse 2 Peter")
    func testParse2Peter() throws {
        let result = ReferenceParser.parse("2 Peter 1:3")

        guard case .success(let parsed) = result else {
            Issue.record("Expected success")
            return
        }

        #expect(parsed.book.name == "2 Peter")
        #expect(parsed.chapter == 1)
        #expect(parsed.verseStart == 3)
    }

    // MARK: - Abbreviation Tests

    @Test("Parse abbreviation - Gen 1:1")
    func testParseAbbreviation() throws {
        let result = ReferenceParser.parse("Gen 1:1")

        guard case .success(let parsed) = result else {
            Issue.record("Expected success")
            return
        }

        #expect(parsed.book.name == "Genesis")
    }

    @Test("Parse abbreviation - Rom 8:28")
    func testParseAbbreviation_Romans() throws {
        let result = ReferenceParser.parse("Rom 8:28")

        guard case .success(let parsed) = result else {
            Issue.record("Expected success")
            return
        }

        #expect(parsed.book.name == "Romans")
    }

    @Test("Parse abbreviation - Ps 23:1")
    func testParseAbbreviation_Psalms() throws {
        let result = ReferenceParser.parse("Ps 23:1")

        guard case .success(let parsed) = result else {
            Issue.record("Expected success")
            return
        }

        #expect(parsed.book.name == "Psalms")
    }

    // MARK: - Error Tests

    @Test("Empty input returns error")
    func testEmptyInput() {
        let result = ReferenceParser.parse("")

        guard case .failure(let error) = result else {
            Issue.record("Expected failure")
            return
        }

        #expect(error == .emptyInput)
    }

    @Test("Invalid book returns error")
    func testInvalidBook() {
        let result = ReferenceParser.parse("Hezekiah 1:1")

        guard case .failure(let error) = result else {
            Issue.record("Expected failure")
            return
        }

        if case .bookNotFound(let name) = error {
            #expect(name == "Hezekiah")
        } else {
            Issue.record("Expected bookNotFound error")
        }
    }

    @Test("Invalid chapter returns error")
    func testInvalidChapter() {
        // Genesis has 50 chapters
        let result = ReferenceParser.parse("Genesis 100:1")

        guard case .failure(let error) = result else {
            Issue.record("Expected failure")
            return
        }

        if case .invalidChapter(let book, let chapter, let max) = error {
            #expect(book == "Genesis")
            #expect(chapter == 100)
            #expect(max == 50)
        } else {
            Issue.record("Expected invalidChapter error")
        }
    }

    @Test("Invalid format returns error")
    func testInvalidFormat() {
        let result = ReferenceParser.parse("not a reference")

        guard case .failure(let error) = result else {
            Issue.record("Expected failure")
            return
        }

        if case .invalidFormat = error {
            // Success
        } else {
            Issue.record("Expected invalidFormat error")
        }
    }

    // MARK: - extractAll Tests

    @Test("Extract all references from text")
    func testExtractAll() {
        let text = """
        In John 3:16, we see God's love. Romans 8:28 tells us about purpose.
        The Sermon on the Mount in Matthew 5:3-12 lists the beatitudes.
        """

        let refs = ReferenceParser.extractAll(from: text)

        #expect(refs.count == 3)

        let refStrings = refs.map { $0.displayText }
        #expect(refStrings.contains("John 3:16"))
        #expect(refStrings.contains("Romans 8:28"))
        #expect(refStrings.contains("Matthew 5:3-12"))
    }

    @Test("Extract all deduplicates")
    func testExtractAll_Deduplicates() {
        let text = "John 3:16 is quoted often. See John 3:16 again."

        let refs = ReferenceParser.extractAll(from: text)

        #expect(refs.count == 1)
        #expect(refs.first?.displayText == "John 3:16")
    }

    @Test("Extract all returns empty for no matches")
    func testExtractAll_NoMatches() {
        let text = "This text has no Bible references."

        let refs = ReferenceParser.extractAll(from: text)

        #expect(refs.isEmpty)
    }

    // MARK: - Canonical ID Tests

    @Test("Canonical ID for single verse")
    func testCanonicalId_SingleVerse() {
        guard case .success(let parsed) = ReferenceParser.parse("John 3:16") else {
            Issue.record("Parse failed")
            return
        }

        let id = ReferenceParser.canonicalId(for: parsed)
        #expect(id == "43.3.16")
    }

    @Test("Canonical ID for verse range")
    func testCanonicalId_VerseRange() {
        guard case .success(let parsed) = ReferenceParser.parse("Romans 8:28-30") else {
            Issue.record("Parse failed")
            return
        }

        let id = ReferenceParser.canonicalId(for: parsed)
        #expect(id == "45.8.28-30")
    }

    @Test("Canonical ID for chapter only")
    func testCanonicalId_ChapterOnly() {
        guard case .success(let parsed) = ReferenceParser.parse("Genesis 1") else {
            Issue.record("Parse failed")
            return
        }

        let id = ReferenceParser.canonicalId(for: parsed)
        #expect(id == "1.1")
    }

    @Test("Parse canonical ID - single verse")
    func testParseCanonicalId_SingleVerse() {
        guard let result = ReferenceParser.parseCanonicalId("43.3.16") else {
            Issue.record("Parse failed")
            return
        }

        #expect(result.bookId == 43)
        #expect(result.chapter == 3)
        #expect(result.verseStart == 16)
        #expect(result.verseEnd == nil)
    }

    @Test("Parse canonical ID - verse range")
    func testParseCanonicalId_VerseRange() {
        guard let result = ReferenceParser.parseCanonicalId("45.8.28-30") else {
            Issue.record("Parse failed")
            return
        }

        #expect(result.bookId == 45)
        #expect(result.chapter == 8)
        #expect(result.verseStart == 28)
        #expect(result.verseEnd == 30)
    }

    @Test("Parse canonical ID - chapter only")
    func testParseCanonicalId_ChapterOnly() {
        guard let result = ReferenceParser.parseCanonicalId("1.1") else {
            Issue.record("Parse failed")
            return
        }

        #expect(result.bookId == 1)
        #expect(result.chapter == 1)
        #expect(result.verseStart == nil)
        #expect(result.verseEnd == nil)
    }

    @Test("Parse canonical ID - invalid returns nil")
    func testParseCanonicalId_Invalid() {
        let result = ReferenceParser.parseCanonicalId("invalid")
        #expect(result == nil)
    }

    // MARK: - Flexible Parse Tests

    @Test("Parse flexible - space separated")
    func testParseFlexible_SpaceSeparated() {
        let result = ReferenceParser.parseFlexible("Romans 5 8")

        guard case .success(let parsed) = result else {
            Issue.record("Expected success")
            return
        }

        #expect(parsed.book.name == "Romans")
        #expect(parsed.chapter == 5)
        #expect(parsed.verseStart == 8)
    }

    @Test("Parse flexible - colon format still works")
    func testParseFlexible_ColonFormat() {
        let result = ReferenceParser.parseFlexible("John 3:16")

        guard case .success(let parsed) = result else {
            Issue.record("Expected success")
            return
        }

        #expect(parsed.book.name == "John")
        #expect(parsed.chapter == 3)
        #expect(parsed.verseStart == 16)
    }

    // MARK: - Suggestion Tests

    @Test("Suggestions returns matching books")
    func testSuggestions() {
        let suggestions = ReferenceParser.suggestions(for: "Gen")

        #expect(!suggestions.isEmpty)
        #expect(suggestions.first?.name == "Genesis")
    }

    @Test("Suggestions returns empty for no match")
    func testSuggestions_NoMatch() {
        let suggestions = ReferenceParser.suggestions(for: "xyz")

        #expect(suggestions.isEmpty)
    }

    @Test("Suggestions respects limit")
    func testSuggestions_Limit() {
        let suggestions = ReferenceParser.suggestions(for: "J", limit: 2)

        #expect(suggestions.count <= 2)
    }
}

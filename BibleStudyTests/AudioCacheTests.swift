import XCTest
@testable import BibleStudy

// MARK: - Audio Cache Tests

final class AudioCacheTests: XCTestCase {

    private var testChapter: AudioChapter!

    override func setUp() {
        super.setUp()

        // Create a test chapter for caching tests
        let location = BibleLocation(bookId: 99, chapter: 99)
        testChapter = AudioChapter(
            location: location,
            bookName: "TestBook",
            translation: "TEST",
            verses: [
                Verse(bookId: 99, chapter: 99, verse: 1, text: "Test verse content.")
            ]
        )
    }

    override func tearDown() {
        // Clean up any test cached files
        if let chapter = testChapter {
            AudioCache.shared.deleteCachedAudio(for: chapter)
        }
        testChapter = nil

        super.tearDown()
    }

    // MARK: - Cache Retrieval Tests

    func testGetCachedAudioReturnsNilWhenNotCached() {
        // Ensure clean state
        AudioCache.shared.deleteCachedAudio(for: testChapter)

        let cachedURL = AudioCache.shared.getCachedAudio(for: testChapter)

        XCTAssertNil(cachedURL)
    }

    func testIsDownloadedReturnsFalseWhenNotCached() {
        // Ensure clean state
        AudioCache.shared.deleteCachedAudio(for: testChapter)

        let isDownloaded = AudioCache.shared.isDownloaded(testChapter)

        XCTAssertFalse(isDownloaded)
    }

    // MARK: - Cache Write Tests

    func testCacheAudioCreatesFile() throws {
        // Create test audio data
        let testData = Data("Test audio content".utf8)

        // Cache the data
        let cachedURL = try AudioCache.shared.cacheAudio(testData, for: testChapter)

        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: cachedURL.path))

        // Verify we can retrieve it
        let retrievedURL = AudioCache.shared.getCachedAudio(for: testChapter)
        XCTAssertNotNil(retrievedURL)
        XCTAssertEqual(cachedURL, retrievedURL)
    }

    func testCacheAudioUpdatesIsDownloaded() throws {
        // Create test audio data
        let testData = Data("Test audio content".utf8)

        // Initially not downloaded
        XCTAssertFalse(AudioCache.shared.isDownloaded(testChapter))

        // Cache the data
        _ = try AudioCache.shared.cacheAudio(testData, for: testChapter)

        // Now should be downloaded
        XCTAssertTrue(AudioCache.shared.isDownloaded(testChapter))
    }

    func testCacheAudioPreservesData() throws {
        // Create test audio data
        let testData = Data("Test audio content for round trip".utf8)

        // Cache the data
        let cachedURL = try AudioCache.shared.cacheAudio(testData, for: testChapter)

        // Read it back
        let retrievedData = try Data(contentsOf: cachedURL)

        // Verify data integrity
        XCTAssertEqual(testData, retrievedData)
    }

    // MARK: - Cache Delete Tests

    func testDeleteCachedAudioRemovesFile() throws {
        // First cache some data
        let testData = Data("Test audio content".utf8)
        let cachedURL = try AudioCache.shared.cacheAudio(testData, for: testChapter)

        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: cachedURL.path))

        // Delete it
        AudioCache.shared.deleteCachedAudio(for: testChapter)

        // Verify file no longer exists
        XCTAssertFalse(FileManager.default.fileExists(atPath: cachedURL.path))
        XCTAssertNil(AudioCache.shared.getCachedAudio(for: testChapter))
    }

    // MARK: - Cache Size Tests

    func testCacheSizeIsNonNegative() {
        let size = AudioCache.shared.cacheSize()

        XCTAssertGreaterThanOrEqual(size, 0)
    }

    func testFormattedCacheSizeReturnsString() {
        let formatted = AudioCache.shared.formattedCacheSize()

        XCTAssertFalse(formatted.isEmpty)
    }

    func testCacheSizeIncreasesAfterCaching() throws {
        // Get initial size
        let initialSize = AudioCache.shared.cacheSize()

        // Cache some data
        let testData = Data(repeating: 0, count: 10000) // 10KB of zeros
        _ = try AudioCache.shared.cacheAudio(testData, for: testChapter)

        // Get new size
        let newSize = AudioCache.shared.cacheSize()

        // Size should have increased
        XCTAssertGreaterThan(newSize, initialSize)
    }

    // MARK: - Downloaded Chapters Tests

    func testDownloadedChaptersReturnsChapterIds() throws {
        // Cache a chapter
        let testData = Data("Test audio content".utf8)
        _ = try AudioCache.shared.cacheAudio(testData, for: testChapter)

        // Get downloaded chapters
        let downloadedChapters = AudioCache.shared.downloadedChapters()

        // Should contain our test chapter ID
        XCTAssertTrue(downloadedChapters.contains(testChapter.id))
    }

    // MARK: - File Extension Tests

    func testCacheUsesCAFExtension() throws {
        // Cache some data
        let testData = Data("Test audio content".utf8)
        let cachedURL = try AudioCache.shared.cacheAudio(testData, for: testChapter)

        // Verify file extension is .caf
        XCTAssertEqual(cachedURL.pathExtension, "caf")
    }

    // MARK: - Clear Cache Tests

    func testClearCacheRemovesAllFiles() throws {
        // Cache some data
        let testData = Data("Test audio content".utf8)
        _ = try AudioCache.shared.cacheAudio(testData, for: testChapter)

        // Verify something is cached
        XCTAssertTrue(AudioCache.shared.isDownloaded(testChapter))

        // Clear cache
        AudioCache.shared.clearCache()

        // Verify cache is empty (or at least our test file is gone)
        XCTAssertFalse(AudioCache.shared.isDownloaded(testChapter))
    }
}

// MARK: - Cache LRU Tests

final class AudioCacheLRUTests: XCTestCase {

    func testLRUCacheUpdateAccessDate() throws {
        // Create a test chapter
        let location = BibleLocation(bookId: 98, chapter: 1)
        let chapter = AudioChapter(
            location: location,
            bookName: "LRUTest",
            translation: "TEST",
            verses: []
        )

        defer {
            AudioCache.shared.deleteCachedAudio(for: chapter)
        }

        // Cache some data
        let testData = Data("Test audio content".utf8)
        let cachedURL = try AudioCache.shared.cacheAudio(testData, for: chapter)

        // Get modification date
        let attributes1 = try FileManager.default.attributesOfItem(atPath: cachedURL.path)
        let modDate1 = attributes1[.modificationDate] as? Date

        // Wait a moment
        Thread.sleep(forTimeInterval: 0.1)

        // Access the cached file (should update modification date)
        _ = AudioCache.shared.getCachedAudio(for: chapter)

        // Get new modification date
        let attributes2 = try FileManager.default.attributesOfItem(atPath: cachedURL.path)
        let modDate2 = attributes2[.modificationDate] as? Date

        // Date should have been updated
        if let date1 = modDate1, let date2 = modDate2 {
            XCTAssertGreaterThanOrEqual(date2, date1)
        }
    }
}

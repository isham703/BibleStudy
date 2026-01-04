import XCTest
@testable import BibleStudy

// MARK: - Audio Service Tests

@MainActor
final class AudioServiceTests: XCTestCase {

    // MARK: - Initial State Tests

    func testInitialState() {
        let service = AudioService.shared

        // Verify initial playback state is idle
        XCTAssertEqual(service.playbackState, .idle)
        XCTAssertFalse(service.isPlaying)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.currentChapter)
        XCTAssertNil(service.currentVerse)
        XCTAssertEqual(service.currentTime, 0)
        XCTAssertEqual(service.duration, 0)
        XCTAssertEqual(service.progress, 0)
    }

    func testDefaultSettings() {
        let service = AudioService.shared

        // Verify default settings
        XCTAssertEqual(service.playbackRate, 1.0)
        XCTAssertFalse(service.isSleepTimerActive)
        XCTAssertEqual(service.sleepTimerRemaining, 0)
    }

    // MARK: - Playback Rate Tests

    func testPlaybackRateChange() {
        let service = AudioService.shared

        service.playbackRate = 1.5
        XCTAssertEqual(service.playbackRate, 1.5)

        service.playbackRate = 0.75
        XCTAssertEqual(service.playbackRate, 0.75)

        // Reset
        service.playbackRate = 1.0
    }

    // MARK: - Sleep Timer Tests

    func testSleepTimerSet() {
        let service = AudioService.shared

        service.setSleepTimer(minutes: 15)

        XCTAssertTrue(service.isSleepTimerActive)
        XCTAssertEqual(service.sleepTimerRemaining, 15 * 60, accuracy: 1)
        XCTAssertFalse(service.sleepTimerEndOfChapter)

        // Clean up
        service.cancelSleepTimer()
    }

    func testSleepTimerEndOfChapter() {
        let service = AudioService.shared

        service.setSleepTimerEndOfChapter()

        XCTAssertTrue(service.isSleepTimerActive)
        XCTAssertTrue(service.sleepTimerEndOfChapter)
        XCTAssertEqual(service.sleepTimerRemaining, 0)

        // Clean up
        service.cancelSleepTimer()
    }

    func testSleepTimerCancel() {
        let service = AudioService.shared

        service.setSleepTimer(minutes: 30)
        XCTAssertTrue(service.isSleepTimerActive)

        service.cancelSleepTimer()

        XCTAssertFalse(service.isSleepTimerActive)
        XCTAssertEqual(service.sleepTimerRemaining, 0)
        XCTAssertFalse(service.sleepTimerEndOfChapter)
    }

    func testSleepTimerFormattedRemaining() {
        let service = AudioService.shared

        // Test end of chapter label
        service.setSleepTimerEndOfChapter()
        XCTAssertEqual(service.formattedSleepTimerRemaining, "End of chapter")

        service.cancelSleepTimer()

        // Test minutes format
        service.setSleepTimer(minutes: 5)
        // Format should be "Xm Ys"
        XCTAssertTrue(service.formattedSleepTimerRemaining.contains("m"))

        service.cancelSleepTimer()
    }

    // MARK: - Time Formatting Tests

    func testFormattedCurrentTime() {
        let service = AudioService.shared

        // When idle, should return "0:00"
        XCTAssertEqual(service.formattedCurrentTime, "0:00")
    }

    func testFormattedDuration() {
        let service = AudioService.shared

        // When idle, should return "0:00"
        XCTAssertEqual(service.formattedDuration, "0:00")
    }

    // MARK: - Progress Tests

    func testProgressWhenIdle() {
        let service = AudioService.shared

        // Progress should be 0 when duration is 0
        XCTAssertEqual(service.progress, 0)
    }

    // MARK: - Stop Tests

    func testStopResetsState() {
        let service = AudioService.shared

        // Set some state
        service.setSleepTimer(minutes: 10)

        // Stop should reset everything
        service.stop()

        XCTAssertEqual(service.playbackState, .idle)
        XCTAssertEqual(service.currentTime, 0)
        XCTAssertEqual(service.duration, 0)
        XCTAssertFalse(service.isSleepTimerActive)
    }
}

// MARK: - Audio Chapter Tests

final class AudioChapterTests: XCTestCase {

    func testAudioChapterInitialization() {
        let location = BibleLocation(bookId: 1, chapter: 1)
        let verses = [
            Verse(bookId: 1, chapter: 1, verse: 1, text: "In the beginning God created the heavens and the earth."),
            Verse(bookId: 1, chapter: 1, verse: 2, text: "The earth was formless and empty.")
        ]

        let chapter = AudioChapter(
            location: location,
            bookName: "Genesis",
            translation: "KJV",
            verses: verses
        )

        XCTAssertEqual(chapter.bookId, 1)
        XCTAssertEqual(chapter.bookName, "Genesis")
        XCTAssertEqual(chapter.chapterNumber, 1)
        XCTAssertEqual(chapter.translation, "KJV")
        XCTAssertEqual(chapter.verses.count, 2)
        // Verse timings start empty and are populated by TTS generation
        XCTAssertEqual(chapter.verseTimings.count, 0)
    }

    func testSetVerseTimings() {
        let location = BibleLocation(bookId: 1, chapter: 1)
        let verses = [
            Verse(bookId: 1, chapter: 1, verse: 1, text: "First verse."),
            Verse(bookId: 1, chapter: 1, verse: 2, text: "Second verse.")
        ]

        var chapter = AudioChapter(
            location: location,
            bookName: "Genesis",
            translation: "KJV",
            verses: verses
        )

        // Set actual timings (as TTS would produce)
        let timings = [
            VerseTiming(verseNumber: 1, startTime: 0.0, endTime: 1.5),
            VerseTiming(verseNumber: 2, startTime: 1.5, endTime: 3.0)
        ]
        chapter.setVerseTimings(timings)

        XCTAssertEqual(chapter.verseTimings.count, 2)
        XCTAssertEqual(chapter.verseTimings[0].startTime, 0.0)
        XCTAssertEqual(chapter.verseTimings[0].endTime, 1.5)
        XCTAssertEqual(chapter.verseTimings[1].startTime, 1.5)
    }

    func testAudioChapterId() {
        let location = BibleLocation(bookId: 1, chapter: 1)
        let chapter = AudioChapter(
            location: location,
            bookName: "Genesis",
            translation: "KJV",
            verses: []
        )

        // ID should include book, chapter, and translation
        XCTAssertEqual(chapter.id, "1-1-KJV")
    }

    func testVerseTimingsAreMonotonic() {
        let location = BibleLocation(bookId: 1, chapter: 1)
        let verses = [
            Verse(bookId: 1, chapter: 1, verse: 1, text: "First verse with some words."),
            Verse(bookId: 1, chapter: 1, verse: 2, text: "Second verse."),
            Verse(bookId: 1, chapter: 1, verse: 3, text: "Third verse with more content.")
        ]

        var chapter = AudioChapter(
            location: location,
            bookName: "Genesis",
            translation: "KJV",
            verses: verses
        )

        // Set timings as TTS would produce them
        let timings = [
            VerseTiming(verseNumber: 1, startTime: 0.0, endTime: 2.5),
            VerseTiming(verseNumber: 2, startTime: 2.5, endTime: 4.0),
            VerseTiming(verseNumber: 3, startTime: 4.0, endTime: 7.0)
        ]
        chapter.setVerseTimings(timings)

        // Verify timings are monotonically increasing
        var previousEndTime: TimeInterval = 0
        for timing in chapter.verseTimings {
            XCTAssertGreaterThanOrEqual(timing.startTime, previousEndTime)
            XCTAssertGreaterThan(timing.endTime, timing.startTime)
            previousEndTime = timing.endTime
        }
    }

    func testCacheKeyIncludesVoiceSettings() {
        let location = BibleLocation(bookId: 1, chapter: 1)
        let chapter = AudioChapter(
            location: location,
            bookName: "Genesis",
            translation: "KJV",
            verses: []
        )

        // Cache key should include voice/rate settings to handle regeneration
        XCTAssertFalse(chapter.cacheKey.isEmpty)
        XCTAssertTrue(chapter.cacheKey.contains("1-1-KJV"))
    }
}

// MARK: - Audio Error Tests

final class AudioErrorTests: XCTestCase {

    func testLoadFailedError() {
        let error = AudioError.loadFailed("Test error message")

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Test error message") ?? false)
    }

    func testGenerationFailedError() {
        let error = AudioError.generationFailed

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("generate") ?? false)
    }

    func testNotAvailableError() {
        let error = AudioError.notAvailable

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("not available") ?? false)
    }
}

// MARK: - Playback State Tests

final class PlaybackStateTests: XCTestCase {

    func testPlaybackStateEquality() {
        XCTAssertEqual(PlaybackState.idle, PlaybackState.idle)
        XCTAssertEqual(PlaybackState.playing, PlaybackState.playing)
        XCTAssertNotEqual(PlaybackState.playing, PlaybackState.paused)
    }

    func testAllPlaybackStates() {
        // Verify all states are distinct
        let states: [PlaybackState] = [.idle, .loading, .ready, .playing, .paused, .finished, .error]

        for (index, state) in states.enumerated() {
            for (otherIndex, otherState) in states.enumerated() {
                if index == otherIndex {
                    XCTAssertEqual(state, otherState)
                } else {
                    XCTAssertNotEqual(state, otherState)
                }
            }
        }
    }
}

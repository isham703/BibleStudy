import SwiftUI

// MARK: - Parallel Reading View Model
// Manages state for viewing two passages side-by-side

@Observable
@MainActor
final class ParallelReadingViewModel {
    // MARK: - Dependencies
    private let bibleService: BibleService

    // MARK: - State
    var leftLocation: BibleLocation
    var rightLocation: BibleLocation

    var leftChapter: Chapter?
    var rightChapter: Chapter?

    var isLoadingLeft: Bool = false
    var isLoadingRight: Bool = false
    var error: Error?

    // Translation support
    var leftTranslationId: String = "kjv"
    var rightTranslationId: String = "esv"

    // Sync scrolling
    var syncScrolling: Bool = true

    // MARK: - Computed Properties
    var leftTitle: String {
        guard let chapter = leftChapter else {
            return leftLocation.reference
        }
        let bookName = Book.find(byId: chapter.bookId)?.name ?? "Unknown"
        return "\(bookName) \(chapter.chapter)"
    }

    var rightTitle: String {
        guard let chapter = rightChapter else {
            return rightLocation.reference
        }
        let bookName = Book.find(byId: chapter.bookId)?.name ?? "Unknown"
        return "\(bookName) \(chapter.chapter)"
    }

    var isLoading: Bool {
        isLoadingLeft || isLoadingRight
    }

    // MARK: - Initialization
    init(
        leftLocation: BibleLocation = BibleLocation(bookId: 1, chapter: 1),
        rightLocation: BibleLocation = BibleLocation(bookId: 43, chapter: 1),
        bibleService: BibleService? = nil
    ) {
        self.leftLocation = leftLocation
        self.rightLocation = rightLocation
        self.bibleService = bibleService ?? BibleService.shared
    }

    // MARK: - Loading

    func loadBothChapters() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.loadLeftChapter()
            }
            group.addTask {
                await self.loadRightChapter()
            }
        }
    }

    func loadLeftChapter() async {
        isLoadingLeft = true
        defer { isLoadingLeft = false }

        do {
            leftChapter = try await bibleService.getChapter(location: leftLocation, translationId: leftTranslationId)
        } catch {
            self.error = error
        }
    }

    func loadRightChapter() async {
        isLoadingRight = true
        defer { isLoadingRight = false }

        do {
            rightChapter = try await bibleService.getChapter(location: rightLocation, translationId: rightTranslationId)
        } catch {
            self.error = error
        }
    }

    // MARK: - Navigation

    func goToLeftChapter(bookId: Int, chapter: Int) async {
        leftLocation = BibleLocation(bookId: bookId, chapter: chapter)
        await loadLeftChapter()
    }

    func goToRightChapter(bookId: Int, chapter: Int) async {
        rightLocation = BibleLocation(bookId: bookId, chapter: chapter)
        await loadRightChapter()
    }

    func goToPreviousLeft() async {
        guard leftLocation.chapter > 1 else { return }
        leftLocation = BibleLocation(bookId: leftLocation.bookId, chapter: leftLocation.chapter - 1)
        await loadLeftChapter()
    }

    func goToNextLeft() async {
        leftLocation = BibleLocation(bookId: leftLocation.bookId, chapter: leftLocation.chapter + 1)
        await loadLeftChapter()
    }

    func goToPreviousRight() async {
        guard rightLocation.chapter > 1 else { return }
        rightLocation = BibleLocation(bookId: rightLocation.bookId, chapter: rightLocation.chapter - 1)
        await loadRightChapter()
    }

    func goToNextRight() async {
        rightLocation = BibleLocation(bookId: rightLocation.bookId, chapter: rightLocation.chapter + 1)
        await loadRightChapter()
    }

    // MARK: - Swap Panels

    func swapPanels() {
        let tempLocation = leftLocation
        let tempChapter = leftChapter
        let tempTranslation = leftTranslationId

        leftLocation = rightLocation
        leftChapter = rightChapter
        leftTranslationId = rightTranslationId

        rightLocation = tempLocation
        rightChapter = tempChapter
        rightTranslationId = tempTranslation
    }

    // MARK: - Synoptic Gospel Presets

    static let synopticPresets: [(name: String, passages: [(Int, Int)])] = [
        ("Baptism of Jesus", [(40, 3), (41, 1), (42, 3)]),  // Matt 3, Mark 1, Luke 3
        ("Sermon on Mount/Plain", [(40, 5), (42, 6)]),      // Matt 5, Luke 6
        ("Feeding 5000", [(40, 14), (41, 6), (42, 9), (43, 6)]), // Matt 14, Mark 6, Luke 9, John 6
        ("Transfiguration", [(40, 17), (41, 9), (42, 9)]),  // Matt 17, Mark 9, Luke 9
        ("Last Supper", [(40, 26), (41, 14), (42, 22), (43, 13)]), // Matt 26, Mark 14, Luke 22, John 13
        ("Resurrection", [(40, 28), (41, 16), (42, 24), (43, 20)]) // Matt 28, Mark 16, Luke 24, John 20
    ]

    func loadSynopticPreset(_ preset: (name: String, passages: [(Int, Int)])) async {
        guard preset.passages.count >= 2 else { return }

        let left = preset.passages[0]
        let right = preset.passages[1]

        leftLocation = BibleLocation(bookId: left.0, chapter: left.1)
        rightLocation = BibleLocation(bookId: right.0, chapter: right.1)

        await loadBothChapters()
    }
}

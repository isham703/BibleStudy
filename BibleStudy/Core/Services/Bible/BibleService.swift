import Foundation

// MARK: - Bible Service
// High-level service for Bible data access used by ViewModels

@MainActor
@Observable
final class BibleService {
    // MARK: - Singleton
    static let shared = BibleService()

    // MARK: - Properties
    private let repository = BibleRepository.shared
    private let entitlementManager = EntitlementManager.shared

    var isDataLoaded: Bool = false
    var isLoading: Bool = false
    var error: Error?

    /// Currently selected translation for reading
    var currentTranslationId: String = BibleRepository.defaultTranslationId

    /// Available translations (populated from database)
    var availableTranslations: [Translation] = []

    /// Current translation object
    var currentTranslation: Translation? {
        Translation.find(byId: currentTranslationId)
    }

    // MARK: - Chapter Cache
    private var chapterCache: [String: CachedChapter] = [:]
    private let maxCacheSize = 10
    private var prefetchTask: Task<Void, Never>?

    /// Cache entry with access tracking for LRU eviction
    private struct CachedChapter {
        let chapter: Chapter
        var lastAccessed: Date

        init(chapter: Chapter) {
            self.chapter = chapter
            self.lastAccessed = Date()
        }
    }

    /// Generate cache key for a chapter location
    private func cacheKey(bookId: Int, chapter: Int, translationId: String) -> String {
        "\(translationId):\(bookId):\(chapter)"
    }

    // MARK: - Initialization
    private init() {
        loadTranslationPreference()
    }

    private func loadTranslationPreference() {
        if let savedTranslation = UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.preferredTranslation) {
            currentTranslationId = savedTranslation
        }
    }

    /// Set the current translation (may trigger paywall for premium translations)
    /// - Parameter translationId: The translation ID to switch to
    /// - Returns: true if translation was set, false if blocked by entitlement
    @discardableResult
    func setTranslation(_ translationId: String) -> Bool {
        // Check if translation is available for the user's tier
        guard entitlementManager.isTranslationAvailable(translationId) else {
            // Trigger paywall for premium translations
            entitlementManager.showPaywall(trigger: .translationLimit)
            return false
        }

        currentTranslationId = translationId
        UserDefaults.standard.set(translationId, forKey: AppConfiguration.UserDefaultsKeys.preferredTranslation)
        return true
    }

    // MARK: - Setup
    func initialize() async {
        guard !isDataLoaded else { return }

        isLoading = true
        error = nil

        do {
            // Initialize database
            try DatabaseManager.shared.setup()

            // Check if data exists
            let hasData = try repository.hasData()

            if !hasData {
                // Import sample Bible data
                try await importSampleData()
            }

            // Load available translations
            availableTranslations = try repository.getTranslations()

            isDataLoaded = true
            print("Bible data loaded successfully")
            print("Available translations: \(availableTranslations.map { $0.abbreviation })")
        } catch {
            self.error = error
            print("Failed to initialize Bible service: \(error)")
        }

        isLoading = false
    }

    // MARK: - Data Import
    private func importSampleData() async throws {
        // Import KJV sample data (Genesis, Psalms 1-50, John)
        // This will be bundled with the app
        let verseCount = try repository.importVersesFromBundle(filename: "kjv_sample")
        print("Imported \(verseCount) verses")

        // Import cross-references
        do {
            let crossRefCount = try CrossRefService.shared.importFromBundle(filename: "crossrefs_sample")
            print("Imported \(crossRefCount) cross-references")
        } catch {
            print("Cross-refs import skipped or failed: \(error.localizedDescription)")
        }

        // Import language tokens
        do {
            let tokenCount = try LanguageService.shared.importFromBundle(filename: "tokens_sample")
            print("Imported \(tokenCount) language tokens")
        } catch {
            print("Tokens import skipped or failed: \(error.localizedDescription)")
        }

        // Import topics from bundled JSON
        do {
            let topicCount = try await importTopicsFromBundle()
            print("Imported \(topicCount) topics")
        } catch {
            print("Topics import skipped or failed: \(error.localizedDescription)")
        }

        // Mark as imported
        UserDefaults.standard.set(true, forKey: AppConfiguration.UserDefaultsKeys.hasImportedBibleData)
    }

    private func importTopicsFromBundle() async throws -> Int {
        guard let url = Bundle.main.url(forResource: "topics_sample", withExtension: "json") else {
            return 0
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let topics = try decoder.decode([TopicDTO].self, from: data)

        // Load topics into TopicService
        TopicService.shared.topics = topics.map { Topic(from: $0) }

        return topics.count
    }

    // MARK: - Verse Access

    /// Get a single verse in the current translation
    func getVerse(bookId: Int, chapter: Int, verse: Int, translationId: String? = nil) async throws -> Verse? {
        try repository.getVerse(bookId: bookId, chapter: chapter, verse: verse, translationId: translationId ?? currentTranslationId)
    }

    /// Get a verse by reference string (e.g., "John 3:16")
    func getVerse(reference: String, translationId: String? = nil) async throws -> Verse? {
        guard let parsed = Verse.parseReference(reference) else {
            return nil
        }
        return try await getVerse(bookId: parsed.bookId, chapter: parsed.chapter, verse: parsed.verse, translationId: translationId)
    }

    /// Get all verses for a chapter in the current translation (with caching)
    func getChapter(bookId: Int, chapter: Int, translationId: String? = nil) async throws -> Chapter {
        let translationToUse = translationId ?? currentTranslationId
        let key = cacheKey(bookId: bookId, chapter: chapter, translationId: translationToUse)

        // Check cache first
        if var cached = chapterCache[key] {
            cached.lastAccessed = Date()
            chapterCache[key] = cached
            return cached.chapter
        }

        // Load from repository
        let verses = try repository.getChapter(bookId: bookId, chapter: chapter, translationId: translationToUse)
        let loadedChapter = Chapter(bookId: bookId, chapter: chapter, verses: verses, translationId: translationToUse)

        // Cache the chapter
        cacheChapter(loadedChapter, forKey: key)

        return loadedChapter
    }

    /// Get a chapter by location (with caching and prefetching)
    func getChapter(location: BibleLocation, translationId: String? = nil) async throws -> Chapter {
        let chapter = try await getChapter(bookId: location.bookId, chapter: location.chapter, translationId: translationId)

        // Prefetch adjacent chapters in background
        prefetchAdjacentChapters(for: location, translationId: translationId ?? currentTranslationId)

        return chapter
    }

    // MARK: - Cache Management

    /// Add chapter to cache with LRU eviction
    private func cacheChapter(_ chapter: Chapter, forKey key: String) {
        // Evict oldest if at capacity
        if chapterCache.count >= maxCacheSize {
            evictOldestCacheEntry()
        }

        chapterCache[key] = CachedChapter(chapter: chapter)
    }

    /// Remove least recently used cache entry
    private func evictOldestCacheEntry() {
        guard let oldestKey = chapterCache.min(by: { $0.value.lastAccessed < $1.value.lastAccessed })?.key else {
            return
        }
        chapterCache.removeValue(forKey: oldestKey)
    }

    /// Clear the entire chapter cache
    func clearCache() {
        chapterCache.removeAll()
        prefetchTask?.cancel()
        prefetchTask = nil
    }

    /// Get cache statistics for debugging
    var cacheStats: (count: Int, maxSize: Int) {
        (chapterCache.count, maxCacheSize)
    }

    // MARK: - Prefetching

    /// Prefetch adjacent chapters in background
    private func prefetchAdjacentChapters(for location: BibleLocation, translationId: String) {
        // Cancel any existing prefetch task
        prefetchTask?.cancel()

        prefetchTask = Task { [weak self] in
            guard let self = self else { return }

            // Get adjacent locations
            guard let book = Book.find(byId: location.bookId) else { return }
            let previous = location.previous()
            let next = location.next(maxChapter: book.chapters)

            // Prefetch previous chapter if not cached
            if let prev = previous {
                let prevKey = self.cacheKey(bookId: prev.bookId, chapter: prev.chapter, translationId: translationId)
                if self.chapterCache[prevKey] == nil {
                    do {
                        try await Task.sleep(nanoseconds: 100_000_000) // Small delay to prioritize main load
                        guard !Task.isCancelled else { return }
                        let verses = try self.repository.getChapter(bookId: prev.bookId, chapter: prev.chapter, translationId: translationId)
                        let chapter = Chapter(bookId: prev.bookId, chapter: prev.chapter, verses: verses, translationId: translationId)
                        guard !Task.isCancelled else { return }
                        self.cacheChapter(chapter, forKey: prevKey)
                    } catch {
                        // Silently fail prefetch - not critical
                    }
                }
            }

            // Prefetch next chapter if not cached
            if let nextLoc = next {
                let nextKey = self.cacheKey(bookId: nextLoc.bookId, chapter: nextLoc.chapter, translationId: translationId)
                if self.chapterCache[nextKey] == nil {
                    do {
                        try await Task.sleep(nanoseconds: 100_000_000) // Small delay
                        guard !Task.isCancelled else { return }
                        let verses = try self.repository.getChapter(bookId: nextLoc.bookId, chapter: nextLoc.chapter, translationId: translationId)
                        let chapter = Chapter(bookId: nextLoc.bookId, chapter: nextLoc.chapter, verses: verses, translationId: translationId)
                        guard !Task.isCancelled else { return }
                        self.cacheChapter(chapter, forKey: nextKey)
                    } catch {
                        // Silently fail prefetch - not critical
                    }
                }
            }
        }
    }

    /// Get verses in a range
    func getVerses(range: VerseRange, translationId: String? = nil) async throws -> [Verse] {
        try repository.getVerses(range: range, translationId: translationId ?? currentTranslationId)
    }

    /// Get text for a verse range
    func getText(range: VerseRange, translationId: String? = nil) async throws -> String {
        let verses = try await getVerses(range: range, translationId: translationId)
        return verses.map { $0.text }.joined(separator: " ")
    }

    /// Get a verse in multiple translations for comparison
    func getVerseComparison(bookId: Int, chapter: Int, verse: Int, translationIds: [String]? = nil) async throws -> [Verse] {
        let translations = translationIds ?? availableTranslations.map { $0.id }
        return try repository.getVerseInTranslations(bookId: bookId, chapter: chapter, verse: verse, translationIds: translations)
    }

    // MARK: - Navigation Info

    /// Get chapter count for a book
    func getChapterCount(bookId: Int) async throws -> Int {
        // First try the Book metadata
        if let book = Book.find(byId: bookId) {
            return book.chapters
        }
        // Fall back to database
        return try repository.getChapterCount(bookId: bookId)
    }

    /// Get verse count for a chapter
    func getVerseCount(bookId: Int, chapter: Int) async throws -> Int {
        try repository.getVerseCount(bookId: bookId, chapter: chapter)
    }

    /// Check if we have data for a specific location
    func hasData(for location: BibleLocation) async -> Bool {
        do {
            return try repository.chapterExists(bookId: location.bookId, chapter: location.chapter)
        } catch {
            return false
        }
    }

    // MARK: - Search

    /// Search verses by text (legacy LIKE search)
    /// - Note: Use `SearchService.shared.search()` for FTS5 full-text search with BM25 ranking
    @available(*, deprecated, message: "Use SearchService.shared.search() for FTS5 full-text search")
    func search(query: String, limit: Int = 50) async throws -> [Verse] {
        try repository.searchVerses(query: query, limit: limit)
    }

    // MARK: - Context

    /// Get surrounding verses for context
    func getSurroundingVerses(for range: VerseRange, count: Int = 3) async throws -> (before: [Verse], after: [Verse]) {
        let beforeStart = max(1, range.verseStart - count)
        let afterEnd = range.verseEnd + count

        let beforeRange = VerseRange(
            bookId: range.bookId,
            chapter: range.chapter,
            verseStart: beforeStart,
            verseEnd: range.verseStart - 1
        )

        let afterRange = VerseRange(
            bookId: range.bookId,
            chapter: range.chapter,
            verseStart: range.verseEnd + 1,
            verseEnd: afterEnd
        )

        let beforeVerses = range.verseStart > 1 ? try await getVerses(range: beforeRange) : []
        let afterVerses = try await getVerses(range: afterRange)

        return (beforeVerses, afterVerses)
    }

    // MARK: - Books

    /// Get all available books (that have data)
    func getAvailableBooks() -> [Book] {
        // For now, return all books - in production, filter by what's in DB
        Book.all
    }

    /// Get books with sample data
    func getSampleBooks() -> [Book] {
        // Genesis, Psalms, John
        [Book.genesis, Book.psalms, Book.john]
    }
}

// MARK: - Book Info Extensions
extension BibleService {
    /// Get previous and next chapter locations
    func getAdjacentChapters(for location: BibleLocation) async -> (previous: BibleLocation?, next: BibleLocation?) {
        guard let book = Book.find(byId: location.bookId) else {
            return (nil, nil)
        }

        let previous = location.previous()
        let next = location.next(maxChapter: book.chapters)

        return (previous, next)
    }
}

import Foundation

// MARK: - AI Response Cache
// Caches AI responses to reduce API calls and improve response time

@MainActor
final class AIResponseCache {
    // MARK: - Singleton
    static let shared = AIResponseCache()

    // MARK: - Cache Storage
    private var quickInsightCache: [String: CachedResponse<QuickInsightOutput>] = [:]
    private var explanationCache: [String: CachedResponse<ExplanationOutput>] = [:]
    private var interpretationCache: [String: CachedResponse<InterpretationOutput>] = [:]
    private var simplificationCache: [String: CachedResponse<SimplifiedPassageOutput>] = [:]
    private var comprehensionCache: [String: CachedResponse<ComprehensionQuestionsOutput>] = [:]

    // MARK: - Configuration
    private let maxCacheSize = 50
    private let cacheExpirationSeconds: TimeInterval = 3600 // 1 hour

    // MARK: - Cache Entry
    private struct CachedResponse<T> {
        let response: T
        let createdAt: Date
        var lastAccessed: Date

        var isExpired: Bool {
            Date().timeIntervalSince(createdAt) > 3600 // 1 hour expiration
        }

        init(response: T) {
            self.response = response
            self.createdAt = Date()
            self.lastAccessed = Date()
        }
    }

    // MARK: - Initialization
    private init() {}

    // MARK: - Cache Key Generation

    /// Generate cache key for verse-based responses
    private func cacheKey(
        range: VerseRange,
        translationId: String,
        mode: String? = nil
    ) -> String {
        var key = "\(translationId):\(range.bookId):\(range.chapter):\(range.verseStart)-\(range.verseEnd)"
        if let mode = mode {
            key += ":\(mode)"
        }
        return key
    }

    // MARK: - Quick Insight Cache

    func getQuickInsight(for range: VerseRange, translationId: String) -> QuickInsightOutput? {
        let key = cacheKey(range: range, translationId: translationId, mode: "quick")

        guard var cached = quickInsightCache[key], !cached.isExpired else {
            quickInsightCache.removeValue(forKey: key)
            return nil
        }

        cached.lastAccessed = Date()
        quickInsightCache[key] = cached
        return cached.response
    }

    func cacheQuickInsight(_ response: QuickInsightOutput, for range: VerseRange, translationId: String) {
        let key = cacheKey(range: range, translationId: translationId, mode: "quick")
        evictIfNeeded(from: &quickInsightCache)
        quickInsightCache[key] = CachedResponse(response: response)
    }

    // MARK: - Explanation Cache

    func getExplanation(for range: VerseRange, translationId: String, mode: ExplanationMode) -> ExplanationOutput? {
        let key = cacheKey(range: range, translationId: translationId, mode: "explain:\(mode.rawValue)")

        guard var cached = explanationCache[key], !cached.isExpired else {
            explanationCache.removeValue(forKey: key)
            return nil
        }

        cached.lastAccessed = Date()
        explanationCache[key] = cached
        return cached.response
    }

    func cacheExplanation(_ response: ExplanationOutput, for range: VerseRange, translationId: String, mode: ExplanationMode) {
        let key = cacheKey(range: range, translationId: translationId, mode: "explain:\(mode.rawValue)")
        evictIfNeeded(from: &explanationCache)
        explanationCache[key] = CachedResponse(response: response)
    }

    // MARK: - Interpretation Cache

    func getInterpretation(for range: VerseRange, translationId: String, mode: InterpretationViewMode) -> InterpretationOutput? {
        let key = cacheKey(range: range, translationId: translationId, mode: "interpret:\(mode.rawValue)")

        guard var cached = interpretationCache[key], !cached.isExpired else {
            interpretationCache.removeValue(forKey: key)
            return nil
        }

        cached.lastAccessed = Date()
        interpretationCache[key] = cached
        return cached.response
    }

    func cacheInterpretation(_ response: InterpretationOutput, for range: VerseRange, translationId: String, mode: InterpretationViewMode) {
        let key = cacheKey(range: range, translationId: translationId, mode: "interpret:\(mode.rawValue)")
        evictIfNeeded(from: &interpretationCache)
        interpretationCache[key] = CachedResponse(response: response)
    }

    // MARK: - Simplification Cache

    func getSimplification(for range: VerseRange, translationId: String, level: ReadingLevel) -> SimplifiedPassageOutput? {
        let key = cacheKey(range: range, translationId: translationId, mode: "simplify:\(level.rawValue)")

        guard var cached = simplificationCache[key], !cached.isExpired else {
            simplificationCache.removeValue(forKey: key)
            return nil
        }

        cached.lastAccessed = Date()
        simplificationCache[key] = cached
        return cached.response
    }

    func cacheSimplification(_ response: SimplifiedPassageOutput, for range: VerseRange, translationId: String, level: ReadingLevel) {
        let key = cacheKey(range: range, translationId: translationId, mode: "simplify:\(level.rawValue)")
        evictIfNeeded(from: &simplificationCache)
        simplificationCache[key] = CachedResponse(response: response)
    }

    // MARK: - Comprehension Questions Cache

    func getComprehensionQuestions(for range: VerseRange, translationId: String, passageType: PassageType) -> ComprehensionQuestionsOutput? {
        let key = cacheKey(range: range, translationId: translationId, mode: "questions:\(passageType.rawValue)")

        guard var cached = comprehensionCache[key], !cached.isExpired else {
            comprehensionCache.removeValue(forKey: key)
            return nil
        }

        cached.lastAccessed = Date()
        comprehensionCache[key] = cached
        return cached.response
    }

    func cacheComprehensionQuestions(_ response: ComprehensionQuestionsOutput, for range: VerseRange, translationId: String, passageType: PassageType) {
        let key = cacheKey(range: range, translationId: translationId, mode: "questions:\(passageType.rawValue)")
        evictIfNeeded(from: &comprehensionCache)
        comprehensionCache[key] = CachedResponse(response: response)
    }

    // MARK: - Cache Management

    /// Evict oldest entry if cache is at capacity
    private func evictIfNeeded<T>(from cache: inout [String: CachedResponse<T>]) {
        // Remove expired entries first
        cache = cache.filter { !$0.value.isExpired }

        // If still at capacity, remove least recently accessed
        while cache.count >= maxCacheSize {
            if let oldestKey = cache.min(by: { $0.value.lastAccessed < $1.value.lastAccessed })?.key {
                cache.removeValue(forKey: oldestKey)
            } else {
                break
            }
        }
    }

    /// Clear all caches
    func clearAll() {
        quickInsightCache.removeAll()
        explanationCache.removeAll()
        interpretationCache.removeAll()
        simplificationCache.removeAll()
        comprehensionCache.removeAll()
    }

    /// Clear expired entries from all caches
    func purgeExpired() {
        quickInsightCache = quickInsightCache.filter { !$0.value.isExpired }
        explanationCache = explanationCache.filter { !$0.value.isExpired }
        interpretationCache = interpretationCache.filter { !$0.value.isExpired }
        simplificationCache = simplificationCache.filter { !$0.value.isExpired }
        comprehensionCache = comprehensionCache.filter { !$0.value.isExpired }
    }

    // MARK: - Statistics

    var totalCachedResponses: Int {
        quickInsightCache.count +
        explanationCache.count +
        interpretationCache.count +
        simplificationCache.count +
        comprehensionCache.count
    }

    var cacheBreakdown: [String: Int] {
        [
            "quickInsight": quickInsightCache.count,
            "explanation": explanationCache.count,
            "interpretation": interpretationCache.count,
            "simplification": simplificationCache.count,
            "comprehension": comprehensionCache.count
        ]
    }
}

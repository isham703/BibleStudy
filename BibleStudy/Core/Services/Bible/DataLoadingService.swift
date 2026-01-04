import Foundation
import GRDB

// MARK: - Data Loading Phase
/// Represents the current state of data loading
enum DataLoadingPhase: Equatable, Sendable {
    case idle
    case loading(description: String, progress: Double)
    case completed
    case failed(String)

    static func == (lhs: DataLoadingPhase, rhs: DataLoadingPhase) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.completed, .completed):
            return true
        case let (.loading(d1, p1), .loading(d2, p2)):
            return d1 == d2 && abs(p1 - p2) < 0.001
        case let (.failed(e1), .failed(e2)):
            return e1 == e2
        default:
            return false
        }
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var isComplete: Bool {
        if case .completed = self { return true }
        return false
    }
}

// MARK: - Data Loading Service
/// Manages background loading of Bible data with progress tracking
@MainActor
@Observable
final class DataLoadingService {
    // MARK: - Singleton
    static let shared = DataLoadingService()

    // MARK: - State
    var phase: DataLoadingPhase = .idle

    /// Whether all required data has been loaded
    var isDataReady: Bool {
        // Check if we have verse data
        do {
            let hasData = try BibleRepository.shared.hasData()
            return hasData
        } catch {
            return false
        }
    }

    /// Verse count from database (for display)
    var verseCount: Int = 0

    // MARK: - Configuration
    private let batchSize = 5000
    private let yieldInterval = 10  // Yield to main thread every N batches

    // MARK: - Initialization
    private init() {}

    // MARK: - Primary Loading Method

    /// Initialize and load all required data
    /// Call this from app launch
    func initializeData() async {
        // If data is already loaded, skip
        guard !isDataReady else {
            phase = .completed
            await updateVerseCount()
            return
        }

        phase = .loading(description: "Initializing...", progress: 0)

        do {
            // Database setup (includes bundled DB copy if available)
            try DatabaseManager.shared.setup()

            // Check if we now have data (from bundled DB)
            if try BibleRepository.shared.hasData() {
                await updateVerseCount()
                phase = .completed
                print("Data ready from bundled database")
                return
            }

            // No bundled data - fall back to sample import
            phase = .loading(description: "Loading sample data...", progress: 0.3)
            try await importSampleDataIfNeeded()

            await updateVerseCount()
            phase = .completed
            print("Data initialization complete")

        } catch {
            phase = .failed(error.localizedDescription)
            print("Data loading failed: \(error)")
        }
    }

    // MARK: - Sample Data Import (Fallback)

    /// Import sample data from bundle if no data exists
    private func importSampleDataIfNeeded() async throws {
        let repository = BibleRepository.shared

        // Check if we already have data
        guard try !repository.hasData() else { return }

        // Import sample verses
        phase = .loading(description: "Loading verses...", progress: 0.4)

        let versesImported = try repository.importVersesFromBundle(
            filename: "kjv_sample",
            translationId: "kjv"
        )

        phase = .loading(description: "Loading cross-references...", progress: 0.7)

        // Import sample cross-references if available
        do {
            let crossRefsImported = try await importCrossReferencesFromBundle()
            print("Imported \(crossRefsImported) cross-references")
        } catch {
            print("Cross-reference import skipped: \(error.localizedDescription)")
        }

        phase = .loading(description: "Loading topics...", progress: 0.9)

        // Import sample topics if available
        do {
            let topicsImported = try await importTopicsFromBundle()
            print("Imported \(topicsImported) topics")
        } catch {
            print("Topics import skipped: \(error.localizedDescription)")
        }

        print("Imported \(versesImported) sample verses")
    }

    // MARK: - Helper Import Methods

    private func importCrossReferencesFromBundle() async throws -> Int {
        guard let url = Bundle.main.url(forResource: "crossrefs_sample", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return 0
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        struct CrossRefImport: Codable {
            let sourceBookId: Int
            let sourceChapter: Int
            let sourceVerseStart: Int
            let sourceVerseEnd: Int
            let targetBookId: Int
            let targetChapter: Int
            let targetVerseStart: Int
            let targetVerseEnd: Int
            let weight: Double?
            let source: String?
        }

        let crossRefs = try decoder.decode([CrossRefImport].self, from: data)

        return try DatabaseManager.shared.write { db in
            var count = 0
            for ref in crossRefs {
                try db.execute(
                    sql: """
                        INSERT OR IGNORE INTO cross_references
                        (source_book_id, source_chapter, source_verse_start, source_verse_end,
                         target_book_id, target_chapter, target_verse_start, target_verse_end,
                         weight, source)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    arguments: [
                        ref.sourceBookId, ref.sourceChapter, ref.sourceVerseStart, ref.sourceVerseEnd,
                        ref.targetBookId, ref.targetChapter, ref.targetVerseStart, ref.targetVerseEnd,
                        ref.weight ?? 0.8, ref.source ?? "sample"
                    ]
                )
                count += 1
            }
            return count
        }
    }

    private func importTopicsFromBundle() async throws -> Int {
        guard let url = Bundle.main.url(forResource: "topics_sample", withExtension: "json"),
              let _ = try? Data(contentsOf: url) else {
            return 0
        }

        // Topics are handled by TopicService - just return 0 for now
        return 0
    }

    // MARK: - Verse Count

    private func updateVerseCount() async {
        do {
            verseCount = try DatabaseManager.shared.read { db in
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM verses") ?? 0
            }
        } catch {
            verseCount = 0
        }
    }

    // MARK: - Data Source Information

    /// Get all data sources for attribution display
    func getDataSources() async throws -> [DataSource] {
        try DatabaseManager.shared.read { db in
            try DataSource.fetchAll(db)
        }
    }
}

// MARK: - Data Source Model
/// Represents a data source for attribution
struct DataSource: Codable, FetchableRecord, PersistableRecord, Identifiable {
    static let databaseTableName = "data_sources"

    let id: String
    let name: String
    let version: String
    let sourceUrl: String?
    let license: String
    let licenseUrl: String?
    let attribution: String?
    let recordCount: Int?
    let importedAt: Date
    let checksum: String?

    enum CodingKeys: String, CodingKey {
        case id, name, version, license, attribution, checksum
        case sourceUrl = "source_url"
        case licenseUrl = "license_url"
        case recordCount = "record_count"
        case importedAt = "imported_at"
    }
}

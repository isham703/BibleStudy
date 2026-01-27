import Foundation
import GRDB

// MARK: - Database Store
// Foundational GRDB infrastructure for local SQLite database

final class DatabaseStore: @unchecked Sendable {
    // MARK: - Singleton
    static let shared = DatabaseStore()

    // MARK: - Bundled Database Configuration
    private enum BundledDatabase {
        static let name = "BibleData"
        static let fileExtension = "sqlite"
        static let versionKey = "bundledDatabaseVersion"
        static let currentVersion = 3  // Increment when bundled data is updated (v3: KJV only, schema fixes)
    }

    // MARK: - Properties
    private(set) var dbQueue: DatabaseQueue?

    /// Provides nonisolated access to dbQueue for background operations.
    /// DatabaseQueue is internally thread-safe, so this is safe to access from any context.
    /// Note: This is a stored property set during setup(), not a computed property accessing shared.
    nonisolated(unsafe) private(set) static var backgroundDBQueue: DatabaseQueue?

    /// Whether the app has bundled Bible data (set to true once pre-built DB is added)
    var hasBundledData: Bool {
        Bundle.main.url(forResource: BundledDatabase.name, withExtension: BundledDatabase.fileExtension) != nil
    }

    // MARK: - Initialization
    private init() {}

    // MARK: - Setup
    func setup() throws {
        let databaseURL = AppConfiguration.Database.path

        // Check if we need to copy bundled database
        if shouldCopyBundledDatabase(to: databaseURL) {
            try copyBundledDatabase(to: databaseURL)
        }

        // Create database queue
        var config = GRDB.Configuration()
        config.foreignKeysEnabled = true
        config.readonly = false

        #if DEBUG
        config.prepareDatabase { db in
            db.trace { print("SQL: \($0)") }
        }
        #endif

        dbQueue = try DatabaseQueue(path: databaseURL.path, configuration: config)
        DatabaseStore.backgroundDBQueue = dbQueue

        // Run migrations (for user data tables and any new migrations)
        try migrate()

        print("Database initialized at: \(databaseURL.path)")
    }

    // MARK: - Bundled Database Management

    /// Check if bundled database should be copied
    private func shouldCopyBundledDatabase(to destination: URL) -> Bool {
        // Only proceed if we have a bundled database
        guard hasBundledData else { return false }

        let fileManager = FileManager.default

        // If no database exists, definitely copy
        if !fileManager.fileExists(atPath: destination.path) {
            return true
        }

        // Check version - supports future data updates
        let storedVersion = UserDefaults.standard.integer(forKey: BundledDatabase.versionKey)
        return storedVersion < BundledDatabase.currentVersion
    }

    /// Copy bundled database to Documents directory
    private func copyBundledDatabase(to destination: URL) throws {
        guard let bundleURL = Bundle.main.url(
            forResource: BundledDatabase.name,
            withExtension: BundledDatabase.fileExtension
        ) else {
            throw DatabaseError.importFailed("Bundled database '\(BundledDatabase.name).\(BundledDatabase.fileExtension)' not found in app bundle")
        }

        let fileManager = FileManager.default

        // Ensure parent directory exists
        let parentDirectory = destination.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDirectory.path) {
            try fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
        }

        // Remove existing database if present (for version updates)
        if fileManager.fileExists(atPath: destination.path) {
            // Close any existing connection first
            dbQueue = nil
            try fileManager.removeItem(at: destination)
            print("Removed existing database for update")
        }

        // Copy from bundle
        try fileManager.copyItem(at: bundleURL, to: destination)

        // Mark all migrations as applied so GRDB doesn't try to re-run them
        // The bundled database was pre-built with the complete schema
        try markBundledMigrationsApplied(at: destination)

        // Store version
        UserDefaults.standard.set(BundledDatabase.currentVersion, forKey: BundledDatabase.versionKey)

        print("Bundled database copied from bundle (version \(BundledDatabase.currentVersion))")
    }

    /// Mark all migrations as applied in the bundled database
    /// This prevents the migrator from trying to re-create existing tables
    private func markBundledMigrationsApplied(at databaseURL: URL) throws {
        // All migration identifiers that the bundled database already has applied
        // Note: v17_stories is NOT included here because the bundled database
        // was created before the stories feature. The migration will run to
        // add the story tables to existing databases.
        let appliedMigrations = [
            "v1_verses",
            "v2_crossrefs",
            "v3_tokens",
            "v4_highlights_cache",
            "v5_notes_cache",
            "v6_ai_cache",
            "v7_translations",
            "v8_user_translation_prefs",
            "v9_memorization",
            "v10_note_templates",
            "v11_highlight_categories",
            "v12_note_links",
            "v13_study_collections",
            "v14_reading_sessions",
            "v15_fts5_search",
            "v16_data_sources"
            // v17_stories - intentionally excluded, migration will run
        ]

        // Open database directly to insert migration records
        let db = try DatabaseQueue(path: databaseURL.path)
        try db.write { database in
            // Create GRDB's migrations table if it doesn't exist
            try database.execute(sql: """
                CREATE TABLE IF NOT EXISTS grdb_migrations (
                    identifier TEXT NOT NULL PRIMARY KEY
                )
            """)

            // Insert all migration identifiers
            for migration in appliedMigrations {
                try database.execute(
                    sql: "INSERT OR IGNORE INTO grdb_migrations (identifier) VALUES (?)",
                    arguments: [migration]
                )
            }
        }

        print("Marked \(appliedMigrations.count) migrations as applied")
    }

    /// Verify database integrity after operations
    func verifyDatabaseIntegrity() throws -> Bool {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        return try dbQueue.read { db in
            // Run SQLite integrity check
            let result = try String.fetchOne(db, sql: "PRAGMA integrity_check")
            guard result == "ok" else {
                print("Database integrity check failed: \(result ?? "unknown")")
                return false
            }

            // Verify verses table exists and has data
            let tables = try String.fetchAll(db, sql: """
                SELECT name FROM sqlite_master WHERE type='table' ORDER BY name
            """)

            guard tables.contains("verses") else {
                print("Missing required table: verses")
                return false
            }

            return true
        }
    }

    /// Reset database to bundled state (for recovery or forced refresh)
    func resetToBundledDatabase() throws {
        let databaseURL = AppConfiguration.Database.path

        // Close current connection
        dbQueue = nil

        // Delete current database
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: databaseURL.path) {
            try fileManager.removeItem(at: databaseURL)
        }

        // Clear version marker to force re-copy
        UserDefaults.standard.removeObject(forKey: BundledDatabase.versionKey)

        // Re-initialize
        try setup()
    }

    // MARK: - Migrations
    private func migrate() throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }

        var migrator = DatabaseMigrator()

        // IMPORTANT: Do NOT use eraseDatabaseOnSchemaChange with bundled databases
        // The bundled BibleData.sqlite is pre-built with all migrations applied.
        // Setting eraseDatabaseOnSchemaChange = true would wipe all verse data.
        //
        // If you need to reset during development, use resetToBundledDatabase() instead.

        // Migration 1: Create verses table
        migrator.registerMigration("v1_verses") { db in
            try db.create(table: "verses", ifNotExists: true) { t in
                t.column("book_id", .integer).notNull()
                t.column("chapter", .integer).notNull()
                t.column("verse", .integer).notNull()
                t.column("text", .text).notNull()
                t.primaryKey(["book_id", "chapter", "verse"])
            }

            try db.create(index: "idx_verses_book_chapter", on: "verses", columns: ["book_id", "chapter"], ifNotExists: true)
        }

        // Migration 2: Create cross-references table
        migrator.registerMigration("v2_crossrefs") { db in
            try db.create(table: "cross_references", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("source_book_id", .integer).notNull()
                t.column("source_chapter", .integer).notNull()
                t.column("source_verse_start", .integer).notNull()
                t.column("source_verse_end", .integer).notNull()
                t.column("target_book_id", .integer).notNull()
                t.column("target_chapter", .integer).notNull()
                t.column("target_verse_start", .integer).notNull()
                t.column("target_verse_end", .integer).notNull()
                t.column("weight", .double).notNull().defaults(to: 1.0)
                t.column("source", .text)
            }

            try db.create(index: "idx_crossrefs_source", on: "cross_references",
                         columns: ["source_book_id", "source_chapter", "source_verse_start"],
                         ifNotExists: true)
            try db.create(index: "idx_crossrefs_target", on: "cross_references",
                         columns: ["target_book_id", "target_chapter", "target_verse_start"],
                         ifNotExists: true)
        }

        // Migration 3: Create language tokens table
        migrator.registerMigration("v3_tokens") { db in
            try db.create(table: "language_tokens", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("book_id", .integer).notNull()
                t.column("chapter", .integer).notNull()
                t.column("verse", .integer).notNull()
                t.column("position", .integer).notNull()
                t.column("surface", .text).notNull()
                t.column("lemma", .text)
                t.column("morph", .text)
                t.column("strong_id", .text)
                t.column("gloss", .text)
                t.column("language", .text).notNull() // "hebrew" or "greek"
            }

            try db.create(index: "idx_tokens_verse", on: "language_tokens",
                         columns: ["book_id", "chapter", "verse"],
                         ifNotExists: true)
            try db.create(index: "idx_tokens_lemma", on: "language_tokens",
                         columns: ["lemma"],
                         ifNotExists: true)
        }

        // Migration 4: Create local highlights cache
        migrator.registerMigration("v4_highlights_cache") { db in
            try db.create(table: "highlights_cache", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("user_id", .text).notNull()
                t.column("book_id", .integer).notNull()
                t.column("chapter", .integer).notNull()
                t.column("verse_start", .integer).notNull()
                t.column("verse_end", .integer).notNull()
                t.column("color", .text).notNull()
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
                t.column("deleted_at", .datetime)
                t.column("needs_sync", .boolean).notNull().defaults(to: false)
            }

            try db.create(index: "idx_highlights_verse", on: "highlights_cache",
                         columns: ["book_id", "chapter", "verse_start"],
                         ifNotExists: true)
            try db.create(index: "idx_highlights_user", on: "highlights_cache",
                         columns: ["user_id"],
                         ifNotExists: true)
        }

        // Migration 5: Create local notes cache
        migrator.registerMigration("v5_notes_cache") { db in
            try db.create(table: "notes_cache", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("user_id", .text).notNull()
                t.column("book_id", .integer).notNull()
                t.column("chapter", .integer).notNull()
                t.column("verse_start", .integer).notNull()
                t.column("verse_end", .integer).notNull()
                t.column("content", .text).notNull()
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
                t.column("deleted_at", .datetime)
                t.column("needs_sync", .boolean).notNull().defaults(to: false)
            }

            try db.create(index: "idx_notes_verse", on: "notes_cache",
                         columns: ["book_id", "chapter", "verse_start"],
                         ifNotExists: true)
            try db.create(index: "idx_notes_user", on: "notes_cache",
                         columns: ["user_id"],
                         ifNotExists: true)
        }

        // Migration 6: Create AI response cache
        migrator.registerMigration("v6_ai_cache") { db in
            try db.create(table: "ai_cache", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("cache_key", .text).notNull().unique()
                t.column("book_id", .integer).notNull()
                t.column("chapter", .integer).notNull()
                t.column("verse_start", .integer).notNull()
                t.column("verse_end", .integer).notNull()
                t.column("mode", .text).notNull()
                t.column("prompt_hash", .text).notNull()
                t.column("response", .text).notNull()
                t.column("model_used", .text)
                t.column("created_at", .datetime).notNull()
                t.column("expires_at", .datetime)
            }

            try db.create(index: "idx_ai_cache_key", on: "ai_cache",
                         columns: ["cache_key"],
                         ifNotExists: true)
            try db.create(index: "idx_ai_cache_verse", on: "ai_cache",
                         columns: ["book_id", "chapter", "verse_start"],
                         ifNotExists: true)
        }

        // Migration 7: Create translations table and update verses for multi-translation support
        migrator.registerMigration("v7_translations") { db in
            // Create translations table
            try db.create(table: "translations", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("abbreviation", .text).notNull()
                t.column("language", .text).notNull()
                t.column("description", .text).notNull()
                t.column("copyright", .text)
                t.column("is_default", .boolean).notNull().defaults(to: false)
                t.column("sort_order", .integer).notNull().defaults(to: 0)
            }

            // Create new verses table with translation support
            // Drop and recreate since we're changing the primary key
            try db.drop(table: "verses")

            try db.create(table: "verses") { t in
                t.column("translation_id", .text).notNull()
                    .references("translations", onDelete: .cascade)
                t.column("book_id", .integer).notNull()
                t.column("chapter", .integer).notNull()
                t.column("verse", .integer).notNull()
                t.column("text", .text).notNull()
                t.primaryKey(["translation_id", "book_id", "chapter", "verse"])
            }

            // Recreate indexes with translation support
            try db.create(index: "idx_verses_translation_book_chapter", on: "verses",
                         columns: ["translation_id", "book_id", "chapter"],
                         ifNotExists: true)
            try db.create(index: "idx_verses_text", on: "verses",
                         columns: ["text"],
                         ifNotExists: true)

            // Insert built-in translation metadata
            try db.execute(sql: """
                INSERT INTO translations (id, name, abbreviation, language, description, copyright, is_default, sort_order)
                VALUES
                ('kjv', 'King James Version', 'KJV', 'en', 'The classic 1611 English translation, beloved for its literary beauty and precision', 'Public Domain', 1, 1),
                ('esv', 'English Standard Version', 'ESV', 'en', 'A word-for-word translation balancing accuracy with readability', '© Crossway', 0, 2),
                ('nasb', 'New American Standard Bible', 'NASB', 'en', 'Highly literal translation favored for serious study', '© The Lockman Foundation', 0, 3),
                ('niv', 'New International Version', 'NIV', 'en', 'A thought-for-thought translation prioritizing clarity', '© Biblica', 0, 4)
                """)
        }

        // Migration 8: Create user translation preferences
        migrator.registerMigration("v8_user_translation_prefs") { db in
            try db.create(table: "user_translation_preferences", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("user_id", .text).notNull()
                t.column("primary_translation_id", .text).notNull()
                    .references("translations", onDelete: .setNull)
                t.column("secondary_translation_id", .text)
                    .references("translations", onDelete: .setNull)
                t.column("updated_at", .datetime).notNull()
                t.uniqueKey(["user_id"])
            }
        }

        // Migration 9: Create memorization items table (Phase 6)
        migrator.registerMigration("v9_memorization") { db in
            try db.create(table: "memorization_items", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("user_id", .text).notNull()
                t.column("book_id", .integer).notNull()
                t.column("chapter", .integer).notNull()
                t.column("verse_start", .integer).notNull()
                t.column("verse_end", .integer).notNull()
                t.column("verse_text", .text).notNull()
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()

                // SM-2 spaced repetition fields
                t.column("ease_factor", .double).notNull().defaults(to: 2.5)
                t.column("interval", .integer).notNull().defaults(to: 0)
                t.column("repetitions", .integer).notNull().defaults(to: 0)
                t.column("next_review_date", .datetime).notNull()
                t.column("last_review_date", .datetime)

                // Mastery tracking
                t.column("mastery_level", .text).notNull().defaults(to: "learning")
                t.column("total_reviews", .integer).notNull().defaults(to: 0)
                t.column("correct_reviews", .integer).notNull().defaults(to: 0)

                // Sync tracking
                t.column("needs_sync", .boolean).notNull().defaults(to: false)
                t.column("deleted_at", .datetime)
            }

            try db.create(index: "idx_memorization_user", on: "memorization_items",
                         columns: ["user_id"],
                         ifNotExists: true)
            try db.create(index: "idx_memorization_next_review", on: "memorization_items",
                         columns: ["user_id", "next_review_date"],
                         ifNotExists: true)
            try db.create(index: "idx_memorization_mastery", on: "memorization_items",
                         columns: ["user_id", "mastery_level"],
                         ifNotExists: true)
        }

        // Migration 10: Add template column to notes_cache (Phase 4)
        migrator.registerMigration("v10_note_templates") { db in
            try db.alter(table: "notes_cache") { t in
                t.add(column: "template", .text).defaults(to: "freeform")
            }
        }

        // Migration 11: Add category column to highlights_cache (Phase 4)
        migrator.registerMigration("v11_highlight_categories") { db in
            try db.alter(table: "highlights_cache") { t in
                t.add(column: "category", .text).defaults(to: "none")
            }

            try db.create(index: "idx_highlights_category", on: "highlights_cache",
                         columns: ["category"],
                         ifNotExists: true)
        }

        // Migration 12: Add linked_note_ids column to notes_cache (Phase 4 - Cross-note linking)
        migrator.registerMigration("v12_note_links") { db in
            try db.alter(table: "notes_cache") { t in
                t.add(column: "linked_note_ids", .text).defaults(to: "[]")
            }
        }

        // Migration 13: Create study_collections table (Phase 7 - Study Sessions & Organization)
        migrator.registerMigration("v13_study_collections") { db in
            try db.create(table: "study_collections", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("user_id", .text).notNull()
                t.column("name", .text).notNull()
                t.column("description", .text).defaults(to: "")
                t.column("type", .text).notNull().defaults(to: "personal")
                t.column("icon", .text).notNull()
                t.column("color", .text).notNull().defaults(to: "AccentGold")
                t.column("items", .text).notNull().defaults(to: "[]") // JSON array of CollectionItem
                t.column("is_pinned", .boolean).notNull().defaults(to: false)
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
                t.column("deleted_at", .datetime)
                t.column("needs_sync", .boolean).notNull().defaults(to: false)
            }

            try db.create(index: "idx_collections_user", on: "study_collections",
                         columns: ["user_id"],
                         ifNotExists: true)
            try db.create(index: "idx_collections_pinned", on: "study_collections",
                         columns: ["user_id", "is_pinned"],
                         ifNotExists: true)
            try db.create(index: "idx_collections_type", on: "study_collections",
                         columns: ["user_id", "type"],
                         ifNotExists: true)
        }

        // Migration 14: Create reading_sessions table (Phase 7 - Reading Analytics)
        migrator.registerMigration("v14_reading_sessions") { db in
            try db.create(table: "reading_sessions", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("user_id", .text).notNull()
                t.column("started_at", .datetime).notNull()
                t.column("ended_at", .datetime)
                t.column("book_id", .integer).notNull()
                t.column("chapter", .integer).notNull()
                t.column("verses_read", .text).notNull().defaults(to: "[]") // JSON array of verse numbers
                t.column("translation_id", .text).notNull().defaults(to: "kjv")
                t.column("duration_seconds", .integer).notNull().defaults(to: 0)
            }

            try db.create(index: "idx_sessions_user", on: "reading_sessions",
                         columns: ["user_id"],
                         ifNotExists: true)
            try db.create(index: "idx_sessions_date", on: "reading_sessions",
                         columns: ["user_id", "started_at"],
                         ifNotExists: true)
            try db.create(index: "idx_sessions_book", on: "reading_sessions",
                         columns: ["user_id", "book_id"],
                         ifNotExists: true)
        }

        // Migration 15: Create FTS5 full-text search index for verses
        migrator.registerMigration("v15_fts5_search") { db in
            // Verify rowid is available (throws if WITHOUT ROWID table)
            _ = try Row.fetchOne(db, sql: "SELECT rowid FROM verses LIMIT 1")

            // Create FTS5 virtual table using external content mode
            // This indexes text only, joins back to verses for full data
            try db.execute(sql: """
                CREATE VIRTUAL TABLE IF NOT EXISTS verses_fts USING fts5(
                    text,
                    content='verses',
                    content_rowid='rowid',
                    tokenize='porter unicode61'
                )
                """)

            // Trigger: sync FTS on INSERT
            try db.execute(sql: """
                CREATE TRIGGER IF NOT EXISTS verses_fts_ai AFTER INSERT ON verses BEGIN
                    INSERT INTO verses_fts(rowid, text) VALUES (new.rowid, new.text);
                END
                """)

            // Trigger: sync FTS on DELETE
            try db.execute(sql: """
                CREATE TRIGGER IF NOT EXISTS verses_fts_ad AFTER DELETE ON verses BEGIN
                    INSERT INTO verses_fts(verses_fts, rowid, text) VALUES('delete', old.rowid, old.text);
                END
                """)

            // Trigger: sync FTS on UPDATE
            try db.execute(sql: """
                CREATE TRIGGER IF NOT EXISTS verses_fts_au AFTER UPDATE ON verses BEGIN
                    INSERT INTO verses_fts(verses_fts, rowid, text) VALUES('delete', old.rowid, old.text);
                    INSERT INTO verses_fts(rowid, text) VALUES (new.rowid, new.text);
                END
                """)

            // Rebuild index from existing verse data
            try db.execute(sql: "INSERT INTO verses_fts(verses_fts) VALUES('rebuild')")
        }

        // Migration 16: Create data_sources table for version tracking and attribution
        migrator.registerMigration("v16_data_sources") { db in
            try db.create(table: "data_sources", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()      // e.g., "kjv_verses", "openbible_crossrefs"
                t.column("name", .text).notNull()       // Display name
                t.column("version", .text).notNull()    // Semantic version
                t.column("source_url", .text)           // Original source URL
                t.column("license", .text).notNull()    // License type (e.g., "Public Domain", "CC BY 4.0")
                t.column("license_url", .text)          // Link to full license
                t.column("attribution", .text)          // Required attribution text
                t.column("record_count", .integer)      // Number of records from this source
                t.column("imported_at", .datetime).notNull()
                t.column("checksum", .text)             // SHA256 of source data for integrity
            }

            // Insert initial data source for KJV (will be populated when bundled data is added)
            try db.execute(sql: """
                INSERT OR IGNORE INTO data_sources (id, name, version, license, attribution, imported_at)
                VALUES ('kjv_verses', 'King James Version', '1.0.0', 'Public Domain',
                        'King James Version (1769 Cambridge Edition)', datetime('now'))
            """)
        }

        // Migration 17: Create user_progress table (Gamification - Streaks, XP, Achievements)
        migrator.registerMigration("v17_user_progress") { db in
            try db.create(table: "user_progress", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("user_id", .text).notNull().unique()

                // Streak tracking
                t.column("current_streak", .integer).notNull().defaults(to: 0)
                t.column("longest_streak", .integer).notNull().defaults(to: 0)
                t.column("last_active_date", .datetime)

                // Grace Day system
                t.column("grace_days_remaining", .integer).notNull().defaults(to: 1)
                t.column("grace_day_used_this_streak", .boolean).notNull().defaults(to: false)
                t.column("last_grace_day_refresh", .datetime)

                // XP and leveling
                t.column("total_xp", .integer).notNull().defaults(to: 0)
                t.column("level", .text).notNull().defaults(to: "novice")

                // Achievements (stored as JSON array)
                t.column("achievements_unlocked", .text).notNull().defaults(to: "[]")

                // Daily activity tracking
                t.column("daily_reading_minutes", .integer).notNull().defaults(to: 0)
                t.column("daily_goal_minutes", .integer).notNull().defaults(to: 10)
                t.column("chapters_read_today", .integer).notNull().defaults(to: 0)
                t.column("verses_reviewed_today", .integer).notNull().defaults(to: 0)

                // Timestamps
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
            }

            try db.create(index: "idx_user_progress_user", on: "user_progress",
                         columns: ["user_id"],
                         ifNotExists: true)
            try db.create(index: "idx_user_progress_streak", on: "user_progress",
                         columns: ["current_streak"],
                         ifNotExists: true)
        }

        // Migration 18: Create stories tables (Narrative Cards feature)
        migrator.registerMigration("v18_stories") { db in
            // Stories table - main story metadata
            try db.create(table: "stories", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("slug", .text).notNull().unique()
                t.column("title", .text).notNull()
                t.column("subtitle", .text)
                t.column("description", .text).notNull()
                t.column("type", .text).notNull()
                t.column("reading_level", .text).notNull()
                t.column("is_prebuilt", .boolean).notNull().defaults(to: false)
                t.column("verse_anchors", .text).notNull() // JSON array of VerseRange
                t.column("estimated_minutes", .integer).notNull()
                t.column("user_id", .text)
                t.column("is_public", .boolean).notNull().defaults(to: false)
                t.column("generation_mode", .text).notNull().defaults(to: "prebuilt")
                t.column("model_id", .text)
                t.column("prompt_version", .integer).notNull().defaults(to: 1)
                t.column("schema_version", .integer).notNull().defaults(to: 1)
                t.column("generated_at", .datetime)
                t.column("source_passage_ids", .text).notNull().defaults(to: "[]")
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
            }

            try db.create(index: "idx_stories_type", on: "stories",
                         columns: ["type"],
                         ifNotExists: true)
            try db.create(index: "idx_stories_level", on: "stories",
                         columns: ["reading_level"],
                         ifNotExists: true)
            try db.create(index: "idx_stories_user", on: "stories",
                         columns: ["user_id"],
                         ifNotExists: true)
            try db.create(index: "idx_stories_prebuilt", on: "stories",
                         columns: ["is_prebuilt"],
                         ifNotExists: true)

            // Story segments table - individual scenes/segments
            try db.create(table: "story_segments", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("story_id", .text).notNull()
                    .references("stories", onDelete: .cascade)
                t.column("order_index", .integer).notNull()
                t.column("title", .text).notNull()
                t.column("content", .text).notNull()
                t.column("verse_anchor", .text) // JSON VerseRange
                t.column("timeline_label", .text)
                t.column("location", .text)
                t.column("key_characters", .text) // JSON array of UUIDs
                t.column("mood", .text)
                t.column("reflection_question", .text)
                t.column("key_term", .text) // JSON KeyTermHighlight
            }

            try db.create(index: "idx_segments_story", on: "story_segments",
                         columns: ["story_id"],
                         ifNotExists: true)
            try db.create(index: "idx_segments_order", on: "story_segments",
                         columns: ["story_id", "order_index"],
                         ifNotExists: true)

            // Story characters table
            try db.create(table: "story_characters", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("title", .text)
                t.column("description", .text).notNull()
                t.column("role", .text).notNull()
                t.column("first_appearance", .text) // JSON VerseRange
                t.column("key_verses", .text) // JSON array of VerseRange
                t.column("icon_name", .text)
            }

            try db.create(index: "idx_characters_name", on: "story_characters",
                         columns: ["name"],
                         ifNotExists: true)

            // Story progress table - user reading progress
            try db.create(table: "story_progress", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("user_id", .text).notNull()
                t.column("story_id", .text).notNull()
                    .references("stories", onDelete: .cascade)
                t.column("current_segment_index", .integer).notNull().defaults(to: 0)
                t.column("completed_segment_ids", .text).notNull().defaults(to: "[]")
                t.column("started_at", .datetime).notNull()
                t.column("last_read_at", .datetime).notNull()
                t.column("completed_at", .datetime)
                t.column("reflection_notes", .text).notNull().defaults(to: "{}")
                t.column("needs_sync", .boolean).notNull().defaults(to: false)
                t.uniqueKey(["user_id", "story_id"])
            }

            try db.create(index: "idx_progress_user", on: "story_progress",
                         columns: ["user_id"],
                         ifNotExists: true)
            try db.create(index: "idx_progress_last_read", on: "story_progress",
                         columns: ["user_id", "last_read_at"],
                         ifNotExists: true)
        }

        // Migration 19: Create achievements table
        migrator.registerMigration("v19_achievements") { db in
            try db.create(table: "achievements", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("unlocked_at", .datetime).notNull()
            }
        }

        // Migration 20: Create saved_prayers table (Prayers from the Deep feature)
        migrator.registerMigration("v20_saved_prayers") { db in
            try db.create(table: "saved_prayers", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("user_id", .text).notNull()
                t.column("tradition", .text).notNull()
                t.column("content", .text).notNull()
                t.column("amen", .text).notNull()
                t.column("user_context", .text).notNull()
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
                t.column("deleted_at", .datetime)
                t.column("needs_sync", .boolean).notNull().defaults(to: false)
            }

            try db.create(index: "idx_saved_prayers_user", on: "saved_prayers",
                         columns: ["user_id"],
                         ifNotExists: true)
            try db.create(index: "idx_saved_prayers_tradition", on: "saved_prayers",
                         columns: ["user_id", "tradition"],
                         ifNotExists: true)
            try db.create(index: "idx_saved_prayers_created", on: "saved_prayers",
                         columns: ["user_id", "created_at"],
                         ifNotExists: true)
        }

        // Migration 21: Create sermon tables (Sermon Recording feature)
        migrator.registerMigration("v21_sermons") { db in
            // Sermons table (metadata + job tracking)
            try db.create(table: "sermons", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("user_id", .text).notNull()
                t.column("title", .text).notNull()
                t.column("speaker_name", .text)
                t.column("recorded_at", .datetime).notNull()
                t.column("duration_seconds", .integer).notNull().defaults(to: 0)

                // Audio metadata
                t.column("local_audio_path", .text)
                t.column("remote_audio_path", .text)
                t.column("audio_file_size", .integer)
                t.column("audio_mime_type", .text)
                t.column("audio_codec", .text)
                t.column("audio_bitrate_kbps", .integer)
                t.column("audio_content_hash", .text)

                // Processing status (job tracking)
                t.column("transcription_status", .text).notNull().defaults(to: "pending")
                t.column("transcription_error", .text)
                t.column("study_guide_status", .text).notNull().defaults(to: "pending")
                t.column("study_guide_error", .text)
                t.column("processing_version", .text).notNull().defaults(to: "1")

                t.column("scripture_references", .text).defaults(to: "[]")

                // Sync tracking
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
                t.column("deleted_at", .datetime)
                t.column("needs_sync", .boolean).notNull().defaults(to: false)
                t.column("audio_needs_upload", .boolean).notNull().defaults(to: false)
            }

            try db.create(index: "idx_sermons_user", on: "sermons",
                         columns: ["user_id"],
                         ifNotExists: true)
            try db.create(index: "idx_sermons_recorded", on: "sermons",
                         columns: ["user_id", "recorded_at"],
                         ifNotExists: true)
            try db.create(index: "idx_sermons_transcription", on: "sermons",
                         columns: ["transcription_status"],
                         ifNotExists: true)
            try db.create(index: "idx_sermons_study_guide", on: "sermons",
                         columns: ["study_guide_status"],
                         ifNotExists: true)

            // Audio chunks table (for chunked recording/playback)
            try db.create(table: "sermon_audio_chunks", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("sermon_id", .text).notNull()
                    .references("sermons", onDelete: .cascade)
                t.column("chunk_index", .integer).notNull()
                t.column("start_offset_seconds", .double).notNull()
                t.column("duration_seconds", .double).notNull()

                // Local/remote paths
                t.column("local_path", .text)
                t.column("remote_path", .text)

                // File metadata
                t.column("file_size", .integer)
                t.column("content_hash", .text)

                // Upload tracking
                t.column("upload_status", .text).notNull().defaults(to: "pending")
                t.column("upload_error", .text)
                t.column("upload_progress", .double).defaults(to: 0)

                // Transcription tracking (per-chunk)
                t.column("transcription_status", .text).notNull().defaults(to: "pending")
                t.column("transcription_error", .text)
                t.column("transcript_segment", .text)

                // Waveform data (downsampled for UI)
                t.column("waveform_samples", .text)

                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
                t.column("needs_sync", .boolean).notNull().defaults(to: false)

                t.uniqueKey(["sermon_id", "chunk_index"])
            }

            try db.create(index: "idx_sermon_chunks_sermon", on: "sermon_audio_chunks",
                         columns: ["sermon_id"],
                         ifNotExists: true)
            try db.create(index: "idx_sermon_chunks_upload", on: "sermon_audio_chunks",
                         columns: ["upload_status"],
                         ifNotExists: true)
            try db.create(index: "idx_sermon_chunks_transcription", on: "sermon_audio_chunks",
                         columns: ["transcription_status"],
                         ifNotExists: true)

            // Transcripts table
            try db.create(table: "sermon_transcripts", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("sermon_id", .text).notNull()
                    .references("sermons", onDelete: .cascade)
                t.column("content", .text).notNull()
                t.column("language", .text).notNull().defaults(to: "en")
                t.column("word_timestamps", .text).defaults(to: "[]")
                t.column("model_used", .text)
                t.column("confidence_score", .double)
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
                t.column("needs_sync", .boolean).notNull().defaults(to: false)
            }

            try db.create(index: "idx_sermon_transcripts_sermon", on: "sermon_transcripts",
                         columns: ["sermon_id"],
                         ifNotExists: true)

            // FTS5 for transcript full-text search
            try db.execute(sql: """
                CREATE VIRTUAL TABLE IF NOT EXISTS sermon_transcripts_fts USING fts5(
                    sermon_id UNINDEXED,
                    content,
                    tokenize='porter unicode61'
                )
            """)

            // FTS triggers for sermon_transcripts
            try db.execute(sql: """
                CREATE TRIGGER IF NOT EXISTS sermon_transcripts_ai AFTER INSERT ON sermon_transcripts BEGIN
                    INSERT INTO sermon_transcripts_fts(rowid, sermon_id, content)
                    VALUES (new.rowid, new.sermon_id, new.content);
                END
            """)

            try db.execute(sql: """
                CREATE TRIGGER IF NOT EXISTS sermon_transcripts_ad AFTER DELETE ON sermon_transcripts BEGIN
                    INSERT INTO sermon_transcripts_fts(sermon_transcripts_fts, rowid, sermon_id, content)
                    VALUES ('delete', old.rowid, old.sermon_id, old.content);
                END
            """)

            try db.execute(sql: """
                CREATE TRIGGER IF NOT EXISTS sermon_transcripts_au AFTER UPDATE ON sermon_transcripts BEGIN
                    INSERT INTO sermon_transcripts_fts(sermon_transcripts_fts, rowid, sermon_id, content)
                    VALUES ('delete', old.rowid, old.sermon_id, old.content);
                    INSERT INTO sermon_transcripts_fts(rowid, sermon_id, content)
                    VALUES (new.rowid, new.sermon_id, new.content);
                END
            """)

            // Study guides table
            try db.create(table: "sermon_study_guides", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("sermon_id", .text).notNull()
                    .references("sermons", onDelete: .cascade)
                t.column("content", .text).notNull()
                t.column("model_used", .text)
                t.column("prompt_version", .text).notNull().defaults(to: "1")
                t.column("transcript_hash", .text)
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
                t.column("needs_sync", .boolean).notNull().defaults(to: false)
            }

            try db.create(index: "idx_sermon_study_guides_sermon", on: "sermon_study_guides",
                         columns: ["sermon_id"],
                         ifNotExists: true)

            // Bookmarks table (user annotations at timestamps)
            try db.create(table: "sermon_bookmarks", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("user_id", .text).notNull()
                t.column("sermon_id", .text).notNull()
                    .references("sermons", onDelete: .cascade)
                t.column("timestamp_seconds", .double).notNull()
                t.column("note", .text)
                t.column("label", .text)
                t.column("verse_reference", .text)
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
                t.column("deleted_at", .datetime)
                t.column("needs_sync", .boolean).notNull().defaults(to: false)
            }

            try db.create(index: "idx_sermon_bookmarks_sermon", on: "sermon_bookmarks",
                         columns: ["sermon_id"],
                         ifNotExists: true)
            try db.create(index: "idx_sermon_bookmarks_user", on: "sermon_bookmarks",
                         columns: ["user_id"],
                         ifNotExists: true)
        }

        // MARK: - v22: Sermon Pagination Index
        // Composite index for optimized cursor-based pagination queries:
        // WHERE user_id = ? AND deleted_at IS NULL ORDER BY recorded_at DESC, id DESC
        migrator.registerMigration("v22_sermon_pagination_index") { db in
            try db.create(
                index: "idx_sermons_pagination",
                on: "sermons",
                columns: ["user_id", "deleted_at", "recorded_at", "id"],
                ifNotExists: true
            )
        }

        // MARK: - v23: Prayer Sync Tracking
        // Add sync tracking and pagination support to saved_prayers
        migrator.registerMigration("v23_prayer_sync_tracking") { db in
            // Check existing columns to avoid duplicate column errors
            let existingColumns = try db.columns(in: "saved_prayers").map { $0.name }

            // Add sync tracking columns only if they don't exist
            if !existingColumns.contains("last_synced_at") {
                try db.alter(table: "saved_prayers") { t in
                    t.add(column: "last_synced_at", .datetime)
                }
            }
            if !existingColumns.contains("sync_retry_count") {
                try db.alter(table: "saved_prayers") { t in
                    t.add(column: "sync_retry_count", .integer).defaults(to: 0)
                }
            }
            if !existingColumns.contains("sync_error") {
                try db.alter(table: "saved_prayers") { t in
                    t.add(column: "sync_error", .text)
                }
            }

            // Composite index for efficient sync queue queries
            try db.create(index: "idx_saved_prayers_sync_queue", on: "saved_prayers",
                         columns: ["user_id", "needs_sync"],
                         ifNotExists: true)

            // Index for pagination by created_at (keyset pagination)
            try db.create(index: "idx_saved_prayers_pagination", on: "saved_prayers",
                         columns: ["user_id", "created_at", "id"],
                         ifNotExists: true)
        }

        // MARK: - v24: Prayer FTS5 Full-Text Search
        // Enable fast full-text search on prayer content and user context
        migrator.registerMigration("v24_prayer_fts5") { db in
            // Create FTS5 virtual table for prayer search
            // Indexes content and user_context for comprehensive search
            try db.execute(sql: """
                CREATE VIRTUAL TABLE IF NOT EXISTS saved_prayers_fts USING fts5(
                    content,
                    user_context,
                    content='saved_prayers',
                    content_rowid='rowid',
                    tokenize='porter unicode61'
                )
                """)

            // Trigger: sync FTS on INSERT
            try db.execute(sql: """
                CREATE TRIGGER IF NOT EXISTS saved_prayers_fts_ai AFTER INSERT ON saved_prayers BEGIN
                    INSERT INTO saved_prayers_fts(rowid, content, user_context)
                    VALUES (new.rowid, new.content, new.user_context);
                END
                """)

            // Trigger: sync FTS on DELETE
            try db.execute(sql: """
                CREATE TRIGGER IF NOT EXISTS saved_prayers_fts_ad AFTER DELETE ON saved_prayers BEGIN
                    INSERT INTO saved_prayers_fts(saved_prayers_fts, rowid, content, user_context)
                    VALUES('delete', old.rowid, old.content, old.user_context);
                END
                """)

            // Trigger: sync FTS on UPDATE
            try db.execute(sql: """
                CREATE TRIGGER IF NOT EXISTS saved_prayers_fts_au AFTER UPDATE ON saved_prayers BEGIN
                    INSERT INTO saved_prayers_fts(saved_prayers_fts, rowid, content, user_context)
                    VALUES('delete', old.rowid, old.content, old.user_context);
                    INSERT INTO saved_prayers_fts(rowid, content, user_context)
                    VALUES (new.rowid, new.content, new.user_context);
                END
                """)

            // Rebuild index from existing prayer data
            try db.execute(sql: "INSERT INTO saved_prayers_fts(saved_prayers_fts) VALUES('rebuild')")
        }

        // MARK: - v25: Repair Sermon Transcripts FTS5 Index
        // Fixes corrupted FTS5 index by recreating with proper external content mode
        migrator.registerMigration("v25_repair_sermon_fts") { db in
            // Drop existing (corrupted) FTS triggers first
            try db.execute(sql: "DROP TRIGGER IF EXISTS sermon_transcripts_ai")
            try db.execute(sql: "DROP TRIGGER IF EXISTS sermon_transcripts_ad")
            try db.execute(sql: "DROP TRIGGER IF EXISTS sermon_transcripts_au")

            // Drop existing (corrupted) FTS table
            try db.execute(sql: "DROP TABLE IF EXISTS sermon_transcripts_fts")

            // Recreate FTS5 with proper external content mode (matches verses_fts pattern)
            // This links to sermon_transcripts table via rowid for better reliability
            try db.execute(sql: """
                CREATE VIRTUAL TABLE IF NOT EXISTS sermon_transcripts_fts USING fts5(
                    sermon_id UNINDEXED,
                    content,
                    content='sermon_transcripts',
                    content_rowid='rowid',
                    tokenize='porter unicode61'
                )
            """)

            // Trigger: sync FTS on INSERT
            try db.execute(sql: """
                CREATE TRIGGER IF NOT EXISTS sermon_transcripts_ai AFTER INSERT ON sermon_transcripts BEGIN
                    INSERT INTO sermon_transcripts_fts(rowid, sermon_id, content)
                    VALUES (new.rowid, new.sermon_id, new.content);
                END
            """)

            // Trigger: sync FTS on DELETE
            try db.execute(sql: """
                CREATE TRIGGER IF NOT EXISTS sermon_transcripts_ad AFTER DELETE ON sermon_transcripts BEGIN
                    INSERT INTO sermon_transcripts_fts(sermon_transcripts_fts, rowid, sermon_id, content)
                    VALUES ('delete', old.rowid, old.sermon_id, old.content);
                END
            """)

            // Trigger: sync FTS on UPDATE
            try db.execute(sql: """
                CREATE TRIGGER IF NOT EXISTS sermon_transcripts_au AFTER UPDATE ON sermon_transcripts BEGIN
                    INSERT INTO sermon_transcripts_fts(sermon_transcripts_fts, rowid, sermon_id, content)
                    VALUES ('delete', old.rowid, old.sermon_id, old.content);
                    INSERT INTO sermon_transcripts_fts(rowid, sermon_id, content)
                    VALUES (new.rowid, new.sermon_id, new.content);
                END
            """)

            // Rebuild index from existing transcript data
            try db.execute(sql: "INSERT INTO sermon_transcripts_fts(sermon_transcripts_fts) VALUES('rebuild')")
        }

        // MARK: - v26: Supabase Insights Cache
        // Local cache for Supabase insights to enable offline access
        migrator.registerMigration("v26_insights_cache") { db in
            // Cache for bible_insights from Supabase
            try db.create(table: "insights_cache", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("book_id", .integer).notNull()
                t.column("chapter", .integer).notNull()
                t.column("verse_start", .integer).notNull()
                t.column("verse_end", .integer).notNull()
                t.column("insight_type", .text).notNull()
                t.column("title", .text).notNull()
                t.column("content", .text).notNull()
                t.column("data", .blob).notNull()  // Full JSON-encoded insight
                t.column("fetched_at", .datetime).notNull()
            }

            try db.create(index: "idx_insights_cache_chapter", on: "insights_cache",
                         columns: ["book_id", "chapter"],
                         ifNotExists: true)
            try db.create(index: "idx_insights_cache_verse", on: "insights_cache",
                         columns: ["book_id", "chapter", "verse_start"],
                         ifNotExists: true)

            // Cache for crossref_explanations from Supabase
            try db.create(table: "crossrefs_cache", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("source_book_id", .integer).notNull()
                t.column("source_chapter", .integer).notNull()
                t.column("source_verse", .integer).notNull()
                t.column("target_book_id", .integer).notNull()
                t.column("target_chapter", .integer).notNull()
                t.column("data", .blob).notNull()  // Full JSON-encoded crossref
                t.column("fetched_at", .datetime).notNull()
            }

            try db.create(index: "idx_crossrefs_cache_source", on: "crossrefs_cache",
                         columns: ["source_book_id", "source_chapter", "source_verse"],
                         ifNotExists: true)

            // Version tracking for cache invalidation
            try db.create(table: "content_cache_version", ifNotExists: true) { t in
                t.column("id", .integer).primaryKey()
                t.column("insights_version", .integer).notNull().defaults(to: 0)
                t.column("crossrefs_version", .integer).notNull().defaults(to: 0)
                t.column("updated_at", .datetime).notNull()
            }

            // Insert initial version row
            try db.execute(sql: """
                INSERT INTO content_cache_version (id, insights_version, crossrefs_version, updated_at)
                VALUES (1, 0, 0, datetime('now'))
            """)
        }

        // MARK: - v27: Sermon Index Cache
        // Lightweight index for fast sermon grouping (<100ms for 500+ sermons)
        migrator.registerMigration("v27_sermon_index") { db in
            try db.create(table: "sermon_index", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("speaker_name", .text)
                t.column("parsed_books", .text).notNull().defaults(to: "[]")
                t.column("recorded_at", .datetime).notNull()
                t.column("duration_seconds", .integer).notNull().defaults(to: 0)
                t.column("display_title", .text).notNull()
                t.column("indexed_at", .datetime).notNull()
                t.column("sermon_updated_at", .datetime).notNull()
            }

            try db.create(index: "idx_sermon_index_speaker", on: "sermon_index",
                         columns: ["speaker_name"],
                         ifNotExists: true)
            try db.create(index: "idx_sermon_index_recorded", on: "sermon_index",
                         columns: ["recorded_at"],
                         ifNotExists: true)
        }

        // MARK: - v28: Sermon Themes
        // Normalized theme assignments for theme-based grouping
        migrator.registerMigration("v28_sermon_themes") { db in
            try db.create(table: "sermon_themes", ifNotExists: true) { t in
                t.column("sermon_id", .text).notNull()
                    .references("sermons", onDelete: .cascade)
                t.column("theme", .text).notNull()
                t.column("confidence", .double).notNull().defaults(to: 0.0)
                t.column("override_state", .text).notNull().defaults(to: "auto")
                t.column("source_themes", .text)
                t.column("match_type", .text).notNull().defaults(to: "exact")
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
                t.primaryKey(["sermon_id", "theme"])
            }

            try db.create(index: "idx_sermon_themes_sermon", on: "sermon_themes",
                         columns: ["sermon_id"],
                         ifNotExists: true)
            try db.create(index: "idx_sermon_themes_theme", on: "sermon_themes",
                         columns: ["theme"],
                         ifNotExists: true)
            try db.create(index: "idx_sermon_themes_override", on: "sermon_themes",
                         columns: ["override_state"],
                         ifNotExists: true)
        }

        // MARK: - v29: Repair Sermon Status
        // Fixes sermon status columns based on actual transcript/study guide data presence
        migrator.registerMigration("v29_repair_sermon_status") { db in
            // Update transcription_status to 'succeeded' for sermons that have transcript data
            try db.execute(sql: """
                UPDATE sermons
                SET transcription_status = 'succeeded',
                    updated_at = datetime('now')
                WHERE id IN (SELECT DISTINCT sermon_id FROM sermon_transcripts)
                  AND transcription_status != 'succeeded'
                """)

            // Update study_guide_status to 'succeeded' for sermons that have study guide data
            try db.execute(sql: """
                UPDATE sermons
                SET study_guide_status = 'succeeded',
                    updated_at = datetime('now')
                WHERE id IN (SELECT DISTINCT sermon_id FROM sermon_study_guides)
                  AND study_guide_status != 'succeeded'
                """)

            let repairedCount = db.changesCount
            print("[Migration v29] Repaired \(repairedCount) sermon status records")
        }

        // MARK: - v30: Sermon Engagements
        // User engagement tracking: application commits, favorites, journal entries
        migrator.registerMigration("v30_sermon_engagements") { db in
            try db.create(table: "sermon_engagements", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("user_id", .text).notNull()
                t.column("sermon_id", .text).notNull()
                    .references("sermons", onDelete: .cascade)
                t.column("engagement_type", .text).notNull()
                t.column("target_id", .text).notNull()
                t.column("content", .text)
                t.column("metadata", .text)
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
                t.column("deleted_at", .datetime)
                t.column("needs_sync", .boolean).notNull().defaults(to: false)
            }

            // Composite index for fast lookups (not unique — toggle via UPDATE)
            try db.create(
                index: "idx_sermon_engagements_lookup",
                on: "sermon_engagements",
                columns: ["sermon_id", "engagement_type", "target_id"],
                ifNotExists: true
            )

            try db.create(
                index: "idx_sermon_engagements_user",
                on: "sermon_engagements",
                columns: ["user_id"],
                ifNotExists: true
            )

            print("[Migration v30] Created sermon_engagements table")
        }

        // MARK: - v31: Sermon Transcript Correction Overlays
        // Adds correction_overlays column for biblical term corrections
        migrator.registerMigration("v31_transcript_corrections") { db in
            try db.alter(table: "sermon_transcripts") { t in
                t.add(column: "correction_overlays", .text).defaults(to: "[]")
            }
            print("[Migration v31] Added correction_overlays column to sermon_transcripts")
        }

        try migrator.migrate(dbQueue)
    }

    // MARK: - Database Access
    func read<T>(_ block: (Database) throws -> T) throws -> T {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        return try dbQueue.read(block)
    }

    func write<T>(_ block: (Database) throws -> T) throws -> T {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        return try dbQueue.write(block)
    }

    // MARK: - Utility
    func deleteDatabase() throws {
        let fileManager = FileManager.default
        let databaseURL = AppConfiguration.Database.path

        if fileManager.fileExists(atPath: databaseURL.path) {
            try fileManager.removeItem(at: databaseURL)
        }

        dbQueue = nil
    }
}

// MARK: - Database Errors
enum DatabaseError: Error, LocalizedError {
    case notInitialized
    case migrationFailed(String)
    case importFailed(String)

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Database has not been initialized"
        case .migrationFailed(let message):
            return "Migration failed: \(message)"
        case .importFailed(let message):
            return "Import failed: \(message)"
        }
    }
}

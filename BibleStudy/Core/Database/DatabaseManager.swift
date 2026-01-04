import Foundation
import GRDB

// MARK: - Database Manager
// Manages the local SQLite database using GRDB

final class DatabaseManager: @unchecked Sendable {
    // MARK: - Singleton
    static let shared = DatabaseManager()

    // MARK: - Bundled Database Configuration
    private enum BundledDatabase {
        static let name = "BibleData"
        static let fileExtension = "sqlite"
        static let versionKey = "bundledDatabaseVersion"
        static let currentVersion = 3  // Increment when bundled data is updated (v3: KJV only, schema fixes)
    }

    // MARK: - Properties
    private(set) var dbQueue: DatabaseQueue?

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

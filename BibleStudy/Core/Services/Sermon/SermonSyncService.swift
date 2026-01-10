import Foundation
import Auth
import Supabase
@preconcurrency import GRDB

// MARK: - Sermon Sync Service
// Manages sermon data and audio sync with offline-first architecture

@MainActor
@Observable
final class SermonSyncService {
    // MARK: - Singleton
    static let shared = SermonSyncService()

    // MARK: - Dependencies
    private let supabase = SupabaseManager.shared
    private let repository = SermonRepository.shared

    // MARK: - State
    var sermons: [Sermon] = []
    var isLoading: Bool = false
    var isSyncing: Bool = false
    var error: Error?

    // Audio cache management
    private let audioCacheDirectory: URL
    private let maxCacheSize: Int64 = 2 * 1024 * 1024 * 1024 // 2 GB

    // MARK: - Initialization

    private init() {
        // Setup audio cache directory
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        audioCacheDirectory = cacheDir.appendingPathComponent("SermonAudio", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(
            at: audioCacheDirectory,
            withIntermediateDirectories: true
        )
    }

    // MARK: - Load Sermons

    /// Load all sermons for current user
    func loadSermons() async {
        guard let userId = supabase.currentUser?.id else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // Load from local cache first (via repository)
            sermons = try repository.fetchAllSermons(userId: userId, includeDeleted: false)

            // Then sync with remote
            try await syncWithRemote()
        } catch {
            self.error = error
            print("[SermonSyncService] Error loading sermons: \(error)")
        }
    }

    /// Load a specific sermon by ID
    func loadSermon(id: UUID) async -> Sermon? {
        do {
            // Try local first (via repository)
            if let sermon = try repository.fetchSermon(id: id) {
                return sermon
            }

            // Fetch from remote
            return try await fetchSermonFromRemote(id: id)
        } catch {
            self.error = error
            return nil
        }
    }

    // MARK: - Create Sermon

    /// Create a new sermon with audio chunks
    func createSermon(_ sermon: Sermon, chunks: [SermonAudioChunk]) async throws {
        // Save locally first (via repository)
        try repository.saveSermon(sermon)
        for chunk in chunks {
            try repository.saveChunk(chunk)
        }

        // Add to local list
        sermons.insert(sermon, at: 0)

        // Queue for sync
        try await syncSermon(sermon)
    }

    /// Update an existing sermon
    func updateSermon(_ sermon: Sermon) async throws {
        var updated = sermon
        updated.updatedAt = Date()
        updated.needsSync = true

        try repository.updateSermon(updated)

        // Update local list
        if let index = sermons.firstIndex(where: { $0.id == sermon.id }) {
            sermons[index] = updated
        }

        // Queue for sync
        try await syncSermon(updated)
    }

    /// Delete a sermon (soft delete)
    func deleteSermon(_ sermon: Sermon) async throws {
        try repository.softDeleteSermon(id: sermon.id)
        sermons.removeAll { $0.id == sermon.id }

        // Sync deletion
        do {
            try await supabase.deleteSermon(id: sermon.id.uuidString)
        } catch {
            // Will sync later
            self.error = error
        }

        // Clean up local audio files
        await cleanupAudioFiles(for: sermon.id)
    }

    // MARK: - Audio Upload

    /// Upload a sermon audio chunk to Supabase Storage
    func uploadChunk(_ chunk: SermonAudioChunk, data: Data) async throws -> String {
        guard let userId = supabase.currentUser?.id else {
            throw SermonError.notAuthenticated
        }

        // Update chunk status
        var updatedChunk = chunk
        updatedChunk.uploadStatus = .uploading
        updatedChunk.uploadProgress = 0
        try repository.updateChunk(updatedChunk)

        do {
            // Refresh session to ensure fresh JWT token for storage RLS
            do {
                _ = try await supabase.client.auth.refreshSession()
                print("[SermonSyncService] Upload: Session refreshed successfully")
            } catch {
                print("[SermonSyncService] Upload: Session refresh failed: \(error.localizedDescription)")
            }

            // Log user ID for debugging
            let sessionUserId = supabase.currentUser?.id
            print("[SermonSyncService] Upload: Session userId: \(sessionUserId?.uuidString ?? "nil"), Chunk userId path: \(userId.uuidString)")

            // Generate storage path: {userId}/{sermonId}/chunk_{index:03d}.m4a
            // IMPORTANT: Use lowercased UUIDs to match PostgreSQL's auth.uid()::text format
            let path = "\(userId.uuidString.lowercased())/\(chunk.sermonId.uuidString.lowercased())/chunk_\(String(format: "%03d", chunk.chunkIndex)).m4a"

            // Upload to Supabase Storage
            print("[SermonSyncService] Uploading chunk to path: \(path)")
            let remotePath = try await supabase.uploadSermonAudio(
                data: data,
                path: path,
                contentType: "audio/mp4"
            )

            // Update chunk with remote path
            updatedChunk.remotePath = remotePath
            updatedChunk.uploadStatus = .succeeded
            updatedChunk.uploadProgress = 1.0
            updatedChunk.fileSize = data.count
            updatedChunk.updatedAt = Date()
            updatedChunk.needsSync = true

            try repository.updateChunk(updatedChunk)

            print("[SermonSyncService] Uploaded chunk \(chunk.chunkIndex) to \(remotePath)")
            return remotePath

        } catch {
            // Mark upload as failed
            updatedChunk.uploadStatus = .failed
            updatedChunk.uploadError = error.localizedDescription
            try repository.updateChunk(updatedChunk)
            throw SermonError.uploadFailed(error.localizedDescription)
        }
    }

    /// Download a sermon audio chunk from Supabase Storage
    func downloadChunk(_ chunk: SermonAudioChunk) async throws -> URL {
        guard let remotePath = chunk.remotePath else {
            throw SermonError.chunkNotFound
        }

        // Check if already cached locally
        if let localPath = chunk.localPath {
            let localURL = URL(fileURLWithPath: localPath)
            if FileManager.default.fileExists(atPath: localPath) {
                return localURL
            }
        }

        // Generate signed URL
        let signedURL = try await supabase.getSermonAudioURL(path: remotePath, expiresIn: 3600)

        // Download to local cache
        let (data, _) = try await URLSession.shared.data(from: signedURL)

        // Save to cache directory
        let localURL = audioCacheDirectory
            .appendingPathComponent(chunk.sermonId.uuidString)
            .appendingPathComponent("chunk_\(String(format: "%03d", chunk.chunkIndex)).m4a")

        // Create directories if needed
        try FileManager.default.createDirectory(
            at: localURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        // Write data
        try data.write(to: localURL)

        // Update chunk with local path (via repository)
        var updatedChunk = chunk
        updatedChunk.localPath = localURL.path
        try repository.updateChunk(updatedChunk)

        // Enforce cache size limit
        await enforceCacheLimit()

        return localURL
    }

    /// Get signed URLs for all chunks of a sermon (for AVQueuePlayer)
    func getChunkURLs(sermonId: UUID) async throws -> [URL] {
        // Fetch chunks via repository
        let chunks = try repository.fetchChunks(sermonId: sermonId)
        var urls: [URL] = []

        for chunk in chunks.sorted(by: { $0.chunkIndex < $1.chunkIndex }) {
            if let localPath = chunk.localPath,
               FileManager.default.fileExists(atPath: localPath) {
                // Use local file
                urls.append(URL(fileURLWithPath: localPath))
            } else if let remotePath = chunk.remotePath {
                // Get signed URL
                let signedURL = try await supabase.getSermonAudioURL(path: remotePath, expiresIn: 3600)
                urls.append(signedURL)
            }
        }

        return urls
    }

    // MARK: - Sync Operations

    private func syncWithRemote() async throws {
        isSyncing = true
        defer { isSyncing = false }

        // Ensure we have an authenticated user with valid session
        guard let userId = supabase.currentUser?.id else {
            print("[SermonSyncService] Skipping sync - user not authenticated")
            return
        }

        // Refresh session if needed (handles expired JWTs)
        do {
            try await supabase.client.auth.refreshSession()
        } catch {
            print("[SermonSyncService] Session refresh failed, will retry sync later: \(error.localizedDescription)")
            return
        }

        // Fetch from Supabase
        let remoteSermons = try await supabase.getSermons()

        // Save remote sermons to local cache (via repository)
        let sermonsToSave = remoteSermons.map { Sermon(from: $0) }
        try repository.saveSermons(sermonsToSave)

        // Reload from cache (via repository)
        sermons = try repository.fetchAllSermons(userId: userId, includeDeleted: false)

        // Push local changes
        try await pushLocalChanges()
    }

    private func syncSermon(_ sermon: Sermon) async throws {
        do {
            // Refresh session to ensure fresh JWT token for RLS validation
            do {
                _ = try await supabase.client.auth.refreshSession()
                print("[SermonSyncService] Session refreshed successfully")
            } catch {
                print("[SermonSyncService] Session refresh failed: \(error.localizedDescription)")
            }

            // Log user ID comparison for debugging
            let sessionUserId = supabase.currentUser?.id
            print("[SermonSyncService] Session userId: \(sessionUserId?.uuidString ?? "nil"), Sermon userId: \(sermon.userId.uuidString)")

            // Verify the user ID matches before syncing
            guard let currentUserId = sessionUserId, currentUserId == sermon.userId else {
                print("[SermonSyncService] User ID mismatch or no session - sermon userId: \(sermon.userId), session userId: \(sessionUserId?.uuidString ?? "nil")")
                throw SermonError.notAuthenticated
            }

            if sermon.deletedAt != nil {
                try await supabase.deleteSermon(id: sermon.id.uuidString)
            } else {
                try await supabase.upsertSermon(sermon.toDTO())
            }

            // Mark as synced (via repository)
            var synced = sermon
            synced.needsSync = false
            try repository.updateSermon(synced)
            print("[SermonSyncService] Sermon synced successfully: \(sermon.id)")

        } catch {
            // Will sync later
            self.error = error
            print("[SermonSyncService] Sync error: \(error)")
        }
    }

    private func pushLocalChanges() async throws {
        // Sync sermons (via repository)
        let sermonsToSync = try repository.fetchSermonsNeedingSync()
        for sermon in sermonsToSync {
            try await syncSermon(sermon)
        }

        // Sync transcripts (via repository)
        let transcriptsToSync = try repository.fetchTranscriptsNeedingSync()
        for transcript in transcriptsToSync {
            try await syncTranscript(transcript)
        }

        // Sync study guides (via repository)
        let guidesToSync = try repository.fetchStudyGuidesNeedingSync()
        for guide in guidesToSync {
            try await syncStudyGuide(guide)
        }

        // Sync bookmarks (via repository)
        let bookmarksToSync = try repository.fetchBookmarksNeedingSync()
        for bookmark in bookmarksToSync {
            try await syncBookmark(bookmark)
        }
    }

    private func syncTranscript(_ transcript: SermonTranscript) async throws {
        do {
            // Refresh session to ensure fresh JWT token for RLS validation
            _ = try? await supabase.client.auth.refreshSession()
            try await supabase.upsertSermonTranscript(transcript.toDTO())

            // Mark as synced (via repository)
            var synced = transcript
            synced.needsSync = false
            try repository.updateTranscript(synced)
        } catch {
            print("[SermonSyncService] Transcript sync error: \(error)")
        }
    }

    private func syncStudyGuide(_ guide: SermonStudyGuide) async throws {
        do {
            // Refresh session to ensure fresh JWT token for RLS validation
            _ = try? await supabase.client.auth.refreshSession()
            try await supabase.upsertSermonStudyGuide(guide.toDTO())

            // Mark as synced (via repository)
            var synced = guide
            synced.needsSync = false
            try repository.updateStudyGuide(synced)
        } catch {
            print("[SermonSyncService] Study guide sync error: \(error)")
        }
    }

    private func syncBookmark(_ bookmark: SermonBookmark) async throws {
        do {
            // Refresh session to ensure fresh JWT token for RLS validation
            _ = try? await supabase.client.auth.refreshSession()

            if bookmark.deletedAt != nil {
                try await supabase.deleteSermonBookmark(id: bookmark.id.uuidString)
            } else {
                try await supabase.upsertSermonBookmark(bookmark.toDTO())
            }

            // Mark as synced (via repository)
            var synced = bookmark
            synced.needsSync = false
            try repository.updateBookmark(synced)
        } catch {
            print("[SermonSyncService] Bookmark sync error: \(error)")
        }
    }

    // MARK: - Cache Management

    private func enforceCacheLimit() async {
        let fileManager = FileManager.default

        // Get all cached audio files
        guard let enumerator = fileManager.enumerator(
            at: audioCacheDirectory,
            includingPropertiesForKeys: [.contentAccessDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        var files: [(url: URL, accessDate: Date, size: Int64)] = []
        var totalSize: Int64 = 0

        while let fileURL = enumerator.nextObject() as? URL {
            guard fileURL.pathExtension == "m4a" else { continue }

            do {
                let values = try fileURL.resourceValues(forKeys: [.contentAccessDateKey, .fileSizeKey])
                let accessDate = values.contentAccessDate ?? Date.distantPast
                let size = Int64(values.fileSize ?? 0)

                files.append((fileURL, accessDate, size))
                totalSize += size
            } catch {
                continue
            }
        }

        // If over limit, remove oldest files
        guard totalSize > maxCacheSize else { return }

        files.sort { $0.accessDate < $1.accessDate }

        for file in files {
            guard totalSize > maxCacheSize else { break }

            try? fileManager.removeItem(at: file.url)
            totalSize -= file.size

            print("[SermonSyncService] Evicted from cache: \(file.url.lastPathComponent)")
        }
    }

    private func cleanupAudioFiles(for sermonId: UUID) async {
        let sermonDir = audioCacheDirectory.appendingPathComponent(sermonId.uuidString)
        try? FileManager.default.removeItem(at: sermonDir)
    }

    // MARK: - Remote Fetch

    private func fetchSermonFromRemote(id: UUID) async throws -> Sermon? {
        let dto = try await supabase.getSermon(id: id.uuidString)
        guard let dto = dto else { return nil }

        let sermon = Sermon(from: dto)

        // Cache locally (via repository)
        try repository.saveSermon(sermon)

        return sermon
    }

    // MARK: - Bookmark Operations

    func addBookmark(_ bookmark: SermonBookmark) async throws {
        try repository.saveBookmark(bookmark)
        try await syncBookmark(bookmark)
    }

    func updateBookmark(_ bookmark: SermonBookmark) async throws {
        var updated = bookmark
        updated.updatedAt = Date()
        updated.needsSync = true

        try repository.updateBookmark(updated)
        try await syncBookmark(updated)
    }

    func deleteBookmark(_ bookmark: SermonBookmark) async throws {
        var deleted = bookmark
        deleted.deletedAt = Date()
        deleted.needsSync = true

        try repository.updateBookmark(deleted)
        try await syncBookmark(deleted)
    }

    func getBookmarks(for sermonId: UUID) async throws -> [SermonBookmark] {
        try repository.fetchBookmarks(sermonId: sermonId, includeDeleted: false)
    }
}

import Foundation

// MARK: - Audio Cache
// Manages caching of audio files for offline playback

final class AudioCache {
    // MARK: - Singleton
    static let shared = AudioCache()

    // MARK: - Properties
    private let fileManager = FileManager.default
    let cacheDirectory: URL

    // Cache limits (configurable via UserDefaults)
    private var maxCacheSize: Int64 {
        let userLimit = UserDefaults.standard.integer(forKey: "audioCacheSizeMB")
        let limitMB = userLimit > 0 ? userLimit : 100 // Default 100MB
        return Int64(limitMB) * 1024 * 1024
    }

    // Maximum age for cached files (30 days)
    private let maxCacheAge: TimeInterval = 30 * 24 * 60 * 60

    // MARK: - Initialization

    private init() {
        // Get cache directory
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = caches.appendingPathComponent("AudioCache", isDirectory: true)

        // Create directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Cache Operations

    /// Result of cache retrieval including audio URL and verse timings
    struct CachedAudioResult {
        let url: URL
        let timings: [VerseTiming]
    }

    /// Get cached audio URL if it exists
    func getCachedAudio(for chapter: AudioChapter) -> URL? {
        let fileURL = cacheURL(for: chapter)
        if fileManager.fileExists(atPath: fileURL.path) {
            // Update access date for LRU tracking
            try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: fileURL.path)
            return fileURL
        }
        return nil
    }

    /// Get cached audio URL with verse timings if both exist
    /// Prioritizes HLS manifest over legacy single-file cache
    /// Then prioritizes Edge TTS over local TTS
    func getCachedAudioWithTimings(for chapter: AudioChapter) -> CachedAudioResult? {
        // Try HLS manifest first (new format)
        let manifestURL = manifestURL(forCacheKey: chapter.cacheKey)
        if fileManager.fileExists(atPath: manifestURL.path) {
            // Load HLS manifest and extract timings
            if let timings = loadTimingsFromManifest(manifestURL, chapter: chapter) {
                // Update access date for LRU tracking
                try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: manifestURL.path)
                return CachedAudioResult(url: manifestURL, timings: timings)
            }
        }

        // Try Edge TTS cache (legacy single-file format)
        let edgeFileURL = edgeCacheURL(for: chapter)
        let edgeTimingsURL = timingsURL(forCacheKey: chapter.edgeCacheKey)

        if fileManager.fileExists(atPath: edgeFileURL.path),
           fileManager.fileExists(atPath: edgeTimingsURL.path) {
            // Update access date for LRU tracking
            try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: edgeFileURL.path)
            try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: edgeTimingsURL.path)

            // Load cached verse timings
            if let timingsData = try? Data(contentsOf: edgeTimingsURL),
               let timings = try? JSONDecoder().decode([CachedVerseTiming].self, from: timingsData) {
                let verseTimings = timings.map { VerseTiming(verseNumber: $0.verseNumber, startTime: $0.startTime, endTime: $0.endTime) }
                return CachedAudioResult(url: edgeFileURL, timings: verseTimings)
            }
        }

        // Fall back to local TTS cache (legacy single-file format)
        let localFileURL = localCacheURL(for: chapter)
        let localTimingsURL = timingsURL(forCacheKey: chapter.localCacheKey)

        guard fileManager.fileExists(atPath: localFileURL.path),
              fileManager.fileExists(atPath: localTimingsURL.path) else {
            return nil
        }

        // Update access date for LRU tracking
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: localFileURL.path)
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: localTimingsURL.path)

        // Load cached verse timings
        guard let timingsData = try? Data(contentsOf: localTimingsURL),
              let timings = try? JSONDecoder().decode([CachedVerseTiming].self, from: timingsData) else {
            return nil
        }

        let verseTimings = timings.map { VerseTiming(verseNumber: $0.verseNumber, startTime: $0.startTime, endTime: $0.endTime) }
        return CachedAudioResult(url: localFileURL, timings: verseTimings)
    }

    // MARK: - HLS Segment Support

    /// Load verse timings from HLS manifest by parsing segment durations
    private func loadTimingsFromManifest(_ manifestURL: URL, chapter: AudioChapter) -> [VerseTiming]? {
        guard let content = try? String(contentsOf: manifestURL, encoding: .utf8) else { return nil }

        var timings: [VerseTiming] = []
        var currentTime: TimeInterval = 0
        var currentVerseNumber = 1

        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            // Parse EXTINF lines: #EXTINF:4.237,Verse 1
            if line.hasPrefix("#EXTINF:") {
                let components = line.components(separatedBy: ",")
                if components.count >= 2 {
                    let durationStr = components[0].replacingOccurrences(of: "#EXTINF:", with: "")
                    if let duration = TimeInterval(durationStr) {
                        let timing = VerseTiming(
                            verseNumber: currentVerseNumber,
                            startTime: currentTime,
                            endTime: currentTime + duration
                        )
                        timings.append(timing)
                        currentTime += duration
                        currentVerseNumber += 1
                    }
                }
            }
        }

        return timings.isEmpty ? nil : timings
    }

    /// Check if chapter has complete HLS manifest cached
    func hasCompleteHLSManifest(for chapter: AudioChapter) -> Bool {
        let manifestURL = manifestURL(forCacheKey: chapter.cacheKey)
        guard fileManager.fileExists(atPath: manifestURL.path),
              let content = try? String(contentsOf: manifestURL, encoding: .utf8) else {
            return false
        }
        return content.contains("#EXT-X-ENDLIST")
    }

    /// Cache audio data and return the file URL
    func cacheAudio(_ data: Data, for chapter: AudioChapter) throws -> URL {
        // Ensure we have space
        try pruneIfNeeded(additionalSize: Int64(data.count))

        let fileURL = cacheURL(for: chapter)
        try data.write(to: fileURL)

        // Set file protection to allow lock-screen playback
        // completeUntilFirstUserAuthentication allows access after first unlock
        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: fileURL.path
        )

        return fileURL
    }

    /// Cache audio data with verse timings and return the file URL
    func cacheAudioWithTimings(_ data: Data, timings: [VerseTiming], for chapter: AudioChapter) throws -> URL {
        // Cache the audio data first
        let audioURL = try cacheAudio(data, for: chapter)

        // Cache the verse timings as JSON
        let timingsURL = self.timingsURL(for: chapter)
        let cachedTimings = timings.map { CachedVerseTiming(verseNumber: $0.verseNumber, startTime: $0.startTime, endTime: $0.endTime) }
        let timingsData = try JSONEncoder().encode(cachedTimings)
        try timingsData.write(to: timingsURL)

        // Set file protection for timings file too
        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: timingsURL.path
        )

        return audioURL
    }

    /// Cache audio data with verse timings using specific cache key and file extension
    /// - Parameters:
    ///   - data: Audio data to cache
    ///   - timings: Verse timing information
    ///   - chapter: The audio chapter (for pruning calculations)
    ///   - cacheKey: Specific cache key to use (e.g., edge vs local)
    ///   - fileExtension: File extension for audio file (e.g., "mp3" or "caf")
    func cacheAudioWithTimings(
        _ data: Data,
        timings: [VerseTiming],
        for chapter: AudioChapter,
        cacheKey: String,
        fileExtension: String
    ) throws -> URL {
        // Ensure we have space
        try pruneIfNeeded(additionalSize: Int64(data.count))

        // Create audio file URL with specific key and extension
        let audioFilename = "\(cacheKey).\(fileExtension)"
        let audioURL = cacheDirectory.appendingPathComponent(audioFilename)
        try data.write(to: audioURL)

        // Set file protection to allow lock-screen playback
        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: audioURL.path
        )

        // Cache the verse timings as JSON
        let timingsFilename = "\(cacheKey).timings.json"
        let timingsFileURL = cacheDirectory.appendingPathComponent(timingsFilename)
        let cachedTimings = timings.map { CachedVerseTiming(verseNumber: $0.verseNumber, startTime: $0.startTime, endTime: $0.endTime) }
        let timingsData = try JSONEncoder().encode(cachedTimings)
        try timingsData.write(to: timingsFileURL)

        // Set file protection for timings file too
        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: timingsFileURL.path
        )

        return audioURL
    }

    /// Delete cached audio for a chapter
    func deleteCachedAudio(for chapter: AudioChapter) {
        let fileURL = cacheURL(for: chapter)
        let timingsURL = timingsURL(for: chapter)
        try? fileManager.removeItem(at: fileURL)
        try? fileManager.removeItem(at: timingsURL)
    }

    /// Clear all cached audio
    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Get total cache size in bytes
    func cacheSize() -> Int64 {
        var size: Int64 = 0
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                size += Int64(fileSize)
            }
        }

        return size
    }

    /// Get formatted cache size string
    func formattedCacheSize() -> String {
        let size = cacheSize()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    // MARK: - Private Helpers

    private func cacheURL(for chapter: AudioChapter) -> URL {
        // Use cacheKey instead of id to account for voice/rate changes
        // Edge TTS uses MP3 format, local TTS uses CAF format
        let isEdge = chapter.cacheKey.contains("edge")
        let ext = isEdge ? "mp3" : "caf"
        let filename = "\(chapter.cacheKey).\(ext)"
        return cacheDirectory.appendingPathComponent(filename)
    }

    /// Get cache URL with specific extension
    func cacheURL(for chapter: AudioChapter, format: String) -> URL {
        let filename = "\(chapter.cacheKey).\(format)"
        return cacheDirectory.appendingPathComponent(filename)
    }

    /// Get Edge TTS cache URL
    func edgeCacheURL(for chapter: AudioChapter) -> URL {
        let filename = "\(chapter.edgeCacheKey).mp3"
        return cacheDirectory.appendingPathComponent(filename)
    }

    /// Get local TTS cache URL
    func localCacheURL(for chapter: AudioChapter) -> URL {
        let filename = "\(chapter.localCacheKey).caf"
        return cacheDirectory.appendingPathComponent(filename)
    }

    private func timingsURL(for chapter: AudioChapter) -> URL {
        // Verse timings stored as JSON alongside audio file
        let filename = "\(chapter.cacheKey).timings.json"
        return cacheDirectory.appendingPathComponent(filename)
    }

    /// Get timings URL for specific cache key
    func timingsURL(forCacheKey cacheKey: String) -> URL {
        let filename = "\(cacheKey).timings.json"
        return cacheDirectory.appendingPathComponent(filename)
    }

    /// Prune cache if it would exceed max size
    private func pruneIfNeeded(additionalSize: Int64) throws {
        // First, prune expired files
        pruneExpiredFiles()

        let currentSize = cacheSize()
        let projectedSize = currentSize + additionalSize

        guard projectedSize > maxCacheSize else { return }

        // Get all cached files with modification dates
        var files: [(url: URL, date: Date, size: Int64)] = []

        if let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
        ) {
            for case let fileURL as URL in enumerator {
                if let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                   let date = values.contentModificationDate,
                   let size = values.fileSize {
                    files.append((fileURL, date, Int64(size)))
                }
            }
        }

        // Sort by date (oldest first)
        files.sort { $0.date < $1.date }

        // Delete oldest files until we're under the limit
        var freedSpace: Int64 = 0
        let spaceNeeded = projectedSize - maxCacheSize

        for file in files {
            guard freedSpace < spaceNeeded else { break }
            try? fileManager.removeItem(at: file.url)
            freedSpace += file.size
            print("[AudioCache] LRU evicted: \(file.url.lastPathComponent)")
        }
    }

    /// Prune files older than maxCacheAge (30 days)
    private func pruneExpiredFiles() {
        let cutoffDate = Date().addingTimeInterval(-maxCacheAge)

        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return }

        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]),
               let date = values.contentModificationDate,
               date < cutoffDate {
                try? fileManager.removeItem(at: fileURL)
                print("[AudioCache] Expired file removed: \(fileURL.lastPathComponent)")
            }
        }
    }

    /// Run maintenance (call periodically, e.g., on app launch)
    func performMaintenance() {
        pruneExpiredFiles()

        // Also enforce size limit
        let currentSize = cacheSize()
        if currentSize > maxCacheSize {
            try? pruneIfNeeded(additionalSize: 0)
        }

        print("[AudioCache] Maintenance complete - \(formattedCacheSize()) used")
    }

    // MARK: - User Settings

    /// Set maximum cache size in MB
    static func setMaxCacheSize(megabytes: Int) {
        UserDefaults.standard.set(megabytes, forKey: "audioCacheSizeMB")
    }

    /// Get current cache size limit in MB
    static func getMaxCacheSizeMB() -> Int {
        let userLimit = UserDefaults.standard.integer(forKey: "audioCacheSizeMB")
        return userLimit > 0 ? userLimit : 100
    }

    /// Available cache size options for settings UI
    static let cacheSizeOptions: [(label: String, mb: Int)] = [
        ("50 MB", 50),
        ("100 MB (Default)", 100),
        ("200 MB", 200),
        ("500 MB", 500),
        ("Unlimited", 2000)
    ]
}

// MARK: - Download Manager Extension

extension AudioCache {
    /// Check if a chapter is downloaded
    func isDownloaded(_ chapter: AudioChapter) -> Bool {
        getCachedAudio(for: chapter) != nil
    }

    /// Get list of downloaded chapters
    func downloadedChapters() -> [String] {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        return files.map { $0.deletingPathExtension().lastPathComponent }
    }
}

// MARK: - Cached Verse Timing

/// Codable struct for persisting verse timings to JSON
private struct CachedVerseTiming: Codable {
    let verseNumber: Int
    let startTime: TimeInterval
    let endTime: TimeInterval
}

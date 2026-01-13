//
//  HLSManifestService.swift
//  BibleStudy
//
//  HLS manifest generation and management for progressive audio streaming.
//  Supports local file:// URLs for server-free streaming.
//

import Foundation
import AVFoundation

// MARK: - HLS Manifest Manager

/// Manages HLS .m3u8 manifest creation and updates for progressive audio streaming
actor HLSManifestService {
    // MARK: - Types

    struct SegmentInfo: Sendable {
        let url: URL
        let verseNumber: Int
        let duration: TimeInterval
        let startTime: TimeInterval

        var endTime: TimeInterval {
            startTime + duration
        }
    }

    struct ManifestState: Sendable {
        var url: URL
        var segments: [SegmentInfo]
        var isComplete: Bool
        var lastModified: Date
        var totalDuration: TimeInterval {
            segments.last?.endTime ?? 0
        }
    }

    enum ManifestError: Error, LocalizedError {
        case notFound
        case invalidFormat
        case fileWriteFailure(String)
        case segmentMissing(Int)

        var errorDescription: String? {
            switch self {
            case .notFound:
                return "HLS manifest not found"
            case .invalidFormat:
                return "Invalid HLS manifest format"
            case .fileWriteFailure(let reason):
                return "Failed to write manifest: \(reason)"
            case .segmentMissing(let verse):
                return "Segment missing for verse \(verse)"
            }
        }
    }

    // MARK: - Properties

    private let cache: AudioCache
    private var activeManifests: [String: ManifestState] = [:]

    // MARK: - Initialization

    init(cache: AudioCache) {
        self.cache = cache
    }

    // MARK: - Manifest Creation

    /// Create a new HLS manifest with initial segments
    func create(chapter: AudioChapter, segments: [SegmentInfo]) async throws -> URL {
        let cacheKey = await MainActor.run { chapter.cacheKey }
        let bookName = await MainActor.run { chapter.bookName }
        let chapterNumber = await MainActor.run { chapter.chapterNumber }

        let manifestURL = await cache.manifestURL(for: chapter)
        let manifestContent = buildManifest(segments: segments, isComplete: false)

        do {
            try manifestContent.write(to: manifestURL, atomically: true, encoding: .utf8)
        } catch {
            throw ManifestError.fileWriteFailure(error.localizedDescription)
        }

        activeManifests[cacheKey] = ManifestState(
            url: manifestURL,
            segments: segments,
            isComplete: false,
            lastModified: Date()
        )

        print("[HLS] Created manifest for \(bookName) \(chapterNumber) with \(segments.count) segments")
        return manifestURL
    }

    /// Append a segment to an existing manifest
    func append(chapter: AudioChapter, segment: SegmentInfo) async throws {
        let cacheKey = await MainActor.run { chapter.cacheKey }

        guard var state = activeManifests[cacheKey] else {
            throw ManifestError.notFound
        }

        state.segments.append(segment)
        state.lastModified = Date()

        let manifestContent = buildManifest(segments: state.segments, isComplete: false)

        do {
            try manifestContent.write(to: state.url, atomically: true, encoding: .utf8)
        } catch {
            throw ManifestError.fileWriteFailure(error.localizedDescription)
        }

        activeManifests[cacheKey] = state

        print("[HLS] Appended verse \(segment.verseNumber) to manifest (\(state.segments.count) total)")
    }

    /// Mark manifest as complete (add #EXT-X-ENDLIST)
    func markComplete(chapter: AudioChapter) async throws {
        let cacheKey = await MainActor.run { chapter.cacheKey }
        let bookName = await MainActor.run { chapter.bookName }
        let chapterNumber = await MainActor.run { chapter.chapterNumber }

        guard var state = activeManifests[cacheKey] else {
            throw ManifestError.notFound
        }

        state.isComplete = true
        let manifestContent = buildManifest(segments: state.segments, isComplete: true)

        do {
            try manifestContent.write(to: state.url, atomically: true, encoding: .utf8)
        } catch {
            throw ManifestError.fileWriteFailure(error.localizedDescription)
        }

        activeManifests[cacheKey] = state

        print("[HLS] Marked manifest complete for \(bookName) \(chapterNumber) (\(state.segments.count) verses)")
    }

    // MARK: - Manifest Retrieval

    /// Get existing manifest if available
    func getManifest(for chapter: AudioChapter) async -> URL? {
        let manifestURL = await cache.manifestURL(for: chapter)
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            return nil
        }
        return manifestURL
    }

    /// Check if manifest is complete
    func isComplete(for chapter: AudioChapter) async -> Bool {
        let cacheKey = await MainActor.run { chapter.cacheKey }

        if let state = activeManifests[cacheKey] {
            return state.isComplete
        }

        // Check file directly
        guard let manifestURL = await getManifest(for: chapter),
              let content = try? String(contentsOf: manifestURL, encoding: .utf8) else {
            return false
        }

        return content.contains("#EXT-X-ENDLIST")
    }

    /// Get manifest state
    func getState(for chapter: AudioChapter) async -> ManifestState? {
        let cacheKey = await MainActor.run { chapter.cacheKey }
        return activeManifests[cacheKey]
    }

    // MARK: - Validation

    /// Validate manifest and check all segments exist
    func validate(chapter: AudioChapter) async throws {
        guard let manifestURL = await getManifest(for: chapter) else {
            throw ManifestError.notFound
        }

        guard let content = try? String(contentsOf: manifestURL, encoding: .utf8) else {
            throw ManifestError.invalidFormat
        }

        // Parse segment URLs from manifest
        let lines = content.components(separatedBy: .newlines)
        for line in lines where !line.hasPrefix("#") && !line.isEmpty {
            guard let url = URL(string: line),
                  FileManager.default.fileExists(atPath: url.path) else {
                // Extract verse number from URL if possible
                let verseNum = extractVerseNumber(from: line)
                throw ManifestError.segmentMissing(verseNum ?? 0)
            }
        }
    }

    // MARK: - Cleanup

    /// Delete manifest and all associated segments
    func delete(chapter: AudioChapter) async throws {
        let cacheKey = await MainActor.run { chapter.cacheKey }
        let bookName = await MainActor.run { chapter.bookName }
        let chapterNumber = await MainActor.run { chapter.chapterNumber }

        guard let manifestURL = await getManifest(for: chapter) else { return }

        // Parse manifest to find all segment URLs
        if let content = try? String(contentsOf: manifestURL, encoding: .utf8) {
            let lines = content.components(separatedBy: .newlines)
            for line in lines where !line.hasPrefix("#") && !line.isEmpty {
                if let url = URL(string: line) {
                    try? FileManager.default.removeItem(at: url)
                }
            }
        }

        // Delete manifest file
        try? FileManager.default.removeItem(at: manifestURL)

        // Remove from active manifests
        activeManifests.removeValue(forKey: cacheKey)

        print("[HLS] Deleted manifest and segments for \(bookName) \(chapterNumber)")
    }

    // MARK: - Private Methods

    /// Build HLS manifest content from segments
    private func buildManifest(segments: [SegmentInfo], isComplete: Bool) -> String {
        var lines: [String] = []

        // Header
        lines.append("#EXTM3U")
        lines.append("#EXT-X-VERSION:3")

        // Target duration (max segment duration + 1 for safety)
        let maxDuration = segments.map(\.duration).max() ?? 10
        lines.append("#EXT-X-TARGETDURATION:\(Int(maxDuration) + 1)")

        // Playlist type (EVENT allows appending segments)
        lines.append("#EXT-X-PLAYLIST-TYPE:EVENT")

        // Segments
        for segment in segments {
            lines.append("#EXTINF:\(String(format: "%.3f", segment.duration)),Verse \(segment.verseNumber)")
            // Use only the filename (relative path) - manifest and segments are in the same directory
            lines.append(segment.url.lastPathComponent)
        }

        // End marker (only for complete manifests)
        if isComplete {
            lines.append("#EXT-X-ENDLIST")
        }

        return lines.joined(separator: "\n") + "\n"
    }

    /// Extract verse number from segment filename
    private func extractVerseNumber(from filename: String) -> Int? {
        // Pattern: ...v###.mp3
        let pattern = "v(\\d{3})\\."
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: filename, range: NSRange(filename.startIndex..., in: filename)),
              let verseRange = Range(match.range(at: 1), in: filename) else {
            return nil
        }
        return Int(filename[verseRange])
    }
}

// MARK: - AudioCache Extension

extension AudioCache {
    /// Get manifest URL for a chapter (async version for actor contexts)
    func manifestURL(for chapter: AudioChapter) async -> URL {
        let cacheKey = await MainActor.run { chapter.cacheKey }
        let filename = "\(cacheKey).m3u8"
        return cacheDirectory.appendingPathComponent(filename)
    }

    /// Get manifest URL for a chapter using direct cache key (synchronous)
    func manifestURL(forCacheKey cacheKey: String) -> URL {
        let filename = "\(cacheKey).m3u8"
        return cacheDirectory.appendingPathComponent(filename)
    }

    /// Get segment URL for a specific verse (async version for actor contexts)
    func segmentURL(for chapter: AudioChapter, verse: Int, fileExtension: String) async -> URL {
        let cacheKey = await MainActor.run { chapter.cacheKey }
        let filename = String(format: "%@-v%03d.%@", cacheKey, verse, fileExtension)
        return cacheDirectory.appendingPathComponent(filename)
    }
}

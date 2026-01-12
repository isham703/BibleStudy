import Foundation
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Sermon Import Service
// Handles audio file import with Whisper-safe chunking for transcription

@MainActor
final class SermonImportService {
    // MARK: - Singleton

    static let shared = SermonImportService()

    // MARK: - Configuration

    /// Target chunk duration (10 minutes, matching RecordingConfiguration)
    static let chunkDurationSeconds: TimeInterval = 600

    /// Whisper API file size limit
    static let maxChunkSize = 25_000_000 // 25 MB

    // MARK: - Import Result

    struct ImportResult: Sendable {
        let sermon: Sermon
        let chunks: [SermonAudioChunk]
        let chunkURLs: [URL]
    }

    // MARK: - Private Properties

    private init() {}

    // MARK: - Import Methods

    /// Import an audio file, splitting into Whisper-safe chunks if needed
    /// - Parameters:
    ///   - url: Source audio file URL (may be security-scoped)
    ///   - userId: User ID for the sermon record
    ///   - title: Optional sermon title (uses filename if nil)
    ///   - speakerName: Optional speaker name
    /// - Returns: ImportResult with sermon, chunks, and local file URLs
    /// - Throws: SermonError on validation or processing failure
    func importAudioFile(
        url: URL,
        userId: UUID,
        title: String?,
        speakerName: String?
    ) async throws -> ImportResult {
        // 1. Validate file
        let metadata = try await AudioFileValidator.validate(url: url)

        // 2. Create sermon record
        let sermon = Sermon(
            userId: userId,
            title: title ?? url.deletingPathExtension().lastPathComponent,
            speakerName: speakerName,
            recordedAt: Date(),
            durationSeconds: Int(metadata.duration),
            audioFileSize: metadata.fileSize,
            audioMimeType: mimeType(for: metadata.format)
        )

        // 3. Create output directory
        let sermonDirectory = try createSermonDirectory(sermonId: sermon.id)

        // 4. Determine if we need to chunk (files > 10 minutes)
        let needsChunking = metadata.duration > Self.chunkDurationSeconds

        if needsChunking {
            // Split into Whisper-safe chunks
            return try await importWithChunking(
                url: url,
                sermon: sermon,
                metadata: metadata,
                outputDirectory: sermonDirectory
            )
        } else {
            // Single chunk - just copy and generate waveform
            return try await importSingleChunk(
                url: url,
                sermon: sermon,
                metadata: metadata,
                outputDirectory: sermonDirectory
            )
        }
    }

    // MARK: - Single Chunk Import

    private func importSingleChunk(
        url: URL,
        sermon: Sermon,
        metadata: AudioFileValidator.Metadata,
        outputDirectory: URL
    ) async throws -> ImportResult {
        // Copy file to local storage
        let localURL = try await copyToLocalStorage(
            url: url,
            outputDirectory: outputDirectory,
            filename: "chunk_000.m4a"
        )

        // Get file size after copy
        let fileSize = try FileManager.default.attributesOfItem(atPath: localURL.path)[.size] as? Int

        // Generate waveform
        let waveform = try await WaveformGenerator.generateSamples(from: localURL)

        // Create chunk record
        let chunk = SermonAudioChunk(
            sermonId: sermon.id,
            chunkIndex: 0,
            startOffsetSeconds: 0,
            durationSeconds: metadata.duration,
            localPath: localURL.path,
            fileSize: fileSize,
            waveformSamples: waveform,
            needsSync: true
        )

        return ImportResult(sermon: sermon, chunks: [chunk], chunkURLs: [localURL])
    }

    // MARK: - Chunked Import

    private func importWithChunking(
        url: URL,
        sermon: Sermon,
        metadata: AudioFileValidator.Metadata,
        outputDirectory: URL
    ) async throws -> ImportResult {
        // Calculate chunk count
        let chunkCount = Int(ceil(metadata.duration / Self.chunkDurationSeconds))

        var chunks: [SermonAudioChunk] = []
        var chunkURLs: [URL] = []

        // Export each chunk using AVAssetExportSession
        for chunkIndex in 0..<chunkCount {
            let startTime = Double(chunkIndex) * Self.chunkDurationSeconds
            let endTime = min(startTime + Self.chunkDurationSeconds, metadata.duration)
            let chunkDuration = endTime - startTime

            let chunkFilename = String(format: "chunk_%03d.m4a", chunkIndex)
            let chunkURL = outputDirectory.appendingPathComponent(chunkFilename)

            // Export this time range
            try await exportChunk(
                from: url,
                to: chunkURL,
                startTime: startTime,
                endTime: endTime
            )

            // Get file size
            let fileSize = try FileManager.default.attributesOfItem(atPath: chunkURL.path)[.size] as? Int

            // Verify chunk is under Whisper limit
            if let size = fileSize, size > Self.maxChunkSize {
                // This shouldn't happen with 10-min chunks at reasonable bitrates
                // but if it does, log a warning - processing will handle it
                print("[SermonImportService] Warning: chunk \(chunkIndex) exceeds 25MB (\(size) bytes)")
            }

            // Generate waveform for this chunk
            let waveform = try await WaveformGenerator.generateSamples(from: chunkURL)

            // Create chunk record
            let chunk = SermonAudioChunk(
                sermonId: sermon.id,
                chunkIndex: chunkIndex,
                startOffsetSeconds: startTime,
                durationSeconds: chunkDuration,
                localPath: chunkURL.path,
                fileSize: fileSize,
                waveformSamples: waveform,
                needsSync: true
            )

            chunks.append(chunk)
            chunkURLs.append(chunkURL)
        }

        return ImportResult(sermon: sermon, chunks: chunks, chunkURLs: chunkURLs)
    }

    // MARK: - Audio Export

    private func exportChunk(
        from sourceURL: URL,
        to destinationURL: URL,
        startTime: TimeInterval,
        endTime: TimeInterval
    ) async throws {
        try await Task.detached(priority: .userInitiated) {
            // Access security-scoped resource if needed
            let didAccess = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            let asset = AVURLAsset(url: sourceURL)

            // Create export session
            guard let exportSession = AVAssetExportSession(
                asset: asset,
                presetName: AVAssetExportPresetAppleM4A
            ) else {
                throw SermonError.importFailed("Could not create export session")
            }

            // Configure time range
            let startCMTime = CMTime(seconds: startTime, preferredTimescale: 600)
            let endCMTime = CMTime(seconds: endTime, preferredTimescale: 600)
            let timeRange = CMTimeRange(start: startCMTime, end: endCMTime)

            exportSession.timeRange = timeRange

            // Export using modern async API
            do {
                try await exportSession.export(to: destinationURL, as: .m4a)
            } catch {
                throw SermonError.importFailed("Export failed: \(error.localizedDescription)")
            }
        }.value
    }

    // MARK: - File Operations

    private func createSermonDirectory(sermonId: UUID) throws -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let sermonDirectory = documentsURL
            .appendingPathComponent("Sermons", isDirectory: true)
            .appendingPathComponent(sermonId.uuidString, isDirectory: true)

        try FileManager.default.createDirectory(
            at: sermonDirectory,
            withIntermediateDirectories: true
        )

        return sermonDirectory
    }

    private func copyToLocalStorage(
        url: URL,
        outputDirectory: URL,
        filename: String
    ) async throws -> URL {
        return try await Task.detached(priority: .userInitiated) {
            // Access security-scoped resource if needed
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let destinationURL = outputDirectory.appendingPathComponent(filename)

            // Remove existing file if present
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            // For short files, we still need to convert to M4A for consistency
            // Use AVAssetExportSession to ensure proper format
            let asset = AVURLAsset(url: url)

            guard let exportSession = AVAssetExportSession(
                asset: asset,
                presetName: AVAssetExportPresetAppleM4A
            ) else {
                // Fallback to direct copy if export session unavailable
                try FileManager.default.copyItem(at: url, to: destinationURL)
                return destinationURL
            }

            // Export using modern async API
            do {
                try await exportSession.export(to: destinationURL, as: .m4a)
            } catch {
                // Fallback to direct copy if export fails
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: url, to: destinationURL)
            }

            return destinationURL
        }.value
    }

    // MARK: - Helpers

    private func mimeType(for format: UTType) -> String {
        switch format {
        case .mp3:
            return "audio/mpeg"
        case .mpeg4Audio:
            return "audio/mp4"
        case .wav:
            return "audio/wav"
        default:
            return "audio/mpeg"
        }
    }
}

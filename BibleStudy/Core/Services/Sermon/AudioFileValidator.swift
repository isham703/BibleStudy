import Foundation
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Audio File Validator
// Validates audio files for import: size, format, and duration

struct AudioFileValidator: Sendable {
    // MARK: - Validation Result

    struct Metadata: Sendable {
        let fileSize: Int
        let duration: TimeInterval
        let format: UTType
    }

    // MARK: - Configuration

    /// Maximum file size in bytes (500 MB)
    static let maxFileSize = 500 * 1024 * 1024

    /// Minimum audio duration in seconds (30s for quality transcription)
    static let minDuration: TimeInterval = 30

    /// Supported audio formats for import
    static let supportedFormats: Set<UTType> = [.mp3, .mpeg4Audio, .wav, .audio]

    // MARK: - Validation

    /// Validate an audio file for import
    /// - Parameter url: The URL of the audio file (may require security scoping)
    /// - Returns: Metadata about the validated file
    /// - Throws: SermonError if validation fails
    static func validate(url: URL) async throws -> Metadata {
        // Capture static properties for use in detached task
        let maxSize = maxFileSize
        let formats = supportedFormats
        let minDur = minDuration

        // Run file IO off the main thread
        return try await Task.detached(priority: .userInitiated) {
            // Access security-scoped resource if needed
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            // 1. Check file size
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])
            let fileSize = resourceValues.fileSize ?? 0

            guard fileSize > 0 else {
                throw SermonError.fileNotFound
            }

            guard fileSize <= maxSize else {
                throw SermonError.fileTooLarge(maxMB: 500)
            }

            // 2. Check format via UTType conformance
            let format: UTType
            if let contentType = resourceValues.contentType {
                // Verify it's a supported audio format
                let isSupported = formats.contains { supportedType in
                    contentType.conforms(to: supportedType)
                }
                guard isSupported else {
                    throw SermonError.unsupportedAudioFormat(contentType.identifier)
                }
                format = contentType
            } else {
                // Fall back to file extension detection
                let pathExtension = url.pathExtension.lowercased()
                switch pathExtension {
                case "mp3":
                    format = .mp3
                case "m4a", "aac":
                    format = .mpeg4Audio
                case "wav":
                    format = .wav
                default:
                    throw SermonError.unsupportedAudioFormat(pathExtension)
                }
            }

            // 3. Get duration using AVAsset
            let asset = AVURLAsset(url: url)
            let duration = try await asset.load(.duration)
            let durationSeconds = CMTimeGetSeconds(duration)

            guard durationSeconds.isFinite && durationSeconds > 0 else {
                throw SermonError.fileCorrupted
            }

            guard durationSeconds >= minDur else {
                throw SermonError.recordingTooShort(
                    durationSeconds: Int(durationSeconds),
                    minimumSeconds: Int(minDur)
                )
            }

            return Metadata(
                fileSize: fileSize,
                duration: durationSeconds,
                format: format
            )
        }.value
    }
}

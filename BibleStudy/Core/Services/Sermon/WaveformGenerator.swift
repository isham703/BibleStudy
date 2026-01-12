import Foundation
import AVFoundation

// MARK: - Waveform Generator
// Generates downsampled waveform samples from audio files for UI visualization

struct WaveformGenerator: Sendable {
    // MARK: - Configuration

    /// Default number of samples for waveform display
    private static let defaultSampleCount = 100

    /// Maximum frames to load at once (avoid memory issues on long files)
    /// 16kHz * 60s = 960,000 frames per minute
    private static let maxFramesPerRead: AVAudioFrameCount = 960_000

    // MARK: - Sample Generation

    /// Generate downsampled waveform samples from an audio file
    /// - Parameters:
    ///   - url: URL of the audio file
    ///   - sampleCount: Number of samples to generate (default 100)
    /// - Returns: Array of normalized amplitude values (0-1)
    /// - Throws: SermonError if file cannot be read
    static func generateSamples(
        from url: URL,
        sampleCount: Int = 100
    ) async throws -> [Float] {
        // Capture constants for use in detached task
        let maxFrames = maxFramesPerRead

        // Run on background thread for performance
        return try await Task.detached(priority: .userInitiated) {
            let file = try AVAudioFile(forReading: url)
            let totalFrames = AVAudioFrameCount(file.length)

            guard totalFrames > 0 else {
                throw SermonError.fileCorrupted
            }

            // For short files, read all at once
            if totalFrames <= maxFrames {
                return try Implementation.generateSamplesFromBuffer(file: file, frameCount: totalFrames, sampleCount: sampleCount)
            }

            // For long files, use streaming approach to avoid memory pressure
            return try Implementation.generateSamplesStreaming(file: file, totalFrames: totalFrames, sampleCount: sampleCount, maxFramesPerRead: maxFrames)
        }.value
    }

    // MARK: - Private Implementation

    /// Namespace for implementation functions to ensure nonisolated context
    private enum Implementation {
        /// Generate samples by reading entire file into buffer (for short files)
        nonisolated static func generateSamplesFromBuffer(
            file: AVAudioFile,
            frameCount: AVAudioFrameCount,
            sampleCount: Int
        ) throws -> [Float] {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frameCount) else {
                throw SermonError.fileCorrupted
            }

            try file.read(into: buffer)

            guard let channelData = buffer.floatChannelData?[0] else {
                throw SermonError.fileCorrupted
            }

            return downsample(channelData: channelData, frameCount: Int(frameCount), targetSamples: sampleCount)
        }

        /// Generate samples by streaming chunks (for long files to avoid memory issues)
        nonisolated static func generateSamplesStreaming(
            file: AVAudioFile,
            totalFrames: AVAudioFrameCount,
            sampleCount: Int,
            maxFramesPerRead: AVAudioFrameCount
        ) throws -> [Float] {
            let framesPerSample = Int(totalFrames) / sampleCount
            var samples: [Float] = []
            samples.reserveCapacity(sampleCount)

            var currentFrame: AVAudioFramePosition = 0
            let bufferSize = min(maxFramesPerRead, totalFrames)

            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: bufferSize) else {
                throw SermonError.fileCorrupted
            }

            var sampleIndex = 0
            var accumulatedRMS: Float = 0
            var framesInCurrentSample = 0

            while currentFrame < Int64(totalFrames) && sampleIndex < sampleCount {
                let framesToRead = min(bufferSize, AVAudioFrameCount(Int64(totalFrames) - currentFrame))

                file.framePosition = currentFrame
                try file.read(into: buffer, frameCount: framesToRead)

                guard let channelData = buffer.floatChannelData?[0] else {
                    throw SermonError.fileCorrupted
                }

                // Process frames in this buffer
                for frameOffset in 0..<Int(framesToRead) {
                    let value = abs(channelData[frameOffset])
                    accumulatedRMS += value * value
                    framesInCurrentSample += 1

                    // Check if we've completed a sample
                    if framesInCurrentSample >= framesPerSample {
                        let rms = sqrt(accumulatedRMS / Float(framesInCurrentSample))
                        samples.append(min(1.0, rms * 2)) // Normalize and cap

                        accumulatedRMS = 0
                        framesInCurrentSample = 0
                        sampleIndex += 1

                        if sampleIndex >= sampleCount {
                            break
                        }
                    }
                }

                currentFrame += Int64(framesToRead)
            }

            // Handle any remaining frames
            if framesInCurrentSample > 0 && sampleIndex < sampleCount {
                let rms = sqrt(accumulatedRMS / Float(framesInCurrentSample))
                samples.append(min(1.0, rms * 2))
            }

            return samples
        }

        /// Downsample channel data to target number of samples using RMS
        nonisolated static func downsample(
            channelData: UnsafePointer<Float>,
            frameCount: Int,
            targetSamples: Int
        ) -> [Float] {
            let framesPerSample = frameCount / targetSamples
            var samples: [Float] = []
            samples.reserveCapacity(targetSamples)

            for i in 0..<targetSamples {
                let startFrame = i * framesPerSample
                let endFrame = min(startFrame + framesPerSample, frameCount)

                var sum: Float = 0
                for frame in startFrame..<endFrame {
                    let value = channelData[frame]
                    sum += value * value // Sum of squares for RMS
                }

                let rms = sqrt(sum / Float(endFrame - startFrame))
                samples.append(min(1.0, rms * 2)) // Normalize and cap at 1.0
            }

            return samples
        }
    }
}

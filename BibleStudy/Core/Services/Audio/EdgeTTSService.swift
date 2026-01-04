//
//  EdgeTTSService.swift
//  BibleStudy
//
//  Microsoft Edge TTS service for high-quality neural text-to-speech.
//  Uses the same voices as Microsoft Edge browser (free, no API key required).
//

import AVFoundation
import Foundation

// MARK: - Edge TTS Service

/// Service for generating speech audio using Microsoft Edge's neural TTS voices.
/// Provides significantly better voice quality than AVSpeechSynthesizer.
actor EdgeTTSService {
    // MARK: - Types

    struct Voice {
        let name: String
        let shortName: String
        let locale: String
        let gender: String

        /// Recommended voices for scripture reading (natural, clear, warm)
        static let recommended: [Voice] = [
            // US English - Recommended for scripture
            Voice(name: "Microsoft Server Speech Text to Speech Voice (en-US, EmmaNeural)",
                  shortName: "en-US-EmmaNeural", locale: "en-US", gender: "Female"),
            Voice(name: "Microsoft Server Speech Text to Speech Voice (en-US, AriaNeural)",
                  shortName: "en-US-AriaNeural", locale: "en-US", gender: "Female"),
            Voice(name: "Microsoft Server Speech Text to Speech Voice (en-US, GuyNeural)",
                  shortName: "en-US-GuyNeural", locale: "en-US", gender: "Male"),
            Voice(name: "Microsoft Server Speech Text to Speech Voice (en-US, JennyNeural)",
                  shortName: "en-US-JennyNeural", locale: "en-US", gender: "Female"),

            // UK English alternatives
            Voice(name: "Microsoft Server Speech Text to Speech Voice (en-GB, SoniaNeural)",
                  shortName: "en-GB-SoniaNeural", locale: "en-GB", gender: "Female"),
            Voice(name: "Microsoft Server Speech Text to Speech Voice (en-GB, RyanNeural)",
                  shortName: "en-GB-RyanNeural", locale: "en-GB", gender: "Male")
        ]

        /// Default voice for scripture reading (Emma - warm, natural US English)
        static let `default` = Voice(
            name: "Microsoft Server Speech Text to Speech Voice (en-US, EmmaNeural)",
            shortName: "en-US-EmmaNeural",
            locale: "en-US",
            gender: "Female"
        )
    }

    struct TTSResult {
        let audioData: Data
        let format: AVAudioFormat
    }

    enum TTSError: LocalizedError {
        case networkUnavailable
        case connectionFailed(String)
        case synthesisTimedOut
        case invalidResponse
        case audioDecodingFailed

        var errorDescription: String? {
            switch self {
            case .networkUnavailable:
                return "No network connection available"
            case .connectionFailed(let reason):
                return "Connection failed: \(reason)"
            case .synthesisTimedOut:
                return "Speech synthesis timed out"
            case .invalidResponse:
                return "Invalid response from TTS service"
            case .audioDecodingFailed:
                return "Failed to decode audio data"
            }
        }
    }

    // MARK: - Properties

    private let voice: Voice
    private let rate: String  // e.g., "-10%" for slower, "+10%" for faster
    private let pitch: String // e.g., "-5Hz" or "+5Hz"

    // Edge TTS WebSocket endpoint
    private let wsEndpoint = "wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1"

    // MARK: - Initialization

    init(voice: Voice = .default, rate: String = "-5%", pitch: String = "+0Hz") {
        self.voice = voice
        self.rate = rate
        self.pitch = pitch
    }

    // MARK: - Public API

    /// Synthesize text to speech audio
    /// - Parameters:
    ///   - text: The text to synthesize
    ///   - timeout: Maximum time to wait for synthesis (default 30 seconds)
    /// - Returns: Audio data in MP3 format
    func synthesize(text: String, timeout: TimeInterval = 30) async throws -> Data {
        // Skip network check - just try directly, fail fast if no connection
        // The WebSocket connection will fail quickly if there's no network
        print("[EdgeTTS] Starting synthesis for text: \(text.prefix(50))...")

        // Generate unique request ID
        let requestId = UUID().uuidString.replacingOccurrences(of: "-", with: "")

        // Build SSML
        let ssml = buildSSML(text: text, requestId: requestId)

        // Connect and synthesize
        return try await withThrowingTaskGroup(of: Data.self) { group in
            group.addTask {
                try await self.performSynthesis(ssml: ssml, requestId: requestId, timeout: timeout)
            }

            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TTSError.synthesisTimedOut
            }

            // Return first successful result or throw first error
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    /// Synthesize multiple verses and return combined audio with timing info
    func synthesizeVerses(_ verses: [(number: Int, text: String)]) async throws -> (data: Data, timings: [VerseTiming]) {
        var combinedData = Data()
        var timings: [VerseTiming] = []
        var currentTime: TimeInterval = 0

        // Approximate duration calculation (Edge TTS is ~150 words per minute at normal speed)
        let wordsPerSecond: Double = 2.5

        for verse in verses {
            // Synthesize individual verse
            let audioData = try await synthesize(text: verse.text)
            combinedData.append(audioData)

            // Calculate approximate timing based on word count
            let wordCount = verse.text.split(separator: " ").count
            let duration = Double(wordCount) / wordsPerSecond

            timings.append(VerseTiming(
                verseNumber: verse.number,
                startTime: currentTime,
                endTime: currentTime + duration
            ))

            currentTime += duration
        }

        return (combinedData, timings)
    }

    // MARK: - Verse-Level Synthesis (HLS Support)

    /// Audio data for a single verse with exact duration
    struct VerseAudio: Sendable {
        let data: Data
        let duration: TimeInterval
    }

    /// Synthesize a single verse and return audio data with exact duration
    /// Used for HLS segment generation
    func synthesizeVerse(text: String, timeout: TimeInterval = 10) async throws -> VerseAudio {
        let audioData = try await synthesize(text: text, timeout: timeout)
        let duration = try extractMP3Duration(from: audioData)

        return VerseAudio(data: audioData, duration: duration)
    }

    /// Extract exact duration from MP3 audio data
    private func extractMP3Duration(from data: Data) throws -> TimeInterval {
        // Write to temp file for AVAudioFile reading
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp3")

        try data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // Read with AVAudioFile to get exact duration
        let audioFile = try AVAudioFile(forReading: tempURL)
        let frameCount = audioFile.length
        let sampleRate = audioFile.fileFormat.sampleRate

        return Double(frameCount) / sampleRate
    }

    // MARK: - Private Methods

    private func isNetworkAvailable() async -> Bool {
        // Simple connectivity check using a lightweight HEAD request
        guard let url = URL(string: "https://speech.platform.bing.com") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    private func buildSSML(text: String, requestId: String) -> String {
        // Escape XML special characters
        let escapedText = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")

        return """
        <speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" \
        xmlns:mstts="https://www.w3.org/2001/mstts" xml:lang="\(voice.locale)">
            <voice name="\(voice.shortName)">
                <prosody rate="\(rate)" pitch="\(pitch)">
                    \(escapedText)
                </prosody>
            </voice>
        </speak>
        """
    }

    private func performSynthesis(ssml: String, requestId: String, timeout: TimeInterval) async throws -> Data {
        // Build WebSocket URL with required parameters
        let trustedClientToken = "6A5AA1D4EAFF4E9FB37E23D68491D6F4"
        let connectionId = UUID().uuidString.replacingOccurrences(of: "-", with: "")

        guard var urlComponents = URLComponents(string: wsEndpoint) else {
            throw TTSError.connectionFailed("Invalid endpoint URL")
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "TrustedClientToken", value: trustedClientToken),
            URLQueryItem(name: "ConnectionId", value: connectionId)
        ]

        guard let url = urlComponents.url else {
            throw TTSError.connectionFailed("Failed to build URL")
        }

        print("[EdgeTTS] Connecting to WebSocket: \(url.absoluteString.prefix(80))...")

        // Create WebSocket connection
        var request = URLRequest(url: url)
        request.setValue("https://www.bing.com", forHTTPHeaderField: "Origin")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")

        // Capture helpers before entering callback closures
        let extractAudio = Self.extractAudioFromBinaryMessage
        let timestamp = Self.getTimestamp

        return try await withCheckedThrowingContinuation { continuation in
            let session = URLSession(configuration: .default)
            let webSocket = session.webSocketTask(with: request)

            var audioData = Data()
            var hasResumed = false

            func receiveMessage() {
                webSocket.receive { result in
                    switch result {
                    case .success(let message):
                        switch message {
                        case .string(let text):
                            // Check for turn.end marker
                            if text.contains("turn.end") {
                                print("[EdgeTTS] Received turn.end, audio size: \(audioData.count) bytes")
                                webSocket.cancel(with: .normalClosure, reason: nil)
                                if !hasResumed {
                                    hasResumed = true
                                    continuation.resume(returning: audioData)
                                }
                            } else {
                                receiveMessage()
                            }

                        case .data(let data):
                            // Extract audio from binary message
                            // Edge TTS binary format: header (variable) + audio data
                            if let audioChunk = extractAudio(data) {
                                audioData.append(audioChunk)
                            }
                            receiveMessage()

                        @unknown default:
                            receiveMessage()
                        }

                    case .failure(let error):
                        print("[EdgeTTS] WebSocket error: \(error.localizedDescription)")
                        webSocket.cancel(with: .abnormalClosure, reason: nil)
                        if !hasResumed {
                            hasResumed = true
                            continuation.resume(throwing: TTSError.connectionFailed(error.localizedDescription))
                        }
                    }
                }
            }

            // Send configuration message
            let configMessage = """
            X-Timestamp:\(timestamp())\r
            Content-Type:application/json; charset=utf-8\r
            Path:speech.config\r
            \r
            {"context":{"synthesis":{"audio":{"metadataoptions":{"sentenceBoundaryEnabled":"false","wordBoundaryEnabled":"false"},"outputFormat":"audio-24khz-96kbitrate-mono-mp3"}}}}
            """

            // Send SSML message
            let ssmlMessage = """
            X-RequestId:\(requestId)\r
            Content-Type:application/ssml+xml\r
            X-Timestamp:\(timestamp())\r
            Path:ssml\r
            \r
            \(ssml)
            """

            webSocket.resume()
            print("[EdgeTTS] WebSocket resumed, waiting for messages...")
            receiveMessage()

            webSocket.send(.string(configMessage)) { error in
                if let error = error {
                    print("[EdgeTTS] Failed to send config: \(error.localizedDescription)")
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(throwing: TTSError.connectionFailed(error.localizedDescription))
                    }
                    return
                }
                print("[EdgeTTS] Config message sent successfully")

                webSocket.send(.string(ssmlMessage)) { error in
                    if let error = error {
                        print("[EdgeTTS] Failed to send SSML: \(error.localizedDescription)")
                        if !hasResumed {
                            hasResumed = true
                            continuation.resume(throwing: TTSError.connectionFailed(error.localizedDescription))
                        }
                    } else {
                        print("[EdgeTTS] SSML message sent successfully")
                    }
                }
            }
        }
    }

    private static func extractAudioFromBinaryMessage(_ data: Data) -> Data? {
        // Edge TTS binary message format:
        // - 2 bytes: header length (big endian)
        // - N bytes: header (text)
        // - Remaining: audio data

        guard data.count > 2 else { return nil }

        let headerLength = Int(data[0]) << 8 | Int(data[1])
        guard data.count > headerLength + 2 else { return nil }

        // Skip header, return audio data
        return data.subdata(in: (headerLength + 2)..<data.count)
    }

    private static func getTimestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }
}

// MARK: - Edge TTS Voice Selection

extension EdgeTTSService.Voice {
    /// Get voice by preference
    static func voice(gender: String = "Female", locale: String = "en-US") -> EdgeTTSService.Voice {
        recommended.first {
            $0.gender == gender && $0.locale == locale
        } ?? .default
    }
}

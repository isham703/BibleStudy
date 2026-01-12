//
//  EdgeTTSService.swift
//  BibleStudy
//
//  Microsoft Edge TTS service for high-quality neural text-to-speech.
//  Uses the same voices as Microsoft Edge browser (free, no API key required).
//

import AVFoundation
import CommonCrypto
import Foundation
import Starscream

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
        print("[EdgeTTS] Starting synthesis for text: \(text.prefix(50))...")

        // Generate unique request ID
        let requestId = UUID().uuidString.replacingOccurrences(of: "-", with: "")

        // Build SSML
        let ssml = buildSSML(text: text, requestId: requestId)

        // Connect and synthesize with timeout
        return try await withThrowingTaskGroup(of: Data.self) { group in
            group.addTask {
                try await self.performSynthesis(ssml: ssml, requestId: requestId)
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

    private func performSynthesis(ssml: String, requestId: String) async throws -> Data {
        // Build WebSocket URL with required parameters
        // Note: Sec-MS-GEC must be passed as a URL query parameter, not as HTTP header
        let trustedClientToken = "6A5AA1D4EAFF4E9FB37E23D68491D6F4"
        let connectionId = UUID().uuidString.replacingOccurrences(of: "-", with: "").uppercased()

        // Compute Sec-MS-GEC security token (required by Microsoft)
        let secMsGec = Self.computeSecMsGec(trustedClientToken: trustedClientToken)
        let secMsGecVersion = "1-143.0.3650.75"
        print("[EdgeTTS] Sec-MS-GEC: \(secMsGec), Version: \(secMsGecVersion)")

        guard var urlComponents = URLComponents(string: wsEndpoint) else {
            throw TTSError.connectionFailed("Invalid endpoint URL")
        }

        // Pass security tokens as query parameters (matching python edge-tts implementation)
        urlComponents.queryItems = [
            URLQueryItem(name: "TrustedClientToken", value: trustedClientToken),
            URLQueryItem(name: "ConnectionId", value: connectionId),
            URLQueryItem(name: "Sec-MS-GEC", value: secMsGec),
            URLQueryItem(name: "Sec-MS-GEC-Version", value: secMsGecVersion)
        ]

        guard let url = urlComponents.url else {
            throw TTSError.connectionFailed("Failed to build URL")
        }

        // Create URLRequest with headers (matching Chrome extension origin used by edge-tts)
        var request = URLRequest(url: url)
        request.setValue("chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold", forHTTPHeaderField: "Origin")
        request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.3650.75", forHTTPHeaderField: "User-Agent")

        // Capture immutable copy for Swift 6 concurrency safety
        let finalRequest = request

        // Use Starscream WebSocket with custom engine
        // Must dispatch to MainActor for WebSocketDelegate conformance
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let engine = WSEngine(
                    transport: TCPTransport(),
                    certPinner: nil,
                    headerValidator: FoundationSecurity()
                )
                let socket = WebSocket(request: finalRequest, engine: engine)
                let handler = EdgeTTSWebSocketHandler(
                    socket: socket,
                    ssml: ssml,
                    requestId: requestId,
                    continuation: continuation
                )
                socket.delegate = handler

                print("[EdgeTTS] Connecting via Starscream WebSocket...")
                socket.connect()
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

    nonisolated static func getTimestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }

    /// Compute the Sec-MS-GEC security header required by Microsoft Edge TTS
    /// This is a SHA256 hash of Windows FILETIME (rounded to 5 min) + TrustedClientToken
    static func computeSecMsGec(trustedClientToken: String) -> String {
        // Windows FILETIME epoch: January 1, 1601
        // Unix epoch: January 1, 1970
        // Difference in seconds: 11644473600
        let windowsEpochDiff: Int64 = 11_644_473_600

        // Get current Unix timestamp in seconds
        let unixTimestamp = Int64(Date().timeIntervalSince1970)

        // Convert to Windows FILETIME (100-nanosecond intervals since 1601)
        let windowsTime = (unixTimestamp + windowsEpochDiff) * 10_000_000

        // Round down to nearest 5 minutes (300 seconds = 3_000_000_000 100-ns intervals)
        let roundedTime = windowsTime - (windowsTime % 3_000_000_000)

        // Create the string to hash: "roundedTimetrustedClientToken" (no space!)
        let stringToHash = "\(roundedTime)\(trustedClientToken)"

        // Compute SHA256 hash
        guard let data = stringToHash.data(using: .utf8) else {
            return ""
        }

        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }

        // Convert to uppercase hex string
        return hash.map { String(format: "%02X", $0) }.joined()
    }
}

// MARK: - Starscream WebSocket Handler

/// Handles Starscream WebSocket events for Edge TTS synthesis.
/// Uses self-retention to prevent deallocation before continuation is resumed.
/// Must be @MainActor to satisfy WebSocketDelegate protocol requirements.
@MainActor
private final class EdgeTTSWebSocketHandler: WebSocketDelegate {
    private let ssml: String
    private let requestId: String
    private let continuation: CheckedContinuation<Data, Error>
    private var audioData = Data()
    private var hasResumed = false

    // Strong reference to socket keeps it alive during synthesis
    private let socket: Starscream.WebSocket

    // Self-retention: prevents handler from being deallocated until completion
    // swiftlint:disable:next identifier_name
    private var _retainedSelf: EdgeTTSWebSocketHandler?

    init(socket: Starscream.WebSocket, ssml: String, requestId: String, continuation: CheckedContinuation<Data, Error>) {
        self.socket = socket
        self.ssml = ssml
        self.requestId = requestId
        self.continuation = continuation

        // Retain self until continuation is resumed
        _retainedSelf = self
    }

    func didReceive(event: WebSocketEvent, client: any WebSocketClient) {
        switch event {
        case .connected:
            print("[EdgeTTS] WebSocket connected, sending config...")
            sendConfigAndSSML()

        case .disconnected(let reason, let code):
            print("[EdgeTTS] WebSocket disconnected: \(reason) (code: \(code))")
            resumeWithError(EdgeTTSService.TTSError.connectionFailed("Disconnected: \(reason)"))

        case .text(let text):
            // Check for turn.end marker
            if text.contains("turn.end") {
                print("[EdgeTTS] Received turn.end, audio size: \(audioData.count) bytes")
                socket.disconnect()
                resumeWithSuccess(audioData)
            }

        case .binary(let data):
            // Extract audio from binary message
            if let audioChunk = extractAudioFromBinaryMessage(data) {
                audioData.append(audioChunk)
            }

        case .error(let error):
            print("[EdgeTTS] WebSocket error: \(error?.localizedDescription ?? "unknown")")
            let errorMessage = error?.localizedDescription ?? "Unknown WebSocket error"
            resumeWithError(EdgeTTSService.TTSError.connectionFailed(errorMessage))

        case .cancelled:
            print("[EdgeTTS] WebSocket cancelled")
            resumeWithError(EdgeTTSService.TTSError.connectionFailed("Connection cancelled"))

        case .viabilityChanged, .reconnectSuggested, .peerClosed, .pong, .ping:
            break
        }
    }

    private func resumeWithSuccess(_ data: Data) {
        guard !hasResumed else { return }
        hasResumed = true
        _retainedSelf = nil  // Release self-retention
        continuation.resume(returning: data)
    }

    private func resumeWithError(_ error: Error) {
        guard !hasResumed else { return }
        hasResumed = true
        _retainedSelf = nil  // Release self-retention
        continuation.resume(throwing: error)
    }

    private func sendConfigAndSSML() {
        let timestamp = EdgeTTSService.getTimestamp()

        // Send configuration message
        let configMessage = """
        X-Timestamp:\(timestamp)\r
        Content-Type:application/json; charset=utf-8\r
        Path:speech.config\r
        \r
        {"context":{"synthesis":{"audio":{"metadataoptions":{"sentenceBoundaryEnabled":"false","wordBoundaryEnabled":"false"},"outputFormat":"audio-24khz-96kbitrate-mono-mp3"}}}}
        """

        socket.write(string: configMessage) {
            print("[EdgeTTS] Config message sent")
        }

        // Send SSML message
        let ssmlMessage = """
        X-RequestId:\(requestId)\r
        Content-Type:application/ssml+xml\r
        X-Timestamp:\(timestamp)\r
        Path:ssml\r
        \r
        \(ssml)
        """

        socket.write(string: ssmlMessage) {
            print("[EdgeTTS] SSML message sent")
        }
    }

    private func extractAudioFromBinaryMessage(_ data: Data) -> Data? {
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

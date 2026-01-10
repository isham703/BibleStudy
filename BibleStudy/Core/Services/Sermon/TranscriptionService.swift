import Foundation

// MARK: - Transcription Output
// Result from Whisper API transcription
struct TranscriptionOutput: Codable, Sendable {
    let text: String
    let language: String
    let duration: Double
    let segments: [TranscriptionSegment]

    struct TranscriptionSegment: Codable, Sendable {
        let id: Int
        let start: Double
        let end: Double
        let text: String
        let tokens: [Int]?
        let temperature: Double?
        let avgLogprob: Double?
        let compressionRatio: Double?
        let noSpeechProb: Double?

        enum CodingKeys: String, CodingKey {
            case id, start, end, text, tokens, temperature
            case avgLogprob = "avg_logprob"
            case compressionRatio = "compression_ratio"
            case noSpeechProb = "no_speech_prob"
        }
    }

    /// Convert to word timestamps for SermonTranscript
    var wordTimestamps: [SermonTranscript.WordTimestamp] {
        // Whisper segments contain phrases, not individual words
        // Estimate word timings within each segment
        var timestamps: [SermonTranscript.WordTimestamp] = []

        for segment in segments {
            let words = segment.text.trimmingCharacters(in: .whitespaces)
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }

            guard !words.isEmpty else { continue }

            let segmentDuration = segment.end - segment.start
            let timePerWord = segmentDuration / Double(words.count)

            for (index, word) in words.enumerated() {
                let start = segment.start + (Double(index) * timePerWord)
                let end = start + timePerWord

                timestamps.append(SermonTranscript.WordTimestamp(
                    word: word,
                    start: start,
                    end: end
                ))
            }
        }

        return timestamps
    }
}

// MARK: - Transcription Input
struct TranscriptionInput: Sendable {
    let audioURL: URL
    let language: String?
    let prompt: String?

    init(audioURL: URL, language: String? = "en", prompt: String? = nil) {
        self.audioURL = audioURL
        self.language = language
        self.prompt = prompt
    }
}

// MARK: - Transcription Service
// Handles audio transcription via OpenAI Whisper API

final class TranscriptionService: Sendable {
    // MARK: - Singleton
    static let shared = TranscriptionService()

    // MARK: - Configuration
    private let apiEndpoint = "https://api.openai.com/v1/audio/transcriptions"
    private let model = "whisper-1"
    private let maxFileSize = 25 * 1024 * 1024  // 25MB Whisper limit

    // MARK: - Initialization
    private init() {}

    // MARK: - Single File Transcription

    /// Transcribe a single audio file
    /// - Parameters:
    ///   - input: Transcription input with audio URL and options
    ///   - onProgress: Progress callback (0-1)
    /// - Returns: Transcription output with text and timestamps
    func transcribe(
        input: TranscriptionInput,
        onProgress: ((Double) -> Void)? = nil
    ) async throws -> TranscriptionOutput {
        // Validate file exists and size
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: input.audioURL.path)
        guard let fileSize = fileAttributes[.size] as? Int else {
            throw SermonError.fileNotFound
        }

        if fileSize > maxFileSize {
            throw SermonError.fileTooLarge(maxMB: 25)
        }

        onProgress?(0.1)

        // Read audio data
        let audioData = try Data(contentsOf: input.audioURL)

        onProgress?(0.2)

        // Build multipart form request
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(getAPIKey())", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Build form body
        var body = Data()

        // Add file
        let filename = input.audioURL.lastPathComponent
        let mimeType = mimeTypeForExtension(input.audioURL.pathExtension)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // Add model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(model)\r\n".data(using: .utf8)!)

        // Add response format (verbose_json for timestamps)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("verbose_json\r\n".data(using: .utf8)!)

        // Add timestamp granularities
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"timestamp_granularities[]\"\r\n\r\n".data(using: .utf8)!)
        body.append("segment\r\n".data(using: .utf8)!)

        // Add language if specified
        if let language = input.language {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(language)\r\n".data(using: .utf8)!)
        }

        // Add prompt if specified (helps with context)
        if let prompt = input.prompt {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(prompt)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        onProgress?(0.3)

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SermonError.transcriptionFailed("Invalid response")
        }

        onProgress?(0.9)

        // Handle errors
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw SermonError.transcriptionFailed(errorResponse.error.message)
            }
            throw SermonError.transcriptionFailed("HTTP \(httpResponse.statusCode)")
        }

        // Decode response
        let decoder = JSONDecoder()
        let output = try decoder.decode(TranscriptionOutput.self, from: data)

        onProgress?(1.0)

        return output
    }

    // MARK: - Multi-Chunk Transcription

    /// Transcribe multiple audio chunks and merge results
    /// - Parameters:
    ///   - chunkURLs: Array of audio chunk URLs in order
    ///   - onProgress: Progress callback (0-1) across all chunks
    /// - Returns: Merged transcription output
    func transcribeChunks(
        chunkURLs: [URL],
        onProgress: ((Double) -> Void)? = nil
    ) async throws -> TranscriptionOutput {
        guard !chunkURLs.isEmpty else {
            throw SermonError.transcriptionFailed("No chunks to transcribe")
        }

        var allSegments: [TranscriptionOutput.TranscriptionSegment] = []
        var allText: [String] = []
        var totalDuration: Double = 0
        var detectedLanguage = "en"
        var currentOffset: Double = 0

        for (index, chunkURL) in chunkURLs.enumerated() {
            let chunkProgress = Double(index) / Double(chunkURLs.count)

            // Transcribe this chunk
            let input = TranscriptionInput(
                audioURL: chunkURL,
                language: detectedLanguage,
                prompt: allText.suffix(3).joined(separator: " ")  // Use recent text as context
            )

            let output = try await transcribe(input: input) { progress in
                let overallProgress = (chunkProgress + progress / Double(chunkURLs.count))
                onProgress?(overallProgress)
            }

            // Update detected language from first chunk
            if index == 0 {
                detectedLanguage = output.language
            }

            // Offset segment timestamps
            let offsetSegments = output.segments.map { segment in
                TranscriptionOutput.TranscriptionSegment(
                    id: allSegments.count + segment.id,
                    start: segment.start + currentOffset,
                    end: segment.end + currentOffset,
                    text: segment.text,
                    tokens: segment.tokens,
                    temperature: segment.temperature,
                    avgLogprob: segment.avgLogprob,
                    compressionRatio: segment.compressionRatio,
                    noSpeechProb: segment.noSpeechProb
                )
            }

            allSegments.append(contentsOf: offsetSegments)
            allText.append(output.text)
            currentOffset += output.duration
            totalDuration += output.duration

            print("[TranscriptionService] Chunk \(index + 1)/\(chunkURLs.count) complete: \(output.segments.count) segments, \(String(format: "%.1f", output.duration))s")
        }

        onProgress?(1.0)

        return TranscriptionOutput(
            text: allText.joined(separator: " "),
            language: detectedLanguage,
            duration: totalDuration,
            segments: allSegments
        )
    }

    // MARK: - Helpers

    private func getAPIKey() -> String {
        // Get API key from Configuration
        // This should be stored securely in production
        return AppConfiguration.AI.openAIKey
    }

    private func mimeTypeForExtension(_ ext: String) -> String {
        switch ext.lowercased() {
        case "mp3": return "audio/mpeg"
        case "mp4", "m4a": return "audio/mp4"
        case "wav": return "audio/wav"
        case "webm": return "audio/webm"
        case "mpeg", "mpga": return "audio/mpeg"
        default: return "audio/mp4"
        }
    }
}

// MARK: - OpenAI Error Response
private struct OpenAIErrorResponse: Codable {
    let error: OpenAIError

    struct OpenAIError: Codable {
        let message: String
        let type: String
        let param: String?
        let code: String?
    }
}

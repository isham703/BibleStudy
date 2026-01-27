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

        // Build form body with pre-allocated capacity to minimize memory reallocations
        let body = buildMultipartBody(
            audioData: audioData,
            filename: input.audioURL.lastPathComponent,
            mimeType: mimeTypeForExtension(input.audioURL.pathExtension),
            boundary: boundary,
            model: model,
            language: input.language,
            prompt: input.prompt
        )

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
    ///   - sermonTitle: Optional sermon title for dynamic glossary boosting
    ///   - onProgress: Progress callback (0-1) across all chunks
    /// - Returns: Merged transcription output
    func transcribeChunks(
        chunkURLs: [URL],
        sermonTitle: String? = nil,
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

        // Use dynamic glossary if sermon title is provided
        let promptBuilder: WhisperPromptBuilder
        if let title = sermonTitle, !title.isEmpty {
            promptBuilder = WhisperPromptBuilder.forSermon(title: title)
            print("[TranscriptionService] Using dynamic glossary for: \(title)")
        } else {
            promptBuilder = WhisperPromptBuilder.default
        }

        for (index, chunkURL) in chunkURLs.enumerated() {
            let chunkProgress = Double(index) / Double(chunkURLs.count)

            // Build prompt with recent context + biblical glossary
            let recentSegments = Array(allText.suffix(3))
            let prompt = promptBuilder.buildPrompt(recentSegments: recentSegments)

            let input = TranscriptionInput(
                audioURL: chunkURL,
                language: detectedLanguage,
                prompt: prompt
            )

            let output = try await transcribe(input: input) { progress in
                let overallProgress = (chunkProgress + progress / Double(chunkURLs.count))
                onProgress?(overallProgress)
            }

            // Update detected language from first chunk (normalize to ISO-639-1)
            if index == 0 {
                detectedLanguage = normalizeLanguageCode(output.language)
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

    /// Normalize language from Whisper output to ISO-639-1 code
    /// Whisper returns full language names ("english") but the API expects ISO-639-1 codes ("en")
    private func normalizeLanguageCode(_ language: String) -> String {
        let lowercased = language.lowercased().trimmingCharacters(in: .whitespaces)

        // Map common full language names to ISO-639-1 codes
        let languageMap: [String: String] = [
            "english": "en",
            "spanish": "es",
            "french": "fr",
            "german": "de",
            "italian": "it",
            "portuguese": "pt",
            "dutch": "nl",
            "russian": "ru",
            "chinese": "zh",
            "japanese": "ja",
            "korean": "ko",
            "arabic": "ar",
            "hindi": "hi",
            "turkish": "tr",
            "polish": "pl",
            "ukrainian": "uk",
            "greek": "el",
            "hebrew": "he",
            "swedish": "sv",
            "norwegian": "no",
            "danish": "da",
            "finnish": "fi",
            "czech": "cs",
            "romanian": "ro",
            "hungarian": "hu",
            "indonesian": "id",
            "vietnamese": "vi",
            "thai": "th",
            "malay": "ms",
            "tagalog": "tl",
            "swahili": "sw"
        ]

        // Return mapped code if found, otherwise return as-is (might already be ISO code)
        return languageMap[lowercased] ?? lowercased
    }

    /// Build multipart form body with pre-allocated capacity
    /// Reduces memory peak from ~52MB to ~30MB for 25MB audio files
    private func buildMultipartBody(
        audioData: Data,
        filename: String,
        mimeType: String,
        boundary: String,
        model: String,
        language: String?,
        prompt: String?
    ) -> Data {
        // Reserve capacity: audio + ~2KB for form fields and boundaries
        var body = Data()
        body.reserveCapacity(audioData.count + 2048)

        // Add file
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
        if let language = language {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(language)\r\n".data(using: .utf8)!)
        }

        // Add prompt if specified (helps with context)
        if let prompt = prompt {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(prompt)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        return body
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

// MARK: - Whisper Prompt Builder

/// Builds Whisper API prompts with biblical glossary and context budget management.
/// Ensures glossary is always fully included and total prompt stays within token limits.
struct WhisperPromptBuilder {
    let glossary: String
    let maxPromptChars: Int
    let glossaryBudgetChars: Int
    let contextBudgetChars: Int

    // nonisolated(unsafe) allows use as default parameter in @MainActor contexts
    nonisolated(unsafe) static let `default` = WhisperPromptBuilder()

    /// Initialize with SermonConfiguration defaults
    private init() {
        self.glossary = SermonConfiguration.biblicalGlossaryPrompt
        self.maxPromptChars = SermonConfiguration.maxPromptChars
        self.glossaryBudgetChars = SermonConfiguration.glossaryBudgetChars
        self.contextBudgetChars = SermonConfiguration.contextBudgetChars
    }

    /// Create a prompt builder with dynamic glossary based on sermon title.
    /// Extracts Bible book references from the title and customizes the glossary
    /// to prioritize terms related to those books.
    /// - Parameter sermonTitle: The sermon title to analyze for book references
    /// - Returns: A WhisperPromptBuilder with customized glossary for the sermon
    static func forSermon(title sermonTitle: String) -> WhisperPromptBuilder {
        let dynamicGlossary = BiblicalContextProvider.glossaryPrompt(forSermonTitle: sermonTitle)
        return WhisperPromptBuilder(
            glossary: dynamicGlossary,
            maxPromptChars: SermonConfiguration.maxPromptChars,
            glossaryBudgetChars: SermonConfiguration.glossaryBudgetChars,
            contextBudgetChars: SermonConfiguration.contextBudgetChars
        )
    }

    /// Initialize with custom values (for testing)
    /// - Parameters:
    ///   - glossary: Biblical glossary text for Whisper prompting
    ///   - maxPromptChars: Maximum total prompt characters
    ///   - glossaryBudgetChars: Characters reserved for glossary
    ///   - contextBudgetChars: Characters available for context
    init(glossary: String, maxPromptChars: Int, glossaryBudgetChars: Int, contextBudgetChars: Int) {
        precondition(glossaryBudgetChars <= maxPromptChars, "glossaryBudgetChars must be <= maxPromptChars")
        precondition(glossary.count <= glossaryBudgetChars, "glossary (\(glossary.count) chars) exceeds glossaryBudgetChars (\(glossaryBudgetChars))")
        precondition(contextBudgetChars >= 0, "contextBudgetChars must be >= 0")

        self.glossary = glossary
        self.maxPromptChars = maxPromptChars
        self.glossaryBudgetChars = glossaryBudgetChars
        self.contextBudgetChars = contextBudgetChars
    }

    /// Build prompt from recent transcript segments.
    /// - Parameter recentSegments: Recent transcript text segments for context
    /// - Returns: Combined prompt with context + glossary, respecting budget limits
    func buildPrompt(recentSegments: [String]) -> String {
        let recentContext = recentSegments.joined(separator: " ")
        return buildPrompt(context: recentContext)
    }

    /// Build prompt from a context string.
    /// - Parameter context: Recent transcript text for context
    /// - Returns: Combined prompt with context + glossary, respecting budget limits
    func buildPrompt(context: String) -> String {
        // Trim context to budget (take suffix to preserve most recent words)
        let contextTrimmed: String
        if context.count > contextBudgetChars {
            contextTrimmed = String(context.suffix(contextBudgetChars))
        } else {
            contextTrimmed = context
        }

        // Build prompt: context + space + glossary
        if contextTrimmed.isEmpty {
            return glossary
        } else {
            return "\(contextTrimmed) \(glossary)"
        }
    }

    /// Validate that glossary fits within budget (design-time check)
    var isGlossaryWithinBudget: Bool {
        glossary.count <= glossaryBudgetChars
    }

    /// Validate that a built prompt fits within max chars
    func isWithinBudget(_ prompt: String) -> Bool {
        prompt.count <= maxPromptChars
    }
}

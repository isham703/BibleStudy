import Foundation

// MARK: - OpenAI Provider
// Implementation of AIServiceProtocol using OpenAI API

final class OpenAIProvider: AIServiceProtocol {
    // MARK: - Properties
    private let apiKey: String
    private let baseURL = URL(string: "https://api.openai.com/v1")!
    private let rateLimiter: RateLimiter
    private let session: URLSession

    var isAvailable: Bool {
        !apiKey.isEmpty
    }

    // MARK: - Initialization
    init(apiKey: String = AppConfiguration.AI.openAIKey) {
        self.apiKey = apiKey
        self.rateLimiter = RateLimiter(
            maxRequests: AppConfiguration.AI.requestsPerMinute,
            timeWindow: 60
        )

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - API Methods

    func generateQuickInsight(verseRange: VerseRange, verseText: String) async throws -> QuickInsightOutput {
        try await rateLimiter.checkLimit()

        let prompt = PromptTemplates.quickInsight(
            verseText: verseText,
            reference: verseRange.reference
        )

        let response = try await callChatCompletion(
            prompt: prompt,
            systemPrompt: PromptTemplates.systemPromptQuickInsight,
            model: AppConfiguration.AI.defaultModel,
            maxTokens: 150  // Keep responses short
        )

        // Strip markdown code fences if present
        let cleanedResponse = Self.stripMarkdownCodeFences(response)

        // Try to parse as JSON, fall back to plain text summary
        if let jsonData = cleanedResponse.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(QuickInsightOutput.self, from: jsonData) {
            return parsed
        }

        // Fallback: use response as plain summary
        return QuickInsightOutput(
            summary: cleanedResponse,
            keyTerm: nil,
            keyTermMeaning: nil,
            suggestedAction: .explainMore
        )
    }

    func generateExplanation(input: ExplanationInput) async throws -> ExplanationOutput {
        try await rateLimiter.checkLimit()

        let prompt = PromptTemplates.explanation(
            verseText: input.verseText,
            reference: input.verseRange.reference,
            context: input.surroundingContext,
            mode: input.mode
        )

        let response = try await callChatCompletion(
            prompt: prompt,
            systemPrompt: PromptTemplates.systemPromptExplanation,
            model: AppConfiguration.AI.defaultModel
        )

        // Parse response into structured output
        // Strip markdown code fences if present
        let cleanedResponse = Self.stripMarkdownCodeFences(response)

        // Try to parse JSON, fall back to plain text
        if let data = cleanedResponse.data(using: .utf8),
           let json = try? JSONDecoder().decode(ExplanationOutput.self, from: data) {
            return json
        }

        // Fall back to plain text response
        return ExplanationOutput(
            explanation: cleanedResponse,
            keyPoints: nil,
            relatedVerses: nil,
            historicalContext: nil,
            applicationPoints: nil,
            uncertaintyNotes: nil,
            reasoning: nil,
            translationNotes: nil
        )
    }

    /// Strips markdown code fences (```json ... ```) from AI responses
    private static func stripMarkdownCodeFences(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove opening code fence with optional language identifier
        if result.hasPrefix("```") {
            if let newlineIndex = result.firstIndex(of: "\n") {
                result = String(result[result.index(after: newlineIndex)...])
            }
        }

        // Remove closing code fence
        if result.hasSuffix("```") {
            result = String(result.dropLast(3))
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func generateWhyLinked(source: VerseRange, target: VerseRange, context: String?) async throws -> String {
        try await rateLimiter.checkLimit()

        let prompt = PromptTemplates.whyLinked(
            sourceReference: source.reference,
            targetReference: target.reference,
            context: context
        )

        return try await callChatCompletion(
            prompt: prompt,
            systemPrompt: PromptTemplates.systemPromptCrossRef,
            model: AppConfiguration.AI.defaultModel
        )
    }

    func generateTermExplanation(lemma: String, morph: String, verseContext: String) async throws -> String {
        try await rateLimiter.checkLimit()

        let prompt = PromptTemplates.termExplanation(
            lemma: lemma,
            morphology: morph,
            verseContext: verseContext
        )

        return try await callChatCompletion(
            prompt: prompt,
            systemPrompt: PromptTemplates.systemPromptLanguage,
            model: AppConfiguration.AI.defaultModel
        )
    }

    func generateInterpretation(input: InterpretationInput) async throws -> InterpretationOutput {
        try await rateLimiter.checkLimit()

        let prompt = PromptTemplates.interpretation(
            verseText: input.verseText,
            reference: input.verseRange.reference,
            context: input.surroundingContext,
            mode: input.mode,
            includeReflection: input.includeReflection
        )

        let response = try await callChatCompletion(
            prompt: prompt,
            systemPrompt: PromptTemplates.systemPromptInterpretation,
            model: AppConfiguration.AI.advancedModel
        )

        // Strip markdown code fences if present
        let cleanedResponse = Self.stripMarkdownCodeFences(response)

        // Parse structured response
        // Try to parse JSON, fall back to plain text
        if let data = cleanedResponse.data(using: .utf8),
           let json = try? JSONDecoder().decode(InterpretationOutput.self, from: data) {
            return json
        }

        // Fall back to plain text response
        return InterpretationOutput(
            plainMeaning: cleanedResponse,
            context: "",
            keyTerms: [],
            crossReferences: [],
            interpretationNotes: "",
            reflectionPrompt: input.includeReflection ? "" : nil,
            hasDebatedInterpretations: false,
            uncertaintyIndicators: nil,
            reasoning: nil,
            alternativeViews: nil
        )
    }

    // MARK: - Comprehension Features (Phase 5)

    func simplifyPassage(verseRange: VerseRange, verseText: String, level: ReadingLevel) async throws -> SimplifiedPassageOutput {
        try await rateLimiter.checkLimit()

        let prompt = PromptTemplates.simplifyPassage(
            verseText: verseText,
            reference: verseRange.reference,
            level: level
        )

        let response = try await callChatCompletion(
            prompt: prompt,
            systemPrompt: PromptTemplates.systemPromptComprehension,
            model: AppConfiguration.AI.defaultModel
        )

        let cleanedResponse = Self.stripMarkdownCodeFences(response)

        if let data = cleanedResponse.data(using: .utf8),
           let json = try? JSONDecoder().decode(SimplifiedPassageOutput.self, from: data) {
            return json
        }

        // Fallback
        return SimplifiedPassageOutput(
            simplified: cleanedResponse,
            keyTermsExplained: nil,
            oneLineSummary: ""
        )
    }

    func summarizePassage(verseRange: VerseRange, verseText: String) async throws -> PassageSummaryOutput {
        try await rateLimiter.checkLimit()

        let prompt = PromptTemplates.summarizePassage(
            verseText: verseText,
            reference: verseRange.reference
        )

        let response = try await callChatCompletion(
            prompt: prompt,
            systemPrompt: PromptTemplates.systemPromptComprehension,
            model: AppConfiguration.AI.defaultModel,
            maxTokens: 200
        )

        let cleanedResponse = Self.stripMarkdownCodeFences(response)

        if let data = cleanedResponse.data(using: .utf8),
           let json = try? JSONDecoder().decode(PassageSummaryOutput.self, from: data) {
            return json
        }

        // Fallback
        return PassageSummaryOutput(
            summary: cleanedResponse,
            theme: "",
            whatHappened: nil
        )
    }

    func generateComprehensionQuestions(verseRange: VerseRange, verseText: String, passageType: PassageType) async throws -> ComprehensionQuestionsOutput {
        try await rateLimiter.checkLimit()

        let prompt = PromptTemplates.generateComprehensionQuestions(
            verseText: verseText,
            reference: verseRange.reference,
            passageType: passageType
        )

        let response = try await callChatCompletion(
            prompt: prompt,
            systemPrompt: PromptTemplates.systemPromptComprehension,
            model: AppConfiguration.AI.defaultModel
        )

        let cleanedResponse = Self.stripMarkdownCodeFences(response)

        if let data = cleanedResponse.data(using: .utf8),
           let json = try? JSONDecoder().decode(ComprehensionQuestionsOutput.self, from: data) {
            return json
        }

        // Fallback with sample questions
        return ComprehensionQuestionsOutput(
            questions: [
                .init(id: "1", question: "What is the main point of this passage?", type: "observation", hint: "Look for the key action or statement."),
                .init(id: "2", question: "Why is this significant?", type: "interpretation", hint: "Consider the context."),
                .init(id: "3", question: "How might this apply to your life?", type: "application", hint: "Think about practical relevance.")
            ],
            passageType: passageType.rawValue
        )
    }

    func clarifyPhrase(phrase: String, verseRange: VerseRange, verseText: String) async throws -> PhraseClarificationOutput {
        try await rateLimiter.checkLimit()

        let prompt = PromptTemplates.clarifyPhrase(
            phrase: phrase,
            verseText: verseText,
            reference: verseRange.reference
        )

        let response = try await callChatCompletion(
            prompt: prompt,
            systemPrompt: PromptTemplates.systemPromptComprehension,
            model: AppConfiguration.AI.defaultModel,
            maxTokens: 300
        )

        let cleanedResponse = Self.stripMarkdownCodeFences(response)

        if let data = cleanedResponse.data(using: .utf8),
           let json = try? JSONDecoder().decode(PhraseClarificationOutput.self, from: data) {
            return json
        }

        // Fallback
        return PhraseClarificationOutput(
            clarification: cleanedResponse,
            simpleVersion: "",
            whyItMatters: ""
        )
    }

    // MARK: - Story Generation

    func generateStory(input: StoryGenerationInput) async throws -> StoryGenerationOutput {
        try await rateLimiter.checkLimit()

        let prompt = PromptTemplates.generateStory(
            verseText: input.verseText,
            reference: input.verseRange.reference,
            bookId: input.verseRange.bookId,
            chapter: input.verseRange.chapter,
            verseStart: input.verseRange.verseStart,
            verseEnd: input.verseRange.verseEnd,
            storyType: input.storyType,
            readingLevel: input.readingLevel
        )

        // Use gpt-4o for story generation (higher quality narratives)
        let response = try await callChatCompletion(
            prompt: prompt,
            systemPrompt: PromptTemplates.systemPromptStoryGeneration,
            model: AppConfiguration.AI.advancedModel,  // gpt-4o for better narratives
            maxTokens: 2000  // Stories need more tokens
        )

        let cleanedResponse = Self.stripMarkdownCodeFences(response)

        guard let data = cleanedResponse.data(using: .utf8),
              let json = try? JSONDecoder().decode(StoryGenerationOutput.self, from: data) else {
            throw AIServiceError.invalidResponse
        }

        return json
    }

    // MARK: - Chat (Ask Tab)

    func sendChatMessage(input: ChatMessageInput) async throws -> ChatMessageOutput {
        try await rateLimiter.checkLimit()

        // Build the conversation messages
        var messages: [[String: String]] = [
            ["role": "system", "content": buildChatSystemPrompt(input: input)]
        ]

        // Add conversation history (windowed for token control)
        let historyWindow = Array(input.conversationHistory.suffix(8))  // Last 8 messages max
        for historyMessage in historyWindow {
            messages.append([
                "role": historyMessage.role,
                "content": historyMessage.content
            ])
        }

        // Build the user prompt with context
        let userPrompt = buildChatUserPrompt(input: input)
        messages.append(["role": "user", "content": userPrompt])

        // Use default model for chat (cost-effective)
        let model = AppConfiguration.AI.defaultModel

        // Make the API call with JSON structured output request
        let url = baseURL.appendingPathComponent("chat/completions")

        // Use json_object mode (more reliable across model versions)
        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 800,
            "response_format": ["type": "json_object"]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("OpenAIProvider: Invalid response type")
            throw AIServiceError.invalidResponse
        }

        // Log response status for debugging
        if httpResponse.statusCode != 200 {
            if let errorBody = String(data: data, encoding: .utf8) {
                print("OpenAIProvider: API error \(httpResponse.statusCode): \(errorBody)")
            }
        }

        try checkResponseStatus(httpResponse)

        // Parse the response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            print("OpenAIProvider: Failed to parse response structure")
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("OpenAIProvider: Raw response: \(rawResponse.prefix(500))")
            }
            throw AIServiceError.invalidResponse
        }

        // Extract token usage
        let usage = json["usage"] as? [String: Any]
        let promptTokens = usage?["prompt_tokens"] as? Int ?? 0
        let completionTokens = usage?["completion_tokens"] as? Int ?? 0

        // Parse the structured JSON response
        let cleanedContent = Self.stripMarkdownCodeFences(content)

        guard let contentData = cleanedContent.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }

        // Try to decode the structured response
        do {
            let structuredResponse = try JSONDecoder().decode(ChatAPIResponse.self, from: contentData)
            return ChatMessageOutput(
                content: structuredResponse.response,
                responseType: ResponseType(rawValue: structuredResponse.responseType) ?? .answer,
                citations: structuredResponse.citations?.map { citation in
                    ChatCitation(
                        id: UUID().uuidString,
                        reference: citation.reference,
                        bookId: citation.bookId,
                        chapter: citation.chapter,
                        verseStart: citation.verseStart,
                        verseEnd: citation.verseEnd ?? citation.verseStart,
                        relevance: citation.relevance
                    )
                },
                uncertaintyLevel: UncertaintyLevel(rawValue: structuredResponse.uncertaintyLevel) ?? .low,
                suggestedFollowUps: structuredResponse.suggestedFollowUps,
                tokensIn: promptTokens,
                tokensOut: completionTokens,
                modelUsed: model
            )
        } catch {
            // Log parsing error and fallback
            print("OpenAIProvider: JSON decode failed: \(error)")
            print("OpenAIProvider: Content was: \(cleanedContent.prefix(300))")

            // Fallback: treat as plain text response
            return ChatMessageOutput(
                content: cleanedContent,
                responseType: .answer,
                citations: nil,
                uncertaintyLevel: .low,
                suggestedFollowUps: nil,
                tokensIn: promptTokens,
                tokensOut: completionTokens,
                modelUsed: model
            )
        }
    }

    /// Build the system prompt for chat, including grounding context
    private func buildChatSystemPrompt(input: ChatMessageInput) -> String {
        var prompt = PromptTemplates.systemPromptChat

        prompt += """


        RESPONSE FORMAT (JSON):
        You MUST respond with valid JSON in this exact format:
        {
          "response": "Your answer to the question",
          "responseType": "answer",
          "citations": [
            {
              "reference": "John 3:16",
              "bookId": 43,
              "chapter": 3,
              "verseStart": 16,
              "verseEnd": 16,
              "relevance": "Brief explanation of why this verse is relevant"
            }
          ],
          "uncertaintyLevel": "low",
          "suggestedFollowUps": ["Follow-up question 1", "Follow-up question 2"]
        }

        RESPONSE TYPES:
        - "answer": In-scope question about Bible/faith
        - "off_topic": Not related to Bible/faith (politely redirect)
        - "clarification": Need more details to answer
        - "crisis_support": User expresses self-harm/crisis (respond with compassion)
        - "refusal_safety": Harmful/inappropriate request

        UNCERTAINTY LEVELS:
        - "low": Clear, well-established interpretation
        - "medium": Some scholarly debate exists
        - "high": Significant interpretive disagreement

        CITATION REQUIREMENTS:
        - Only cite verses you are confident exist
        - Include bookId using standard numbering (Genesis=1, Exodus=2, ... John=43, etc.)
        - Provide relevance explanation for each citation
        """

        // Add retrieved verses context if available (retrieval-first grounding)
        if let retrievedVerses = input.retrievedVerses, !retrievedVerses.isEmpty {
            prompt += "\n\nRELEVANT SCRIPTURE CONTEXT (cite from these when applicable):\n"
            for verse in retrievedVerses {
                prompt += "- \(verse.reference): \"\(verse.text)\"\n"
            }
        }

        return prompt
    }

    /// Build the user prompt with any anchored verse context
    private func buildChatUserPrompt(input: ChatMessageInput) -> String {
        var prompt = input.question

        if let verse = input.anchoredVerse, let text = input.anchoredVerseText {
            prompt = """
            I'm studying this passage:
            \(verse.reference)
            "\(text)"

            My question: \(input.question)

            Please answer with reference to this passage. Include relevant citations.
            """
        }

        return prompt
    }

    // MARK: - Prayer Generation (Prayers from the Deep)

    func generatePrayer(input: PrayerGenerationInput) async throws -> PrayerGenerationOutput {
        try await rateLimiter.checkLimit()

        let prompt = PromptTemplates.prayerGeneration(
            userContext: input.userContext,
            tradition: input.tradition
        )

        // Use gpt-4o-mini for cost-effective prayer generation
        let response = try await callChatCompletion(
            prompt: prompt,
            systemPrompt: PromptTemplates.systemPromptPrayer,
            model: AppConfiguration.AI.defaultModel,
            maxTokens: 500
        )

        // Strip markdown code fences if present
        let cleanedResponse = Self.stripMarkdownCodeFences(response)

        // Try to parse JSON response
        guard let data = cleanedResponse.data(using: .utf8),
              let output = try? JSONDecoder().decode(PrayerGenerationOutput.self, from: data) else {
            throw AIServiceError.invalidResponse
        }

        return output
    }

    // MARK: - Embeddings

    func embedText(text: String) async throws -> [Float] {
        try await rateLimiter.checkLimit()

        let url = baseURL.appendingPathComponent("embeddings")

        let body: [String: Any] = [
            "model": AppConfiguration.AI.embeddingModel,
            "input": text
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        try checkResponseStatus(httpResponse)

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let dataArray = json?["data"] as? [[String: Any]],
              let embedding = dataArray.first?["embedding"] as? [Double] else {
            throw AIServiceError.invalidResponse
        }

        return embedding.map { Float($0) }
    }

    // MARK: - Content Moderation (FREE)

    /// Moderate content using OpenAI's free Moderation API
    /// Returns flags for hate, violence, self-harm, sexual, harassment
    func moderateContent(_ text: String) async throws -> ModerationResult {
        let url = baseURL.appendingPathComponent("moderations")

        let body: [String: Any] = [
            "input": text
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            print("OpenAIProvider: Moderation URLError - \(urlError.localizedDescription)")
            throw AIServiceError.networkError(urlError)
        } catch {
            print("OpenAIProvider: Moderation network error - \(error.localizedDescription)")
            throw AIServiceError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        try checkResponseStatus(httpResponse)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]],
              let firstResult = results.first,
              let flagged = firstResult["flagged"] as? Bool,
              let categories = firstResult["categories"] as? [String: Bool] else {
            throw AIServiceError.invalidResponse
        }

        let selfHarmFlagged = (categories["self-harm"] ?? false) ||
                              (categories["self-harm/intent"] ?? false) ||
                              (categories["self-harm/instructions"] ?? false)

        return ModerationResult(
            flagged: flagged,
            selfHarmFlagged: selfHarmFlagged,
            categories: ModerationCategories(
                hate: categories["hate"] ?? false,
                hateThreatening: categories["hate/threatening"] ?? false,
                harassment: categories["harassment"] ?? false,
                harassmentThreatening: categories["harassment/threatening"] ?? false,
                selfHarm: categories["self-harm"] ?? false,
                selfHarmIntent: categories["self-harm/intent"] ?? false,
                selfHarmInstructions: categories["self-harm/instructions"] ?? false,
                sexual: categories["sexual"] ?? false,
                sexualMinors: categories["sexual/minors"] ?? false,
                violence: categories["violence"] ?? false,
                violenceGraphic: categories["violence/graphic"] ?? false
            )
        )
    }

    // MARK: - Private Methods

    private func callChatCompletion(
        prompt: String,
        systemPrompt: String,
        model: String,
        maxTokens: Int = 1000
    ) async throws -> String {
        let url = baseURL.appendingPathComponent("chat/completions")

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": prompt]
        ]

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": maxTokens
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            print("OpenAIProvider: URLError - \(urlError.localizedDescription)")
            throw AIServiceError.networkError(urlError)
        } catch {
            print("OpenAIProvider: Network error - \(error.localizedDescription)")
            throw AIServiceError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        try checkResponseStatus(httpResponse)

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.invalidResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func checkResponseStatus(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 429:
            throw AIServiceError.rateLimited
        case 401, 403:
            throw AIServiceError.notConfigured
        case 500...599:
            throw AIServiceError.modelUnavailable
        default:
            throw AIServiceError.invalidResponse
        }
    }
}

// MARK: - Chat API Response
// Internal struct for decoding the structured JSON response from chat completions

private struct ChatAPIResponse: Codable {
    let response: String
    let responseType: String
    let citations: [ChatAPICitation]?
    let uncertaintyLevel: String
    let suggestedFollowUps: [String]?

    enum CodingKeys: String, CodingKey {
        case response
        case responseType
        case citations
        case uncertaintyLevel
        case suggestedFollowUps
    }
}

private struct ChatAPICitation: Codable {
    let reference: String
    let bookId: Int
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int?
    let relevance: String?

    enum CodingKeys: String, CodingKey {
        case reference
        case bookId
        case chapter
        case verseStart
        case verseEnd
        case relevance
    }
}

// MARK: - Shared Instance
extension OpenAIProvider {
    static let shared = OpenAIProvider()
}

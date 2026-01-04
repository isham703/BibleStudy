import Foundation

// MARK: - Token Budget Manager
// Manages token budgets for AI chat to control costs
// Implements conversation summarization and windowing strategies

@Observable
@MainActor
final class TokenBudgetManager {
    // MARK: - Configuration

    /// Maximum messages before summarization is triggered
    static let summarizationThreshold = 6

    /// Number of recent messages to keep after summarization
    static let windowSize = 4

    /// Approximate tokens per character (conservative estimate)
    private static let tokensPerChar: Double = 0.4

    /// Maximum input tokens per request (leaving room for response)
    static let maxInputTokens = 4000

    // MARK: - Token Tracking

    private(set) var totalTokensUsed: Int = 0
    private(set) var totalRequestsMade: Int = 0
    private(set) var sessionStartDate: Date = Date()

    /// Estimated cost in USD (based on GPT-4o-mini pricing)
    var estimatedCostUSD: Double {
        // GPT-4o-mini: $0.15/1M input, $0.60/1M output
        // Assume 60% input, 40% output split
        let inputTokens = Double(totalTokensUsed) * 0.6
        let outputTokens = Double(totalTokensUsed) * 0.4
        let inputCost = (inputTokens / 1_000_000) * 0.15
        let outputCost = (outputTokens / 1_000_000) * 0.60
        return inputCost + outputCost
    }

    // MARK: - Shared Instance

    static let shared = TokenBudgetManager()

    private init() {}

    // MARK: - Token Estimation

    /// Estimate token count for a string (rough approximation)
    func estimateTokens(_ text: String) -> Int {
        Int(Double(text.count) * Self.tokensPerChar)
    }

    /// Estimate tokens for a conversation history
    func estimateTokens(for messages: [ChatHistoryMessage]) -> Int {
        messages.reduce(0) { total, message in
            total + estimateTokens(message.content) + 4  // +4 for role/formatting overhead
        }
    }

    // MARK: - Conversation Windowing

    /// Apply windowing strategy to conversation history
    /// Returns (windowed messages, optional summary to prepend)
    func windowConversation(
        _ messages: [ChatHistoryMessage],
        summary: String?
    ) -> (messages: [ChatHistoryMessage], summary: String?) {
        // If under threshold, return as-is
        guard messages.count > Self.summarizationThreshold else {
            return (messages, summary)
        }

        // Window to last N messages
        let windowedMessages = Array(messages.suffix(Self.windowSize))

        // If we have a summary, use it; otherwise indicate summarization is needed
        return (windowedMessages, summary)
    }

    /// Check if conversation needs summarization
    func needsSummarization(messageCount: Int) -> Bool {
        messageCount >= Self.summarizationThreshold
    }

    /// Generate a summary of the older conversation
    func generateConversationSummary(
        from messages: [ChatHistoryMessage]
    ) async throws -> String {
        // Messages to summarize (all but the last windowSize)
        let toSummarize = Array(messages.dropLast(Self.windowSize))
        guard !toSummarize.isEmpty else { return "" }

        // Build summary context
        let context = toSummarize.map { message in
            "\(message.role.capitalized): \(message.content)"
        }.joined(separator: "\n\n")

        // Use OpenAI to summarize (this is a lightweight call)
        let summaryPrompt = """
        Summarize the following Bible study conversation in 2-3 sentences.
        Focus on: the main topics discussed, any verses mentioned, and key insights shared.

        Conversation:
        \(context)

        Summary:
        """

        // Call OpenAI directly for summarization
        let provider = OpenAIProvider.shared
        let summary = try await provider.summarizeConversation(prompt: summaryPrompt)

        return summary
    }

    // MARK: - Usage Tracking

    /// Record token usage from a request
    func recordUsage(tokensIn: Int, tokensOut: Int) {
        totalTokensUsed += tokensIn + tokensOut
        totalRequestsMade += 1
    }

    /// Reset session tracking
    func resetSession() {
        totalTokensUsed = 0
        totalRequestsMade = 0
        sessionStartDate = Date()
    }

    /// Check if we're approaching budget limits
    func isApproachingLimit(dailyBudgetUSD: Double = 1.0) -> Bool {
        estimatedCostUSD > (dailyBudgetUSD * 0.8)
    }

    // MARK: - Budget Validation

    /// Validate that a request is within budget
    func validateRequest(
        estimatedInputTokens: Int,
        dailyBudgetUSD: Double = 1.0
    ) throws {
        // Check if input tokens are too high
        if estimatedInputTokens > Self.maxInputTokens {
            throw TokenBudgetError.inputTooLarge(tokens: estimatedInputTokens, max: Self.maxInputTokens)
        }

        // Check daily budget
        if estimatedCostUSD >= dailyBudgetUSD {
            throw TokenBudgetError.dailyBudgetExceeded(spent: estimatedCostUSD, budget: dailyBudgetUSD)
        }
    }
}

// MARK: - Token Budget Errors

enum TokenBudgetError: Error, LocalizedError {
    case inputTooLarge(tokens: Int, max: Int)
    case dailyBudgetExceeded(spent: Double, budget: Double)

    var errorDescription: String? {
        switch self {
        case .inputTooLarge(let tokens, let max):
            return "Conversation is too long (\(tokens) tokens, max \(max)). Please start a new conversation."
        case .dailyBudgetExceeded(let spent, let budget):
            return String(format: "Daily AI budget exceeded ($%.2f of $%.2f). Try again tomorrow.", spent, budget)
        }
    }
}

// MARK: - OpenAI Summarization Extension

extension OpenAIProvider {
    /// Lightweight summarization call for conversation compression
    func summarizeConversation(prompt: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1")!.appendingPathComponent("chat/completions")

        let messages: [[String: String]] = [
            ["role": "system", "content": "You are a helpful assistant that summarizes conversations concisely."],
            ["role": "user", "content": prompt]
        ]

        let body: [String: Any] = [
            "model": AppConfiguration.AI.defaultModel,
            "messages": messages,
            "temperature": 0.3,  // Lower temperature for more consistent summaries
            "max_tokens": 150    // Short summaries only
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AppConfiguration.AI.openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        let session = URLSession(configuration: config)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIServiceError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.invalidResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Usage Statistics

struct TokenUsageStats: Codable {
    let date: Date
    let tokensUsed: Int
    let requestCount: Int
    let estimatedCostUSD: Double

    /// Save daily stats to UserDefaults
    func save() {
        let key = "tokenUsage_\(formattedDate)"
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Load stats for a specific date
    static func load(for date: Date) -> TokenUsageStats? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = "tokenUsage_\(formatter.string(from: date))"
        guard let data = UserDefaults.standard.data(forKey: key),
              let stats = try? JSONDecoder().decode(TokenUsageStats.self, from: data) else {
            return nil
        }
        return stats
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

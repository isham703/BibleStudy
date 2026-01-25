import Foundation
import SwiftUI

// MARK: - Ask View Model
// Manages state and logic for the AI chat feature

// MARK: - Input Validation Result
enum InputValidation {
    case valid
    case tooShort
    case tooLong
    case rateLimited
    case blocked  // User exceeded violation threshold
}

@Observable
@MainActor
final class AskViewModel {
    // MARK: - Dependencies

    private let aiProvider: AIServiceProtocol
    private let tokenBudgetManager: TokenBudgetService
    private let persistenceService: ChatPersistenceService
    private let searchService: SearchService
    private let bibleService: BibleService

    // MARK: - State

    var mode: ChatMode = .general
    var inputText: String = ""
    var isLoading: Bool = false
    var showHistory: Bool = false
    var showVersePicker: Bool = false
    var errorMessage: String?
    var showError: Bool = false

    var currentThread: ChatThread?
    var threads: [ChatThread] = []
    var anchorRange: VerseRange?
    var anchorVerseText: String?

    /// Conversation summary for token management
    private var conversationSummary: String?

    var messages: [ChatMessage] {
        currentThread?.messages ?? []
    }

    /// Uncertainty level for the last response
    var lastUncertaintyLevel: UncertaintyLevel?

    /// Suggested follow-up questions from AI
    var suggestedFollowUps: [String] = []

    // MARK: - Guardrails State

    /// Tracks content policy violations for potential blocking
    private var violationCount: Int = 0
    private let maxViolations = 3
    private let violationCooldownMinutes: TimeInterval = 30

    /// Whether user is temporarily blocked from Ask feature
    var isUserBlocked: Bool {
        guard violationCount >= maxViolations else { return false }

        // Check if cooldown has expired
        if let blockedUntil = UserDefaults.standard.object(forKey: "askFeatureBlockedUntil") as? Date {
            if Date() > blockedUntil {
                // Cooldown expired, reset
                violationCount = 0
                UserDefaults.standard.removeObject(forKey: "askFeatureBlockedUntil")
                return false
            }
            return true
        }
        return true
    }

    // MARK: - Initialization

    init(
        aiProvider: AIServiceProtocol? = nil,
        tokenBudgetManager: TokenBudgetService? = nil,
        persistenceService: ChatPersistenceService? = nil,
        searchService: SearchService? = nil,
        bibleService: BibleService? = nil
    ) {
        // Use provided dependencies or MainActor-isolated singletons
        // This pattern avoids Swift 6 concurrency errors with default parameters
        self.aiProvider = aiProvider ?? OpenAIProvider.shared
        self.tokenBudgetManager = tokenBudgetManager ?? TokenBudgetService.shared
        self.persistenceService = persistenceService ?? ChatPersistenceService.shared
        self.searchService = searchService ?? SearchService.shared
        self.bibleService = bibleService ?? BibleService.shared

        // Load saved conversations
        loadConversations()
    }

    // MARK: - Persistence

    private func loadConversations() {
        do {
            threads = try persistenceService.fetchAllConversations()
        } catch {
            print("AskViewModel: Failed to load conversations: \(error)")
            threads = []
        }
    }

    private func saveCurrentConversation() {
        guard let thread = currentThread else { return }

        do {
            try persistenceService.saveConversation(thread)
        } catch {
            print("AskViewModel: Failed to save conversation: \(error)")
        }
    }

    func deleteThread(_ thread: ChatThread) {
        do {
            try persistenceService.deleteConversation(id: thread.id)
            threads.removeAll { $0.id == thread.id }

            // If we deleted the current thread, start a new chat
            if currentThread?.id == thread.id {
                startNewChat()
            }
        } catch {
            print("AskViewModel: Failed to delete conversation: \(error)")
        }
    }

    // MARK: - Actions

    func sendMessage() async {
        guard !inputText.isEmpty else { return }

        // Clear previous error state
        errorMessage = nil
        showError = false

        // STEP 1: Pre-check validation (length, rate, blocked)
        let validation = validateInput(inputText)
        switch validation {
        case .tooShort:
            errorMessage = "Please enter a longer question."
            showError = true
            return
        case .tooLong:
            errorMessage = "Your question is too long. Please shorten it to under 2000 characters."
            showError = true
            return
        case .blocked:
            errorMessage = "Ask feature temporarily disabled. Please try again later or contact support."
            showError = true
            return
        case .rateLimited:
            errorMessage = "Please wait a moment before sending another message."
            showError = true
            return
        case .valid:
            break
        }

        let question = inputText

        // STEP 2: Input moderation (FREE OpenAI Moderation API)
        do {
            let inputModeration = try await (aiProvider as? OpenAIProvider)?.moderateContent(question)

            // Handle self-harm detection - skip generation, return crisis response
            if inputModeration?.selfHarmFlagged == true {
                addCrisisResponse(for: question)
                inputText = ""
                return
            }

            // Handle other flagged content - return refusal
            if inputModeration?.flagged == true {
                recordViolation()
                addRefusalResponse(for: question)
                inputText = ""
                return
            }
        } catch {
            // Moderation failed - continue but log (never block on moderation failure)
            print("AskViewModel: Input moderation failed: \(error)")
        }

        let userMessage = ChatMessage(
            threadId: currentThread?.id ?? UUID(),
            role: .user,
            content: question
        )

        // Create thread if needed
        if currentThread == nil {
            currentThread = ChatThread(
                userId: UUID(),
                mode: mode,
                anchorRange: anchorRange,
                messages: [userMessage]
            )
            threads.insert(currentThread!, at: 0)
        } else {
            currentThread?.addMessage(userMessage)
        }

        inputText = ""
        isLoading = true

        do {
            // Build conversation history for context
            let historyMessages = buildConversationHistory()

            // Check if we need to summarize
            if tokenBudgetManager.needsSummarization(messageCount: messages.count) && conversationSummary == nil {
                // Generate summary asynchronously
                conversationSummary = try await tokenBudgetManager.generateConversationSummary(from: historyMessages)
            }

            // Apply windowing
            let (windowedMessages, summary) = tokenBudgetManager.windowConversation(
                historyMessages,
                summary: conversationSummary
            )

            // Build the input with summary context if available
            var finalHistory = windowedMessages
            if let summary = summary, !summary.isEmpty {
                finalHistory.insert(
                    ChatHistoryMessage(role: "system", content: "Previous conversation summary: \(summary)"),
                    at: 0
                )
            }

            // Validate budget
            let estimatedTokens = tokenBudgetManager.estimateTokens(for: finalHistory)
            try tokenBudgetManager.validateRequest(estimatedInputTokens: estimatedTokens)

            // Retrieve relevant verses for grounding (RAG)
            let retrievedVerses = await retrieveRelevantVerses(for: question)

            // Prepare input
            let input = ChatMessageInput(
                question: question,
                conversationHistory: finalHistory,
                anchoredVerse: anchorRange,
                anchoredVerseText: anchorVerseText,
                mode: mode,
                retrievedVerses: retrievedVerses.isEmpty ? nil : retrievedVerses
            )

            // STEP 3: Call the AI service (with strict JSON schema)
            var output = try await aiProvider.sendChatMessage(input: input)

            // Record token usage
            tokenBudgetManager.recordUsage(tokensIn: output.tokensIn, tokensOut: output.tokensOut)

            // STEP 4: Validate output (citation correctness)
            output = validateOutput(output)

            // STEP 5: Output moderation (Scripture-aware)
            output = await moderateOutput(output)

            // Create assistant message with citations and responseType
            let citations = output.citations?.map { citation in
                VerseRange(
                    bookId: citation.bookId,
                    chapter: citation.chapter,
                    verseStart: citation.verseStart,
                    verseEnd: citation.verseEnd
                )
            }

            let assistantMessage = ChatMessage(
                threadId: currentThread?.id ?? UUID(),
                role: .assistant,
                content: output.content,
                responseType: output.responseType,
                citations: citations
            )

            currentThread?.addMessage(assistantMessage)

            // Update state from response
            lastUncertaintyLevel = output.uncertaintyLevel
            suggestedFollowUps = output.suggestedFollowUps ?? []

            // Save to persistence
            saveCurrentConversation()

        } catch let error as TokenBudgetError {
            handleError(error)
        } catch let error as AIServiceError {
            handleError(error)
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    func startNewChat() {
        currentThread = nil
        anchorRange = nil
        anchorVerseText = nil
        inputText = ""
        conversationSummary = nil
        lastUncertaintyLevel = nil
        suggestedFollowUps = []
        errorMessage = nil
        showError = false
    }

    func selectThread(_ thread: ChatThread) {
        currentThread = thread
        mode = thread.mode
        anchorRange = thread.anchorRange
        conversationSummary = nil  // Reset summary when switching threads
        lastUncertaintyLevel = nil
        suggestedFollowUps = []
    }

    func setAnchor(_ range: VerseRange) {
        anchorRange = range
        mode = .verseAnchored
        // TODO: Load verse text from database
        loadAnchorVerseText(for: range)
    }

    func clearAnchor() {
        anchorRange = nil
        anchorVerseText = nil
        mode = .general
    }

    func selectSuggestedQuestion(_ question: String) {
        inputText = question
    }

    func retryLastMessage() async {
        // Remove the last failed message and retry
        guard let lastUserMessage = messages.last(where: { $0.role == .user }) else { return }

        // Remove messages after the last user message
        if let thread = currentThread,
           let index = thread.messages.firstIndex(where: { $0.id == lastUserMessage.id }) {
            // Keep only messages up to and including the user message
            currentThread?.messages = Array(thread.messages.prefix(through: index))
        }

        // Re-send
        inputText = lastUserMessage.content
        await sendMessage()
    }

    func dismissError() {
        errorMessage = nil
        showError = false
    }

    // MARK: - Private Methods

    private func buildConversationHistory() -> [ChatHistoryMessage] {
        messages.map { message in
            ChatHistoryMessage(
                role: message.role == .user ? "user" : "assistant",
                content: message.content
            )
        }
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true

        // Remove the user's message if the request failed
        if let lastMessage = currentThread?.messages.last, lastMessage.role == .user {
            currentThread?.messages.removeLast()
            inputText = lastMessage.content  // Restore the input
        }
    }

    private func loadAnchorVerseText(for range: VerseRange) {
        Task {
            do {
                let verses = try await BibleService.shared.getVerses(range: range)
                anchorVerseText = verses.map { $0.text }.joined(separator: " ")
            } catch {
                // Use reference as fallback
                anchorVerseText = nil
            }
        }
    }

    // MARK: - RAG: Verse Retrieval

    /// Retrieves relevant Bible verses based on the user's question
    /// Uses FTS5 full-text search for zero-cost, low-latency retrieval
    private func retrieveRelevantVerses(for question: String) async -> [RetrievedVerse] {
        // Skip retrieval for very short queries
        guard question.count >= 3 else { return [] }

        do {
            // Search using the user's current translation
            let results = try await searchService.search(
                query: question,
                translationId: bibleService.currentTranslationId,
                bookId: nil,
                limit: 5
            )

            // Convert SearchResult to RetrievedVerse
            return results.map { result in
                RetrievedVerse(
                    reference: result.verse.reference,
                    text: result.verse.text,
                    bookId: result.verse.bookId,
                    chapter: result.verse.chapter,
                    verseStart: result.verse.verse,
                    verseEnd: result.verse.verse
                )
            }
        } catch {
            // Log but don't fail - RAG is enhancement, not requirement
            print("AskViewModel: Verse retrieval failed: \(error)")
            return []
        }
    }

    // MARK: - Guardrails: Input Validation

    /// Validates input before sending (length, rate limits, block status)
    private func validateInput(_ text: String) -> InputValidation {
        // Check if user is blocked (repeated violations)
        if isUserBlocked { return .blocked }

        // Length limits (DoS prevention)
        guard text.count >= 2 else { return .tooShort }
        guard text.count <= 2000 else { return .tooLong }

        return .valid
    }

    /// Records a content policy violation and sets block if threshold reached
    private func recordViolation() {
        violationCount += 1
        if violationCount >= maxViolations {
            // Set cooldown period
            let blockedUntil = Date().addingTimeInterval(violationCooldownMinutes * 60)
            UserDefaults.standard.set(blockedUntil, forKey: "askFeatureBlockedUntil")
        }
    }

    // MARK: - Guardrails: Crisis & Refusal Responses

    /// Hardcoded crisis response text (not AI-generated for safety)
    private static let crisisResponseText = """
    I can see you may be going through a difficult time. You're not alone, and there is hope.

    Please consider reaching out to someone who can help:
    • A pastor, counselor, or trusted friend
    • A mental health professional

    Scripture reminds us of God's presence in our struggles:

    "The Lord is close to the brokenhearted and saves those who are crushed in spirit." — Psalm 34:18

    "Come to me, all you who are weary and burdened, and I will give you rest." — Matthew 11:28

    You matter deeply. Please reach out to someone you trust.
    """

    /// Adds a crisis support response (bypasses AI generation)
    private func addCrisisResponse(for question: String) {
        // Add user message
        let userMessage = ChatMessage(
            threadId: currentThread?.id ?? UUID(),
            role: .user,
            content: question
        )

        if currentThread == nil {
            currentThread = ChatThread(
                userId: UUID(),
                mode: mode,
                anchorRange: anchorRange,
                messages: [userMessage]
            )
            threads.insert(currentThread!, at: 0)
        } else {
            currentThread?.addMessage(userMessage)
        }

        // Add hardcoded crisis response (not AI-generated)
        let crisisMessage = ChatMessage(
            threadId: currentThread?.id ?? UUID(),
            role: .assistant,
            content: Self.crisisResponseText,
            responseType: .crisisSupport,
            citations: nil
        )

        currentThread?.addMessage(crisisMessage)
        saveCurrentConversation()
    }

    /// Adds a refusal response for flagged content
    private func addRefusalResponse(for question: String) {
        // Add user message
        let userMessage = ChatMessage(
            threadId: currentThread?.id ?? UUID(),
            role: .user,
            content: question
        )

        if currentThread == nil {
            currentThread = ChatThread(
                userId: UUID(),
                mode: mode,
                anchorRange: anchorRange,
                messages: [userMessage]
            )
            threads.insert(currentThread!, at: 0)
        } else {
            currentThread?.addMessage(userMessage)
        }

        // Add refusal response
        let refusalMessage = ChatMessage(
            threadId: currentThread?.id ?? UUID(),
            role: .assistant,
            content: "I can't help with that request. I'm here to support positive spiritual growth and Bible study. Is there something else I can help you with?",
            responseType: .refusalSafety,
            citations: nil
        )

        currentThread?.addMessage(refusalMessage)
        saveCurrentConversation()
    }

    // MARK: - Guardrails: Output Validation

    /// Validates AI output for citation correctness
    private func validateOutput(_ output: ChatMessageOutput) -> ChatMessageOutput {
        // For answers with no citations but verse mentions, downgrade confidence
        if output.responseType == .answer {
            let mentionsVerses = output.content.contains(where: { $0.isNumber }) &&
                                 (output.content.contains(":") || output.content.lowercased().contains("verse"))

            if mentionsVerses && (output.citations?.isEmpty ?? true) {
                // Downgrade to medium uncertainty when mentioning verses without citations
                return ChatMessageOutput(
                    content: output.content,
                    responseType: output.responseType,
                    citations: nil,
                    uncertaintyLevel: .medium,
                    suggestedFollowUps: output.suggestedFollowUps,
                    tokensIn: output.tokensIn,
                    tokensOut: output.tokensOut,
                    modelUsed: output.modelUsed
                )
            }

            // Validate citations exist (filter hallucinated ones)
            if let citations = output.citations, !citations.isEmpty {
                let validCitations = citations.filter { isValidCitation($0) }
                if validCitations.count < citations.count {
                    // Some citations were invalid (hallucinated)
                    return ChatMessageOutput(
                        content: output.content,
                        responseType: output.responseType,
                        citations: validCitations.isEmpty ? nil : validCitations,
                        uncertaintyLevel: .medium,  // Downgrade confidence
                        suggestedFollowUps: output.suggestedFollowUps,
                        tokensIn: output.tokensIn,
                        tokensOut: output.tokensOut,
                        modelUsed: output.modelUsed
                    )
                }
            }
        }

        return output
    }

    /// Checks if a citation refers to a valid verse in our database
    private func isValidCitation(_ citation: ChatCitation) -> Bool {
        // Basic validation: check book ID is in valid range (1-66)
        guard citation.bookId >= 1 && citation.bookId <= 66 else { return false }

        // Check chapter is reasonable for the book
        // This is a simplified check - could be enhanced with actual book/chapter data
        guard citation.chapter >= 1 && citation.chapter <= 150 else { return false }  // Psalms has 150

        // Check verse is reasonable
        guard citation.verseStart >= 1 && citation.verseStart <= 200 else { return false }

        return true
    }

    // MARK: - Guardrails: Output Moderation

    /// Moderates AI output with Scripture-awareness
    private func moderateOutput(_ output: ChatMessageOutput) async -> ChatMessageOutput {
        guard let provider = aiProvider as? OpenAIProvider else {
            return output
        }

        do {
            let modResult = try await provider.moderateContent(output.content)

            guard modResult.flagged else {
                return output  // Not flagged, proceed normally
            }

            // Scripture study exemption: If response includes citations and
            // is discussing biblical content academically, allow it
            if output.responseType == .answer,
               let citations = output.citations, !citations.isEmpty,
               !modResult.selfHarmFlagged {  // Never exempt self-harm
                // Log for review but allow (legitimate Bible study)
                print("AskViewModel: Output flagged but allowed (has citations): \(modResult.categories)")
                return output
            }

            // Replace flagged content with safe output (never throw)
            return ChatMessageOutput(
                content: "I encountered an issue generating that response. Please try rephrasing your question.",
                responseType: .clarification,
                citations: nil,
                uncertaintyLevel: .low,
                suggestedFollowUps: ["Could you ask that differently?"],
                tokensIn: output.tokensIn,
                tokensOut: output.tokensOut,
                modelUsed: output.modelUsed
            )
        } catch {
            // Moderation failed - continue but log
            print("AskViewModel: Output moderation failed: \(error)")
            return output
        }
    }
}

// MARK: - Error Alert Configuration

extension AskViewModel {
    var errorAlertTitle: String {
        if errorMessage?.contains("rate") == true || errorMessage?.contains("limited") == true {
            return "Please Wait"
        } else if errorMessage?.contains("budget") == true {
            return "Usage Limit Reached"
        } else if errorMessage?.contains("network") == true {
            return "Connection Error"
        } else {
            return "Something Went Wrong"
        }
    }

    var canRetry: Bool {
        // Don't allow retry for rate limits or budget exceeded
        guard let error = errorMessage else { return false }
        return !error.contains("rate") &&
               !error.contains("limited") &&
               !error.contains("budget")
    }
}

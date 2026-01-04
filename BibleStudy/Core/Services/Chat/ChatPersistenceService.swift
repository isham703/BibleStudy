import Foundation
import SwiftData

// MARK: - Chat Persistence Service
// Manages local storage of chat conversations using SwiftData

@MainActor
final class ChatPersistenceService {
    // MARK: - Shared Instance

    static let shared = ChatPersistenceService()

    // MARK: - Model Container

    private var container: ModelContainer?

    private init() {
        setupContainer()
    }

    private func setupContainer() {
        do {
            let schema = Schema([
                PersistedConversation.self,
                PersistedMessage.self,
                PersistedCitation.self,
                PersistedMessageMeta.self
            ])

            // Use app's documents directory, not App Group
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let storeURL = documentsURL.appendingPathComponent("ChatHistory.store")

            let modelConfiguration = ModelConfiguration(
                "ChatHistory",
                url: storeURL,
                cloudKitDatabase: .none
            )

            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("ChatPersistenceService: Failed to create model container: \(error)")
            // Fall back to in-memory storage so the app doesn't crash
            setupInMemoryContainer()
        }
    }

    private func setupInMemoryContainer() {
        do {
            let schema = Schema([
                PersistedConversation.self,
                PersistedMessage.self,
                PersistedCitation.self,
                PersistedMessageMeta.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )

            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("ChatPersistenceService: Using in-memory storage as fallback")
        } catch {
            print("ChatPersistenceService: Failed to create in-memory container: \(error)")
        }
    }

    // MARK: - Context

    private var context: ModelContext? {
        container?.mainContext
    }

    // MARK: - Conversation Operations

    /// Save a new conversation or update an existing one
    func saveConversation(_ thread: ChatThread) throws {
        guard let context else { throw PersistenceError.containerNotAvailable }

        // Check if conversation exists
        let existingConversation = try fetchConversation(id: thread.id)

        if let existing = existingConversation {
            // Update existing
            existing.mode = thread.mode.rawValue
            existing.updatedAt = Date()
            existing.summary = nil  // Will be set separately if needed

            // Update messages
            try syncMessages(for: existing, from: thread)
        } else {
            // Create new
            let conversation = PersistedConversation(
                id: thread.id,
                userId: thread.userId,
                mode: thread.mode.rawValue,
                anchorBookId: thread.anchorRange?.bookId,
                anchorChapter: thread.anchorRange?.chapter,
                anchorVerseStart: thread.anchorRange?.verseStart,
                anchorVerseEnd: thread.anchorRange?.verseEnd,
                createdAt: thread.createdAt,
                updatedAt: Date()
            )

            context.insert(conversation)

            // Add messages
            for message in thread.messages {
                try saveMessage(message, to: conversation)
            }
        }

        try context.save()
    }

    /// Fetch a conversation by ID
    func fetchConversation(id: UUID) throws -> PersistedConversation? {
        guard let context else { throw PersistenceError.containerNotAvailable }

        let descriptor = FetchDescriptor<PersistedConversation>(
            predicate: #Predicate { $0.id == id }
        )

        return try context.fetch(descriptor).first
    }

    /// Fetch all conversations, sorted by most recent
    func fetchAllConversations() throws -> [ChatThread] {
        guard let context else { throw PersistenceError.containerNotAvailable }

        var descriptor = FetchDescriptor<PersistedConversation>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 50  // Limit to last 50 conversations

        let persisted = try context.fetch(descriptor)
        return persisted.map { $0.toChatThread() }
    }

    /// Delete a conversation
    func deleteConversation(id: UUID) throws {
        guard let context else { throw PersistenceError.containerNotAvailable }

        if let conversation = try fetchConversation(id: id) {
            context.delete(conversation)
            try context.save()
        }
    }

    /// Delete all conversations
    func deleteAllConversations() throws {
        guard let context else { throw PersistenceError.containerNotAvailable }

        try context.delete(model: PersistedConversation.self)
        try context.save()
    }

    // MARK: - Message Operations

    /// Save a message to a conversation
    func saveMessage(_ message: ChatMessage, to conversation: PersistedConversation) throws {
        guard let context else { throw PersistenceError.containerNotAvailable }

        let persistedMessage = PersistedMessage(
            id: message.id,
            conversationId: conversation.id,
            role: message.role.rawValue,
            content: message.content,
            createdAt: message.createdAt
        )

        context.insert(persistedMessage)

        // Save citations if present
        if let citations = message.citations {
            for citation in citations {
                let persistedCitation = PersistedCitation(
                    messageId: message.id,
                    reference: citation.reference,
                    bookId: citation.bookId,
                    chapter: citation.chapter,
                    verseStart: citation.verseStart,
                    verseEnd: citation.verseEnd
                )
                context.insert(persistedCitation)
            }
        }

        try context.save()
    }

    /// Sync messages from a thread to a persisted conversation
    private func syncMessages(for conversation: PersistedConversation, from thread: ChatThread) throws {
        guard context != nil else { throw PersistenceError.containerNotAvailable }

        // Get existing message IDs
        let existingIds = Set((conversation.messages ?? []).map { $0.id })

        // Add new messages
        for message in thread.messages where !existingIds.contains(message.id) {
            try saveMessage(message, to: conversation)
        }

        // Note: We don't delete messages that are in persisted but not in thread
        // This preserves history even if the in-memory thread is windowed
    }

    // MARK: - Message Meta Operations

    /// Save metadata for a message (tokens, latency, etc.)
    func saveMessageMeta(
        messageId: UUID,
        tokensIn: Int,
        tokensOut: Int,
        modelUsed: String,
        latencyMs: Int
    ) throws {
        guard let context else { throw PersistenceError.containerNotAvailable }

        let meta = PersistedMessageMeta(
            messageId: messageId,
            tokensIn: tokensIn,
            tokensOut: tokensOut,
            modelUsed: modelUsed,
            latencyMs: latencyMs
        )

        context.insert(meta)
        try context.save()
    }

    // MARK: - Summary Operations

    /// Update conversation summary (for token windowing)
    func updateSummary(_ summary: String, for conversationId: UUID) throws {
        guard let context else { throw PersistenceError.containerNotAvailable }

        if let conversation = try fetchConversation(id: conversationId) {
            conversation.summary = summary
            try context.save()
        }
    }

    /// Fetch summary for a conversation
    func fetchSummary(for conversationId: UUID) throws -> String? {
        try fetchConversation(id: conversationId)?.summary
    }

    // MARK: - Usage Statistics

    /// Get total token usage across all conversations
    func getTotalTokenUsage() throws -> (tokensIn: Int, tokensOut: Int) {
        guard let context else { throw PersistenceError.containerNotAvailable }

        let descriptor = FetchDescriptor<PersistedMessageMeta>()
        let metas = try context.fetch(descriptor)

        let totalIn = metas.reduce(0) { $0 + $1.tokensIn }
        let totalOut = metas.reduce(0) { $0 + $1.tokensOut }

        return (totalIn, totalOut)
    }

    /// Get token usage for a specific date range
    func getTokenUsage(from startDate: Date, to endDate: Date) throws -> (tokensIn: Int, tokensOut: Int) {
        guard context != nil else { throw PersistenceError.containerNotAvailable }

        // Need to join with messages to filter by date
        // For now, return total usage (simplified implementation)
        return try getTotalTokenUsage()
    }
}

// MARK: - Persistence Error

enum PersistenceError: Error, LocalizedError {
    case containerNotAvailable
    case saveError(Error)
    case fetchError(Error)

    var errorDescription: String? {
        switch self {
        case .containerNotAvailable:
            return "Chat storage is not available"
        case .saveError(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .fetchError(let error):
            return "Failed to fetch: \(error.localizedDescription)"
        }
    }
}

// MARK: - SwiftData Models

@Model
final class PersistedConversation {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var mode: String
    var anchorBookId: Int?
    var anchorChapter: Int?
    var anchorVerseStart: Int?
    var anchorVerseEnd: Int?
    var createdAt: Date
    var updatedAt: Date
    var summary: String?

    @Relationship(deleteRule: .cascade, inverse: \PersistedMessage.conversation)
    var messages: [PersistedMessage]?

    init(
        id: UUID,
        userId: UUID,
        mode: String,
        anchorBookId: Int?,
        anchorChapter: Int?,
        anchorVerseStart: Int?,
        anchorVerseEnd: Int?,
        createdAt: Date,
        updatedAt: Date,
        summary: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.mode = mode
        self.anchorBookId = anchorBookId
        self.anchorChapter = anchorChapter
        self.anchorVerseStart = anchorVerseStart
        self.anchorVerseEnd = anchorVerseEnd
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.summary = summary
    }

    func toChatThread() -> ChatThread {
        let anchorRange: VerseRange?
        if let bookId = anchorBookId, let chapter = anchorChapter,
           let verseStart = anchorVerseStart {
            anchorRange = VerseRange(
                bookId: bookId,
                chapter: chapter,
                verseStart: verseStart,
                verseEnd: anchorVerseEnd ?? verseStart
            )
        } else {
            anchorRange = nil
        }

        let chatMessages = (messages ?? [])
            .sorted { $0.createdAt < $1.createdAt }
            .map { $0.toChatMessage() }

        return ChatThread(
            id: id,
            userId: userId,
            mode: ChatMode(rawValue: mode) ?? .general,
            anchorRange: anchorRange,
            messages: chatMessages,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

@Model
final class PersistedMessage {
    @Attribute(.unique) var id: UUID
    var conversationId: UUID
    var role: String
    var content: String
    var createdAt: Date

    var conversation: PersistedConversation?

    @Relationship(deleteRule: .cascade, inverse: \PersistedCitation.message)
    var citations: [PersistedCitation]?

    init(
        id: UUID,
        conversationId: UUID,
        role: String,
        content: String,
        createdAt: Date
    ) {
        self.id = id
        self.conversationId = conversationId
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }

    func toChatMessage() -> ChatMessage {
        let citationRanges = (citations ?? []).map { citation in
            VerseRange(
                bookId: citation.bookId,
                chapter: citation.chapter,
                verseStart: citation.verseStart,
                verseEnd: citation.verseEnd
            )
        }

        return ChatMessage(
            id: id,
            threadId: conversationId,
            role: MessageRole(rawValue: role) ?? .user,
            content: content,
            citations: citationRanges.isEmpty ? nil : citationRanges,
            createdAt: createdAt
        )
    }
}

@Model
final class PersistedCitation {
    @Attribute(.unique) var id: UUID
    var messageId: UUID
    var reference: String
    var bookId: Int
    var chapter: Int
    var verseStart: Int
    var verseEnd: Int

    var message: PersistedMessage?

    init(
        id: UUID = UUID(),
        messageId: UUID,
        reference: String,
        bookId: Int,
        chapter: Int,
        verseStart: Int,
        verseEnd: Int
    ) {
        self.id = id
        self.messageId = messageId
        self.reference = reference
        self.bookId = bookId
        self.chapter = chapter
        self.verseStart = verseStart
        self.verseEnd = verseEnd
    }
}

@Model
final class PersistedMessageMeta {
    @Attribute(.unique) var id: UUID
    var messageId: UUID
    var tokensIn: Int
    var tokensOut: Int
    var modelUsed: String
    var latencyMs: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        messageId: UUID,
        tokensIn: Int,
        tokensOut: Int,
        modelUsed: String,
        latencyMs: Int
    ) {
        self.id = id
        self.messageId = messageId
        self.tokensIn = tokensIn
        self.tokensOut = tokensOut
        self.modelUsed = modelUsed
        self.latencyMs = latencyMs
        self.createdAt = Date()
    }
}

import Foundation

// MARK: - Chat Message
// Represents a message in a Bible study chat

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let threadId: UUID
    let role: MessageRole
    let content: String
    let responseType: ResponseType?  // For guardrails routing
    let citations: [VerseRange]?
    let createdAt: Date

    var isUser: Bool { role == .user }
    var isAssistant: Bool { role == .assistant }
    var isCrisisSupport: Bool { responseType == .crisisSupport }

    init(
        id: UUID = UUID(),
        threadId: UUID,
        role: MessageRole,
        content: String,
        responseType: ResponseType? = nil,
        citations: [VerseRange]? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.threadId = threadId
        self.role = role
        self.content = content
        self.responseType = responseType
        self.citations = citations
        self.createdAt = createdAt
    }
}

// MARK: - Message Role
enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

// MARK: - Chat Thread
struct ChatThread: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var title: String?
    let mode: ChatMode
    let anchorRange: VerseRange?
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date

    var lastMessage: ChatMessage? {
        messages.last
    }

    var displayTitle: String {
        if let title = title {
            return title
        }
        if let anchor = anchorRange {
            return anchor.reference
        }
        return "New Chat"
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        title: String? = nil,
        mode: ChatMode = .general,
        anchorRange: VerseRange? = nil,
        messages: [ChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.mode = mode
        self.anchorRange = anchorRange
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        updatedAt = Date()
    }
}

// MARK: - Chat Mode
enum ChatMode: String, Codable, CaseIterable {
    case general
    case verseAnchored = "verse_anchored"

    var displayName: String {
        switch self {
        case .general: return "General"
        case .verseAnchored: return "Verse-Anchored"
        }
    }

    var description: String {
        switch self {
        case .general: return "Ask any Bible question"
        case .verseAnchored: return "Ask questions about specific verses"
        }
    }

    /// Icon name for display (deprecated - kept for compatibility)
    var iconName: String {
        switch self {
        case .verseAnchored: return "book.closed.fill"
        case .general: return "sparkles"
        }
    }
}

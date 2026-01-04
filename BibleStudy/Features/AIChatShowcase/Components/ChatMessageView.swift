import SwiftUI

// MARK: - Showcase Chat Message
// Data model for showcase chat messages (separate from app's ChatMessage)

struct ShowcaseChatMessage: Identifiable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    var citations: [Citation]?
    var isTyping: Bool

    init(
        id: UUID = UUID(),
        content: String,
        isUser: Bool,
        timestamp: Date = Date(),
        citations: [Citation]? = nil,
        isTyping: Bool = false
    ) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.citations = citations
        self.isTyping = isTyping
    }

    struct Citation: Identifiable, Equatable {
        let id: UUID
        let reference: String
        let type: CitationType

        init(id: UUID = UUID(), reference: String, type: CitationType) {
            self.id = id
            self.reference = reference
            self.type = type
        }

        enum CitationType: Equatable {
            case scripture
            case crossReference
            case commentary
        }
    }
}

// MARK: - Chat Message View
// Renders a single message bubble with variant-specific styling

struct ShowcaseChatMessageView: View {
    let message: ShowcaseChatMessage
    let variant: ChatVariant

    @State private var isVisible = false

    private var palette: MessagePalette {
        MessagePalette(variant: variant, isUser: message.isUser)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                // Message bubble
                messageBubble

                // Citations (AI messages only, scholarly variant)
                if !message.isUser, let citations = message.citations, variant == .scholarlyCompanion {
                    citationsView(citations)
                }
            }

            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 16)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)
        .onAppear {
            withAnimation(ChatPalette.Animation.messageAppear) {
                isVisible = true
            }
        }
    }

    // MARK: - Message Bubble

    private var messageBubble: some View {
        Group {
            if message.isTyping {
                typingIndicator
            } else {
                Text(message.content)
                    .font(messageFont)
                    .foregroundStyle(palette.textColor)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(palette.bubbleBackground)
        .clipShape(bubbleShape)
        .overlay(
            bubbleShape
                .stroke(palette.bubbleBorder, lineWidth: palette.borderWidth)
        )
        .shadow(color: palette.shadow, radius: 4, y: 2)
    }

    private var messageFont: Font {
        switch variant {
        case .minimalStudio:
            return .system(size: 15, weight: .regular)
        case .scholarlyCompanion:
            return .system(size: 15, weight: .regular)
        case .warmSanctuary:
            return .custom("CormorantGaramond-Regular", size: 17)
        }
    }

    private var bubbleShape: some Shape {
        RoundedRectangle(cornerRadius: ChatPalette.Shared.messageBubble)
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(palette.textColor.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .offset(y: typingOffset(for: index))
            }
        }
        .frame(width: 40, height: 20)
        .onAppear {
            // Animation handled by offset calculation
        }
    }

    private func typingOffset(for index: Int) -> CGFloat {
        // Simple static offset for now - could be animated
        return 0
    }

    // MARK: - Citations View (Scholarly only)

    private func citationsView(_ citations: [ShowcaseChatMessage.Citation]) -> some View {
        HStack(spacing: 6) {
            ForEach(citations) { citation in
                citationChip(citation)
            }
        }
    }

    private func citationChip(_ citation: ShowcaseChatMessage.Citation) -> some View {
        HStack(spacing: 4) {
            Image(systemName: citationIcon(for: citation.type))
                .font(.system(size: 10, weight: .medium))

            Text(citation.reference)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(ChatPalette.Scholarly.accent)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(ChatPalette.Scholarly.citationChip)
        .clipShape(Capsule())
    }

    private func citationIcon(for type: ShowcaseChatMessage.Citation.CitationType) -> String {
        switch type {
        case .scripture: return "book.closed.fill"
        case .crossReference: return "arrow.triangle.branch"
        case .commentary: return "text.quote"
        }
    }
}

// MARK: - Message Palette Helper

private struct MessagePalette {
    let variant: ChatVariant
    let isUser: Bool

    var bubbleBackground: Color {
        switch variant {
        case .minimalStudio:
            return isUser ? ChatPalette.Minimal.userBubble : ChatPalette.Minimal.aiBubble
        case .scholarlyCompanion:
            return isUser ? ChatPalette.Scholarly.userBubble : ChatPalette.Scholarly.aiBubble
        case .warmSanctuary:
            return isUser ? ChatPalette.Sanctuary.userBubble : ChatPalette.Sanctuary.aiBubble
        }
    }

    var textColor: Color {
        switch variant {
        case .minimalStudio:
            return isUser ? ChatPalette.Minimal.userText : ChatPalette.Minimal.aiText
        case .scholarlyCompanion:
            return isUser ? ChatPalette.Scholarly.userText : ChatPalette.Scholarly.aiText
        case .warmSanctuary:
            return isUser ? ChatPalette.Sanctuary.userText : ChatPalette.Sanctuary.aiText
        }
    }

    var bubbleBorder: Color {
        switch variant {
        case .minimalStudio:
            return isUser ? Color.clear : ChatPalette.Minimal.aiBorder
        case .scholarlyCompanion:
            return isUser ? Color.clear : ChatPalette.Scholarly.aiBorder
        case .warmSanctuary:
            return isUser ? ChatPalette.Sanctuary.userBorder : ChatPalette.Sanctuary.aiBorder
        }
    }

    var borderWidth: CGFloat {
        switch variant {
        case .minimalStudio: return isUser ? 0 : 1
        case .scholarlyCompanion: return isUser ? 0 : 1
        case .warmSanctuary: return 1
        }
    }

    var shadow: Color {
        switch variant {
        case .minimalStudio: return ChatPalette.Minimal.shadow
        case .scholarlyCompanion: return ChatPalette.Scholarly.shadow
        case .warmSanctuary: return ChatPalette.Sanctuary.shadow
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Minimal
        VStack(spacing: 12) {
            ShowcaseChatMessageView(
                message: ShowcaseChatMessage(content: "What does John 3:16 mean?", isUser: true),
                variant: .minimalStudio
            )
            ShowcaseChatMessageView(
                message: ShowcaseChatMessage(content: "John 3:16 is one of the most well-known verses in the Bible. It speaks to God's unconditional love for humanity.", isUser: false),
                variant: .minimalStudio
            )
        }
        .padding()
        .background(ChatPalette.Minimal.background)

        // Scholarly
        VStack(spacing: 12) {
            ShowcaseChatMessageView(
                message: ShowcaseChatMessage(
                    content: "The Greek word 'agape' here represents divine, unconditional love.",
                    isUser: false,
                    citations: [
                        .init(reference: "John 3:16", type: .scripture),
                        .init(reference: "1 John 4:8", type: .crossReference)
                    ]
                ),
                variant: .scholarlyCompanion
            )
        }
        .padding()
        .background(ChatPalette.Scholarly.background)
    }
}

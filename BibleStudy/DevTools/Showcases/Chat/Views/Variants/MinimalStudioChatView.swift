import SwiftUI

// MARK: - Minimal Studio Chat View
// Ultra-clean, modern, distraction-free chat interface
// Maximum whitespace, monochromatic palette, focused conversation

struct MinimalStudioChatView: View {
    @State private var inputText = ""
    @State private var messages: [ShowcaseChatMessage] = MinimalStudioChatView.sampleMessages
    @State private var isTyping = false

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            messagesScrollView

            // Divider
            Rectangle()
                .fill(ChatPalette.Minimal.aiBorder)
                .frame(height: 1)

            // Input bar
            ShowcaseChatInputBar(
                text: $inputText,
                variant: .minimalStudio,
                onSend: sendMessage,
                onVoice: startVoice
            )
        }
        .background(ChatPalette.Minimal.background)
        .navigationTitle("Minimal Studio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ChatPalette.Minimal.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - Messages Scroll View

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Welcome header
                    welcomeHeader
                        .padding(.top, 24)
                        .padding(.bottom, 8)

                    // Messages
                    ForEach(messages) { message in
                        ShowcaseChatMessageView(message: message, variant: .minimalStudio)
                    }

                    // Typing indicator
                    if isTyping {
                        ShowcaseChatMessageView(
                            message: ShowcaseChatMessage(content: "", isUser: false, isTyping: true),
                            variant: .minimalStudio
                        )
                    }

                    // Bottom padding
                    Color.clear.frame(height: 20)
                        .id("bottom")
                }
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(ChatPalette.Minimal.tertiaryText)

            // Title
            Text("Ask anything")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(ChatPalette.Minimal.primaryText)

            // Subtitle
            Text("I'm here to help with your Bible study")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(ChatPalette.Minimal.secondaryText)
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Add user message
        let userMessage = ShowcaseChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        inputText = ""

        // Simulate AI typing
        isTyping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isTyping = false
            let aiResponse = ShowcaseChatMessage(
                content: generateResponse(for: text),
                isUser: false
            )
            messages.append(aiResponse)
        }
    }

    private func startVoice() {
        // Voice recording would be implemented here
    }

    private func generateResponse(for query: String) -> String {
        // Simple mock responses
        let responses = [
            "That's a thoughtful question. Let me share some insights with you.",
            "The scripture you're asking about has deep meaning. Here's what I found.",
            "Based on the biblical context, I can help explain this passage.",
            "This is a beautiful verse. Let me break down its significance."
        ]
        return responses.randomElement() ?? responses[0]
    }

    // MARK: - Sample Messages

    static let sampleMessages: [ShowcaseChatMessage] = [
        ShowcaseChatMessage(
            content: "What does 'love your neighbor' really mean in the original context?",
            isUser: true
        ),
        ShowcaseChatMessage(
            content: "In Leviticus 19:18, the Hebrew word for 'neighbor' (רֵעַ, rea) refers to a fellow member of the community. Jesus expanded this concept in the parable of the Good Samaritan, teaching that our neighbor is anyone in need.\n\nThe command to love is expressed through the Hebrew 'ahav' — an active, choice-driven love that involves practical care and justice.",
            isUser: false
        )
    ]
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MinimalStudioChatView()
    }
}

import SwiftUI

// MARK: - Warm Sanctuary Chat View
// Soft, contemplative, intimate conversation experience
// Candlelit aesthetic with warm gold accents

struct WarmSanctuaryChatView: View {
    @State private var inputText = ""
    @State private var messages: [ShowcaseChatMessage] = WarmSanctuaryChatView.sampleMessages
    @State private var isTyping = false

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            VStack(spacing: 0) {
                // Messages
                messagesScrollView

                // Input bar
                inputSection
            }
        }
        .navigationTitle("Warm Sanctuary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ChatPalette.Sanctuary.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            // Base color
            ChatPalette.Sanctuary.background
                .ignoresSafeArea()

            // Warm ambient glow at top
            RadialGradient(
                colors: [
                    ChatPalette.Sanctuary.accent.opacity(0.08),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()

            // Subtle bottom glow
            RadialGradient(
                colors: [
                    ChatPalette.Sanctuary.accent.opacity(0.04),
                    Color.clear
                ],
                center: .bottom,
                startRadius: 0,
                endRadius: 200
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Messages Scroll View

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Welcome header
                    welcomeHeader
                        .padding(.top, 32)
                        .padding(.bottom, 16)

                    // Messages
                    ForEach(messages) { message in
                        ShowcaseChatMessageView(message: message, variant: .warmSanctuary)
                    }

                    // Typing indicator
                    if isTyping {
                        typingIndicatorView
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
        VStack(spacing: 20) {
            // Candle icon with glow
            ZStack {
                // Glow effect
                Circle()
                    .fill(ChatPalette.Sanctuary.accent.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)

                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ChatPalette.Sanctuary.accent, ChatPalette.Sanctuary.accentGlow],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            // Title
            VStack(spacing: 8) {
                Text("Welcome, friend")
                    .font(.custom("CormorantGaramond-Regular", size: 28))
                    .foregroundStyle(ChatPalette.Sanctuary.primaryText)

                Text("A quiet space for reflection and conversation")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(ChatPalette.Sanctuary.secondaryText)
                    .multilineTextAlignment(.center)
            }

            // Decorative divider
            HStack(spacing: 12) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, ChatPalette.Sanctuary.divider],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                Image(systemName: "sparkle")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(ChatPalette.Sanctuary.accent.opacity(0.6))

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [ChatPalette.Sanctuary.divider, Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }
            .padding(.horizontal, 60)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Typing Indicator

    private var typingIndicatorView: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(ChatPalette.Sanctuary.accent.opacity(0.6))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(ChatPalette.Sanctuary.aiBubble)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(ChatPalette.Sanctuary.aiBorder, lineWidth: 1)
            )

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 0) {
            // Divider with glow
            Rectangle()
                .fill(ChatPalette.Sanctuary.divider)
                .frame(height: 1)
                .shadow(color: ChatPalette.Sanctuary.accent.opacity(0.3), radius: 4, y: -2)

            // Input bar
            ShowcaseChatInputBar(
                text: $inputText,
                variant: .warmSanctuary,
                onSend: sendMessage,
                onVoice: startVoice
            )
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Add user message
        let userMessage = ShowcaseChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        inputText = ""

        // Simulate AI typing with contemplative pacing
        isTyping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isTyping = false
            let aiResponse = ShowcaseChatMessage(
                content: generateContemplativeResponse(for: text),
                isUser: false
            )
            messages.append(aiResponse)
        }
    }

    private func startVoice() {
        // Voice recording would be implemented here
    }

    private func generateContemplativeResponse(for query: String) -> String {
        "What a beautiful question to bring into this quiet space.\n\nThe words of Scripture often reveal their deepest meaning when we sit with them patiently, allowing them to speak to our hearts.\n\nTake a moment to breathe, and let's explore this together with openness and wonder."
    }

    // MARK: - Sample Messages

    static let sampleMessages: [ShowcaseChatMessage] = [
        ShowcaseChatMessage(
            content: "I've been struggling to find peace lately. What does the Bible say about rest?",
            isUser: true
        ),
        ShowcaseChatMessage(
            content: "I hear you, friend. The weight of daily life can feel heavy.\n\nJesus offers a beautiful invitation in Matthew 11:28-30:\n\n\"Come to me, all you who are weary and burdened, and I will give you rest. Take my yoke upon you and learn from me, for I am gentle and humble in heart, and you will find rest for your souls.\"\n\nThe Hebrew concept of 'shalom' — often translated as peace — speaks of a wholeness and completeness that goes beyond just the absence of conflict. It's the kind of deep rest that comes from knowing you are held.\n\nWould you like to explore this passage further together?",
            isUser: false
        )
    ]
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WarmSanctuaryChatView()
    }
}

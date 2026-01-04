import SwiftUI

// MARK: - The Apprentice POC
// Personal AI study companion with memory and personality
// Aesthetic: Warm, intimate, like talking to a wise friend

struct TheApprenticePOC: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = false
    @State private var messages: [ApprenticeMessage] = []
    @State private var inputText = ""
    @State private var isTyping = false
    @State private var showingPersonality = true
    @FocusState private var isInputFocused: Bool

    private let initialMessages: [ApprenticeMessage] = [
        ApprenticeMessage(
            isUser: false,
            text: "Welcome back. I noticed you've been circling Ecclesiastes for the past few weeks. The Teacher's words about 'meaningless, meaningless' keep appearing in your highlights.",
            timestamp: "Just now"
        ),
        ApprenticeMessage(
            isUser: false,
            text: "I wonder... are you wrestling with something deeper? Sometimes when we return to the same passages, there's a question underneath the question.",
            timestamp: "Just now"
        )
    ]

    var body: some View {
        ZStack {
            // Warm background
            warmBackground

            VStack(spacing: 0) {
                // Header
                apprenticeHeader

                if showingPersonality {
                    // Personality intro
                    personalityIntro
                } else {
                    // Chat interface
                    chatInterface
                }
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isVisible = true
            }
        }
    }

    // MARK: - Warm Background

    private var warmBackground: some View {
        ZStack {
            // Base - warm dark
            Color(hex: "1a1512")

            // Warm glow
            RadialGradient(
                colors: [
                    Color(hex: "f59e0b").opacity(0.08),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 500
            )

            // Subtle accent
            RadialGradient(
                colors: [
                    Color(hex: "ef4444").opacity(0.05),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 400
            )
        }
    }

    // MARK: - Header

    private var apprenticeHeader: some View {
        HStack(spacing: 16) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "f59e0b"), Color(hex: "ef4444")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Text("א")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("The Apprentice")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "22c55e"))
                        .frame(width: 6, height: 6)
                    Text("Remembers 47 conversations")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 16)
        .background(Color(hex: "1a1512").opacity(0.95))
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.5), value: isVisible)
    }

    // MARK: - Personality Intro

    private var personalityIntro: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Avatar large
                ZStack {
                    Circle()
                        .fill(Color(hex: "f59e0b").opacity(0.2))
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "f59e0b"), Color(hex: "ef4444")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Text("א")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.white)
                }
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.8)
                .animation(.spring(duration: 0.7).delay(0.2), value: isVisible)

                VStack(spacing: 16) {
                    Text("Your Study Companion")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(.white)

                    Text("I remember your journey. I know which books you've studied deeply, which questions keep you up at night, and where you're growing.")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 32)
                }
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: isVisible)

                // Personality traits
                VStack(spacing: 12) {
                    personalityTrait(icon: "brain.head.profile", text: "Adapts to your learning style")
                    personalityTrait(icon: "clock.arrow.circlepath", text: "Remembers past conversations")
                    personalityTrait(icon: "lightbulb.fill", text: "Asks questions, not just answers")
                }
                .padding(.top, 8)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.6), value: isVisible)

                Button(action: startConversation) {
                    Text("Begin Conversation")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "f59e0b"), Color(hex: "ef4444")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding(.top, 24)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.8), value: isVisible)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func personalityTrait(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "f59e0b"))
                .frame(width: 24)

            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Chat Interface

    private var chatInterface: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                            MessageBubble(message: message)
                                .id(index)
                        }

                        if isTyping {
                            typingIndicator
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
                .onChange(of: messages.count) { _, _ in
                    withAnimation {
                        proxy.scrollTo(messages.count - 1, anchor: .bottom)
                    }
                }
            }

            // Input area
            inputArea
        }
    }

    // MARK: - Message Bubble

    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color(hex: "f59e0b").opacity(0.6))
                        .frame(width: 8, height: 8)
                        .offset(y: isTyping ? -4 : 0)
                        .animation(
                            .easeInOut(duration: 0.4)
                            .repeatForever()
                            .delay(Double(i) * 0.15),
                            value: isTyping
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.08))
            )

            Spacer()
        }
    }

    // MARK: - Input Area

    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("", text: $inputText, prompt: Text("Ask anything...").foregroundColor(.white.opacity(0.3)))
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.08))
                )
                .focused($isInputFocused)

            Button(action: sendMessage) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "f59e0b"), Color(hex: "ef4444")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
            .disabled(inputText.isEmpty)
            .opacity(inputText.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(hex: "1a1512").opacity(0.95))
    }

    // MARK: - Actions

    private func startConversation() {
        withAnimation(.spring(duration: 0.5)) {
            showingPersonality = false
        }

        // Add initial messages with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            for (index, message) in initialMessages.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 1.5) {
                    withAnimation(.spring(duration: 0.4)) {
                        messages.append(message)
                    }
                }
            }
        }
    }

    private func sendMessage() {
        guard !inputText.isEmpty else { return }

        let userMessage = ApprenticeMessage(isUser: true, text: inputText, timestamp: "Now")
        withAnimation(.spring(duration: 0.3)) {
            messages.append(userMessage)
        }
        inputText = ""
        isInputFocused = false

        // Simulate AI response
        isTyping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isTyping = false
            let response = ApprenticeMessage(
                isUser: false,
                text: "That's a profound question. I've noticed you've asked something similar before, about three months ago when you were studying Job. What's different now? What's prompting this question to resurface?",
                timestamp: "Now"
            )
            withAnimation(.spring(duration: 0.4)) {
                messages.append(response)
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ApprenticeMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer() }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                Text(message.text)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(message.isUser ? Color(hex: "f59e0b").opacity(0.8) : Color.white.opacity(0.08))
                    )

                Text(message.timestamp)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser { Spacer() }
        }
    }
}

// MARK: - Apprentice Message Model

struct ApprenticeMessage: Equatable {
    let isUser: Bool
    let text: String
    let timestamp: String
}

// MARK: - Preview

#Preview {
    TheApprenticePOC()
}

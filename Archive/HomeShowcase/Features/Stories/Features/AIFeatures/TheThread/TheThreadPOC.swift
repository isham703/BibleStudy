import SwiftUI

// MARK: - The Thread POC
// Conversations with historical figures about scripture
// Aesthetic: Scholarly, multi-voice, timeless

struct TheThreadPOC: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = false
    @State private var selectedFigure: HistoricalFigure?
    @State private var showingConversation = false
    @State private var conversationMessages: [ThreadMessage] = []
    @State private var isTyping = false
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    private let figures: [HistoricalFigure] = [
        HistoricalFigure(
            name: "Augustine of Hippo",
            title: "Bishop & Theologian",
            era: "354-430 AD",
            avatar: "A",
            color: Color(hex: "9333ea"),
            expertise: "Grace, free will, the nature of sin",
            introMessage: "My restless heart finds rest in God alone. What weighs upon yours, friend?"
        ),
        HistoricalFigure(
            name: "Martin Luther",
            title: "Reformer",
            era: "1483-1546 AD",
            avatar: "L",
            color: Color(hex: "dc2626"),
            expertise: "Faith, scripture, justification",
            introMessage: "Here I stand, ready to reason from scripture. What troubles your faith?"
        ),
        HistoricalFigure(
            name: "Miriam of Nazareth",
            title: "Mother of Jesus",
            era: "1st Century",
            avatar: "M",
            color: Color(hex: "0891b2"),
            expertise: "Motherhood, suffering, trust",
            introMessage: "I pondered many things in my heart. Perhaps we can ponder together."
        ),
        HistoricalFigure(
            name: "C.S. Lewis",
            title: "Author & Apologist",
            era: "1898-1963 AD",
            avatar: "C",
            color: Color(hex: "16a34a"),
            expertise: "Reason, imagination, doubt",
            introMessage: "I was the most reluctant convert. I understand the struggle to believe."
        )
    ]

    var body: some View {
        ZStack {
            // Scholarly background
            scholarlyBackground

            if showingConversation, let figure = selectedFigure {
                conversationView(with: figure)
            } else {
                figureSelectionView
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

    // MARK: - Background

    private var scholarlyBackground: some View {
        ZStack {
            Color(hex: "0c0a09")

            // Warm library glow
            RadialGradient(
                colors: [
                    Color(hex: "451a03").opacity(0.3),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 600
            )

            // Subtle texture
            Rectangle()
                .fill(Color.white.opacity(0.02))
        }
    }

    // MARK: - Figure Selection View

    private var figureSelectionView: some View {
        VStack(spacing: 0) {
            // Header
            header

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Intro
                    VStack(spacing: 16) {
                        Text("The Thread")
                            .font(.system(size: 36, weight: .bold, design: .serif))
                            .foregroundStyle(.white)

                        Text("Across centuries, the faithful have wrestled with the same questions. Choose a voice from history.")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 16)
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: isVisible)

                    // Figure cards
                    VStack(spacing: 16) {
                        ForEach(Array(figures.enumerated()), id: \.element.name) { index, figure in
                            figureCard(figure: figure, index: index)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: {
                if showingConversation {
                    withAnimation(.spring(duration: 0.4)) {
                        showingConversation = false
                        conversationMessages = []
                    }
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: showingConversation ? "chevron.left" : "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Text("THE THREAD")
                .font(.system(size: 10, weight: .bold))
                .tracking(3)
                .foregroundStyle(Color(hex: "10b981"))

            Spacer()

            Color.clear.frame(width: 20)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .opacity(isVisible ? 1 : 0)
    }

    // MARK: - Figure Card

    private func figureCard(figure: HistoricalFigure, index: Int) -> some View {
        Button(action: { selectFigure(figure) }) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(figure.color.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Text(figure.avatar)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundStyle(figure.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(figure.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("\(figure.title) · \(figure.era)")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))

                    Text(figure.expertise)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(figure.color)
                        .padding(.top, 2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(figure.color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -30)
        .animation(.spring(duration: 0.6).delay(0.3 + Double(index) * 0.1), value: isVisible)
    }

    // MARK: - Conversation View

    private func conversationView(with figure: HistoricalFigure) -> some View {
        VStack(spacing: 0) {
            // Conversation header
            conversationHeader(figure: figure)

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(Array(conversationMessages.enumerated()), id: \.offset) { index, message in
                            threadMessageBubble(message: message, figure: figure)
                                .id(index)
                        }

                        if isTyping {
                            typingIndicator(figure: figure)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
                .onChange(of: conversationMessages.count) { _, _ in
                    withAnimation {
                        proxy.scrollTo(conversationMessages.count - 1, anchor: .bottom)
                    }
                }
            }

            // Input
            conversationInput(figure: figure)
        }
    }

    private func conversationHeader(figure: HistoricalFigure) -> some View {
        HStack(spacing: 16) {
            Button(action: {
                withAnimation(.spring(duration: 0.4)) {
                    showingConversation = false
                    conversationMessages = []
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            ZStack {
                Circle()
                    .fill(figure.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Text(figure.avatar)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(figure.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(figure.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                Text(figure.era)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 16)
        .background(Color(hex: "0c0a09").opacity(0.95))
    }

    private func threadMessageBubble(message: ThreadMessage, figure: HistoricalFigure) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if !message.isUser {
                ZStack {
                    Circle()
                        .fill(figure.color.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Text(figure.avatar)
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundStyle(figure.color)
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                Text(message.text)
                    .font(.system(size: 16, design: .serif))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.isUser ? figure.color.opacity(0.3) : Color.white.opacity(0.08))
                    )
            }
            .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)

            if message.isUser {
                Spacer().frame(width: 48)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }

    private func typingIndicator(figure: HistoricalFigure) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(figure.color.opacity(0.2))
                    .frame(width: 36, height: 36)

                Text(figure.avatar)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundStyle(figure.color)
            }

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(figure.color.opacity(0.6))
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
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.08))
            )

            Spacer()
        }
    }

    private func conversationInput(figure: HistoricalFigure) -> some View {
        HStack(spacing: 12) {
            TextField("", text: $inputText, prompt: Text("Ask \(figure.name.components(separatedBy: " ").first ?? "")...").foregroundColor(.white.opacity(0.3)))
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.08))
                )
                .focused($isInputFocused)

            Button(action: { sendMessage(to: figure) }) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(figure.color))
            }
            .disabled(inputText.isEmpty)
            .opacity(inputText.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(hex: "0c0a09").opacity(0.95))
    }

    // MARK: - Actions

    private func selectFigure(_ figure: HistoricalFigure) {
        selectedFigure = figure
        withAnimation(.spring(duration: 0.5)) {
            showingConversation = true
        }

        // Add intro message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(duration: 0.4)) {
                conversationMessages.append(ThreadMessage(isUser: false, text: figure.introMessage))
            }
        }
    }

    private func sendMessage(to figure: HistoricalFigure) {
        guard !inputText.isEmpty else { return }

        let userMessage = ThreadMessage(isUser: true, text: inputText)
        withAnimation(.spring(duration: 0.3)) {
            conversationMessages.append(userMessage)
        }
        inputText = ""
        isInputFocused = false

        // Simulate response
        isTyping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isTyping = false
            let response = getResponse(from: figure)
            withAnimation(.spring(duration: 0.4)) {
                conversationMessages.append(ThreadMessage(isUser: false, text: response))
            }
        }
    }

    private func getResponse(from figure: HistoricalFigure) -> String {
        switch figure.name {
        case "Augustine of Hippo":
            return "Ah, you touch upon a wound I know well. In my Confessions, I wrote of stealing pears not from hunger, but from the sheer delight of transgression. The heart is indeed a mystery unto itself. Tell me more of what you're wrestling with."
        case "Martin Luther":
            return "Scripture alone! Not the traditions of men, not the decrees of councils, but the living Word. When I nailed my theses to that door, I trembled. Yet truth demanded it. What scripture passage troubles you?"
        case "Miriam of Nazareth":
            return "When the angel came to me, I was afraid. When Simeon spoke of a sword piercing my heart, I did not understand. Sometimes we must trust before we can see. What are you being asked to trust?"
        default:
            return "I spent years running from faith, constructing elaborate arguments against it. Until I realized I was arguing with the Hound of Heaven. What argument keeps you running?"
        }
    }
}

// MARK: - Models

struct HistoricalFigure {
    let name: String
    let title: String
    let era: String
    let avatar: String
    let color: Color
    let expertise: String
    let introMessage: String
}

struct ThreadMessage: Equatable {
    let isUser: Bool
    let text: String
}

// MARK: - Preview

#Preview {
    TheThreadPOC()
}

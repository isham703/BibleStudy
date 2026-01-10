import SwiftUI

// MARK: - Scholarly Companion Chat View
// Editorial, research-focused chat with citations and cross-references
// Academic aesthetic with warm vellum background

struct ScholarlyCompanionChatView: View {
    @State private var inputText = ""
    @State private var messages: [ShowcaseChatMessage] = ScholarlyCompanionChatView.sampleMessages
    @State private var isTyping = false
    @State private var showSuggestions = true

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            messagesScrollView

            // Suggestions bar
            if showSuggestions && messages.count < 4 {
                suggestionsBar
            }

            // Divider
            Rectangle()
                .fill(ChatPalette.Scholarly.aiBorder)
                .frame(height: 1)

            // Input bar
            ShowcaseChatInputBar(
                text: $inputText,
                variant: .scholarlyCompanion,
                onSend: sendMessage,
                onVoice: startVoice
            )
        }
        .background(ChatPalette.Scholarly.background)
        .navigationTitle("Scholarly Companion")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ChatPalette.Scholarly.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: {}) {
                        Label("Export Notes", systemImage: "square.and.arrow.up")
                    }
                    Button(action: {}) {
                        Label("View Sources", systemImage: "books.vertical")
                    }
                    Button(action: {}) {
                        Label("Study History", systemImage: "clock.arrow.circlepath")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(Typography.Command.headline)
                        .foregroundStyle(ChatPalette.Scholarly.accent)
                }
            }
        }
    }

    // MARK: - Messages Scroll View

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Welcome header
                    welcomeHeader
                        .padding(.top, 24)
                        .padding(.bottom, 8)

                    // Messages
                    ForEach(messages) { message in
                        ShowcaseChatMessageView(message: message, variant: .scholarlyCompanion)
                    }

                    // Typing indicator
                    if isTyping {
                        ShowcaseChatMessageView(
                            message: ShowcaseChatMessage(content: "", isUser: false, isTyping: true),
                            variant: .scholarlyCompanion
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
        VStack(spacing: 16) {
            // Icon with scholarly styling
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(ChatPalette.Scholarly.accentSubtle)
                    .frame(width: 64, height: 64)

                Image(systemName: "text.book.closed.fill")
                    .font(Typography.Icon.xl)
                    .foregroundStyle(ChatPalette.Scholarly.accent)
            }

            // Title
            VStack(spacing: 6) {
                Text("SCHOLARLY COMPANION")
                    .font(Typography.Icon.xxs.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(ChatPalette.Scholarly.accent)

                Text("Explore Scripture Deeply")
                    .font(.custom("CormorantGaramond-SemiBold", size: 26))
                    .foregroundStyle(ChatPalette.Scholarly.primaryText)
            }

            // Description
            Text("Ask questions and receive research-backed insights with citations from original languages, commentaries, and cross-references.")
                .font(Typography.Command.caption)
                .foregroundStyle(ChatPalette.Scholarly.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Suggestions Bar

    private var suggestionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        inputText = suggestion
                        sendMessage()
                    }) {
                        Text(suggestion)
                            .font(Typography.Command.meta)
                            .foregroundStyle(ChatPalette.Scholarly.accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(ChatPalette.Scholarly.accentSubtle)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(ChatPalette.Scholarly.accent.opacity(Theme.Opacity.light), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(ChatPalette.Scholarly.surface)
    }

    private var suggestions: [String] {
        [
            "Explain the Greek word 'agape'",
            "Cross-references for Psalm 23",
            "Historical context of Romans 8"
        ]
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Add user message
        let userMessage = ShowcaseChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        inputText = ""
        showSuggestions = false

        // Simulate AI typing
        isTyping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isTyping = false
            let aiResponse = ShowcaseChatMessage(
                content: generateScholarlyResponse(for: text),
                isUser: false,
                citations: [
                    .init(reference: "John 3:16", type: .scripture),
                    .init(reference: "1 John 4:8", type: .crossReference)
                ]
            )
            messages.append(aiResponse)
        }
    }

    private func startVoice() {
        // Voice recording would be implemented here
    }

    private func generateScholarlyResponse(for query: String) -> String {
        "Based on my analysis of the original Greek text and scholarly commentaries, here's what we can understand:\n\nThe passage you're asking about uses specific terminology that reveals deeper theological meaning. The Greek word employed here carries connotations that are sometimes lost in translation.\n\nFor further study, I recommend examining the related passages I've cited below."
    }

    // MARK: - Sample Messages

    static let sampleMessages: [ShowcaseChatMessage] = [
        ShowcaseChatMessage(
            content: "What is the significance of 'logos' in John 1:1?",
            isUser: true
        ),
        ShowcaseChatMessage(
            content: "The Greek word 'λόγος' (logos) in John 1:1 is extraordinarily rich in meaning. In Greek philosophy, particularly Stoicism, logos referred to the rational principle governing the universe.\n\nJohn's Gospel brilliantly bridges Hebrew and Greek thought. The Hebrew concept of God's creative 'word' (dabar) in Genesis 1 is unified with the Greek philosophical logos.\n\nKey theological implications:\n• Pre-existence: The Logos was 'in the beginning' (ἐν ἀρχῇ)\n• Relationship: The Logos was 'with God' (πρὸς τὸν θεόν)\n• Identity: The Logos 'was God' (θεὸς ἦν ὁ λόγος)",
            isUser: false,
            citations: [
                .init(reference: "John 1:1-3", type: .scripture),
                .init(reference: "Gen 1:1", type: .crossReference),
                .init(reference: "Heb 1:1-2", type: .crossReference)
            ]
        )
    ]
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScholarlyCompanionChatView()
    }
}

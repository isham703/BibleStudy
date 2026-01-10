import SwiftUI

// MARK: - Ornate Conversation View
// Chat-like message thread with scrolling and typing indicator

struct OrnateConversationView: View {
    let messages: [ConversationMessage]
    let isTyping: Bool
    @Binding var selectedTradition: PrayerTradition

    @Namespace private var bottomID

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Messages
                    ForEach(messages) { message in
                        OrnateMessageBubble(message: message)
                            .id(message.id)
                    }

                    // Typing indicator
                    if isTyping {
                        OrnateTypingIndicator()
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // Scroll anchor
                    Color.clear
                        .frame(height: 1)
                        .id(bottomID)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            }
            .onChange(of: isTyping) { _, newValue in
                if newValue {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
            }
        }
    }
}

// MARK: - Empty State

struct OrnateEmptyConversation: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Decorative icon
            ZStack {
                Circle()
                    .fill(DeepPrayerColors.roseAccent.opacity(Theme.Opacity.overlay))
                    .frame(width: 100, height: 100)

                Image(systemName: "hands.sparkles.fill")
                    .font(Typography.Icon.hero)
                    .foregroundStyle(DeepPrayerColors.roseAccent.opacity(Theme.Opacity.tertiary))
            }

            VStack(spacing: 12) {
                Text("Prayers from the Deep")
                    .font(Typography.Scripture.prompt.weight(.medium))
                    .foregroundStyle(DeepPrayerColors.primaryText)

                Text("Share what weighs on your heart,\nand I shall weave it into sacred words.")
                    .font(Typography.Scripture.footnote)
                    .foregroundStyle(DeepPrayerColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .italic()
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Preview

#Preview("Conversation") {
    OrnateConversationView(
        messages: [
            ConversationMessage(
                role: .assistant,
                content: "What weighs upon your heart today?",
                tradition: nil
            ),
            ConversationMessage(
                role: .user,
                content: "I'm struggling with anxiety about my future.",
                tradition: nil
            )
        ],
        isTyping: true,
        selectedTradition: .constant(.psalmicLament)
    )
    .background(DeepPrayerColors.sacredNavy)
}

#Preview("Empty State") {
    OrnateEmptyConversation()
        .background(DeepPrayerColors.sacredNavy)
}

import SwiftUI

// MARK: - Ornate Message Bubble
// Styled message containers for conversational flow

struct OrnateMessageBubble: View {
    let message: ConversationMessage

    @State private var hasAppeared = false

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                // Message content
                messageContent
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)

                // Tradition attribution (for AI messages with prayer)
                if let tradition = message.tradition {
                    Text("In the tradition of \(tradition.rawValue)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DeepPrayerColors.tertiaryText)
                        .italic()
                        .opacity(hasAppeared ? 1 : 0)
                }
            }

            if message.role == .assistant {
                Spacer(minLength: 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Message Content

    @ViewBuilder
    private var messageContent: some View {
        switch message.role {
        case .user:
            userBubble
        case .assistant:
            assistantBubble
        }
    }

    // MARK: - User Bubble

    private var userBubble: some View {
        Text(message.content)
            .font(.system(size: 15))
            .foregroundStyle(DeepPrayerColors.primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(DeepPrayerColors.roseHighlight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(DeepPrayerColors.roseBorder, lineWidth: 1)
            )
    }

    // MARK: - Assistant Bubble

    private var assistantBubble: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Decorative header for prayer messages
            if message.tradition != nil {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundStyle(DeepPrayerColors.goldAccent)

                    Rectangle()
                        .fill(DeepPrayerColors.goldAccent.opacity(0.3))
                        .frame(height: 1)
                }
            }

            // Prayer or message text
            if message.tradition != nil {
                // Prayer content with special styling
                Text(message.content)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundStyle(DeepPrayerColors.primaryText)
                    .lineSpacing(8)
            } else {
                // Regular assistant message
                Text(message.content)
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(DeepPrayerColors.primaryText)
                    .italic()
            }

            // Decorative footer for prayer messages
            if message.tradition != nil {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(DeepPrayerColors.goldAccent.opacity(0.3))
                        .frame(height: 1)

                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundStyle(DeepPrayerColors.goldAccent)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DeepPrayerColors.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    message.tradition != nil
                        ? DeepPrayerColors.goldAccent.opacity(0.3)
                        : DeepPrayerColors.surfaceBorder,
                    lineWidth: 1
                )
        )
        .overlay(alignment: .topLeading) {
            // Corner ornament for prayer messages
            if message.tradition != nil {
                cornerOrnament
                    .offset(x: -4, y: -4)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            // Corner ornament for prayer messages
            if message.tradition != nil {
                cornerOrnament
                    .offset(x: 4, y: 4)
            }
        }
    }

    private var cornerOrnament: some View {
        Circle()
            .fill(DeepPrayerColors.goldAccent.opacity(0.4))
            .frame(width: 8, height: 8)
    }
}

// MARK: - Typing Indicator

struct OrnateTypingIndicator: View {
    @State private var animationPhase = 0

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(DeepPrayerColors.roseAccent)
                        .frame(width: 8, height: 8)
                        .opacity(animationPhase == index ? 1.0 : 0.3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(DeepPrayerColors.surfaceElevated)
            )
            .overlay(
                Capsule()
                    .stroke(DeepPrayerColors.surfaceBorder, lineWidth: 1)
            )

            Spacer()
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.2)) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

// MARK: - Preview

#Preview("Message Bubbles") {
    ScrollView {
        VStack(spacing: 16) {
            OrnateMessageBubble(
                message: ConversationMessage(
                    role: .assistant,
                    content: "What weighs upon your heart today?",
                    tradition: nil
                )
            )

            OrnateMessageBubble(
                message: ConversationMessage(
                    role: .user,
                    content: "I'm worried about my son who has drifted away from faith.",
                    tradition: nil
                )
            )

            OrnateTypingIndicator()

            OrnateMessageBubble(
                message: ConversationMessage(
                    role: .assistant,
                    content: MockPrayer.psalmicLament.content + "\n\n" + MockPrayer.psalmicLament.amen,
                    tradition: .psalmicLament
                )
            )
        }
        .padding()
    }
    .background(DeepPrayerColors.sacredNavy)
}

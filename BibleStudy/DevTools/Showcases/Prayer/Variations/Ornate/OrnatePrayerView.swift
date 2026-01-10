import SwiftUI

// MARK: - Ornate Prayer View
// Rich medieval manuscript aesthetic with chat-like conversational flow
// Visual Density: Rich | Animation: Immersive | Interaction: Conversational

struct OrnatePrayerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var flowState = PrayerFlowState()
    @State private var isVisible = false
    @State private var breathePhase: CGFloat = 0
    @State private var messages: [ConversationMessage] = []
    @State private var inputText = ""
    @State private var isTyping = false
    @State private var showActionSheet = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Animated background
            AnimatedDeepPrayerBackground(breathingDuration: 4.0)

            // Decorative border frame
            OrnateBorderFrame(breathePhase: breathePhase)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 1.0), value: isVisible)

            VStack(spacing: 0) {
                // Header
                header

                // Conversation view
                OrnateConversationView(
                    messages: messages,
                    isTyping: isTyping,
                    selectedTradition: $flowState.selectedTradition
                )

                // Input area
                if !showActionSheet {
                    inputArea
                }

                // Action sheet (after prayer complete)
                if showActionSheet {
                    ornateActionSheet
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isVisible = true
            }
            startBreathingAnimation()
            addWelcomeMessage()
        }
        .onDisappear {
            flowState.reset()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(Typography.Icon.md)
                    .foregroundStyle(DeepPrayerColors.secondaryText)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("ORNATE")
                    .font(Typography.Icon.xxxs.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(DeepPrayerColors.roseAccent)

                Text("Conversational Flow")
                    .font(Typography.Icon.xxs)
                    .foregroundStyle(DeepPrayerColors.tertiaryText)
            }

            Spacer()

            Color.clear.frame(width: 20)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 8)
        .opacity(isVisible ? 1 : 0)
    }

    // MARK: - Input Area

    private var inputArea: some View {
        VStack(spacing: 12) {
            // Tradition selector (compact)
            if messages.count <= 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Text("Style:")
                            .font(Typography.Command.caption)
                            .foregroundStyle(DeepPrayerColors.tertiaryText)

                        ForEach(PrayerTradition.allCases) { tradition in
                            traditionChip(tradition)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            // Text input with send button
            HStack(spacing: 12) {
                TextField("Share what's on your heart...", text: $inputText, axis: .vertical)
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(DeepPrayerColors.primaryText)
                    .lineLimit(1...4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.sheet)
                            .fill(DeepPrayerColors.surfaceElevated)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.sheet)
                                    .stroke(DeepPrayerColors.surfaceBorder, lineWidth: 1)
                            )
                    )

                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(Typography.Icon.hero)
                        .foregroundStyle(
                            inputText.isEmpty
                                ? DeepPrayerColors.tertiaryText
                                : DeepPrayerColors.roseAccent
                        )
                }
                .disabled(inputText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .padding(.top, 8)
        .background(
            DeepPrayerColors.sacredNavy.opacity(Theme.Opacity.nearOpaque)
                .background(.ultraThinMaterial)
        )
    }

    private func traditionChip(_ tradition: PrayerTradition) -> some View {
        let isSelected = flowState.selectedTradition == tradition

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                flowState.selectedTradition = tradition
            }
        }) {
            Text(tradition.shortName)
                .font(Typography.Icon.xxs.weight(.medium))
                .foregroundStyle(
                    isSelected
                        ? DeepPrayerColors.primaryText
                        : DeepPrayerColors.tertiaryText
                )
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? DeepPrayerColors.roseHighlight
                                : Color.clear
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected
                                ? DeepPrayerColors.roseBorder
                                : DeepPrayerColors.surfaceBorder,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Ornate Action Sheet

    private var ornateActionSheet: some View {
        VStack(spacing: 16) {
            Text("Your prayer has been crafted")
                .font(Typography.Scripture.footnote)
                .foregroundStyle(DeepPrayerColors.secondaryText)

            HStack(spacing: 20) {
                ornateActionButton(icon: "bookmark.fill", label: "Save") {
                    // Save action
                }
                ornateActionButton(icon: "square.and.arrow.up", label: "Share") {
                    // Share action
                }
                ornateActionButton(icon: "arrow.counterclockwise", label: "New") {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        messages.removeAll()
                        showActionSheet = false
                        addWelcomeMessage()
                    }
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
        .background(
            DeepPrayerColors.sacredNavy.opacity(Theme.Opacity.nearOpaque)
                .background(.ultraThinMaterial)
        )
        .overlay(alignment: .top) {
            // Decorative divider
            HStack(spacing: 8) {
                Rectangle()
                    .fill(DeepPrayerColors.goldAccent.opacity(Theme.Opacity.subtle))
                    .frame(width: 40, height: 1)
                Image(systemName: "diamond.fill")
                    .font(Typography.Icon.xxxs)
                    .foregroundStyle(DeepPrayerColors.goldAccent.opacity(Theme.Opacity.medium))
                Rectangle()
                    .fill(DeepPrayerColors.goldAccent.opacity(Theme.Opacity.subtle))
                    .frame(width: 40, height: 1)
            }
        }
    }

    private func ornateActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(DeepPrayerColors.surfaceElevated)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(DeepPrayerColors.goldAccent.opacity(Theme.Opacity.subtle), lineWidth: 1)
                        )

                    Image(systemName: icon)
                        .font(Typography.Command.title3)
                        .foregroundStyle(DeepPrayerColors.goldAccent)
                }

                Text(label)
                    .font(Typography.Icon.xxs.weight(.medium))
                    .foregroundStyle(DeepPrayerColors.secondaryText)
            }
        }
    }

    // MARK: - Actions

    private func addWelcomeMessage() {
        let welcome = ConversationMessage(
            role: .assistant,
            content: "What weighs upon your heart today? Share your burden, and I shall weave it into sacred words.",
            tradition: nil
        )
        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            messages.append(welcome)
        }
    }

    private func sendMessage() {
        guard !inputText.isEmpty else { return }

        // Add user message
        let userMessage = ConversationMessage(
            role: .user,
            content: inputText,
            tradition: nil
        )
        withAnimation(.easeOut(duration: 0.3)) {
            messages.append(userMessage)
        }
        inputText = ""

        // Show typing indicator
        withAnimation(.easeOut(duration: 0.3).delay(0.3)) {
            isTyping = true
        }

        // Generate AI response after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                isTyping = false
            }

            // Add prayer response
            let prayer = MockPrayer.prayer(for: flowState.selectedTradition)
            let prayerMessage = ConversationMessage(
                role: .assistant,
                content: prayer.content + "\n\n" + prayer.amen,
                tradition: flowState.selectedTradition
            )
            withAnimation(.easeOut(duration: 0.4)) {
                messages.append(prayerMessage)
            }

            // Show action sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(Theme.Animation.settle) {
                    showActionSheet = true
                }
            }
        }
    }

    // MARK: - Animation

    private func startBreathingAnimation() {
        guard !reduceMotion else { return }
        withAnimation(
            .easeInOut(duration: 4)
            .repeatForever(autoreverses: true)
        ) {
            breathePhase = 1
        }
    }
}

// MARK: - Conversation Message Model

struct ConversationMessage: Identifiable, Equatable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let tradition: PrayerTradition?
    let timestamp = Date()

    enum MessageRole {
        case user
        case assistant
    }
}

// MARK: - Preview

#Preview("Ornate Prayer") {
    OrnatePrayerView()
}

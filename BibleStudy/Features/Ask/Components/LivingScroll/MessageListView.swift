import SwiftUI

// MARK: - Living Scroll View
// Revolutionary AI chat interface with illuminated manuscript aesthetic
// Enhanced with scroll-aware effects and vignette

struct LivingScrollView: View {
    let messages: [ChatMessage]
    let isLoading: Bool
    let lastUncertaintyLevel: UncertaintyLevel?
    let suggestedFollowUps: [String]
    let onSelectFollowUp: (String) -> Void
    let onDismissKeyboard: () -> Void

    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var scrollOffset: CGFloat = 0
    @State private var showScrollToBottom = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    // Calculate vignette intensity based on scroll (subtle effect)
    private var vignetteIntensity: CGFloat {
        guard !respectsReducedMotion else { return 0 }
        return min(scrollOffset / 300, 0.15) // Max 15% vignette
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.lg) {
                        // Scroll position tracker
                        GeometryReader { geometry in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: -geometry.frame(in: .named("scroll")).origin.y
                                )
                        }
                        .frame(height: 0)

                        // Messages
                        ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                            ManuscriptMessageView(
                                message: message,
                                isLatestAIMessage: isLatestAIMessage(message, at: index),
                                onCitationTap: { citation in
                                    navigateToCitation(citation)
                                }
                            )
                            .id(message.id)
                        }

                        // Uncertainty indicator
                        if let uncertainty = lastUncertaintyLevel,
                           uncertainty.shouldShowIndicator,
                           !isLoading {
                            LivingScrollUncertaintyBanner(level: uncertainty)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        // Suggested follow-ups
                        if !suggestedFollowUps.isEmpty && !isLoading {
                            LivingScrollFollowUps(
                                suggestions: suggestedFollowUps,
                                onSelect: onSelectFollowUp
                            )
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        // Loading state - Sacred Geometry with ambient glow
                        if isLoading {
                            EnhancedSacredGeometryThinking()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, Theme.Spacing.md)
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                    }
                    .padding(.vertical, Theme.Spacing.md)
                    .animation(Theme.Animation.settle, value: messages.count)
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                    updateScrollToBottomVisibility()
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture(perform: onDismissKeyboard)
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: isLoading) { _, newValue in
                    if newValue {
                        scrollToBottom(proxy: proxy)
                    }
                }

                // Scroll to bottom FAB
                if showScrollToBottom {
                    scrollToBottomButton(proxy: proxy)
                }
            }

            // Vignette overlay (subtle focus effect when scrolled)
            vignetteOverlay
        }
    }

    // MARK: - Vignette Overlay

    private var vignetteOverlay: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.clear,
                            Color.appBackground.opacity(vignetteIntensity)
                        ],
                        center: .center,
                        startRadius: geometry.size.width * 0.4,
                        endRadius: geometry.size.width * 0.8
                    )
                )
        }
        .allowsHitTesting(false)
    }

    // MARK: - Scroll to Bottom Button

    private func scrollToBottomButton(proxy: ScrollViewProxy) -> some View {
        Button {
            withAnimation(Theme.Animation.settle) {
                if let lastMessage = messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
            HapticService.shared.lightTap()
        } label: {
            ZStack {
                Circle()
                    .fill(Color("AppAccentAction").opacity(Theme.Opacity.overlay))
                    .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                Color("AppAccentAction").opacity(Theme.Opacity.textSecondary),
                                lineWidth: Theme.Stroke.hairline
                            )
                    )
                    .shadow(
                        color: Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground),
                        radius: 8,
                        y: 2
                    )

                Image(systemName: "chevron.down")
                    .font(Typography.Command.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("AppAccentAction"))
            }
        }
        .padding(.bottom, Theme.Spacing.lg)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Scroll Visibility

    private func updateScrollToBottomVisibility() {
        let shouldShow = scrollOffset > 200 && !messages.isEmpty
        if shouldShow != showScrollToBottom {
            withAnimation(Theme.Animation.fade) {
                showScrollToBottom = shouldShow
            }
        }
    }

    // MARK: - Helpers

    private func isLatestAIMessage(_ message: ChatMessage, at index: Int) -> Bool {
        guard message.isAssistant else { return false }
        // Check if this is the last assistant message
        let laterAssistantMessages = messages.dropFirst(index + 1).filter { $0.isAssistant }
        return laterAssistantMessages.isEmpty
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessage = messages.last else { return }
        withAnimation(Theme.Animation.settle) {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }

    private func navigateToCitation(_ citation: VerseRange) {
        let location = BibleLocation(bookId: citation.bookId, chapter: citation.chapter)
        appState.saveLocation(location)
        appState.lastScrolledVerse = citation.verseStart

        HapticService.shared.mediumTap()

        NotificationCenter.default.post(
            name: .deepLinkNavigationRequested,
            object: nil,
            userInfo: ["location": location]
        )
    }
}

// MARK: - Living Scroll Uncertainty Banner
// Styled uncertainty indicator for the Living Scroll

private struct LivingScrollUncertaintyBanner: View {
    let level: UncertaintyLevel

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(Typography.Command.caption)
                .foregroundStyle(Color("AppAccentAction"))

            Text(level.displayText)
                .font(Typography.Scripture.footnote)
                .foregroundStyle(Color("AppTextSecondary"))

            Spacer()
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppAccentAction").opacity(Theme.Opacity.overlay))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .strokeBorder(Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground), lineWidth: Theme.Stroke.hairline)
                )
        )
        .padding(.horizontal, Theme.Spacing.md)
    }
}

// MARK: - Living Scroll Follow-ups
// Styled follow-up suggestions with staggered entrance animation

private struct LivingScrollFollowUps: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var visibleButtons: Set<Int> = []
    @State private var headerVisible = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header with fade-in
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "arrow.turn.down.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppAccentAction"))

                Text("Continue exploring")
                    .font(Typography.Scripture.footnote)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .padding(.leading, Theme.Spacing.md)
            .opacity(headerVisible ? 1 : 0)
            .offset(y: headerVisible ? 0 : 5)

            // Buttons with staggered appearance
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(Array(suggestions.enumerated()), id: \.element) { index, question in
                        LivingScrollFollowUpButton(question: question) {
                            onSelect(question)
                        }
                        .opacity(visibleButtons.contains(index) ? 1 : 0)
                        .offset(x: visibleButtons.contains(index) ? 0 : 15)
                        .scaleEffect(visibleButtons.contains(index) ? 1 : 0.95)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
        .onAppear {
            animateAppearance()
        }
    }

    private func animateAppearance() {
        if respectsReducedMotion {
            headerVisible = true
            visibleButtons = Set(0..<suggestions.count)
            return
        }

        // Header appears first
        withAnimation(Theme.Animation.settle) {
            headerVisible = true
        }

        // Buttons appear with stagger
        for index in 0..<suggestions.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 + Double(index) * 0.1) {
                withAnimation(Theme.Animation.settle) {
                    _ = visibleButtons.insert(index)
                }
            }
        }
    }
}

// MARK: - Living Scroll Follow-up Button
// Enhanced with ripple effect and glow on press

private struct LivingScrollFollowUpButton: View {
    let question: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    @State private var glowIntensity: CGFloat = 0
    @State private var rippleScale: CGFloat = 0
    @State private var rippleOpacity: CGFloat = 0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        Button {
            performAction()
        } label: {
            ZStack {
                // Ripple effect layer
                if rippleScale > 0 {
                    Capsule()
                        .fill(Color("AppAccentAction").opacity(Theme.Opacity.textSecondary))
                        .scaleEffect(rippleScale)
                        .opacity(rippleOpacity)
                }

                // Button content
                Text(question)
                    .font(Typography.Scripture.footnote)
                    .foregroundStyle(Color("AppAccentAction"))
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(buttonBackground)
            }
            .scaleEffect(isPressed ? 0.98 : 1)
            .animation(Theme.Animation.fade, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        animatePress()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    animateRelease()
                }
        )
    }

    private var buttonBackground: some View {
        Capsule()
            .fill(Color("AppAccentAction").opacity(Theme.Opacity.overlay).opacity(Double(1.0 + glowIntensity * 0.1)))
            .overlay(
                Capsule()
                    .strokeBorder(
                        Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground + glowIntensity * 0.3),
                        lineWidth: Theme.Stroke.hairline
                    )
            )
            .shadow(
                color: Color("AppAccentAction").opacity(glowIntensity * 0.2),
                radius: 6 * glowIntensity
            )
    }

    private func animatePress() {
        guard !respectsReducedMotion else { return }

        withAnimation(Theme.Animation.fade) {
            glowIntensity = 1
        }
    }

    private func animateRelease() {
        guard !respectsReducedMotion else { return }

        withAnimation(Theme.Animation.settle) {
            glowIntensity = 0
        }
    }

    private func performAction() {
        HapticService.shared.lightTap()

        if !respectsReducedMotion {
            // Trigger ripple effect
            rippleScale = 0.5
            rippleOpacity = 0.5

            withAnimation(Theme.Animation.slowFade) {
                rippleScale = 1.5
                rippleOpacity = 0
            }

            // Reset after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                rippleScale = 0
            }
        }

        action()
    }
}

// MARK: - Staggered Follow-Up Buttons
// Follow-ups appear with staggered animation

private struct LivingScrollFollowUpsStaggered: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var visibleButtons: Set<Int> = []

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "arrow.turn.down.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppAccentAction"))

                Text("Continue exploring")
                    .font(Typography.Scripture.footnote)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .padding(.leading, Theme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(Array(suggestions.enumerated()), id: \.element) { index, question in
                        LivingScrollFollowUpButton(question: question) {
                            onSelect(question)
                        }
                        .opacity(visibleButtons.contains(index) ? 1 : 0)
                        .offset(x: visibleButtons.contains(index) ? 0 : 20)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
        .onAppear {
            animateButtonsAppearance()
        }
    }

    private func animateButtonsAppearance() {
        if respectsReducedMotion {
            visibleButtons = Set(0..<suggestions.count)
            return
        }

        for index in 0..<suggestions.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                withAnimation(Theme.Animation.settle) {
                    _ = visibleButtons.insert(index)
                }
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key
// Tracks scroll position for scroll-aware effects

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Enhanced Sacred Geometry Thinking
// Sacred Geometry with ambient glow background

private struct EnhancedSacredGeometryThinking: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var ambientGlowOpacity: CGFloat = 0.4

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Ambient glow behind the sacred geometry
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground),
                            Color("AppAccentAction").opacity(Theme.Opacity.subtle),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 16)
                .opacity(ambientGlowOpacity)
                .offset(x: -30, y: 0)

            SacredGeometryThinking()
        }
        .onAppear {
            guard !respectsReducedMotion else { return }

            // Gentle pulsing of ambient glow
            withAnimation(
                Theme.Animation.slowFade
                    .repeatForever(autoreverses: true)
            ) {
                ambientGlowOpacity = 0.6
            }
        }
    }
}

// MARK: - Preview

#Preview("Living Scroll View") {
    LivingScrollView(
        messages: [
            ChatMessage(
                threadId: UUID(),
                role: .user,
                content: "What does it mean to be blessed?"
            ),
            ChatMessage(
                threadId: UUID(),
                role: .assistant,
                content: "When Jesus spoke of the blessed in the Beatitudes, He was describing a profound state of spiritual flourishing that transcends earthly circumstances. The Greek word 'makarios' conveys a deep, abiding joy and divine favor that comes from alignment with God's kingdom values.",
                citations: [
                    VerseRange(bookId: 40, chapter: 5, verseStart: 3, verseEnd: 12)
                ]
            )
        ],
        isLoading: false,
        lastUncertaintyLevel: .medium,
        suggestedFollowUps: [
            "What are the Beatitudes?",
            "How can I apply this today?"
        ],
        onSelectFollowUp: { _ in },
        onDismissKeyboard: {}
    )
    .environment(AppState())
    .background(Color.appBackground)
}

#Preview("Living Scroll Loading") {
    LivingScrollView(
        messages: [
            ChatMessage(
                threadId: UUID(),
                role: .user,
                content: "Tell me about the parable of the sower"
            )
        ],
        isLoading: true,
        lastUncertaintyLevel: nil,
        suggestedFollowUps: [],
        onSelectFollowUp: { _ in },
        onDismissKeyboard: {}
    )
    .environment(AppState())
    .background(Color.appBackground)
}

import SwiftUI

// MARK: - Ask Chat Components
// Clean, reusable chat UI components adapted from prebuilt patterns
// Uses app design system while preserving all existing features

// MARK: - Chat Bubble

/// Styled message bubble with directional layout and citation support
struct ChatBubble: View {
    let message: ChatMessage
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.xs) {
            if message.isUser { Spacer(minLength: 0) }

            // AI sparkle indicator for assistant messages
            if !message.isUser {
                AISparkle()
                    .padding(.top, Theme.Spacing.sm)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: Theme.Spacing.xs) {
                bubbleContent
                citationsView
            }
            .containerRelativeFrame(.horizontal, alignment: message.isUser ? .trailing : .leading) { width, _ in
                width * 0.75
            }

            if !message.isUser { Spacer(minLength: 0) }
        }
        .transition(.asymmetric(
            insertion: .move(edge: message.isUser ? .trailing : .leading).combined(with: .opacity),
            removal: .opacity
        ))
    }

    // MARK: - Bubble Content

    private var bubbleContent: some View {
        Text(message.content)
            .font(Typography.Command.body)
            .foregroundStyle(message.isUser ? Colors.Semantic.onAccentAction(for: ThemeMode.current(from: colorScheme)) : Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
            .padding(Theme.Spacing.md)
            .background(bubbleBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .contextMenu {
                // Report button for assistant messages only
                if !message.isUser {
                    Button(role: .destructive) {
                        reportMessage()
                    } label: {
                        Label("Report Response", systemImage: "exclamationmark.bubble")
                    }

                    Button {
                        copyMessage()
                    } label: {
                        Label("Copy Text", systemImage: "doc.on.doc")
                    }
                }
            }
    }

    private func reportMessage() {
        // Log to analytics for review
        print("AskChat: User reported message \(message.id)")
        HapticService.shared.success()
        // TODO: Send to backend for review
    }

    private func copyMessage() {
        UIPasteboard.general.string = message.content
        HapticService.shared.lightTap()
    }

    private var bubbleBackground: Color {
        message.isUser ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Colors.Surface.surface(for: ThemeMode.current(from: colorScheme))
    }

    // MARK: - Citations

    @ViewBuilder
    private var citationsView: some View {
        if let citations = message.citations, !citations.isEmpty {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(citations) { citation in
                    CitationButton(citation: citation, appState: appState)
                }
            }
        }
    }
}

// MARK: - Citation Button

/// Tappable citation that navigates to the verse in the Read tab
struct CitationButton: View {
    let citation: VerseRange
    let appState: AppState

    @Environment(\.colorScheme) private var colorScheme

    var body: some View{
        Button(action: navigateToVerse) {
            HStack(spacing: 2) {
                Image(systemName: "book.closed")
                    .font(Typography.Command.meta)
                Text(citation.shortReference)
                    .font(Typography.Command.meta)
            }
            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.overlay))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Read \(citation.reference)")
        .accessibilityHint("Tap to open this verse in the Read tab")
    }

    private func navigateToVerse() {
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

// MARK: - Typing Indicator

/// Animated dots showing AI is processing
struct TypingIndicator: View {
    @State private var dotScales: [CGFloat] = [0.5, 0.7, 0.5]
    @Environment(\.colorScheme) private var colorScheme

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
                    .frame(
                        width: 8,
                        height: 8
                    )
                    .scaleEffect(dotScales[index])
            }
        }
        .padding(Theme.Spacing.md)
        .background(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .onAppear(perform: startAnimation)
    }

    private func startAnimation() {
        guard !respectsReducedMotion else {
            dotScales = [1, 1, 1]
            return
        }

        for index in 0..<3 {
            withAnimation(
                Theme.Animation.slowFade
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.2)
            ) {
                dotScales[index] = 1.2
            }
        }
    }
}

// MARK: - Chat Input Bar

/// Bottom input field with Liquid Glass and manuscript styling
struct ChatInputBar: View {
    @Binding var text: String
    var isLoading: Bool = false
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    @State private var glowIntensity: CGFloat = 0.3
    @State private var sendButtonScale: CGFloat = 1.0
    @State private var inputBarScale: CGFloat = 1.0
    @State private var showInkSplash = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Ink splash particles (behind input bar)
            if showInkSplash {
                InkSplashParticles()
                    .offset(x: 60, y: 0) // Position near send button
            }

            HStack(spacing: Theme.Spacing.md) {
                textField
                sendButton
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(inputBarBackground)
            .glassEffect(in: RoundedRectangle(cornerRadius: Theme.Radius.card))
            .scrollEdgeEffectStyle(.soft, for: .bottom)
            .scaleEffect(inputBarScale)
        }
        .onChange(of: isFocused.wrappedValue) { _, newValue in
            animateFocus(isFocused: newValue)
        }
    }

    // MARK: - Background with Ambient Glow

    private var inputBarBackground: some View {
        ZStack {
            // Base fill
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Colors.Surface.background(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.primary))

            // Ambient gold glow when focused
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(
                    Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(glowIntensity),
                    lineWidth: Theme.Stroke.control
                )
        }
    }

    // MARK: - Text Field

    private var textField: some View {
        TextField("Ask a question...", text: $text, axis: .vertical)
            .font(Typography.Command.body)
            .textFieldStyle(.plain)
            .focused(isFocused)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(textFieldBackground)
            .lineLimit(1...5)
            .submitLabel(.send)
            .onSubmit(handleSubmit)
    }

    private var textFieldBackground: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .fill(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(
                        Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(isFocused.wrappedValue ? Theme.Opacity.secondary : Theme.Opacity.faint),
                        lineWidth: Theme.Stroke.hairline
                    )
            )
    }

    // MARK: - Send Button (Quill Icon)

    private var sendButton: some View {
        Button(action: performSend) {
            ZStack {
                if isLoading {
                    // Sacred geometry loading indicator
                    ProgressView()
                        .tint(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
                        .scaleEffect(0.95)
                } else {
                    // Quill send icon
                    quillIcon
                }
            }
            .frame(width: 44, height: 44)
            .background(sendButtonBackground)
            .clipShape(Circle())
            .scaleEffect(sendButtonScale)
        }
        .disabled(text.isEmpty || isLoading)
        .animation(Theme.Animation.settle, value: text.isEmpty)
        .animation(Theme.Animation.fade, value: sendButtonScale)
    }

    private var quillIcon: some View {
        Image(systemName: "pencil.and.outline")
            .font(Typography.Command.headline)
            .foregroundStyle(
                text.isEmpty
                    ? Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme))
                    : Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme))
            )
            .rotationEffect(.degrees(-45))
    }

    private var sendButtonBackground: some View {
        Group {
            if text.isEmpty {
                Circle()
                    .fill(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)))
            } else {
                Circle()
                    .fill(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light))
                    .overlay(
                        Circle()
                            .strokeBorder(
                                Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary),
                                lineWidth: Theme.Stroke.hairline
                            )
                    )
            }
        }
    }

    // MARK: - Actions

    private func handleSubmit() {
        guard !text.isEmpty && !isLoading else { return }
        performSend()
    }

    private func performSend() {
        guard !text.isEmpty && !isLoading else { return }

        // Haptic feedback - wax seal impression
        HapticService.shared.divineReveal()

        if !respectsReducedMotion {
            // Phase 1: Input bar "lifts" with scale (Release)
            withAnimation(Theme.Animation.fade) {
                inputBarScale = 1.02
            }

            // Button press animation
            withAnimation(Theme.Animation.fade) {
                sendButtonScale = 0.98
            }

            // Trigger ink splash particles
            showInkSplash = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(Theme.Animation.settle) {
                    sendButtonScale = 1.0
                    inputBarScale = 1.0
                }
            }

            // Hide ink splash after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showInkSplash = false
            }
        }

        onSend()
    }

    // MARK: - Focus Animation

    private func animateFocus(isFocused: Bool) {
        if respectsReducedMotion {
            glowIntensity = isFocused ? 0.6 : 0.3
            return
        }

        withAnimation(Theme.Animation.slowFade) {
            glowIntensity = isFocused ? 0.6 : 0.3
        }
    }
}

// MARK: - Messages List View

/// Scrollable list of chat messages with auto-scroll
struct MessagesListView: View {
    let messages: [ChatMessage]
    let isLoading: Bool
    let lastUncertaintyLevel: UncertaintyLevel?
    let suggestedFollowUps: [String]
    let onSelectFollowUp: (String) -> Void
    let onDismissKeyboard: () -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.md) {
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)

                        // Show crisis support banner after crisis_support messages
                        if message.isCrisisSupport {
                            CrisisSupportBanner()
                        }
                    }

                    // Uncertainty indicator
                    if let uncertainty = lastUncertaintyLevel,
                       uncertainty.shouldShowIndicator,
                       !isLoading {
                        UncertaintyBanner(level: uncertainty)
                    }

                    // Suggested follow-ups
                    if !suggestedFollowUps.isEmpty && !isLoading {
                        SuggestedFollowUpsView(
                            suggestions: suggestedFollowUps,
                            onSelect: onSelectFollowUp
                        )
                    }

                    // Loading indicator
                    if isLoading {
                        AIInlineThinking()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
                .padding(Theme.Spacing.md)
                .animation(Theme.Animation.settle, value: messages.count)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture(perform: onDismissKeyboard)
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessage = messages.last else { return }
        withAnimation(Theme.Animation.settle) {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}

// MARK: - Uncertainty Banner

/// Shows when AI response has interpretive uncertainty
struct UncertaintyBanner: View {
    let level: UncertaintyLevel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle")
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Semantic.warning(for: ThemeMode.current(from: colorScheme)))

            Text(level.displayText)
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))

            Spacer()
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.input, style: .continuous)
                .fill(Colors.Semantic.warning(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint))
        )
        .padding(.horizontal, Theme.Spacing.md)
    }
}

// MARK: - Suggested Follow-ups View

/// Horizontal scrolling follow-up question buttons
struct SuggestedFollowUpsView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Follow-up questions")
                .font(Typography.Command.meta)
                .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
                .padding(.leading, Theme.Spacing.sm)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(suggestions, id: \.self) { question in
                        FollowUpButton(question: question) {
                            onSelect(question)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.sm)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Follow-up Button

/// Individual suggestion button
struct FollowUpButton: View {
    let question: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Text(question)
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                        .stroke(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary), lineWidth: Theme.Stroke.hairline)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Anchor Header

/// Shows the currently anchored verse passage
struct AnchorHeader: View {
    let anchor: VerseRange
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View{
        Button(action: onTap) {
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Anchored to:")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
                    Text(anchor.reference)
                        .font(Typography.Command.body.weight(.semibold))
                        .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
            }
            .padding(Theme.Spacing.md)
            .background(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Consent Required Bar

/// Shows when AI consent has not been granted
struct ConsentRequiredBar: View {
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "exclamationmark.shield")
                    .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))

                Text("Tap to enable AI assistant")
                    .font(Typography.Command.body)
                    .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Ask Header (DEPRECATED)
// NOTE: No longer used - mode is auto-determined by verse anchor presence
// Kept for backwards compatibility with previews

struct CompactAskHeader: View {
    @Binding var mode: ChatMode
    let anchorRange: VerseRange?
    let onAnchorTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    @Namespace private var modeSelection

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Mode pills - compact horizontal selector
            modePills

            Spacer()

            // Anchor badge (when in verse-anchored mode with selection)
            if mode == .verseAnchored {
                anchorBadge
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .background(headerBackground)
    }

    // MARK: - Mode Pills

    private var modePills: some View {
        HStack(spacing: 0) {
            ForEach(ChatMode.allCases, id: \.self) { chatMode in
                CompactModePill(
                    mode: chatMode,
                    isSelected: mode == chatMode,
                    namespace: modeSelection
                ) {
                    withAnimation(Theme.Animation.fade) {
                        mode = chatMode
                    }
                    HapticService.shared.selectionChanged()
                }
            }
        }
        .padding(2)
        .background(
            Capsule()
                .fill(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.primary))
        )
    }

    // MARK: - Anchor Badge

    @ViewBuilder
    private var anchorBadge: some View {
        Button(action: onAnchorTap) {
            HStack(spacing: 2) {
                if let anchor = anchorRange {
                    // Show selected anchor
                    Image(systemName: "bookmark.fill")
                        .font(Typography.Command.meta)
                        .fontWeight(.semibold)
                        .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))

                    Text(anchor.shortReference)
                        .font(Typography.Command.meta)
                        .fontWeight(.medium)
                        .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
                } else {
                    // Prompt to select
                    Image(systemName: "bookmark")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))

                    Text("Select verse")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
                }

                Image(systemName: "chevron.right")
                    .font(Typography.Icon.xxxs)
                    .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 2)
            .background(anchorBadgeBackground)
        }
        .buttonStyle(.plain)
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    private var anchorBadgeBackground: some View {
        Capsule()
            .fill(
                anchorRange != nil
                    ? Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint)
                    : Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.pressed)
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        anchorRange != nil
                            ? Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light)
                            : Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)),
                        lineWidth: Theme.Stroke.hairline
                    )
            )
    }

    // MARK: - Header Background

    private var headerBackground: some View {
        Rectangle()
            .fill(Colors.Surface.background(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.primary))
            .overlay(alignment: .bottom) {
                // Subtle golden divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: Theme.Stroke.hairline)
            }
    }
}

// MARK: - Compact Mode Pill

private struct CompactModePill: View {
    let mode: ChatMode
    let isSelected: Bool
    let namespace: Namespace.ID
    let onSelect: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    @State private var isPressed = false

    var body: some View {
        Button(action: onSelect) {
            Text(mode.displayName)
                .font(Typography.Command.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)) : Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs)
                .background(selectionBackground)
                .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(mode.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var selectionBackground: some View {
        if isSelected {
            Capsule()
                .fill(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light),
                            lineWidth: Theme.Stroke.hairline
                        )
                )
                .matchedGeometryEffect(id: "compactSelection", in: namespace)
        }
    }
}

// MARK: - Compact Ask Header Preview

#Preview("Compact Ask Header - General") {
    struct PreviewWrapper: View {
        @State private var mode: ChatMode = .general

        var body: some View {
            VStack(spacing: 0) {
                CompactAskHeader(
                    mode: $mode,
                    anchorRange: nil,
                    onAnchorTap: {}
                )

                Spacer()
            }
            .background(Colors.Surface.background(for: .dark))
        }
    }
    return PreviewWrapper()
}

#Preview("Compact Ask Header - Verse Anchored") {
    struct PreviewWrapper: View {
        @State private var mode: ChatMode = .verseAnchored

        var body: some View {
            VStack(spacing: 0) {
                CompactAskHeader(
                    mode: $mode,
                    anchorRange: VerseRange(bookId: 43, chapter: 3, verse: 16),
                    onAnchorTap: {}
                )

                Spacer()
            }
            .background(Colors.Surface.background(for: .dark))
        }
    }
    return PreviewWrapper()
}

// MARK: - Ask Mode Title Menu (DEPRECATED)
// NOTE: No longer used - mode is auto-determined by verse anchor presence
// Title is now a simple "Ask" text. Kept for backwards compatibility.

struct AskModeTitleMenu: View {
    @Binding var mode: ChatMode
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    var body: some View {
        Menu {
            ForEach(ChatMode.allCases, id: \.self) { chatMode in
                Button {
                    withAnimation(Theme.Animation.fade) {
                        mode = chatMode
                    }
                    HapticService.shared.selectionChanged()
                } label: {
                    HStack {
                        Label {
                            Text(chatMode.displayName)
                        } icon: {
                            Image(systemName: chatMode.iconName)
                        }

                        Spacer()

                        if mode == chatMode {
                            Image(systemName: "checkmark")
                                .font(Typography.Command.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
                        }
                    }
                }
            }
        } label: {
            titleLabel
        }
        .menuStyle(.borderlessButton)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(Theme.Animation.fade) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(Theme.Animation.fade) {
                        isPressed = false
                    }
                }
        )
    }

    // MARK: - Title Label

    private var titleLabel: some View {
        HStack(spacing: Theme.Spacing.xs) {
            // Mode title with premium serif typography
            Text(mode.displayName)
                .font(Typography.Scripture.heading)
                .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

            // Subtle chevron indicator
            Image(systemName: "chevron.down")
                .font(Typography.Icon.xxs)
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.primary))
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 2)
        .background(titleBackground)
        .scaleEffect(isPressed ? 0.97 : 1)
    }

    // MARK: - Title Background (subtle pill on press)

    private var titleBackground: some View {
        Capsule()
            .fill(isPressed ? Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.pressed) : Color.clear)
    }
}

// MARK: - Anchor Badge Header
// Shows the selected verse anchor when in verse-anchored mode
// Minimal header that appears below the navigation bar

struct AnchorBadgeHeader: View {
    let anchorRange: VerseRange?
    let onAnchorTap: () -> Void
    var onClearAnchor: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme

    @State private var isPressed = false
    @State private var pulseGold = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        HStack {
            Spacer()

            HStack(spacing: 0) {
                // Main badge button (tap to change anchor)
                Button {
                    HapticService.shared.lightTap()
                    onAnchorTap()
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        if let anchor = anchorRange {
                            // Show selected anchor
                            Image(systemName: "bookmark.fill")
                                .font(Typography.Command.meta)
                                .fontWeight(.semibold)
                                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))

                            Text(anchor.shortReference)
                                .font(Typography.Command.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                            Image(systemName: "chevron.right")
                                .font(Typography.Icon.xxxs)
                                .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
                        } else {
                            // Prompt to select
                            Image(systemName: "bookmark")
                                .font(Typography.Command.meta)
                                .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))

                            Text("Select a passage")
                                .font(Typography.Command.caption)
                                .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))

                            Image(systemName: "chevron.right")
                                .font(Typography.Icon.xxxs)
                                .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
                        }
                    }
                }
                .buttonStyle(.plain)

                // Clear button (only shown when anchor is set)
                if anchorRange != nil, let onClear = onClearAnchor {
                    // Divider
                    Rectangle()
                        .fill(Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)))
                        .frame(width: Theme.Stroke.hairline, height: 14)
                        .padding(.horizontal, Theme.Spacing.sm)

                    Button {
                        HapticService.shared.lightTap()
                        onClear()
                    } label: {
                        Image(systemName: "xmark")
                            .font(Typography.Command.meta)
                            .fontWeight(.medium)
                            .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear anchor")
                    .accessibilityHint("Removes the verse anchor and returns to general mode")
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
            .background(badgeBackground)
            .overlay(pulseOverlay)
            .scaleEffect(isPressed ? 0.99 : 1.0)
            .animation(Theme.Animation.fade, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )

            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xs)
        .background(headerBackground)
        .onAppear {
            triggerEntrancePulse()
        }
    }

    // MARK: - Entrance Pulse Animation

    private func triggerEntrancePulse() {
        guard anchorRange != nil, !respectsReducedMotion else { return }

        withAnimation(Theme.Animation.settle) {
            pulseGold = true
        }
        withAnimation(Theme.Animation.slowFade.delay(0.3)) {
            pulseGold = false
        }
    }

    @ViewBuilder
    private var pulseOverlay: some View {
        if !respectsReducedMotion {
            Capsule()
                .stroke(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)), lineWidth: Theme.Stroke.hairline)
                .opacity(pulseGold ? Theme.Opacity.secondary : 0)
                .scaleEffect(pulseGold ? 1.1 : 1.0)
        }
    }

    private var badgeBackground: some View {
        Capsule()
            .fill(
                anchorRange != nil
                    ? Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint)
                    : Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.pressed)
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        anchorRange != nil
                            ? Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light)
                            : Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)),
                        lineWidth: Theme.Stroke.hairline
                    )
            )
    }

    private var headerBackground: some View {
        Rectangle()
            .fill(Colors.Surface.background(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.primary))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: Theme.Stroke.hairline)
            }
    }
}

// MARK: - Ask Mode Title Menu Previews

#Preview("Ask Mode Title - General") {
    struct PreviewWrapper: View {
        @State private var mode: ChatMode = .general

        var body: some View {
            NavigationStack {
                Colors.Surface.background(for: .dark)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            AskModeTitleMenu(mode: $mode)
                        }
                    }
            }
        }
    }
    return PreviewWrapper()
}

#Preview("Ask Mode Title - Verse Anchored") {
    struct PreviewWrapper: View {
        @State private var mode: ChatMode = .verseAnchored

        var body: some View {
            NavigationStack {
                VStack(spacing: 0) {
                    AnchorBadgeHeader(
                        anchorRange: VerseRange(bookId: 43, chapter: 3, verse: 16),
                        onAnchorTap: {}
                    )
                    Spacer()
                }
                .background(Colors.Surface.background(for: .dark))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        AskModeTitleMenu(mode: $mode)
                    }
                }
            }
        }
    }
    return PreviewWrapper()
}

// MARK: - Ask Disclaimer Banner (Legacy - kept for reference)

/// Shows AI usage disclaimer for the Ask feature
/// NOTE: Replaced by CompactAskHeader - keeping for backwards compatibility
struct AskDisclaimerBanner: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))

            Text("AI study tool. Always verify with Scripture.")
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)))
    }
}

// MARK: - Crisis Support Banner

/// Hardcoded crisis support banner shown when responseType == .crisisSupport
/// IMPORTANT: Hotline info is hardcoded (not AI-generated) for safety
/// Enhanced with compassionate design: breathing heart, warm gradient, delayed appearance
struct CrisisSupportBanner: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var heartScale: CGFloat = 1.0
    @State private var heartOpacity: CGFloat = 1.0
    @State private var isVisible = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Header with breathing heart
            HStack(spacing: Theme.Spacing.sm) {
                breathingHeart

                Text("You're Not Alone")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
            }

            Text("If you're in crisis, please reach out for help:")
                .font(Typography.Command.body)
                .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                .multilineTextAlignment(.center)

            // 988 Hotline (US) - warm styling
            Link(destination: URL(string: "tel:988")!) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "phone.fill")
                    Text("Call or Text 988")
                }
                .font(Typography.Command.body.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    LinearGradient(
                        colors: [
                            Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)),
                            Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.primary - 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                .shadow(color: Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary), radius: 8, y: 4)
            }

            Text("988 Suicide & Crisis Lifeline (US)")
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))

            // International disclaimer
            Text("If you're outside the US, please contact your local emergency services or a crisis helpline in your country.")
                .font(Typography.Command.meta)
                .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.md)

            // Warm divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: Theme.Stroke.hairline)
                .padding(.vertical, Theme.Spacing.xs)

            Text("You matter. Please reach out to someone you trust.")
                .font(Typography.Command.subheadline)
                .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.lg)
        .background(crisisBannerBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(
                    Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light),
                    lineWidth: Theme.Stroke.hairline
                )
        )
        .padding(.horizontal, Theme.Spacing.md)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)
        .onAppear {
            startAppearanceAnimation()
        }
    }

    // MARK: - Breathing Heart

    private var breathingHeart: some View {
        Image(systemName: "heart.fill")
            .font(Typography.Command.title3)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)),
                        Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.pressed)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .scaleEffect(heartScale)
            .opacity(heartOpacity)
            .shadow(color: Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.disabled), radius: 8)
    }

    // MARK: - Warm Gradient Background

    private var crisisBannerBackground: some View {
        LinearGradient(
            colors: [
                Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint),
                Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint + 0.02),
                Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint - 0.03)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Animations

    private func startAppearanceAnimation() {
        if respectsReducedMotion {
            isVisible = true
            heartScale = 1.0
            heartOpacity = 1.0
            return
        }

        // Delayed appearance (0.5s) for less jarring entry
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(Theme.Animation.slowFade) {
                isVisible = true
            }

            // Compassionate heartbeat haptic
            HapticService.shared.compassionateHeartbeat()

            // Start breathing animation after appearance
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                startBreathingAnimation()
            }
        }
    }

    private func startBreathingAnimation() {
        guard !respectsReducedMotion else { return }

        // Gentle heartbeat rhythm (slower than real heartbeat for calmness)
        withAnimation(
            Theme.Animation.fade
        ) {
            heartScale = 1.08
            heartOpacity = Theme.Opacity.primary
        }
    }
}

// MARK: - Ink Splash Particles
// Subtle golden particles that burst from the send button when sending a message

struct InkSplashParticles: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var particles: [InkParticle] = []

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.offset.x, y: particle.offset.y)
                    .opacity(particle.opacity)
                    .blur(radius: particle.blur)
            }
        }
        .onAppear {
            guard !respectsReducedMotion else { return }
            spawnParticles()
        }
    }

    private func spawnParticles() {
        // Create 8-12 particles
        let particleCount = Int.random(in: 8...12)

        for i in 0..<particleCount {
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 20...60)
            let delay = Double(i) * 0.02

            let particle = InkParticle(
                id: UUID(),
                size: CGFloat.random(in: 3...8),
                offset: .zero,
                targetOffset: CGPoint(
                    x: cos(angle) * distance,
                    y: sin(angle) * distance - 20 // Bias upward
                ),
                opacity: 1.0,
                blur: 0
            )

            particles.append(particle)

            // Animate particle outward
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(Theme.Animation.slowFade) {
                    if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                        particles[index].offset = particles[index].targetOffset
                        particles[index].opacity = 0
                        particles[index].blur = 2
                    }
                }
            }
        }
    }
}

private struct InkParticle: Identifiable {
    let id: UUID
    var size: CGFloat
    var offset: CGPoint
    var targetOffset: CGPoint
    var opacity: Double
    var blur: CGFloat
}

// MARK: - Previews

#Preview("Crisis Support Banner") {
    CrisisSupportBanner()
        .padding()
}

#Preview("Chat Bubble - User") {
    ChatBubble(message: ChatMessage(
        threadId: UUID(),
        role: .user,
        content: "What does the Bible say about love?"
    ))
    .environment(AppState())
    .padding()
}

#Preview("Chat Bubble - Assistant") {
    ChatBubble(message: ChatMessage(
        threadId: UUID(),
        role: .assistant,
        content: "The Bible speaks extensively about love. In 1 Corinthians 13:4-7, Paul describes the nature of love..."
    ))
    .environment(AppState())
    .padding()
}

#Preview("Typing Indicator") {
    TypingIndicator()
        .padding()
}

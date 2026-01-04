import SwiftUI

// MARK: - Ask Chat Components
// Clean, reusable chat UI components adapted from prebuilt patterns
// Uses app design system while preserving all existing features

// MARK: - Chat Bubble

/// Styled message bubble with directional layout and citation support
struct ChatBubble: View {
    let message: ChatMessage
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.xs) {
            if message.isUser { Spacer(minLength: 0) }

            // AI sparkle indicator for assistant messages
            if !message.isUser {
                AISparkle()
                    .padding(.top, AppTheme.Spacing.sm)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: AppTheme.Spacing.xs) {
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
            .font(Typography.UI.body)
            .foregroundStyle(message.isUser ? Color.white : Color.primaryText)
            .padding(AppTheme.Spacing.md)
            .background(bubbleBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
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
        message.isUser ? Color.scholarIndigo : Color.surfaceBackground
    }

    // MARK: - Citations

    @ViewBuilder
    private var citationsView: some View {
        if let citations = message.citations, !citations.isEmpty {
            HStack(spacing: AppTheme.Spacing.xs) {
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

    var body: some View {
        Button(action: navigateToVerse) {
            HStack(spacing: AppTheme.Spacing.xxs) {
                Image(systemName: "book.closed")
                    .font(Typography.UI.caption2)
                Text(citation.shortReference)
                    .font(Typography.UI.caption2)
            }
            .foregroundStyle(Color.scholarIndigo)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(Color.scholarIndigo.opacity(0.1))
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

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.tertiaryText)
                    .frame(
                        width: AppTheme.ComponentSize.indicator,
                        height: AppTheme.ComponentSize.indicator
                    )
                    .scaleEffect(dotScales[index])
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
        .onAppear(perform: startAnimation)
    }

    private func startAnimation() {
        guard !respectsReducedMotion else {
            dotScales = [1, 1, 1]
            return
        }

        for index in 0..<3 {
            withAnimation(
                AppTheme.Animation.slow
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

            HStack(spacing: AppTheme.Spacing.md) {
                textField
                sendButton
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(inputBarBackground)
            .glassEffect(in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl))
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
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                .fill(Color.primaryBackground.opacity(AppTheme.Opacity.nearOpaque))

            // Ambient gold glow when focused
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                .strokeBorder(
                    Color.divineGold.opacity(glowIntensity),
                    lineWidth: AppTheme.Border.medium
                )
        }
    }

    // MARK: - Text Field

    private var textField: some View {
        TextField("Ask a question...", text: $text, axis: .vertical)
            .font(Typography.UI.body)
            .textFieldStyle(.plain)
            .focused(isFocused)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(textFieldBackground)
            .lineLimit(1...5)
            .submitLabel(.send)
            .onSubmit(handleSubmit)
    }

    private var textFieldBackground: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
            .fill(Color.surfaceBackground)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                    .strokeBorder(
                        Color.divineGold.opacity(isFocused.wrappedValue ? AppTheme.Opacity.medium : AppTheme.Opacity.subtle),
                        lineWidth: AppTheme.Border.thin
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
                        .tint(Color.divineGold)
                        .scaleEffect(AppTheme.Scale.reduced)
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
        .animation(AppTheme.Animation.sacredSpring, value: text.isEmpty)
        .animation(AppTheme.Animation.quick, value: sendButtonScale)
    }

    private var quillIcon: some View {
        Image(systemName: "pencil.and.outline")
            .font(Typography.UI.headline)
            .foregroundStyle(
                text.isEmpty
                    ? Color.tertiaryText
                    : Color.divineGold
            )
            .rotationEffect(.degrees(-45))
    }

    private var sendButtonBackground: some View {
        Group {
            if text.isEmpty {
                Circle()
                    .fill(Color.surfaceBackground)
            } else {
                Circle()
                    .fill(Color.divineGold.opacity(AppTheme.Opacity.light))
                    .overlay(
                        Circle()
                            .strokeBorder(
                                Color.divineGold.opacity(AppTheme.Opacity.medium),
                                lineWidth: AppTheme.Border.thin
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
            withAnimation(AppTheme.Animation.quick) {
                inputBarScale = 1.02
            }

            // Button press animation
            withAnimation(AppTheme.Animation.quick) {
                sendButtonScale = AppTheme.Scale.pressed
            }

            // Trigger ink splash particles
            showInkSplash = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppTheme.Animation.sacredSpring) {
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

        withAnimation(AppTheme.Animation.luminous) {
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
                LazyVStack(spacing: AppTheme.Spacing.md) {
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
                .padding(AppTheme.Spacing.md)
                .animation(AppTheme.Animation.standard, value: messages.count)
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
        withAnimation(AppTheme.Animation.standard) {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}

// MARK: - Uncertainty Banner

/// Shows when AI response has interpretive uncertainty
struct UncertaintyBanner: View {
    let level: UncertaintyLevel

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.warning)

            Text(level.displayText)
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)

            Spacer()
        }
        .padding(AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                .fill(Color.warning.opacity(AppTheme.Opacity.subtle))
        )
        .padding(.horizontal, AppTheme.Spacing.md)
    }
}

// MARK: - Suggested Follow-ups View

/// Horizontal scrolling follow-up question buttons
struct SuggestedFollowUpsView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Follow-up questions")
                .font(Typography.UI.caption2)
                .foregroundStyle(Color.tertiaryText)
                .padding(.leading, AppTheme.Spacing.sm)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(suggestions, id: \.self) { question in
                        FollowUpButton(question: question) {
                            onSelect(question)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.sm)
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}

// MARK: - Follow-up Button

/// Individual suggestion button
struct FollowUpButton: View {
    let question: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(question)
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.scholarIndigo)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .stroke(Color.scholarIndigo.opacity(AppTheme.Opacity.heavy), lineWidth: AppTheme.Border.thin)
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

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(Color.scholarIndigo)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text("Anchored to:")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)
                    Text(anchor.reference)
                        .font(Typography.UI.bodyBold)
                        .foregroundStyle(Color.primaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(AppTheme.Spacing.md)
            .background(Color.surfaceBackground)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Consent Required Bar

/// Shows when AI consent has not been granted
struct ConsentRequiredBar: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "exclamationmark.shield")
                    .foregroundStyle(Color.tertiaryText)

                Text("Tap to enable AI assistant")
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.secondaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(Color.surfaceBackground)
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

    @Namespace private var modeSelection

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            // Mode pills - compact horizontal selector
            modePills

            Spacer()

            // Anchor badge (when in verse-anchored mode with selection)
            if mode == .verseAnchored {
                anchorBadge
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
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
                    withAnimation(AppTheme.Animation.quick) {
                        mode = chatMode
                    }
                    HapticService.shared.selectionChanged()
                }
            }
        }
        .padding(AppTheme.Spacing.xxs)
        .background(
            Capsule()
                .fill(Color.surfaceBackground.opacity(AppTheme.Opacity.strong))
        )
    }

    // MARK: - Anchor Badge

    @ViewBuilder
    private var anchorBadge: some View {
        Button(action: onAnchorTap) {
            HStack(spacing: AppTheme.Spacing.xxs) {
                if let anchor = anchorRange {
                    // Show selected anchor
                    Image(systemName: "bookmark.fill")
                        .font(Typography.UI.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.divineGold)

                    Text(anchor.shortReference)
                        .font(Typography.UI.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.primaryText)
                } else {
                    // Prompt to select
                    Image(systemName: "bookmark")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)

                    Text("Select verse")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)
                }

                Image(systemName: "chevron.right")
                    .font(Typography.UI.iconXxxs)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xxs)
            .background(anchorBadgeBackground)
        }
        .buttonStyle(.plain)
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    private var anchorBadgeBackground: some View {
        Capsule()
            .fill(
                anchorRange != nil
                    ? Color.divineGold.opacity(AppTheme.Opacity.subtle)
                    : Color.surfaceBackground.opacity(AppTheme.Opacity.pressed)
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        anchorRange != nil
                            ? Color.divineGold.opacity(AppTheme.Opacity.light)
                            : Color.divider,
                        lineWidth: AppTheme.Divider.hairline
                    )
            )
    }

    // MARK: - Header Background

    private var headerBackground: some View {
        Rectangle()
            .fill(Color.appBackground.opacity(AppTheme.Opacity.nearOpaque))
            .overlay(alignment: .bottom) {
                // Subtle golden divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.divineGold.opacity(AppTheme.Opacity.light),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: AppTheme.Divider.hairline)
            }
    }
}

// MARK: - Compact Mode Pill

private struct CompactModePill: View {
    let mode: ChatMode
    let isSelected: Bool
    let namespace: Namespace.ID
    let onSelect: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onSelect) {
            Text(mode.displayName)
                .font(Typography.UI.caption1)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.divineGold : Color.secondaryText)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
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
                .fill(Color.divineGold.opacity(AppTheme.Opacity.subtle))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            Color.divineGold.opacity(AppTheme.Opacity.light),
                            lineWidth: AppTheme.Divider.hairline
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
            .background(Color.appBackground)
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
            .background(Color.appBackground)
        }
    }
    return PreviewWrapper()
}

// MARK: - Ask Mode Title Menu (DEPRECATED)
// NOTE: No longer used - mode is auto-determined by verse anchor presence
// Title is now a simple "Ask" text. Kept for backwards compatibility.

struct AskModeTitleMenu: View {
    @Binding var mode: ChatMode
    @State private var isPressed = false

    var body: some View {
        Menu {
            ForEach(ChatMode.allCases, id: \.self) { chatMode in
                Button {
                    withAnimation(AppTheme.Animation.quick) {
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
                                .font(Typography.UI.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.divineGold)
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
                    withAnimation(AppTheme.Animation.quick) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(AppTheme.Animation.quick) {
                        isPressed = false
                    }
                }
        )
    }

    // MARK: - Title Label

    private var titleLabel: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            // Mode title with premium serif typography
            Text(mode.displayName)
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)

            // Subtle chevron indicator
            Image(systemName: "chevron.down")
                .font(Typography.UI.iconXxs)
                .foregroundStyle(Color.divineGold.opacity(AppTheme.Opacity.strong))
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xxs)
        .background(titleBackground)
        .scaleEffect(isPressed ? 0.97 : 1)
    }

    // MARK: - Title Background (subtle pill on press)

    private var titleBackground: some View {
        Capsule()
            .fill(isPressed ? Color.surfaceBackground.opacity(AppTheme.Opacity.pressed) : Color.clear)
    }
}

// MARK: - Anchor Badge Header
// Shows the selected verse anchor when in verse-anchored mode
// Minimal header that appears below the navigation bar

struct AnchorBadgeHeader: View {
    let anchorRange: VerseRange?
    let onAnchorTap: () -> Void
    var onClearAnchor: (() -> Void)?

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
                    HStack(spacing: AppTheme.Spacing.xs) {
                        if let anchor = anchorRange {
                            // Show selected anchor
                            Image(systemName: "bookmark.fill")
                                .font(Typography.UI.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.divineGold)

                            Text(anchor.shortReference)
                                .font(Typography.UI.caption1)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.primaryText)

                            Image(systemName: "chevron.right")
                                .font(Typography.UI.iconXxxs)
                                .foregroundStyle(Color.tertiaryText)
                        } else {
                            // Prompt to select
                            Image(systemName: "bookmark")
                                .font(Typography.UI.caption2)
                                .foregroundStyle(Color.tertiaryText)

                            Text("Select a passage")
                                .font(Typography.UI.caption1)
                                .foregroundStyle(Color.tertiaryText)

                            Image(systemName: "chevron.right")
                                .font(Typography.UI.iconXxxs)
                                .foregroundStyle(Color.tertiaryText)
                        }
                    }
                }
                .buttonStyle(.plain)

                // Clear button (only shown when anchor is set)
                if anchorRange != nil, let onClear = onClearAnchor {
                    // Divider
                    Rectangle()
                        .fill(Color.divider)
                        .frame(width: AppTheme.Divider.hairline, height: Typography.Scale.sm)
                        .padding(.horizontal, AppTheme.Spacing.sm)

                    Button {
                        HapticService.shared.lightTap()
                        onClear()
                    } label: {
                        Image(systemName: "xmark")
                            .font(Typography.UI.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.tertiaryText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear anchor")
                    .accessibilityHint("Removes the verse anchor and returns to general mode")
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(badgeBackground)
            .overlay(pulseOverlay)
            .scaleEffect(isPressed ? AppTheme.Scale.subtle : 1.0)
            .animation(AppTheme.Animation.quick, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )

            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(headerBackground)
        .onAppear {
            triggerEntrancePulse()
        }
    }

    // MARK: - Entrance Pulse Animation

    private func triggerEntrancePulse() {
        guard anchorRange != nil, !respectsReducedMotion else { return }

        withAnimation(AppTheme.Animation.sacredSpring) {
            pulseGold = true
        }
        withAnimation(AppTheme.Animation.reverent.delay(0.3)) {
            pulseGold = false
        }
    }

    @ViewBuilder
    private var pulseOverlay: some View {
        if !respectsReducedMotion {
            Capsule()
                .stroke(Color.divineGold, lineWidth: AppTheme.Border.thin)
                .opacity(pulseGold ? AppTheme.Opacity.medium : 0)
                .scaleEffect(pulseGold ? 1.1 : 1.0)
        }
    }

    private var badgeBackground: some View {
        Capsule()
            .fill(
                anchorRange != nil
                    ? Color.divineGold.opacity(AppTheme.Opacity.subtle)
                    : Color.surfaceBackground.opacity(AppTheme.Opacity.pressed)
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        anchorRange != nil
                            ? Color.divineGold.opacity(AppTheme.Opacity.light)
                            : Color.divider,
                        lineWidth: AppTheme.Divider.hairline
                    )
            )
    }

    private var headerBackground: some View {
        Rectangle()
            .fill(Color.appBackground.opacity(AppTheme.Opacity.nearOpaque))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.divineGold.opacity(AppTheme.Opacity.subtle),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: AppTheme.Divider.hairline)
            }
    }
}

// MARK: - Ask Mode Title Menu Previews

#Preview("Ask Mode Title - General") {
    struct PreviewWrapper: View {
        @State private var mode: ChatMode = .general

        var body: some View {
            NavigationStack {
                Color.appBackground
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
                .background(Color.appBackground)
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
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.divineGold)

            Text("AI study tool. Always verify with Scripture.")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(Color.surfaceBackground)
    }
}

// MARK: - Crisis Support Banner

/// Hardcoded crisis support banner shown when responseType == .crisisSupport
/// IMPORTANT: Hotline info is hardcoded (not AI-generated) for safety
/// Enhanced with compassionate design: breathing heart, warm gradient, delayed appearance
struct CrisisSupportBanner: View {
    @State private var heartScale: CGFloat = 1.0
    @State private var heartOpacity: CGFloat = 1.0
    @State private var isVisible = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Header with breathing heart
            HStack(spacing: AppTheme.Spacing.sm) {
                breathingHeart

                Text("You're Not Alone")
                    .font(Typography.Display.headline)
                    .foregroundStyle(Color.primaryText)
            }

            Text("If you're in crisis, please reach out for help:")
                .font(Typography.UI.warmBody)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)

            // 988 Hotline (US) - warm styling
            Link(destination: URL(string: "tel:988")!) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "phone.fill")
                    Text("Call or Text 988")
                }
                .font(Typography.UI.bodyBold)
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(
                    LinearGradient(
                        colors: [
                            Color.vermillion,
                            Color.vermillion.opacity(AppTheme.Opacity.high - 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                .shadow(color: Color.vermillion.opacity(AppTheme.Opacity.medium), radius: AppTheme.Blur.medium, y: 4)
            }

            Text("988 Suicide & Crisis Lifeline (US)")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.tertiaryText)

            // International disclaimer
            Text("If you're outside the US, please contact your local emergency services or a crisis helpline in your country.")
                .font(Typography.UI.caption2)
                .foregroundStyle(Color.tertiaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.md)

            // Warm divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.vermillion.opacity(AppTheme.Opacity.lightMedium),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: AppTheme.Divider.thin)
                .padding(.vertical, AppTheme.Spacing.xs)

            Text("You matter. Please reach out to someone you trust.")
                .font(Typography.UI.warmSubheadline)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.lg)
        .background(crisisBannerBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .strokeBorder(
                    Color.vermillion.opacity(AppTheme.Opacity.light),
                    lineWidth: AppTheme.Border.thin
                )
        )
        .padding(.horizontal, AppTheme.Spacing.md)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)
        .onAppear {
            startAppearanceAnimation()
        }
    }

    // MARK: - Breathing Heart

    private var breathingHeart: some View {
        Image(systemName: "heart.fill")
            .font(Typography.UI.title3)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color.vermillion,
                        Color.vermillion.opacity(AppTheme.Opacity.pressed)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .scaleEffect(heartScale)
            .opacity(heartOpacity)
            .shadow(color: Color.vermillion.opacity(AppTheme.Opacity.disabled), radius: AppTheme.Blur.medium)
    }

    // MARK: - Warm Gradient Background

    private var crisisBannerBackground: some View {
        LinearGradient(
            colors: [
                Color.vermillion.opacity(AppTheme.Opacity.faint),
                Color.vermillion.opacity(AppTheme.Opacity.subtle + 0.02),
                Color.divineGold.opacity(AppTheme.Opacity.faint - 0.03)
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
            withAnimation(AppTheme.Animation.reverent) {
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
            AppTheme.Animation.pulse
        ) {
            heartScale = 1.08
            heartOpacity = AppTheme.Opacity.high
        }
    }
}

// MARK: - Ink Splash Particles
// Subtle golden particles that burst from the send button when sending a message

struct InkSplashParticles: View {
    @State private var particles: [InkParticle] = []

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(Color.divineGold)
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
                withAnimation(AppTheme.Animation.slow) {
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

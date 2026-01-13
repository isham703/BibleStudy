import SwiftUI

// MARK: - Chat Message View
// Renders chat messages with appropriate styling
// AI: Decorative Stoic-Roman style
// User: Modern minimal style

struct ChatMessageView: View {
    let message: ChatMessage
    let isLatestAIMessage: Bool
    let onCitationTap: (VerseRange) -> Void

    var body: some View {
        if message.isUser {
            UserMessageView(content: message.content)
        } else {
            AIMessageView(
                message: message,
                isAnimating: isLatestAIMessage,
                onCitationTap: onCitationTap
            )
        }
    }
}

// MARK: - User Message View
// Clean, modern styling to contrast with AI's decorative style
// Enhanced with "wax seal" entrance animation

private struct UserMessageView: View {
    let content: String

    @Environment(\.colorScheme) private var colorScheme
    @State private var appearProgress: CGFloat = 0
    @State private var rotationAngle: Double = -2
    @State private var borderGlow: CGFloat = 0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        HStack {
            Spacer(minLength: Theme.Spacing.xxl)

            Text(content)
                .font(Typography.Command.body)
                .foregroundStyle(.white)
                .padding(Theme.Spacing.md)
                .background(messageBackground)
                .rotation3DEffect(
                    .degrees(rotationAngle),
                    axis: (x: 0, y: 0, z: 1),
                    anchor: .bottomTrailing
                )
                .scaleEffect(0.99 + ((1 - 0.99) * appearProgress))
                .opacity(Double(appearProgress))
        }
        .padding(.horizontal, Theme.Spacing.md)
        .onAppear {
            startEntranceAnimation()
        }
    }

    private var messageBackground: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .fill(Color("AppAccentAction"))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(
                        Color("AppAccentAction").opacity(Theme.Opacity.textSecondary + borderGlow * 0.3),
                        lineWidth: Theme.Stroke.hairline + (borderGlow * 1)
                    )
            )
            .shadow(
                color: Color("AppAccentAction").opacity(borderGlow * 0.2),
                radius: 8 * borderGlow,
                y: 2
            )
    }

    private func startEntranceAnimation() {
        if respectsReducedMotion {
            appearProgress = 1
            rotationAngle = 0
            borderGlow = 0
            return
        }

        // Phase 1: Ascent (0-200ms) - Message floats up with rotation
        withAnimation(Theme.Animation.settle) {
            appearProgress = 1
        }

        withAnimation(Theme.Animation.settle) {
            rotationAngle = 0
        }

        // Phase 2: Seal (200-400ms) - Gold border materializes with shimmer
        withAnimation(Theme.Animation.fade.delay(0.15)) {
            borderGlow = 1
        }

        // Phase 3: Settle (400-600ms) - Border glow fades to normal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(Theme.Animation.settle) {
                borderGlow = 0
            }
        }
    }
}

// MARK: - AI Message View
// Decorative Stoic-Roman styling with optional animation
// Enhanced with ambient glow anticipation before text appears

private struct AIMessageView: View {
    let message: ChatMessage
    let isAnimating: Bool
    let onCitationTap: (VerseRange) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var showContent = false
    @State private var ambientGlowOpacity: CGFloat = 0
    @State private var showCitations = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Ambient golden glow (appears before content)
            if isAnimating && !respectsReducedMotion {
                ambientGlow
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Crisis support banner if needed
                if message.isCrisisSupport {
                    CrisisBanner()
                }

                // Main content with illuminated capital
                messageContent

                // Citations below text (with sequential animation)
                if let citations = message.citations, !citations.isEmpty, showCitations {
                    SequentialCitationGroup(
                        citations: citations,
                        onCitationTap: onCitationTap
                    )
                } else if let citations = message.citations, !citations.isEmpty, !isAnimating {
                    // Non-animating messages show citations immediately
                    CitationGroup(
                        citations: citations,
                        onCitationTap: onCitationTap
                    )
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .onAppear {
            startRevealSequence()
        }
    }

    // MARK: - Ambient Glow

    private var ambientGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color("AppAccentAction").opacity(Theme.Opacity.textSecondary),
                        Color("AppAccentAction").opacity(Theme.Opacity.subtle),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 100
                )
            )
            .frame(width: 200, height: 200)
            .blur(radius: 16)
            .opacity(ambientGlowOpacity)
            .offset(x: -20, y: 20)
    }

    // MARK: - Reveal Sequence

    private func startRevealSequence() {
        if respectsReducedMotion || !isAnimating {
            showContent = true
            showCitations = true
            return
        }

        // Phase 1: Ambient glow pulses (0-400ms)
        withAnimation(Theme.Animation.settle) {
            ambientGlowOpacity = 1
        }

        // Phase 2: Content begins appearing (200ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showContent = true

            // Glow fades as content appears
            withAnimation(Theme.Animation.slowFade) {
                ambientGlowOpacity = 0
            }
        }

        // Phase 3: Citations appear after content has started
        // Delay based on content length (longer content = longer wait)
        let citationDelay = min(Double(message.content.count) * 0.015, 2.0) + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + citationDelay) {
            withAnimation(Theme.Animation.settle) {
                showCitations = true
            }
        }
    }

    @ViewBuilder
    private var messageContent: some View {
        if shouldUseDropCap {
            DropCapInkFlowText(
                text: message.content,
                isAnimating: isAnimating && showContent
            )
        } else {
            StreamingTextView(
                text: message.content,
                isAnimating: isAnimating && showContent
            )
        }
    }

    private var shouldUseDropCap: Bool {
        // Use drop cap for substantial responses
        message.content.count > 50 && message.content.first?.isLetter == true
    }
}

// MARK: - Sequential Citation Group
// Citations appear one by one with staggered delays

private struct SequentialCitationGroup: View {
    let citations: [VerseRange]
    let onCitationTap: (VerseRange) -> Void

    @State private var visibleCitations: Set<String> = []

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Golden thread connection
            SequentialGoldenThread(citationCount: citations.count)
                .frame(height: 20)

            // Citation pills with staggered appearance
            CitationFlowLayout(spacing: Theme.Spacing.sm) {
                ForEach(Array(citations.enumerated()), id: \.element.id) { index, citation in
                    CitationPill(citation: citation) {
                        onCitationTap(citation)
                    }
                    .opacity(visibleCitations.contains(citation.id) ? 1 : 0)
                    .offset(y: visibleCitations.contains(citation.id) ? 0 : 8)
                    .scaleEffect(visibleCitations.contains(citation.id) ? 1 : 0.9)
                }
            }
        }
        .padding(.top, Theme.Spacing.xs)
        .onAppear {
            animateCitationsSequentially()
        }
    }

    private func animateCitationsSequentially() {
        if respectsReducedMotion {
            visibleCitations = Set(citations.map(\.id))
            return
        }

        // Stagger each citation appearance by 150ms
        for (index, citation) in citations.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15 + 0.1) {
                withAnimation(Theme.Animation.settle) {
                    _ = visibleCitations.insert(citation.id)
                }

                // Haptic for each citation
                HapticService.shared.lightTap()
            }
        }
    }
}

// MARK: - Sequential Golden Thread
// Thread draws progressively as citations appear

private struct SequentialGoldenThread: View {
    let citationCount: Int

    @Environment(\.colorScheme) private var colorScheme
    @State private var threadLength: CGFloat = 0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let midX = width * 0.15
                let height = geometry.size.height

                path.move(to: CGPoint(x: midX, y: 0))
                path.addLine(to: CGPoint(x: midX, y: height * 0.6))
                path.addLine(to: CGPoint(x: midX + 8, y: height * 0.6))
            }
            .trim(from: 0, to: threadLength)
            .stroke(
                Color("AppAccentAction").opacity(Theme.Opacity.textPrimary),
                style: StrokeStyle(
                    lineWidth: Theme.Stroke.hairline,
                    lineCap: .round,
                    dash: [4, 4]
                )
            )

            // Connection node
            Circle()
                .fill(Color("AppAccentAction"))
                .frame(width: 4, height: 4)
                .position(x: geometry.size.width * 0.15, y: 0)
                .opacity(threadLength > 0 ? Theme.Opacity.pressed : 0)
        }
        .onAppear {
            animateThread()
        }
    }

    private func animateThread() {
        if respectsReducedMotion {
            threadLength = 1
            return
        }

        withAnimation(Theme.Animation.slowFade) {
            threadLength = 1
        }
    }
}

// MARK: - Flow Layout for Sequential Citations
// Wrapping horizontal layout for citation pills

private struct CitationFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, containerWidth: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let layout = layout(sizes: sizes, containerWidth: bounds.width)

        for (index, subview) in subviews.enumerated() {
            let position = layout.positions[index]
            subview.place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(sizes: [CGSize], containerWidth: CGFloat) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for size in sizes {
            if currentX + size.width > containerWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentX - spacing)
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

// MARK: - Crisis Banner
// Visual indicator for crisis support responses (local to this file)

private struct CrisisBanner: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "heart.fill")
                .foregroundStyle(Color("FeedbackError"))

            Text("If you're in crisis, please reach out for help")
                .font(Typography.Command.caption)
                .foregroundStyle(Color("AppTextPrimary"))

            Spacer()
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("FeedbackError").opacity(Theme.Opacity.subtle))
        )
    }
}

// MARK: - Message Timestamp
// Optional timestamp display

struct MessageTimestamp: View {
    let date: Date
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(date.formatted(date: .omitted, time: .shortened))
            .font(Typography.Command.meta)
            .foregroundStyle(Color("TertiaryText"))
    }
}

// MARK: - Message Uncertainty Banner
// Visual indicator when AI is uncertain (local to this file)

private struct MessageUncertaintyBanner: View {
    let level: MessageUncertaintyLevel

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: level.iconName)
                .foregroundStyle(level.color)

            Text(level.message)
                .font(Typography.Command.caption)
                .foregroundStyle(Color("AppTextSecondary"))

            Spacer()
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(level.color.opacity(Theme.Opacity.subtle))
        )
        .padding(.horizontal, Theme.Spacing.md)
    }
}

// MARK: - Message Uncertainty Level
// Levels of AI uncertainty for display (local to this file)

private enum MessageUncertaintyLevel {
    case low
    case medium
    case high

    var iconName: String {
        switch self {
        case .low: return "checkmark.circle"
        case .medium: return "questionmark.circle"
        case .high: return "exclamationmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .low: return Color("FeedbackSuccess")
        case .medium: return Color("FeedbackWarning")
        case .high: return Color("FeedbackError")
        }
    }

    var message: String {
        switch self {
        case .low: return "High confidence response"
        case .medium: return "This interpretation may vary"
        case .high: return "Consider consulting additional sources"
        }
    }
}

// MARK: - Preview

#Preview("Chat Messages") {
    ScrollView {
        VStack(spacing: Theme.Spacing.xl) {
            Text("User Message")
                .font(Typography.Command.headline)

            ChatMessageView(
                message: ChatMessage(
                    threadId: UUID(),
                    role: .user,
                    content: "What does it mean to be blessed?"
                ),
                isLatestAIMessage: false,
                onCitationTap: { _ in }
            )

            Text("AI Response")
                .font(Typography.Command.headline)

            ChatMessageView(
                message: ChatMessage(
                    threadId: UUID(),
                    role: .assistant,
                    content: "When Jesus spoke of the blessed, he was describing a state of spiritual flourishing that transcends earthly circumstances. The Beatitudes reveal that true blessedness comes not from wealth or power, but from humility, mercy, and righteousness.",
                    citations: [
                        VerseRange(bookId: 40, chapter: 5, verseStart: 3, verseEnd: 12),
                        VerseRange(bookId: 42, chapter: 6, verseStart: 20, verseEnd: 23)
                    ]
                ),
                isLatestAIMessage: true,
                onCitationTap: { _ in }
            )

            Text("Uncertainty Banner")
                .font(Typography.Command.headline)

            MessageUncertaintyBanner(level: .medium)
        }
        .padding()
    }
    .background(Color.appBackground)
}

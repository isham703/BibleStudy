import SwiftUI

// MARK: - Editorial Margin View
// Two-column manuscript layout with bezier connection lines
// Inspired by: Scrollytelling trends + medieval marginalia
// All insights visible simultaneously — passive reading experience

struct EditorialMarginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var streamingState = InsightStreamingState()

    @State private var isVisible = false
    @State private var connectionLineProgress: [Int: CGFloat] = [:]
    @State private var phrasePositions: [String: CGRect] = [:]
    @State private var cardPositions: [Int: CGRect] = [:]

    private let insights = LivingCommentaryDemoData.insights

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Parchment background with subtle texture
                backgroundLayer

                VStack(spacing: 0) {
                    // Header
                    headerView
                        .opacity(isVisible ? 1 : 0)
                        .animation(.easeOut(duration: 0.5), value: isVisible)

                    // Two-column content
                    ScrollView(showsIndicators: false) {
                        twoColumnLayout(geometry: geometry)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 100)
                    }
                }

                // Connection lines overlay
                connectionLinesOverlay(geometry: geometry)
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            startEntranceSequence()
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color.commentaryParchment

            // Subtle paper texture
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.commentaryText.opacity(0.02),
                            Color.clear,
                            Color.commentaryText.opacity(0.015)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.commentaryText.opacity(0.5))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("EDITORIAL MARGIN")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.commentaryAccent)

                Text(LivingCommentaryDemoData.verseReference)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.commentaryText.opacity(0.5))
            }

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 16, height: 16)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

    // MARK: - Two Column Layout

    private func twoColumnLayout(geometry: GeometryProxy) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Left column: Verse text (~60%)
            verseColumn(width: geometry.size.width * 0.55)

            // Right column: Marginalia cards (~40%)
            marginaliaColumn
        }
    }

    // MARK: - Verse Column

    private func verseColumn(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Book title
            VStack(alignment: .leading, spacing: 4) {
                Text("THE GOSPEL OF")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Color.commentaryText.opacity(0.4))

                Text(LivingCommentaryDemoData.bookName)
                    .font(.custom("CormorantGaramond-SemiBold", size: 36))
                    .foregroundStyle(Color.commentaryText)

                Text("Chapter \(LivingCommentaryDemoData.chapterNumber)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.commentaryAccent)
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(.spring(duration: 0.6).delay(0.1), value: isVisible)

            // Verse text with underlined phrases
            verseTextWithPhrases
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
                .animation(.spring(duration: 0.6).delay(0.2), value: isVisible)
        }
        .frame(width: width, alignment: .leading)
    }

    private var verseTextWithPhrases: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                // Verse number
                Text("1")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.commentaryAccent)
                    .frame(width: 14)

                // Verse text with tracked phrases
                buildTrackedVerseText()
            }
        }
    }

    @ViewBuilder
    private func buildTrackedVerseText() -> some View {
        let text = LivingCommentaryDemoData.verseText

        Text(attributedVerseText(text))
            .font(.custom("CormorantGaramond-Regular", size: 20))
            .lineSpacing(8)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func attributedVerseText(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        result.font = .custom("CormorantGaramond-Regular", size: 20)
        result.foregroundColor = Color.commentaryText

        // Underline insight phrases
        for insight in insights {
            if let range = result.range(of: insight.phrase) {
                result[range].underlineStyle = .single
                result[range].underlineColor = UIColor(insight.type.color.opacity(0.5))
            }
        }

        return result
    }

    // MARK: - Marginalia Column

    private var marginaliaColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(insights.enumerated()), id: \.element.id) { index, insight in
                marginaliaCard(insight: insight, index: index)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    cardPositions[index] = geo.frame(in: .global)
                                }
                                .onChange(of: geo.frame(in: .global)) { _, newValue in
                                    cardPositions[index] = newValue
                                }
                        }
                    )
            }
        }
    }

    private func marginaliaCard(insight: MarginaliaInsight, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Type badge
            HStack(spacing: 6) {
                Image(systemName: insight.icon)
                    .font(.system(size: 11))
                    .foregroundStyle(insight.type.color)

                Text(insight.type.label.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(insight.type.color)
            }

            // Title
            Text(insight.title)
                .font(.custom("CormorantGaramond-SemiBold", size: 15))
                .foregroundStyle(Color.commentaryText)

            // Content with streaming
            StreamingTextView(
                fullText: insight.content,
                insight: insight,
                streamingState: streamingState,
                startDelay: Double(index) * 0.4
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.commentaryCardBackground)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        )
        .overlay(
            // Left accent bar
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(insight.type.color)
                    .frame(width: 3)
                Spacer()
            }
            .padding(.vertical, 8)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : 30)
        .animation(
            reduceMotion
                ? .easeOut(duration: 0.2)
                : .spring(duration: 0.5).delay(0.3 + Double(index) * 0.08),
            value: isVisible
        )
    }

    // MARK: - Connection Lines

    private func connectionLinesOverlay(geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            // Draw bezier curves from phrases to cards
            for (index, _) in insights.enumerated() {
                let progress = connectionLineProgress[index] ?? 0

                if progress > 0 {
                    // Calculate start and end points
                    let startY = 200 + CGFloat(index) * 40
                    let endY = 180 + CGFloat(index) * 100

                    let start = CGPoint(x: size.width * 0.55, y: startY)
                    let end = CGPoint(x: size.width * 0.58, y: endY)

                    var path = Path()
                    path.move(to: start)

                    // Bezier curve
                    let ctrl1 = CGPoint(x: start.x + 20, y: start.y)
                    let ctrl2 = CGPoint(x: end.x - 10, y: end.y)
                    path.addCurve(to: end, control1: ctrl1, control2: ctrl2)

                    // Trim path based on progress
                    let trimmedPath = path.trimmedPath(from: 0, to: progress)

                    context.stroke(
                        trimmedPath,
                        with: .color(Color.commentaryAccent.opacity(0.3)),
                        lineWidth: 1.5
                    )

                    // Draw dot at end if complete
                    if progress >= 1.0 {
                        let dotRect = CGRect(x: end.x - 3, y: end.y - 3, width: 6, height: 6)
                        context.fill(
                            Circle().path(in: dotRect),
                            with: .color(Color.commentaryAccent.opacity(0.5))
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Entrance Sequence

    private func startEntranceSequence() {
        withAnimation(.easeOut(duration: 0.6)) {
            isVisible = true
        }

        // Animate connection lines
        guard !reduceMotion else {
            // Instant for reduced motion
            for index in insights.indices {
                connectionLineProgress[index] = 1.0
            }
            return
        }

        for index in insights.indices {
            let delay = 0.5 + Double(index) * 0.15
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.4)) {
                    connectionLineProgress[index] = 1.0
                }
            }
        }
    }
}

// MARK: - Streaming Text View

struct StreamingTextView: View {
    let fullText: String
    let insight: MarginaliaInsight
    @ObservedObject var streamingState: InsightStreamingState
    let startDelay: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayedText = ""
    @State private var isStreaming = false
    @State private var showThinking = true
    @State private var streamingTimer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if showThinking && !reduceMotion {
                // Thinking indicator
                HStack(spacing: 6) {
                    ThinkingDotsView()
                    Text("Generating insight...")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.commentaryText.opacity(0.5))
                }
            } else {
                // Streamed text with cursor
                HStack(alignment: .bottom, spacing: 0) {
                    Text(displayedText)
                        .font(.custom("CormorantGaramond-Regular", size: 13))
                        .foregroundStyle(Color.commentaryText.opacity(0.75))
                        .lineSpacing(4)
                    if isStreaming {
                        Text("▍")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.commentaryAccent)
                    }
                }
            }
        }
        .onAppear {
            if reduceMotion {
                // Show full text immediately
                displayedText = fullText
                showThinking = false
            } else {
                startStreamingSequence()
            }
        }
        .onDisappear {
            streamingTimer?.invalidate()
            streamingTimer = nil
        }
    }

    private func startStreamingSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
            // Show thinking for 0.6s
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showThinking = false
                }
                isStreaming = true

                // Stream characters
                let chars = Array(fullText)
                var index = 0
                streamingTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
                    if index < chars.count {
                        displayedText.append(chars[index])
                        index += 1
                    } else {
                        timer.invalidate()
                        streamingTimer = nil
                        withAnimation(.easeOut(duration: 0.2)) {
                            isStreaming = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Thinking Dots

struct ThinkingDotsView: View {
    @State private var activeIndex = 0
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.commentaryAccent)
                    .frame(width: 5, height: 5)
                    .scaleEffect(activeIndex == index ? 1.3 : 0.8)
                    .opacity(activeIndex == index ? 1 : 0.4)
            }
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.15)) {
                    activeIndex = (activeIndex + 1) % 3
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}

// MARK: - Preview

#Preview {
    EditorialMarginView()
}

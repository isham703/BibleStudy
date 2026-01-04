import SwiftUI

// MARK: - Immersive Scroll View
// Vertical scrolling with parallax depth and scroll-triggered AI streaming
// Inspired by: Parallax trends + micro-interactions + scrollytelling
// Verse segments interleaved with inline insight cards

struct ImmersiveScrollView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Dynamic Type Support
    @ScaledMetric(relativeTo: .title) private var chapterTitleSize: CGFloat = 52
    @ScaledMetric(relativeTo: .body) private var verseTextSize: CGFloat = 26
    @ScaledMetric(relativeTo: .subheadline) private var insightTitleSize: CGFloat = 18
    @ScaledMetric(relativeTo: .footnote) private var insightBodySize: CGFloat = 14
    @ScaledMetric(relativeTo: .caption) private var labelSize: CGFloat = 11

    @State private var isVisible = false
    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 1
    @State private var streamedInsights: Set<UUID> = []
    @State private var viewportCenter: CGFloat = 0

    private let insights = LivingCommentaryDemoData.insights
    private let segments = LivingCommentaryDemoData.verseSegments

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Parallax background
                parallaxBackground(geometry: geometry)

                VStack(spacing: 0) {
                    // Floating header
                    floatingHeader(geometry: geometry)

                    // Immersive content
                    immersiveScrollContent(geometry: geometry)
                }

                // Reading progress bar
                progressBar(geometry: geometry)
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

    // MARK: - Parallax Background

    private func parallaxBackground(geometry: GeometryProxy) -> some View {
        ZStack {
            // Base color
            Color.commentaryParchment

            // Parallax texture layer (moves at 0.3x scroll speed)
            GeometryReader { geo in
                let parallaxOffset = scrollOffset * 0.3

                ZStack {
                    // Warm radial gradient
                    RadialGradient(
                        colors: [
                            Color.commentaryGold.opacity(0.08),
                            Color.clear
                        ],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: geometry.size.height * 0.8
                    )
                    .offset(y: parallaxOffset)

                    // Paper grain texture
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.commentaryText.opacity(0.015),
                                    Color.clear,
                                    Color.commentaryText.opacity(0.02)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .offset(y: parallaxOffset * 0.5)
                }
            }
        }
    }

    // MARK: - Floating Header

    private func floatingHeader(geometry: GeometryProxy) -> some View {
        let headerOpacity = max(0, 1 - (scrollOffset / 100))

        return HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.commentaryText.opacity(0.6))
                    .padding(10)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }

            Spacer()

            VStack(spacing: 2) {
                Text("IMMERSIVE SCROLL")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(Color.commentaryAccent)

                Text(LivingCommentaryDemoData.verseReference)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.commentaryText.opacity(0.5))
            }

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .opacity(headerOpacity)
    }

    // MARK: - Progress Bar

    private func progressBar(geometry: GeometryProxy) -> some View {
        let progress = min(1, max(0, scrollOffset / max(1, contentHeight - geometry.size.height)))

        return VStack {
            // Progress bar at top
            GeometryReader { _ in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.commentaryAccent.opacity(0.3))
                    .frame(height: 3)
                    .overlay(
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(Color.commentaryAccent)
                                .frame(width: geo.size.width * progress, height: 3)
                        },
                        alignment: .leading
                    )
            }
            .frame(height: 3)
            .padding(.horizontal, 20)
            .padding(.top, 52)

            Spacer()
        }
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.5), value: isVisible)
    }

    // MARK: - Immersive Scroll Content

    private func immersiveScrollContent(geometry: GeometryProxy) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Chapter heading
                chapterHeading
                    .padding(.top, 40)
                    .padding(.bottom, 60)
                    .scrollTargetLayout()

                // Interleaved verse segments and insights
                ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                    VStack(spacing: 0) {
                        // Verse segment
                        verseSegment(text: segment.text, index: index, geometry: geometry)

                        // Insight card if present
                        if let insight = segment.insight {
                            scrollTriggeredInsightCard(
                                insight: insight,
                                index: index,
                                geometry: geometry
                            )
                            .padding(.vertical, 24)
                        }
                    }
                    .scrollTargetLayout()
                }

                // Bottom padding
                Spacer()
                    .frame(height: 120)
            }
            .scrollTargetLayout()
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: ImmersiveScrollOffsetPreferenceKey.self,
                            value: -geo.frame(in: .named("scroll")).origin.y
                        )
                        .preference(
                            key: ImmersiveContentHeightPreferenceKey.self,
                            value: geo.size.height
                        )
                }
            )
            .padding(.horizontal, 28)
        }
        .scrollTargetBehavior(.viewAligned)
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ImmersiveScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
            viewportCenter = value + geometry.size.height / 2
        }
        .onPreferenceChange(ImmersiveContentHeightPreferenceKey.self) { value in
            contentHeight = value
        }
    }

    // MARK: - Chapter Heading

    private var chapterHeading: some View {
        VStack(spacing: 12) {
            Text("THE GOSPEL OF")
                .font(.system(size: labelSize, weight: .medium))
                .tracking(3)
                .foregroundStyle(Color.commentaryText.opacity(0.4))

            Text(LivingCommentaryDemoData.bookName)
                .font(.custom("CormorantGaramond-SemiBold", size: chapterTitleSize))
                .foregroundStyle(Color.commentaryText)

            HStack(spacing: 16) {
                Rectangle()
                    .fill(Color.commentaryAccent.opacity(0.3))
                    .frame(width: 40, height: 1)

                Text("Chapter \(LivingCommentaryDemoData.chapterNumber)")
                    .font(.system(size: insightBodySize, weight: .semibold))
                    .foregroundStyle(Color.commentaryAccent)

                Rectangle()
                    .fill(Color.commentaryAccent.opacity(0.3))
                    .frame(width: 40, height: 1)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
        .animation(.spring(duration: 0.7).delay(0.2), value: isVisible)
    }

    // MARK: - Verse Segment

    private func verseSegment(text: String, index: Int, geometry: GeometryProxy) -> some View {
        GeometryReader { geo in
            let midY = geo.frame(in: .named("scroll")).midY
            let screenHeight = geometry.size.height
            let distanceFromCenter = abs(midY - screenHeight / 2)
            let normalizedDistance = min(1, distanceFromCenter / (screenHeight / 2))

            // Scale and opacity based on distance from center
            let scale = reduceMotion ? 1.0 : (1.0 - normalizedDistance * 0.04)
            let opacity = reduceMotion ? 1.0 : (1.0 - normalizedDistance * 0.3)

            Text(text)
                .font(.custom("CormorantGaramond-Regular", size: verseTextSize))
                .lineSpacing(10)
                .foregroundStyle(Color.commentaryText.opacity(opacity))
                .scaleEffect(scale)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 50)
    }

    // MARK: - Scroll-Triggered Insight Card

    private func scrollTriggeredInsightCard(
        insight: MarginaliaInsight,
        index: Int,
        geometry: GeometryProxy
    ) -> some View {
        ScrollTriggeredCard(
            insight: insight,
            hasStreamed: streamedInsights.contains(insight.id),
            onStream: {
                streamedInsights.insert(insight.id)
            },
            reduceMotion: reduceMotion,
            containerHeight: geometry.size.height
        )
    }
}

// MARK: - Scroll-Triggered Card

struct ScrollTriggeredCard: View {
    let insight: MarginaliaInsight
    let hasStreamed: Bool
    let onStream: () -> Void
    let reduceMotion: Bool
    let containerHeight: CGFloat

    // MARK: - Dynamic Type Support
    @ScaledMetric(relativeTo: .subheadline) private var titleSize: CGFloat = 18
    @ScaledMetric(relativeTo: .footnote) private var contentSize: CGFloat = 14
    @ScaledMetric(relativeTo: .caption) private var labelSize: CGFloat = 10
    @ScaledMetric(relativeTo: .caption2) private var hintSize: CGFloat = 12

    @State private var isInViewport = false
    @State private var displayedText = ""
    @State private var isStreaming = false
    @State private var showThinking = true
    @State private var showShimmer = false
    @State private var streamingTimer: Timer?

    var body: some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .global)
            let isVisible = frame.minY < containerHeight * 0.7 && frame.maxY > containerHeight * 0.3

            cardContent
                .opacity(isInViewport ? 1 : 0.3)
                .scaleEffect(isInViewport ? 1 : 0.96)
                .onChange(of: isVisible) { _, newValue in
                    if newValue && !isInViewport {
                        withAnimation(.spring(duration: 0.4)) {
                            isInViewport = true
                        }
                        if !hasStreamed {
                            startStreaming()
                        } else {
                            displayedText = insight.content
                            showThinking = false
                        }
                    }
                }
                .onAppear {
                    if reduceMotion {
                        isInViewport = true
                        displayedText = insight.content
                        showThinking = false
                    }
                }
        }
        .frame(height: 160)
        .onDisappear {
            streamingTimer?.invalidate()
            streamingTimer = nil
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Type badge with icon
            HStack(spacing: 8) {
                Circle()
                    .fill(insight.type.color)
                    .frame(width: 8, height: 8)

                Text(insight.type.label.uppercased())
                    .font(.system(size: labelSize, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(insight.type.color)

                Spacer()

                Image(systemName: insight.icon)
                    .font(.system(size: contentSize))
                    .foregroundStyle(insight.type.color.opacity(0.7))
            }

            // Title
            Text(insight.title)
                .font(.custom("CormorantGaramond-SemiBold", size: titleSize))
                .foregroundStyle(Color.commentaryText)

            // Content
            if showThinking && !reduceMotion {
                HStack(spacing: 6) {
                    ThinkingDotsView()
                    Text("Generating insight...")
                        .font(.system(size: hintSize))
                        .foregroundStyle(Color.commentaryText.opacity(0.5))
                }
            } else {
                // Streamed text with cursor
                HStack(alignment: .bottom, spacing: 0) {
                    Text(displayedText)
                        .font(.custom("CormorantGaramond-Regular", size: contentSize))
                        .foregroundStyle(Color.commentaryText.opacity(0.75))
                        .lineSpacing(5)
                    if isStreaming {
                        Text("▍")
                            .font(.system(size: contentSize))
                            .foregroundStyle(Color.commentaryAccent)
                    }
                }
            }

            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.commentaryCardBackground)

                // Shimmer overlay on completion
                if showShimmer {
                    shimmerOverlay
                }
            }
        )
        .overlay(
            // Left accent bar
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(insight.type.color)
                    .frame(width: 3)
                Spacer()
            }
            .padding(.vertical, 12)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
    }

    private var shimmerOverlay: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.commentaryGold.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 80)
                .offset(x: showShimmer ? geo.size.width + 80 : -80)
                .animation(.easeInOut(duration: 0.6), value: showShimmer)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func startStreaming() {
        guard !reduceMotion else {
            displayedText = insight.content
            showThinking = false
            onStream()
            return
        }

        // Show thinking for 0.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.2)) {
                showThinking = false
            }
            isStreaming = true

            // Stream characters
            let chars = Array(insight.content)
            var index = 0
            streamingTimer = Timer.scheduledTimer(withTimeInterval: 0.018, repeats: true) { timer in
                if index < chars.count {
                    displayedText.append(chars[index])
                    index += 1
                } else {
                    timer.invalidate()
                    streamingTimer = nil
                    withAnimation(.easeOut(duration: 0.2)) {
                        isStreaming = false
                    }
                    // Trigger shimmer
                    withAnimation {
                        showShimmer = true
                    }
                    onStream()
                }
            }
        }
    }
}

// MARK: - Preference Keys

struct ImmersiveScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ImmersiveContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview {
    ImmersiveScrollView()
}

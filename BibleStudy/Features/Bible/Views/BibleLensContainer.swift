import SwiftUI

// MARK: - Lens Container
// Expandable marginalia container that appears below a verse when indicator is tapped
// Contains lens pills for switching between insight types and displays content
// Design: Feels like margin notes materializing from the page, not a modal

struct LensContainer: View {
    // MARK: - Properties

    /// All insights for this verse
    let insights: [BibleInsight]

    /// Currently selected lens (nil = pills visible but no content expanded)
    let selectedLens: BibleInsightType?

    /// Callback when a lens is selected
    let onSelectLens: (BibleInsightType) -> Void

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    @State private var goldLineProgress: CGFloat = 0
    @State private var containerOpacity: CGFloat = 0
    @State private var contentOpacity: CGFloat = 0

    // MARK: - Computed Properties

    /// Available lenses based on insights for this verse
    /// Note: Connections and Greek excluded from Reading Mode
    /// Connections are chapter-level only; Greek is opt-in via Study Mode
    private var availableLenses: [BibleInsightType] {
        let types = Set(insights.map { $0.insightType })
        // Order: Theology, Reflection (Greek opt-in via Study Mode, Connections chapter-level)
        return [.theology, .question].filter { types.contains($0) }
    }

    /// Insights for the currently selected lens
    private var selectedInsights: [BibleInsight] {
        guard let lens = selectedLens else { return [] }
        return insights.filter { $0.insightType == lens }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Animated gold line at top
            goldLine

            VStack(alignment: .leading, spacing: 16) {
                // Lens pills row
                LensPillRow(
                    availableLenses: availableLenses,
                    selectedLens: selectedLens,
                    insights: insights,
                    onSelectLens: onSelectLens
                )

                // Content area (if lens selected)
                if selectedLens != nil && !selectedInsights.isEmpty {
                    Divider()
                        .background(Color.bibleInsightText.opacity(0.1))

                    insightContent
                        .opacity(contentOpacity)
                }
            }
            .padding(16)
            .background(containerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(containerBorder)
        }
        .opacity(containerOpacity)
        .onAppear {
            animateEntrance()
        }
        .onChange(of: selectedLens) { _, _ in
            animateContentChange()
        }
    }

    // MARK: - Gold Line

    private var goldLine: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.divineGold.opacity(0.3),
                            Color.divineGold,
                            Color.divineGold.opacity(0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: geo.size.width * goldLineProgress, height: 1)
        }
        .frame(height: 1)
        .padding(.horizontal, 16)
    }

    // MARK: - Container Background

    private var containerBackground: some View {
        ZStack {
            // Base parchment color
            Color.bibleInsightCardBackground

            // Subtle inner glow from top-left (like light on manuscript)
            RadialGradient(
                colors: [
                    Color.divineGold.opacity(0.03),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 200
            )

            // Paper grain texture simulation
            LinearGradient(
                colors: [
                    Color.bibleInsightText.opacity(0.008),
                    Color.clear,
                    Color.bibleInsightText.opacity(0.01)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Container Border

    private var containerBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.bibleInsightText.opacity(0.08), lineWidth: 0.5)
    }

    // MARK: - Insight Content

    private var insightContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(selectedInsights) { insight in
                InsightContentCard(insight: insight)
            }
        }
    }

    // MARK: - Animations

    private func animateEntrance() {
        if reduceMotion {
            goldLineProgress = 1
            containerOpacity = 1
            contentOpacity = 1
            return
        }

        // Staggered entrance
        withAnimation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.3).delay(0.1)) {
            goldLineProgress = 1
        }

        withAnimation(AppTheme.Animation.cardUnfurl.delay(0.15)) {
            containerOpacity = 1
        }

        if selectedLens != nil {
            withAnimation(AppTheme.Animation.unfurl.delay(0.3)) {
                contentOpacity = 1
            }
        }
    }

    private func animateContentChange() {
        if reduceMotion {
            contentOpacity = selectedLens != nil ? 1 : 0
            return
        }

        withAnimation(AppTheme.Animation.unfurl) {
            contentOpacity = selectedLens != nil ? 1 : 0
        }
    }
}

// MARK: - Lens Pill Row
// Horizontal scrolling row of lens pills using InsightChip pattern

struct LensPillRow: View {
    let availableLenses: [BibleInsightType]
    let selectedLens: BibleInsightType?
    let insights: [BibleInsight]
    let onSelectLens: (BibleInsightType) -> Void

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    @State private var pillsAppeared: Set<BibleInsightType> = []

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(Array(availableLenses.indices), id: \.self) { index in
                    let lens = availableLenses[index]
                    let count = insights.filter { $0.insightType == lens }.count
                    let hasAppeared = pillsAppeared.contains(lens)

                    LensPill(
                        lens: lens,
                        isSelected: selectedLens == lens,
                        insightCount: count,
                        onTap: {
                            HapticService.shared.lightTap()
                            onSelectLens(lens)
                        }
                    )
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(x: hasAppeared ? 0 : -8)
                    .onAppear {
                        if reduceMotion {
                            pillsAppeared.insert(lens)
                        } else {
                            let animation = AppTheme.Animation.stagger(index: index, delay: 0.05).delay(0.2)
                            withAnimation(animation) {
                                pillsAppeared.insert(lens)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Lens Pill
// Individual lens pill with wax-seal-inspired aesthetic

struct LensPill: View {
    let lens: BibleInsightType
    let isSelected: Bool
    let insightCount: Int
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: isSelected ? 4 : 0) {
                // Lens icon (always visible)
                Image(systemName: lens.icon)
                    .font(.system(size: 11, weight: .medium))

                // Lens name (only when selected - reduces visual weight)
                if isSelected {
                    Text(lens.label)
                        .font(.custom("CormorantGaramond-SemiBold", size: 12))
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .foregroundStyle(isSelected ? .white : lens.color.opacity(0.8))
            .padding(.horizontal, isSelected ? 10 : 8)
            .padding(.vertical, 6)
            .background(pillBackground)
            .clipShape(Capsule())
            .overlay(pillBorder)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            if reduceMotion {
                isPressed = pressing
            } else {
                withAnimation(AppTheme.Animation.quick) {
                    isPressed = pressing
                }
            }
        }, perform: {})
        .accessibilityLabel("\(lens.label) insights")
        .accessibilityHint(isSelected ? "Currently selected. \(insightCount) insight\(insightCount == 1 ? "" : "s"). Double tap to collapse." : "\(insightCount) insight\(insightCount == 1 ? "" : "s"). Double tap to expand.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var pillBackground: some View {
        Group {
            if isSelected {
                lens.color
            } else {
                lens.color.opacity(0.08)
            }
        }
    }

    private var pillBorder: some View {
        Capsule()
            .stroke(
                isSelected ? Color.clear : lens.color.opacity(0.25),
                lineWidth: 0.5
            )
    }
}

// MARK: - Insight Content Card
// Displays a single insight's content within the lens container

struct InsightContentCard: View {
    let insight: BibleInsight

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showSources = false
    @State private var isExpanded = false

    /// Max lines to show in collapsed state (Reading Mode height cap - strict)
    private let collapsedLineLimit = 3

    /// Whether content is long enough to need truncation
    private var needsTruncation: Bool {
        insight.content.count > 150  // ~3 lines of text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(insight.title)
                .font(.custom("Cinzel-Regular", size: 14))
                .foregroundStyle(Color.bibleInsightText)
                .tracking(0.3)

            // Content (height-capped in Reading Mode)
            VStack(alignment: .leading, spacing: 8) {
                Text(insight.content)
                    .font(.custom("CormorantGaramond-Regular", size: 15))
                    .lineSpacing(6)
                    .foregroundStyle(Color.bibleInsightText.opacity(0.85))
                    .lineLimit(isExpanded ? nil : collapsedLineLimit)

                // "Read more" if truncated
                if needsTruncation && !isExpanded {
                    Button {
                        if reduceMotion {
                            isExpanded = true
                        } else {
                            withAnimation(AppTheme.Animation.chipExpand) {
                                isExpanded = true
                            }
                        }
                    } label: {
                        Text("Read more")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.scholarAccent)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Interpretive badge
            if insight.isInterpretive {
                interpretiveBadge
            }

            // Sources (if available and content expanded)
            if !insight.sources.isEmpty && (isExpanded || !needsTruncation) {
                sourcesSection
            }
        }
    }

    private var interpretiveBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "info.circle")
                .font(.system(size: 10))

            Text("Interpretive")
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundStyle(Color.info)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.info.opacity(0.12))
        )
    }

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                if reduceMotion {
                    showSources.toggle()
                } else {
                    withAnimation(AppTheme.Animation.chipExpand) {
                        showSources.toggle()
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showSources ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))

                    Text("Sources (\(insight.sources.count))")
                        .font(.system(size: 11, weight: .medium))

                    Spacer()
                }
                .foregroundStyle(Color.scholarAccent)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showSources {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(insight.sources, id: \.reference) { source in
                        sourceRow(source)
                    }
                }
                .padding(.leading, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, 4)
    }

    private func sourceRow(_ source: InsightSource) -> some View {
        HStack(alignment: .top, spacing: 8) {
            sourceIcon(for: source.type)
                .font(.system(size: 10))
                .foregroundStyle(sourceColor(for: source.type))
                .frame(width: 14)

            VStack(alignment: .leading, spacing: 2) {
                Text(source.reference)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.primaryText)

                if let description = source.description {
                    Text(description)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.tertiaryText)
                }
            }
        }
    }

    private func sourceIcon(for type: InsightSource.SourceType) -> Image {
        switch type {
        case .crossReference: return Image(systemName: "link")
        case .strongs: return Image(systemName: "character.book.closed")
        case .commentary: return Image(systemName: "text.book.closed")
        case .lexicon: return Image(systemName: "textformat.abc")
        }
    }

    private func sourceColor(for type: InsightSource.SourceType) -> Color {
        switch type {
        case .crossReference: return .connectionAmber
        case .strongs: return .greekBlue
        case .commentary: return .theologyGreen
        case .lexicon: return .greekBlue
        }
    }
}

// MARK: - Preview

#Preview("Lens Container") {
    struct PreviewContainer: View {
        @State private var selectedLens: BibleInsightType? = nil

        private var sampleInsights: [BibleInsight] {
            [
                BibleInsight(
                    id: "1",
                    bookId: 43,
                    chapter: 1,
                    verseStart: 1,
                    verseEnd: 1,
                    segmentText: "In the beginning",
                    segmentStartChar: 0,
                    segmentEndChar: 16,
                    insightType: .theology,
                    title: "The Word as Divine Person",
                    content: "John's prologue establishes the pre-existence and deity of Christ. The 'Word' (logos) was not created but eternally existed with God. This echoes Genesis 1:1 and declares Jesus as the creative agent of all that exists.",
                    icon: "sparkles",
                    sources: [
                        InsightSource(type: .crossReference, reference: "Genesis 1:1", description: "In the beginning God created..."),
                        InsightSource(type: .strongs, reference: "G3056 - λόγος (logos)", description: "Word, speech, reason")
                    ],
                    contentVersion: 1,
                    promptVersion: "v1.0",
                    modelVersion: "gpt-4o-mini",
                    createdAt: Date(),
                    qualityTier: .standard,
                    isInterpretive: false
                ),
                BibleInsight(
                    id: "2",
                    bookId: 43,
                    chapter: 1,
                    verseStart: 1,
                    verseEnd: 1,
                    segmentText: "was God",
                    segmentStartChar: 50,
                    segmentEndChar: 57,
                    insightType: .question,
                    title: "Identity and Purpose",
                    content: "If the Word was God from the beginning, how does this truth shape your understanding of Jesus's identity? What does it mean for your relationship with Him?",
                    icon: "questionmark.circle",
                    sources: [],
                    contentVersion: 1,
                    promptVersion: "v1.0",
                    modelVersion: "gpt-4o-mini",
                    createdAt: Date(),
                    qualityTier: .standard,
                    isInterpretive: true
                )
            ]
        }

        var body: some View {
            VStack(spacing: 20) {
                Text("Lens Container Preview")
                    .font(.headline)

                LensContainer(
                    insights: sampleInsights,
                    selectedLens: selectedLens,
                    onSelectLens: { lens in
                        withAnimation(AppTheme.Animation.chipExpand) {
                            if selectedLens == lens {
                                selectedLens = nil
                            } else {
                                selectedLens = lens
                            }
                        }
                    }
                )
            }
            .padding(28)
            .background(Color.bibleInsightParchment)
        }
    }

    return PreviewContainer()
}

#Preview("Lens Pills") {
    VStack(spacing: 20) {
        // All lenses unselected
        HStack(spacing: 8) {
            LensPill(lens: .theology, isSelected: false, insightCount: 2, onTap: {})
            LensPill(lens: .question, isSelected: false, insightCount: 1, onTap: {})
            LensPill(lens: .greek, isSelected: false, insightCount: 1, onTap: {})
        }

        // One selected
        HStack(spacing: 8) {
            LensPill(lens: .theology, isSelected: true, insightCount: 2, onTap: {})
            LensPill(lens: .question, isSelected: false, insightCount: 1, onTap: {})
            LensPill(lens: .greek, isSelected: false, insightCount: 1, onTap: {})
        }
    }
    .padding()
    .background(Color.bibleInsightParchment)
}

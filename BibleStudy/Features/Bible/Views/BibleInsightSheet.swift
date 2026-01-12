import SwiftUI

// MARK: - Insight Sheet
// Bottom sheet for viewing insights for a specific verse
// Opens when verse marker is tapped in Reading Mode
// Design: Compact header, segmented tabs, flat content, fast to scan

struct BibleInsightSheet: View {
    // MARK: - Properties

    /// The verse this sheet is showing insights for
    let verse: Verse

    /// All insights for this verse
    let insights: [BibleInsight]

    /// All verses in chapter (for navigation)
    var allVerses: [Verse] = []

    /// Verse insight counts (for nav button enablement)
    var verseInsightCounts: [Int: Int] = [:]

    /// Dismiss this sheet (back to reader)
    let onDismiss: () -> Void

    /// Optional: Dismiss entire sheet stack (used by sub-sheets)
    /// If not provided, defaults to onDismiss
    var onDismissAll: (() -> Void)?

    /// Optional: Navigate to Study Mode for this verse
    var onOpenInStudy: (() -> Void)?

    /// Optional: Navigate to a different verse
    var onNavigateToVerse: ((Verse) -> Void)?

    /// Optional: Navigate to a cross-reference (e.g., "Genesis 1:1")
    var onNavigateToReference: ((String) -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    /// Computed: The actual dismiss-all action
    private var dismissAll: () -> Void {
        onDismissAll ?? onDismiss
    }

    // MARK: - State

    @State private var selectedLens: BibleInsightType?
    @State private var showConnectionsSheet = false
    @State private var showSourcesSheet = false

    /// Centralized state for managing dismiss callbacks
    @State private var sheetState = InsightSheetState()

    // MARK: - Scroll Management
    /// Stores ScrollViewReader proxy for programmatic scrolling
    @State private var scrollProxy: ScrollViewProxy?
    /// Stable scroll anchor ID
    private let scrollTopID = "insight-scroll-top"

    // MARK: - Persisted Preferences

    /// Remember last selected lens across sheet presentations
    @AppStorage("lastSelectedInsightLens") private var lastSelectedLensRawValue: String = ""

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Computed Properties

    /// All potential lenses (always show both, disable if empty)
    private var allLenses: [BibleInsightType] {
        [.theology, .question]
    }

    /// Lenses that have content
    private var lensesWithContent: Set<BibleInsightType> {
        Set(insights.map { $0.insightType }).intersection(Set(allLenses))
    }

    /// Check if a lens has content
    private func hasContent(for lens: BibleInsightType) -> Bool {
        lensesWithContent.contains(lens)
    }

    /// Insights for the currently selected lens
    private var selectedInsights: [BibleInsight] {
        guard let lens = selectedLens else { return [] }
        return insights.filter { $0.insightType == lens }
    }

    /// Connection count for this verse
    private var connectionCount: Int {
        insights.filter { $0.insightType == .connection }.count
    }

    /// Total sources across all non-connection insights
    private var totalSourceCount: Int {
        allSources.count
    }

    /// All sources from non-connection insights
    private var allSources: [InsightSource] {
        insights.filter { $0.insightType != .connection }
            .flatMap { $0.sources }
    }

    /// Stable content identity based on verse and lens (avoids UUID rebuilds)
    private var contentIdentity: String {
        "\(verse.verse)-\(selectedLens?.rawValue ?? "none")"
    }

    /// Verse reference string (short form)
    private var verseReference: String {
        guard let book = Book.find(byId: verse.bookId) else {
            return "\(verse.verse)"
        }
        return "\(book.abbreviation) \(verse.chapter):\(verse.verse)"
    }

    /// Navigation: previous verse with insights
    private var previousVerse: Verse? {
        guard !allVerses.isEmpty else { return nil }
        let currentIndex = allVerses.firstIndex(where: { $0.verse == verse.verse })
        guard let index = currentIndex, index > 0 else { return nil }

        // Find previous verse that has insights
        for idx in stride(from: index - 1, through: 0, by: -1) {
            let candidate = allVerses[idx]
            if (verseInsightCounts[candidate.verse] ?? 0) > 0 {
                return candidate
            }
        }
        return nil
    }

    /// Navigation: next verse with insights
    private var nextVerse: Verse? {
        guard !allVerses.isEmpty else { return nil }
        let currentIndex = allVerses.firstIndex(where: { $0.verse == verse.verse })
        guard let index = currentIndex, index < allVerses.count - 1 else { return nil }

        // Find next verse that has insights
        for idx in (index + 1)..<allVerses.count {
            let candidate = allVerses[idx]
            if (verseInsightCounts[candidate.verse] ?? 0) > 0 {
                return candidate
            }
        }
        return nil
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Compact header with verse nav
            compactHeader
                .padding(.top, Theme.Spacing.sm)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.md)

            // Segmented tabs (always show both, disable if empty)
            segmentedTabs
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.md)

            // Thin divider
            Rectangle()
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle))
                // swiftlint:disable:next hardcoded_frame
                .frame(height: 0.5)

            // Content area with verse change animation
            ScrollViewReader { proxy in
                ScrollView {
                    // Invisible scroll anchor at top
                    Color.clear.frame(height: 0).id(scrollTopID)

                    Group {
                        if selectedInsights.isEmpty {
                            emptyLensState
                        } else {
                            flatContent
                        }
                    }
                    .id(contentIdentity) // Stable identity, not UUID
                    .transition(.opacity)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md + 2)
                    .padding(.bottom, Theme.Spacing.xl)
                }
                .onAppear { scrollProxy = proxy }
            }

            // Footer actions (parallel style)
            footerActions
        }
        .background(Color.bibleInsightCardBackground)
        .onAppear {
            // Configure the shared state with dismiss callbacks
            sheetState.configure(
                verse: verse,
                insights: insights,
                onDismissAll: dismissAll,
                onNavigateToReference: onNavigateToReference
            )

            // Try to restore last selected lens if it has content for this verse
            if selectedLens == nil {
                if let lastLens = BibleInsightType.from(rawValue: lastSelectedLensRawValue),
                   hasContent(for: lastLens) {
                    selectedLens = lastLens
                } else {
                    selectedLens = allLenses.first { hasContent(for: $0) } ?? .theology
                }
            }
        }
        .onChange(of: selectedLens) { _, newLens in
            // Persist the selected lens for future sheet presentations
            if let lens = newLens {
                lastSelectedLensRawValue = lens.persistenceKey
            }
        }
        .onChange(of: verse.verse) { _, _ in
            // Scroll to top on verse navigation (no UUID rebuild for performance)
            if !reduceMotion {
                withAnimation(Theme.Animation.settle) {
                    scrollProxy?.scrollTo(scrollTopID, anchor: .top)
                }
            } else {
                scrollProxy?.scrollTo(scrollTopID, anchor: .top)
            }

            // Keep current lens if it has content in new verse, otherwise fall back
            if let currentLens = selectedLens, hasContent(for: currentLens) {
                // Keep current lens - no change needed
            } else {
                // Fall back to first available lens
                selectedLens = allLenses.first { hasContent(for: $0) } ?? .theology
            }

            HapticService.shared.lightTap()
        }
        .sheet(isPresented: $showConnectionsSheet) {
            ConnectionsSheet(
                verse: verse,
                connections: insights.filter { $0.insightType == .connection },
                onDismiss: { showConnectionsSheet = false }
            )
            .environment(\.insightSheetState, sheetState)
            .presentationDetents([.fraction(0.55), .fraction(0.95)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSourcesSheet) {
            SourcesSheet(
                verse: verse,
                sources: allSources,
                onDismiss: { showSourcesSheet = false }
            )
            .environment(\.insightSheetState, sheetState)
            .presentationDetents([.fraction(0.55), .fraction(0.95)])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Empty Lens State

    private var emptyLensState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: selectedLens?.icon ?? "questionmark.circle")
                .font(Typography.Icon.xl)
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.selectionBackground))

            Text("No \(selectedLens?.label.lowercased() ?? "content") for this verse")
                .font(Typography.Scripture.footnote)
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
    }

    // MARK: - Compact Header

    private var compactHeader: some View {
        VStack(spacing: Theme.Spacing.xs) {
            // Drag indicator
            RoundedRectangle(cornerRadius: Theme.Radius.input / 2)
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.selectionBackground))
                .frame(width: 36, height: 4)

            // Title row with navigation
            HStack(spacing: Theme.Spacing.md) {
                // Previous verse nav (if available)
                if let prev = previousVerse {
                    Button {
                        HapticService.shared.lightTap()
                        onNavigateToVerse?(prev)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(Typography.Icon.xs.weight(.semibold))
                            .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                    }
                } else {
                    Image(systemName: "chevron.left")
                        .font(Typography.Icon.xs.weight(.semibold))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.selectionBackground))
                }

                // Verse reference
                Text(verseReference)
                    .font(Typography.Scripture.body.weight(.semibold))
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.pressed))

                // Next verse nav (if available)
                if let next = nextVerse {
                    Button {
                        HapticService.shared.lightTap()
                        onNavigateToVerse?(next)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(Typography.Icon.xs.weight(.semibold))
                            .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                    }
                } else {
                    Image(systemName: "chevron.right")
                        .font(Typography.Icon.xs.weight(.semibold))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.selectionBackground))
                }

                Spacer()

                // Close button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(Typography.Icon.xxs.weight(.medium))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.focusStroke))
                        .padding(Theme.Spacing.xs)
                        .background(Circle().fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle / 2)))
                }
            }
        }
    }

    // MARK: - Segmented Tabs (Classic iOS Style)

    private var segmentedTabs: some View {
        HStack(spacing: 0) {
            ForEach(Array(allLenses.enumerated()), id: \.element) { index, lens in
                segmentTab(lens, isFirst: index == 0, isLast: index == allLenses.count - 1)

                // Divider between tabs (only if not last)
                if index < allLenses.count - 1 {
                    Rectangle()
                        .fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle))
                        // swiftlint:disable:next hardcoded_frame
                        .frame(width: 0.5, height: Theme.Spacing.lg)
                }
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle / 2))
        )
    }

    private func segmentTab(_ lens: BibleInsightType, isFirst: Bool, isLast: Bool) -> some View {
        let isSelected = selectedLens == lens
        let isEnabled = hasContent(for: lens)

        return Button {
            guard isEnabled else { return }
            HapticService.shared.lightTap()
            if reduceMotion {
                selectedLens = lens
            } else {
                withAnimation(Theme.Animation.settle) {
                    selectedLens = lens
                }
            }
        } label: {
            HStack(spacing: 2) {
                Image(systemName: lens.icon)
                    .font(Typography.Icon.xxs.weight(isSelected ? .semibold : .medium))

                Text(lens.label)
                    .font(Typography.Icon.xs.weight(isSelected ? .semibold : .regular))
            }
            // Strong contrast: selected = solid, unselected = muted, disabled = very faint
            .foregroundStyle(
                isSelected
                    ? Color.bibleInsightCardBackground
                    : (isEnabled ? Color.bibleInsightText.opacity(Theme.Opacity.textSecondary - 0.05) : Color.bibleInsightText.opacity(Theme.Opacity.selectionBackground))
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xs + 1)
            .padding(.horizontal, Theme.Spacing.md)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: Theme.Radius.input + 1)
                            .fill(Color.bibleInsightText.opacity(Theme.Opacity.pressed + 0.05))
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    // MARK: - Flat Content (No Inner Card)

    private var flatContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            ForEach(selectedInsights) { insight in
                FlatInsightView(insight: insight)
                    .environment(\.insightSheetState, sheetState)
            }
        }
    }

    // MARK: - Footer Actions (Parallel Style)

    private var footerActions: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle))
                // swiftlint:disable:next hardcoded_frame
                .frame(height: 0.5)

            // Action rows (consistent parallel style)
            VStack(spacing: 0) {
                // Sources row (opens drill-in sheet)
                footerRow(
                    icon: "text.quote",
                    label: "Sources",
                    count: totalSourceCount,
                    color: Color("AppAccentAction"),
                    isEnabled: totalSourceCount > 0
                ) {
                    showSourcesSheet = true
                }

                Rectangle()
                    .fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle / 2))
                    // swiftlint:disable:next hardcoded_frame
                    .frame(height: 0.5)

                // Connections row
                footerRow(
                    icon: "arrow.triangle.branch",
                    label: "Connections",
                    count: connectionCount,
                    color: Color("AccentBronze"),
                    isEnabled: true
                ) {
                    showConnectionsSheet = true
                }
            }
        }
        .background(Color.bibleInsightCardBackground)
    }

    private func footerRow(
        icon: String,
        label: String,
        count: Int?,
        color: Color,
        isEnabled: Bool,
        showChevron: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            guard isEnabled else { return }
            HapticService.shared.lightTap()
            action()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(Typography.Icon.xxs)
                    .foregroundStyle(isEnabled ? color : color.opacity(Theme.Opacity.focusStroke))
                    .frame(width: Theme.Spacing.lg)

                Text(label)
                    .font(Typography.Icon.xs.weight(.medium))
                    .foregroundStyle(isEnabled ? Color.bibleInsightText.opacity(Theme.Opacity.pressed) : Color.bibleInsightText.opacity(Theme.Opacity.focusStroke))

                if let count = count {
                    Text("(\(count))")
                        .font(Typography.Icon.xxs)
                        .foregroundStyle(isEnabled ? color.opacity(Theme.Opacity.textSecondary) : color.opacity(Theme.Opacity.selectionBackground))
                }

                Spacer()

                Image(systemName: showChevron ? "arrow.up.right" : "chevron.right")
                    .font(Typography.Icon.xxs.weight(.medium))
                    .foregroundStyle(isEnabled ? Color.bibleInsightText.opacity(Theme.Opacity.focusStroke) : Color.bibleInsightText.opacity(Theme.Opacity.selectionBackground))
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md - 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - Preview

#Preview("Insight Sheet") {
    struct PreviewContainer: View {
        @State private var isPresented = true

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
            Color.bibleInsightParchment
                .ignoresSafeArea()
                .sheet(isPresented: $isPresented) {
                    BibleInsightSheet(
                        verse: Verse(bookId: 43, chapter: 1, verse: 1, text: "In the beginning was the Word..."),
                        insights: sampleInsights,
                        onDismiss: { isPresented = false }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
                }
        }
    }

    return PreviewContainer()
}

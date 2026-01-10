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
    @State private var contentId = UUID()  // For verse change animation

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
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.faint))
                // swiftlint:disable:next hardcoded_frame
                .frame(height: 0.5)

            // Content area with verse change animation
            ScrollView {
                Group {
                    if selectedInsights.isEmpty {
                        emptyLensState
                    } else {
                        flatContent
                    }
                }
                .id(contentId)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.md + 2)
                .padding(.bottom, Theme.Spacing.xl)
            }

            // Footer actions (parallel style)
            footerActions
        }
        .background(Color.bibleInsightCardBackground)
        .onAppear {
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
            // Animate content change on verse navigation
            if !reduceMotion {
                withAnimation(Theme.Animation.settle) {
                    contentId = UUID()
                }
            } else {
                contentId = UUID()
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
                onDismiss: { showConnectionsSheet = false },
                onDismissAll: {
                    showConnectionsSheet = false
                    dismissAll()
                },
                onNavigateToReference: { reference in
                    showConnectionsSheet = false
                    dismissAll()
                    onNavigateToReference?(reference)
                }
            )
            .presentationDetents([.fraction(0.55), .fraction(0.95)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSourcesSheet) {
            SourcesSheet(
                verse: verse,
                sources: allSources,
                onDismiss: { showSourcesSheet = false },
                onDismissAll: {
                    showSourcesSheet = false
                    dismissAll()
                },
                onNavigateToReference: { reference in
                    showSourcesSheet = false
                    dismissAll()
                    onNavigateToReference?(reference)
                }
            )
            .presentationDetents([.fraction(0.55), .fraction(0.95)])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Empty Lens State

    private var emptyLensState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: selectedLens?.icon ?? "questionmark.circle")
                .font(Typography.Icon.xl)
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.lightMedium))

            Text("No \(selectedLens?.label.lowercased() ?? "content") for this verse")
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 13, weight: .regular, design: .serif))
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
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.light))
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
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.light))
                }

                // Verse reference
                Text(verseReference)
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 16, weight: .semibold, design: .serif))
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
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.light))
                }

                Spacer()

                // Close button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(Typography.Icon.xxs.weight(.medium))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.medium))
                        .padding(Theme.Spacing.xs)
                        .background(Circle().fill(Color.bibleInsightText.opacity(Theme.Opacity.faint / 2)))
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
                        .fill(Color.bibleInsightText.opacity(Theme.Opacity.faint))
                        // swiftlint:disable:next hardcoded_frame
                        .frame(width: 0.5, height: Theme.Spacing.lg)
                }
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.faint / 2))
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
                    : (isEnabled ? Color.bibleInsightText.opacity(Theme.Opacity.heavy - 0.05) : Color.bibleInsightText.opacity(Theme.Opacity.lightMedium))
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
                FlatInsightView(insight: insight, onDismissAll: dismissAll)
            }
        }
    }

    // MARK: - Footer Actions (Parallel Style)

    private var footerActions: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.faint))
                // swiftlint:disable:next hardcoded_frame
                .frame(height: 0.5)

            // Action rows (consistent parallel style)
            VStack(spacing: 0) {
                // Sources row (opens drill-in sheet)
                footerRow(
                    icon: "text.quote",
                    label: "Sources",
                    count: totalSourceCount,
                    color: Color.accentIndigo,
                    isEnabled: totalSourceCount > 0
                ) {
                    showSourcesSheet = true
                }

                Rectangle()
                    .fill(Color.bibleInsightText.opacity(Theme.Opacity.faint / 2))
                    // swiftlint:disable:next hardcoded_frame
                    .frame(height: 0.5)

                // Connections row
                footerRow(
                    icon: "arrow.triangle.branch",
                    label: "Connections",
                    count: connectionCount,
                    color: .connectionAmber,
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
                    .foregroundStyle(isEnabled ? color : color.opacity(Theme.Opacity.medium))
                    .frame(width: Theme.Spacing.lg)

                Text(label)
                    .font(Typography.Icon.xs.weight(.medium))
                    .foregroundStyle(isEnabled ? Color.bibleInsightText.opacity(Theme.Opacity.pressed) : Color.bibleInsightText.opacity(Theme.Opacity.medium))

                if let count = count {
                    Text("(\(count))")
                        .font(Typography.Icon.xxs)
                        .foregroundStyle(isEnabled ? color.opacity(Theme.Opacity.heavy) : color.opacity(Theme.Opacity.lightMedium))
                }

                Spacer()

                Image(systemName: showChevron ? "arrow.up.right" : "chevron.right")
                    .font(Typography.Icon.xxs.weight(.medium))
                    .foregroundStyle(isEnabled ? Color.bibleInsightText.opacity(Theme.Opacity.medium) : Color.bibleInsightText.opacity(Theme.Opacity.light))
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md - 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - Flat Insight View (No Card Border)
// Dense typography for fast scanning - annotation, not scripture

struct FlatInsightView: View {
    let insight: BibleInsight

    /// Optional: Dismiss entire sheet stack (for InterpretiveBadgeSheet)
    var onDismissAll: (() -> Void)?

    /// Optional: Callback for writing a note (Reflection CTA)
    var onWriteNote: ((BibleInsight) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showInterpretiveExplanation = false
    @State private var isSavedToJournal = false

    /// Is this a reflection/question type insight?
    private var isReflection: Bool {
        insight.insightType == .question
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Title (compact)
            Text(insight.title)
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundStyle(Color.bibleInsightText)

            // Content (dense, fast to scan)
            Text(insight.content)
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 14, weight: .regular, design: .serif))
                // swiftlint:disable:next hardcoded_line_spacing
                .lineSpacing(3)
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.pressed))

            // Interpretive badge (tappable) - Sources are accessed via footer row
            if insight.isInterpretive {
                interpretiveBadge
                    .padding(.top, 2)
            }

            // Reflection CTA (only for question-type insights)
            if isReflection {
                reflectionCTA
                    .padding(.top, Theme.Spacing.xs)
            }
        }
        .sheet(isPresented: $showInterpretiveExplanation) {
            InterpretiveBadgeSheet(
                onDismiss: { showInterpretiveExplanation = false },
                onDismissAll: {
                    showInterpretiveExplanation = false
                    onDismissAll?()
                }
            )
            // swiftlint:disable:next hardcoded_presentation_detent
            .presentationDetents([.height(320)])  // Slightly taller for new header
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Reflection CTA

    private var reflectionCTA: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Write a note button
            Button {
                HapticService.shared.mediumTap()
                onWriteNote?(insight)
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "square.and.pencil")
                        .font(Typography.Icon.xxs.weight(.medium))
                    Text("Write a note")
                        .font(Typography.Icon.xxs.weight(.medium))
                }
                .foregroundStyle(Color.bibleReflection)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs + 1)
                .background(
                    Capsule()
                        .fill(Color.bibleReflection.opacity(Theme.Opacity.subtle))
                )
            }
            .buttonStyle(.plain)

            // Save to journal button
            Button {
                HapticService.shared.lightTap()
                withAnimation(Theme.Animation.settle) {
                    isSavedToJournal.toggle()
                }
                // TODO: Actually save to journal
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: isSavedToJournal ? "bookmark.fill" : "bookmark")
                        .font(Typography.Icon.xxs.weight(.medium))
                    Text(isSavedToJournal ? "Saved" : "Save question")
                        .font(Typography.Icon.xxs.weight(.medium))
                }
                .foregroundStyle(isSavedToJournal ? Color.bibleReflection : Color.bibleInsightText.opacity(Theme.Opacity.heavy))
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs + 1)
                .background(
                    Capsule()
                        .fill(isSavedToJournal ? Color.bibleReflection.opacity(Theme.Opacity.subtle) : Color.bibleInsightText.opacity(Theme.Opacity.faint / 2))
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private var interpretiveBadge: some View {
        Button {
            HapticService.shared.lightTap()
            showInterpretiveExplanation = true
        } label: {
            HStack(spacing: 2) {
                Image(systemName: "info.circle")
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Icon.xxxs)
                Text("Interpretive")
                    .font(Typography.Icon.xxs.weight(.medium))
            }
            .foregroundStyle(Color.info)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.info.opacity(Theme.Opacity.subtle))
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Tap to learn what interpretive means")
    }
}

// MARK: - Connections Sheet (Stacked)
// Separate surface for exploring cross-references as a graph
// Opens from InsightSheet footer, not inline
// Designed for scale: filters, caps, grouping

struct ConnectionsSheet: View {
    let verse: Verse
    let connections: [BibleInsight]
    let onDismiss: () -> Void         // Back to InsightSheet
    var onDismissAll: (() -> Void)?   // Dismiss entire sheet stack
    var onNavigateToReference: ((String) -> Void)?  // Navigate to a cross-reference

    // MARK: - State for Chapter Map
    @State private var showChapterMap = false

    // MARK: - Connection Filter

    enum ConnectionFilter: String, CaseIterable {
        case all = "All"
        case oldTestament = "OT"
        case newTestament = "NT"
        case themes = "Themes"

        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .oldTestament: return "scroll"
            case .newTestament: return "book.closed"
            case .themes: return "tag"
            }
        }
    }

    // MARK: - State

    @State private var selectedFilter: ConnectionFilter = .all
    @State private var showAllConnections = false

    // MARK: - Constants

    private let displayCap = 10

    // MARK: - Computed Properties

    /// Verse reference
    private var verseReference: String {
        guard let book = Book.find(byId: verse.bookId) else { return "Verse \(verse.verse)" }
        return "\(book.name) \(verse.chapter):\(verse.verse)"
    }

    /// Filtered connections based on selected filter
    private var filteredConnections: [BibleInsight] {
        switch selectedFilter {
        case .all:
            return connections
        case .oldTestament:
            // Filter to OT books (Genesis-Malachi, book IDs 1-39)
            return connections.filter { connection in
                // Parse target book from title if possible
                // For now, show all if we can't determine
                true  // TODO: Parse book ID from connection
            }
        case .newTestament:
            // Filter to NT books (Matthew-Revelation, book IDs 40-66)
            return connections.filter { connection in
                true  // TODO: Parse book ID from connection
            }
        case .themes:
            // Filter to thematic connections
            return connections.filter { connection in
                connection.content.lowercased().contains("theme") ||
                connection.content.lowercased().contains("parallel") ||
                connection.content.lowercased().contains("echo")
            }
        }
    }

    /// Connections to display (capped unless showing all)
    private var displayedConnections: [BibleInsight] {
        if showAllConnections || filteredConnections.count <= displayCap {
            return filteredConnections
        }
        return Array(filteredConnections.prefix(displayCap))
    }

    /// Whether there are more connections beyond the cap
    private var hasMoreConnections: Bool {
        filteredConnections.count > displayCap && !showAllConnections
    }

    /// Count of hidden connections
    private var hiddenCount: Int {
        max(0, filteredConnections.count - displayCap)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with Back/Close navigation
            header

            Rectangle()
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.faint))
                // swiftlint:disable:next hardcoded_frame
                .frame(height: 0.5)

            // Filter tabs (if more than a few connections)
            if connections.count > 3 {
                filterTabs
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.md)

                Rectangle()
                    .fill(Color.bibleInsightText.opacity(Theme.Opacity.faint / 2))
                    // swiftlint:disable:next hardcoded_frame
                    .frame(height: 0.5)
            }

            // Connections list
            if filteredConnections.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.md) {
                        ForEach(displayedConnections) { connection in
                            connectionRow(connection)
                        }

                        // "Show more" button if capped
                        if hasMoreConnections {
                            showMoreButton
                        }
                    }
                    .padding(Theme.Spacing.lg)

                    // Chapter Map CTA at bottom
                    chapterMapCTA
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)
                }
            }
        }
        .background(Color.bibleInsightCardBackground)
        .fullScreenCover(isPresented: $showChapterMap) {
            ChapterMapView(
                verse: verse,
                connections: connections,
                onDismiss: { showChapterMap = false },
                onDismissAll: {
                    showChapterMap = false
                    onDismissAll?()
                },
                onNavigateToReference: { reference in
                    showChapterMap = false
                    onNavigateToReference?(reference)
                }
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Back button
            Button {
                HapticService.shared.lightTap()
                onDismiss()
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "chevron.left")
                        .font(Typography.Icon.xs.weight(.semibold))
                    Text("Back")
                        .font(Typography.Command.caption.weight(.medium))
                }
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
            }
            .buttonStyle(.plain)

            Spacer()

            // Title
            // swiftlint:disable:next hardcoded_stack_spacing
            VStack(spacing: 1) {  // Tight title/subtitle spacing
                Text("Connections")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(Color.bibleInsightText)

                Text("\(connections.count) passage\(connections.count == 1 ? "" : "s")")
                    .font(Typography.Icon.xxs)
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
            }

            Spacer()

            // Close button
            Button {
                HapticService.shared.lightTap()
                if let dismissAll = onDismissAll {
                    dismissAll()
                } else {
                    onDismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(Typography.Icon.xxs.weight(.medium))
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                    .padding(Theme.Spacing.xs)
                    .background(Circle().fill(Color.bibleInsightText.opacity(Theme.Opacity.faint / 2)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(ConnectionFilter.allCases, id: \.self) { filter in
                filterTab(filter)
            }
        }
    }

    private func filterTab(_ filter: ConnectionFilter) -> some View {
        let isSelected = selectedFilter == filter
        let count = countForFilter(filter)

        return Button {
            HapticService.shared.lightTap()
            withAnimation(Theme.Animation.settle) {
                selectedFilter = filter
                showAllConnections = false  // Reset cap when changing filter
            }
        } label: {
            HStack(spacing: 2) {
                Text(filter.rawValue)
                    .font(Typography.Icon.xxs.weight(isSelected ? .semibold : .medium))

                if count > 0 && filter != .all {
                    Text("\(count)")
                        // swiftlint:disable:next hardcoded_font_system
                        .font(Typography.Icon.xxxs)
                        .foregroundStyle(isSelected ? Color.bibleInsightCardBackground.opacity(Theme.Opacity.overlay) : Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                }
            }
            .foregroundStyle(isSelected ? Color.bibleInsightCardBackground : Color.bibleInsightText.opacity(Theme.Opacity.heavy))
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? Color.feedbackWarning : Color.bibleInsightText.opacity(Theme.Opacity.faint / 2))
            )
        }
        .buttonStyle(.plain)
    }

    private func countForFilter(_ filter: ConnectionFilter) -> Int {
        switch filter {
        case .all: return connections.count
        case .oldTestament, .newTestament, .themes:
            // Return count based on filter logic
            return filteredConnections.count
        }
    }

    // MARK: - Show More Button

    private var showMoreButton: some View {
        Button {
            HapticService.shared.lightTap()
            withAnimation(Theme.Animation.settle) {
                showAllConnections = true
            }
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Text("Show \(hiddenCount) more")
                    .font(Typography.Icon.xs.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(Typography.Icon.xxs.weight(.semibold))
            }
            .foregroundStyle(Color.feedbackWarning)
            .padding(.vertical, Theme.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(Color.feedbackWarning.opacity(Theme.Opacity.faint))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Chapter Map CTA
    // When few connections: Big callout (teaches feature)
    // When many connections: Compact row (doesn't compete with list)

    @ViewBuilder
    private var chapterMapCTA: some View {
        if connections.count <= 5 {
            // Prominent callout for first-time discovery
            chapterMapCallout
        } else {
            // Compact row when list dominates
            chapterMapCompact
        }
    }

    private var chapterMapCallout: some View {
        Button {
            HapticService.shared.mediumTap()
            showChapterMap = true
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "map")
                    .font(Typography.Icon.sm)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Open Chapter Map")
                        .font(Typography.Command.caption.weight(.medium))
                    Text("See all connections visually")
                        .font(Typography.Icon.xxs)
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(Typography.Icon.xxs.weight(.semibold))
            }
            .foregroundStyle(Color.feedbackWarning)
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color.feedbackWarning.opacity(Theme.Opacity.faint))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    // swiftlint:disable:next hardcoded_line_width
                    .stroke(Color.feedbackWarning.opacity(Theme.Opacity.lightMedium), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var chapterMapCompact: some View {
        Button {
            HapticService.shared.mediumTap()
            showChapterMap = true
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "map")
                    .font(Typography.Icon.xxs)
                Text("Chapter Map")
                    .font(Typography.Icon.xxs.weight(.medium))
                Image(systemName: "arrow.up.right")
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Icon.xxxs.weight(.semibold))
            }
            .foregroundStyle(Color.feedbackWarning)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(Color.feedbackWarning.opacity(Theme.Opacity.faint))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "arrow.triangle.branch")
                .font(Typography.Icon.xxl)
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.lightMedium))

            Text(selectedFilter == .all ? "No connections yet" : "No \(selectedFilter.rawValue) connections")
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, Theme.Spacing.xxl + 8)
    }

    // MARK: - Connection Row

    private func connectionRow(_ connection: BibleInsight) -> some View {
        // Extract target passage from sources (first cross-reference)
        let targetPassage = connection.sources
            .first { $0.type == .crossReference }?
            .reference

        return Button {
            HapticService.shared.lightTap()
            // Navigate to the referenced verse
            if let reference = targetPassage {
                onNavigateToReference?(reference)
            }
        } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Header: Target passage + connection type badge
                HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                    // Connection icon
                    Image(systemName: "link")
                        .font(Typography.Icon.xxs.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(width: Theme.Spacing.xl, height: Theme.Spacing.xl)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.input - 1)
                                .fill(Color.feedbackWarning)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        // Connection title
                        Text(connection.title)
                            .font(Typography.Command.caption.weight(.semibold))
                            .foregroundStyle(Color.bibleInsightText)

                        // Target passage (if available)
                        if let passage = targetPassage {
                            Text(passage)
                                .font(Typography.Icon.xxs)
                                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
                        }

                        // Connection type badge
                        Text(connectionType(for: connection))
                            // swiftlint:disable:next hardcoded_font_system
                            .font(Typography.Icon.xxxs)
                            .foregroundStyle(Color.feedbackWarning)
                            .textCase(.uppercase)
                            // swiftlint:disable:next hardcoded_tracking
                            .tracking(0.5)
                    }

                    Spacer()

                    // Navigation chevron (consistent with Sources)
                    Image(systemName: "chevron.right")
                        .font(Typography.Icon.xs.weight(.semibold))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.medium))
                }

                // 1-line rationale
                Text(connection.content)
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    // swiftlint:disable:next hardcoded_line_spacing
                    .lineSpacing(2)
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.overlay + 0.05))
                    .lineLimit(2)
                    .padding(.leading, Theme.Spacing.xxl + 4)  // Align with title
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color.bibleInsightText.opacity(Theme.Opacity.faint / 2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    // swiftlint:disable:next hardcoded_line_width
                    .stroke(Color.feedbackWarning.opacity(Theme.Opacity.faint), lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Determine connection type from content (heuristic)
    private func connectionType(for connection: BibleInsight) -> String {
        let content = connection.content.lowercased()
        if content.contains("echo") || content.contains("allusion") {
            return "Echo"
        } else if content.contains("parallel") {
            return "Parallel"
        } else if content.contains("fulfillment") || content.contains("fulfilled") {
            return "Fulfillment"
        } else if content.contains("type") || content.contains("shadow") {
            return "Type"
        } else if content.contains("quote") || content.contains("cited") {
            return "Quotation"
        } else if content.contains("theme") {
            return "Theme"
        } else if content.contains("creation") || content.contains("genesis") {
            return "Creation"
        }
        return "Reference"
    }
}

// MARK: - Sources Sheet (Stacked)
// Separate surface for viewing all sources/citations
// Opens from InsightSheet footer, not inline

struct SourcesSheet: View {
    let verse: Verse
    let sources: [InsightSource]
    let onDismiss: () -> Void         // Back to InsightSheet
    var onDismissAll: (() -> Void)?   // Dismiss entire sheet stack
    var onNavigateToReference: ((String) -> Void)?  // Navigate to a cross-reference

    // MARK: - State
    @State private var selectedSource: InsightSource?

    /// Verse reference
    private var verseReference: String {
        guard let book = Book.find(byId: verse.bookId) else { return "Verse \(verse.verse)" }
        return "\(book.name) \(verse.chapter):\(verse.verse)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with Back/Close navigation
            HStack(spacing: Theme.Spacing.md) {
                // Back button (returns to InsightSheet)
                Button {
                    HapticService.shared.lightTap()
                    onDismiss()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                            .font(Typography.Icon.xs.weight(.semibold))
                        Text("Back")
                            .font(Typography.Command.caption.weight(.medium))
                    }
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
                }
                .buttonStyle(.plain)

                Spacer()

                // Title
                // swiftlint:disable:next hardcoded_stack_spacing
                VStack(spacing: 1) {  // Tight title/subtitle spacing
                    Text("Sources")
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundStyle(Color.bibleInsightText)

                    Text("\(sources.count) citation\(sources.count == 1 ? "" : "s")")
                        .font(Typography.Icon.xxs)
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
                }

                Spacer()

                // Close button (dismisses entire stack)
                Button {
                    HapticService.shared.lightTap()
                    if let dismissAll = onDismissAll {
                        dismissAll()
                    } else {
                        onDismiss()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(Typography.Icon.xxs.weight(.medium))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                        .padding(Theme.Spacing.xs)
                        .background(Circle().fill(Color.bibleInsightText.opacity(Theme.Opacity.faint / 2)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)

            Rectangle()
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.faint))
                // swiftlint:disable:next hardcoded_frame
                .frame(height: 0.5)

            // Sources list
            if sources.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.md) {
                        ForEach(sources, id: \.reference) { source in
                            sourceRow(source)
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
        }
        .background(Color.bibleInsightCardBackground)
        .sheet(item: $selectedSource) { source in
            SourceDetailSheet(
                verse: verse,
                source: source,
                onDismiss: { selectedSource = nil },
                onDismissAll: {
                    selectedSource = nil
                    onDismissAll?()
                },
                onNavigateToReference: { reference in
                    selectedSource = nil
                    onNavigateToReference?(reference)
                }
            )
            .presentationDetents([.fraction(0.55), .fraction(0.95)])
            .presentationDragIndicator(.visible)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "text.quote")
                .font(Typography.Icon.xxl)
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.lightMedium))

            Text("No sources available")
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, Theme.Spacing.xxl + 8)
    }

    private func sourceRow(_ source: InsightSource) -> some View {
        Button {
            HapticService.shared.lightTap()
            selectedSource = source
        } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Header row: icon + formatted title + chevron
                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    // Type icon with colored background
                    sourceIcon(for: source.type)
                        .font(Typography.Icon.xs.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.input)
                                .fill(sourceColor(for: source.type))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        // Formatted title based on type
                        Text(formattedTitle(for: source))
                            .font(Typography.Command.caption.weight(.semibold))
                            .foregroundStyle(Color.bibleInsightText)

                        // Type badge inline
                        Text(source.type.label)
                            // swiftlint:disable:next hardcoded_font_system
                            .font(Typography.Icon.xxxs)
                            .foregroundStyle(sourceColor(for: source.type))
                            .textCase(.uppercase)
                            // swiftlint:disable:next hardcoded_tracking
                            .tracking(0.5)
                    }

                    Spacer()

                    // Navigation chevron (consistent with Connections)
                    Image(systemName: "chevron.right")
                        .font(Typography.Icon.xs.weight(.semibold))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.medium))
                }

                // "Cited for" rationale
                if let description = source.description {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cited for")
                            // swiftlint:disable:next hardcoded_font_system
                            .font(Typography.Icon.xxxs.weight(.semibold))
                            .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                            .textCase(.uppercase)
                            // swiftlint:disable:next hardcoded_tracking
                            .tracking(0.5)

                        Text(description)
                            // swiftlint:disable:next hardcoded_font_custom
                            .font(.system(size: 13, weight: .regular, design: .serif))
                            .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.pressed))
                            // swiftlint:disable:next hardcoded_line_spacing
                            .lineSpacing(2)
                    }
                    .padding(.leading, Theme.Spacing.xxl + Theme.Spacing.md)  // Align with title
                }
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color.bibleInsightText.opacity(Theme.Opacity.faint / 2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    // swiftlint:disable:next hardcoded_line_width
                    .stroke(sourceColor(for: source.type).opacity(Theme.Opacity.subtle), lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Format title based on source type for explicit display
    private func formattedTitle(for source: InsightSource) -> String {
        switch source.type {
        case .strongs:
            // e.g., "Strong's G3056" → "Strong's Greek Lexicon (G3056)"
            // Extract the number part (G3056 or H1234)
            let pattern = /([GH]\d+)/
            if let match = source.reference.firstMatch(of: pattern) {
                let number = String(match.output.1)
                if number.hasPrefix("G") {
                    return "Strong's Greek Lexicon (\(number))"
                } else if number.hasPrefix("H") {
                    return "Strong's Hebrew Lexicon (\(number))"
                }
            }
            return source.reference
        case .crossReference:
            return source.reference
        case .commentary:
            return source.reference
        case .lexicon:
            return source.reference
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

// MARK: - Interpretive Badge Explanation Sheet
// Small sheet explaining what "Interpretive" means

struct InterpretiveBadgeSheet: View {
    let onDismiss: () -> Void         // Back to FlatInsightView
    var onDismissAll: (() -> Void)?   // Dismiss entire sheet stack

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Header with Back/Close navigation
            HStack(spacing: Theme.Spacing.md) {
                // Back button
                Button {
                    HapticService.shared.lightTap()
                    onDismiss()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                            .font(Typography.Icon.xs.weight(.semibold))
                        Text("Back")
                            .font(Typography.Command.caption.weight(.medium))
                    }
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
                }
                .buttonStyle(.plain)

                Spacer()

                // Title with icon
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "info.circle.fill")
                        .font(Typography.Icon.sm)
                        .foregroundStyle(Color.info)

                    Text("About Interpretive")
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundStyle(Color.bibleInsightText)
                }

                Spacer()

                // Close button (dismisses entire stack)
                Button {
                    HapticService.shared.lightTap()
                    if let dismissAll = onDismissAll {
                        dismissAll()
                    } else {
                        onDismiss()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(Typography.Icon.xxs.weight(.medium))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                        .padding(Theme.Spacing.xs)
                        .background(Circle().fill(Color.bibleInsightText.opacity(Theme.Opacity.faint / 2)))
                }
                .buttonStyle(.plain)
            }

            // Explanation
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Insights marked as \"Interpretive\" represent theological synthesis or application rather than direct textual facts.")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.pressed + 0.05))
                    // swiftlint:disable:next hardcoded_line_spacing
                    .lineSpacing(3)

                // Types grid
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    typeRow(
                        icon: "quote.bubble",
                        title: "Textual",
                        description: "Direct from the original text",
                        color: .theologyGreen
                    )
                    typeRow(
                        icon: "sparkles",
                        title: "Interpretive",
                        description: "Theological synthesis; may vary by tradition",
                        color: .info
                    )
                    typeRow(
                        icon: "clock",
                        title: "Historical",
                        description: "Based on historical context",
                        color: .connectionAmber
                    )
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Color.bibleInsightCardBackground)
    }

    private func typeRow(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(Typography.Icon.xs)
                .foregroundStyle(color)
                .frame(width: Theme.Spacing.xl)

            // swiftlint:disable:next hardcoded_stack_spacing
            VStack(alignment: .leading, spacing: 1) {  // Tight title/description spacing
                Text(title)
                    .font(Typography.Icon.xs.weight(.medium))
                    .foregroundStyle(Color.bibleInsightText)

                Text(description)
                    .font(Typography.Icon.xxs)
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Source Detail Sheet
// Shows expanded detail for a source (Strong's lexicon, cross-reference text, etc.)

struct SourceDetailSheet: View {
    let verse: Verse
    let source: InsightSource
    let onDismiss: () -> Void
    var onDismissAll: (() -> Void)?
    var onNavigateToReference: ((String) -> Void)?

    // MARK: - State
    @State private var verseText: String?
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Rectangle()
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.faint))
                // swiftlint:disable:next hardcoded_frame
                .frame(height: 0.5)

            // Content based on source type
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    sourceContent
                }
                .padding(Theme.Spacing.lg)
            }

            // Action button for cross-references
            if source.type == .crossReference {
                actionButton
            }
        }
        .background(Color.bibleInsightCardBackground)
        .task {
            await loadSourceContent()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Back button
            Button {
                HapticService.shared.lightTap()
                onDismiss()
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "chevron.left")
                        .font(Typography.Icon.xs.weight(.semibold))
                    Text("Back")
                        .font(Typography.Command.caption.weight(.medium))
                }
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
            }
            .buttonStyle(.plain)

            Spacer()

            // Title with icon
            HStack(spacing: Theme.Spacing.sm) {
                sourceIcon
                    .font(Typography.Icon.sm.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.input)
                            .fill(sourceColor)
                    )

                Text(source.type.label)
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundStyle(Color.bibleInsightText)
            }

            Spacer()

            // Close button
            Button {
                HapticService.shared.lightTap()
                if let dismissAll = onDismissAll {
                    dismissAll()
                } else {
                    onDismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(Typography.Icon.xxs.weight(.medium))
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                    .padding(Theme.Spacing.xs)
                    .background(Circle().fill(Color.bibleInsightText.opacity(Theme.Opacity.faint / 2)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
    }

    // MARK: - Source Content

    @ViewBuilder
    private var sourceContent: some View {
        switch source.type {
        case .crossReference:
            crossReferenceContent
        case .strongs:
            strongsContent
        case .commentary:
            commentaryContent
        case .lexicon:
            lexiconContent
        }
    }

    private var crossReferenceContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Reference title
            Text(source.reference)
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 18, weight: .medium, design: .serif))
                .foregroundStyle(Color.bibleInsightText)

            // Description (why cited)
            if let description = source.description {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Connection")
                        // swiftlint:disable:next hardcoded_font_system
                        .font(Typography.Icon.xxs.weight(.semibold))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                        .textCase(.uppercase)
                        // swiftlint:disable:next hardcoded_tracking
                        .tracking(0.5)

                    Text(description)
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.pressed))
                        // swiftlint:disable:next hardcoded_line_spacing
                        .lineSpacing(3)
                }
            }

            // Verse text (loaded async)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Text")
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Icon.xxs.weight(.semibold))
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                    .textCase(.uppercase)
                    // swiftlint:disable:next hardcoded_tracking
                    .tracking(0.5)

                if isLoading {
                    HStack(spacing: Theme.Spacing.sm) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading verse...")
                            // swiftlint:disable:next hardcoded_font_custom
                            .font(.system(size: 14, weight: .regular, design: .serif))
                            .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
                    }
                } else if let text = verseText {
                    Text(text)
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundStyle(Color.bibleInsightText)
                        // swiftlint:disable:next hardcoded_line_spacing
                        .lineSpacing(4)
                        .italic()
                } else {
                    Text("Verse text not available")
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
                }
            }
            .padding(.top, Theme.Spacing.sm)
        }
    }

    private var strongsContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Strong's number title
            Text(formattedStrongsTitle)
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 18, weight: .medium, design: .serif))
                .foregroundStyle(Color.bibleInsightText)

            // Gloss/Description
            if let description = source.description {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Gloss")
                        // swiftlint:disable:next hardcoded_font_system
                        .font(Typography.Icon.xxs.weight(.semibold))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                        .textCase(.uppercase)
                        // swiftlint:disable:next hardcoded_tracking
                        .tracking(0.5)

                    Text(description)
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.bibleInsightText)
                }
            }

            // Placeholder for additional lexicon data
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Definition")
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Icon.xxs.weight(.semibold))
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                    .textCase(.uppercase)
                    // swiftlint:disable:next hardcoded_tracking
                    .tracking(0.5)

                if isLoading {
                    HStack(spacing: Theme.Spacing.sm) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading lexicon entry...")
                            // swiftlint:disable:next hardcoded_font_custom
                            .font(.system(size: 14, weight: .regular, design: .serif))
                            .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
                    }
                } else {
                    Text("The lexicon entry shows the original word's meaning, etymology, and usage across Scripture.")
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.pressed))
                        // swiftlint:disable:next hardcoded_line_spacing
                        .lineSpacing(3)
                }
            }
            .padding(.top, Theme.Spacing.sm)
        }
    }

    private var commentaryContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(source.reference)
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 18, weight: .medium, design: .serif))
                .foregroundStyle(Color.bibleInsightText)

            if let description = source.description {
                Text(description)
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.pressed))
                    // swiftlint:disable:next hardcoded_line_spacing
                    .lineSpacing(3)
            }
        }
    }

    private var lexiconContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(source.reference)
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 18, weight: .medium, design: .serif))
                .foregroundStyle(Color.bibleInsightText)

            if let description = source.description {
                Text(description)
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.pressed))
                    // swiftlint:disable:next hardcoded_line_spacing
                    .lineSpacing(3)
            }
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.faint))
                // swiftlint:disable:next hardcoded_frame
                .frame(height: 0.5)

            Button {
                HapticService.shared.mediumTap()
                onNavigateToReference?(source.reference)
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(Typography.Icon.sm)
                    Text("Go to \(source.reference)")
                        .font(Typography.Command.caption.weight(.medium))
                }
                .foregroundStyle(Color.feedbackWarning)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md + 2)
            }
            .buttonStyle(.plain)
        }
        .background(Color.bibleInsightCardBackground)
    }

    // MARK: - Helpers

    private var sourceIcon: Image {
        switch source.type {
        case .crossReference: return Image(systemName: "link")
        case .strongs: return Image(systemName: "character.book.closed")
        case .commentary: return Image(systemName: "text.book.closed")
        case .lexicon: return Image(systemName: "textformat.abc")
        }
    }

    private var sourceColor: Color {
        switch source.type {
        case .crossReference: return .connectionAmber
        case .strongs: return .greekBlue
        case .commentary: return .theologyGreen
        case .lexicon: return .greekBlue
        }
    }

    private var formattedStrongsTitle: String {
        let pattern = /([GH]\d+)/
        if let match = source.reference.firstMatch(of: pattern) {
            let number = String(match.output.1)
            if number.hasPrefix("G") {
                return "Greek Word (\(number))"
            } else if number.hasPrefix("H") {
                return "Hebrew Word (\(number))"
            }
        }
        return source.reference
    }

    private func loadSourceContent() async {
        // Simulate loading time
        try? await Task.sleep(nanoseconds: 300_000_000)  // 0.3s

        // For cross-references, try to load the verse text
        if source.type == .crossReference {
            let result = ReferenceParser.parse(source.reference)
            if case .success(let parsed) = result {
                // Create verse range for the target verse
                let verseNum = parsed.verseStart ?? 1
                let range = VerseRange(
                    bookId: parsed.book.id,
                    chapter: parsed.chapter,
                    verseStart: verseNum,
                    verseEnd: parsed.verseEnd ?? verseNum
                )

                // Load verse from BibleService
                do {
                    let verses = try await BibleService.shared.getVerses(range: range)
                    if let foundVerse = verses.first {
                        verseText = foundVerse.text
                    }
                } catch {
                    verseText = nil
                }
            }
        }

        isLoading = false
    }
}

// MARK: - Chapter Map View
// Visual representation of all connections for a chapter

struct ChapterMapView: View {
    let verse: Verse
    let connections: [BibleInsight]
    let onDismiss: () -> Void
    var onDismissAll: (() -> Void)?
    var onNavigateToReference: ((String) -> Void)?

    // MARK: - State
    @State private var selectedConnection: BibleInsight?
    @State private var viewMode: ViewMode = .list

    enum ViewMode: String, CaseIterable {
        case list = "List"
        case groups = "Groups"

        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .groups: return "rectangle.3.group"
            }
        }
    }

    // MARK: - Computed Properties

    private var verseReference: String {
        guard let book = Book.find(byId: verse.bookId) else { return "Chapter \(verse.chapter)" }
        return "\(book.name) \(verse.chapter)"
    }

    /// Connections grouped by target book
    private var groupedConnections: [(String, [BibleInsight])] {
        var groups: [String: [BibleInsight]] = [:]

        for connection in connections {
            if let reference = connection.sources.first(where: { $0.type == .crossReference })?.reference {
                // Extract book name from reference
                let bookName = extractBookName(from: reference)
                groups[bookName, default: []].append(connection)
            }
        }

        return groups.sorted { $0.key < $1.key }
    }

    /// Old Testament connections
    private var otConnections: [BibleInsight] {
        connections.filter { connection in
            if let reference = connection.sources.first(where: { $0.type == .crossReference })?.reference {
                let result = ReferenceParser.parse(reference)
                if case .success(let parsed) = result {
                    return parsed.book.id < 40  // OT books 1-39
                }
            }
            return false
        }
    }

    /// New Testament connections
    private var ntConnections: [BibleInsight] {
        connections.filter { connection in
            if let reference = connection.sources.first(where: { $0.type == .crossReference })?.reference {
                let result = ReferenceParser.parse(reference)
                if case .success(let parsed) = result {
                    return parsed.book.id >= 40  // NT books 40-66
                }
            }
            return false
        }
    }

    /// Descriptive subtitle: "John 1 · 3 connections" or "John 1 · 1 OT, 2 NT"
    private var subtitleText: Text {
        let otCount = otConnections.count
        let ntCount = ntConnections.count
        let total = connections.count
        let connectionWord = total == 1 ? "connection" : "connections"

        if otCount > 0 && ntCount > 0 {
            // Both OT and NT - show breakdown
            return Text("\(verseReference) · \(otCount) OT, \(ntCount) NT")
        } else if otCount > 0 {
            // Only OT
            return Text("\(verseReference) · \(otCount) OT \(connectionWord)")
        } else if ntCount > 0 {
            // Only NT
            return Text("\(verseReference) · \(ntCount) NT \(connectionWord)")
        } else {
            // Fallback
            return Text("\(verseReference) · \(total) \(connectionWord)")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Rectangle()
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.faint))
                // swiftlint:disable:next hardcoded_frame
                .frame(height: 0.5)

            // View mode toggle
            viewModeToggle
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md - 2)

            Rectangle()
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.faint / 2))
                // swiftlint:disable:next hardcoded_frame
                .frame(height: 0.5)

            // Content
            if connections.isEmpty {
                emptyState
            } else {
                ScrollView {
                    switch viewMode {
                    case .list:
                        listView
                    case .groups:
                        groupsView
                    }
                }
            }
        }
        .background(Color.bibleInsightCardBackground)
        .fullScreenCover(item: $selectedConnection) { connection in
            ConnectionDetailView(
                sourceVerse: verse,
                connection: connection,
                onDismiss: { selectedConnection = nil },
                onDismissAll: {
                    selectedConnection = nil
                    onDismissAll?()
                },
                onNavigateToReference: { reference in
                    selectedConnection = nil
                    onNavigateToReference?(reference)
                }
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            // Top bar with Done button only (no redundant X)
            HStack {
                Spacer()

                // Done button dismisses entire sheet stack
                Button {
                    HapticService.shared.lightTap()
                    if let dismissAll = onDismissAll {
                        dismissAll()
                    } else {
                        onDismiss()
                    }
                } label: {
                    Text("Done")
                        .font(Typography.Command.body.weight(.medium))
                        .foregroundStyle(Color.feedbackWarning)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.sm)

            // Title area
            VStack(spacing: Theme.Spacing.xs) {
                Text("Chapter Map")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .foregroundStyle(Color.bibleInsightText)

                subtitleText
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
            }
            .padding(.bottom, Theme.Spacing.md)
        }
    }

    // MARK: - View Mode Toggle

    private var viewModeToggle: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                modeButton(mode)
            }
            Spacer()
        }
    }

    private func modeButton(_ mode: ViewMode) -> some View {
        let isSelected = viewMode == mode
        let count = countForMode(mode)

        return Button {
            HapticService.shared.lightTap()
            withAnimation(Theme.Animation.settle) {
                viewMode = mode
            }
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: mode.icon)
                    .font(Typography.Icon.xxs.weight(.medium))
                Text(mode.rawValue)
                    // swiftlint:disable:next hardcoded_font_system
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                // Show count on both options for consistency
                if count > 0 {
                    Text("(\(count))")
                        // swiftlint:disable:next hardcoded_font_system
                        .font(Typography.Icon.xxxs)
                        .foregroundStyle(isSelected ? Color.bibleInsightCardBackground.opacity(Theme.Opacity.overlay) : Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                }
            }
            .foregroundStyle(isSelected ? Color.bibleInsightCardBackground : Color.bibleInsightText.opacity(Theme.Opacity.strong))
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs + 2)
            .background(
                Capsule()
                    .fill(isSelected ? Color.feedbackWarning : Color.bibleInsightText.opacity(Theme.Opacity.faint / 2))
            )
        }
        .buttonStyle(.plain)
    }

    private func countForMode(_ mode: ViewMode) -> Int {
        switch mode {
        case .list: return connections.count
        case .groups:
            // Count unique groups (OT + NT sections that have content)
            var count = 0
            if !otConnections.isEmpty { count += 1 }
            if !ntConnections.isEmpty { count += 1 }
            return count
        }
    }

    // MARK: - List View

    private var listView: some View {
        LazyVStack(spacing: Theme.Spacing.md) {
            ForEach(connections) { connection in
                connectionCard(connection)
            }
        }
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Groups View

    private var groupsView: some View {
        LazyVStack(spacing: Theme.Spacing.xl) {
            // OT Section
            if !otConnections.isEmpty {
                groupSection(title: "Old Testament", connections: otConnections, color: .theologyGreen)
            }

            // NT Section
            if !ntConnections.isEmpty {
                groupSection(title: "New Testament", connections: ntConnections, color: .greekBlue)
            }
        }
        .padding(Theme.Spacing.lg)
    }

    private func groupSection(title: String, connections: [BibleInsight], color: Color) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section header
            HStack(spacing: Theme.Spacing.sm) {
                Circle()
                    .fill(color)
                    .frame(width: Theme.Spacing.sm, height: Theme.Spacing.sm)

                Text(title)
                    .font(Typography.Icon.xs.weight(.semibold))
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.strong))
                    .textCase(.uppercase)
                    // swiftlint:disable:next hardcoded_tracking
                    .tracking(0.5)

                Text("(\(connections.count))")
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))

                Spacer()
            }

            // Connection cards
            ForEach(connections) { connection in
                connectionCard(connection)
            }
        }
    }

    // MARK: - Connection Card

    private func connectionCard(_ connection: BibleInsight) -> some View {
        let targetPassage = connection.sources
            .first { $0.type == .crossReference }?
            .reference

        return Button {
            HapticService.shared.lightTap()
            // Show connection detail instead of navigating directly
            selectedConnection = connection
        } label: {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                // Connection icon
                Image(systemName: "link")
                    .font(Typography.Icon.xxs.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: Theme.Spacing.xl, height: Theme.Spacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.input - 1)
                            .fill(Color.feedbackWarning)
                    )

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    // Title
                    Text(connection.title)
                        .font(Typography.Command.caption.weight(.semibold))
                        .foregroundStyle(Color.bibleInsightText)
                        .lineLimit(1)

                    // Target passage
                    if let passage = targetPassage {
                        Text(passage)
                            // swiftlint:disable:next hardcoded_font_system
                            .font(Typography.Command.meta)
                            .foregroundStyle(Color.feedbackWarning)
                    }

                    // Description
                    Text(connection.content)
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(.system(size: 12, weight: .regular, design: .serif))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.overlay))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Icon.xxs.weight(.semibold))
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.medium))
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color.bibleInsightText.opacity(Theme.Opacity.faint / 2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    // swiftlint:disable:next hardcoded_line_width
                    .stroke(Color.feedbackWarning.opacity(Theme.Opacity.subtle), lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "map")
                .font(Typography.Icon.xxl)
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.lightMedium))

            Text("No connections mapped yet")
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, Theme.Spacing.xxl + Theme.Spacing.xxl)
    }

    // MARK: - Helpers

    private func extractBookName(from reference: String) -> String {
        let result = ReferenceParser.parse(reference)
        if case .success(let parsed) = result {
            return parsed.book.name
        }
        // Fallback: extract first word(s) before number
        let pattern = #"^((?:\d\s*)?[a-zA-Z]+(?:\s+[a-zA-Z]+)*)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: reference, range: NSRange(reference.startIndex..., in: reference)),
           let range = Range(match.range(at: 1), in: reference) {
            return String(reference[range])
        }
        return "Unknown"
    }
}

// MARK: - Connection Detail View
// Shows both verses side-by-side with connection rationale before navigating

struct ConnectionDetailView: View {
    let sourceVerse: Verse
    let connection: BibleInsight
    let onDismiss: () -> Void
    var onDismissAll: (() -> Void)?
    var onNavigateToReference: ((String) -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State
    @State private var targetVerseText: String?
    @State private var isLoading = true

    // MARK: - Computed Properties

    private var targetReference: String? {
        connection.sources
            .first { $0.type == .crossReference }?
            .reference
    }

    private var sourceReference: String {
        guard let book = Book.find(byId: sourceVerse.bookId) else {
            return "Verse \(sourceVerse.verse)"
        }
        return "\(book.name) \(sourceVerse.chapter):\(sourceVerse.verse)"
    }

    private var connectionType: String {
        // Determine connection type from sources or content
        if connection.content.lowercased().contains("echo") ||
           connection.content.lowercased().contains("allusion") {
            return "Echo / Allusion"
        } else if connection.content.lowercased().contains("fulfil") ||
                  connection.content.lowercased().contains("prophec") {
            return "Prophecy Fulfillment"
        } else if connection.content.lowercased().contains("parallel") {
            return "Parallel Passage"
        } else if connection.content.lowercased().contains("contrast") {
            return "Contrast"
        } else {
            return "Thematic Connection"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Rectangle()
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.faint))
                // swiftlint:disable:next hardcoded_frame
                .frame(height: 0.5)

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    // Source verse (current reading location)
                    verseCard(
                        reference: sourceReference,
                        text: sourceVerse.text,
                        label: "Current Passage",
                        color: .theologyGreen
                    )

                    // Connection indicator
                    connectionIndicator

                    // Target verse (cross-reference)
                    if let ref = targetReference {
                        verseCard(
                            reference: ref,
                            text: targetVerseText,
                            label: "Connected Passage",
                            color: .connectionAmber,
                            isLoading: isLoading
                        )
                    }

                    // Rationale
                    rationaleSection
                }
                .padding(Theme.Spacing.lg)
            }

            // Action button
            if targetReference != nil {
                actionButton
            }
        }
        .background(Color.bibleInsightCardBackground)
        .task {
            await loadTargetVerse()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            // Top bar with Back and Done buttons
            HStack {
                // Back button
                Button {
                    HapticService.shared.lightTap()
                    onDismiss()
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(Typography.Icon.xs.weight(.semibold))
                        Text("Map")
                            .font(Typography.Command.caption.weight(.medium))
                    }
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.strong))
                }
                .buttonStyle(.plain)

                Spacer()

                // Done button dismisses entire sheet stack
                Button {
                    HapticService.shared.lightTap()
                    if let dismissAll = onDismissAll {
                        dismissAll()
                    } else {
                        onDismiss()
                    }
                } label: {
                    Text("Done")
                        .font(Typography.Command.body.weight(.medium))
                        .foregroundStyle(Color.feedbackWarning)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.sm)

            // Title area: "John 1:1 ↔ Genesis 1:1"
            VStack(spacing: Theme.Spacing.xs) {
                // References with bidirectional arrow
                HStack(spacing: Theme.Spacing.sm) {
                    Text(sourceReference)
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(Color.bibleOlive)

                    Image(systemName: "arrow.left.arrow.right")
                        .font(Typography.Icon.xs.weight(.medium))
                        .foregroundStyle(Color.feedbackWarning)

                    if let ref = targetReference {
                        Text(ref)
                            // swiftlint:disable:next hardcoded_font_custom
                            .font(.system(size: 16, weight: .medium, design: .serif))
                            .foregroundStyle(Color.feedbackWarning)
                    }
                }

                // Connection type as subtitle
                Text(connectionType)
                    .font(Typography.Icon.xs)
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
            }
            .padding(.bottom, Theme.Spacing.md)
        }
    }

    // MARK: - Verse Card

    private func verseCard(
        reference: String,
        text: String?,
        label: String,
        color: Color,
        isLoading: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Label
            Text(label)
                // swiftlint:disable:next hardcoded_font_system
                .font(Typography.Icon.xxs.weight(.semibold))
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                .textCase(.uppercase)
                // swiftlint:disable:next hardcoded_tracking
                .tracking(0.5)

            // Card
            VStack(alignment: .leading, spacing: Theme.Spacing.md - 2) {
                // Reference
                HStack(spacing: Theme.Spacing.sm) {
                    Circle()
                        .fill(color)
                        .frame(width: Theme.Spacing.sm, height: Theme.Spacing.sm)

                    Text(reference)
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundStyle(Color.bibleInsightText)
                }

                // Text
                if isLoading {
                    HStack(spacing: Theme.Spacing.sm) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading verse...")
                            // swiftlint:disable:next hardcoded_font_custom
                            .font(.system(size: 14, weight: .regular, design: .serif))
                            .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
                    }
                } else if let verseText = text {
                    Text(verseText)
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.high))
                        // swiftlint:disable:next hardcoded_line_spacing
                        .lineSpacing(4)
                        .italic()
                } else {
                    Text("Verse text not available")
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
                }
            }
            .padding(Theme.Spacing.md + 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color.bibleInsightText.opacity(Theme.Opacity.faint / 2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(color.opacity(Theme.Opacity.light), lineWidth: Theme.Stroke.hairline)
            )
        }
    }

    // MARK: - Connection Indicator (Simplified Divider)

    private var connectionIndicator: some View {
        HStack(spacing: Theme.Spacing.md) {
            Rectangle()
                .fill(Color.feedbackWarning.opacity(Theme.Opacity.lightMedium))
                .frame(height: Theme.Stroke.hairline)

            Image(systemName: "link")
                .font(Typography.Icon.xxs.weight(.medium))
                .foregroundStyle(Color.feedbackWarning.opacity(Theme.Opacity.disabled))

            Rectangle()
                .fill(Color.feedbackWarning.opacity(Theme.Opacity.lightMedium))
                .frame(height: Theme.Stroke.hairline)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    // MARK: - Rationale Section

    /// Extract a key idea (thesis) from the connection title
    private var keyIdea: String {
        // Use the title as the key idea - it's typically a concise summary
        connection.title
    }

    /// Sources count for this connection
    private var sourceCount: Int {
        connection.sources.count
    }

    private var rationaleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Label
            Text("Why Connected")
                // swiftlint:disable:next hardcoded_font_system
                .font(Typography.Icon.xxs.weight(.semibold))
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                .textCase(.uppercase)
                // swiftlint:disable:next hardcoded_tracking
                .tracking(0.5)

            // Key idea (thesis line) - scannable summary
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                Text("Key idea:")
                    .font(Typography.Icon.xs.weight(.semibold))
                    .foregroundStyle(Color.feedbackWarning)

                Text(keyIdea)
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.bibleInsightText)
            }

            // Full rationale (optional depth)
            Text(connection.content)
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.overlay + 0.05))
                // swiftlint:disable:next hardcoded_line_spacing
                .lineSpacing(3)

            // Sources row (future-proof slot)
            if sourceCount > 0 {
                sourcesRow
            }
        }
        .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - Sources Row

    @State private var showSources = false

    private var sourcesRow: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs + 2) {
            Button {
                HapticService.shared.lightTap()
                withAnimation(Theme.Animation.settle) {
                    showSources.toggle()
                }
            } label: {
                HStack(spacing: Theme.Spacing.xs + 2) {
                    Text("Sources (\(sourceCount))")
                        // swiftlint:disable:next hardcoded_font_system
                        .font(Typography.Icon.xxs.weight(.medium))

                    Image(systemName: showSources ? "chevron.down" : "chevron.right")
                        .font(Typography.Icon.xxs.weight(.semibold))
                }
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            }
            .buttonStyle(.plain)

            if showSources {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    ForEach(connection.sources, id: \.reference) { source in
                        HStack(alignment: .top, spacing: Theme.Spacing.xs + 2) {
                            sourceIcon(for: source.type)
                                // swiftlint:disable:next hardcoded_font_system
                                .font(Typography.Icon.xxxs)
                                .foregroundStyle(sourceColor(for: source.type))
                                .frame(width: Theme.Spacing.md)

                            // swiftlint:disable:next hardcoded_stack_spacing
                            VStack(alignment: .leading, spacing: 1) {  // Tight ref/verse spacing
                                Text(source.reference)
                                    // swiftlint:disable:next hardcoded_font_system
                                    .font(Typography.Icon.xxs.weight(.medium))
                                    .foregroundStyle(Color.bibleInsightText)

                                if let description = source.description {
                                    Text(description)
                                        .font(Typography.Icon.xxs)
                                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.strong))
                                }
                            }
                        }
                    }
                }
                .padding(.leading, Theme.Spacing.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, Theme.Spacing.xs)
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

    // MARK: - Action Button

    private var actionButton: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.faint))
                // swiftlint:disable:next hardcoded_frame
                .frame(height: 0.5)

            // Primary CTA: Open connected passage
            Button {
                HapticService.shared.mediumTap()
                if let reference = targetReference {
                    onNavigateToReference?(reference)
                }
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(Typography.Icon.sm)
                    if let ref = targetReference {
                        Text("Open \(ref)")
                            .font(Typography.Icon.sm.weight(.medium))
                    }
                }
                .foregroundStyle(Color.feedbackWarning)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
            }
            .buttonStyle(.plain)

            // Secondary CTA: Open source passage (neutral label)
            Button {
                HapticService.shared.lightTap()
                onNavigateToReference?(sourceReference)
            } label: {
                HStack(spacing: Theme.Spacing.xs + 2) {
                    Image(systemName: "book.pages")
                        // swiftlint:disable:next hardcoded_font_system
                        .font(Typography.Command.meta)
                    Text("Open \(sourceReference)")
                        .font(Typography.Icon.xs.weight(.medium))
                }
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.heavy))
                .padding(.vertical, Theme.Spacing.sm)
            }
            .buttonStyle(.plain)
        }
        .background(Color.bibleInsightCardBackground)
    }

    // MARK: - Load Target Verse

    private func loadTargetVerse() async {
        guard let reference = targetReference else {
            isLoading = false
            return
        }

        // Simulate loading delay
        try? await Task.sleep(nanoseconds: 200_000_000)

        let result = ReferenceParser.parse(reference)
        if case .success(let parsed) = result {
            let verseNum = parsed.verseStart ?? 1
            let range = VerseRange(
                bookId: parsed.book.id,
                chapter: parsed.chapter,
                verseStart: verseNum,
                verseEnd: parsed.verseEnd ?? verseNum
            )

            do {
                let verses = try await BibleService.shared.getVerses(range: range)
                if let foundVerse = verses.first {
                    targetVerseText = foundVerse.text
                }
            } catch {
                targetVerseText = nil
            }
        }

        isLoading = false
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

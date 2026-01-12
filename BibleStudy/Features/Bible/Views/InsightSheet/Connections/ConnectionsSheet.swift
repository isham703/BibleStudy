import SwiftUI

// MARK: - Connections Sheet (Stacked)
// Separate surface for exploring cross-references as a graph
// Opens from InsightSheet footer, not inline
// Designed for scale: filters, caps, grouping

struct ConnectionsSheet: View {
    let verse: Verse
    let connections: [BibleInsight]
    let onDismiss: () -> Void         // Back to InsightSheet

    // MARK: - Environment
    @Environment(\.insightSheetState) private var sheetState

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
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle))
                .frame(height: 0.5)

            // Filter tabs (if more than a few connections)
            if connections.count > 3 {
                filterTabs
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.md)

                Rectangle()
                    .fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle / 2))
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
                onDismiss: { showChapterMap = false }
            )
            .environment(\.insightSheetState, sheetState)
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
                HStack(spacing: Theme.Spacing.xxs) {
                    Image(systemName: "chevron.left")
                        .font(Typography.Icon.xs.weight(.semibold))
                    Text("Back")
                        .font(Typography.Command.caption.weight(.medium))
                }
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
            }
            .buttonStyle(.plain)

            Spacer()

            // Title
            // swiftlint:disable:next hardcoded_stack_spacing
            VStack(spacing: 1) {  // Tight title/subtitle spacing
                Text("Connections")
                    .font(Typography.Scripture.footnote.weight(.medium))
                    .foregroundStyle(Color.bibleInsightText)

                Text("\(connections.count) passage\(connections.count == 1 ? "" : "s")")
                    .font(Typography.Icon.xxs)
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
            }

            Spacer()

            // Close button (dismisses entire sheet stack)
            Button {
                HapticService.shared.lightTap()
                sheetState?.dismissAll()
            } label: {
                Image(systemName: "xmark")
                    .font(Typography.Icon.xxs.weight(.medium))
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                    .padding(Theme.Spacing.xs)
                    .background(Circle().fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle / 2)))
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
            HStack(spacing: Theme.Spacing.xxs) {
                Text(filter.rawValue)
                    .font(Typography.Icon.xxs.weight(isSelected ? .semibold : .medium))

                if count > 0 && filter != .all {
                    Text("\(count)")
                        .font(Typography.Icon.xxxs)
                        .foregroundStyle(isSelected ? Color.bibleInsightCardBackground.opacity(Theme.Opacity.overlay) : Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                }
            }
            .foregroundStyle(isSelected ? Color.bibleInsightCardBackground : Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? Color("FeedbackWarning") : Color.bibleInsightText.opacity(Theme.Opacity.subtle / 2))
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
            .foregroundStyle(Color("FeedbackWarning"))
            .padding(.vertical, Theme.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(Color("FeedbackWarning").opacity(Theme.Opacity.subtle))
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
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text("Open Chapter Map")
                        .font(Typography.Command.caption.weight(.medium))
                    Text("See all connections visually")
                        .font(Typography.Icon.xxs)
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(Typography.Icon.xxs.weight(.semibold))
            }
            .foregroundStyle(Color("FeedbackWarning"))
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color("FeedbackWarning").opacity(Theme.Opacity.subtle))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(Color("FeedbackWarning").opacity(Theme.Opacity.selectionBackground), lineWidth: Theme.Stroke.hairline)
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
                    .font(Typography.Icon.xxxs.weight(.semibold))
            }
            .foregroundStyle(Color("FeedbackWarning"))
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(Color("FeedbackWarning").opacity(Theme.Opacity.subtle))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "arrow.triangle.branch")
                .font(Typography.Icon.xxl)
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.selectionBackground))

            Text(selectedFilter == .all ? "No connections yet" : "No \(selectedFilter.rawValue) connections")
                .font(Typography.Scripture.footnote)
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
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
                sheetState?.navigateToReference(reference)
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
                                .fill(Color("FeedbackWarning"))
                        )

                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        // Connection title
                        Text(connection.title)
                            .font(Typography.Command.caption.weight(.semibold))
                            .foregroundStyle(Color.bibleInsightText)

                        // Target passage (if available)
                        if let passage = targetPassage {
                            Text(passage)
                                .font(Typography.Icon.xxs)
                                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
                        }

                        // Connection type badge
                        Text(connectionType(for: connection))
                            .font(Typography.Icon.xxxs)
                            .foregroundStyle(Color("FeedbackWarning"))
                            .textCase(.uppercase)
                            .tracking(Typography.Editorial.labelTracking)
                    }

                    Spacer()

                    // Navigation chevron (consistent with Sources)
                    Image(systemName: "chevron.right")
                        .font(Typography.Icon.xs.weight(.semibold))
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.focusStroke))
                }

                // 1-line rationale
                Text(connection.content)
                    .font(Typography.Scripture.footnote)
                    .lineSpacing(Typography.Command.metaLineSpacing)
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
                    .lineLimit(2)
                    .padding(.leading, Theme.Spacing.xxl + 4)  // Align with title
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle / 2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(Color("FeedbackWarning").opacity(Theme.Opacity.subtle), lineWidth: Theme.Stroke.hairline)
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

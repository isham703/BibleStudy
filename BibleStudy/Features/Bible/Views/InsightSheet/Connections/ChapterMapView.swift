import SwiftUI

// MARK: - Chapter Map View
// Visual representation of all connections for a chapter

struct ChapterMapView: View {
    let verse: Verse
    let connections: [BibleInsight]
    let onDismiss: () -> Void

    // MARK: - Environment
    @Environment(\.insightSheetState) private var sheetState

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
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle))
                .frame(height: 0.5)

            // View mode toggle
            viewModeToggle
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md - 2)

            Rectangle()
                .fill(Color.bibleInsightText.opacity(Theme.Opacity.subtle / 2))
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
                onDismiss: { selectedConnection = nil }
            )
            .environment(\.insightSheetState, sheetState)
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
                    sheetState?.dismissAll()
                } label: {
                    Text("Done")
                        .font(Typography.Command.body.weight(.medium))
                        .foregroundStyle(Color("FeedbackWarning"))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.sm)

            // Title area
            VStack(spacing: Theme.Spacing.xs) {
                Text("Chapter Map")
                    .font(Typography.Scripture.heading.weight(.medium))
                    .foregroundStyle(Color.bibleInsightText)

                subtitleText
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
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
                    .font(Typography.Icon.xxs.weight(isSelected ? .semibold : .medium))
                // Show count on both options for consistency
                if count > 0 {
                    Text("(\(count))")
                        .font(Typography.Icon.xxxs)
                        .foregroundStyle(isSelected ? Color.bibleInsightCardBackground.opacity(Theme.Opacity.overlay) : Color.bibleInsightText.opacity(Theme.Opacity.disabled))
                }
            }
            .foregroundStyle(isSelected ? Color.bibleInsightCardBackground : Color.bibleInsightText.opacity(Theme.Opacity.pressed))
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs + 2)
            .background(
                Capsule()
                    .fill(isSelected ? Color("FeedbackWarning") : Color.bibleInsightText.opacity(Theme.Opacity.subtle / 2))
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
                groupSection(title: "Old Testament", connections: otConnections, color: Color("FeedbackSuccess"))
            }

            // NT Section
            if !ntConnections.isEmpty {
                groupSection(title: "New Testament", connections: ntConnections, color: Color("FeedbackInfo"))
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
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.pressed))
                    .textCase(.uppercase)
                    .tracking(Typography.Editorial.labelTracking)

                Text("(\(connections.count))")
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
                            .fill(Color("FeedbackWarning"))
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
                            .font(Typography.Command.meta)
                            .foregroundStyle(Color("FeedbackWarning"))
                    }

                    // Description
                    Text(connection.content)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Icon.xxs.weight(.semibold))
                    .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.focusStroke))
            }
            .padding(Theme.Spacing.md)
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "map")
                .font(Typography.Icon.xxl)
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.selectionBackground))

            Text("No connections mapped yet")
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color.bibleInsightText.opacity(Theme.Opacity.textSecondary))
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

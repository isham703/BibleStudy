import SwiftUI

// MARK: - Highlight Library View
// Filterable collection of all user highlights with navigation to source

struct HighlightLibraryView: View {
    @State private var viewModel = HighlightLibraryViewModel()
    @State private var showSortOptions = false
    @State private var showGroupOptions = false
    @State private var navigateToVerse: VerseRange?

    @Environment(\.colorScheme) private var colorScheme

    var onNavigate: ((VerseRange) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isEmpty {
                emptyState
            } else {
                // Filter Bar
                filterBar

                // Highlight List
                highlightList
            }
        }
        .background(Color.appBackground)
        .sheet(isPresented: $showSortOptions) {
            SortOptionsSheet(
                sortOption: $viewModel.sortOption,
                groupOption: $viewModel.groupOption
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView.noHighlights
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Search field
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.tertiaryText)

                TextField("Search highlights...", text: $viewModel.searchQuery)
                    .font(Typography.Command.body)

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.tertiaryText)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))

            // Color filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    // All chip
                    HighlightFilterChip(
                        label: "All",
                        count: viewModel.highlightStats.total,
                        isSelected: viewModel.selectedColorFilter == nil,
                        color: nil
                    ) {
                        viewModel.selectedColorFilter = nil
                    }

                    // Color chips
                    ForEach(HighlightColor.allCases, id: \.self) { color in
                        HighlightFilterChip(
                            label: color.displayName,
                            count: viewModel.highlightStats.byColor[color] ?? 0,
                            isSelected: viewModel.selectedColorFilter == color,
                            color: color
                        ) {
                            viewModel.toggleColorFilter(color)
                        }
                    }

                    Divider()
                        .frame(height: 24)
                        .padding(.horizontal, Theme.Spacing.xs)

                    // Sort/Group button
                    Button {
                        showSortOptions = true
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Sort")
                        }
                        .font(Typography.Command.caption)
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(
                            Capsule()
                                .stroke(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.medium), lineWidth: Theme.Stroke.hairline)
                        )
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }

            // Category filter chips (if any categories in use)
            if hasUsedCategories {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(usedCategories, id: \.self) { category in
                            CategoryHighlightFilterChip(
                                category: category,
                                count: viewModel.highlightStats.byCategory[category] ?? 0,
                                isSelected: viewModel.selectedCategoryFilter == category
                            ) {
                                viewModel.toggleCategoryFilter(category)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
            }

            // Active filters indicator
            if viewModel.hasActiveFilters {
                HStack {
                    Text("\(viewModel.filteredHighlights.count) of \(viewModel.allHighlights.count) highlights")
                        .font(Typography.Command.caption.monospacedDigit())
                        .foregroundStyle(Color.secondaryText)

                    Spacer()

                    Button("Clear Filters") {
                        viewModel.clearFilters()
                    }
                    .font(Typography.Command.caption)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
        .background(Color.elevatedBackground)
    }

    private var hasUsedCategories: Bool {
        viewModel.highlightStats.byCategory.values.contains { $0 > 0 && viewModel.highlightStats.byCategory.keys.contains(where: { $0 != .none }) }
    }

    private var usedCategories: [HighlightCategory] {
        HighlightCategory.allCases.filter { category in
            category != .none && (viewModel.highlightStats.byCategory[category] ?? 0) > 0
        }
    }

    // MARK: - Highlight List

    private var highlightList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md, pinnedViews: .sectionHeaders) {
                ForEach(viewModel.groupedHighlights) { group in
                    Section {
                        ForEach(group.highlights, id: \.id) { highlight in
                            HighlightListCard(highlight: highlight) {
                                onNavigate?(highlight.range)
                            } onDelete: {
                                Task {
                                    await viewModel.deleteHighlight(highlight)
                                }
                            }
                        }
                    } header: {
                        if let title = group.title {
                            GroupHeader(
                                title: title,
                                color: group.color,
                                category: group.category,
                                count: group.highlights.count
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Filter Chip

struct HighlightFilterChip: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let color: HighlightColor?
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                if let color = color {
                    Circle()
                        .fill(color.color)
                        .frame(width: 8 + 2, height: 8 + 2)
                }
                Text(label)
                    .font(Typography.Command.caption)
                if count > 0 {
                    Text("\(count)")
                        .font(Typography.Command.meta.monospacedDigit())
                        .foregroundStyle(isSelected ? Color.primaryText : Color.tertiaryText)
                }
            }
            .foregroundStyle(isSelected ? Color.primaryText : Color.secondaryText)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? (color?.color.opacity(Theme.Opacity.lightMedium) ?? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium)) : Color.surfaceBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? (color?.color ?? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))) : Color.cardBorder, lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Filter Chip

struct CategoryHighlightFilterChip: View {
    let category: HighlightCategory
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                categoryIcon
                Text(category.displayName)
                    .font(Typography.Command.caption)
                Text("\(count)")
                    .font(Typography.Command.meta.monospacedDigit())
                    .foregroundStyle(isSelected ? Color.primaryText : Color.tertiaryText)
            }
            .foregroundStyle(isSelected ? category.suggestedColor.color : Color.secondaryText)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? category.suggestedColor.color.opacity(Theme.Opacity.light) : Color.surfaceBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? category.suggestedColor.color.opacity(Theme.Opacity.heavy) : Color.cardBorder, lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var categoryIcon: some View {
        if category.usesStreamlineIcon {
            Image(category.icon)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
        } else {
            Image(systemName: category.icon)
                .font(Typography.Command.meta)
        }
    }
}

// MARK: - Group Header

struct GroupHeader: View {
    let title: String
    var color: HighlightColor?
    var category: HighlightCategory?
    let count: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if let color = color {
                Circle()
                    .fill(color.color)
                    .frame(width: 12, height: 12)
            } else if let category = category {
                categoryIcon(for: category)
                    .foregroundStyle(category.suggestedColor.color)
            }

            Text(title)
                .font(Typography.Command.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primaryText)

            Text("(\(count))")
                .font(Typography.Command.caption.monospacedDigit())
                .foregroundStyle(Color.tertiaryText)

            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xs)
        .padding(.horizontal, Theme.Spacing.sm)
        .background(Color.appBackground)
    }

    @ViewBuilder
    private func categoryIcon(for category: HighlightCategory) -> some View {
        if category.usesStreamlineIcon {
            Image(category.icon)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 14, height: 14)
        } else {
            Image(systemName: category.icon)
                .font(Typography.Command.caption)
        }
    }
}

// MARK: - Highlight Card

struct HighlightListCard: View {
    let highlight: Highlight
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false
    @Environment(BibleService.self) private var bibleService

    @State private var verseText: String = ""

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                // Color indicator
                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                    .fill(highlight.color.color)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    // Reference and category
                    HStack {
                        Text(highlight.reference)
                            .font(Typography.Command.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.primaryText)

                        if highlight.category != .none {
                            HStack(spacing: 2) {
                                categoryIcon(for: highlight.category)
                                Text(highlight.category.displayName)
                                    .font(Typography.Command.meta)
                            }
                            .foregroundStyle(highlight.category.suggestedColor.color)
                            .padding(.horizontal, Theme.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(highlight.category.suggestedColor.color.opacity(Theme.Opacity.subtle))
                            )
                        }

                        Spacer()

                        // Delete button
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(Typography.Command.caption)
                                .foregroundStyle(Color.tertiaryText)
                        }
                    }

                    // Verse preview
                    if !verseText.isEmpty {
                        Text(verseText)
                            .font(Typography.Scripture.footnote)
                            .foregroundStyle(Color.secondaryText)
                            .lineLimit(2)
                    }

                    // Date
                    Text(highlight.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.elevatedBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color.cardBorder, lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
        .task {
            await loadVerseText()
        }
        .confirmationDialog(
            "Delete Highlight",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this highlight?")
        }
    }

    private func loadVerseText() async {
        do {
            let verses = try await bibleService.getVerses(range: highlight.range)
            verseText = verses.map { $0.text }.joined(separator: " ")
        } catch {
            verseText = ""
        }
    }

    @ViewBuilder
    private func categoryIcon(for category: HighlightCategory) -> some View {
        if category.usesStreamlineIcon {
            Image(category.icon)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
        } else {
            Image(systemName: category.icon)
                .font(Typography.Command.meta)
        }
    }
}

// MARK: - Sort Options Sheet

struct SortOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var sortOption: SortOption
    @Binding var groupOption: GroupOption

    var body: some View {
        NavigationStack {
            List {
                Section("Sort By") {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            sortOption = option
                        } label: {
                            HStack {
                                Image(systemName: option.icon)
                                    .frame(width: 24)
                                Text(option.rawValue)
                                Spacer()
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                                }
                            }
                            .foregroundStyle(Color.primaryText)
                        }
                    }
                }

                Section("Group By") {
                    ForEach(GroupOption.allCases, id: \.self) { option in
                        Button {
                            groupOption = option
                        } label: {
                            HStack {
                                Image(systemName: option.icon)
                                    .frame(width: 24)
                                Text(option.rawValue)
                                Spacer()
                                if groupOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                                }
                            }
                            .foregroundStyle(Color.primaryText)
                        }
                    }
                }
            }
            .navigationTitle("Sort & Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HighlightLibraryView()
        .environment(BibleService.shared)
}

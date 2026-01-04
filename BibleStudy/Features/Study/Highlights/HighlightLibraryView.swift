import SwiftUI

// MARK: - Highlight Library View
// Filterable collection of all user highlights with navigation to source

struct HighlightLibraryView: View {
    @State private var viewModel = HighlightLibraryViewModel()
    @State private var showSortOptions = false
    @State private var showGroupOptions = false
    @State private var navigateToVerse: VerseRange?

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
        VStack(spacing: AppTheme.Spacing.sm) {
            // Search field
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.tertiaryText)

                TextField("Search highlights...", text: $viewModel.searchQuery)
                    .font(Typography.UI.body)

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.tertiaryText)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))

            // Color filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
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
                        .padding(.horizontal, AppTheme.Spacing.xs)

                    // Sort/Group button
                    Button {
                        showSortOptions = true
                    } label: {
                        HStack(spacing: AppTheme.Spacing.xxs) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Sort")
                        }
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.accentBlue)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(
                            Capsule()
                                .stroke(Color.accentBlue.opacity(AppTheme.Opacity.medium), lineWidth: AppTheme.Border.thin)
                        )
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }

            // Category filter chips (if any categories in use)
            if hasUsedCategories {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.sm) {
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
                    .padding(.horizontal, AppTheme.Spacing.md)
                }
            }

            // Active filters indicator
            if viewModel.hasActiveFilters {
                HStack {
                    Text("\(viewModel.filteredHighlights.count) of \(viewModel.allHighlights.count) highlights")
                        .font(Typography.UI.caption1.monospacedDigit())
                        .foregroundStyle(Color.secondaryText)

                    Spacer()

                    Button("Clear Filters") {
                        viewModel.clearFilters()
                    }
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.accentBlue)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
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
            LazyVStack(spacing: AppTheme.Spacing.md, pinnedViews: .sectionHeaders) {
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

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xxs) {
                if let color = color {
                    Circle()
                        .fill(color.color)
                        .frame(width: AppTheme.ComponentSize.indicator + 2, height: AppTheme.ComponentSize.indicator + 2)
                }
                Text(label)
                    .font(Typography.UI.caption1)
                if count > 0 {
                    Text("\(count)")
                        .font(Typography.UI.caption2.monospacedDigit())
                        .foregroundStyle(isSelected ? Color.primaryText : Color.tertiaryText)
                }
            }
            .foregroundStyle(isSelected ? Color.primaryText : Color.secondaryText)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? (color?.color.opacity(AppTheme.Opacity.lightMedium) ?? Color.accentGold.opacity(AppTheme.Opacity.lightMedium)) : Color.surfaceBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? (color?.color ?? Color.accentGold) : Color.cardBorder, lineWidth: AppTheme.Border.thin)
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
            HStack(spacing: AppTheme.Spacing.xxs) {
                categoryIcon
                Text(category.displayName)
                    .font(Typography.UI.caption1)
                Text("\(count)")
                    .font(Typography.UI.caption2.monospacedDigit())
                    .foregroundStyle(isSelected ? Color.primaryText : Color.tertiaryText)
            }
            .foregroundStyle(isSelected ? category.suggestedColor.color : Color.secondaryText)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? category.suggestedColor.color.opacity(AppTheme.Opacity.light) : Color.surfaceBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? category.suggestedColor.color.opacity(AppTheme.Opacity.heavy) : Color.cardBorder, lineWidth: AppTheme.Border.thin)
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
                .font(Typography.UI.caption2)
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
        HStack(spacing: AppTheme.Spacing.sm) {
            if let color = color {
                Circle()
                    .fill(color.color)
                    .frame(width: 12, height: 12)
            } else if let category = category {
                categoryIcon(for: category)
                    .foregroundStyle(category.suggestedColor.color)
            }

            Text(title)
                .font(Typography.UI.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primaryText)

            Text("(\(count))")
                .font(Typography.UI.caption1.monospacedDigit())
                .foregroundStyle(Color.tertiaryText)

            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .padding(.horizontal, AppTheme.Spacing.sm)
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
                .font(Typography.UI.caption1)
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
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                // Color indicator
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xs)
                    .fill(highlight.color.color)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    // Reference and category
                    HStack {
                        Text(highlight.reference)
                            .font(Typography.UI.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.primaryText)

                        if highlight.category != .none {
                            HStack(spacing: AppTheme.Spacing.xxs) {
                                categoryIcon(for: highlight.category)
                                Text(highlight.category.displayName)
                                    .font(Typography.UI.caption2)
                            }
                            .foregroundStyle(highlight.category.suggestedColor.color)
                            .padding(.horizontal, AppTheme.Spacing.xs)
                            .padding(.vertical, AppTheme.Spacing.xxs)
                            .background(
                                Capsule()
                                    .fill(highlight.category.suggestedColor.color.opacity(AppTheme.Opacity.subtle))
                            )
                        }

                        Spacer()

                        // Delete button
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(Typography.UI.caption1)
                                .foregroundStyle(Color.tertiaryText)
                        }
                    }

                    // Verse preview
                    if !verseText.isEmpty {
                        Text(verseText)
                            .font(Typography.Scripture.body(size: 14))
                            .foregroundStyle(Color.secondaryText)
                            .lineLimit(2)
                    }

                    // Date
                    Text(highlight.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .fill(Color.elevatedBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
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
                .font(Typography.UI.caption2)
        }
    }
}

// MARK: - Sort Options Sheet

struct SortOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
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
                                    .frame(width: AppTheme.IconContainer.small)
                                Text(option.rawValue)
                                Spacer()
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentGold)
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
                                    .frame(width: AppTheme.IconContainer.small)
                                Text(option.rawValue)
                                Spacer()
                                if groupOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentGold)
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

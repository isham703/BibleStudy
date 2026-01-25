import SwiftUI

// MARK: - Highlight Library View
// Hierarchical highlights browser with filter bar, color chips, and grouped list

struct HighlightLibraryView: View {
    @State private var viewModel = HighlightLibraryViewModel()
    @State private var showSortSheet = false
    @State private var appeared = false

    let onNavigate: ((VerseRange) -> Void)?

    init(onNavigate: ((VerseRange) -> Void)? = nil) {
        self.onNavigate = onNavigate
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            filterChips
            sortButton

            if viewModel.isEmpty {
                emptyState
            } else if viewModel.hasActiveFilters && viewModel.filteredHighlights.isEmpty {
                noResultsState
            } else {
                highlightsList
            }
        }
        .background(Color.appBackground)
        .sheet(isPresented: $showSortSheet) {
            sortSheet
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(Typography.Icon.sm)
                .foregroundStyle(Color("TertiaryText"))

            TextField("Search highlights...", text: $viewModel.searchQuery)
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextPrimary"))

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(Typography.Icon.sm)
                        .foregroundStyle(Color("TertiaryText"))
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                // All filter
                HighlightColorFilterChip(
                    color: nil,
                    count: viewModel.highlightStats.total,
                    isSelected: viewModel.selectedColorFilter == nil
                ) {
                    viewModel.selectedColorFilter = nil
                }

                // Color filters
                ForEach(HighlightColor.allCases, id: \.self) { color in
                    HighlightColorFilterChip(
                        color: color,
                        count: viewModel.highlightStats.byColor[color] ?? 0,
                        isSelected: viewModel.selectedColorFilter == color
                    ) {
                        viewModel.selectedColorFilter = color
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
        }
    }

    // MARK: - Sort Button

    private var sortButton: some View {
        HStack {
            Spacer()

            Button {
                showSortSheet = true
            } label: {
                HStack(spacing: Theme.Spacing.xxs) {
                    Image(systemName: viewModel.groupOption.icon)
                        .font(Typography.Icon.xs)
                    Text(viewModel.groupOption.rawValue)
                        .font(Typography.Command.caption)
                    Image(systemName: "chevron.down")
                        .font(Typography.Icon.xxs)
                }
                .foregroundStyle(Color("AppAccentAction"))
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.xs)
    }

    // MARK: - Highlights List

    private var highlightsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.lg, pinnedViews: [.sectionHeaders]) {
                ForEach(viewModel.groupedHighlights) { group in
                    Section {
                        ForEach(Array(group.highlights.enumerated()), id: \.element.id) { index, highlight in
                            highlightCard(highlight, index: index)
                        }
                    } header: {
                        if let title = group.title {
                            sectionHeader(title, color: group.color)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .onAppear {
            // Trigger stagger animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }

    private func sectionHeader(_ title: String, color: HighlightColor?) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            if let color = color {
                Circle()
                    .fill(color.solidColor)
                    .frame(width: 12, height: 12)
            }

            Text(title)
                .font(Typography.Command.subheadline.weight(.semibold))
                .foregroundStyle(Color("AppTextPrimary"))

            Spacer()
        }
        .padding(.vertical, Theme.Spacing.sm)
        .padding(.horizontal, Theme.Spacing.sm)
        .background(Color.appBackground)
    }

    private func highlightCard(_ highlight: Highlight, index: Int) -> some View {
        Button {
            onNavigate?(highlight.range)
        } label: {
            HighlightLibraryCard(
                highlight: highlight,
                onDelete: {
                    Task {
                        await viewModel.deleteHighlight(highlight)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 4)
        .animation(Theme.Animation.stagger(index: index), value: appeared)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "highlighter")
                .font(Typography.Icon.xxl)
                .foregroundStyle(Color("TertiaryText"))

            Text("No Highlights Yet")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color("AppTextPrimary"))

            Text("Long-press any verse to add your first highlight.")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - No Results State

    private var noResultsState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(Typography.Icon.xxl)
                .foregroundStyle(Color("TertiaryText"))

            Text("No Results")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color("AppTextPrimary"))

            Text("Try adjusting your search or filters.")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sort Sheet

    private var sortSheet: some View {
        NavigationStack {
            List {
                Section("Sort By") {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            viewModel.sortOption = option
                        } label: {
                            HStack {
                                Image(systemName: option.icon)
                                    .foregroundStyle(Color("AppAccentAction"))
                                    .frame(width: Theme.Size.iconSizeLarge)

                                Text(option.rawValue)
                                    .foregroundStyle(Color("AppTextPrimary"))

                                Spacer()

                                if viewModel.sortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color("AppAccentAction"))
                                }
                            }
                        }
                    }
                }

                Section("Group By") {
                    ForEach(GroupOption.allCases, id: \.self) { option in
                        Button {
                            viewModel.groupOption = option
                        } label: {
                            HStack {
                                Image(systemName: option.icon)
                                    .foregroundStyle(Color("AppAccentAction"))
                                    .frame(width: Theme.Size.iconSizeLarge)

                                Text(option.rawValue)
                                    .foregroundStyle(Color("AppTextPrimary"))

                                Spacer()

                                if viewModel.groupOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color("AppAccentAction"))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sort & Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showSortSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HighlightLibraryView { range in
            print("Navigate to \(range)")
        }
    }
}

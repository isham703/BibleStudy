import SwiftUI

// MARK: - Collections View
// Displays and manages user's study collections

struct CollectionsView: View {
    @State private var viewModel = CollectionsViewModel()
    @State private var showingNewCollection = false
    @State private var selectedCollection: StudyCollection?

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading collections...")
            } else if viewModel.isEmpty {
                emptyState
            } else if viewModel.isSearchEmpty {
                searchEmptyState
            } else {
                contentList
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search collections")
        .task {
            await viewModel.load()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewCollection = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewCollection) {
            NewCollectionSheet { name, description, type in
                Task {
                    if let collection = await viewModel.createCollection(
                        name: name,
                        description: description,
                        type: type
                    ) {
                        selectedCollection = collection
                    }
                }
            }
        }
        .navigationDestination(item: $selectedCollection) { collection in
            CollectionDetailView(collection: collection)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            EmptyStateView(
                icon: "folder",
                title: "No collections yet",
                message: "Create a collection to organize your verses, highlights, and notes"
            )

            Button {
                showingNewCollection = true
            } label: {
                Label("Create Collection", systemImage: "plus")
                    .font(Typography.UI.bodyBold)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Search Empty State
    private var searchEmptyState: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No results",
            message: "Try a different search term"
        )
    }

    // MARK: - Content List
    private var contentList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.md) {
                // Type Filter
                typeFilterPicker

                // Pinned Collections
                if !viewModel.pinnedCollections.isEmpty && viewModel.searchText.isEmpty {
                    pinnedSection
                }

                // All Collections
                collectionsSection
            }
            .padding(.vertical, AppTheme.Spacing.md)
        }
    }

    // MARK: - Type Filter
    private var typeFilterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                FilterChip(
                    title: "All",
                    isSelected: viewModel.selectedType == nil
                ) {
                    viewModel.selectedType = nil
                }

                ForEach(CollectionType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.displayName,
                        icon: type.icon,
                        isSelected: viewModel.selectedType == type
                    ) {
                        viewModel.selectedType = type
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }

    // MARK: - Pinned Section
    private var pinnedSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "pin.fill")
                    .font(Typography.UI.caption1)
                Text("Pinned")
                    .font(Typography.UI.caption1Bold)
            }
            .foregroundStyle(Color.accentGold)
            .padding(.horizontal, AppTheme.Spacing.md)

            ForEach(viewModel.pinnedCollections) { collection in
                collectionRow(collection)
            }
        }
    }

    // MARK: - Collections Section
    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            if !viewModel.pinnedCollections.isEmpty && viewModel.searchText.isEmpty {
                Text("Collections")
                    .font(Typography.UI.caption1Bold)
                    .foregroundStyle(Color.secondaryText)
                    .padding(.horizontal, AppTheme.Spacing.md)
            }

            ForEach(viewModel.unpinnedCollections) { collection in
                collectionRow(collection)
            }
        }
    }

    // MARK: - Collection Row
    private func collectionRow(_ collection: StudyCollection) -> some View {
        CollectionCard(collection: collection) {
            selectedCollection = collection
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .contextMenu {
            Button {
                Task {
                    await viewModel.togglePin(collection)
                }
            } label: {
                Label(
                    collection.isPinned ? "Unpin" : "Pin",
                    systemImage: collection.isPinned ? "pin.slash" : "pin"
                )
            }

            Divider()

            Button(role: .destructive) {
                Task {
                    await viewModel.deleteCollection(collection)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Collection Card

struct CollectionCard: View {
    let collection: StudyCollection
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(Color(collection.color).opacity(AppTheme.Opacity.light))
                        .frame(width: 44, height: 44)

                    Image(systemName: collection.icon)
                        .font(Typography.UI.title3)
                        .foregroundStyle(Color(collection.color))
                }

                // Content
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    HStack {
                        Text(collection.name)
                            .font(Typography.UI.bodyBold)
                            .foregroundStyle(Color.primaryText)

                        if collection.isPinned {
                            Image(systemName: "pin.fill")
                                .font(Typography.UI.caption2)
                                .foregroundStyle(Color.accentGold)
                        }
                    }

                    if !collection.description.isEmpty {
                        Text(collection.description)
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.secondaryText)
                            .lineLimit(1)
                    }

                    HStack(spacing: AppTheme.Spacing.sm) {
                        Label(collection.type.displayName, systemImage: collection.type.icon)
                        Text("•")
                        Text("\(collection.itemCount) items")
                    }
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.tertiaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.UI.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(Color.elevatedBackground)
            )
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(Typography.UI.caption1)
                }
                Text(title)
                    .font(Typography.UI.caption1Bold)
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentGold : Color.elevatedBackground)
            )
            .foregroundStyle(isSelected ? Color.appBackground : Color.primaryText)
        }
    }
}

// MARK: - New Collection Sheet

struct NewCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var selectedType: CollectionType = .personal

    let onCreate: (String, String, CollectionType) -> Void

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Collection Name", text: $name)
                    TextField("Description (optional)", text: $description)
                }

                Section("Type") {
                    ForEach(CollectionType.allCases, id: \.self) { type in
                        Button {
                            selectedType = type
                        } label: {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundStyle(Color.accentGold)
                                    .frame(width: AppTheme.IconContainer.small)

                                VStack(alignment: .leading) {
                                    Text(type.displayName)
                                        .foregroundStyle(Color.primaryText)
                                    Text(type.description)
                                        .font(Typography.UI.caption1)
                                        .foregroundStyle(Color.secondaryText)
                                }

                                Spacer()

                                if selectedType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentGold)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(name, description, selectedType)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CollectionsView()
            .navigationTitle("Collections")
    }
}

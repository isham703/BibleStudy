import SwiftUI

// MARK: - Collections View
// Displays and manages user's study collections

struct CollectionsView: View {
    @State private var viewModel = CollectionsViewModel()
    @State private var showingNewCollection = false
    @State private var selectedCollection: StudyCollection?

    @Environment(\.colorScheme) private var colorScheme

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
        VStack(spacing: Theme.Spacing.lg) {
            EmptyStateView(
                icon: "folder",
                title: "No collections yet",
                message: "Create a collection to organize your verses, highlights, and notes"
            )

            Button {
                showingNewCollection = true
            } label: {
                Label("Create Collection", systemImage: "plus")
                    .font(Typography.Command.body.weight(.semibold))
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
            LazyVStack(spacing: Theme.Spacing.md) {
                // Type Filter
                typeFilterPicker

                // Pinned Collections
                if !viewModel.pinnedCollections.isEmpty && viewModel.searchText.isEmpty {
                    pinnedSection
                }

                // All Collections
                collectionsSection
            }
            .padding(.vertical, Theme.Spacing.md)
        }
    }

    // MARK: - Type Filter
    private var typeFilterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
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
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    // MARK: - Pinned Section
    private var pinnedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "pin.fill")
                    .font(Typography.Command.caption)
                Text("Pinned")
                    .font(Typography.Command.caption.weight(.semibold))
            }
            .foregroundStyle(Color("AppAccentAction"))
            .padding(.horizontal, Theme.Spacing.md)

            ForEach(viewModel.pinnedCollections) { collection in
                collectionRow(collection)
            }
        }
    }

    // MARK: - Collections Section
    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if !viewModel.pinnedCollections.isEmpty && viewModel.searchText.isEmpty {
                Text("Collections")
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .padding(.horizontal, Theme.Spacing.md)
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
        .padding(.horizontal, Theme.Spacing.md)
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

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .fill(Color(collection.color).opacity(Theme.Opacity.selectionBackground))
                        .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)

                    Image(systemName: collection.icon)
                        .font(Typography.Command.title3)
                        .foregroundStyle(Color(collection.color))
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(collection.name)
                            .font(Typography.Command.body.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))

                        if collection.isPinned {
                            Image(systemName: "pin.fill")
                                .font(Typography.Command.meta)
                                .foregroundStyle(Color("AppAccentAction"))
                        }
                    }

                    if !collection.description.isEmpty {
                        Text(collection.description)
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .lineLimit(1)
                    }

                    HStack(spacing: Theme.Spacing.sm) {
                        Label(collection.type.displayName, systemImage: collection.type.icon)
                        Text("•")
                        Text("\(collection.itemCount) items")
                    }
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("TertiaryText"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color("AppSurface"))
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

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(Typography.Command.caption)
                }
                Text(title)
                    .font(Typography.Command.caption.weight(.semibold))
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? Color("AppAccentAction") : Color("AppSurface"))
            )
            .foregroundStyle(isSelected ? Color.appBackground : Color("AppTextPrimary"))
        }
    }
}

// MARK: - New Collection Sheet

struct NewCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

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
                                    .foregroundStyle(Color("AppAccentAction"))
                                    .frame(width: 24)

                                VStack(alignment: .leading) {
                                    Text(type.displayName)
                                        .foregroundStyle(Color("AppTextPrimary"))
                                    Text(type.description)
                                        .font(Typography.Command.caption)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }

                                Spacer()

                                if selectedType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color("AppAccentAction"))
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

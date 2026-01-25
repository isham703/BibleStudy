import SwiftUI

// MARK: - Sermon Library View
// Lists all saved sermons with search, filtering, and delete functionality

struct SermonLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SermonLibraryViewModel()

    // Sheet/dialog state
    @State private var showGroupSelector = false
    @State private var showDeleteConfirmation = false
    @State private var sermonToDelete: Sermon?
    @State private var showRenameSheet = false
    @State private var sermonToRename: Sermon?
    @State private var renameText = ""

    // Selection mode state
    @State private var isSelectionMode = false
    @State private var selectedSermons: Set<UUID> = []
    @State private var showBatchDeleteConfirmation = false
    @State private var isDeleting = false

    let onSelect: (Sermon) -> Void

    private let pinService = SermonPinService.shared

    var body: some View {
        // @Bindable allows two-way binding to @Observable properties
        @Bindable var vm = viewModel

        NavigationStack {
            VStack(spacing: 0) {
                // Filter and group controls
                if !viewModel.sermons.isEmpty {
                    HStack(spacing: Theme.Spacing.md) {
                        // Status filter chips
                        SermonStatusFilterBar(
                            selectedFilter: $vm.selectedFilter,
                            counts: SermonStatusCounts.from(viewModel.searchFilteredSermons)
                        )

                        // Group button
                        SermonGroupButton(currentGroup: viewModel.selectedGroup) {
                            showGroupSelector = true
                        }
                        .padding(.trailing, Theme.Spacing.lg)
                    }
                    .padding(.vertical, Theme.Spacing.sm)
                }

                // Content
                ZStack {
                    // Background
                    Color("AppBackground")
                        .ignoresSafeArea()

                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.filteredSermons.isEmpty {
                        emptyStateView
                    } else {
                        sermonList
                    }
                }
            }
            .background(Color("AppBackground"))
            .navigationTitle("Your Sermons")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isSelectionMode {
                        Button("Cancel") {
                            exitSelectionMode()
                        }
                        .foregroundStyle(Color("AccentBronze"))
                    } else {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundStyle(Color("AccentBronze"))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSelectionMode {
                        Button("Delete (\(selectedSermons.count))") {
                            showBatchDeleteConfirmation = true
                        }
                        .foregroundStyle(Color("FeedbackError"))
                        .disabled(selectedSermons.isEmpty || isDeleting)
                    } else if !viewModel.filteredSermons.isEmpty {
                        Button("Select") {
                            isSelectionMode = true
                        }
                        .foregroundStyle(Color("AccentBronze"))
                    }
                }
            }
            .searchable(text: $vm.searchText, prompt: "Search sermons")
            .task {
                await viewModel.loadSermons()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        // Single delete confirmation
        .confirmationDialog(
            "Delete \"\(sermonToDelete?.displayTitle ?? "Sermon")\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible,
            presenting: sermonToDelete
        ) { sermon in
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteSermon(sermon)
                }
            }
            Button("Cancel", role: .cancel) {
                sermonToDelete = nil
            }
        } message: { sermon in
            let size = viewModel.formattedStorageSize(for: sermon)
            Text("This cannot be undone and will free \(size) on this device.")
        }
        // Batch delete confirmation
        .confirmationDialog(
            "Delete \(selectedSermons.count) sermons?",
            isPresented: $showBatchDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                Task {
                    isDeleting = true
                    await viewModel.batchDeleteSermons(Array(selectedSermons))
                    isDeleting = false
                    exitSelectionMode()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let size = viewModel.formattedTotalStorageSize(for: Array(selectedSermons))
            Text("This cannot be undone and will free \(size) on this device.")
        }
        // Rename sheet
        .sheet(isPresented: $showRenameSheet) {
            renameSheet
        }
        // Group selector sheet
        .sheet(isPresented: $showGroupSelector) {
            SermonGroupSelector(
                selectedGroup: $vm.selectedGroup,
                selectedSort: $vm.selectedSort,
                groupCounts: SermonGroupingService.shared.groupCounts(for: viewModel.filteredSermons)
            )
        }
    }

    // MARK: - Rename Sheet

    private var renameSheet: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text("RENAME")
                .font(Typography.Editorial.sectionHeader)
                .tracking(Typography.Editorial.sectionTracking)
                .foregroundStyle(Color("TertiaryText"))
                .padding(.top, Theme.Spacing.md)

            TextField("Sermon title", text: $renameText)
                .font(Typography.Scripture.body)
                .padding(Theme.Spacing.md)
                .background(Color("AppSurface"))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
                )

            HStack(spacing: Theme.Spacing.md) {
                Button("Cancel") {
                    showRenameSheet = false
                    sermonToRename = nil
                    renameText = ""
                }
                .font(Typography.Command.body)
                .foregroundStyle(Color("AccentBronze"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(Color("AppSurface"))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
                )

                Button("Save") {
                    if let sermon = sermonToRename {
                        Task {
                            await viewModel.renameSermon(sermon, to: renameText)
                        }
                    }
                    showRenameSheet = false
                    sermonToRename = nil
                    renameText = ""
                }
                .font(Typography.Command.cta)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(Color("AppAccentAction"))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Color("AppBackground"))
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color("AccentBronze")))

            Text("Loading sermons...")
                .font(Typography.Scripture.body)
                .foregroundStyle(Color.appTextSecondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        Group {
            if viewModel.searchText.isEmpty && viewModel.selectedFilter == .all {
                SermonEmptyState.noSermons
            } else if !viewModel.searchText.isEmpty {
                SermonEmptyState.noResults
            } else {
                SermonEmptyState.noMatches(filter: viewModel.selectedFilter.rawValue)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sermon List

    private var sermonList: some View {
        List {
            if viewModel.isUsingCustomGroup {
                // Custom grouping (date, book, speaker)
                ForEach(viewModel.sermonGroups) { group in
                    Section {
                        ForEach(group.sermons) { sermon in
                            sermonRow(sermon)
                        }
                    } header: {
                        groupHeader(group)
                    }
                }
            } else {
                // Status-based sectioning (default)

                // Pinned section (always first)
                if !viewModel.pinnedSermons.isEmpty {
                    Section {
                        ForEach(viewModel.pinnedSermons) { sermon in
                            sermonRow(sermon)
                        }
                    } header: {
                        pinnedSectionHeader
                    }
                }

                // Processing section
                if !viewModel.processingSermons.isEmpty {
                    Section {
                        ForEach(viewModel.processingSermons) { sermon in
                            sermonRow(sermon)
                        }
                    } header: {
                        if viewModel.hasMultipleSections {
                            sectionHeader("PROCESSING")
                        }
                    }
                }

                // Error section
                if !viewModel.errorSermons.isEmpty {
                    Section {
                        ForEach(viewModel.errorSermons) { sermon in
                            sermonRow(sermon)
                        }
                    } header: {
                        if viewModel.hasMultipleSections {
                            sectionHeader("NEEDS ATTENTION")
                        }
                    }
                }

                // Ready section
                if !viewModel.readySermons.isEmpty {
                    Section {
                        ForEach(viewModel.readySermons) { sermon in
                            sermonRow(sermon)
                        }
                    } header: {
                        if viewModel.hasMultipleSections {
                            sectionHeader("READY")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func groupHeader(_ group: SermonGroup) -> some View {
        HStack {
            Text(group.title.uppercased())
                .font(Typography.Editorial.sectionHeader)
                .tracking(Typography.Editorial.sectionTracking)
                .foregroundStyle(Color("TertiaryText"))

            Spacer()

            Text(group.subtitle)
                .font(Typography.Command.caption)
                .foregroundStyle(Color("TertiaryText"))
        }
        .listRowInsets(EdgeInsets(
            top: Theme.Spacing.md,
            leading: Theme.Spacing.lg,
            bottom: Theme.Spacing.xs,
            trailing: Theme.Spacing.lg
        ))
    }

    @ViewBuilder
    private func sermonRow(_ sermon: Sermon) -> some View {
        SermonLibraryCard(
            sermon: sermon,
            isSelected: selectedSermons.contains(sermon.id),
            isSelectionMode: isSelectionMode,
            isSelectable: viewModel.canDelete(sermon)
        ) {
            handleSermonTap(sermon)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(
            top: Theme.Spacing.sm,
            leading: Theme.Spacing.lg,
            bottom: Theme.Spacing.sm,
            trailing: Theme.Spacing.lg
        ))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if viewModel.canDelete(sermon) {
                Button(role: .destructive) {
                    sermonToDelete = sermon
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                pinService.togglePin(sermon.id)
            } label: {
                Label(
                    pinService.isPinned(sermon.id) ? "Unpin" : "Pin",
                    systemImage: pinService.isPinned(sermon.id) ? "pin.slash.fill" : "pin.fill"
                )
            }
            .tint(Color("AccentBronze"))
        }
        .contextMenu {
            // Pin/Unpin (available for all sermons)
            Button {
                pinService.togglePin(sermon.id)
            } label: {
                Label(
                    pinService.isPinned(sermon.id) ? "Unpin" : "Pin",
                    systemImage: pinService.isPinned(sermon.id) ? "pin.slash" : "pin"
                )
            }

            // Rename (available for all sermons)
            Button {
                sermonToRename = sermon
                renameText = sermon.title.isEmpty ? "" : sermon.title
                showRenameSheet = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Divider()

            if viewModel.canDelete(sermon) {
                Button(role: .destructive) {
                    sermonToDelete = sermon
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }

                if !isSelectionMode {
                    Button {
                        isSelectionMode = true
                        selectedSermons.insert(sermon.id)
                    } label: {
                        Label("Select", systemImage: "checkmark.circle")
                    }
                }
            } else {
                Text("Cannot delete while processing")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Typography.Editorial.sectionHeader)
            .tracking(Typography.Editorial.sectionTracking)
            .foregroundStyle(Color("TertiaryText"))
            .listRowInsets(EdgeInsets(
                top: Theme.Spacing.md,
                leading: Theme.Spacing.lg,
                bottom: Theme.Spacing.xs,
                trailing: Theme.Spacing.lg
            ))
    }

    private var pinnedSectionHeader: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "pin.fill")
                .font(Typography.Icon.xxs)
                .foregroundStyle(Color("AccentBronze"))

            Text("PINNED")
                .font(Typography.Editorial.sectionHeader)
                .tracking(Typography.Editorial.sectionTracking)
                .foregroundStyle(Color("AccentBronze"))
        }
        .listRowInsets(EdgeInsets(
            top: Theme.Spacing.md,
            leading: Theme.Spacing.lg,
            bottom: Theme.Spacing.xs,
            trailing: Theme.Spacing.lg
        ))
    }

    // MARK: - Helpers

    private func handleSermonTap(_ sermon: Sermon) {
        if isSelectionMode {
            toggleSelection(sermon)
        } else {
            onSelect(sermon)
        }
    }

    private func toggleSelection(_ sermon: Sermon) {
        guard viewModel.canDelete(sermon) else { return }

        if selectedSermons.contains(sermon.id) {
            selectedSermons.remove(sermon.id)
        } else {
            selectedSermons.insert(sermon.id)
        }
        HapticService.shared.selectionChanged()
    }

    private func exitSelectionMode() {
        isSelectionMode = false
        selectedSermons.removeAll()
    }
}

// MARK: - Sermon Library Card

struct SermonLibraryCard: View {
    let sermon: Sermon
    var isSelected: Bool = false
    var isSelectionMode: Bool = false
    var isSelectable: Bool = true
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: Theme.Spacing.lg) {
                // Selection checkbox (selection mode only)
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(Typography.Icon.base)
                        .foregroundStyle(
                            isSelected ? Color("AccentBronze") :
                            isSelectable ? Color("TertiaryText") : Color("TertiaryText").opacity(0.4)
                        )
                        .animation(Theme.Animation.settle, value: isSelected)
                }

                // Status indicator (44pt tap target)
                SermonStatusView(sermon: sermon, layout: .full)

                // Info
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack(spacing: Theme.Spacing.xs) {
                        // Pin indicator
                        if sermon.isPinned {
                            Image(systemName: "pin.fill")
                                .font(Typography.Icon.xxs)
                                .foregroundStyle(Color("AccentBronze"))
                        }

                        Text(sermon.displayTitle)
                            .font(Typography.Scripture.heading)
                            .foregroundStyle(Color.appTextPrimary)
                            .lineLimit(2)
                    }

                    HStack(spacing: Theme.Spacing.sm) {
                        if let speaker = sermon.speakerName {
                            Text(speaker)
                                .foregroundStyle(Color.appTextSecondary)

                            Text("—")
                                .foregroundStyle(Color("TertiaryText"))
                        }

                        Text(sermon.formattedDuration)
                            .foregroundStyle(Color.appTextSecondary)

                        Text("—")
                            .foregroundStyle(Color("TertiaryText"))

                        Text(formattedDate)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .font(Typography.Command.caption)
                    .lineLimit(1)
                }

                Spacer()

                // Chevron (hide in selection mode)
                if !isSelectionMode {
                    Image(systemName: "chevron.right")
                        // swiftlint:disable:next hardcoded_font_system
                        .font(Typography.Icon.sm)
                        .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.textSecondary))
                }
            }
            .padding(Theme.Spacing.lg)
            .background(
                isSelected
                    ? Color("AccentBronze").opacity(Theme.Opacity.subtle)
                    : Color("AppSurface").opacity(Theme.Opacity.pressed)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(
                        isSelected
                            ? Color("AccentBronze")
                            : Color("AccentBronze").opacity(Theme.Opacity.selectionBackground),
                        lineWidth: isSelected ? Theme.Stroke.control : Theme.Stroke.hairline
                    )
            )
            .opacity(isSelectionMode && !isSelectable ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isSelectionMode && !isSelectable)
    }

    // MARK: - Date Formatting

    /// Short date format: "Jan 24" for current year, "Jan 24, 2025" for other years
    private var formattedDate: String {
        let calendar = Calendar.current
        let isCurrentYear = calendar.isDate(sermon.recordedAt, equalTo: Date(), toGranularity: .year)

        if isCurrentYear {
            return sermon.recordedAt.formatted(.dateTime.month(.abbreviated).day())
        } else {
            return sermon.recordedAt.formatted(.dateTime.month(.abbreviated).day().year())
        }
    }
}

// MARK: - Preview

#Preview {
    SermonLibraryView { sermon in
        print("Selected: \(sermon.title)")
    }
    .preferredColorScheme(.dark)
}

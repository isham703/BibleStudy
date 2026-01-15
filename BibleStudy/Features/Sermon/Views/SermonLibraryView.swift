import SwiftUI

// MARK: - Sermon Library View
// Lists all saved sermons with search, filtering, and delete functionality

struct SermonLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SermonLibraryViewModel()
    @State private var searchText = ""

    // Delete state
    @State private var showDeleteConfirmation = false
    @State private var sermonToDelete: Sermon?

    // Selection mode state
    @State private var isSelectionMode = false
    @State private var selectedSermons: Set<UUID> = []
    @State private var showBatchDeleteConfirmation = false
    @State private var isDeleting = false

    let onSelect: (Sermon) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color("AppBackground")
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else if filteredSermons.isEmpty {
                    emptyStateView
                } else {
                    sermonList
                }
            }
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
                    } else if !filteredSermons.isEmpty {
                        Button {
                            isSelectionMode = true
                        } label: {
                            Image(systemName: "checkmark.circle")
                        }
                        .foregroundStyle(Color("AccentBronze"))
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search sermons")
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
    }

    // MARK: - Filtered Sermons

    private var filteredSermons: [Sermon] {
        if searchText.isEmpty {
            return viewModel.sermons
        }
        return viewModel.sermons.filter { sermon in
            sermon.title.localizedCaseInsensitiveContains(searchText) ||
            (sermon.speakerName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
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
        VStack(spacing: Theme.Spacing.xxl) {
            Image(systemName: "waveform.circle")
                // swiftlint:disable:next hardcoded_font_system
                .font(Typography.Icon.display)
                .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.textSecondary))

            VStack(spacing: Theme.Spacing.sm) {
                Text(searchText.isEmpty ? "No Sermons Yet" : "No Results")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color.appTextPrimary)

                Text(searchText.isEmpty
                    ? "Record or import your first sermon to get started"
                    : "Try a different search term"
                )
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Theme.Spacing.xxl + Theme.Spacing.sm)
    }

    // MARK: - Sermon List

    private var sermonList: some View {
        List {
            ForEach(filteredSermons) { sermon in
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
                .contextMenu {
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
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
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

                // Status indicator
                statusIcon
                    .frame(width: 40, height: 40)

                // Info
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(sermon.displayTitle)
                        .font(Typography.Scripture.heading)
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(1)

                    HStack(spacing: Theme.Spacing.sm) {
                        if let speaker = sermon.speakerName {
                            Text(speaker)
                                .foregroundStyle(Color.appTextSecondary)
                        }

                        Text("•")
                            .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.textSecondary))

                        Text(sermon.formattedDuration)
                            .foregroundStyle(Color.appTextSecondary)

                        Text("•")
                            .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.textSecondary))

                        Text(sermon.recordedAt.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .font(Typography.Scripture.body)
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

    // MARK: - Status Icon

    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(statusBackgroundColor)

            if sermon.isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("AccentBronze")))
                    .scaleEffect(0.98)
            } else {
                Image(systemName: statusIconName)
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Icon.base)
                    .foregroundStyle(statusIconColor)
            }
        }
    }

    private var statusBackgroundColor: Color {
        if sermon.hasError {
            return Color.red.opacity(Theme.Opacity.selectionBackground)
        } else if sermon.isComplete {
            return Color("AccentBronze").opacity(Theme.Opacity.selectionBackground)
        } else {
            return Color("AppSurface")
        }
    }

    private var statusIconName: String {
        if sermon.hasError {
            return "exclamationmark.triangle.fill"
        } else if sermon.isComplete {
            return "checkmark.circle.fill"
        } else {
            return "clock"
        }
    }

    private var statusIconColor: Color {
        if sermon.hasError {
            return Color.red
        } else if sermon.isComplete {
            return Color("AccentBronze")
        } else {
            return Color.appTextSecondary
        }
    }
}

// MARK: - Sermon Library ViewModel

@MainActor
@Observable
final class SermonLibraryViewModel {
    var sermons: [Sermon] = []
    var isLoading = false

    private let syncService = SermonSyncService.shared
    private let toastService = ToastService.shared

    func loadSermons() async {
        isLoading = true
        defer { isLoading = false }

        await syncService.loadSermons()
        sermons = syncService.sermons.sorted { $0.recordedAt > $1.recordedAt }
    }

    // MARK: - Delete Operations

    func canDelete(_ sermon: Sermon) -> Bool {
        syncService.canDeleteSermon(sermon)
    }

    func deleteSermon(_ sermon: Sermon) async {
        print("[SermonLibraryViewModel] deleteSermon called for: \(sermon.displayTitle) (id: \(sermon.id))")
        do {
            try await syncService.deleteSermon(sermon)
            sermons.removeAll { $0.id == sermon.id }
            print("[SermonLibraryViewModel] Delete succeeded, remaining sermons: \(sermons.count)")
            HapticService.shared.deleteConfirmed()
            toastService.showSermonDeleted(title: sermon.displayTitle)
        } catch {
            print("[SermonLibraryViewModel] Failed to delete sermon: \(error)")
            HapticService.shared.warning()
            toastService.showDeleteError(message: error.localizedDescription)
        }
    }

    func batchDeleteSermons(_ sermonIds: [UUID]) async {
        print("[SermonLibraryViewModel] batchDeleteSermons called with \(sermonIds.count) IDs")
        print("[SermonLibraryViewModel] Current sermons count: \(sermons.count)")
        let toDelete = sermons.filter { sermonIds.contains($0.id) }
        print("[SermonLibraryViewModel] Sermons to delete: \(toDelete.count)")
        do {
            try await syncService.batchDeleteSermons(toDelete)
            sermons.removeAll { sermonIds.contains($0.id) }
            print("[SermonLibraryViewModel] Batch delete succeeded, remaining sermons: \(sermons.count)")
            HapticService.shared.deleteConfirmed()
            toastService.showSermonsDeleted(count: sermonIds.count)
        } catch {
            print("[SermonLibraryViewModel] Failed to batch delete: \(error)")
            HapticService.shared.warning()
            toastService.showDeleteError(message: error.localizedDescription)
        }
    }

    // MARK: - Storage Info

    func formattedStorageSize(for sermon: Sermon) -> String {
        do {
            let bytes = try syncService.getSermonStorageSize(sermon.id)
            return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
        } catch {
            return "unknown storage"
        }
    }

    func formattedTotalStorageSize(for sermonIds: [UUID]) -> String {
        do {
            var total: Int64 = 0
            for id in sermonIds {
                total += try syncService.getSermonStorageSize(id)
            }
            return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
        } catch {
            return "unknown storage"
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

import Foundation

// MARK: - Sermon Library ViewModel
// Memoized filtering with revision-based invalidation

@MainActor
@Observable
final class SermonLibraryViewModel: SyncResultNotifying {
    // MARK: - State

    var sermons: [Sermon] = []
    var isLoading = false

    // Filter/Sort state (moved from View for memoization)
    var searchText = ""
    var selectedFilter: SermonStatusFilterOption = .all
    var selectedGroup: SermonGroupOption = .saved
    var selectedSort: SermonSortOption = .saved

    // MARK: - Revision Tracking

    /// Revision increments on any sermon mutation
    private(set) var sermonsRevision: Int = 0

    // MARK: - Memoization Cache

    private struct FilterKey: Hashable {
        let revision: Int
        let searchText: String
        let filter: SermonStatusFilterOption
        let group: SermonGroupOption
        let sort: SermonSortOption
    }

    private var cachedFilteredSermons: (key: FilterKey, result: [Sermon])?
    private var cachedSearchFilteredSermons: (key: (Int, String), result: [Sermon])?
    private var cachedSermonGroups: (key: FilterKey, result: [SermonGroup])?

    // MARK: - Dependencies

    private let syncService = SermonSyncService.shared
    private let groupingService = SermonGroupingService.shared
    private let pinService = SermonPinService.shared
    private let toastService = ToastService.shared

    // MARK: - Computed Properties (Memoized)

    /// Sermons filtered by search text only (for filter chip counts)
    var searchFilteredSermons: [Sermon] {
        let key = (sermonsRevision, searchText)

        if let cached = cachedSearchFilteredSermons, cached.key == key {
            return cached.result
        }

        let result: [Sermon]
        if searchText.isEmpty {
            result = sermons
        } else {
            result = sermons.filter { sermon in
                sermon.title.localizedCaseInsensitiveContains(searchText) ||
                (sermon.speakerName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        cachedSearchFilteredSermons = (key, result)
        return result
    }

    /// Sermons filtered by both search and status filter
    var filteredSermons: [Sermon] {
        let key = makeFilterKey()

        if let cached = cachedFilteredSermons, cached.key == key {
            return cached.result
        }

        let result = searchFilteredSermons.filter { selectedFilter.matches($0) }
        cachedFilteredSermons = (key, result)
        return result
    }

    /// Sermons grouped by selected option
    var sermonGroups: [SermonGroup] {
        let key = makeFilterKey()

        if let cached = cachedSermonGroups, cached.key == key {
            return cached.result
        }

        let result = groupingService.group(filteredSermons, by: selectedGroup, sortedBy: selectedSort)
        cachedSermonGroups = (key, result)
        return result
    }

    /// Whether using custom grouping (not status-based)
    var isUsingCustomGroup: Bool {
        selectedGroup != .none
    }

    // MARK: - Pinned/Status Sectioned Sermons

    var pinnedSermons: [Sermon] {
        pinService.pinnedSermons(from: filteredSermons)
    }

    var unpinnedSermons: [Sermon] {
        pinService.unpinnedSermons(from: filteredSermons)
    }

    var processingSermons: [Sermon] {
        unpinnedSermons.filter { $0.isProcessing }
    }

    var errorSermons: [Sermon] {
        unpinnedSermons.filter { $0.hasError }
    }

    var readySermons: [Sermon] {
        unpinnedSermons.filter { !$0.isProcessing && !$0.hasError }
    }

    var hasMultipleSections: Bool {
        let sections = [pinnedSermons, processingSermons, errorSermons, readySermons].filter { !$0.isEmpty }
        return sections.count > 1
    }

    // MARK: - Private Helpers

    private func makeFilterKey() -> FilterKey {
        FilterKey(
            revision: sermonsRevision,
            searchText: searchText,
            filter: selectedFilter,
            group: selectedGroup,
            sort: selectedSort
        )
    }

    private func incrementRevision() {
        sermonsRevision += 1
    }

    // MARK: - Load Operations

    func loadSermons() async {
        isLoading = true
        defer { isLoading = false }

        await syncService.loadSermons()
        sermons = syncService.sermons.sorted { $0.recordedAt > $1.recordedAt }
        incrementRevision()
    }

    // MARK: - Delete Operations

    func canDelete(_ sermon: Sermon) -> Bool {
        syncService.canDeleteSermon(sermon)
    }

    func deleteSermon(_ sermon: Sermon) async {
        print("[SermonLibraryViewModel] deleteSermon called for: \(sermon.displayTitle) (id: \(sermon.id))")

        let result = await syncService.deleteSermon(sermon)

        if result.isLocalSuccess {
            sermons.removeAll { $0.id == sermon.id }
            incrementRevision()

            // Invalidate transcript segment cache for deleted sermon
            TranscriptSegmentCache.shared.invalidate(sermonId: sermon.id)

            print("[SermonLibraryViewModel] Delete succeeded, remaining sermons: \(sermons.count)")
            HapticService.shared.deleteConfirmed()
        }

        handleSyncResult(result, for: .delete)
    }

    func batchDeleteSermons(_ sermonIds: [UUID]) async {
        print("[SermonLibraryViewModel] batchDeleteSermons called with \(sermonIds.count) IDs")
        print("[SermonLibraryViewModel] Current sermons count: \(sermons.count)")

        let toDelete = sermons.filter { sermonIds.contains($0.id) }
        print("[SermonLibraryViewModel] Sermons to delete: \(toDelete.count)")

        let result = await syncService.batchDeleteSermons(toDelete)

        // Get the IDs that were successfully deleted
        let deletedIds: Set<UUID>
        switch result {
        case .success(let ids, _):
            deletedIds = Set(ids)
        case .partialSuccess(let succeeded, _):
            deletedIds = Set(succeeded.flatMap { $0.0 })
        case .failure:
            deletedIds = []
        }

        if !deletedIds.isEmpty {
            sermons.removeAll { deletedIds.contains($0.id) }
            incrementRevision()

            // Invalidate transcript segment cache for deleted sermons
            for id in deletedIds {
                TranscriptSegmentCache.shared.invalidate(sermonId: id)
            }

            print("[SermonLibraryViewModel] Batch delete succeeded for \(deletedIds.count), remaining: \(sermons.count)")
            HapticService.shared.deleteConfirmed()
        }

        handleSyncResult(result, for: .batchDelete)
    }

    // MARK: - Rename Operations

    func renameSermon(_ sermon: Sermon, to newTitle: String) async {
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let result = await syncService.renameSermon(sermon.id, title: trimmedTitle)

        if result.isLocalSuccess {
            if let index = sermons.firstIndex(where: { $0.id == sermon.id }) {
                sermons[index].title = trimmedTitle
                incrementRevision()
            }
            HapticService.shared.selectionChanged()
        }

        handleSyncResult(result, for: .rename)
    }

    // MARK: - SyncResultNotifying

    func handleSyncResult<T: Sendable>(_ result: SyncResult<T>) {
        handleSyncResult(result, for: .sync)
    }

    func handleSyncResult<T: Sendable>(_ result: SyncResult<T>, for operation: SyncOperation) {
        switch result {
        case .success(_, let syncState):
            if syncState == .synced {
                // Full success - show appropriate toast based on operation
                switch operation {
                case .delete:
                    toastService.showSermonDeleted(title: "Sermon")
                case .batchDelete:
                    // Toast shown via different path with count
                    break
                case .rename:
                    toastService.showSuccess(message: "Renamed successfully")
                default:
                    break
                }
            } else {
                // Queued for later sync
                toastService.showInfo(message: "Saved locally. Will sync when online.")
            }

        case .failure(let error):
            HapticService.shared.warning()
            if error.failureScope == .local {
                toastService.showDeleteError(message: error.localizedDescription)
            }
            // Remote failures are soft - data is saved locally
            print("[SermonLibraryViewModel] Sync error: \(error)")

        case .partialSuccess(let succeeded, let failed):
            let successCount = succeeded.count
            let failCount = failed.count

            if operation == .batchDelete {
                toastService.showSermonsDeleted(count: successCount)
                if failCount > 0 {
                    toastService.showInfo(message: "\(failCount) will retry later")
                }
            }
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

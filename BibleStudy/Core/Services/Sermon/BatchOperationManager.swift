import Foundation

// MARK: - Batch Operation Manager
// Manages batch operations with partial failure support

enum BatchOperationManager {
    // MARK: - Batch Execute

    /// Execute a batch of operations with partial failure support
    /// - Parameters:
    ///   - items: Items to process
    ///   - operation: Async operation to perform on each item
    /// - Returns: SyncResult with succeeded and failed items
    static func execute<T: Sendable, R: Sendable>(
        items: [T],
        operation: @escaping (T) async throws -> (R, SyncState)
    ) async -> SyncResult<[R]> {
        guard !items.isEmpty else {
            return .success([], syncState: .synced)
        }

        var succeeded: [(R, SyncState)] = []
        var failed: [(R, SermonSyncError)] = []
        var allSynced = true

        for item in items {
            do {
                let (result, syncState) = try await operation(item)
                succeeded.append((result, syncState))
                if syncState != .synced {
                    allSynced = false
                }
            } catch let error as SermonSyncError {
                // If we can get a partial result, include it
                // Otherwise, we skip this item in the failure list
                // Note: For delete operations, the item ID itself is the result
                if let identifiable = item as? any Identifiable,
                   let id = identifiable.id as? R {
                    failed.append((id, error))
                }
            } catch {
                // Wrap generic error
                let syncError = SermonSyncError.localFailure(
                    operation: .batchDelete,
                    error: error
                )
                if let identifiable = item as? any Identifiable,
                   let id = identifiable.id as? R {
                    failed.append((id, syncError))
                }
            }
        }

        // Return appropriate result
        if failed.isEmpty {
            let results = succeeded.map { $0.0 }
            let syncState: SyncState = allSynced ? .synced : .queued
            return .success(results, syncState: syncState)
        } else if succeeded.isEmpty {
            // All failed - return first error
            if let firstError = failed.first?.1 {
                return .failure(firstError)
            }
            return .failure(SermonSyncError.localFailure(
                operation: .batchDelete,
                error: SermonError.deleteFailed("All operations failed")
            ))
        } else {
            // Partial success - wrap individual items in arrays for SyncResult<[R]>
            let wrappedSucceeded = succeeded.map { ([($0.0)], $0.1) }
            let wrappedFailed = failed.map { ([($0.0)], $0.1) }
            return .partialSuccess(succeeded: wrappedSucceeded, failed: wrappedFailed)
        }
    }

    /// Execute a batch of void operations with partial failure support
    /// - Parameters:
    ///   - items: Items to process
    ///   - getId: Closure to extract identifier from item
    ///   - operation: Async operation to perform on each item
    /// - Returns: SyncResult with succeeded and failed item IDs
    static func executeWithId<T, ID: Sendable>(
        items: [T],
        getId: (T) -> ID,
        operation: @escaping (T) async throws -> SyncState
    ) async -> SyncResult<[ID]> {
        guard !items.isEmpty else {
            return .success([], syncState: .synced)
        }

        var succeeded: [(ID, SyncState)] = []
        var failed: [(ID, SermonSyncError)] = []
        var allSynced = true

        for item in items {
            let id = getId(item)
            do {
                let syncState = try await operation(item)
                succeeded.append((id, syncState))
                if syncState != .synced {
                    allSynced = false
                }
            } catch let error as SermonSyncError {
                failed.append((id, error))
            } catch {
                let syncError = SermonSyncError.localFailure(
                    operation: .batchDelete,
                    error: error
                )
                failed.append((id, syncError))
            }
        }

        if failed.isEmpty {
            let results = succeeded.map { $0.0 }
            let syncState: SyncState = allSynced ? .synced : .queued
            return .success(results, syncState: syncState)
        } else if succeeded.isEmpty {
            if let firstError = failed.first?.1 {
                return .failure(firstError)
            }
            return .failure(SermonSyncError.localFailure(
                operation: .batchDelete,
                error: SermonError.deleteFailed("All operations failed")
            ))
        } else {
            // Partial success - wrap individual items in arrays for SyncResult<[ID]>
            let wrappedSucceeded = succeeded.map { ([($0.0)], $0.1) }
            let wrappedFailed = failed.map { ([($0.0)], $0.1) }
            return .partialSuccess(succeeded: wrappedSucceeded, failed: wrappedFailed)
        }
    }
}

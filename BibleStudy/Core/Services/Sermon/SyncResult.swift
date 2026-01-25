import Foundation

// MARK: - Sync Result
// Result type with local/remote distinction for offline-first sync operations

/// Represents the sync state after an operation
enum SyncState: Sendable {
    /// Both local and remote operations succeeded
    case synced
    /// Local succeeded, remote pending/failed (will retry automatically)
    case queued
}

/// Represents the scope of a sync failure
enum FailureScope: Sendable {
    /// Hard failure - local database write failed
    case local
    /// Soft failure - remote sync failed but queued for retry
    case remote
}

/// Represents the type of sync operation
enum SyncOperation: String, Sendable {
    case create
    case update
    case delete
    case batchDelete
    case rename
    case sync
    case upload
    case download
    case jwtRefresh
}

// MARK: - Sermon Sync Error

/// Error type for sermon sync operations with failure scope
struct SermonSyncError: Error, LocalizedError, Sendable {
    let operation: SyncOperation
    let underlyingError: Error
    let isRetryable: Bool
    let failureScope: FailureScope

    var errorDescription: String? {
        let scopePrefix = failureScope == .local ? "Local" : "Sync"
        return "\(scopePrefix) error during \(operation.rawValue): \(underlyingError.localizedDescription)"
    }

    var recoverySuggestion: String? {
        if failureScope == .remote && isRetryable {
            return "Changes saved locally. Will sync automatically when connection is restored."
        }
        return nil
    }

    /// Create a local failure error (hard failure)
    static func localFailure(
        operation: SyncOperation,
        error: Error
    ) -> SermonSyncError {
        SermonSyncError(
            operation: operation,
            underlyingError: error,
            isRetryable: false,
            failureScope: .local
        )
    }

    /// Create a remote failure error (soft failure, queued for retry)
    static func remoteFailure(
        operation: SyncOperation,
        error: Error,
        isRetryable: Bool = true
    ) -> SermonSyncError {
        SermonSyncError(
            operation: operation,
            underlyingError: error,
            isRetryable: isRetryable,
            failureScope: .remote
        )
    }
}

// MARK: - Sync Result

/// Result of a sync operation with local/remote distinction
enum SyncResult<T: Sendable>: Sendable {
    /// Operation fully succeeded (local and optionally remote)
    case success(T, syncState: SyncState)

    /// Operation failed
    case failure(SermonSyncError)

    /// Batch operation with partial success
    case partialSuccess(
        succeeded: [(T, SyncState)],
        failed: [(T, SermonSyncError)]
    )

    /// Whether the local operation succeeded (remote may have failed but is queued)
    var isLocalSuccess: Bool {
        switch self {
        case .success:
            return true
        case .partialSuccess(let succeeded, _):
            return !succeeded.isEmpty
        case .failure(let error):
            // Remote failures are still "local success" since data is saved locally
            return error.failureScope == .remote
        }
    }

    /// Whether the operation fully succeeded (both local and remote)
    var isFullySucceeded: Bool {
        switch self {
        case .success(_, let syncState):
            return syncState == .synced
        case .partialSuccess, .failure:
            return false
        }
    }

    /// The error if the operation failed, nil otherwise
    var error: SermonSyncError? {
        switch self {
        case .failure(let error):
            return error
        case .success, .partialSuccess:
            return nil
        }
    }

    /// The value if successful, nil otherwise
    var value: T? {
        switch self {
        case .success(let value, _):
            return value
        case .partialSuccess, .failure:
            return nil
        }
    }

    /// Map the success value to a new type
    func map<U: Sendable>(_ transform: (T) -> U) -> SyncResult<U> {
        switch self {
        case .success(let value, let syncState):
            return .success(transform(value), syncState: syncState)
        case .failure(let error):
            return .failure(error)
        case .partialSuccess(let succeeded, let failed):
            let mappedSucceeded = succeeded.map { (transform($0.0), $0.1) }
            let mappedFailed = failed.map { (transform($0.0), $0.1) }
            return .partialSuccess(succeeded: mappedSucceeded, failed: mappedFailed)
        }
    }
}

// MARK: - Void Convenience

extension SyncResult where T == Void {
    /// Create a success result for void operations
    static func success(syncState: SyncState) -> SyncResult<Void> {
        .success((), syncState: syncState)
    }
}

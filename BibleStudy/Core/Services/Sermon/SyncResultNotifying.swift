import Foundation

// MARK: - Sync Result Notifying
// Protocol for handling sync results (UI-agnostic, implemented at Feature layer)

/// Protocol for components that handle sync result notifications
/// Implemented at the Feature layer (ViewModels) to handle UI feedback
@MainActor
protocol SyncResultNotifying {
    /// Handle a sync result and show appropriate UI feedback
    /// - Parameter result: The sync result to handle
    func handleSyncResult<T: Sendable>(_ result: SyncResult<T>)

    /// Handle a sync result for a specific operation type
    /// - Parameters:
    ///   - result: The sync result to handle
    ///   - operation: The operation that produced this result
    func handleSyncResult<T: Sendable>(_ result: SyncResult<T>, for operation: SyncOperation)
}

// MARK: - Default Implementation

extension SyncResultNotifying {
    /// Default implementation delegates to the simpler method
    func handleSyncResult<T: Sendable>(_ result: SyncResult<T>, for operation: SyncOperation) {
        handleSyncResult(result)
    }
}

// MARK: - Sync Result Message

/// Helper to generate user-facing messages from sync results
enum SyncResultMessage {
    /// Generate a user-facing message for a sync result
    static func message<T: Sendable>(
        for result: SyncResult<T>,
        operation: SyncOperation,
        itemName: String = "item"
    ) -> (title: String, isError: Bool)? {
        switch result {
        case .success(_, let syncState):
            switch syncState {
            case .synced:
                return nil // No toast needed for full success
            case .queued:
                return (
                    title: "\(itemName.capitalized) saved. Will sync when online.",
                    isError: false
                )
            }

        case .failure(let error):
            if error.failureScope == .remote && error.isRetryable {
                return (
                    title: "\(itemName.capitalized) saved locally. Sync will retry.",
                    isError: false
                )
            } else {
                return (
                    title: error.localizedDescription,
                    isError: true
                )
            }

        case .partialSuccess(let succeeded, let failed):
            let successCount = succeeded.count
            let failCount = failed.count
            let allRemote = failed.allSatisfy { $0.1.failureScope == .remote }

            if allRemote {
                return (
                    title: "\(successCount) \(itemName)(s) synced, \(failCount) will retry later.",
                    isError: false
                )
            } else {
                return (
                    title: "\(successCount) succeeded, \(failCount) failed.",
                    isError: true
                )
            }
        }
    }
}

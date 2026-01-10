import Foundation

// MARK: - Progress Update
// Represents a progress update for a sermon processing job

struct SermonProgressUpdate: Sendable {
    let job: SermonProcessingJob
    let progress: Double

    /// Progress percentage (0-100)
    var progressPercent: Int {
        Int(progress * 100)
    }
}

// MARK: - Sermon Progress Publisher
// Actor-based progress publisher using AsyncStream for type-safe, memory-safe progress updates.
// Replaces callback dictionary pattern to prevent memory leaks from orphaned callbacks.

actor SermonProgressPublisher {

    // MARK: - Types

    /// Unique identifier for a subscription
    typealias SubscriptionID = UUID

    /// Continuation wrapper with metadata
    private struct Subscription {
        let id: SubscriptionID
        let sermonId: UUID
        let continuation: AsyncStream<SermonProgressUpdate>.Continuation
    }

    // MARK: - State

    /// Active subscriptions keyed by sermon ID, then by subscription ID
    /// Multiple views can subscribe to the same sermon's progress
    private var subscriptions: [UUID: [SubscriptionID: Subscription]] = [:]

    // MARK: - Singleton

    static let shared = SermonProgressPublisher()

    /// Internal init allows @testable import to create isolated instances for testing
    init() {}

    // MARK: - Public API

    /// Subscribe to progress updates for a specific sermon
    /// - Parameter sermonId: The sermon to subscribe to
    /// - Returns: An AsyncStream that yields progress updates
    ///
    /// The stream will automatically clean up when the consumer stops iterating.
    /// Example usage:
    /// ```swift
    /// let stream = await progressPublisher.subscribe(to: sermonId)
    /// for await update in stream {
    ///     self.updateUI(progress: update.progress)
    /// }
    /// ```
    func subscribe(to sermonId: UUID) -> AsyncStream<SermonProgressUpdate> {
        let subscriptionId = UUID()

        return AsyncStream { continuation in
            let subscription = Subscription(
                id: subscriptionId,
                sermonId: sermonId,
                continuation: continuation
            )

            // Store subscription
            if subscriptions[sermonId] == nil {
                subscriptions[sermonId] = [:]
            }
            subscriptions[sermonId]?[subscriptionId] = subscription

            // Handle cancellation/termination
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.removeSubscription(id: subscriptionId, sermonId: sermonId)
                }
            }
        }
    }

    /// Publish a progress update to all subscribers for a sermon
    /// - Parameters:
    ///   - sermonId: The sermon being processed
    ///   - job: Current job state
    ///   - progress: Progress value (0.0 to 1.0)
    func publish(sermonId: UUID, job: SermonProcessingJob, progress: Double) {
        guard let sermonSubscriptions = subscriptions[sermonId] else { return }

        let update = SermonProgressUpdate(job: job, progress: progress)

        for subscription in sermonSubscriptions.values {
            subscription.continuation.yield(update)
        }
    }

    /// Complete all streams for a sermon (called when processing finishes)
    /// - Parameter sermonId: The sermon that completed processing
    func complete(sermonId: UUID) {
        guard let sermonSubscriptions = subscriptions.removeValue(forKey: sermonId) else { return }

        for subscription in sermonSubscriptions.values {
            subscription.continuation.finish()
        }
    }

    /// Complete a stream with an error indication
    /// - Parameters:
    ///   - sermonId: The sermon that failed
    ///   - job: Final job state with error status
    func completeWithError(sermonId: UUID, job: SermonProcessingJob) {
        // Yield final state before finishing
        if let sermonSubscriptions = subscriptions[sermonId] {
            let update = SermonProgressUpdate(job: job, progress: 1.0)
            for subscription in sermonSubscriptions.values {
                subscription.continuation.yield(update)
            }
        }

        complete(sermonId: sermonId)
    }

    /// Get count of active subscriptions for a sermon (for debugging)
    func subscriptionCount(for sermonId: UUID) -> Int {
        subscriptions[sermonId]?.count ?? 0
    }

    /// Get total count of all active subscriptions (for debugging)
    var totalSubscriptionCount: Int {
        subscriptions.values.reduce(0) { $0 + $1.count }
    }

    // MARK: - Private

    private func removeSubscription(id: SubscriptionID, sermonId: UUID) {
        subscriptions[sermonId]?.removeValue(forKey: id)

        // Clean up empty sermon entry
        if subscriptions[sermonId]?.isEmpty == true {
            subscriptions.removeValue(forKey: sermonId)
        }
    }
}

// MARK: - Convenience Extension for Non-Actor Contexts

extension SermonProgressPublisher {
    /// Get a stream for use in @MainActor contexts
    /// This is a convenience wrapper that handles the async call with proper cancellation handling
    nonisolated func progressStream(for sermonId: UUID) -> AsyncStream<SermonProgressUpdate> {
        // Create stream that bridges to actor with cancellation support
        AsyncStream { continuation in
            let task = Task {
                let innerStream = await self.subscribe(to: sermonId)
                for await update in innerStream {
                    // Check for cancellation before yielding
                    guard !Task.isCancelled else { break }
                    continuation.yield(update)
                }
                continuation.finish()
            }

            // Handle termination by cancelling the bridging task
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

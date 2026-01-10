import Testing
import Foundation
@testable import BibleStudy

// MARK: - Progress Publisher Tests
// Tests for AsyncStream-based progress updates and cancellation

@Suite("SermonProgressPublisher")
struct ProgressPublisherTests {

    // MARK: - Subscription Tests

    @Test("Subscribe returns stream")
    func testSubscribe_ReturnsStream() async {
        let publisher = SermonProgressPublisher()
        let sermonId = UUID()

        let stream = await publisher.subscribe(to: sermonId)

        // Stream should exist (we can't easily test iteration without publishing)
        #expect(stream != nil)
    }

    @Test("Publish yields to subscriber")
    func testPublish_YieldsToSubscriber() async throws {
        let publisher = SermonProgressPublisher()
        let sermonId = UUID()

        let stream = await publisher.subscribe(to: sermonId)

        // Create a test job
        let job = SermonProcessingJob(
            sermonId: sermonId,
            transcriptionStatus: .running,
            studyGuideStatus: .pending,
            chunkStatuses: []
        )

        // Publish in a separate task
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            await publisher.publish(sermonId: sermonId, job: job, progress: 0.5)
            try? await Task.sleep(for: .milliseconds(50))
            await publisher.complete(sermonId: sermonId)
        }

        // Collect updates
        var updates: [SermonProgressUpdate] = []
        for await update in stream {
            updates.append(update)
            if updates.count >= 1 { break }
        }

        #expect(updates.count == 1)
        #expect(updates.first?.progress == 0.5)
        #expect(updates.first?.progressPercent == 50)
    }

    @Test("Multiple subscribers receive updates")
    func testMultipleSubscribers_ReceiveUpdates() async throws {
        let publisher = SermonProgressPublisher()
        let sermonId = UUID()

        let stream1 = await publisher.subscribe(to: sermonId)
        let stream2 = await publisher.subscribe(to: sermonId)

        // Both should be subscribed
        let count = await publisher.subscriptionCount(for: sermonId)
        #expect(count == 2)

        let job = SermonProcessingJob(
            sermonId: sermonId,
            transcriptionStatus: .running,
            studyGuideStatus: .pending,
            chunkStatuses: []
        )

        // Publish and complete
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            await publisher.publish(sermonId: sermonId, job: job, progress: 0.75)
            try? await Task.sleep(for: .milliseconds(50))
            await publisher.complete(sermonId: sermonId)
        }

        // Both streams should receive the update - use actor for thread-safe collection
        actor UpdateCollector {
            var updates: [SermonProgressUpdate] = []
            func append(_ update: SermonProgressUpdate) { updates.append(update) }
            func getCount() -> Int { updates.count }
        }

        let collector1 = UpdateCollector()
        let collector2 = UpdateCollector()

        // Wait with timeout using task group
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                for await update in stream1 {
                    await collector1.append(update)
                }
            }
            group.addTask {
                for await update in stream2 {
                    await collector2.append(update)
                }
            }
            group.addTask {
                try await Task.sleep(for: .seconds(1))
                throw CancellationError()
            }

            // Wait for streams to complete or timeout
            var completed = 0
            while completed < 2 {
                do {
                    try await group.next()
                    completed += 1
                } catch is CancellationError {
                    break
                }
            }
            group.cancelAll()
        }

        #expect(await collector1.getCount() >= 1)
        #expect(await collector2.getCount() >= 1)
    }

    @Test("Complete finishes stream")
    func testComplete_FinishesStream() async throws {
        let publisher = SermonProgressPublisher()
        let sermonId = UUID()

        let stream = await publisher.subscribe(to: sermonId)

        // Complete immediately
        await publisher.complete(sermonId: sermonId)

        // Stream should finish without yielding
        var count = 0
        for await _ in stream {
            count += 1
        }

        #expect(count == 0)
    }

    @Test("Complete with error yields final state")
    func testCompleteWithError_YieldsFinalState() async throws {
        let publisher = SermonProgressPublisher()
        let sermonId = UUID()

        let stream = await publisher.subscribe(to: sermonId)

        let job = SermonProcessingJob(
            sermonId: sermonId,
            transcriptionStatus: .failed,
            studyGuideStatus: .pending,
            chunkStatuses: []
        )

        // Complete with error in a separate task
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            await publisher.completeWithError(sermonId: sermonId, job: job)
        }

        // Should receive one update then finish
        var updates: [SermonProgressUpdate] = []
        for await update in stream {
            updates.append(update)
        }

        #expect(updates.count == 1)
        #expect(updates.first?.progress == 1.0)
        #expect(updates.first?.job.transcriptionStatus == .failed)
    }

    @Test("Subscription count tracks correctly")
    func testSubscriptionCount() async {
        let publisher = SermonProgressPublisher()
        let sermonId = UUID()

        #expect(await publisher.subscriptionCount(for: sermonId) == 0)

        let stream1 = await publisher.subscribe(to: sermonId)
        #expect(await publisher.subscriptionCount(for: sermonId) == 1)

        let stream2 = await publisher.subscribe(to: sermonId)
        #expect(await publisher.subscriptionCount(for: sermonId) == 2)

        // Complete to clean up
        await publisher.complete(sermonId: sermonId)

        // Give time for cleanup
        try? await Task.sleep(for: .milliseconds(100))

        // Iterate to consume (triggers cleanup)
        for await _ in stream1 { break }
        for await _ in stream2 { break }

        // After completion, subscriptions should be cleaned up
        #expect(await publisher.subscriptionCount(for: sermonId) == 0)
    }

    @Test("Total subscription count")
    func testTotalSubscriptionCount() async {
        let publisher = SermonProgressPublisher()
        let sermon1 = UUID()
        let sermon2 = UUID()

        #expect(await publisher.totalSubscriptionCount == 0)

        _ = await publisher.subscribe(to: sermon1)
        #expect(await publisher.totalSubscriptionCount == 1)

        _ = await publisher.subscribe(to: sermon2)
        #expect(await publisher.totalSubscriptionCount == 2)

        _ = await publisher.subscribe(to: sermon1)
        #expect(await publisher.totalSubscriptionCount == 3)
    }

    @Test("Progress percent calculation")
    func testProgressPercent() {
        let job = SermonProcessingJob(
            sermonId: UUID(),
            transcriptionStatus: .running,
            studyGuideStatus: .pending,
            chunkStatuses: []
        )

        let update1 = SermonProgressUpdate(job: job, progress: 0.0)
        #expect(update1.progressPercent == 0)

        let update2 = SermonProgressUpdate(job: job, progress: 0.5)
        #expect(update2.progressPercent == 50)

        let update3 = SermonProgressUpdate(job: job, progress: 1.0)
        #expect(update3.progressPercent == 100)

        let update4 = SermonProgressUpdate(job: job, progress: 0.333)
        #expect(update4.progressPercent == 33)
    }

    // MARK: - Cancellation Tests

    @Test("Cancelled task cleans up subscription")
    func testCancellation_CleansUpSubscription() async throws {
        let publisher = SermonProgressPublisher()
        let sermonId = UUID()

        // Create a task that subscribes and then gets cancelled
        let task = Task {
            let stream = await publisher.subscribe(to: sermonId)
            for await _ in stream {
                // Wait indefinitely (will be cancelled)
            }
        }

        // Give time for subscription
        try await Task.sleep(for: .milliseconds(50))
        #expect(await publisher.subscriptionCount(for: sermonId) == 1)

        // Cancel the task
        task.cancel()

        // Give time for cancellation to propagate
        try await Task.sleep(for: .milliseconds(100))

        // Subscription should be cleaned up
        #expect(await publisher.subscriptionCount(for: sermonId) == 0)
    }

    // MARK: - Convenience Extension Tests

    @Test("Progress stream convenience method works")
    func testProgressStream_ConvenienceMethod() async {
        let publisher = SermonProgressPublisher.shared
        let sermonId = UUID()

        // Use the nonisolated convenience method
        let stream = publisher.progressStream(for: sermonId)

        // Should work without await
        #expect(stream != nil)
    }
}

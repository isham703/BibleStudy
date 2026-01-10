import Foundation
import BackgroundTasks

// MARK: - Sermon Background Task Service
// Manages background processing for sermon uploads and sync operations.
// Uses BGTaskScheduler to continue work when app moves to background.

@MainActor
final class SermonBackgroundTaskService {

    // MARK: - Task Identifiers

    enum TaskIdentifier: String, CaseIterable {
        case upload = "com.biblestudy.sermon.upload"
        case sync = "com.biblestudy.sermon.sync"
    }

    // MARK: - Singleton

    static let shared = SermonBackgroundTaskService()

    // MARK: - Dependencies

    private let syncService = SermonSyncService.shared
    private let repository = SermonRepository.shared

    // MARK: - State

    private(set) var isUploadScheduled: Bool = false
    private(set) var isSyncScheduled: Bool = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Registration

    /// Register all background task handlers. Call this from app initialization.
    func registerBackgroundTasks() {
        for identifier in TaskIdentifier.allCases {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: identifier.rawValue,
                using: nil
            ) { [weak self] task in
                Task { @MainActor [weak self] in
                    await self?.handleBackgroundTask(task)
                }
            }
        }

        print("[SermonBackgroundTaskService] Registered background tasks")
    }

    // MARK: - Scheduling

    /// Schedule a background upload task for pending sermon chunks.
    /// Call this when the app moves to background with pending uploads.
    func scheduleUploadTask() {
        guard !isUploadScheduled else {
            print("[SermonBackgroundTaskService] Upload task already scheduled")
            return
        }

        do {
            let request = BGProcessingTaskRequest(identifier: TaskIdentifier.upload.rawValue)
            request.requiresNetworkConnectivity = true
            request.requiresExternalPower = false

            // Give the system a deadline for starting the task
            request.earliestBeginDate = Date(timeIntervalSinceNow: 60) // Start within 1 minute

            try BGTaskScheduler.shared.submit(request)
            isUploadScheduled = true

            print("[SermonBackgroundTaskService] Scheduled upload task")
        } catch {
            print("[SermonBackgroundTaskService] Failed to schedule upload task: \(error)")
        }
    }

    /// Schedule a background sync task for pending sermon data.
    /// Call this when the app moves to background with unsynchronized data.
    func scheduleSyncTask() {
        guard !isSyncScheduled else {
            print("[SermonBackgroundTaskService] Sync task already scheduled")
            return
        }

        do {
            let request = BGAppRefreshTaskRequest(identifier: TaskIdentifier.sync.rawValue)
            request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes

            try BGTaskScheduler.shared.submit(request)
            isSyncScheduled = true

            print("[SermonBackgroundTaskService] Scheduled sync task")
        } catch {
            print("[SermonBackgroundTaskService] Failed to schedule sync task: \(error)")
        }
    }

    /// Schedule background tasks if there's pending work.
    /// Call this when the app is about to enter background.
    func scheduleTasksIfNeeded() {
        Task { @MainActor in
            // Check for pending uploads
            do {
                let pendingChunks = try repository.fetchChunksNeedingSync()
                let hasUnuploadedChunks = pendingChunks.contains { $0.uploadStatus != .succeeded }

                if hasUnuploadedChunks {
                    scheduleUploadTask()
                }

                // Check for pending sync
                let pendingSermons = try repository.fetchSermonsNeedingSync()
                let pendingTranscripts = try repository.fetchTranscriptsNeedingSync()
                let pendingGuides = try repository.fetchStudyGuidesNeedingSync()

                if !pendingSermons.isEmpty || !pendingTranscripts.isEmpty || !pendingGuides.isEmpty {
                    scheduleSyncTask()
                }
            } catch {
                print("[SermonBackgroundTaskService] Error checking pending work: \(error)")
            }
        }
    }

    // MARK: - Task Handling

    private func handleBackgroundTask(_ task: BGTask) async {
        guard let identifier = TaskIdentifier(rawValue: task.identifier) else {
            print("[SermonBackgroundTaskService] Unknown task identifier: \(task.identifier)")
            task.setTaskCompleted(success: false)
            return
        }

        print("[SermonBackgroundTaskService] Handling \(identifier.rawValue)")

        // Set up expiration handler
        task.expirationHandler = { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleTaskExpiration(identifier)
            }
        }

        switch identifier {
        case .upload:
            await handleUploadTask(task)
        case .sync:
            await handleSyncTask(task)
        }
    }

    private func handleUploadTask(_ task: BGTask) async {
        isUploadScheduled = false

        do {
            // Find chunks that need uploading
            let pendingChunks = try repository.fetchChunksNeedingSync()
            let chunksToUpload = pendingChunks.filter { $0.uploadStatus != .succeeded }

            var successCount = 0

            for chunk in chunksToUpload {
                // Check if task is about to expire
                if Task.isCancelled { break }

                guard let localPath = chunk.localPath else { continue }

                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: localPath))
                    _ = try await syncService.uploadChunk(chunk, data: data)
                    successCount += 1
                } catch {
                    print("[SermonBackgroundTaskService] Upload failed for chunk \(chunk.id): \(error)")
                }
            }

            print("[SermonBackgroundTaskService] Uploaded \(successCount)/\(chunksToUpload.count) chunks")
            task.setTaskCompleted(success: successCount > 0)

            // Schedule another task if there's more work
            if successCount < chunksToUpload.count {
                scheduleUploadTask()
            }

        } catch {
            print("[SermonBackgroundTaskService] Upload task failed: \(error)")
            task.setTaskCompleted(success: false)
        }
    }

    private func handleSyncTask(_ task: BGTask) async {
        isSyncScheduled = false

        do {
            // Perform sync
            await syncService.loadSermons()

            print("[SermonBackgroundTaskService] Sync completed")
            task.setTaskCompleted(success: true)

            // Schedule next sync if there's still pending work
            let pendingSermons = try repository.fetchSermonsNeedingSync()
            if !pendingSermons.isEmpty {
                scheduleSyncTask()
            }

        } catch {
            print("[SermonBackgroundTaskService] Sync task failed: \(error)")
            task.setTaskCompleted(success: false)
        }
    }

    private func handleTaskExpiration(_ identifier: TaskIdentifier) {
        print("[SermonBackgroundTaskService] Task \(identifier.rawValue) expired")

        // Reset scheduling state so we can reschedule
        switch identifier {
        case .upload:
            isUploadScheduled = false
        case .sync:
            isSyncScheduled = false
        }
    }

    // MARK: - Testing Support

    #if DEBUG
    /// Simulate a background task for testing.
    /// Use this in the debugger or test code.
    func simulateBackgroundTask(_ identifier: TaskIdentifier) async {
        print("[SermonBackgroundTaskService] Simulating \(identifier.rawValue)")

        switch identifier {
        case .upload:
            do {
                let pendingChunks = try repository.fetchChunksNeedingSync()
                let chunksToUpload = pendingChunks.filter { $0.uploadStatus != .succeeded }
                print("[SermonBackgroundTaskService] Found \(chunksToUpload.count) chunks to upload")
            } catch {
                print("[SermonBackgroundTaskService] Simulation failed: \(error)")
            }
        case .sync:
            await syncService.loadSermons()
        }
    }
    #endif
}

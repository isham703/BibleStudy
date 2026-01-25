import Foundation
import Supabase

// MARK: - JWT Refresh Manager
// Actor that handles JWT token refresh with in-flight task coalescing and exponential backoff

actor JWTRefreshManager {
    // MARK: - Singleton

    static let shared = JWTRefreshManager()

    // MARK: - Dependencies

    private let supabase = SupabaseManager.shared

    // MARK: - State

    private var lastRefreshTime: Date?
    private var inFlightTask: Task<Void, Error>?
    private let minimumRefreshInterval: TimeInterval = 10

    // MARK: - Configuration

    private let maxRetries = 3
    private let baseDelaySeconds: Double = 1.0

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Refresh JWT token if needed, with coalescing of concurrent requests
    /// - Throws: SermonSyncError if refresh fails after retries
    func refreshIfNeeded() async throws {
        // Return existing in-flight task if one is running (coalescing)
        if let task = inFlightTask {
            return try await task.value
        }

        // Skip if recently refreshed
        if let lastRefresh = lastRefreshTime,
           Date().timeIntervalSince(lastRefresh) < minimumRefreshInterval {
            return
        }

        // Create and track new task
        // Note: defer is inside Task to avoid clearing inFlightTask on caller cancellation
        let task = Task { [weak self] in
            guard let self = self else { return }
            defer { Task { await self.clearInFlightTask() } }
            try await self.performRefresh()
        }

        inFlightTask = task
        try await task.value
    }

    /// Force refresh the JWT token (bypasses minimum interval check)
    /// - Throws: SermonSyncError if refresh fails after retries
    func forceRefresh() async throws {
        // Wait for any in-flight task first
        if let task = inFlightTask {
            try await task.value
            return
        }

        // Note: defer is inside Task to avoid clearing inFlightTask on caller cancellation
        let task = Task { [weak self] in
            guard let self = self else { return }
            defer { Task { await self.clearInFlightTask() } }
            try await self.performRefresh()
        }

        inFlightTask = task
        try await task.value
    }

    /// Clear in-flight task (called from within the refresh Task)
    private func clearInFlightTask() {
        inFlightTask = nil
    }

    // MARK: - Private

    private func performRefresh() async throws {
        var lastError: Error?

        for attempt in 0..<maxRetries {
            try Task.checkCancellation()

            do {
                _ = try await supabase.client.auth.refreshSession()
                lastRefreshTime = Date()
                return
            } catch {
                lastError = error

                // Don't retry on the last attempt
                guard attempt < maxRetries - 1 else { break }

                // Exponential backoff with jitter
                let baseDelay = pow(2.0, Double(attempt)) * baseDelaySeconds
                let jitter = Double.random(in: 0...0.5)
                let delay = baseDelay + jitter

                try await Task.sleep(for: .seconds(delay))
            }
        }

        throw SermonSyncError(
            operation: .jwtRefresh,
            underlyingError: lastError ?? SermonError.authorizationFailed,
            isRetryable: true,
            failureScope: .remote
        )
    }

    // MARK: - Testing Support

    #if DEBUG
    /// Reset state for testing
    func reset() {
        lastRefreshTime = nil
        inFlightTask = nil
    }
    #endif
}

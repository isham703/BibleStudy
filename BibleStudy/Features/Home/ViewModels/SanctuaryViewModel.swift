import SwiftUI

// MARK: - Sanctuary View Model
// Centralized state management for the Sanctuary Home feature
// Follows BibleReaderViewModel pattern with proper lifecycle management

@Observable
@MainActor
final class SanctuaryViewModel {
    // MARK: - Dependencies

    private let progressService: ProgressService
    private let authService: AuthService

    // MARK: - Time State

    var currentTime: SanctuaryTimeOfDay = .current
    var manualOverride: SanctuaryTimeOfDay?

    /// Active time considers manual override for debug/preview
    var activeTime: SanctuaryTimeOfDay {
        manualOverride ?? currentTime
    }

    // MARK: - User Data

    var userName: String? {
        authService.userProfile?.displayName
    }

    var currentStreak: Int {
        progressService.currentStreak
    }

    var graceDayUsed: Bool {
        progressService.graceDaysRemaining < 1
    }

    // MARK: - Lifecycle State

    private var timeUpdateTask: Task<Void, Never>?
    var scenePhase: ScenePhase = .active
    var reduceMotion: Bool = false

    /// Whether animations should be running
    var shouldAnimate: Bool {
        !isPaused
    }

    /// Whether the view is paused (backgrounded or reduce motion enabled)
    var isPaused: Bool {
        scenePhase != .active || reduceMotion
    }

    // MARK: - Initialization

    init(
        progressService: ProgressService = .shared,
        authService: AuthService = .shared
    ) {
        self.progressService = progressService
        self.authService = authService
    }

    // MARK: - Data Loading

    /// Load user data from services
    func loadUserData() async {
        await progressService.loadProgress()
        try? await authService.loadProfile()
    }

    // MARK: - Time Updates

    /// Start background time updates (Task-based, properly cancellable)
    func startTimeUpdates() {
        // Cancel any existing task
        stopTimeUpdates()

        timeUpdateTask = Task { [weak self] in
            while !Task.isCancelled {
                // Sleep for 60 seconds
                try? await Task.sleep(for: .seconds(60))

                guard !Task.isCancelled else { return }

                // Only update if no manual override
                await MainActor.run {
                    guard let self = self, self.manualOverride == nil else { return }

                    let newTime = SanctuaryTimeOfDay.current
                    if newTime != self.currentTime {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            self.currentTime = newTime
                        }
                    }
                }
            }
        }
    }

    /// Stop time updates (explicit cleanup)
    func stopTimeUpdates() {
        timeUpdateTask?.cancel()
        timeUpdateTask = nil
    }

    /// Full reset for cleanup
    func cleanup() {
        stopTimeUpdates()
        manualOverride = nil
    }

    // MARK: - Scene Phase Handling

    /// Update scene phase and pause/resume animations accordingly
    func updateScenePhase(_ phase: ScenePhase) {
        scenePhase = phase
    }

    /// Update reduce motion preference
    func updateReduceMotion(_ reduce: Bool) {
        reduceMotion = reduce
    }
}

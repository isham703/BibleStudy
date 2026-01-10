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

    /// Full reset for cleanup
    func cleanup() {
        // No cleanup needed currently
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

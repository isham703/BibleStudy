import SwiftUI

// MARK: - Sanctuary Data Adapter
// Bridges HomeShowcase views to real app services
// Provides live data from ProgressService and AuthService

@MainActor
@Observable
final class SanctuaryDataAdapter {
    // MARK: - Singleton
    static let shared = SanctuaryDataAdapter()

    // MARK: - Services
    private let progressService = ProgressService.shared
    private let authService = AuthService.shared

    // MARK: - Initialization
    private init() {}

    // MARK: - User Data

    /// User's display name (falls back to "friend" if not available)
    var userName: String? {
        authService.userProfile?.displayName
    }

    /// Current streak from ProgressService
    var currentStreak: Int {
        progressService.currentStreak
    }

    /// Whether grace day was used today
    var graceDayUsed: Bool {
        // Grace day is used when graceDaysRemaining < max (1 for free, 3 for premium)
        progressService.graceDaysRemaining < 1
    }

    /// Mock-compatible user data for Sanctuary views
    var userData: MockUserData {
        MockUserData(
            userName: userName,
            currentStreak: currentStreak,
            graceDayUsed: graceDayUsed
        )
    }

    // MARK: - Loading

    /// Load user data from services
    func loadData() async {
        await progressService.loadProgress()
        try? await authService.loadProfile()
    }
}

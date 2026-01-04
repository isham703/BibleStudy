import SwiftUI

// MARK: - Sanctuary Data Adapter (Showcase Stub)
// Provides mock data for HomeShowcase previews

@MainActor
@Observable
final class SanctuaryDataAdapter {
    static let shared = SanctuaryDataAdapter()

    private init() {}

    // MARK: - Mock User Data for Previews

    var userName: String? { "Sarah" }
    var currentStreak: Int { 14 }
    var graceDayUsed: Bool { false }

    var userData: MockUserData {
        MockUserData(
            userName: userName,
            currentStreak: currentStreak,
            graceDayUsed: graceDayUsed
        )
    }
}

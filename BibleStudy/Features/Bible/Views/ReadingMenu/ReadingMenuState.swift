import SwiftUI

// MARK: - Reading Menu State
// Centralized @Observable state for BibleReadingMenuSheet
// Manages view navigation, search state, and settings expansion

@Observable
@MainActor
final class ReadingMenuState {
    // MARK: - View Navigation

    enum MenuView {
        case menu
        case search
        case settings
        case insights
    }

    var currentView: MenuView = .menu

    // MARK: - Search State

    var query = ""
    var results: [SearchService.SearchResult] = []
    var isSearching = false
    var searchTask: Task<Void, Never>?

    // MARK: - Settings State

    var showAdvanced = false

    // MARK: - Animation

    let animation: Animation = .snappy(duration: 0.3, extraBounce: 0)

    // MARK: - Actions

    func resetSearch() {
        query = ""
        results = []
        isSearching = false
        searchTask?.cancel()
        searchTask = nil
    }

    func navigateToMenu() {
        withAnimation(animation) {
            currentView = .menu
            resetSearch()
        }
    }

    func navigateToSearch() {
        withAnimation(animation) {
            currentView = .search
        }
    }

    func navigateToSettings() {
        withAnimation(animation) {
            currentView = .settings
        }
    }

    func navigateToInsights() {
        withAnimation(animation) {
            currentView = .insights
        }
    }
}

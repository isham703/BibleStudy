import SwiftUI

// MARK: - Insight Sheet State
// Centralized @Observable state for BibleInsightSheet
// Manages dismiss callbacks to eliminate manual callback threading
// Child views call state.dismissAll() instead of threading closures

@Observable
@MainActor
final class InsightSheetState {
    // MARK: - Callbacks (set by root sheet)

    /// Dismiss entire sheet stack and navigate to reference
    var onNavigateToReference: ((String) -> Void)?

    /// Dismiss entire sheet stack
    var onDismissAll: (() -> Void)?

    // MARK: - Data

    /// The verse being displayed
    var verse: Verse?

    /// All insights for the verse
    var insights: [BibleInsight] = []

    // MARK: - Loading State

    /// Active async tasks (for cancellation on dismiss)
    private var activeTasks: [String: Task<Void, Never>] = [:]

    // MARK: - Computed Properties

    /// Connection-type insights
    var connections: [BibleInsight] {
        insights.filter { $0.insightType == .connection }
    }

    /// All sources from non-connection insights
    var allSources: [InsightSource] {
        insights.filter { $0.insightType != .connection }
            .flatMap { $0.sources }
    }

    // MARK: - Actions

    /// Dismiss all sheets and navigate to a reference
    func navigateToReference(_ reference: String) {
        onNavigateToReference?(reference)
    }

    /// Dismiss entire sheet stack
    func dismissAll() {
        onDismissAll?()
    }

    // MARK: - Task Management

    /// Register an async task for cancellation on dismiss
    func registerTask(_ task: Task<Void, Never>, id: String) {
        activeTasks[id] = task
    }

    /// Cancel a specific task
    func cancelTask(id: String) {
        activeTasks[id]?.cancel()
        activeTasks.removeValue(forKey: id)
    }

    /// Cancel all active tasks (call on sheet dismiss)
    func cancelAllTasks() {
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
    }

    // MARK: - Configuration

    /// Configure state for a new verse presentation
    func configure(
        verse: Verse,
        insights: [BibleInsight],
        onDismissAll: @escaping () -> Void,
        onNavigateToReference: ((String) -> Void)?
    ) {
        self.verse = verse
        self.insights = insights
        self.onDismissAll = onDismissAll
        self.onNavigateToReference = onNavigateToReference
    }

    /// Reset all state (call when sheet closes)
    func reset() {
        cancelAllTasks()
        verse = nil
        insights = []
        onDismissAll = nil
        onNavigateToReference = nil
    }
}

// MARK: - Environment Key

private struct InsightSheetStateKey: EnvironmentKey {
    static let defaultValue: InsightSheetState? = nil
}

extension EnvironmentValues {
    var insightSheetState: InsightSheetState? {
        get { self[InsightSheetStateKey.self] }
        set { self[InsightSheetStateKey.self] = newValue }
    }
}

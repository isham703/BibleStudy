import SwiftUI

// MARK: - Coach Mark Manager
// Tracks which coach marks have been seen and manages their presentation

@MainActor
@Observable
final class CoachMarkManager {
    static let shared = CoachMarkManager()

    // MARK: - Coach Mark Keys

    private enum Keys {
        static let highlightTutorial = "hasSeenHighlightCoachMark"
        static let multiSelectTutorial = "hasSeenMultiSelectCoachMark"
        static let categoryTutorial = "hasSeenCategoryCoachMark"
    }

    // MARK: - State

    /// Currently showing coach mark type (nil = none)
    private(set) var currentCoachMark: CoachMarkType?

    /// Whether a coach mark is currently being displayed
    var isShowingCoachMark: Bool { currentCoachMark != nil }

    // MARK: - User Defaults

    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Check if Should Show

    /// Returns true if the highlight tutorial should be shown
    var shouldShowHighlightTutorial: Bool {
        !defaults.bool(forKey: Keys.highlightTutorial)
    }

    /// Returns true if the multi-select tutorial should be shown
    var shouldShowMultiSelectTutorial: Bool {
        !defaults.bool(forKey: Keys.multiSelectTutorial)
    }

    /// Returns true if the category tutorial should be shown
    var shouldShowCategoryTutorial: Bool {
        !defaults.bool(forKey: Keys.categoryTutorial)
    }

    // MARK: - Show Coach Marks

    /// Shows the highlight tutorial coach mark
    func showHighlightTutorial() {
        guard shouldShowHighlightTutorial else { return }
        currentCoachMark = .highlightTutorial
    }

    /// Shows the multi-select tutorial coach mark
    func showMultiSelectTutorial() {
        guard shouldShowMultiSelectTutorial else { return }
        currentCoachMark = .multiSelectTutorial
    }

    /// Shows the category tutorial coach mark
    func showCategoryTutorial() {
        guard shouldShowCategoryTutorial else { return }
        currentCoachMark = .categoryTutorial
    }

    // MARK: - Dismiss

    /// Dismisses the current coach mark and marks it as seen
    func dismissCurrentCoachMark() {
        guard let coachMark = currentCoachMark else { return }

        // Mark as seen
        switch coachMark {
        case .highlightTutorial:
            defaults.set(true, forKey: Keys.highlightTutorial)
        case .multiSelectTutorial:
            defaults.set(true, forKey: Keys.multiSelectTutorial)
        case .categoryTutorial:
            defaults.set(true, forKey: Keys.categoryTutorial)
        }

        // Haptic feedback
        HapticService.shared.lightTap()

        // Animate out
        withAnimation(Theme.Animation.fade) {
            currentCoachMark = nil
        }
    }

    /// Dismisses coach mark with "Begin" action (celebratory)
    func beginFromCoachMark() {
        guard currentCoachMark != nil else { return }

        // Celebratory haptic
        HapticService.shared.correctAnswer()

        // Mark as seen and dismiss
        dismissCurrentCoachMark()
    }

    /// Dismisses coach mark with "Later" action (deferred)
    func dismissForLater() {
        guard currentCoachMark != nil else { return }

        // Light haptic
        HapticService.shared.lightTap()

        // Animate out (but don't mark as seen)
        withAnimation(Theme.Animation.fade) {
            currentCoachMark = nil
        }
    }

    // MARK: - Reset (for testing)

    /// Resets all coach marks to unseen (for testing/debugging)
    func resetAllCoachMarks() {
        defaults.removeObject(forKey: Keys.highlightTutorial)
        defaults.removeObject(forKey: Keys.multiSelectTutorial)
        defaults.removeObject(forKey: Keys.categoryTutorial)
    }
}

// MARK: - Coach Mark Types

enum CoachMarkType: Equatable {
    case highlightTutorial
    case multiSelectTutorial
    case categoryTutorial

    var title: String {
        switch self {
        case .highlightTutorial:
            return "ILLUMINATOR'S TIP"
        case .multiSelectTutorial:
            return "SCRIBE'S SECRET"
        case .categoryTutorial:
            return "SCHOLAR'S NOTE"
        }
    }

    var message: String {
        switch self {
        case .highlightTutorial:
            return "Tap any verse to reveal its hidden wisdom and mark it for your journey."
        case .multiSelectTutorial:
            return "Hold a verse to begin a range selection, then tap another to highlight an entire passage."
        case .categoryTutorial:
            return "Long-press a color to assign a category like Promise, Command, or Prophecy to organize your highlights."
        }
    }

    var icon: String {
        switch self {
        case .highlightTutorial:
            return "sparkle"
        case .multiSelectTutorial:
            return "selection.pin.in.out"
        case .categoryTutorial:
            return "tag.fill"
        }
    }
}

// MARK: - Environment Key

private struct CoachMarkManagerKey: EnvironmentKey {
    static let defaultValue = CoachMarkManager.shared
}

extension EnvironmentValues {
    var coachMarkManager: CoachMarkManager {
        get { self[CoachMarkManagerKey.self] }
        set { self[CoachMarkManagerKey.self] = newValue }
    }
}

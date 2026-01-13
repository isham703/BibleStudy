import UIKit

// MARK: - Haptic Service
// Centralized haptic feedback manager with patterns for different interactions
// Respects user's hapticFeedbackEnabled preference from Settings

@MainActor
final class HapticService {
    static let shared = HapticService()

    // MARK: - User Preference
    /// Check if haptic feedback is enabled in user settings
    private var isEnabled: Bool {
        // Default to true if not set
        UserDefaults.standard.object(forKey: AppConfiguration.UserDefaultsKeys.hapticFeedbackEnabled) as? Bool ?? true
    }

    // MARK: - Feedback Generators
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        // Pre-warm generators for faster response
        prepareGenerators()
    }

    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    // MARK: - Basic Haptics

    /// Light tap - for subtle UI interactions
    func lightTap() {
        guard isEnabled else { return }
        impactLight.impactOccurred()
    }

    /// Medium tap - for standard button presses
    func mediumTap() {
        guard isEnabled else { return }
        impactMedium.impactOccurred()
    }

    /// Heavy tap - for significant actions
    func heavyTap() {
        guard isEnabled else { return }
        impactHeavy.impactOccurred()
    }

    /// Soft tap - for gentle feedback
    func softTap() {
        guard isEnabled else { return }
        impactSoft.impactOccurred()
    }

    /// Rigid tap - for precise feedback
    func rigidTap() {
        guard isEnabled else { return }
        impactRigid.impactOccurred()
    }

    /// Selection changed - for picker/selection changes
    func selectionChanged() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
    }

    /// Success notification
    func success() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }

    /// Warning notification
    func warning() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Error notification
    func error() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
    }

    // MARK: - Celebration Patterns

    /// Correct answer celebration - rising success pattern
    func correctAnswer() {
        guard isEnabled else { return }
        // Quick ascending pattern
        impactLight.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [self] in
            impactMedium.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { [self] in
            notificationGenerator.notificationOccurred(.success)
        }
    }

    /// Wrong answer - sharp warning pattern
    func wrongAnswer() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.error)

        // Double tap for emphasis
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            impactRigid.impactOccurred()
        }
    }

    /// First verse mastered - triumphant celebration
    func firstVerseMastered() {
        guard isEnabled else { return }
        // Building excitement
        impactSoft.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            impactLight.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            impactMedium.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [self] in
            impactHeavy.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            notificationGenerator.notificationOccurred(.success)
        }
    }

    /// Streak milestone - rhythmic pulsing pattern
    func streakMilestone(count: Int) {
        guard isEnabled else { return }
        // Number of pulses based on milestone tier
        let pulseCount = min(count / 7 + 1, 4)

        for i in 0..<pulseCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.12) { [self] in
                impactMedium.impactOccurred()
            }
        }

        // Final success
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(pulseCount) * 0.12 + 0.1) { [self] in
            notificationGenerator.notificationOccurred(.success)
        }
    }

    /// Level up - ascending power pattern
    func levelUp() {
        guard isEnabled else { return }
        // Crescendo effect
        impactSoft.impactOccurred(intensity: 0.3)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            impactSoft.impactOccurred(intensity: 0.5)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            impactMedium.impactOccurred(intensity: 0.7)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            impactMedium.impactOccurred(intensity: 0.9)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [self] in
            impactHeavy.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [self] in
            notificationGenerator.notificationOccurred(.success)
        }
    }

    /// Achievement unlocked - special fanfare pattern
    func achievementUnlocked() {
        guard isEnabled else { return }
        // Dramatic reveal
        impactRigid.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            impactLight.impactOccurred()
            impactLight.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [self] in
            impactMedium.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            impactHeavy.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { [self] in
            notificationGenerator.notificationOccurred(.success)
        }
    }

    /// User level up - grand celebration pattern
    func userLevelUp() {
        guard isEnabled else { return }
        // Extended crescendo for major milestone
        for i in 0..<6 {
            let intensity = 0.3 + Double(i) * 0.14
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) { [self] in
                impactMedium.impactOccurred(intensity: min(intensity, 1.0))
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [self] in
            impactHeavy.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) { [self] in
            notificationGenerator.notificationOccurred(.success)
        }
    }

    // MARK: - Interaction Patterns

    /// Button press - standard interaction
    func buttonPress() {
        guard isEnabled else { return }
        impactLight.impactOccurred()
    }

    /// Tab switch - navigation feedback
    func tabSwitch() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
    }

    /// Swipe action - gesture feedback
    func swipeAction() {
        guard isEnabled else { return }
        impactMedium.impactOccurred()
    }

    /// Long press activated
    func longPressActivated() {
        guard isEnabled else { return }
        impactHeavy.impactOccurred()
    }

    /// Pull to refresh triggered
    func pullToRefresh() {
        guard isEnabled else { return }
        impactMedium.impactOccurred()
    }

    /// Verse highlighted
    func verseHighlighted() {
        guard isEnabled else { return }
        impactLight.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            impactSoft.impactOccurred()
        }
    }

    /// Note saved
    func noteSaved() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }

    /// Bookmark added
    func bookmarkAdded() {
        guard isEnabled else { return }
        impactMedium.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            impactLight.impactOccurred()
        }
    }

    /// Verse added to memorization
    func verseAddedToMemorization() {
        guard isEnabled else { return }
        impactMedium.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            notificationGenerator.notificationOccurred(.success)
        }
    }

    /// Undo action confirmed - soft double-tap
    func undoAction() {
        guard isEnabled else { return }
        impactSoft.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [self] in
            impactSoft.impactOccurred()
        }
    }

    /// Toast appeared - subtle notification
    func toastAppeared() {
        guard isEnabled else { return }
        impactLight.impactOccurred(intensity: 0.5)
    }

    /// Category assigned confirmation
    func categoryAssigned() {
        guard isEnabled else { return }
        impactMedium.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [self] in
            selectionGenerator.selectionChanged()
        }
    }

    // MARK: - Color-Specific Haptic Patterns (Accessibility)
    // Each color has a unique rhythm so users can identify by feel

    /// Announce highlight color change with distinct pattern
    /// Each color has a unique rhythm so VoiceOver users can identify by feel
    func highlightColorAnnouncement(_ color: HighlightColor) {
        guard isEnabled else { return }
        switch color {
        case .amber:
            // Single strong tap (primary color)
            impactMedium.impactOccurred()

        case .rose:
            // Quick double tap (energetic, like passion)
            impactLight.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [self] in
                impactLight.impactOccurred()
            }

        case .blue:
            // Single light tap (calm, like still water)
            impactLight.impactOccurred()

        case .green:
            // Soft tap (earthy, grounding)
            impactSoft.impactOccurred()

        case .purple:
            // Heavy tap (royal, substantial)
            impactHeavy.impactOccurred()
        }
    }

    // MARK: - Sacred Motion Haptics (Stoic-Roman)
    // Haptic patterns synchronized with sacred motion animations

    /// Page turn - synchronized with page curl gesture
    /// Light tap → threshold feedback → paper snap
    func pageTurn(progress: CGFloat) {
        guard isEnabled else { return }
        if progress < 0.3 {
            // Initial light touch
            impactLight.impactOccurred(intensity: 0.3)
        } else if progress > 0.7 {
            // Crossing threshold
            impactMedium.impactOccurred(intensity: 0.6)
        }
    }

    /// Page turn completed - final snap
    func pageTurnComplete() {
        guard isEnabled else { return }
        impactMedium.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
            impactLight.impactOccurred(intensity: 0.4)
        }
    }

    /// Page turn cancelled - return to original position
    func pageTurnCancelled() {
        guard isEnabled else { return }
        impactSoft.impactOccurred(intensity: 0.5)
    }

    /// Verse selection - tactile confirmation
    func verseSelected() {
        guard isEnabled else { return }
        impactLight.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [self] in
            impactSoft.impactOccurred(intensity: 0.6)
        }
    }

    /// Golden burst - rapid ascending pattern for celebrations
    /// Use for: daily goal achieved, reading streak, special moments
    func goldenBurst() {
        guard isEnabled else { return }
        // Rapid ascending intensity
        for i in 0..<4 {
            let delay = Double(i) * 0.06
            let intensity = 0.4 + Double(i) * 0.15

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
                impactMedium.impactOccurred(intensity: min(intensity, 1.0))
            }
        }

        // Final success
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            notificationGenerator.notificationOccurred(.success)
        }
    }

    /// Divine reveal - building crescendo for major revelations
    /// Use for: unlocking content, revealing answers, chapter completion
    func divineReveal() {
        guard isEnabled else { return }
        // Building anticipation
        impactSoft.impactOccurred(intensity: 0.3)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            impactLight.impactOccurred(intensity: 0.5)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            impactMedium.impactOccurred(intensity: 0.7)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            impactHeavy.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { [self] in
            notificationGenerator.notificationOccurred(.success)
        }
    }

    /// Chapter begin - reverent announcement
    func chapterBegin() {
        guard isEnabled else { return }
        impactMedium.impactOccurred(intensity: 0.6)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            impactLight.impactOccurred(intensity: 0.4)
        }
    }

    /// Chapter end - gentle conclusion
    func chapterEnd() {
        guard isEnabled else { return }
        impactSoft.impactOccurred(intensity: 0.5)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            impactSoft.impactOccurred(intensity: 0.3)
        }
    }

    /// Theme changed - subtle confirmation
    func themeChanged() {
        guard isEnabled else { return }
        impactLight.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            impactSoft.impactOccurred(intensity: 0.4)
        }
    }

    /// Drop cap appeared - decorative emphasis
    func dropCapAppeared() {
        guard isEnabled else { return }
        impactLight.impactOccurred(intensity: 0.5)
    }

    /// Daily reading goal achieved - triumphant pattern
    func dailyGoalAchieved() {
        guard isEnabled else { return }
        // Similar to golden burst but more sustained
        for i in 0..<5 {
            let delay = Double(i) * 0.08
            let intensity = 0.3 + Double(i) * 0.14

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
                impactMedium.impactOccurred(intensity: min(intensity, 1.0))
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [self] in
            impactHeavy.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [self] in
            notificationGenerator.notificationOccurred(.success)
        }
    }

    /// Compassionate heartbeat - gentle, slow pulsing for crisis support
    /// Use for: crisis banner appearance, compassionate presence moments
    func compassionateHeartbeat() {
        guard isEnabled else { return }
        // Gentle double-pulse like a heartbeat
        impactSoft.impactOccurred(intensity: 0.4)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            impactSoft.impactOccurred(intensity: 0.3)
        }
    }

    /// Scroll snap - feedback when verse snaps into place
    func scrollSnap() {
        guard isEnabled else { return }
        impactLight.impactOccurred(intensity: 0.4)
    }

    /// Navigation threshold crossed - edge of content
    func navigationThreshold() {
        guard isEnabled else { return }
        impactMedium.impactOccurred(intensity: 0.5)
    }
}

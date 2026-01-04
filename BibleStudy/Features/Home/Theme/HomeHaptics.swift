import UIKit

// MARK: - Home Feature Haptics
// Tactile feedback for Home page interactions

enum HomeShowcaseHaptics {
    static func cardPress() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func cardRelease() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func navigate() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Candlelit Sanctuary Haptics (Gentle, meditative)

    static func candlelitPress() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
    }

    static func candlelitRelease() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.3)
    }

    // MARK: - Scholar's Atrium Haptics (Precise, tactile)

    static func scholarlyPress() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.6)
    }

    static func chipSelect() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Sacred Threshold Haptics (Dramatic, weighted)

    static func thresholdPress() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func roomTransition() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 0.7)
    }

    static func portalEnter() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

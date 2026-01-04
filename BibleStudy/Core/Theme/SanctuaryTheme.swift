import SwiftUI

// MARK: - Home Showcase Theme
// Design tokens for the Home Page Showcase app

enum SanctuaryTheme {

    // MARK: - Spacing Scale

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
        static let huge: CGFloat = 64
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let xs: CGFloat = 4
        static let small: CGFloat = 8
        static let card: CGFloat = 12
        static let large: CGFloat = 16
        static let sheet: CGFloat = 20
        static let pill: CGFloat = 100
    }

    // MARK: - Animation Curves

    enum Animation {
        // Quick, responsive interactions
        static let quick = SwiftUI.Animation.spring(duration: 0.25, bounce: 0.0)

        // Standard UI transitions
        static let standard = SwiftUI.Animation.spring(duration: 0.4, bounce: 0.15)

        // Sacred & Reverent - slow, meditative
        static let reverent = SwiftUI.Animation.easeOut(duration: 0.6)

        // Luminous - fast in, slow out (light appearing)
        static let luminous = SwiftUI.Animation.timingCurve(0.0, 0.0, 0.2, 1.0, duration: 0.4)

        // Contemplative - extended ease for meditative moments
        static let contemplative = SwiftUI.Animation.easeInOut(duration: 1.2)

        // Sacred spring - dignified bounce
        static let sacredSpring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.75)

        // Cinematic - dramatic entrance
        static let cinematic = SwiftUI.Animation.spring(duration: 0.6, bounce: 0.2)

        // Unfurl effect for page reveals
        static let unfurl = SwiftUI.Animation.spring(duration: 0.7, bounce: 0.15)

        // Gold shimmer loop
        static let shimmer = SwiftUI.Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)

        // Gentle pulse for ambient effects
        static let pulse = SwiftUI.Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)

        // Rotating gradient animation
        static let gradientRotation = SwiftUI.Animation.linear(duration: 8).repeatForever(autoreverses: false)

        // Float animation for chat pill
        static let float = SwiftUI.Animation.easeInOut(duration: 4).repeatForever(autoreverses: true)

        // Stagger delay helper
        static func stagger(index: Int, delay: Double = 0.08) -> SwiftUI.Animation {
            .spring(duration: 0.5, bounce: 0.15).delay(Double(index) * delay)
        }

        // Staggered entrance with sacred timing
        static func staggeredEntrance(index: Int, baseDelay: Double = 0.1) -> SwiftUI.Animation {
            sacredSpring.delay(Double(index) * baseDelay)
        }
    }

    // MARK: - Shadows

    enum Shadow {
        static let subtle = SwiftUI.Color.black.opacity(0.05)
        static let small = SwiftUI.Color.black.opacity(0.08)
        static let medium = SwiftUI.Color.black.opacity(0.12)
        static let large = SwiftUI.Color.black.opacity(0.18)
        static let dramatic = SwiftUI.Color.black.opacity(0.25)
    }

    // MARK: - Opacity

    enum Opacity {
        static let faint: Double = 0.03
        static let subtle: Double = 0.08
        static let light: Double = 0.15
        static let quarter: Double = 0.25
        static let medium: Double = 0.40
        static let half: Double = 0.50
        static let strong: Double = 0.70
        static let high: Double = 0.85
    }

    // MARK: - Component Sizes

    enum Size {
        static let cardMinHeight: CGFloat = 120
        static let cardMaxWidth: CGFloat = 400
        static let heroHeight: CGFloat = 380
        static let metricPillHeight: CGFloat = 72
        static let touchTarget: CGFloat = 44
        static let iconSmall: CGFloat = 16
        static let iconMedium: CGFloat = 24
        static let iconLarge: CGFloat = 32
        static let streakBadgeWidth: CGFloat = 60
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply staggered entrance animation
    func staggeredEntrance(index: Int, isVisible: Bool, delay: Double = 0.08) -> some View {
        self
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 30)
            .scaleEffect(isVisible ? 1 : 0.95)
            .animation(
                .spring(duration: 0.6, bounce: 0.15).delay(Double(index) * delay),
                value: isVisible
            )
    }

    /// Apply press effect with scale
    func pressEffect(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }

    /// Apply glass card style
    func glassCard() -> some View {
        self
            .background(.ultraThinMaterial.opacity(0.3))
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: SanctuaryTheme.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: SanctuaryTheme.CornerRadius.card)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
    }

    /// Accessible animation that respects reduced motion
    func accessibleAnimation<V: Equatable>(_ animation: SwiftUI.Animation?, value: V) -> some View {
        self.animation(
            UIAccessibility.isReduceMotionEnabled ? nil : animation,
            value: value
        )
    }
}

// MARK: - Haptics

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

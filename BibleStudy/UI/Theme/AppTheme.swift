import SwiftUI
import UIKit

// MARK: - App Theme
// Centralized theme configuration for the Bible Study app

struct AppTheme {
    // MARK: - Spacing
    struct Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    struct CornerRadius {
        static let xs: CGFloat = 2  // For thin indicator strips
        static let small: CGFloat = 4
        static let sm: CGFloat = 4  // Alias for small
        static let medium: CGFloat = 8
        static let md: CGFloat = 8  // Alias for medium
        static let large: CGFloat = 12
        static let lg: CGFloat = 12  // Alias for large
        static let xl: CGFloat = 16
        static let card: CGFloat = 12
        static let sheet: CGFloat = 20
        static let menu: CGFloat = 14  // Floating context menus
    }

    // MARK: - Animation
    struct Animation {
        static let quick: SwiftUI.Animation = .easeInOut(duration: 0.15)
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.25)
        static let slow: SwiftUI.Animation = .easeInOut(duration: 0.4)
        static let spring: SwiftUI.Animation = .spring(response: 0.35, dampingFraction: 0.7)

        // Celebration animations - intentionally bouncier
        static let celebrationBounce: SwiftUI.Animation = .spring(response: 0.5, dampingFraction: 0.6)
        static let celebrationSettle: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.7)

        // MARK: - Sacred Motion (Illuminated Manuscript)
        // Timing curves inspired by manuscript aesthetics and contemplative rhythm

        /// Reverent - slow, gentle transitions for major state changes
        /// Use for: theme changes, view transitions, modal presentations
        static let reverent: SwiftUI.Animation = .easeInOut(duration: 0.6)

        /// Luminous - fast-in, slow-out for light-like appearances
        /// Use for: glow effects, highlights appearing, gold accents
        static let luminous: SwiftUI.Animation = .timingCurve(0.2, 0.8, 0.2, 1.0, duration: 0.4)

        /// Contemplative - extended ease for meditative moments
        /// Use for: ambient effects, background changes, pulsing glows
        static let contemplative: SwiftUI.Animation = .easeInOut(duration: 1.2)

        /// Sacred Spring - dignified bounce without playfulness
        /// Use for: selection feedback, card appearances, emphasis
        static let sacredSpring: SwiftUI.Animation = .spring(response: 0.5, dampingFraction: 0.85)

        /// Unfurl - scroll-like reveal animation
        /// Use for: content reveals, list appearances, vertical transitions
        static let unfurl: SwiftUI.Animation = .timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.7)

        /// Golden Ratio - phi-based harmonious movement (1.618)
        /// Use for: proportional animations, balanced transitions
        static let goldenRatio: SwiftUI.Animation = .timingCurve(0.382, 0.0, 0.618, 1.0, duration: 0.5)

        /// Page Turn - synchronized with physical page curl gesture
        /// Use for: page transitions, swipe navigation
        static let pageTurn: SwiftUI.Animation = .spring(response: 0.4, dampingFraction: 0.9)

        /// Shimmer - repeating animation for gold shimmer effects
        /// Use for: gold highlights, decorative elements
        static let shimmer: SwiftUI.Animation = .easeInOut(duration: 2.0).repeatForever(autoreverses: true)

        /// Pulse - gentle pulsing for ambient effects
        /// Use for: glows, selections, attention indicators
        static let pulse: SwiftUI.Animation = .easeInOut(duration: 3.0).repeatForever(autoreverses: true)

        /// Sacred Rotation - very slow continuous rotation for decorative elements
        /// Use for: sacred geometry, mandala patterns, ambient decorations
        static let sacredRotation: SwiftUI.Animation = .linear(duration: 20).repeatForever(autoreverses: false)

        /// Sacred Rotation Fast - faster rotation for compact elements
        /// Use for: smaller decorative elements, compact sacred geometry
        static let sacredRotationFast: SwiftUI.Animation = .linear(duration: 15).repeatForever(autoreverses: false)

        /// Celestial Rotation - for loading indicators and compact animations
        /// Use for: audio loading spinners, progress indicators
        static let celestialRotation: SwiftUI.Animation = .linear(duration: 8).repeatForever(autoreverses: false)

        /// Breathing Pulse - gentle scale animation for ambient effects
        /// Use for: glowing elements, breathing animations, focus indicators
        static let breathingPulse: SwiftUI.Animation = .easeInOut(duration: 2).repeatForever(autoreverses: true)

        /// Shimmer Continuous - linear shimmer for gold leaf effects
        /// Use for: shimmer overlays, light sweeps, metallic highlights
        static let shimmerContinuous: SwiftUI.Animation = .linear(duration: 2.5).repeatForever(autoreverses: false)

        /// Meditative Pulse - extended pulse for contemplative UI elements
        /// Use for: thinking indicators, breathing animations
        static let meditativePulse: SwiftUI.Animation = .easeInOut(duration: 4.0).repeatForever(autoreverses: true)

        /// Circle Wave - for sequential illumination effects
        /// Use for: circle animations, wave patterns
        static let circleWave: SwiftUI.Animation = .easeInOut(duration: 0.6)

        /// Keyboard Sync - tuned to match iOS 26 keyboard animation timing
        /// Use for: input bar expansion, layout morphs synced with keyboard
        /// iOS 26 keyboard animates faster (0.22s) than previous versions
        static let keyboardSync: SwiftUI.Animation = .easeOut(duration: 0.22)

        // MARK: - Scholar Component Animations
        // Refined animations for reader UI components

        /// Menu appear - smooth spring for context menus
        static let menuAppear: SwiftUI.Animation = .spring(response: 0.35, dampingFraction: 0.8)

        /// Selection - quick ease for verse/item selection
        static let selection: SwiftUI.Animation = .easeOut(duration: 0.2)

        /// Card unfurl - elegant spring for insight cards expanding
        static let cardUnfurl: SwiftUI.Animation = .spring(response: 0.4, dampingFraction: 0.85)

        /// Chip expand - snappy spring for filter chips
        static let chipExpand: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.8)

        // MARK: - Reduced Motion Support

        /// Returns true when user has enabled "Reduce Motion" in Accessibility settings
        static var isReduceMotionEnabled: Bool {
            UIAccessibility.isReduceMotionEnabled
        }

        /// Returns the animation or nil if reduce motion is enabled
        /// Usage: .animation(AppTheme.Animation.reduced(.standard), value: state)
        static func reduced(_ animation: SwiftUI.Animation) -> SwiftUI.Animation? {
            isReduceMotionEnabled ? nil : animation
        }

        /// Returns a subtle fade animation when reduce motion is enabled, otherwise the original
        /// Use for important state changes that need some visual feedback
        static func accessible(_ animation: SwiftUI.Animation) -> SwiftUI.Animation {
            isReduceMotionEnabled ? .easeInOut(duration: 0.1) : animation
        }
    }

    // MARK: - Shadows
    struct Shadow {
        static let small = ShadowStyle(color: .black.opacity(Opacity.shadowSmall), radius: 2, x: 0, y: 1)
        static let medium = ShadowStyle(color: .black.opacity(Opacity.shadowMedium), radius: 8, x: 0, y: 4)
        static let large = ShadowStyle(color: .black.opacity(Opacity.shadowLarge), radius: 16, x: 0, y: 8)
        /// Floating menu shadow with soft drop
        static let menu = ShadowStyle(color: .black.opacity(Opacity.shadowMenu), radius: 16, x: 0, y: 6)
        /// Menu shadow for dark mode (more pronounced)
        static let menuDark = ShadowStyle(color: .black.opacity(Opacity.shadowMenuDark), radius: 16, x: 0, y: 6)
        /// Indigo glow effect for accented elements
        static let indigoGlow = ShadowStyle(color: Color.scholarIndigo.opacity(Opacity.shadowGoldGlow), radius: 8, x: 0, y: 0)

        /// Legacy alias for goldGlow
        @available(*, deprecated, renamed: "indigoGlow")
        static var goldGlow: ShadowStyle { indigoGlow }
        /// Alias for small (common card usage)
        static let card = small

        // MARK: - Scholar Component Shadows
        // Computed shadow colors for reader components

        /// Menu shadow color - for floating context menus
        static var menuColor: Color { Color.black.opacity(0.12) }

        /// Card shadow color - indigo-tinted for insight cards
        static var cardColor: Color { Color.scholarIndigo.opacity(0.08) }

        /// Elevated shadow color - subtle lift effect
        static var elevatedColor: Color { Color.black.opacity(0.06) }
    }

    // MARK: - Scholar Component Themes
    // Semantic color groups for reader UI components

    /// Context menu colors
    enum Menu {
        /// Menu background
        static var background: Color { .white }

        /// Menu border
        static var border: Color { Color.scholarIndigo.opacity(0.15) }

        /// Divider lines between menu sections
        static var divider: Color { Color.scholarInk.opacity(0.08) }

        /// Button hover/pressed background
        static var buttonHover: Color { Color.scholarIndigo.opacity(0.06) }

        /// Action button text
        static var actionText: Color { Color.scholarInk.opacity(0.8) }
    }

    /// Insight card colors (expandable verse insight panels)
    enum InsightCard {
        /// Left accent bar gradient colors
        static let barGradient: [Color] = [
            Color.scholarIndigo,
            Color.scholarIndigoLight,
            Color.scholarIndigo
        ]

        /// Card background
        static var background: Color { .white }

        /// Card border
        static var border: Color { Color.scholarIndigo.opacity(0.1) }

        /// Chip background (unselected)
        static var chipBackground: Color { Color.scholarIndigo.opacity(0.06) }

        /// Chip selected background
        static var chipSelected: Color { Color.scholarIndigo.opacity(0.15) }

        /// Chip text
        static var chipText: Color { Color.scholarIndigo }

        /// Hero summary text
        static var heroText: Color { Color.scholarInk }

        /// Supporting/secondary text
        static var supportText: Color { Color.footnoteGray }
    }

    /// Inline insight panel colors (embedded in verse rows)
    enum InlineInsight {
        /// Panel background inside verse row
        static var background: Color { Color.scholarIndigo.opacity(0.04) }

        /// Divider between verse text and insight
        static var divider: Color { Color.scholarInk.opacity(0.08) }

        /// Subtle border for inline panel
        static var border: Color { Color.scholarIndigo.opacity(0.1) }

        /// Voice mode underline (future use)
        static var spokenUnderline: Color { Color.scholarIndigoLight.opacity(0.6) }
    }

    // MARK: - Icon Sizes
    struct IconSize {
        static let small: CGFloat = 16
        static let medium: CGFloat = 20
        static let large: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let celebration: CGFloat = 36  // For achievement/celebration badges
    }

    // MARK: - Minimum Touch Target
    static let minTouchTarget: CGFloat = 44

    // MARK: - Opacity
    struct Opacity: Sendable {
        // MARK: - General Purpose
        static let faint: Double = 0.08      // Very subtle backgrounds
        static let subtle: Double = 0.1      // Subtle backgrounds
        static let light: Double = 0.15      // Light highlights
        static let lightMedium: Double = 0.2 // Light to medium
        static let quarter: Double = 0.25    // Light shadows, borders
        static let medium: Double = 0.3      // Standard opacity
        static let disabled: Double = 0.4    // Disabled states
        static let midHeavy: Double = 0.45   // Semi-prominent UI
        static let heavy: Double = 0.5       // Heavy/emphasized
        static let strong: Double = 0.6      // Strong visibility
        static let overlay: Double = 0.7     // Overlays
        static let pressed: Double = 0.8     // Pressed states
        static let high: Double = 0.9        // Very visible
        static let nearOpaque: Double = 0.95 // Almost fully visible

        // MARK: - Gradient-Specific
        static let glassTop: Double = 0.08       // Glass overlay top
        static let glassBottom: Double = 0.02   // Glass overlay bottom
        static let vignetteEdge: Double = 0.3   // Vignette outer edge
        static let candleGlowInner: Double = 0.4 // Candle glow center
        static let candleGlowOuter: Double = 0.1 // Candle glow edge
        static let goldRadialCenter: Double = 0.2 // Accent glow center (legacy name)
        static let goldRadialEdge: Double = 0.0  // Accent glow fade (legacy name)

        // MARK: - Shadow-Specific
        static let shadowSmall: Double = 0.1    // Small shadow
        static let shadowMedium: Double = 0.15  // Medium shadow
        static let shadowLarge: Double = 0.2    // Large shadow
        static let shadowMenu: Double = 0.15    // Menu shadow light mode
        static let shadowMenuDark: Double = 0.5 // Menu shadow dark mode
        static let shadowGoldGlow: Double = 0.3 // Gold glow shadow
    }

    // MARK: - Border
    struct Border {
        static let hairline: CGFloat = 0.5
        static let thin: CGFloat = 1
        static let medium: CGFloat = 1.5
        static let regular: CGFloat = 2
        static let thick: CGFloat = 3
        static let heavy: CGFloat = 4
    }

    // MARK: - Icon Container Sizes
    struct IconContainer {
        static let small: CGFloat = 24
        static let medium: CGFloat = 32
        static let large: CGFloat = 44
        static let xl: CGFloat = 56
    }

    // MARK: - Blur Radius (Phase 3)
    struct Blur {
        static let glow: CGFloat = 1.5       // Very subtle glow softening
        static let subtle: CGFloat = 3       // Subtle softening
        static let light: CGFloat = 5        // Light blur for glows
        static let medium: CGFloat = 8       // Standard blur
        static let heavy: CGFloat = 10       // Heavy blur for backgrounds
        static let intense: CGFloat = 15     // Intense blur for overlays
    }

    // MARK: - Scale Effects (Phase 3)
    struct Scale {
        static let pressed: CGFloat = 0.95   // Button pressed state
        static let subtle: CGFloat = 0.98    // Subtle pressed feedback
        static let reduced: CGFloat = 0.8    // Reduced size (e.g., ProgressView)
        static let small: CGFloat = 0.7      // Smaller scale
        static let enlarged: CGFloat = 1.2   // Slightly enlarged
        static let pulse: CGFloat = 1.5      // Pulse animation max
    }

    // MARK: - Divider Heights (Phase 4)
    struct Divider {
        static let hairline: CGFloat = 0.5   // Subtle separator
        static let thin: CGFloat = 1         // Standard divider
        static let medium: CGFloat = 2       // Emphasized divider
        static let thick: CGFloat = 4        // Section divider
        static let heavy: CGFloat = 6        // Major section break
    }

    // MARK: - Touch Target Sizes (Phase 4)
    struct TouchTarget {
        static let minimum: CGFloat = 44     // Apple HIG minimum
        static let comfortable: CGFloat = 48 // Comfortable tapping
        static let large: CGFloat = 56       // Large touch target
    }

    // MARK: - Gesture Thresholds
    struct Gesture {
        /// Horizontal swipe distance to trigger navigation (chapter change)
        static let swipeThreshold: CGFloat = 80

        /// Maximum drag offset for visual feedback during swipe
        static let maxDragOffset: CGFloat = 100

        /// Minimum distance to start recognizing a drag gesture
        static let minimumDragDistance: CGFloat = 30

        /// Long press duration for range selection
        static let longPressDuration: TimeInterval = 0.5

        /// Auto-hide delay for reading chrome (seconds)
        static let chromeAutoHideDelay: TimeInterval = 8.0

        /// Extended auto-hide delay after settings interaction (seconds)
        static let chromeExtendedHideDelay: TimeInterval = 12.0

        // MARK: - Velocity-Based Chrome Reveal

        /// Scroll velocity above which chrome hides for immersive reading (px/s)
        static let velocityThresholdForHide: CGFloat = 150

        /// Scroll velocity below which chrome reveals (px/s)
        static let velocityThresholdForReveal: CGFloat = 30

        /// Pause duration required before velocity-based reveal triggers (seconds)
        static let pauseDurationForReveal: TimeInterval = 0.5

        /// Duration chrome stays visible after velocity-based reveal (seconds)
        static let velocityRevealDuration: TimeInterval = 3.0
    }

    // MARK: - Component Sizes (Phase 4)
    struct ComponentSize {
        static let dot: CGFloat = 4          // Tiny dots (animations)
        static let dotSmall: CGFloat = 6     // Small dots
        static let indicator: CGFloat = 8    // Status indicators
        static let badge: CGFloat = 20       // Small badges
        static let icon: CGFloat = 24        // Standard icons
        static let avatar: CGFloat = 40      // User avatars
        static let thumbnail: CGFloat = 64   // Thumbnails
        static let preview: CGFloat = 120    // Preview cards
    }

    // MARK: - Input Bar (Animated Ask Input)
    struct InputBar {
        static let height: CGFloat = 55              // Collapsed bar height
        static let buttonSize: CGFloat = 35          // Leading/trailing action buttons
        static let mainButtonSize: CGFloat = 55      // Main send button size
        static let cornerRadius: CGFloat = 30        // Collapsed corner radius
        static let cornerRadiusFocused: CGFloat = 25 // Expanded corner radius
        static let textFieldMaskPadding: CGFloat = 40 // Trailing mask when collapsed
        static let slideOffset: CGFloat = 32         // Send button slide-out offset
    }
}

// MARK: - Shadow Style
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extension for Shadows
extension View {
    func shadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }

    func cardStyle() -> some View {
        self
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
            .shadow(AppTheme.Shadow.small)
    }

    func elevatedCardStyle() -> some View {
        self
            .background(Color.elevatedBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
            .shadow(AppTheme.Shadow.medium)
    }
}

// MARK: - View Extension for Reduced Motion
extension View {
    /// Applies animation only when reduce motion is disabled
    /// Usage: .reducedMotionAnimation(AppTheme.Animation.standard, value: state)
    func reducedMotionAnimation<V: Equatable>(
        _ animation: SwiftUI.Animation,
        value: V
    ) -> some View {
        self.animation(AppTheme.Animation.reduced(animation), value: value)
    }

    /// Applies accessible animation (subtle fade when reduce motion enabled)
    /// Usage: .accessibleAnimation(AppTheme.Animation.spring, value: state)
    func accessibleAnimation<V: Equatable>(
        _ animation: SwiftUI.Animation,
        value: V
    ) -> some View {
        self.animation(AppTheme.Animation.accessible(animation), value: value)
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.UI.buttonLabel)
            .tracking(0.3)
            .foregroundStyle(.white)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(Color.Semantic.accent)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            .opacity(configuration.isPressed ? AppTheme.Opacity.pressed : 1.0)
            .scaleEffect(configuration.isPressed ? AppTheme.Scale.subtle : 1.0)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.UI.buttonLabel)
            .tracking(0.3)
            .foregroundStyle(Color.Semantic.accent)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(Color.Semantic.accent.opacity(AppTheme.Opacity.light))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            .opacity(configuration.isPressed ? AppTheme.Opacity.pressed : 1.0)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}

struct ChipButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.UI.chipLabel)
            .foregroundStyle(isSelected ? .white : Color.primaryText)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(isSelected ? Color.Semantic.accent : Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .stroke(isSelected ? Color.clear : Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
            .opacity(configuration.isPressed ? AppTheme.Opacity.pressed : 1.0)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

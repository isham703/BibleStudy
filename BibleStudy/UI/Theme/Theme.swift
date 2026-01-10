//
//  Theme.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Design tokens for spacing, radius, stroke, and motion
//
//  Motion Principle: "Ceremonial, restrained, almost invisible"
//  - ALL cubic easing - NO spring animations
//  - fade: easeInOut 220ms
//  - settle: easeOut 260ms (NOT spring - weight via easeOut + delay)
//  - slowFade: easeInOut 420ms
//  - stagger: easeOut with delay for sequential reveals
//
//  Banned Motion:
//  - ❌ Confetti, fireworks, ALL spring animations
//  - ❌ Bouncy easing (spring/bounce/elastic curves)
//  - ❌ Shimmer gradients, particle effects
//  - ❌ "Celebration" animations
//

import SwiftUI

// MARK: - Theme

enum Theme {

    // MARK: - Spacing

    /// Standardized spacing scale (from Stoic-Existential Renaissance plan)
    enum Spacing {
        static let xs: CGFloat = 6      // Tight spacing
        static let sm: CGFloat = 10     // Small gaps
        static let md: CGFloat = 16     // Medium gaps (default)
        static let lg: CGFloat = 24     // Large spacing
        static let xl: CGFloat = 32     // Extra large
        static let xxl: CGFloat = 48    // Section spacing
    }

    // MARK: - Radius

    /// Corner radius values (from Design System spec)
    /// Consistent radii create visual harmony
    enum Radius {
        // Small radii
        static let xs: CGFloat = 2            // Indicator strips
        static let small: CGFloat = 4         // Chips, badges
        static let sm: CGFloat = 4            // Alias for small

        // Medium radii
        static let medium: CGFloat = 8        // Inputs
        static let md: CGFloat = 8            // Alias for medium
        static let input: CGFloat = 8         // Input fields
        static let button: CGFloat = 10       // All buttons use 10pt radius (per plan)

        // Large radii
        static let large: CGFloat = 14        // Standard cards
        static let lg: CGFloat = 14           // Alias for large
        static let card: CGFloat = 14         // Cards (tighter than 22 to avoid softness - per plan)
        static let menu: CGFloat = 14         // Floating menus

        // Extra large radii
        static let xl: CGFloat = 16           // Large cards
        static let sheet: CGFloat = 20        // Bottom sheets
        static let tag: CGFloat = 6           // Small badges/tags (legacy)

        // NOTE: NO pill radius (999) - pill buttons are banned
        // Pill shapes violate "no friendly rounded elements" doctrine
    }

    // MARK: - Stroke

    /// Stroke width values
    /// Prefer strokes over shadows for separation
    enum Stroke {
        static let hairline: CGFloat = 1     // Subtle dividers, card borders
        static let control: CGFloat = 2      // Control strokes (buttons, inputs)
    }

    // Legacy Border namespace - redirects to Stroke values
    // TO DELETE after FloatingContextMenu component migration
    enum Border {
        static let hairline: CGFloat = Stroke.hairline  // 1pt
        static let thin: CGFloat = Stroke.hairline      // 1pt (alias)
        static let regular: CGFloat = Stroke.control    // 2pt
        static let medium: CGFloat = Stroke.control     // 2pt (alias) - TO DELETE after ConnectionNode migration
        static let thick: CGFloat = 3                   // 3pt - TO DELETE after QuickInsightCard migration
        static let heavy: CGFloat = 4                   // 4pt - TO DELETE after ConnectionCelebration migration
    }

    // MARK: - Animation

    /// Motion tokens - ALL cubic easing, NO spring animations
    /// Motion is ceremonial, restrained, almost invisible
    enum Animation {
        /// Fade: easeInOut 220ms - standard transitions
        /// Use for: tab switching, modal appearance, general fades
        static let fade: SwiftUI.Animation = .easeInOut(duration: 0.22)

        /// Settle: easeOut 260ms - weight without bounce
        /// Use for: content settling, card reveals, button feedback
        /// CRITICAL: This is NOT spring - uses cubic easing for weight
        static let settle: SwiftUI.Animation = .easeOut(duration: 0.26)

        /// SlowFade: easeInOut 420ms - deliberate content reveals
        /// Use for: "Begin" transitions, ritual moments, important reveals
        static let slowFade: SwiftUI.Animation = .easeInOut(duration: 0.42)

        /// Stagger: easeOut with delay - sequential reveals
        /// Use for: list reveals, card grids, sequential animations
        /// - Parameters:
        ///   - index: The index of the item in the sequence
        ///   - step: The delay between each item (default 60ms)
        static func stagger(index: Int, step: Double = 0.06) -> SwiftUI.Animation {
            .easeOut(duration: 0.26).delay(Double(index) * step)
        }

        /// Legacy helper for reduce motion detection
        /// TO DELETE after UsageRow migration - use UIAccessibility.isReduceMotionEnabled directly
        static var isReduceMotionEnabled: Bool {
            UIAccessibility.isReduceMotionEnabled
        }
    }

    // MARK: - Size

    /// Minimum tap target sizes (Apple HIG requirement)
    enum Size {
        static let minTapTarget: CGFloat = 44      // Minimum interactive element size
        static let iconSize: CGFloat = 24          // Standard icon size
        static let iconSizeLarge: CGFloat = 32     // Large icon size
    }

    // MARK: - Opacity

    /// Opacity values for visual hierarchy
    /// Organized from most transparent to most opaque
    enum Opacity {
        // Very subtle (backgrounds, atmospheric effects)
        static let faint: Double = 0.05            // Barely visible: subtle backgrounds, atmospheric
        static let overlay: Double = 0.10          // Overlays, hover states, subtle fills
        static let divider: Double = 0.15          // Divider lines, borders
        static let light: Double = 0.20            // Light fills, subtle accents

        // Quarter-range (borders, secondary fills)
        static let quarter: Double = 0.25          // Borders, secondary backgrounds
        static let subtle: Double = 0.30           // Subtle fills, icon backgrounds

        // Mid-range (disabled, interactive states)
        static let disabled: Double = 0.35         // Disabled state
        static let lightMedium: Double = 0.40      // Light-medium fills, focus rings
        static let medium: Double = 0.50           // Medium fills, secondary content

        // Upper-range (text, active content)
        static let tertiary: Double = 0.60         // Tertiary text, metadata
        static let midHeavy: Double = 0.65         // Mid-heavy fills
        static let heavy: Double = 0.70            // Heavy fills, secondary text
        static let secondary: Double = 0.75        // Secondary text

        // Near-opaque (emphasis, pressed states)
        static let pressed: Double = 0.80          // Pressed state
        static let strong: Double = 0.85           // Strong emphasis
        static let high: Double = 0.90             // High opacity fills
        static let nearOpaque: Double = 0.95       // Near-opaque
        static let primary: Double = 0.96          // Primary text
    }
}

// MARK: - Canonical Ritual Transition (Documentation)

/*
 Canonical Ritual Transition ("Begin" → Session Start):

 This transition is used consistently across all "Begin" actions
 to create a ceremonial, ritualized feel.

 Sequence:
 1. Fade to near-black: 200ms easeOut
 2. Content fade in: 240-360ms easeInOut
 3. Subtle vertical drift: 2-4pt during fade in
 4. Consistent everywhere - same feeling across all "Begin" actions

 Implementation Example:
 ```swift
 withAnimation(Theme.Animation.slowFade) {
     showContent = true
 }
 ```

 Usage:
 - Daily Office begin
 - Evening Examen begin
 - Any "Begin" button that starts a practice/session
 - Major feature transitions that deserve ceremony
 */

// MARK: - Motion Doctrine (Documentation)

/*
 Motion Doctrine: Ceremonial, Restrained, Almost Invisible

 Allowed Motion:
 - Fade in/out (short, controlled, 180-240ms)
 - Subtle vertical drift (2-4pt) only on screen entry
 - Micro "press" feedback on buttons (scale 0.98-0.99, NO bounce)
 - Slow progress indicators (linear or easeOut, no bouncing)

 Banned Motion:
 - ❌ Confetti, fireworks, ALL spring animations
 - ❌ Bouncy easing (spring/bounce/elastic curves)
 - ❌ Shimmer gradients, particle effects
 - ❌ "Celebration" animations

 Timing Rules:
 - Default transitions: 180-240ms
 - Content reveals: 240-360ms
 - No motion longer than 400ms unless deliberate "ritual" transition

 Reduce Motion Support:
 - When enabled: use only fade transitions (no drift, no stagger, no scale)
 - Disable all "ritual" transitions, use instant fade only
 - Duration reduced to 100-150ms

 Implementation:
 ```swift
 @Environment(\.accessibilityReduceMotion) var reduceMotion

 withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : Theme.Animation.fade) {
     // ...
 }
 ```
 */

// MARK: - Elevation & Shadow Policy (Documentation)

/*
 Elevation & Shadow Policy:

 Default Policy: NO shadows

 Exception (Minimal Shadow Token):
 - Modal sheets: shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 4)
 - Floating bars (if needed): shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 2)

 Preferred Over Shadows:
 - Hairline strokes (1pt, 10-20% opacity)
 - Subtle divider lines
 - Background color contrast (surface vs background)

 Rule: Prefer strokes/dividers over shadows everywhere except modals

 Implementation Example:
 ```swift
 // Prefer this:
 Rectangle()
     .stroke(Colors.Surface.divider(for: mode), lineWidth: Theme.Stroke.hairline)

 // Over this:
 Rectangle()
     .shadow(radius: 4)
 ```
 */

// MARK: - AppTheme (Legacy Compatibility)

/// Legacy AppTheme namespace for backward compatibility with old code
/// Redirects to new Theme tokens
typealias AppTheme = Theme

extension Theme {
    /// Legacy CornerRadius namespace
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 20  // TODO: Replace with Theme.Radius.card in OnboardingAnimations
        static let card: CGFloat = Radius.card  // Redirect to new Radius.card
    }

    /// Legacy Toggle namespace
    enum Toggle {
        static let trackWidth: CGFloat = 51
        static let trackHeight: CGFloat = 31
        static let thumbSize: CGFloat = 27
        static let thumbOffset: CGFloat = 10
    }

    /// Legacy Spacing aliases
    enum Spacing2 {
        static let xxs: CGFloat = 4
    }
}

// MARK: - StoicTheme Deleted
// StoicTheme legacy namespace has been fully migrated and deleted.
// All components now use proper design tokens:
// - Colors: Color.accentBronze, Color.surfaceRaised, Color.textPrimary, etc.
// - Typography: Typography.Scripture.*, Typography.Command.*
// - Spacing: Theme.Spacing.*
// - Animation: Theme.Animation.*

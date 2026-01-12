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
        static let xxs: CGFloat = 2     // Micro-spacing (tight title/subtitle pairs)
        static let xs: CGFloat = 6      // Tight spacing
        static let sm: CGFloat = 10     // Small gaps
        static let md: CGFloat = 16     // Medium gaps (default)
        static let lg: CGFloat = 24     // Large spacing
        static let xl: CGFloat = 32     // Extra large
        static let xxl: CGFloat = 48    // Section spacing
    }

    // MARK: - Radius

    /// Corner radius values - semantic naming by component type
    enum Radius {
        static let xs: CGFloat = 2            // Indicator strips, progress bars
        static let tag: CGFloat = 6           // Small badges/tags
        static let input: CGFloat = 8         // Input fields, small controls
        static let md: CGFloat = 8            // Alias for input (context menus)
        static let button: CGFloat = 10       // CTA buttons
        static let card: CGFloat = 14         // Cards, floating menus
        static let xl: CGFloat = 16           // Large cards, overlays
        static let sheet: CGFloat = 20        // Bottom sheets, modals
    }

    // MARK: - Stroke

    /// Stroke width values
    /// Prefer strokes over shadows for separation
    enum Stroke {
        static let hairline: CGFloat = 1     // Subtle dividers, card borders
        static let control: CGFloat = 2      // Control strokes (buttons, inputs)
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
    }

    // MARK: - Size

    /// Minimum tap target sizes (Apple HIG requirement)
    enum Size {
        static let minTapTarget: CGFloat = 44      // Minimum interactive element size
        static let iconSize: CGFloat = 24          // Standard icon size
        static let iconSizeLarge: CGFloat = 32     // Large icon size
    }

    // MARK: - Opacity

    /// Semantic opacity values for consistent visual hierarchy
    /// Organized by purpose: Interaction, Text, Structural
    enum Opacity {

        // MARK: - Interaction States

        /// Press feedback on buttons/controls
        static let pressed: Double = 0.80

        /// Disabled controls and buttons
        static let disabled: Double = 0.35

        /// Focus ring/stroke strength
        static let focusStroke: Double = 0.60

        /// Verse/text selection background (temporary state)
        static let selectionBackground: Double = 0.14

        /// Persistent highlight background (stronger than selection to differentiate)
        static let highlightBackground: Double = 0.24

        // MARK: - Text Hierarchy

        /// Primary body text
        static let textPrimary: Double = 0.96

        /// Secondary/supporting text
        static let textSecondary: Double = 0.75

        /// Metadata, captions, timestamps
        static let textTertiary: Double = 0.60

        /// Disabled text
        static let textDisabled: Double = 0.35

        // MARK: - Structural

        /// Divider lines, borders
        static let divider: Double = 0.12

        /// Modal overlays, scrims
        static let overlay: Double = 0.10

        /// Atmospheric backgrounds
        static let subtle: Double = 0.05

        /// Highlight backgrounds (verse highlights)
        static let highlight: Double = 0.40
    }

    // MARK: - Reading

    /// Layout tokens for Bible reading experience
    /// Controls measure (line length), spacing, and reading rhythm
    enum Reading {
        /// Maximum content width for optimal readability (~55 chars at 17pt)
        /// Use with .frame(maxWidth:) on reading containers
        static let maxWidth: CGFloat = 500

        /// Horizontal padding for reading content
        static let horizontalPadding: CGFloat = 20

        /// Space between paragraphs
        static let paragraphSpacing: CGFloat = 12

        /// Space between major sections (chapter breaks, etc.)
        static let sectionSpacing: CGFloat = 24

        /// Extra verse spacing for meditative/slow reading mode
        static let verseSpacingMeditative: CGFloat = 20
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
     .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)

 // Over this:
 Rectangle()
     .shadow(radius: 4)
 ```
 */

extension Theme {
    /// Custom toggle sizing for GoldToggleStyle
    enum Toggle {
        static let trackWidth: CGFloat = 51
        static let trackHeight: CGFloat = 31
        static let thumbSize: CGFloat = 27
        static let thumbOffset: CGFloat = 10
    }
}

// MARK: - StoicTheme Deleted
// StoicTheme legacy namespace has been fully migrated and deleted.
// All components now use proper design tokens:
// - Colors: Color("AppBackground"), Color("AppTextPrimary"), Color("AccentBronze"), etc.
// - Typography: Typography.Scripture.*, Typography.Command.*
// - Spacing: Theme.Spacing.*
// - Animation: Theme.Animation.*

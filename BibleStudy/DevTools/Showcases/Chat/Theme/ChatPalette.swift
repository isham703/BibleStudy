import SwiftUI

// MARK: - Chat Palette
// Color and style definitions for AI Chat Showcase
// Each variant has its own sub-palette for consistent theming

enum ChatPalette {

    // MARK: - Directory Colors (Dark Theme)
    enum Directory {
        static let background = Color(hex: "0f0f0f")
        static let surface = Color(hex: "1a1a1a")
        static let elevated = Color(hex: "262626")
        static let primaryText = Color(hex: "fafafa")
        static let secondaryText = Color(hex: "a1a1aa")
        static let tertiaryText = Color(hex: "71717a")
        static let accent = Color(hex: "6366f1") // Indigo-500
        static let divider = Color.white.opacity(0.08)
    }

    // MARK: - Minimal Studio Palette
    // Ultra-clean, monochromatic, modern design
    enum Minimal {
        // Backgrounds
        static let background = Color(hex: "fafafa")
        static let surface = Color.white
        static let inputBackground = Color(hex: "f4f4f5")

        // Text
        static let primaryText = Color.surfaceRaised
        static let secondaryText = Color(hex: "52525b")
        static let tertiaryText = Color(hex: "a1a1aa")
        static let placeholder = Color(hex: "d4d4d8")

        // Accents
        static let accent = Color.surfaceRaised
        static let accentSubtle = Color.surfaceRaised.opacity(0.08)

        // Messages
        static let userBubble = Color.surfaceRaised
        static let userText = Color.white
        static let aiBubble = Color.white
        static let aiText = Color.surfaceRaised
        static let aiBorder = Color(hex: "e4e4e7")

        // Interactive
        static let voiceButton = Color.surfaceRaised
        static let sendButton = Color.surfaceRaised
        static let buttonDisabled = Color(hex: "d4d4d8")

        // Shadows
        static let shadow = Color.black.opacity(0.04)
    }

    // MARK: - Scholarly Companion Palette
    // Editorial, academic, research-focused
    enum Scholarly {
        // Backgrounds
        static let background = Color(hex: "f8f5f0") // Warm vellum
        static let surface = Color.white
        static let inputBackground = Color.white

        // Text
        static let primaryText = Color(hex: "1c1917") // Scholar ink
        static let secondaryText = Color(hex: "44403c")
        static let tertiaryText = Color(hex: "78716c")
        static let placeholder = Color(hex: "a8a29e")

        // Accents
        static let accent = Color.accentIndigo
        static let accentSubtle = Color.accentIndigo.opacity(0.08)
        static let greek = Color(hex: "2563eb") // Blue for Greek
        static let hebrew = Color(hex: "7c3aed") // Purple for Hebrew
        static let citation = Color(hex: "059669") // Green for citations

        // Messages
        static let userBubble = Color.accentIndigo
        static let userText = Color.white
        static let aiBubble = Color.white
        static let aiText = Color(hex: "1c1917")
        static let aiBorder = Color(hex: "e7e5e4")

        // Interactive
        static let voiceButton = Color.accentIndigo
        static let sendButton = Color.accentIndigo
        static let buttonDisabled = Color(hex: "d6d3d1")

        // Special
        static let citationChip = Color.accentIndigo.opacity(0.1)
        static let crossReference = Color.amberOrange // Amber

        // Shadows
        static let shadow = Color.accentIndigo.opacity(0.06)
    }

    // MARK: - Warm Sanctuary Palette
    // Candlelit, intimate, contemplative
    enum Sanctuary {
        // Backgrounds
        static let background = Color(hex: "1c1917") // Stone
        static let surface = Color(hex: "292524")
        static let inputBackground = Color(hex: "292524")

        // Text
        static let primaryText = Color(hex: "fafaf9")
        static let secondaryText = Color(hex: "d6d3d1")
        static let tertiaryText = Color(hex: "a8a29e")
        static let placeholder = Color(hex: "78716c")

        // Accents - warm gold tones
        static let accent = Color.accentBronze // Divine gold
        static let accentSubtle = Color.accentBronze.opacity(0.15)
        static let accentGlow = Color(hex: "e8c978") // Illuminated gold

        // Messages
        static let userBubble = Color.accentBronze.opacity(0.2)
        static let userBorder = Color.accentBronze.opacity(0.4)
        static let userText = Color(hex: "fafaf9")
        static let aiBubble = Color(hex: "292524")
        static let aiBorder = Color(hex: "44403c")
        static let aiText = Color(hex: "fafaf9")

        // Interactive
        static let voiceButton = Color.accentBronze
        static let sendButton = Color.accentBronze
        static let buttonDisabled = Color(hex: "57534e")

        // Special
        static let divider = Color.accentBronze.opacity(0.2)
        static let glow = Color.accentBronze.opacity(0.1)

        // Shadows
        static let shadow = Color.black.opacity(0.3)
    }

    // MARK: - Shared Values
    enum Shared {
        // Corner Radii
        static let messageBubble: CGFloat = 20
        static let inputBar: CGFloat = 24
        static let chip: CGFloat = 8
        static let card: CGFloat = 16

        // Spacing
        static let messageSpacing: CGFloat = 16
        static let bubblePadding: CGFloat = 16
        static let inputPadding: CGFloat = 16

        // Sizing
        static let voiceButtonSize: CGFloat = 44
        static let sendButtonSize: CGFloat = 40
        static let avatarSize: CGFloat = 32
        static let maxBubbleWidth: CGFloat = 280
    }

    // MARK: - Animations
    enum Animation {
        static let messageAppear = Theme.Animation.settle
        static let typing = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let inputExpand = Theme.Animation.settle
        static let voicePulse = SwiftUI.Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
    }
}

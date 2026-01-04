import SwiftUI

// MARK: - Scholar Palette
// Centralized color and style definitions for the Scholar's Marginalia reader
// References existing colors from SanctuaryColors with Scholar-specific additions

enum ScholarPalette {
    // MARK: - Primary Accent
    /// Main accent color (replaces gold in Illuminated theme)
    static let accent = Color.scholarIndigo

    /// Lighter indigo for hover states and subtle accents
    static let accentLight = Color.scholarIndigoLight

    /// Very subtle indigo for backgrounds
    static let accentSubtle = Color.scholarIndigo.opacity(0.08)

    // MARK: - Secondary Accent
    /// Greek/Hebrew language features
    static let greek = Color.greekBlue

    /// Theology/doctrine color
    static let theology = Color.theologyGreen

    /// Connection/cross-reference color
    static let connection = Color.connectionAmber

    // MARK: - Surfaces
    /// Primary background - warm vellum paper
    static let vellum = Color.vellumCream

    /// Elevated surface - slightly darker paper
    static let elevated = Color.scholarElevatedPaper

    /// Card background - clean white
    static let card = Color.white

    /// Paper gradient for depth
    static let paperGradient = Color.paperGradient

    // MARK: - Text
    /// Primary text - rich ink
    static let ink = Color.scholarInk

    /// Secondary text in verses (slightly lighter than ink)
    static let inkWell = Color.inkWell

    /// Tertiary text - footnotes, metadata
    static let footnote = Color.footnoteGray

    /// Connection amber for cross-references
    static let connectionAmber = Color.connectionAmber

    // MARK: - Selection
    /// Verse selection background
    static let selectionBackground = Color.scholarIndigo.opacity(0.08)

    /// Verse selection border
    static let selectionBorder = Color.scholarIndigo.opacity(0.3)

    // MARK: - Context Menu
    enum Menu {
        /// Menu background
        static let background = Color.white

        /// Menu border
        static let border = Color.scholarIndigo.opacity(0.15)

        /// Divider lines
        static let divider = Color.scholarInk.opacity(0.08)

        /// Button hover background
        static let buttonHover = Color.scholarIndigo.opacity(0.06)

        /// Action button text
        static let actionText = Color.scholarInk.opacity(0.8)
    }

    // MARK: - Insight Card
    enum Insight {
        /// Left accent bar gradient colors
        static let barGradient: [Color] = [
            Color.scholarIndigo,
            Color.scholarIndigoLight,
            Color.scholarIndigo
        ]

        /// Card background
        static let background = Color.white

        /// Card border
        static let border = Color.scholarIndigo.opacity(0.1)

        /// Chip background
        static let chipBackground = Color.scholarIndigo.opacity(0.06)

        /// Chip selected background
        static let chipSelected = Color.scholarIndigo.opacity(0.15)

        /// Chip text
        static let chipText = Color.scholarIndigo

        /// Hero summary text
        static let heroText = Color.scholarInk

        /// Supporting text
        static let supportText = Color.footnoteGray
    }

    // MARK: - Inline Insight Panel
    enum InlineInsight {
        /// Panel background inside verse row
        static let background = Color.scholarIndigo.opacity(0.04)

        /// Divider between verse text and insight
        static let divider = Color.scholarInk.opacity(0.08)

        /// Subtle border for inline panel
        static let border = Color.scholarIndigo.opacity(0.1)

        /// Voice mode underline (future use)
        static let spokenUnderline = Color.scholarIndigoLight.opacity(0.6)
    }

    // MARK: - Animations
    enum Animation {
        /// Menu appear spring
        static let menuAppear = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.8)

        /// Selection highlight
        static let selection = SwiftUI.Animation.easeOut(duration: 0.2)

        /// Insight card unfurl
        static let cardUnfurl = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.85)

        /// Chip expansion
        static let chipExpand = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
    }

    // MARK: - Shadows
    enum Shadow {
        /// Menu shadow
        static let menu = Color.black.opacity(0.12)

        /// Card shadow
        static let card = Color.scholarIndigo.opacity(0.08)

        /// Elevated shadow
        static let elevated = Color.black.opacity(0.06)
    }

    // MARK: - Corner Radii
    enum CornerRadius {
        /// Small elements (chips, buttons)
        static let small: CGFloat = 8

        /// Cards and panels
        static let card: CGFloat = 12

        /// Menu container
        static let menu: CGFloat = 16

        /// Large containers
        static let large: CGFloat = 20
    }

    // MARK: - Spacing
    enum Spacing {
        /// Tiny spacing
        static let xxs: CGFloat = 2

        /// Compact spacing
        static let xs: CGFloat = 4

        /// Small spacing
        static let sm: CGFloat = 8

        /// Medium spacing
        static let md: CGFloat = 12

        /// Large spacing
        static let lg: CGFloat = 16

        /// Extra large spacing
        static let xl: CGFloat = 24

        /// Extra extra large spacing
        static let xxl: CGFloat = 32
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Accent colors
        HStack(spacing: 10) {
            Circle().fill(ScholarPalette.accent).frame(width: 40, height: 40)
            Circle().fill(ScholarPalette.accentLight).frame(width: 40, height: 40)
            Circle().fill(ScholarPalette.greek).frame(width: 40, height: 40)
        }

        // Surfaces
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(ScholarPalette.vellum)
                .frame(width: 60, height: 40)
            RoundedRectangle(cornerRadius: 8)
                .fill(ScholarPalette.elevated)
                .frame(width: 60, height: 40)
            RoundedRectangle(cornerRadius: 8)
                .fill(ScholarPalette.card)
                .frame(width: 60, height: 40)
        }

        // Text samples
        VStack(alignment: .leading, spacing: 4) {
            Text("Scholar Ink").foregroundStyle(ScholarPalette.ink)
            Text("Footnote Gray").foregroundStyle(ScholarPalette.footnote)
            Text("Greek Blue").foregroundStyle(ScholarPalette.greek)
        }
        .font(.system(size: 14, weight: .medium))

        // Menu sample
        RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.menu)
            .fill(ScholarPalette.Menu.background)
            .overlay(
                RoundedRectangle(cornerRadius: ScholarPalette.CornerRadius.menu)
                    .stroke(ScholarPalette.Menu.border, lineWidth: 1)
            )
            .frame(height: 60)
            .shadow(color: ScholarPalette.Shadow.menu, radius: 12, x: 0, y: 4)
    }
    .padding()
    .background(ScholarPalette.vellum)
}

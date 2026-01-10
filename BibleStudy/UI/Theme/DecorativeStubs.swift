//
//  DecorativeStubs.swift
//  BibleStudy
//
//  TEMPORARY FILE - TO DELETE after component migration
//  Minimal stubs for deleted decorative components to keep production code compiling
//

import SwiftUI

// MARK: - DropCapStyle

/// Temporary stub for DropCapStyle
/// TO DELETE after AppState migration
enum DropCapStyle: String, CaseIterable, Codable {
    case none
    case illuminated
    case ornamental
    case simple

    var displayName: String {
        switch self {
        case .none: return "None"
        case .illuminated: return "Illuminated"
        case .ornamental: return "Ornamental"
        case .simple: return "Simple"
        }
    }
}

// MARK: - VerseNumberStyle

/// Temporary stub for VerseNumberStyle
/// TO DELETE after VerseNumberView migration
enum VerseNumberStyle: String, CaseIterable, Codable {
    case superscript    // Small, raised
    case inline         // Same baseline
    case marginal       // In margin
    case ornamental     // Decorative
    case minimal        // Very subtle

    var font: Font {
        switch self {
        case .superscript: return .system(size: 12, weight: .regular)
        case .inline: return .system(size: 15, weight: .medium)
        case .marginal: return .system(size: 13, weight: .regular)
        case .ornamental: return .system(size: 14, weight: .semibold)
        case .minimal: return .system(size: 11, weight: .light)
        }
    }

    var opacity: Double {
        switch self {
        case .superscript: return 0.80
        case .inline: return 0.90
        case .marginal: return 0.70
        case .ornamental: return 1.00
        case .minimal: return 0.50
        }
    }

    var displayName: String {
        switch self {
        case .superscript: return "Superscript"
        case .inline: return "Inline"
        case .marginal: return "Marginal"
        case .ornamental: return "Ornamental"
        case .minimal: return "Minimal"
        }
    }
}

// MARK: - OrnamentalDividerStyle

/// Temporary stub for OrnamentalDividerStyle
/// TO DELETE after divider component migration
enum OrnamentalDividerStyle {
    case simple
    case flourish
    case manuscript
    case chapterUnderline
    case sectionBreak
}

// MARK: - OrnamentalDivider

/// Temporary stub for OrnamentalDivider
/// TO DELETE after divider component migration
/// Renders as simple thin divider instead of decorative version
struct OrnamentalDivider: View {
    let style: OrnamentalDividerStyle
    let color: Color

    init(style: OrnamentalDividerStyle = .simple, color: Color = Color.gray.opacity(0.3)) {
        self.style = style
        self.color = color
    }

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: Theme.Stroke.hairline)
    }
}

// MARK: - Missing AppTheme Stubs

// Opacity tokens are now consolidated in Theme.Opacity (Theme.swift)

extension Theme {
    /// Temporary shadow values
    /// TO DELETE after Breathe migration
    enum Shadow {
        static let breathingGlow: CGFloat = 20
        static let indigoGlow: CGFloat = 12  // TO DELETE after AskFAB migration
        static let medium: CGFloat = 8  // TO DELETE after AskFAB migration
        static let small: CGFloat = 4  // TO DELETE after StoryCard/TimelineNodeView migration
        static let large: CGFloat = 16  // TO DELETE after CelebrationOverlay migration

        /// Shadow style with radius, x, and y properties
        /// TO DELETE after UnifiedContextMenu migration
        static let menu: (radius: CGFloat, x: CGFloat, y: CGFloat) = (radius: 12, x: 0, y: 4)

        /// TO DELETE after BibleBookPickerView/BibleContextMenu/BibleInsightCard migration
        static var elevatedColor: Color { Color.black.opacity(0.15) }
        static var menuColor: Color { Color.black.opacity(0.15) }
        static var card: CGFloat = 12
    }

    /// Temporary gesture values
    /// TO DELETE after InlineHighlightColorRow migration
    enum Gesture {
        static let minimumDistance: CGFloat = 10
        static let minimumDuration: Double = 0.2
        static let longPressDuration: Double = 0.5  // Long press duration
    }
}

extension Theme.CornerRadius {
    /// TO DELETE after Breathe migration
    static let sheet: CGFloat = 24

    /// TO DELETE after InlineThemeCard/UsageRow migration
    static let xs: CGFloat = 4

    /// TO DELETE after TopicDetailView/TopicExplorerView migration
    static let md: CGFloat = 10

    /// TO DELETE after PlansTabView migration
    static let lg: CGFloat = 16

    /// TO DELETE after UnifiedContextMenu migration
    static let menu: CGFloat = 12
}

extension Theme {
    /// Temporary menu values
    /// TO DELETE after ReadingMenu migration
    enum Menu {
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let rowHeight: CGFloat = 44
        static let iconSize: CGFloat = 20
        static var border: Color { Color.gray.opacity(0.15) }
        static var buttonHover: Color { Color.gray.opacity(0.1) }
        static var divider: Color { Color.gray.opacity(0.15) }
        static var background: Color { Color.surfaceRaised }  // TO DELETE after BibleContextMenu migration
    }
}

// MARK: - Button Style Stubs

/// Temporary button style stub for .primary button style
/// TO DELETE after EmptyStateView migration
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.Command.cta)
            .foregroundStyle(Colors.Semantic.onAccentAction(for: ThemeMode.current(from: colorScheme)))
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.md)
            .background(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? Theme.Opacity.pressed : 1.0)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

/// Temporary button style stub for .secondary button style
/// TO DELETE after ErrorView migration
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.Command.cta)
            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.md)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)), lineWidth: Theme.Stroke.control)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? Theme.Opacity.pressed : 1.0)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

// MARK: - Typography Shortcuts

/// Temporary Typography shortcuts for easier migration
/// TO DELETE after FloatingSlider migration
extension Typography {
    /// Body shorthand - redirects to Command.body
    /// TO DELETE after FloatingNavigationRow migration
    static var body: Font { Command.body }

    /// Caption shorthand - redirects to Command.caption
    static var caption: Font { Command.caption }

    /// TO DELETE after SegmentContentView migration
    enum Language {
        static let transliteration: Font = .system(size: 15, weight: .regular, design: .serif).italic()
    }
}

// MARK: - View Extension Stubs

/// TO DELETE after MiniatureActionsView migration
@available(iOS 13.0, *)
extension View {
    /// Accessible animation that respects reduce motion settings
    func accessibleAnimation<V>(_ animation: Animation, value: V) -> some View where V: Equatable {
        self.animation(animation, value: value)
    }

    /// Shadow helper that accepts a single radius value
    /// TO DELETE after CelebrationOverlay migration
    func shadow(_ radius: CGFloat) -> some View {
        self.shadow(color: Color.black.opacity(0.15), radius: radius, x: 0, y: radius / 4)
    }
}

// MARK: - Shape Stubs

/// TO DELETE after SettingsView migration
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - SanctuaryTimeOfDay Stub

/// TEMPORARY: Stub for SanctuaryTimeOfDay to fix @Observable macro compilation
/// TO DELETE once SanctuaryTimeOfDay.swift is properly added to target OR after sanctuary feature migration
/// The actual file exists at BibleStudy/Features/Home/Models/SanctuaryTimeOfDay.swift but has target membership issues
enum SanctuaryTimeOfDay: String, Equatable, CaseIterable, Identifiable {
    case dawn, meridian, afternoon, vespers, compline

    var id: String { rawValue }

    static var current: SanctuaryTimeOfDay { .meridian }
}

// MARK: - Card Modifier

extension View {
    /// Standard card styling with surface background and hairline border
    /// Use for: content cards, list items, section containers
    func card() -> some View {
        modifier(CardModifier())
    }

    /// Applies pressed state feedback (scale + opacity)
    /// Use inside ButtonStyle for interactive cards
    func applyPressedState(_ isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isPressed ? Theme.Opacity.pressed : 1.0)
            .animation(Theme.Animation.fade, value: isPressed)
    }
}

private struct CardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        let mode = ThemeMode.current(from: colorScheme)

        content
            .padding(Theme.Spacing.lg)
            .background(Colors.Surface.surface(for: mode))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Colors.Surface.divider(for: mode), lineWidth: Theme.Stroke.hairline)
            )
    }
}

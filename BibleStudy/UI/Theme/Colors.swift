//
//  Colors.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Color Architecture:
//  All colors are defined in Asset Catalog (iOS 17+) with automatic dark/light mode support.
//  Use Color("ColorName") directly for Asset Catalog colors.
//
//  Asset Catalog Colors:
//  - AppBackground, AppSurface, AppDivider
//  - AppTextPrimary, AppTextSecondary, TertiaryText
//  - AppAccentAction, AccentBronze
//  - FeedbackError, FeedbackWarning, FeedbackSuccess, FeedbackInfo
//

import SwiftUI

// MARK: - Semantic Surface Colors

extension Color {
    /// Warm charcoal for dark mode "candlelit" surfaces
    /// Used instead of pure black for hero transitions and prayer backgrounds
    /// Lifted slightly for brighter hero images - warm deep brown, not near-black
    /// Hex approximately #29231C
    static let warmCharcoal = Color(red: 0.16, green: 0.14, blue: 0.11)
}

// MARK: - State Overlay Utilities

/// State overlay utilities for consistent interaction feedback
enum Colors {
    enum StateOverlay {
        /// Pressed state for button feedback
        static func pressed(_ base: Color) -> Color {
            base.opacity(Theme.Opacity.pressed)
        }

        /// Selection background (verse selection, text selection)
        static func selection(_ base: Color) -> Color {
            base.opacity(Theme.Opacity.selectionBackground)
        }

        /// Focus stroke (input focus rings)
        static func focusStroke(_ accent: Color) -> Color {
            accent.opacity(Theme.Opacity.focusStroke)
        }

        /// Disabled state
        static func disabled(_ base: Color) -> Color {
            base.opacity(Theme.Opacity.disabled)
        }
    }
}

// MARK: - Highlight Colors

/// Highlight color options for verse annotations
/// All highlight colors are defined in Asset Catalog with light/dark mode variants
enum HighlightColor: String, CaseIterable, Codable {
    case blue
    case green
    case amber
    case rose
    case purple

    /// Highlight color with automatic light/dark mode adaptation
    /// Asset Catalog handles the opacity variation:
    /// - Light mode: 16% opacity (restrained on paper)
    /// - Dark mode: 24% opacity (visible on dark background)
    var color: Color {
        switch self {
        case .blue: return Color("HighlightBlue")
        case .green: return Color("HighlightGreen")
        case .amber: return Color("HighlightAmber")
        case .rose: return Color("HighlightRose")
        case .purple: return Color("HighlightPurple")
        }
    }

    /// Solid (full opacity) color for color dots and previews
    var solidColor: Color {
        switch self {
        case .blue: return Color("FeedbackInfo")
        case .green: return Color("FeedbackSuccess")
        case .amber: return Color("FeedbackWarning")
        case .rose: return Color("AccentBronze")
        case .purple: return Color("AppAccentAction")
        }
    }

    var displayName: String {
        switch self {
        case .blue: return "Blue"
        case .green: return "Green"
        case .amber: return "Amber"
        case .rose: return "Rose"
        case .purple: return "Purple"
        }
    }

    var accessibilityName: String {
        switch self {
        case .blue: return "Blue highlight"
        case .green: return "Green highlight"
        case .amber: return "Amber highlight"
        case .rose: return "Rose highlight"
        case .purple: return "Purple highlight"
        }
    }
}

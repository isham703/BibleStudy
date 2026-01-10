//
//  TypographyPreferences.swift
//  BibleStudy
//
//  Typography style preferences for user-customizable display options
//

import SwiftUI

// MARK: - DropCapStyle

/// User preference for drop cap style in reading mode
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

/// User preference for verse number display style
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

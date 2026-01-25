//
//  ThemeMatchResult.swift
//  BibleStudy
//
//  Result of theme normalization with confidence and match type.
//

import Foundation

// MARK: - Theme Match Type

enum ThemeMatchType: String, Codable, Sendable {
    /// Direct dictionary match (highest confidence)
    case exact
    /// Token overlap match (medium confidence)
    case fuzzy
    /// No match found
    case unmatched
}

// MARK: - Theme Match Result

struct ThemeMatchResult: Sendable {
    /// The normalized theme (nil if unmatched)
    let theme: NormalizedTheme?
    /// Confidence score 0.0-1.0
    let confidence: Double
    /// How the match was made
    let matchType: ThemeMatchType
    /// Original AI-generated theme string
    let sourceTheme: String

    /// Whether this result has a valid theme match
    var isMatched: Bool { theme != nil }
}

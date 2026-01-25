//
//  ThemeCanonicalizer.swift
//  BibleStudy
//
//  Canonicalizes raw theme strings for consistent matching.
//  Handles curly quotes, punctuation, whitespace, and stopwords.
//

import Foundation

// MARK: - Theme Canonicalizer

struct ThemeCanonicalizer {

    /// Stopwords to remove during canonicalization
    private static let stopwords: Set<String> = [
        "the", "a", "an", "of", "in", "on", "to", "for", "with",
        "and", "or", "but", "is", "are", "was", "were", "be", "been",
        "gods", "god", "christ", "jesus", "lord", "holy", "spirit",
        "our", "his", "her", "their", "your", "my", "its"
    ]

    /// Result of canonicalization
    struct CanonicalizedTheme: Sendable {
        /// Full canonical key for dictionary lookup
        let key: String
        /// Individual tokens for fuzzy matching
        let tokens: Set<String>
    }

    /// Canonicalize a raw theme string for consistent matching
    /// - Parameter rawTheme: The original AI-generated theme string
    /// - Returns: Canonical key for dictionary lookup and tokens for fuzzy matching
    static func canonicalize(_ rawTheme: String) -> CanonicalizedTheme {
        // 1. Lowercase
        var text = rawTheme.lowercased()

        // 2. Replace curly quotes with straight
        text = text.replacingOccurrences(of: "\u{2018}", with: "'")  // Left single quote
        text = text.replacingOccurrences(of: "\u{2019}", with: "'")  // Right single quote
        text = text.replacingOccurrences(of: "\u{201C}", with: "\"") // Left double quote
        text = text.replacingOccurrences(of: "\u{201D}", with: "\"") // Right double quote
        text = text.replacingOccurrences(of: "\u{2014}", with: " ")  // Em dash
        text = text.replacingOccurrences(of: "\u{2013}", with: " ")  // En dash

        // 3. Remove punctuation except letters/numbers/spaces
        let allowed = CharacterSet.alphanumerics.union(.whitespaces)
        text = String(text.unicodeScalars.filter { allowed.contains($0) })

        // 4. Collapse whitespace and trim
        let words = text.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        text = words.joined(separator: " ")

        // 5. Extract tokens (without stopwords)
        let allTokens = Set(words)
        let meaningfulTokens = allTokens.subtracting(stopwords)

        // 6. Create canonical key (full phrase)
        let key = text.trimmingCharacters(in: .whitespaces)

        return CanonicalizedTheme(key: key, tokens: meaningfulTokens)
    }
}

//
//  LanguageLoader.swift
//  BibleStudy
//
//  Domain loader for Hebrew/Greek language tokens
//  Encapsulates database access and display mapping
//

import Foundation

// Note: LanguageTokenDisplay is defined in BibleInsightViewModel.swift

// MARK: - Language Load Result

/// Result of loading language tokens
struct LanguageLoadResult: Sendable {
    let tokens: [LanguageTokenDisplay]
    let error: Error?

    static let empty = LanguageLoadResult(tokens: [], error: nil)
}

// MARK: - Language Loader

/// Loads Hebrew/Greek language tokens for verses
/// Handles database access and fallback to samples
@MainActor
final class LanguageLoader {
    // MARK: - Dependencies

    private let languageService: LanguageServiceProtocol

    // MARK: - Initialization

    init(languageService: LanguageServiceProtocol? = nil) {
        self.languageService = languageService ?? LanguageService.shared
    }

    // MARK: - Load Language Tokens

    /// Load language tokens for a verse range
    /// - Parameter verseRange: The verse range to load tokens for
    /// - Returns: LanguageLoadResult with tokens or error
    func load(for verseRange: VerseRange) async -> LanguageLoadResult {
        var tokens: [LanguageToken] = []

        do {
            tokens = try languageService.getTokens(for: verseRange)
        } catch {
            // Fall back to sample data
            tokens = languageService.getSampleTokens(for: verseRange)

            // If still empty, use defaults
            if tokens.isEmpty {
                return LanguageLoadResult(tokens: defaultSamples(), error: error)
            }

            return LanguageLoadResult(
                tokens: tokens.map { LanguageTokenDisplay(from: $0) },
                error: error
            )
        }

        // Convert to display tokens
        let displayTokens = tokens.map { LanguageTokenDisplay(from: $0) }

        // If no tokens found, provide default samples
        if displayTokens.isEmpty {
            return LanguageLoadResult(tokens: defaultSamples(), error: nil)
        }

        return LanguageLoadResult(tokens: displayTokens, error: nil)
    }

    // MARK: - Default Samples

    private func defaultSamples() -> [LanguageTokenDisplay] {
        [
            LanguageTokenDisplay(
                id: "1",
                surface: "יְהִי",
                transliteration: "yehi",
                lemma: "הָיָה",
                gloss: "let there be",
                morph: "V-Qal-Jussive-3ms",
                language: "hebrew",
                strongsNumber: "H1961",
                partOfSpeech: "Verb",
                plainEnglishMorph: "Command form ('let it be'), third person singular",
                grammaticalSignificance: "Expresses a divine command—something that should happen."
            ),
            LanguageTokenDisplay(
                id: "2",
                surface: "אוֹר",
                transliteration: "'or",
                lemma: "אוֹר",
                gloss: "light",
                morph: "N-ms",
                language: "hebrew",
                strongsNumber: "H216",
                partOfSpeech: "Noun",
                plainEnglishMorph: "A masculine, singular noun",
                grammaticalSignificance: "Names the thing being created."
            )
        ]
    }
}

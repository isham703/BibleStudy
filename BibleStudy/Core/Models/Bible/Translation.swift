import Foundation

// MARK: - Bible Translation Model
// Represents a Bible translation (e.g., KJV, ESV, NIV)

struct Translation: Identifiable, Codable, Hashable, Sendable {
    let id: String               // Unique identifier (e.g., "kjv", "esv")
    let name: String             // Full name (e.g., "King James Version")
    let abbreviation: String     // Short form (e.g., "KJV")
    let language: String         // Language code (e.g., "en")
    let translationInfo: String  // Brief description
    let copyright: String?       // Copyright notice
    let isDefault: Bool          // Whether this is the default translation
    let sortOrder: Int           // Display order in lists
    let isAvailable: Bool        // Whether offline data is available (false = "Coming Soon")

    var displayName: String { abbreviation }

    /// Status text for UI display
    var availabilityStatus: String? {
        isAvailable ? nil : "Coming Soon"
    }
}

// MARK: - Built-in Translations Data
extension Translation {
    /// Only KJV is included - it's public domain and freely redistributable.
    /// Other translations (ESV, NIV, NASB, NLT, NKJV) require licensing agreements.
    fileprivate static var builtInTranslations: [Translation] {[
        Translation(
            id: "kjv",
            name: "King James Version",
            abbreviation: "KJV",
            language: "en",
            translationInfo: "The classic 1611 English translation, beloved for its literary beauty and precision",
            copyright: "Public Domain",
            isDefault: true,
            sortOrder: 1,
            isAvailable: true
        )
    ]}
}

// MARK: - Translation Lookup
extension Translation {
    /// Find a translation by ID from built-in list
    static func find(byId id: String) -> Translation? {
        Self.builtInTranslations.first { $0.id == id }
    }

    /// Get the default translation
    static func getDefault() -> Translation {
        Self.builtInTranslations.first { $0.isDefault && $0.isAvailable } ?? Self.builtInTranslations[0]
    }

    /// All built-in translations (including unavailable)
    static func getAll() -> [Translation] {
        Self.builtInTranslations
    }

    /// Only translations with offline data available
    static func getAvailable() -> [Translation] {
        Self.builtInTranslations.filter { $0.isAvailable }
    }

    /// Translations marked as "Coming Soon"
    static func getComingSoon() -> [Translation] {
        Self.builtInTranslations.filter { !$0.isAvailable }
    }
}

// MARK: - Translation Comparison Support
extension Translation {
    /// Categories for grouping translations by translation philosophy
    enum TranslationPhilosophy: String, CaseIterable {
        case wordForWord = "Word-for-Word"
        case thoughtForThought = "Thought-for-Thought"
        case paraphrase = "Paraphrase"

        var info: String {
            switch self {
            case .wordForWord:
                return "Formal equivalence - closest to original languages"
            case .thoughtForThought:
                return "Dynamic equivalence - meaning-focused translation"
            case .paraphrase:
                return "Free translation for maximum readability"
            }
        }
    }

    var translationType: TranslationPhilosophy {
        switch id {
        case "kjv":
            return .wordForWord
        default:
            return .wordForWord
        }
    }
}

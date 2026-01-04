import Foundation

// MARK: - Plain English Morphology
// Converts technical morphology codes to human-readable descriptions
// Goal: Make Hebrew/Greek grammar accessible without seminary training

enum PlainEnglishMorphology {

    // MARK: - Transliteration

    /// Basic transliteration for Hebrew and Greek text
    /// In production, use a comprehensive transliteration library
    static func transliterate(_ text: String, language: Language) -> String {
        switch language {
        case .hebrew:
            return transliterateHebrew(text)
        case .greek:
            return transliterateGreek(text)
        }
    }

    private static func transliterateHebrew(_ text: String) -> String {
        // Hebrew transliteration mapping
        let hebrewMap: [Character: String] = [
            "א": "'", "ב": "v", "ג": "g", "ד": "d", "ה": "h",
            "ו": "v", "ז": "z", "ח": "ch", "ט": "t", "י": "y",
            "כ": "kh", "ך": "kh", "ל": "l", "מ": "m", "ם": "m",
            "נ": "n", "ן": "n", "ס": "s", "ע": "'", "פ": "f",
            "ף": "f", "צ": "ts", "ץ": "ts", "ק": "q", "ר": "r",
            "ש": "sh", "ת": "t",
            // With dagesh
            "בּ": "b", "כּ": "k", "פּ": "p",
            // Vowels (simplified)
            "ָ": "a", "ַ": "a", "ֶ": "e", "ֵ": "e", "ִ": "i",
            "ֹ": "o", "ֻ": "u", "ְ": "", "ֲ": "a", "ֱ": "e",
            "ֳ": "o"
        ]

        var result = ""
        for char in text {
            if let mapped = hebrewMap[char] {
                result += mapped
            } else if char.isLetter {
                result += String(char)
            }
        }
        return result.isEmpty ? text : result
    }

    private static func transliterateGreek(_ text: String) -> String {
        // Greek transliteration mapping
        let greekMap: [Character: String] = [
            "α": "a", "β": "b", "γ": "g", "δ": "d", "ε": "e",
            "ζ": "z", "η": "ē", "θ": "th", "ι": "i", "κ": "k",
            "λ": "l", "μ": "m", "ν": "n", "ξ": "x", "ο": "o",
            "π": "p", "ρ": "r", "σ": "s", "ς": "s", "τ": "t",
            "υ": "u", "φ": "ph", "χ": "ch", "ψ": "ps", "ω": "ō",
            // Uppercase
            "Α": "A", "Β": "B", "Γ": "G", "Δ": "D", "Ε": "E",
            "Ζ": "Z", "Η": "Ē", "Θ": "Th", "Ι": "I", "Κ": "K",
            "Λ": "L", "Μ": "M", "Ν": "N", "Ξ": "X", "Ο": "O",
            "Π": "P", "Ρ": "R", "Σ": "S", "Τ": "T", "Υ": "U",
            "Φ": "Ph", "Χ": "Ch", "Ψ": "Ps", "Ω": "Ō"
        ]

        var result = ""
        for char in text {
            // Remove diacritics for simpler transliteration
            let charString = String(char)
            let baseString = charString.decomposedStringWithCanonicalMapping
            let baseChar = baseString.first ?? char

            if let mapped = greekMap[baseChar] {
                result += mapped
            } else if char.isLetter {
                result += String(char)
            }
        }
        return result.isEmpty ? text : result
    }

    // MARK: - Main Entry Point

    /// Convert a morphology code to plain English description
    static func describe(_ code: String, language: Language) -> MorphologyDescription {
        switch language {
        case .hebrew:
            return describeHebrew(code)
        case .greek:
            return describeGreek(code)
        }
    }

    // MARK: - Hebrew Morphology

    private static func describeHebrew(_ code: String) -> MorphologyDescription {
        let normalized = code.uppercased()

        // Parse the morphology code
        var partOfSpeech = ""
        var plainDescription = ""
        var significance = ""

        // Determine part of speech and main characteristics
        if normalized.hasPrefix("V") {
            let verbInfo = parseHebrewVerb(normalized)
            partOfSpeech = "Verb"
            plainDescription = verbInfo.description
            significance = verbInfo.significance
        } else if normalized.hasPrefix("N") {
            let nounInfo = parseHebrewNoun(normalized)
            partOfSpeech = "Noun"
            plainDescription = nounInfo.description
            significance = nounInfo.significance
        } else if normalized.hasPrefix("A") {
            partOfSpeech = "Adjective"
            plainDescription = parseHebrewAdjective(normalized)
            significance = "Describes a quality or characteristic."
        } else if normalized.hasPrefix("P") || normalized.contains("PREP") {
            partOfSpeech = "Preposition"
            plainDescription = "Shows relationship between words."
            significance = "Indicates location, direction, or association."
        } else if normalized.hasPrefix("C") || normalized.contains("CONJ") {
            partOfSpeech = "Conjunction"
            plainDescription = "Connects words or ideas."
            significance = "Links thoughts together in the narrative."
        } else if normalized.hasPrefix("D") || normalized.contains("ART") {
            partOfSpeech = "Article"
            plainDescription = "The definite article 'the'."
            significance = "Makes the noun specific rather than general."
        } else if normalized.contains("PRON") || normalized.hasPrefix("R") {
            partOfSpeech = "Pronoun"
            plainDescription = parseHebrewPronoun(normalized)
            significance = "Refers back to someone or something mentioned."
        } else {
            partOfSpeech = "Word"
            plainDescription = "A building block of the sentence."
            significance = ""
        }

        return MorphologyDescription(
            partOfSpeech: partOfSpeech,
            plainDescription: plainDescription,
            grammaticalSignificance: significance,
            technicalCode: code
        )
    }

    private static func parseHebrewVerb(_ code: String) -> (description: String, significance: String) {
        var aspects: [String] = []
        var significance = ""

        // Stem (binyan)
        if code.contains("QAL") || code.contains("Q") && !code.contains("QP") {
            aspects.append("simple action")
            significance = "The basic, simple form of the action."
        } else if code.contains("NIPH") || code.contains("N") {
            aspects.append("passive or reflexive action")
            significance = "The subject receives the action or acts on itself."
        } else if code.contains("PIEL") || code.contains("PI") {
            aspects.append("intensive action")
            significance = "The action is intensified, repeated, or causative."
        } else if code.contains("PUAL") || code.contains("PU") {
            aspects.append("intensive passive")
            significance = "Intensified action received by the subject."
        } else if code.contains("HIPH") || code.contains("H") {
            aspects.append("causative action")
            significance = "The subject causes someone else to do the action."
        } else if code.contains("HOPH") || code.contains("HO") {
            aspects.append("causative passive")
            significance = "The subject is caused to receive an action."
        } else if code.contains("HITH") || code.contains("HT") {
            aspects.append("reflexive action")
            significance = "The subject acts upon itself."
        }

        // Aspect/Tense
        if code.contains("PERF") || code.contains("P") && code.count > 2 {
            aspects.append("completed action")
            if significance.isEmpty {
                significance = "The action is viewed as complete or certain."
            }
        } else if code.contains("IMPF") || code.contains("I") {
            aspects.append("ongoing or future action")
            if significance.isEmpty {
                significance = "The action is incomplete, ongoing, or yet to happen."
            }
        } else if code.contains("JUSS") || code.contains("J") {
            aspects.append("command form ('let it be')")
            significance = "Expresses a wish, command, or something that should happen."
        } else if code.contains("IMP") || code.contains("M") {
            aspects.append("direct command")
            significance = "A direct order or instruction to do something."
        } else if code.contains("INF") {
            aspects.append("verbal noun form")
            significance = "The action expressed as a concept or noun."
        } else if code.contains("PTCP") || code.contains("PT") {
            aspects.append("ongoing characteristic")
            significance = "Describes someone by what they do continuously."
        }

        // Person and number
        let personNumber = parsePersonNumber(code)
        if !personNumber.isEmpty {
            aspects.append(personNumber)
        }

        let description = aspects.isEmpty ? "An action word" : aspects.joined(separator: ", ").capitalized
        return (description, significance)
    }

    private static func parseHebrewNoun(_ code: String) -> (description: String, significance: String) {
        var aspects: [String] = []
        var significance = ""

        // Gender
        if code.contains("M") {
            aspects.append("masculine")
        } else if code.contains("F") {
            aspects.append("feminine")
        }

        // Number
        if code.contains("S") && !code.contains("SC") {
            aspects.append("singular (one)")
            significance = "Refers to a single thing or person."
        } else if code.contains("P") {
            aspects.append("plural (many)")
            significance = "Refers to multiple things or people."
        } else if code.contains("D") {
            aspects.append("dual (two)")
            significance = "Specifically refers to a pair of things."
        }

        // State
        if code.contains("A") && !code.contains("ART") {
            aspects.append("in absolute state")
        } else if code.contains("C") {
            aspects.append("in construct (possessive) state")
            significance = "Connected to another noun in a 'of' relationship."
        }

        let description = aspects.isEmpty ? "A naming word" : "A " + aspects.joined(separator: ", ") + " noun"
        return (description, significance.isEmpty ? "Names a person, place, thing, or idea." : significance)
    }

    private static func parseHebrewAdjective(_ code: String) -> String {
        var aspects: [String] = []

        if code.contains("M") { aspects.append("masculine") }
        if code.contains("F") { aspects.append("feminine") }
        if code.contains("S") { aspects.append("singular") }
        if code.contains("P") { aspects.append("plural") }

        return aspects.isEmpty ? "Describes a quality" : "A " + aspects.joined(separator: ", ") + " describing word"
    }

    private static func parseHebrewPronoun(_ code: String) -> String {
        var aspects: [String] = []

        if code.contains("1") { aspects.append("first person (I/we)") }
        if code.contains("2") { aspects.append("second person (you)") }
        if code.contains("3") { aspects.append("third person (he/she/they)") }
        if code.contains("S") { aspects.append("singular") }
        if code.contains("P") { aspects.append("plural") }

        return aspects.isEmpty ? "Refers to someone" : aspects.joined(separator: ", ").capitalized
    }

    // MARK: - Greek Morphology

    private static func describeGreek(_ code: String) -> MorphologyDescription {
        let normalized = code.uppercased()

        var partOfSpeech = ""
        var plainDescription = ""
        var significance = ""

        // Determine part of speech
        if normalized.hasPrefix("V") || normalized.contains("-V-") {
            let verbInfo = parseGreekVerb(normalized)
            partOfSpeech = "Verb"
            plainDescription = verbInfo.description
            significance = verbInfo.significance
        } else if normalized.hasPrefix("N") || normalized.contains("-N") {
            let nounInfo = parseGreekNoun(normalized)
            partOfSpeech = "Noun"
            plainDescription = nounInfo.description
            significance = nounInfo.significance
        } else if normalized.hasPrefix("A") || normalized.contains("-A") && !normalized.contains("AOR") {
            let adjInfo = parseGreekAdjective(normalized)
            partOfSpeech = "Adjective"
            plainDescription = adjInfo.description
            significance = adjInfo.significance
        } else if normalized.hasPrefix("P") && !normalized.contains("PART") {
            partOfSpeech = "Preposition"
            plainDescription = "Shows relationship between words."
            significance = "Indicates location, direction, or association."
        } else if normalized.hasPrefix("C") || normalized.contains("CONJ") {
            partOfSpeech = "Conjunction"
            plainDescription = "Connects words or ideas."
            significance = "Links thoughts together."
        } else if normalized.hasPrefix("D") || normalized.contains("ART") {
            let artInfo = parseGreekArticle(normalized)
            partOfSpeech = "Article"
            plainDescription = artInfo.description
            significance = artInfo.significance
        } else if normalized.contains("PRON") || normalized.hasPrefix("R") {
            partOfSpeech = "Pronoun"
            plainDescription = parseGreekPronoun(normalized)
            significance = "Refers to someone or something mentioned."
        } else if normalized.contains("ADV") || normalized.hasPrefix("D") {
            partOfSpeech = "Adverb"
            plainDescription = "Modifies how an action is done."
            significance = "Adds detail about manner, time, or place."
        } else if normalized.contains("PART") {
            partOfSpeech = "Particle"
            plainDescription = "A small word that adds meaning."
            significance = "Often adds emphasis or shows connection."
        } else {
            partOfSpeech = "Word"
            plainDescription = "A building block of the sentence."
            significance = ""
        }

        return MorphologyDescription(
            partOfSpeech: partOfSpeech,
            plainDescription: plainDescription,
            grammaticalSignificance: significance,
            technicalCode: code
        )
    }

    private static func parseGreekVerb(_ code: String) -> (description: String, significance: String) {
        var aspects: [String] = []
        var significance = ""

        // Tense
        if code.contains("PRES") || code.contains("-P-") {
            aspects.append("present/ongoing action")
            significance = "The action is happening now or continuously."
        } else if code.contains("AOR") || code.contains("-A-") {
            aspects.append("simple past action")
            significance = "The action happened at a point in time, viewed as a whole."
        } else if code.contains("IMPF") || code.contains("-I-") {
            aspects.append("ongoing past action")
            significance = "The action was happening repeatedly or continuously in the past."
        } else if code.contains("FUT") || code.contains("-F-") {
            aspects.append("future action")
            significance = "The action will happen in the future."
        } else if code.contains("PERF") || code.contains("-R-") || code.contains("-X-") {
            aspects.append("completed action with lasting results")
            significance = "The action was completed but its effects continue."
        } else if code.contains("PLUP") || code.contains("-L-") {
            aspects.append("past completed action")
            significance = "The action was already completed before another past event."
        }

        // Voice
        if code.contains("ACT") || code.contains("-A") {
            aspects.append("active voice")
            // Don't override tense significance
        } else if code.contains("MID") || code.contains("-M") {
            aspects.append("middle voice (self-involved)")
            if significance.isEmpty {
                significance = "The subject is personally involved in or affected by the action."
            }
        } else if code.contains("PASS") || code.contains("-P") && !code.contains("PRES") {
            aspects.append("passive voice")
            if significance.isEmpty {
                significance = "The subject receives the action rather than doing it."
            }
        }

        // Mood
        if code.contains("IND") {
            aspects.append("statement of fact")
        } else if code.contains("SUBJ") || code.contains("-S") {
            aspects.append("possibility or wish")
            significance = "Expresses something possible, wished for, or uncertain."
        } else if code.contains("IMP") && !code.contains("IMPF") {
            aspects.append("command")
            significance = "A direct instruction or order."
        } else if code.contains("OPT") || code.contains("-O") {
            aspects.append("wish or possibility")
            significance = "Expresses a wish or remote possibility."
        } else if code.contains("INF") {
            aspects.append("verbal noun")
            significance = "The action expressed as a concept."
        } else if code.contains("PART") || code.contains("PTC") {
            aspects.append("verbal adjective")
            significance = "Describes someone by what they are doing."
        }

        // Person and number
        let personNumber = parsePersonNumber(code)
        if !personNumber.isEmpty {
            aspects.append(personNumber)
        }

        let description = aspects.isEmpty ? "An action word" : aspects.joined(separator: ", ").capitalized
        return (description, significance)
    }

    private static func parseGreekNoun(_ code: String) -> (description: String, significance: String) {
        var aspects: [String] = []
        var significance = ""

        // Case
        if code.contains("NOM") || code.contains("-N") {
            aspects.append("subject")
            significance = "This is the one doing the action (the subject)."
        } else if code.contains("GEN") || code.contains("-G") {
            aspects.append("possessive/source")
            significance = "Shows possession, source, or 'of' relationship."
        } else if code.contains("DAT") || code.contains("-D") {
            aspects.append("indirect object")
            significance = "The one receiving something indirectly ('to' or 'for')."
        } else if code.contains("ACC") || code.contains("-A") && !code.contains("ACT") {
            aspects.append("direct object")
            significance = "The one directly receiving the action."
        } else if code.contains("VOC") || code.contains("-V") && !code.contains("VERB") {
            aspects.append("direct address")
            significance = "Someone being spoken to directly."
        }

        // Gender and number
        if code.contains("M") { aspects.append("masculine") }
        if code.contains("F") { aspects.append("feminine") }
        if code.contains("N") && !code.contains("NOM") { aspects.append("neuter") }
        if code.contains("S") && !code.contains("SUBJ") { aspects.append("singular") }
        if code.contains("P") && !code.contains("PASS") && !code.contains("PART") { aspects.append("plural") }

        let description = aspects.isEmpty ? "A naming word" : aspects.joined(separator: ", ").capitalized
        return (description, significance.isEmpty ? "Names a person, place, thing, or idea." : significance)
    }

    private static func parseGreekAdjective(_ code: String) -> (description: String, significance: String) {
        var aspects: [String] = []

        // Case (agreeing with noun)
        if code.contains("NOM") { aspects.append("describing the subject") }
        else if code.contains("GEN") { aspects.append("describing possession") }
        else if code.contains("DAT") { aspects.append("describing recipient") }
        else if code.contains("ACC") { aspects.append("describing direct object") }

        if code.contains("M") { aspects.append("masculine") }
        if code.contains("F") { aspects.append("feminine") }
        if code.contains("N") && !code.contains("NOM") { aspects.append("neuter") }
        if code.contains("S") { aspects.append("singular") }
        if code.contains("P") && !code.contains("PART") { aspects.append("plural") }

        let description = aspects.isEmpty ? "A describing word" : aspects.joined(separator: ", ").capitalized
        let significance = "Describes a quality of the noun it modifies."
        return (description, significance)
    }

    private static func parseGreekArticle(_ code: String) -> (description: String, significance: String) {
        var aspects: [String] = ["the definite article 'the'"]

        if code.contains("NOM") { aspects.append("marking the subject") }
        else if code.contains("GEN") { aspects.append("marking possession") }
        else if code.contains("DAT") { aspects.append("marking recipient") }
        else if code.contains("ACC") { aspects.append("marking direct object") }

        let description = aspects.joined(separator: ", ")
        let significance = "Makes the noun specific and definite."
        return (description, significance)
    }

    private static func parseGreekPronoun(_ code: String) -> String {
        var aspects: [String] = []

        if code.contains("1") { aspects.append("first person (I/we)") }
        if code.contains("2") { aspects.append("second person (you)") }
        if code.contains("3") { aspects.append("third person (he/she/they)") }

        if code.contains("NOM") { aspects.append("as subject") }
        else if code.contains("GEN") { aspects.append("possessive") }
        else if code.contains("DAT") { aspects.append("as recipient") }
        else if code.contains("ACC") { aspects.append("as direct object") }

        return aspects.isEmpty ? "Refers to someone" : aspects.joined(separator: ", ")
    }

    // MARK: - Helper Methods

    private static func parsePersonNumber(_ code: String) -> String {
        var parts: [String] = []

        // Person
        if code.contains("1") { parts.append("first person (I/we)") }
        else if code.contains("2") { parts.append("second person (you)") }
        else if code.contains("3") { parts.append("third person (he/she/they)") }

        // Number (avoid false positives)
        if code.contains("S") && !code.contains("SUBJ") && !code.contains("SC") {
            parts.append("singular")
        } else if code.contains("P") && !code.contains("PASS") && !code.contains("PERF") && !code.contains("PRES") && !code.contains("PART") {
            parts.append("plural")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Morphology Description

/// Human-readable morphology information
struct MorphologyDescription: Sendable {
    /// The part of speech (Verb, Noun, etc.)
    let partOfSpeech: String

    /// Plain English description of the grammatical form
    /// Example: "Completed action, third person singular"
    let plainDescription: String

    /// Why this grammatical form matters in context
    /// Example: "The action is viewed as complete or certain."
    let grammaticalSignificance: String

    /// Original technical morphology code
    let technicalCode: String

    /// Combined display string for UI
    var displayString: String {
        if plainDescription.isEmpty {
            return partOfSpeech
        }
        return "\(partOfSpeech): \(plainDescription)"
    }

    /// Short summary for compact display
    var shortSummary: String {
        partOfSpeech
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension PlainEnglishMorphology {
    /// Test cases for preview and debugging
    static let testCases: [(code: String, language: Language)] = [
        // Hebrew
        ("Vqp3ms", .hebrew),      // Qal perfect 3rd masc sing
        ("Ncfsa", .hebrew),       // Noun common fem sing absolute
        ("Vqj3ms", .hebrew),      // Qal jussive 3rd masc sing
        ("Ncmpa", .hebrew),       // Noun common masc plural absolute
        ("Prep", .hebrew),        // Preposition

        // Greek
        ("V-PAI-3S", .greek),     // Verb present active indicative 3rd sing
        ("V-AAS-3S", .greek),     // Verb aorist active subjunctive 3rd sing
        ("N-NSM", .greek),        // Noun nominative singular masculine
        ("N-GSF", .greek),        // Noun genitive singular feminine
        ("V-AAI-3P", .greek),     // Verb aorist active indicative 3rd plural
    ]
}
#endif

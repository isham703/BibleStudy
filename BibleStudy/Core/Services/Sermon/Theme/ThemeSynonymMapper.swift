//
//  ThemeSynonymMapper.swift
//  BibleStudy
//
//  Maps AI-generated theme strings to canonical NormalizedTheme values.
//  Uses exact dictionary matching with token-based fuzzy fallback.
//

import Foundation

// MARK: - Theme Synonym Mapper

struct ThemeSynonymMapper {

    // MARK: - Explicit Mappings

    /// Dictionary of canonicalized strings to themes
    static let mapping: [String: NormalizedTheme] = [
        // Salvation cluster
        "salvation": .salvation,
        "redemption": .salvation,
        "atonement": .salvation,
        "being saved": .salvation,
        "justification": .salvation,
        "born again": .salvation,
        "new birth": .salvation,
        "regeneration": .salvation,
        "ransom": .salvation,
        "redeemed": .salvation,
        "rescue": .salvation,

        // Grace cluster
        "grace": .grace,
        "unmerited favor": .grace,
        "kindness": .grace,
        "divine grace": .grace,
        "amazing grace": .grace,
        "favor": .grace,
        "gracious": .grace,

        // Forgiveness cluster
        "forgiveness": .forgiveness,
        "pardon": .forgiveness,
        "reconciliation": .forgiveness,
        "absolution": .forgiveness,
        "forgiven": .forgiveness,

        // Faith cluster
        "faith": .faith,
        "trust": .faith,
        "belief": .faith,
        "trusting": .faith,
        "walking faith": .faith,
        "confidence": .faith,
        "believing": .faith,

        // Hope cluster
        "hope": .hope,
        "expectation": .hope,
        "future hope": .hope,
        "blessed hope": .hope,
        "anticipation": .hope,

        // Perseverance cluster
        "perseverance": .perseverance,
        "endurance": .perseverance,
        "steadfastness": .perseverance,
        "patience": .perseverance,
        "pressing on": .perseverance,
        "enduring": .perseverance,

        // Love cluster
        "love": .love,
        "agape": .love,
        "charity": .love,
        "loving": .love,
        "neighbor": .love,
        "beloved": .love,

        // Humility cluster
        "humility": .humility,
        "humble": .humility,
        "meekness": .humility,
        "servant heart": .humility,
        "lowliness": .humility,
        "servanthood": .humility,

        // Wisdom cluster
        "wisdom": .wisdom,
        "discernment": .wisdom,
        "knowledge": .wisdom,
        "understanding": .wisdom,
        "prudence": .wisdom,
        "insight": .wisdom,

        // Obedience cluster
        "obedience": .obedience,
        "obey": .obedience,
        "following": .obedience,
        "submission": .obedience,
        "commandments": .obedience,
        "discipleship": .obedience,
        "obedient": .obedience,

        // Righteousness cluster
        "righteousness": .righteousness,
        "righteous": .righteousness,
        "holy living": .righteousness,
        "moral uprightness": .righteousness,
        "virtue": .righteousness,
        "purity": .righteousness,
        "upright": .righteousness,

        // Prayer cluster
        "prayer": .prayer,
        "pray": .prayer,
        "praying": .prayer,
        "communion": .prayer,
        "intercession": .prayer,
        "supplication": .prayer,

        // Worship cluster
        "worship": .worship,
        "praise": .worship,
        "adoration": .worship,
        "glorifying": .worship,
        "praising": .worship,
        "exalt": .worship,

        // Holiness cluster
        "holiness": .holiness,
        "sanctification": .holiness,
        "consecration": .holiness,
        "set apart": .holiness,
        "sacred": .holiness,
        "sanctify": .holiness,

        // Fellowship cluster
        "fellowship": .fellowship,
        "community": .fellowship,
        "church body": .fellowship,
        "unity": .fellowship,
        "brotherhood": .fellowship,
        "congregation": .fellowship,

        // Service cluster
        "service": .service,
        "ministry": .service,
        "serving": .service,
        "helping others": .service,
        "stewardship": .service,
        "minister": .service,

        // Evangelism cluster
        "evangelism": .evangelism,
        "gospel": .evangelism,
        "missions": .evangelism,
        "witnessing": .evangelism,
        "great commission": .evangelism,
        "proclaim": .evangelism,
        "preach": .evangelism,

        // Suffering cluster
        "suffering": .suffering,
        "trials": .suffering,
        "tribulation": .suffering,
        "persecution": .suffering,
        "hardship": .suffering,
        "affliction": .suffering,
        "trial": .suffering,

        // Healing cluster
        "healing": .healing,
        "restoration": .healing,
        "wholeness": .healing,
        "recovery": .healing,
        "heal": .healing,
        "restore": .healing,

        // Transformation cluster
        "transformation": .transformation,
        "renewal": .transformation,
        "spiritual growth": .transformation,
        "change": .transformation,
        "becoming": .transformation,
        "renewed": .transformation,
        "renew": .transformation,

        // Sovereignty cluster
        "sovereignty": .sovereignty,
        "sovereign": .sovereignty,
        "providence": .sovereignty,
        "control": .sovereignty,
        "divine plan": .sovereignty,
        "predestination": .sovereignty,
        "omnipotent": .sovereignty,

        // Faithfulness cluster
        "faithfulness": .faithfulness,
        "faithful": .faithfulness,
        "reliability": .faithfulness,
        "covenant keeping": .faithfulness,
        "promises": .faithfulness,
        "dependable": .faithfulness,

        // Mercy cluster
        "mercy": .mercy,
        "compassion": .mercy,
        "loving kindness": .mercy,
        "pity": .mercy,
        "merciful": .mercy,
        "compassionate": .mercy,

        // Justice cluster
        "justice": .justice,
        "judgment": .justice,
        "equity": .justice,
        "fairness": .justice,
        "just": .justice,
        "righteous judgment": .justice,

        // Kingdom cluster
        "kingdom": .kingdom,
        "reign": .kingdom,
        "rule": .kingdom,
        "dominion": .kingdom,
        "throne": .kingdom,
        "royal": .kingdom,

        // Eternity cluster
        "eternity": .eternity,
        "heaven": .eternity,
        "afterlife": .eternity,
        "eternal life": .eternity,
        "everlasting": .eternity,
        "immortality": .eternity,
        "forever": .eternity,

        // Truth cluster
        "truth": .truth,
        "doctrine": .truth,
        "biblical truth": .truth,
        "scripture": .truth,
        "word": .truth,
        "revelation": .truth,

        // Covenant cluster
        "covenant": .covenant,
        "promise": .covenant,
        "agreement": .covenant,
        "testament": .covenant,
        "oath": .covenant,
        "vow": .covenant,
    ]

    // MARK: - Normalization

    /// Normalize a raw theme string to a canonical theme
    /// - Parameter rawTheme: The original AI-generated theme string
    /// - Returns: Match result with theme, confidence, and match type
    static func normalize(_ rawTheme: String) -> ThemeMatchResult {
        let canonical = ThemeCanonicalizer.canonicalize(rawTheme)

        // 1. Try exact mapping first
        if let theme = mapping[canonical.key] {
            return ThemeMatchResult(
                theme: theme,
                confidence: 1.0,
                matchType: .exact,
                sourceTheme: rawTheme
            )
        }

        // 2. Try fuzzy token-based matching
        if let fuzzyResult = fuzzyMatch(tokens: canonical.tokens, rawTheme: rawTheme) {
            return fuzzyResult
        }

        // 3. No match found
        return ThemeMatchResult(
            theme: nil,
            confidence: 0.0,
            matchType: .unmatched,
            sourceTheme: rawTheme
        )
    }

    // MARK: - Fuzzy Matching

    /// Fuzzy match using token overlap scoring (Jaccard similarity)
    /// - Parameters:
    ///   - tokens: Canonicalized tokens from the raw theme
    ///   - rawTheme: Original theme string for result
    /// - Returns: Match result if confidence threshold met, nil otherwise
    static func fuzzyMatch(tokens: Set<String>, rawTheme: String) -> ThemeMatchResult? {
        guard !tokens.isEmpty else { return nil }

        var bestMatch: NormalizedTheme?
        var bestScore: Double = 0.0

        for theme in NormalizedTheme.allCases {
            let themeKeywords = theme.keywords

            // Calculate Jaccard similarity: |A ∩ B| / |A ∪ B|
            let intersection = tokens.intersection(themeKeywords)
            let union = tokens.union(themeKeywords)

            guard !union.isEmpty else { continue }

            let jaccard = Double(intersection.count) / Double(union.count)

            // Boost score for exact keyword matches
            let exactBoost: Double = intersection.count > 0 ? 0.1 : 0.0

            let score = jaccard + exactBoost

            if score > bestScore {
                bestScore = score
                bestMatch = theme
            }
        }

        // Only return if confidence threshold met (0.25 minimum)
        guard let match = bestMatch, bestScore >= 0.25 else {
            return nil
        }

        // Map score to confidence (0.25-1.0 → 0.6-0.9)
        let confidence = min(0.9, 0.6 + (bestScore - 0.25) * 0.4)

        return ThemeMatchResult(
            theme: match,
            confidence: confidence,
            matchType: .fuzzy,
            sourceTheme: rawTheme
        )
    }
}

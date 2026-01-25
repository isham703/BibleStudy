//
//  NormalizedTheme.swift
//  BibleStudy
//
//  Controlled taxonomy of 27 canonical theological themes.
//  Maps AI-generated free-form themes to consistent groups.
//

import Foundation

// MARK: - Normalized Theme

enum NormalizedTheme: String, CaseIterable, Codable, Sendable, Identifiable {
    // Salvation & Redemption
    case salvation
    case grace
    case forgiveness

    // Faith & Trust
    case faith
    case hope
    case perseverance

    // Character & Virtue
    case love
    case humility
    case wisdom
    case obedience
    case righteousness

    // Relationship with God
    case prayer
    case worship
    case holiness

    // Community & Service
    case fellowship
    case service
    case evangelism

    // Trials & Growth
    case suffering
    case healing
    case transformation

    // God's Nature
    case sovereignty
    case faithfulness
    case mercy
    case justice

    // Eschatology & Future
    case kingdom
    case eternity

    // Scripture & Truth
    case truth
    case covenant

    // MARK: - Identifiable

    var id: String { rawValue }

    // MARK: - Display

    var displayName: String {
        switch self {
        case .salvation: return "Salvation"
        case .grace: return "Grace"
        case .forgiveness: return "Forgiveness"
        case .faith: return "Faith"
        case .hope: return "Hope"
        case .perseverance: return "Perseverance"
        case .love: return "Love"
        case .humility: return "Humility"
        case .wisdom: return "Wisdom"
        case .obedience: return "Obedience"
        case .righteousness: return "Righteousness"
        case .prayer: return "Prayer"
        case .worship: return "Worship"
        case .holiness: return "Holiness"
        case .fellowship: return "Fellowship"
        case .service: return "Service"
        case .evangelism: return "Evangelism"
        case .suffering: return "Suffering"
        case .healing: return "Healing"
        case .transformation: return "Transformation"
        case .sovereignty: return "Sovereignty"
        case .faithfulness: return "Faithfulness"
        case .mercy: return "Mercy"
        case .justice: return "Justice"
        case .kingdom: return "Kingdom"
        case .eternity: return "Eternity"
        case .truth: return "Truth"
        case .covenant: return "Covenant"
        }
    }

    var icon: String {
        switch self {
        case .salvation: return "cross"
        case .grace: return "gift"
        case .forgiveness: return "arrow.uturn.backward.circle"
        case .faith: return "heart"
        case .hope: return "sunrise"
        case .perseverance: return "figure.walk"
        case .love: return "heart.fill"
        case .humility: return "person.crop.circle.badge.minus"
        case .wisdom: return "lightbulb"
        case .obedience: return "checkmark.seal"
        case .righteousness: return "scale.3d"
        case .prayer: return "hands.sparkles"
        case .worship: return "music.note"
        case .holiness: return "sparkles"
        case .fellowship: return "person.3"
        case .service: return "hand.raised"
        case .evangelism: return "megaphone"
        case .suffering: return "cloud.rain"
        case .healing: return "bandage"
        case .transformation: return "arrow.triangle.2.circlepath"
        case .sovereignty: return "crown"
        case .faithfulness: return "shield.checkered"
        case .mercy: return "drop"
        case .justice: return "scalemass"
        case .kingdom: return "building.columns"
        case .eternity: return "infinity"
        case .truth: return "book.closed"
        case .covenant: return "signature"
        }
    }

    /// Keywords for token-based fuzzy matching
    var keywords: Set<String> {
        switch self {
        case .salvation:
            return ["salvation", "redemption", "atonement", "saved", "redeemed", "savior", "justification", "born", "again", "ransom", "rescue"]
        case .grace:
            return ["grace", "unmerited", "favor", "kindness", "gift", "freely", "gracious", "favor"]
        case .forgiveness:
            return ["forgiveness", "forgive", "pardon", "reconciliation", "reconcile", "absolution", "forgiven"]
        case .faith:
            return ["faith", "trust", "believe", "belief", "confidence", "trusting", "faithful", "believing"]
        case .hope:
            return ["hope", "expectation", "future", "anticipation", "hopeful", "promising", "await"]
        case .perseverance:
            return ["perseverance", "endurance", "steadfast", "persist", "patience", "patient", "endure", "pressing"]
        case .love:
            return ["love", "agape", "charity", "loving", "beloved", "affection", "neighbor"]
        case .humility:
            return ["humility", "humble", "meek", "meekness", "servant", "lowly", "modest", "servanthood"]
        case .wisdom:
            return ["wisdom", "wise", "discernment", "knowledge", "understanding", "prudent", "insight", "discern"]
        case .obedience:
            return ["obedience", "obey", "obedient", "follow", "submit", "submission", "commandments", "discipleship"]
        case .righteousness:
            return ["righteousness", "righteous", "moral", "uprightness", "virtue", "virtuous", "upright"]
        case .prayer:
            return ["prayer", "pray", "praying", "supplication", "intercession", "petition", "communion"]
        case .worship:
            return ["worship", "praise", "adoration", "glorify", "exalt", "magnify", "praising"]
        case .holiness:
            return ["holiness", "sanctification", "sanctify", "sacred", "pure", "purity", "consecrate", "holy"]
        case .fellowship:
            return ["fellowship", "community", "church", "unity", "together", "body", "congregation", "brotherhood"]
        case .service:
            return ["service", "serve", "ministry", "minister", "help", "helping", "servant", "stewardship"]
        case .evangelism:
            return ["evangelism", "gospel", "witness", "missions", "missionary", "proclaim", "preach", "commission"]
        case .suffering:
            return ["suffering", "trial", "tribulation", "hardship", "persecution", "affliction", "pain", "trials"]
        case .healing:
            return ["healing", "heal", "restoration", "restore", "wholeness", "recovery", "healed"]
        case .transformation:
            return ["transformation", "transform", "renewal", "renew", "growth", "change", "becoming", "renewed"]
        case .sovereignty:
            return ["sovereignty", "sovereign", "providence", "providential", "control", "reign", "almighty", "omnipotent"]
        case .faithfulness:
            return ["faithfulness", "faithful", "reliable", "steadfast", "dependable", "trustworthy"]
        case .mercy:
            return ["mercy", "merciful", "compassion", "compassionate", "pity", "tenderness"]
        case .justice:
            return ["justice", "just", "judgment", "equity", "fair", "fairness", "righteous"]
        case .kingdom:
            return ["kingdom", "reign", "rule", "king", "throne", "dominion", "royal"]
        case .eternity:
            return ["eternity", "eternal", "heaven", "afterlife", "immortal", "everlasting", "forever", "heavenly"]
        case .truth:
            return ["truth", "true", "doctrine", "scripture", "word", "biblical", "revelation"]
        case .covenant:
            return ["covenant", "promise", "agreement", "testament", "vow", "oath", "promises"]
        }
    }
}

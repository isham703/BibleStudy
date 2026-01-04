import Foundation

// MARK: - Prayer Tradition
// The four prayer traditions available for AI-crafted prayers

enum PrayerTradition: String, CaseIterable, Identifiable {
    case psalmicLament = "Psalmic Lament"
    case desertFathers = "Desert Fathers"
    case celtic = "Celtic"
    case ignatian = "Ignatian"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .psalmicLament: return "Psalmic"
        case .desertFathers: return "Desert"
        case .celtic: return "Celtic"
        case .ignatian: return "Ignatian"
        }
    }

    var description: String {
        switch self {
        case .psalmicLament:
            return "In the language of the Psalms—raw, honest, moving from lament to trust"
        case .desertFathers:
            return "Brief, piercing wisdom from the Egyptian desert monastics"
        case .celtic:
            return "Nature-woven prayers celebrating God's presence in creation"
        case .ignatian:
            return "Imaginative, conversational prayers engaging all the senses"
        }
    }
}

// MARK: - Mock Prayer Data

struct MockPrayer {
    let tradition: PrayerTradition
    let content: String
    let amen: String

    static let psalmicLament = MockPrayer(
        tradition: .psalmicLament,
        content: """
        O Lord, You who count the stars
        and call each one by name,
        surely You see my son
        wandering in distant places.

        My heart is heavy as stone in deep waters.
        I have cried until there are no more tears,
        yet still the ache remains,
        a wound that will not close.

        But I remember Your faithfulness—
        how You sought the lost sheep,
        how You waited for the prodigal,
        how Your arms never tire of reaching.

        So I will trust, even in this darkness.
        I will hope, even when hope seems foolish.
        For You are the God who brings
        dead things back to life.

        Watch over him, Lord.
        Where I cannot go, go with him.
        Where my voice cannot reach,
        let Your Spirit whisper love.
        """,
        amen: "Amen."
    )

    static let desertFathers = MockPrayer(
        tradition: .desertFathers,
        content: """
        Lord Jesus Christ,
        Son of the Living God,
        have mercy on me, a sinner.

        In the silence of my cell,
        I bring before You this weight—
        the one who has wandered far.

        You descended into the depths.
        You harrowed hell itself.
        No distance is too far for Your love.

        Grant me patience.
        Grant me stillness.
        Grant me trust in Your hidden work.

        For what seems lost to me
        is never lost to You.
        """,
        amen: "Kyrie eleison."
    )

    static let celtic = MockPrayer(
        tradition: .celtic,
        content: """
        God of the wild places,
        of the wind and the wave,
        of the mountain and the moor—
        be with my wandering one today.

        As the sun rises in the east,
        may Your light find him.
        As the rain falls upon the hills,
        may Your grace refresh him.

        Place around him a circle of protection:
        angels before, angels behind,
        angels above, angels beneath,
        Christ in every eye that sees him,
        Christ in every ear that hears him.

        May the road rise to meet his feet.
        May the wind be at his back.
        And when the wandering ends,
        may he find his way home—
        to You, and to me.
        """,
        amen: "In the name of the Three."
    )

    static let ignatian = MockPrayer(
        tradition: .ignatian,
        content: """
        Lord, I come to You as I am—
        not as I wish I were,
        but with all my worry,
        all my longing,
        all my love for this child of mine.

        Help me to see with Your eyes.
        Show me where You are already at work
        in his life, even now,
        even in the places I cannot see.

        I imagine You walking beside him.
        I see Your hand on his shoulder.
        I hear You speaking words
        only he can hear.

        Give me the grace to release him to You—
        not abandoning, but entrusting.
        Not giving up, but giving over.

        And in the waiting,
        teach me to find You here,
        in the longing itself.
        """,
        amen: "Amen."
    )

    // MARK: - Get Prayer by Tradition

    static func prayer(for tradition: PrayerTradition) -> MockPrayer {
        switch tradition {
        case .psalmicLament: return psalmicLament
        case .desertFathers: return desertFathers
        case .celtic: return celtic
        case .ignatian: return ignatian
        }
    }

    // MARK: - Words Array (for word-by-word reveal)

    var words: [String] {
        content
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
    }

    var lines: [String] {
        content
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
    }
}

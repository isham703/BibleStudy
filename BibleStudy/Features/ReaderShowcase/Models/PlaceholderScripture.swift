import Foundation

// MARK: - Placeholder Scripture
// Static placeholder Bible text for the reader showcase

struct PlaceholderScripture {

    // MARK: - Data Structures

    struct Passage {
        let reference: String
        let bookName: String
        let chapter: Int
        let verses: [Verse]

        var paragraphText: String {
            verses.map { $0.text }.joined(separator: " ")
        }

        var formattedReference: String {
            "\(bookName) \(chapter)"
        }
    }

    struct Verse: Identifiable {
        let id: Int  // verse number
        let text: String
        let annotations: [Annotation]

        init(id: Int, text: String, annotations: [Annotation] = []) {
            self.id = id
            self.text = text
            self.annotations = annotations
        }
    }

    struct Annotation: Identifiable {
        let id = UUID()
        let type: AnnotationType
        let content: String
        let greekWord: String?
        let transliteration: String?

        init(type: AnnotationType, content: String, greekWord: String? = nil, transliteration: String? = nil) {
            self.type = type
            self.content = content
            self.greekWord = greekWord
            self.transliteration = transliteration
        }
    }

    enum AnnotationType: String {
        case greek
        case crossRef
        case commentary
        case theology

        var icon: String {
            switch self {
            case .greek: return "character.book.closed"
            case .crossRef: return "arrow.triangle.branch"
            case .commentary: return "text.quote"
            case .theology: return "building.columns"
            }
        }

        var color: String {
            switch self {
            case .greek: return "greekBlue"
            case .crossRef: return "connectionAmber"
            case .commentary: return "scholarIndigo"
            case .theology: return "theologyGreen"
            }
        }
    }

    // MARK: - John 1:1-14 (For Illuminated Scriptorium - verse by verse with drop cap)

    static let johnPrologue = Passage(
        reference: "John 1:1-14",
        bookName: "John",
        chapter: 1,
        verses: [
            Verse(id: 1, text: "In the beginning was the Word, and the Word was with God, and the Word was God."),
            Verse(id: 2, text: "He was in the beginning with God."),
            Verse(id: 3, text: "All things were made through him, and without him was not any thing made that was made."),
            Verse(id: 4, text: "In him was life, and the life was the light of men."),
            Verse(id: 5, text: "The light shines in the darkness, and the darkness has not overcome it."),
            Verse(id: 6, text: "There was a man sent from God, whose name was John."),
            Verse(id: 7, text: "He came as a witness, to bear witness about the light, that all might believe through him."),
            Verse(id: 8, text: "He was not the light, but came to bear witness about the light."),
            Verse(id: 9, text: "The true light, which gives light to everyone, was coming into the world."),
            Verse(id: 10, text: "He was in the world, and the world was made through him, yet the world did not know him."),
            Verse(id: 11, text: "He came to his own, and his own people did not receive him."),
            Verse(id: 12, text: "But to all who did receive him, who believed in his name, he gave the right to become children of God,"),
            Verse(id: 13, text: "who were born, not of blood nor of the will of the flesh nor of the will of man, but of God."),
            Verse(id: 14, text: "And the Word became flesh and dwelt among us, and we have seen his glory, glory as of the only Son from the Father, full of grace and truth.")
        ]
    )

    // MARK: - Psalm 23 (For Candlelit Chapel - paragraph flow)

    static let psalm23 = Passage(
        reference: "Psalm 23",
        bookName: "Psalm",
        chapter: 23,
        verses: [
            Verse(id: 1, text: "The Lord is my shepherd; I shall not want."),
            Verse(id: 2, text: "He makes me lie down in green pastures. He leads me beside still waters."),
            Verse(id: 3, text: "He restores my soul. He leads me in paths of righteousness for his name's sake."),
            Verse(id: 4, text: "Even though I walk through the valley of the shadow of death, I will fear no evil, for you are with me; your rod and your staff, they comfort me."),
            Verse(id: 5, text: "You prepare a table before me in the presence of my enemies; you anoint my head with oil; my cup overflows."),
            Verse(id: 6, text: "Surely goodness and mercy shall follow me all the days of my life, and I shall dwell in the house of the Lord forever.")
        ]
    )

    // MARK: - Romans 8:28-30 (For Scholar's Marginalia - with annotations)

    static let romans8 = Passage(
        reference: "Romans 8:28-30",
        bookName: "Romans",
        chapter: 8,
        verses: [
            Verse(
                id: 28,
                text: "And we know that for those who love God all things work together for good, for those who are called according to his purpose.",
                annotations: [
                    Annotation(
                        type: .greek,
                        content: "works together",
                        greekWord: "συνεργεῖ",
                        transliteration: "synergei"
                    ),
                    Annotation(
                        type: .crossRef,
                        content: "Genesis 50:20 — Joseph's story shows God working through evil for good"
                    ),
                    Annotation(
                        type: .theology,
                        content: "Divine Providence: God sovereignly orchestrates all events"
                    )
                ]
            ),
            Verse(
                id: 29,
                text: "For those whom he foreknew he also predestined to be conformed to the image of his Son, in order that he might be the firstborn among many brothers.",
                annotations: [
                    Annotation(
                        type: .greek,
                        content: "foreknew",
                        greekWord: "προέγνω",
                        transliteration: "proegnō"
                    ),
                    Annotation(
                        type: .greek,
                        content: "predestined",
                        greekWord: "προώρισεν",
                        transliteration: "proōrisen"
                    ),
                    Annotation(
                        type: .commentary,
                        content: "The golden chain of salvation: foreknowledge, predestination, calling, justification, glorification"
                    )
                ]
            ),
            Verse(
                id: 30,
                text: "And those whom he predestined he also called, and those whom he called he also justified, and those whom he justified he also glorified.",
                annotations: [
                    Annotation(
                        type: .theology,
                        content: "Ordo Salutis: The logical order of salvation's application"
                    ),
                    Annotation(
                        type: .crossRef,
                        content: "Ephesians 1:3-14 — Paul's extended doxology on election"
                    )
                ]
            )
        ]
    )

    // MARK: - Get Passage by Variant

    static func passage(for variant: ReaderVariant) -> Passage {
        switch variant {
        case .illuminatedScriptorium:
            return johnPrologue
        case .candlelitChapel:
            return psalm23
        case .scholarsMarginalia:
            return romans8
        }
    }
}

import Foundation

enum ScholarInsightSummary {
    static func heroSummary(from text: String) -> String {
        let sentences = text.components(separatedBy: ". ")
        let heroSentences = sentences.prefix(2)
        return heroSentences.joined(separator: ". ") + (heroSentences.count >= 2 ? "." : "")
    }
}

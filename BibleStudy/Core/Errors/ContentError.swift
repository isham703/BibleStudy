import Foundation

// MARK: - Content Validation Error
// Errors related to user-generated content validation (notes, etc.)

enum ContentError: Error, LocalizedError, Sendable {
    case contentTooLong(limit: Int)
    case contentTooLarge(byteLimit: Int)

    var errorDescription: String? {
        switch self {
        case .contentTooLong(let limit):
            return "Note exceeds \(limit.formatted()) character limit. Please shorten your note or split it into multiple notes."
        case .contentTooLarge(let byteLimit):
            return "Note exceeds \(byteLimit.formatted()) byte size limit. Please shorten your note."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .contentTooLong:
            return "Try splitting your note into multiple smaller notes, or remove unnecessary content."
        case .contentTooLarge:
            return "Remove some characters (especially emoji or special symbols) to reduce the note size."
        }
    }
}

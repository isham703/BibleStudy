import Foundation

// MARK: - JSON Coding Utilities
// Factory methods for configured JSON coders (thread-safe)
// Using factories (not shared instances) avoids Sendable/thread-safety issues

enum JSONCodingUtilities {
    // MARK: - Decoder Factory

    /// Create a configured decoder for sermon data
    /// - Returns: A new JSONDecoder instance with standard configuration
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    // MARK: - Encoder Factory

    /// Create a configured encoder for sermon data
    /// - Returns: A new JSONEncoder instance with standard configuration
    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    // MARK: - Convenience Methods

    /// Decode data using a configured decoder
    /// - Parameters:
    ///   - type: The type to decode
    ///   - data: The data to decode from
    /// - Returns: The decoded value
    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try makeDecoder().decode(type, from: data)
    }

    /// Encode a value using a configured encoder
    /// - Parameter value: The value to encode
    /// - Returns: The encoded data
    static func encode<T: Encodable>(_ value: T) throws -> Data {
        try makeEncoder().encode(value)
    }
}

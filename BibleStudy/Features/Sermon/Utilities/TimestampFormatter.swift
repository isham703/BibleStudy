import Foundation

// MARK: - Timestamp Formatter
// Shared utility for consistent timestamp formatting across sermon features

enum TimestampFormatter {
    /// Format a time interval as HH:MM:SS or MM:SS
    /// - Parameter time: Time in seconds
    /// - Returns: Formatted string (e.g., "5:23" or "1:05:23")
    static func format(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Format a time interval with optional hours
    /// - Parameters:
    ///   - time: Time in seconds
    ///   - forceHours: Always show hours even if zero
    /// - Returns: Formatted string
    static func format(_ time: TimeInterval, forceHours: Bool) -> String {
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if forceHours || hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Format a duration for display (e.g., "5 min", "1 hr 5 min")
    /// - Parameter time: Time in seconds
    /// - Returns: Human-readable duration string
    static func formatDuration(_ time: TimeInterval) -> String {
        let totalMinutes = Int(time) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours) hr \(minutes) min"
            }
            return "\(hours) hr"
        }
        return "\(minutes) min"
    }
}

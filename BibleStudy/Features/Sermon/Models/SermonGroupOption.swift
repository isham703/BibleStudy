//
//  SermonGroupOption.swift
//  BibleStudy
//
//  Grouping and sorting options for sermon library
//  V3: Includes theme grouping with normalized taxonomy
//

import Foundation

// MARK: - Sermon Group Option

enum SermonGroupOption: String, CaseIterable, Identifiable {
    case none = "None"
    case date = "Date"
    case book = "Scripture"
    case speaker = "Speaker"
    case theme = "Theme"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .none: return "list.bullet"
        case .date: return "calendar"
        case .book: return "book"
        case .speaker: return "person"
        case .theme: return "tag"
        }
    }

    var description: String {
        switch self {
        case .none: return "Show all sermons in one list"
        case .date: return "Group by month and year"
        case .book: return "Group by primary scripture book"
        case .speaker: return "Group by speaker name"
        case .theme: return "Group by theological theme"
        }
    }
}

// MARK: - Sermon Sort Option

enum SermonSortOption: String, CaseIterable, Identifiable {
    case newest = "Newest First"
    case oldest = "Oldest First"
    case title = "Title A-Z"
    case duration = "Duration"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .newest: return "arrow.down"
        case .oldest: return "arrow.up"
        case .title: return "textformat.abc"
        case .duration: return "clock"
        }
    }
}

// MARK: - Sermon Group

/// A group of sermons with a header
struct SermonGroup: Identifiable {
    let id: String
    let title: String
    let icon: String?
    let sermons: [Sermon]

    init(id: String, title: String, icon: String? = nil, sermons: [Sermon]) {
        self.id = id
        self.title = title
        self.icon = icon
        self.sermons = sermons
    }

    var count: Int { sermons.count }

    var totalDuration: TimeInterval {
        sermons.reduce(0) { $0 + Double($1.durationSeconds) }
    }

    var formattedDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var subtitle: String {
        let countText = count == 1 ? "1 sermon" : "\(count) sermons"
        return "\(countText) · \(formattedDuration)"
    }
}

// MARK: - Date Group Keys

enum DateGroupKey: String, CaseIterable {
    case today = "Today"
    case yesterday = "Yesterday"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case lastMonth = "Last Month"
    case older = "Older"

    static func from(date: Date) -> DateGroupKey {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return .today
        } else if calendar.isDateInYesterday(date) {
            return .yesterday
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return .thisWeek
        } else if calendar.isDate(date, equalTo: now, toGranularity: .month) {
            return .thisMonth
        } else {
            // Check if last month
            if let lastMonth = calendar.date(byAdding: .month, value: -1, to: now),
               calendar.isDate(date, equalTo: lastMonth, toGranularity: .month) {
                return .lastMonth
            }
            return .older
        }
    }

    /// For older dates, generate a month-year key
    static func monthYearKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - User Defaults Keys

extension SermonGroupOption {
    static let userDefaultsKey = "sermon_group_option"

    static var saved: SermonGroupOption {
        guard let raw = UserDefaults.standard.string(forKey: userDefaultsKey),
              let option = SermonGroupOption(rawValue: raw) else {
            return .none
        }
        return option
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: Self.userDefaultsKey)
    }
}

extension SermonSortOption {
    static let userDefaultsKey = "sermon_sort_option"

    static var saved: SermonSortOption {
        guard let raw = UserDefaults.standard.string(forKey: userDefaultsKey),
              let option = SermonSortOption(rawValue: raw) else {
            return .newest
        }
        return option
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: Self.userDefaultsKey)
    }
}

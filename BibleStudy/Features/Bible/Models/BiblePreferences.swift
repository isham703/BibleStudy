import SwiftUI

// MARK: - Bible Preferences
// User preferences for Bible tab insight display and behavior

enum BibleGreekLevel: String, CaseIterable {
    case off
    case light
    case deep

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .light: return "Light"
        case .deep: return "Deep"
        }
    }

    var description: String {
        switch self {
        case .off: return "No Greek annotations"
        case .light: return "Key terms only"
        case .deep: return "Full morphology"
        }
    }
}

// MARK: - UserDefaults Keys

extension AppConfiguration.UserDefaultsKeys {
    static let scholarShowTheology = "scholarShowTheology"
    static let scholarShowReflection = "scholarShowReflection"
    static let scholarShowGreek = "scholarShowGreek"
    static let scholarShowConnections = "scholarShowConnections"
    static let scholarGreekLevel = "scholarGreekLevel"
    static let scholarAutoReveal = "scholarAutoReveal"
}

// MARK: - Bible Settings Manager
// Observable object for managing Bible preferences

@Observable
final class BibleSettings {
    static let shared = BibleSettings()

    // Insight type toggles
    var showTheology: Bool {
        didSet { save(AppConfiguration.UserDefaultsKeys.scholarShowTheology, value: showTheology) }
    }

    var showReflection: Bool {
        didSet { save(AppConfiguration.UserDefaultsKeys.scholarShowReflection, value: showReflection) }
    }

    var showGreek: Bool {
        didSet { save(AppConfiguration.UserDefaultsKeys.scholarShowGreek, value: showGreek) }
    }

    var showConnections: Bool {
        didSet { save(AppConfiguration.UserDefaultsKeys.scholarShowConnections, value: showConnections) }
    }

    // Greek annotation level
    var greekLevel: BibleGreekLevel {
        didSet {
            UserDefaults.standard.set(greekLevel.rawValue, forKey: AppConfiguration.UserDefaultsKeys.scholarGreekLevel)
        }
    }

    // Auto-reveal insights on scroll
    var autoReveal: Bool {
        didSet { save(AppConfiguration.UserDefaultsKeys.scholarAutoReveal, value: autoReveal) }
    }

    // MARK: - Initialization

    private init() {
        // Load saved preferences with defaults
        self.showTheology = UserDefaults.standard.object(forKey: AppConfiguration.UserDefaultsKeys.scholarShowTheology) as? Bool ?? true
        self.showReflection = UserDefaults.standard.object(forKey: AppConfiguration.UserDefaultsKeys.scholarShowReflection) as? Bool ?? true
        self.showGreek = UserDefaults.standard.object(forKey: AppConfiguration.UserDefaultsKeys.scholarShowGreek) as? Bool ?? false
        self.showConnections = UserDefaults.standard.object(forKey: AppConfiguration.UserDefaultsKeys.scholarShowConnections) as? Bool ?? true
        self.autoReveal = UserDefaults.standard.object(forKey: AppConfiguration.UserDefaultsKeys.scholarAutoReveal) as? Bool ?? true

        if let greekLevelRaw = UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.scholarGreekLevel),
           let level = BibleGreekLevel(rawValue: greekLevelRaw) {
            self.greekLevel = level
        } else {
            self.greekLevel = .off
        }
    }

    // MARK: - Helpers

    private func save(_ key: String, value: Bool) {
        UserDefaults.standard.set(value, forKey: key)
    }

    /// Returns enabled insight types based on current settings
    var enabledBibleInsightTypes: Set<BibleInsightType> {
        var types: Set<BibleInsightType> = []
        if showTheology { types.insert(.theology) }
        if showReflection { types.insert(.question) }
        if showGreek { types.insert(.greek) }
        if showConnections { types.insert(.connection) }
        return types
    }

    /// Check if a specific insight type is enabled
    func isEnabled(_ type: BibleInsightType) -> Bool {
        switch type {
        case .theology: return showTheology
        case .question: return showReflection
        case .greek: return showGreek
        case .connection: return showConnections
        }
    }

    /// Toggle a specific insight type
    func toggle(_ type: BibleInsightType) {
        switch type {
        case .theology: showTheology.toggle()
        case .question: showReflection.toggle()
        case .greek: showGreek.toggle()
        case .connection: showConnections.toggle()
        }
        HapticService.shared.lightTap()
    }

    /// Enable all insight types
    func enableAll() {
        showTheology = true
        showReflection = true
        showGreek = true
        showConnections = true
        HapticService.shared.lightTap()
    }

    /// Disable all insight types
    func disableAll() {
        showTheology = false
        showReflection = false
        showGreek = false
        showConnections = false
        HapticService.shared.lightTap()
    }

    /// Reset reading position
    func resetReadingPosition() {
        UserDefaults.standard.set(43, forKey: "scholarLastBookId") // John
        UserDefaults.standard.set(1, forKey: "scholarLastChapter")
        HapticService.shared.success()
    }
}

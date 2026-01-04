import Foundation
import SwiftUI

// MARK: - User Profile
// Local representation of user profile synced with Supabase

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var displayName: String?
    var preferredTranslation: String
    var fontSize: Int
    var theme: ThemeMode
    var devotionalModeEnabled: Bool
    var hasCompletedOnboarding: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        displayName: String? = nil,
        preferredTranslation: String = "KJV",
        fontSize: Int = 18,
        theme: ThemeMode = .system,
        devotionalModeEnabled: Bool = true,
        hasCompletedOnboarding: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.preferredTranslation = preferredTranslation
        self.fontSize = fontSize
        self.theme = theme
        self.devotionalModeEnabled = devotionalModeEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Theme Mode
enum ThemeMode: String, Codable, CaseIterable {
    case light
    case dark
    case system

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }

    /// The SwiftUI ColorScheme for this theme mode
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// MARK: - Conversion from DTO
extension UserProfile {
    init(from dto: UserProfileDTO) {
        self.id = dto.id
        self.displayName = dto.displayName
        self.preferredTranslation = dto.preferredTranslation
        self.fontSize = dto.fontSize
        self.theme = ThemeMode(rawValue: dto.theme) ?? .system
        self.devotionalModeEnabled = dto.devotionalModeEnabled
        self.hasCompletedOnboarding = dto.hasCompletedOnboarding
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

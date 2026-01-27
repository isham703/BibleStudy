import Foundation

// MARK: - App Configuration
// Centralized configuration for API keys, feature flags, and settings

enum AppConfiguration {
    // MARK: - Environment
    enum Environment {
        case development
        case staging
        case production

        static var current: Environment {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }
    }

    // MARK: - Supabase
    enum Supabase {
        static var url: URL {
            guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
                  !urlString.isEmpty,
                  let url = URL(string: urlString) else {
                #if DEBUG
                fatalError(ConfigurationError.missingSupabaseURL.localizedDescription)
                #else
                // Return a placeholder URL in release; the app should handle this gracefully
                return URL(string: "https://placeholder.supabase.co")!
                #endif
            }
            return url
        }

        static var anonKey: String {
            guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
                  !key.isEmpty else {
                #if DEBUG
                fatalError(ConfigurationError.missingSupabaseKey.localizedDescription)
                #else
                return ""
                #endif
            }
            return key
        }
    }

    // MARK: - AI Provider
    enum AI {
        static var openAIKey: String {
            guard let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
                  !key.isEmpty else {
                #if DEBUG
                fatalError(ConfigurationError.missingOpenAIKey.localizedDescription)
                #else
                return ""
                #endif
            }
            return key
        }

        static var defaultModel: String {
            "gpt-4o-mini"
        }

        static var advancedModel: String {
            "gpt-4o"
        }

        static var embeddingModel: String {
            "text-embedding-3-small"
        }

        // Rate limiting
        static var requestsPerMinute: Int { 20 }
        static var requestsPerDay: Int { 200 }
    }

    // MARK: - Feature Flags
    enum Features {
        static var isDevotionalModeAvailable: Bool { true }
        static var isLanguageLensAvailable: Bool { true }
        static var isTopicSearchAvailable: Bool { true }
        static var isChatAvailable: Bool { true }
        static var isOfflineAICacheEnabled: Bool { true }
    }

    // MARK: - Database
    enum Database {
        static var name: String { "BibleStudy.sqlite" }

        static var path: URL {
            let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first!
            return documentsURL.appendingPathComponent(name)
        }
    }

    // MARK: - App Info
    enum App {
        static var version: String {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        }

        static var build: String {
            Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        }

        static var bundleId: String {
            Bundle.main.bundleIdentifier ?? "com.biblestudy.app"
        }

        /// App Group ID for sharing data with widgets
        /// Important: This must match the App Group ID configured in:
        /// 1. Main app entitlements
        /// 2. Widget extension entitlements
        /// 3. DailyVerseWidget/DailyVerseWidget.swift
        static let appGroupId = "group.com.biblestudy.app"
    }

    // MARK: - User Defaults Keys
    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let userName = "userName"
        static let lastReadLocation = "lastReadLocation"
        static let lastScrolledVerse = "lastScrolledVerse"
        static let preferredFontSize = "preferredFontSize"
        static let preferredLineSpacing = "preferredLineSpacing"
        static let preferredContentWidth = "preferredContentWidth"
        static let paragraphMode = "paragraphMode"
        static let preferredTheme = "preferredTheme"
        static let preferredTranslation = "preferredTranslation"
        static let devotionalModeEnabled = "devotionalModeEnabled"
        static let hasImportedBibleData = "hasImportedBibleData"

        // Onboarding & Mode
        static let appMode = "appMode"
        static let dailyGoalMinutes = "dailyGoalMinutes"
        static let primaryFocus = "primaryFocus"
        static let experienceLevel = "experienceLevel"

        // Reader Mode
        static let usePagedReader = "usePagedReader"

        // AI Consent (App Store compliance)
        static let hasConsentedToAIProcessing = "hasConsentedToAIProcessing"
        static let aiConsentDate = "aiConsentDate"

        // Home Page Variant
        static let homeVariant = "homeVariant"

        // Typography Preferences (Stoic-Roman)
        static let scriptureFont = "scriptureFont"
        static let displayFont = "displayFont"
        static let verseNumberStyle = "verseNumberStyle"
        static let dropCapStyle = "dropCapStyle"
        static let showDropCaps = "showDropCaps"

        // AI Preferences
        static let aiInsightsEnabled = "aiInsightsEnabled"
        static let scholarModeEnabled = "scholarModeEnabled"
        static let voiceGuidanceEnabled = "voiceGuidanceEnabled"
        static let hapticFeedbackEnabled = "hapticFeedbackEnabled"
        static let cloudSyncEnabled = "cloudSyncEnabled"

        // Sermon Live Captions
        static let liveCaptionsEnabled = "liveCaptionsEnabled"
    }
}

// MARK: - Configuration Error
// Thrown when required configuration is missing

enum ConfigurationError: Error, LocalizedError {
    case missingSupabaseURL
    case missingSupabaseKey
    case missingOpenAIKey

    var errorDescription: String? {
        switch self {
        case .missingSupabaseURL:
            return "Missing SUPABASE_URL. Copy Config/Secrets.xcconfig.template to Config/Secrets.xcconfig and add your Supabase URL."
        case .missingSupabaseKey:
            return "Missing SUPABASE_ANON_KEY. Copy Config/Secrets.xcconfig.template to Config/Secrets.xcconfig and add your Supabase anon key."
        case .missingOpenAIKey:
            return "Missing OPENAI_API_KEY. Copy Config/Secrets.xcconfig.template to Config/Secrets.xcconfig and add your OpenAI API key."
        }
    }
}
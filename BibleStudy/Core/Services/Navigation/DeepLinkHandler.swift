import Foundation
import SwiftUI

// MARK: - Deep Link Handler
// Handles URL scheme deep links from widgets and external sources

enum DeepLinkHandler {
    // MARK: - URL Scheme
    static let scheme = "biblestudy"

    // MARK: - Auth Redirect URL
    /// The redirect URL for Supabase email confirmation
    static var authCallbackURL: URL {
        URL(string: "\(scheme)://auth/callback")!
    }

    // MARK: - Deep Link Types
    enum DeepLink: Equatable {
        case verse(reference: String)
        case chapter(bookId: Int, chapter: Int)
        case search(query: String)
        case home
        case ask  // Open Ask modal
        case practice  // Memorization practice
        case memorization  // Legacy - redirects to practice
        case settings
        case authCallback(code: String)  // Email confirmation callback
        case authError(code: String, description: String)  // Auth error (e.g., expired OTP)

        /// Parse a URL into a DeepLink
        static func from(url: URL) -> DeepLink? {
            guard url.scheme == scheme else { return nil }

            let host = url.host ?? ""
            let pathComponents = url.pathComponents.filter { $0 != "/" }

            switch host {
            case "verse":
                // biblestudy://verse/John%203:16
                if let reference = pathComponents.first?.removingPercentEncoding {
                    return .verse(reference: reference)
                }

            case "chapter":
                // biblestudy://chapter/43/3 (bookId/chapter)
                if pathComponents.count >= 2,
                   let bookId = Int(pathComponents[0]),
                   let chapter = Int(pathComponents[1]) {
                    return .chapter(bookId: bookId, chapter: chapter)
                }

            case "search":
                // biblestudy://search/love
                if let query = pathComponents.first?.removingPercentEncoding {
                    return .search(query: query)
                }

            case "home":
                // biblestudy://home
                return .home

            case "ask":
                // biblestudy://ask
                return .ask

            case "practice":
                // biblestudy://practice
                return .practice

            case "memorization":
                // Legacy URL - redirect to practice
                return .practice

            case "settings":
                return .settings

            case "auth":
                // biblestudy://auth/callback?code=xxx or ?error=access_denied&error_code=otp_expired
                // Handle email confirmation callback from Supabase
                if pathComponents.first == "callback" {
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    let queryItems = components?.queryItems ?? []

                    // Check for error first (e.g., expired OTP, access denied)
                    if let _ = queryItems.first(where: { $0.name == "error" })?.value,
                       let errorCode = queryItems.first(where: { $0.name == "error_code" })?.value {
                        let description = queryItems.first(where: { $0.name == "error_description" })?.value?
                            .replacingOccurrences(of: "+", with: " ") ?? "An error occurred"
                        return .authError(code: errorCode, description: description)
                    }

                    // Then check for success code
                    if let code = queryItems.first(where: { $0.name == "code" })?.value {
                        return .authCallback(code: code)
                    }
                }

            default:
                break
            }

            return nil
        }
    }

    // MARK: - Handle Deep Link

    /// Handle a deep link and return the navigation action
    @MainActor
    static func handle(_ url: URL, appState: AppState) -> Bool {
        guard let deepLink = DeepLink.from(url: url) else {
            print("DeepLinkHandler: Invalid URL: \(url)")
            return false
        }

        print("DeepLinkHandler: Handling \(deepLink)")

        switch deepLink {
        case .verse(let reference):
            return navigateToVerse(reference: reference, appState: appState)

        case .chapter(let bookId, let chapter):
            return navigateToChapter(bookId: bookId, chapter: chapter, appState: appState)

        case .search(let query):
            return navigateToSearch(query: query)

        case .home:
            return navigateToHome()

        case .ask:
            return navigateToAsk()

        case .practice, .memorization:
            return navigateToPractice()

        case .settings:
            return navigateToSettings()

        case .authCallback(let code):
            return handleAuthCallback(code: code)

        case .authError(let code, let description):
            return handleAuthError(code: code, description: description)
        }
    }

    // MARK: - Auth Callback

    @MainActor
    private static func handleAuthCallback(code: String) -> Bool {
        // Post notification to handle email confirmation
        NotificationCenter.default.post(
            name: .deepLinkAuthCallbackReceived,
            object: nil,
            userInfo: ["code": code]
        )
        return true
    }

    // MARK: - Auth Error

    @MainActor
    private static func handleAuthError(code: String, description: String) -> Bool {
        // Post notification to show auth error alert to user
        NotificationCenter.default.post(
            name: .deepLinkAuthErrorReceived,
            object: nil,
            userInfo: ["code": code, "description": description]
        )
        return true
    }

    // MARK: - Search Navigation

    @MainActor
    private static func navigateToSearch(query: String) -> Bool {
        // Post notification to switch to Read tab and open search
        NotificationCenter.default.post(
            name: .deepLinkSearchRequested,
            object: nil,
            userInfo: ["query": query]
        )
        return true
    }

    // MARK: - Home Navigation

    @MainActor
    private static func navigateToHome() -> Bool {
        // Post notification to switch to Home tab
        NotificationCenter.default.post(
            name: .deepLinkHomeRequested,
            object: nil
        )
        return true
    }

    // MARK: - Ask Navigation

    @MainActor
    private static func navigateToAsk() -> Bool {
        // Post notification to open Ask modal
        NotificationCenter.default.post(
            name: .deepLinkAskRequested,
            object: nil
        )
        return true
    }

    // MARK: - Practice Navigation

    @MainActor
    private static func navigateToPractice() -> Bool {
        // Post notification to switch to Home tab and trigger practice
        NotificationCenter.default.post(
            name: .deepLinkPracticeRequested,
            object: nil
        )
        return true
    }

    // MARK: - Settings Navigation

    @MainActor
    private static func navigateToSettings() -> Bool {
        // Post notification to open settings sheet
        NotificationCenter.default.post(
            name: .deepLinkSettingsRequested,
            object: nil
        )
        return true
    }

    // MARK: - Navigation Helpers

    @MainActor
    private static func navigateToVerse(reference: String, appState: AppState) -> Bool {
        // Parse the reference using ReferenceParser
        let result = ReferenceParser.parse(reference)

        switch result {
        case .success(let parsed):
            let location = parsed.location
            appState.saveLocation(location)

            // Set scroll position to the verse if specified
            if let verse = parsed.verseStart {
                appState.lastScrolledVerse = verse
            }

            // Post notification to trigger navigation
            NotificationCenter.default.post(
                name: .deepLinkNavigationRequested,
                object: nil,
                userInfo: ["location": location]
            )

            return true

        case .failure(let error):
            print("DeepLinkHandler: Failed to parse reference '\(reference)': \(error.localizedDescription)")
            return false
        }
    }

    @MainActor
    private static func navigateToChapter(bookId: Int, chapter: Int, appState: AppState) -> Bool {
        let location = BibleLocation(bookId: bookId, chapter: chapter)
        appState.saveLocation(location)

        // Post notification to trigger navigation
        NotificationCenter.default.post(
            name: .deepLinkNavigationRequested,
            object: nil,
            userInfo: ["location": location]
        )

        return true
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let deepLinkNavigationRequested = Notification.Name("deepLinkNavigationRequested")
    static let deepLinkTabChangeRequested = Notification.Name("deepLinkTabChangeRequested")
    static let deepLinkSearchRequested = Notification.Name("deepLinkSearchRequested")
    static let deepLinkSettingsRequested = Notification.Name("deepLinkSettingsRequested")
    static let deepLinkHomeRequested = Notification.Name("deepLinkHomeRequested")
    static let deepLinkAskRequested = Notification.Name("deepLinkAskRequested")
    static let deepLinkPracticeRequested = Notification.Name("deepLinkPracticeRequested")
    static let deepLinkAuthCallbackReceived = Notification.Name("deepLinkAuthCallbackReceived")
    static let deepLinkAuthErrorReceived = Notification.Name("deepLinkAuthErrorReceived")
}

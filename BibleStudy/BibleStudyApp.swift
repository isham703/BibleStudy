//
//  BibleStudyApp.swift
//  BibleStudy
//
//  A Bible reading experience enhanced by AI
//

import SwiftUI

private let analytics = AnalyticsService.shared

@main
struct BibleStudyApp: App {
    // MARK: - State
    @State private var bibleService = BibleService.shared
    @State private var dataLoadingService = DataLoadingService.shared
    @State private var authService = AuthService.shared
    @State private var appState = AppState()
    @State private var isInitialized = false
    @State private var isCheckingSession = true  // Session restoration state
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    // Auth error alert state
    @State private var authErrorMessage: String?
    @State private var showAuthErrorAlert = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app content (or onboarding)
                if hasCompletedOnboarding {
                    MainTabView()
                        .environment(bibleService)
                        .environment(appState)
                        .withAllCelebrations()
                        .withPaywall()
                        .opacity(isInitialized && !isCheckingSession ? 1 : 0)
                } else {
                    OnboardingView()
                        .environment(appState)
                        .opacity(isInitialized && !isCheckingSession ? 1 : 0)
                }

                // First launch overlay (data loading)
                if !isInitialized {
                    FirstLaunchOverlay(phase: dataLoadingService.phase) {
                        Task {
                            await initializeApp()
                        }
                    }
                    .transition(.opacity)
                }

                // Session restoration skeleton (shows after data init, during auth check)
                if isInitialized && isCheckingSession {
                    SessionRestorationView()
                        .transition(.opacity)
                }
            }
            .animation(AppTheme.Animation.standard, value: isInitialized)
            .animation(AppTheme.Animation.standard, value: isCheckingSession)
            .animation(AppTheme.Animation.standard, value: hasCompletedOnboarding)
            .task {
                await initializeApp()
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhaseChange(newPhase)
            }
            .onReceive(NotificationCenter.default.publisher(for: .deepLinkAuthCallbackReceived)) { notification in
                if let code = notification.userInfo?["code"] as? String {
                    Task {
                        await handleAuthCallback(code: code)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .deepLinkAuthErrorReceived)) { notification in
                if let code = notification.userInfo?["code"] as? String,
                   let description = notification.userInfo?["description"] as? String {
                    authErrorMessage = friendlyAuthErrorMessage(code: code, description: description)
                    showAuthErrorAlert = true
                }
            }
            .alert("Email Link Issue", isPresented: $showAuthErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(authErrorMessage ?? "An error occurred.")
            }
            .preferredColorScheme(appState.colorScheme)
        }
    }

    /// Handle scene phase changes
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // End any active reading session and sync widget data
            ReadingAnalyticsService.shared.endCurrentSession()
            Task {
                await WidgetService.shared.syncWidgetData()
            }
            // Track session end
            analytics.trackSessionEnd()
        case .active:
            // Sync widget data when becoming active (in case data changed)
            if isInitialized {
                Task {
                    await WidgetService.shared.syncWidgetData()
                }
                // Track session start
                analytics.trackSessionStart()
            }
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    /// Handle deep links from widgets and external sources
    private func handleDeepLink(_ url: URL) {
        guard isInitialized else {
            // Queue the deep link to handle after initialization
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                _ = DeepLinkHandler.handle(url, appState: appState)
            }
            return
        }
        _ = DeepLinkHandler.handle(url, appState: appState)
    }

    /// Handle email confirmation auth callback
    private func handleAuthCallback(code: String) async {
        do {
            // Exchange the code for a session
            try await SupabaseManager.shared.exchangeCodeForSession(code: code)

            // Update auth state
            appState.isAuthenticated = authService.isAuthenticated
            if let userId = authService.currentUserId {
                appState.userId = userId.uuidString
            }

            // Load profile
            try? await authService.loadProfile()

            print("BibleStudyApp: Email confirmed successfully")
        } catch {
            print("BibleStudyApp: Failed to exchange auth code: \(error.localizedDescription)")
        }
    }

    /// Convert auth error codes to user-friendly messages
    private func friendlyAuthErrorMessage(code: String, description: String) -> String {
        switch code {
        case "otp_expired":
            return "This email link has expired. Please request a new one from the sign-in screen."
        case "access_denied":
            return "Access was denied. Please try signing in again."
        case "invalid_request":
            return "The sign-in link is invalid. Please request a new one."
        case "unauthorized_client":
            return "This sign-in method is not authorized. Please try a different method."
        default:
            // Use the description from Supabase if no specific mapping
            return description.isEmpty ? "An error occurred during sign-in. Please try again." : description
        }
    }

    /// Initialize app data and services
    private func initializeApp() async {
        // Use DataLoadingService for initialization (handles bundled DB copy)
        await dataLoadingService.initializeData()

        // Then initialize BibleService (which sets up caching, etc.)
        await bibleService.initialize()

        // Sync widget data for Home Screen widgets
        await WidgetService.shared.syncWidgetData()

        // Run audio cache maintenance (prunes expired files, enforces size limit)
        AudioCache.shared.performMaintenance()

        // Mark as initialized to show main content
        withAnimation {
            isInitialized = dataLoadingService.isDataReady || dataLoadingService.phase.isComplete
        }

        // Check for existing auth session (brief delay for Supabase SDK init)
        await checkExistingSession()
    }

    /// Check for existing authentication session
    private func checkExistingSession() async {
        // Small delay to allow Supabase SDK to restore session from storage
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Update app state with auth status
        appState.isAuthenticated = authService.isAuthenticated
        if let userId = authService.currentUserId {
            appState.userId = userId.uuidString
        }

        // Load profile and sync onboarding state if authenticated
        if authService.isAuthenticated {
            try? await authService.loadProfile()

            // Sync onboarding state from remote profile
            if authService.hasCompletedOnboardingRemote && !hasCompletedOnboarding {
                // Remote says completed, update local
                hasCompletedOnboarding = true
            } else if hasCompletedOnboarding && !authService.hasCompletedOnboardingRemote {
                // Local says completed but remote doesn't know - sync to remote
                try? await authService.markOnboardingCompleted()
            }
        }

        // End session check
        withAnimation(AppTheme.Animation.reverent) {
            isCheckingSession = false
        }
    }
}

// MARK: - App State
@Observable
final class AppState {
    // Theme
    var preferredTheme: AppThemeMode = .system
    var colorScheme: ColorScheme? {
        preferredTheme.baseColorScheme
    }

    // Font Size
    var scriptureFontSize: ScriptureFontSize = .medium

    // Line Spacing
    var lineSpacing: LineSpacing = .normal

    // Content Width (for large screens like iPad)
    var contentWidth: ContentWidth = .standard

    // Paragraph Mode (continuous prose vs verse-per-line)
    var paragraphMode: Bool = false

    // MARK: - Typography Preferences (Illuminated Manuscript)

    /// Scripture body font family
    var scriptureFont: ScriptureFont = .newYork {
        didSet {
            UserDefaults.standard.set(scriptureFont.rawValue, forKey: AppConfiguration.UserDefaultsKeys.scriptureFont)
        }
    }

    /// Display font for headers, titles, drop caps
    var displayFont: DisplayFont = .system {
        didSet {
            UserDefaults.standard.set(displayFont.rawValue, forKey: AppConfiguration.UserDefaultsKeys.displayFont)
        }
    }

    /// Verse number display style
    var verseNumberStyle: VerseNumberStyle = .superscript {
        didSet {
            UserDefaults.standard.set(verseNumberStyle.rawValue, forKey: AppConfiguration.UserDefaultsKeys.verseNumberStyle)
        }
    }

    /// Drop cap style for chapter/paragraph beginnings
    var dropCapStyle: DropCapStyle = .none {
        didSet {
            UserDefaults.standard.set(dropCapStyle.rawValue, forKey: AppConfiguration.UserDefaultsKeys.dropCapStyle)
        }
    }

    /// Whether to show drop caps at chapter beginnings
    var showDropCaps: Bool = false {
        didSet {
            UserDefaults.standard.set(showDropCaps, forKey: AppConfiguration.UserDefaultsKeys.showDropCaps)
        }
    }

    // App Mode (Devotion vs Study) - determines home screen layout
    var appMode: AppMode = .devotion {
        didSet {
            UserDefaults.standard.set(appMode.rawValue, forKey: AppConfiguration.UserDefaultsKeys.appMode)
        }
    }

    // Home Page Variant (Liturgical Hours, Candlelit, Scholar's, Threshold)
    var homeVariant: HomeVariant = .liturgicalHours {
        didSet {
            UserDefaults.standard.set(homeVariant.rawValue, forKey: AppConfiguration.UserDefaultsKeys.homeVariant)
        }
    }

    // Daily Goal
    var dailyGoalMinutes: Int = 10 {
        didSet {
            UserDefaults.standard.set(dailyGoalMinutes, forKey: AppConfiguration.UserDefaultsKeys.dailyGoalMinutes)
        }
    }

    // User
    var isAuthenticated: Bool = false
    var userId: String?

    // Tab Bar Visibility (for child views that need full-screen)
    var hideTabBar: Bool = false

    // Navigation
    var currentLocation: BibleLocation = .genesis1

    // Scroll Position (verse number for restoration)
    var lastScrolledVerse: Int = 1

    // Selection
    var selectedVerseRange: VerseRange?

    init() {
        loadPreferences()
    }

    private func loadPreferences() {
        if let themeRaw = UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.preferredTheme),
           let theme = AppThemeMode(rawValue: themeRaw) {
            preferredTheme = theme
        }

        if let fontSizeRaw = UserDefaults.standard.object(forKey: AppConfiguration.UserDefaultsKeys.preferredFontSize) as? CGFloat,
           let fontSize = ScriptureFontSize(rawValue: fontSizeRaw) {
            scriptureFontSize = fontSize
        }

        if let lineSpacingRaw = UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.preferredLineSpacing),
           let spacing = LineSpacing(rawValue: lineSpacingRaw) {
            lineSpacing = spacing
        }

        if let contentWidthRaw = UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.preferredContentWidth),
           let width = ContentWidth(rawValue: contentWidthRaw) {
            contentWidth = width
        }

        paragraphMode = UserDefaults.standard.bool(forKey: AppConfiguration.UserDefaultsKeys.paragraphMode)

        // Load app mode
        if let modeRaw = UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.appMode),
           let mode = AppMode(rawValue: modeRaw) {
            appMode = mode
        }

        // Load home variant
        if let variantRaw = UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.homeVariant),
           let variant = HomeVariant(rawValue: variantRaw) {
            homeVariant = variant
        }

        // Load daily goal
        let savedGoal = UserDefaults.standard.integer(forKey: AppConfiguration.UserDefaultsKeys.dailyGoalMinutes)
        if savedGoal > 0 {
            dailyGoalMinutes = savedGoal
        }

        // Load last read location
        if let locationData = UserDefaults.standard.data(forKey: AppConfiguration.UserDefaultsKeys.lastReadLocation),
           let location = try? JSONDecoder().decode(BibleLocation.self, from: locationData) {
            currentLocation = location
        }

        // Load last scroll position
        let scrolledVerse = UserDefaults.standard.integer(forKey: AppConfiguration.UserDefaultsKeys.lastScrolledVerse)
        if scrolledVerse > 0 {
            lastScrolledVerse = scrolledVerse
        }

        // Load typography preferences
        if let scriptureFontRaw = UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.scriptureFont),
           let font = ScriptureFont(rawValue: scriptureFontRaw) {
            scriptureFont = font
        }

        if let displayFontRaw = UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.displayFont),
           let font = DisplayFont(rawValue: displayFontRaw) {
            displayFont = font
        }

        if let verseStyleRaw = UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.verseNumberStyle),
           let style = VerseNumberStyle(rawValue: verseStyleRaw) {
            verseNumberStyle = style
        }

        if let dropCapStyleRaw = UserDefaults.standard.string(forKey: AppConfiguration.UserDefaultsKeys.dropCapStyle),
           let style = DropCapStyle(rawValue: dropCapStyleRaw) {
            dropCapStyle = style
        }

        showDropCaps = UserDefaults.standard.bool(forKey: AppConfiguration.UserDefaultsKeys.showDropCaps)
    }

    /// Apply settings from onboarding
    func applyOnboardingData(_ data: OnboardingData) {
        appMode = data.recommendedMode
        dailyGoalMinutes = data.dailyGoalMinutes

        // Store quiz answers for analytics
        if let focus = data.primaryFocus {
            UserDefaults.standard.set(focus, forKey: AppConfiguration.UserDefaultsKeys.primaryFocus)
        }
        if let experience = data.experienceLevel {
            UserDefaults.standard.set(experience, forKey: AppConfiguration.UserDefaultsKeys.experienceLevel)
        }
    }

    func saveLocation(_ location: BibleLocation) {
        // Reset scroll position when navigating to a new chapter
        if location != currentLocation {
            lastScrolledVerse = 1
            UserDefaults.standard.set(1, forKey: AppConfiguration.UserDefaultsKeys.lastScrolledVerse)
        }

        currentLocation = location
        if let data = try? JSONEncoder().encode(location) {
            UserDefaults.standard.set(data, forKey: AppConfiguration.UserDefaultsKeys.lastReadLocation)
        }
    }

    func saveScrollPosition(verse: Int) {
        lastScrolledVerse = verse
        UserDefaults.standard.set(verse, forKey: AppConfiguration.UserDefaultsKeys.lastScrolledVerse)
    }
}

// MARK: - Theme Mode
enum AppThemeMode: String, CaseIterable {
    case system
    case light
    case dark
    case sepia
    case oled

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .sepia: return "Sepia"
        case .oled: return "OLED Black"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .sepia: return "book.fill"
        case .oled: return "moon.stars.fill"
        }
    }

    /// Description for the theme
    var themeDescription: String {
        switch self {
        case .system: return "Follows your device settings"
        case .light: return "Bright and clear"
        case .dark: return "Easy on the eyes"
        case .sepia: return "Warm parchment tone"
        case .oled: return "True black, saves battery"
        }
    }

    /// The underlying color scheme (sepia uses light, OLED uses dark)
    var baseColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light, .sepia: return .light
        case .dark, .oled: return .dark
        }
    }

    /// Whether this theme uses custom background colors
    var usesCustomBackground: Bool {
        switch self {
        case .system, .light, .dark: return false
        case .sepia, .oled: return true
        }
    }

    /// Custom background color for the theme (nil if using system colors)
    var customBackground: Color? {
        switch self {
        case .sepia: return .sepiaBackground
        case .oled: return .oledBackground
        default: return nil
        }
    }

    /// Custom surface color for the theme (nil if using system colors)
    var customSurface: Color? {
        switch self {
        case .sepia: return .sepiaSurface
        case .oled: return .oledSurface
        default: return nil
        }
    }

    /// Custom text color for the theme (nil if using system colors)
    var customTextColor: Color? {
        switch self {
        case .sepia: return .sepiaText
        case .oled: return .oledText
        default: return nil
        }
    }

    /// Custom secondary text color for the theme (nil if using system colors)
    var customSecondaryTextColor: Color? {
        switch self {
        case .sepia: return .sepiaSecondaryText
        case .oled: return .oledSecondaryText
        default: return nil
        }
    }

    /// Accent color for the theme
    var accentColor: Color {
        Color.divineGold
    }
}

// MARK: - Line Spacing
enum LineSpacing: String, CaseIterable {
    case compact
    case normal
    case relaxed

    var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .normal: return "Normal"
        case .relaxed: return "Relaxed"
        }
    }

    /// The line spacing value in points
    var value: CGFloat {
        switch self {
        case .compact: return 4
        case .normal: return 8
        case .relaxed: return 12
        }
    }

    var description: String {
        switch self {
        case .compact: return "Tighter text, more content visible"
        case .normal: return "Balanced readability"
        case .relaxed: return "More breathing room between lines"
        }
    }
}

// MARK: - Content Width
enum ContentWidth: String, CaseIterable {
    case compact
    case standard
    case wide
    case full

    var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .standard: return "Standard"
        case .wide: return "Wide"
        case .full: return "Full Width"
        }
    }

    /// The maximum content width in points (nil means no limit)
    var maxWidth: CGFloat? {
        switch self {
        case .compact: return 400
        case .standard: return 500
        case .wide: return 600
        case .full: return nil
        }
    }

    var description: String {
        switch self {
        case .compact: return "Narrow column, optimal for reading"
        case .standard: return "Balanced width for most screens"
        case .wide: return "More content per line"
        case .full: return "Use entire screen width"
        }
    }
}

// MARK: - Home Variant
/// Defines the visual style of the home page
enum HomeVariant: String, CaseIterable {
    case liturgicalHours = "liturgicalHours"
    case candlelitSanctuary = "candlelitSanctuary"
    case scholarsAtrium = "scholarsAtrium"
    case sacredThreshold = "sacredThreshold"

    var displayName: String {
        switch self {
        case .liturgicalHours: return "Liturgical Hours"
        case .candlelitSanctuary: return "Candlelit Sanctuary"
        case .scholarsAtrium: return "Scholar's Atrium"
        case .sacredThreshold: return "Sacred Threshold"
        }
    }

    var description: String {
        switch self {
        case .liturgicalHours: return "Time-aware design that adapts to the Liturgy of the Hours"
        case .candlelitSanctuary: return "Intimate evening design with candlelight and starfield"
        case .scholarsAtrium: return "Light-mode scholarly design for focused study"
        case .sacredThreshold: return "Architectural journey with room-based navigation"
        }
    }

    var icon: String {
        switch self {
        case .liturgicalHours: return "clock.fill"
        case .candlelitSanctuary: return "moon.stars.fill"
        case .scholarsAtrium: return "text.book.closed.fill"
        case .sacredThreshold: return "building.columns.fill"
        }
    }
}

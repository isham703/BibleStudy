import SwiftUI
import StoreKit
import Auth

// MARK: - Settings View Model
// Service delegation, computed properties, and async actions for Settings.
// Simple boolean preferences use @AppStorage directly in views (SettingsView).

@Observable
@MainActor
final class SettingsViewModel {
    // MARK: - Dependencies
    private let authService: AuthService
    private let notificationService: NotificationService
    private let storeManager: StoreManager
    private let entitlementManager: EntitlementManager
    private let biometricService: BiometricService

    // MARK: - Audio Cache Properties

    /// Current audio cache size formatted for display
    var audioCacheSize: String {
        AudioCache.shared.formattedCacheSize()
    }

    /// Current cache limit in MB
    var audioCacheLimitMB: Int {
        get { AudioCache.getMaxCacheSizeMB() }
        set { AudioCache.setMaxCacheSize(megabytes: newValue) }
    }

    /// Available cache size options for picker
    var audioCacheSizeOptions: [(label: String, mb: Int)] {
        AudioCache.cacheSizeOptions
    }

    /// Clear the audio cache
    func clearAudioCache() {
        AudioCache.shared.clearCache()
    }

    // MARK: - UI State
    var showPaywall: Bool = false
    var paywallTrigger: PaywallTrigger = .manual
    var isSigningOut: Bool = false
    var showSignOutConfirmation: Bool = false
    var isRestoringPurchases: Bool = false
    var errorMessage: String?
    var showError: Bool = false

    // MARK: - Animation State
    var appeared: Bool = false

    // MARK: - Authentication Properties

    var isAuthenticated: Bool {
        authService.isAuthenticated
    }

    var displayName: String? {
        authService.userProfile?.displayName
    }

    var email: String? {
        SupabaseManager.shared.currentUser?.email
    }

    // MARK: - Biometric Properties

    var isBiometricAvailable: Bool {
        biometricService.isAvailable
    }

    var isBiometricEnabled: Bool {
        get { biometricService.isEnabled }
        set { biometricService.isEnabled = newValue }
    }

    var biometricType: BiometricType {
        biometricService.biometricType
    }

    // MARK: - Notification Properties

    var dailyReminderEnabled: Bool {
        get { notificationService.dailyReminderEnabled }
        set { notificationService.dailyReminderEnabled = newValue }
    }

    var dailyReminderTime: Date {
        get { notificationService.dailyReminderTime }
        set { notificationService.dailyReminderTime = newValue }
    }

    var streakReminderEnabled: Bool {
        get { notificationService.streakReminderEnabled }
        set { notificationService.streakReminderEnabled = newValue }
    }

    var notificationsAuthorized: Bool {
        notificationService.isAuthorized
    }

    // MARK: - Subscription Properties

    var currentTier: SubscriptionTier {
        storeManager.currentTier
    }

    var tierDisplayName: String {
        storeManager.currentTier.displayName
    }

    var tierIcon: String {
        storeManager.currentTier.icon
    }

    var isPremiumOrHigher: Bool {
        storeManager.isPremiumOrHigher
    }

    var isScholar: Bool {
        storeManager.isScholar
    }

    var premiumProduct: Product? {
        storeManager.premiumProduct
    }

    var scholarProduct: Product? {
        storeManager.scholarProduct
    }

    var isLoadingProducts: Bool {
        storeManager.isLoading
    }

    var showsUsageLimits: Bool {
        !isPremiumOrHigher
    }

    // MARK: - Usage Properties

    var aiInsightsUsed: Int {
        entitlementManager.aiInsightsUsedToday
    }

    var aiInsightsTotal: Int {
        FreeTierLimits.dailyAIInsights
    }

    var remainingAIInsights: Int {
        entitlementManager.remainingAIInsights
    }

    var highlightsUsed: Int {
        entitlementManager.highlightsUsedToday
    }

    var highlightsTotal: Int {
        FreeTierLimits.maxHighlightsPerDay
    }

    var remainingHighlights: Int {
        entitlementManager.remainingHighlights
    }

    var notesUsed: Int {
        entitlementManager.notesUsedToday
    }

    var notesTotal: Int {
        FreeTierLimits.maxNotesPerDay
    }

    var remainingNotes: Int {
        entitlementManager.remainingNotes
    }

    // MARK: - Subscription Renewal Info

    var subscriptionRenewalDate: Date? {
        // This will be populated asynchronously
        _renewalDate
    }

    private var _renewalDate: Date?

    // MARK: - Initialization

    init(
        authService: AuthService? = nil,
        notificationService: NotificationService? = nil,
        storeManager: StoreManager? = nil,
        entitlementManager: EntitlementManager? = nil,
        biometricService: BiometricService? = nil
    ) {
        // Use provided services or fall back to shared instances
        // Note: .shared access is inside the MainActor-isolated init body
        // to avoid Swift 6 concurrency warnings in default parameters
        self.authService = authService ?? .shared
        self.notificationService = notificationService ?? .shared
        self.storeManager = storeManager ?? .shared
        self.entitlementManager = entitlementManager ?? .shared
        self.biometricService = biometricService ?? .shared
    }

    // MARK: - Lifecycle

    /// Call this from the view's .task modifier to load initial async data
    func loadInitialData() async {
        await loadRenewalDate()
    }

    // MARK: - Actions

    func signOut() async {
        isSigningOut = true
        defer { isSigningOut = false }

        // Clear biometric credentials for security (Face ID/Touch ID tokens)
        biometricService.clearCredentials()

        // Sign out from auth service (invalidates Supabase session)
        try? await authService.signOut()
    }

    func updateDisplayName(_ name: String) async {
        do {
            try await authService.updateProfile(displayName: name)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func requestNotificationPermission() async {
        await notificationService.requestAuthorization()
    }

    func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    func showUpgradePaywall() {
        paywallTrigger = .manual
        showPaywall = true
    }

    func manageSubscription() async {
        await storeManager.showManageSubscriptions()
    }

    func restorePurchases() async {
        isRestoringPurchases = true
        defer { isRestoringPurchases = false }

        do {
            try await storeManager.restorePurchases()
            await loadRenewalDate()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Renewal Date Loading

    private func loadRenewalDate() async {
        guard isPremiumOrHigher else {
            _renewalDate = nil
            return
        }

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == ProductID.premiumYearly.rawValue ||
                   transaction.productID == ProductID.scholarYearly.rawValue {
                    _renewalDate = transaction.expirationDate
                    break
                }
            }
        }
    }

    // MARK: - Formatted Properties

    var formattedRenewalDate: String? {
        guard let date = subscriptionRenewalDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var tierDescription: String {
        switch currentTier {
        case .free:
            return "Limited daily access"
        case .premium:
            return "Unlimited access to core features"
        case .scholar:
            return "Complete access with advanced study tools"
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension SettingsViewModel {
    static var preview: SettingsViewModel {
        SettingsViewModel()
    }
}
#endif

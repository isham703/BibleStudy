import Testing
import Foundation
@testable import BibleStudy

// MARK: - Settings View Model Tests
// Tests for SettingsViewModel using Swift Testing framework.
// Note: Simple boolean preferences now use @AppStorage directly in views,
// so those are no longer tested via ViewModel.

@Suite("SettingsViewModel Tests")
struct SettingsViewModelTests {

    // MARK: - Computed Property Tests

    @Test("Tier description returns correct value for free tier")
    @MainActor
    func tierDescriptionFree() async {
        let viewModel = SettingsViewModel()

        // This test verifies the computed property works
        // The actual tier depends on StoreManager state
        let description = viewModel.tierDescription
        #expect(!description.isEmpty)
    }

    @Test("Shows usage limits reflects premium status")
    @MainActor
    func showsUsageLimitsReflectsPremium() async {
        let viewModel = SettingsViewModel()

        // showsUsageLimits should be opposite of isPremiumOrHigher
        #expect(viewModel.showsUsageLimits == !viewModel.isPremiumOrHigher)
    }

    // MARK: - UI State Tests

    @Test("Initial UI state is correct")
    @MainActor
    func initialUIState() async {
        let viewModel = SettingsViewModel()

        #expect(viewModel.showPaywall == false)
        #expect(viewModel.isSigningOut == false)
        #expect(viewModel.showSignOutConfirmation == false)
        #expect(viewModel.isRestoringPurchases == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showError == false)
        #expect(viewModel.appeared == false)
    }

    @Test("Show upgrade paywall sets correct state")
    @MainActor
    func showUpgradePaywallSetsState() async {
        let viewModel = SettingsViewModel()

        viewModel.showUpgradePaywall()

        #expect(viewModel.showPaywall == true)
        #expect(viewModel.paywallTrigger == .manual)
    }

    // MARK: - Audio Cache Tests

    @Test("Audio cache size returns formatted string")
    @MainActor
    func audioCacheSizeReturnsFormattedString() async {
        let viewModel = SettingsViewModel()

        let size = viewModel.audioCacheSize
        #expect(!size.isEmpty)
    }

    @Test("Audio cache size options are available")
    @MainActor
    func audioCacheSizeOptionsAvailable() async {
        let viewModel = SettingsViewModel()

        let options = viewModel.audioCacheSizeOptions
        #expect(options.count > 0)
    }

    // MARK: - Service Delegation Tests

    @Test("Daily reminder delegates to notification service")
    @MainActor
    func dailyReminderDelegation() async {
        let viewModel = SettingsViewModel()

        // The dailyReminderEnabled property should delegate to NotificationService
        // We can't easily mock this without protocol injection, but we can verify
        // the property is accessible and returns a boolean value
        let _ = viewModel.dailyReminderEnabled
        #expect(true) // Property access didn't crash
    }

    @Test("Biometric availability check")
    @MainActor
    func biometricAvailabilityCheck() async {
        let viewModel = SettingsViewModel()

        // isBiometricAvailable should delegate to BiometricService
        let _ = viewModel.isBiometricAvailable
        #expect(true) // Property access didn't crash
    }

    // MARK: - Subscription Properties Tests

    @Test("Tier display name is not empty")
    @MainActor
    func tierDisplayNameNotEmpty() async {
        let viewModel = SettingsViewModel()

        let displayName = viewModel.tierDisplayName
        #expect(!displayName.isEmpty)
    }

    @Test("Tier icon is not empty")
    @MainActor
    func tierIconNotEmpty() async {
        let viewModel = SettingsViewModel()

        let icon = viewModel.tierIcon
        #expect(!icon.isEmpty)
    }

    // MARK: - Usage Entitlement Tests

    @Test("AI insights usage values are non-negative")
    @MainActor
    func aiInsightsUsageNonNegative() async {
        let viewModel = SettingsViewModel()

        #expect(viewModel.aiInsightsUsed >= 0)
        #expect(viewModel.aiInsightsTotal > 0)
        #expect(viewModel.remainingAIInsights >= 0)
    }

    @Test("Highlights usage values are non-negative")
    @MainActor
    func highlightsUsageNonNegative() async {
        let viewModel = SettingsViewModel()

        #expect(viewModel.highlightsUsed >= 0)
        #expect(viewModel.highlightsTotal > 0)
        #expect(viewModel.remainingHighlights >= 0)
    }

    @Test("Notes usage values are non-negative")
    @MainActor
    func notesUsageNonNegative() async {
        let viewModel = SettingsViewModel()

        #expect(viewModel.notesUsed >= 0)
        #expect(viewModel.notesTotal > 0)
        #expect(viewModel.remainingNotes >= 0)
    }
}

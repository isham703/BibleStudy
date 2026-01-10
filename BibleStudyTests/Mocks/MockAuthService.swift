import Foundation
import AuthenticationServices
@testable import BibleStudy

// MARK: - Mock Auth Service
// Configurable mock for testing AuthViewModel

@MainActor
final class MockAuthService: AuthServiceProtocol {
    // MARK: - State Properties
    var isAuthenticated: Bool = false
    var currentUserId: UUID?
    var userProfile: UserProfile?
    var isLoading: Bool = false
    var error: AuthError?
    var hasCompletedOnboardingRemote: Bool = false

    // MARK: - Call Tracking
    var signInCallCount = 0
    var signUpCallCount = 0
    var signOutCallCount = 0
    var resetPasswordCallCount = 0
    var resendConfirmationCallCount = 0
    var restoreSessionCallCount = 0
    var signInWithAppleCallCount = 0
    var loadProfileCallCount = 0
    var updateProfileCallCount = 0
    var markOnboardingCompletedCallCount = 0

    // MARK: - Captured Arguments
    var lastSignInEmail: String?
    var lastSignInPassword: String?
    var lastSignUpEmail: String?
    var lastSignUpPassword: String?
    var lastResetPasswordEmail: String?
    var lastResendConfirmationEmail: String?
    var lastRestoreSessionToken: String?

    // MARK: - Configurable Behavior
    var shouldSignInSucceed = true
    var shouldSignUpSucceed = true
    var shouldSignOutSucceed = true
    var shouldResetPasswordSucceed = true
    var shouldResendConfirmationSucceed = true
    var shouldRestoreSessionSucceed = true
    var shouldSignInWithAppleSucceed = true
    var shouldLoadProfileSucceed = true
    var shouldUpdateProfileSucceed = true

    var signInError: AuthError?
    var signUpError: AuthError?
    var signOutError: AuthError?
    var resetPasswordError: AuthError?
    var resendConfirmationError: AuthError?
    var restoreSessionError: AuthError?
    var signInWithAppleError: AuthError?

    var mockRefreshToken = "mock-refresh-token-12345"
    var mockRestoredRefreshToken = "mock-restored-refresh-token-67890"

    // MARK: - Network Delay Simulation
    var simulatedNetworkDelay: TimeInterval = 0

    // MARK: - AuthServiceProtocol Implementation

    func signUp(email: String, password: String) async throws {
        signUpCallCount += 1
        lastSignUpEmail = email
        lastSignUpPassword = password

        if simulatedNetworkDelay > 0 {
            try await Task.sleep(for: .seconds(simulatedNetworkDelay))
        }

        if !shouldSignUpSucceed {
            throw signUpError ?? AuthError.signUpFailed("Mock sign up failed")
        }
    }

    @discardableResult
    func signIn(email: String, password: String) async throws -> String {
        signInCallCount += 1
        lastSignInEmail = email
        lastSignInPassword = password

        if simulatedNetworkDelay > 0 {
            try await Task.sleep(for: .seconds(simulatedNetworkDelay))
        }

        if !shouldSignInSucceed {
            throw signInError ?? AuthError.signInFailed("Mock sign in failed")
        }

        isAuthenticated = true
        return mockRefreshToken
    }

    @discardableResult
    func signInWithApple(authorization: ASAuthorization) async throws -> String {
        signInWithAppleCallCount += 1

        if simulatedNetworkDelay > 0 {
            try await Task.sleep(for: .seconds(simulatedNetworkDelay))
        }

        if !shouldSignInWithAppleSucceed {
            throw signInWithAppleError ?? AuthError.signInFailed("Mock Apple sign in failed")
        }

        isAuthenticated = true
        return mockRefreshToken
    }

    func signOut() async throws {
        signOutCallCount += 1

        if simulatedNetworkDelay > 0 {
            try await Task.sleep(for: .seconds(simulatedNetworkDelay))
        }

        if !shouldSignOutSucceed {
            throw signOutError ?? AuthError.signOutFailed("Mock sign out failed")
        }

        isAuthenticated = false
        currentUserId = nil
        userProfile = nil
    }

    func resetPassword(email: String) async throws {
        resetPasswordCallCount += 1
        lastResetPasswordEmail = email

        if simulatedNetworkDelay > 0 {
            try await Task.sleep(for: .seconds(simulatedNetworkDelay))
        }

        if !shouldResetPasswordSucceed {
            throw resetPasswordError ?? AuthError.resetPasswordFailed("Mock reset failed")
        }
    }

    func resendConfirmation(email: String) async throws {
        resendConfirmationCallCount += 1
        lastResendConfirmationEmail = email

        if simulatedNetworkDelay > 0 {
            try await Task.sleep(for: .seconds(simulatedNetworkDelay))
        }

        if !shouldResendConfirmationSucceed {
            throw resendConfirmationError ?? AuthError.resendConfirmationFailed("Mock resend failed")
        }
    }

    @discardableResult
    func restoreSession(refreshToken: String) async throws -> String {
        restoreSessionCallCount += 1
        lastRestoreSessionToken = refreshToken

        if simulatedNetworkDelay > 0 {
            try await Task.sleep(for: .seconds(simulatedNetworkDelay))
        }

        if !shouldRestoreSessionSucceed {
            throw restoreSessionError ?? AuthError.signInFailed("Session expired")
        }

        isAuthenticated = true
        return mockRestoredRefreshToken
    }

    func loadProfile() async throws {
        loadProfileCallCount += 1

        if simulatedNetworkDelay > 0 {
            try await Task.sleep(for: .seconds(simulatedNetworkDelay))
        }

        if !shouldLoadProfileSucceed {
            throw AuthError.signInFailed("Mock profile load failed")
        }
    }

    func updateProfile(
        displayName: String?,
        preferredTranslation: String?,
        fontSize: Int?,
        theme: ThemeMode?,
        devotionalModeEnabled: Bool?
    ) async throws {
        updateProfileCallCount += 1

        if simulatedNetworkDelay > 0 {
            try await Task.sleep(for: .seconds(simulatedNetworkDelay))
        }

        if !shouldUpdateProfileSucceed {
            throw AuthError.signInFailed("Mock profile update failed")
        }
    }

    func markOnboardingCompleted() async throws {
        markOnboardingCompletedCallCount += 1
        hasCompletedOnboardingRemote = true
    }

    // MARK: - Test Helpers

    func reset() {
        // Reset state
        isAuthenticated = false
        currentUserId = nil
        userProfile = nil
        isLoading = false
        error = nil
        hasCompletedOnboardingRemote = false

        // Reset call counts
        signInCallCount = 0
        signUpCallCount = 0
        signOutCallCount = 0
        resetPasswordCallCount = 0
        resendConfirmationCallCount = 0
        restoreSessionCallCount = 0
        signInWithAppleCallCount = 0
        loadProfileCallCount = 0
        updateProfileCallCount = 0
        markOnboardingCompletedCallCount = 0

        // Reset captured arguments
        lastSignInEmail = nil
        lastSignInPassword = nil
        lastSignUpEmail = nil
        lastSignUpPassword = nil
        lastResetPasswordEmail = nil
        lastResendConfirmationEmail = nil
        lastRestoreSessionToken = nil

        // Reset behavior
        shouldSignInSucceed = true
        shouldSignUpSucceed = true
        shouldSignOutSucceed = true
        shouldResetPasswordSucceed = true
        shouldResendConfirmationSucceed = true
        shouldRestoreSessionSucceed = true
        shouldSignInWithAppleSucceed = true
        shouldLoadProfileSucceed = true
        shouldUpdateProfileSucceed = true

        signInError = nil
        signUpError = nil
        signOutError = nil
        resetPasswordError = nil
        resendConfirmationError = nil
        restoreSessionError = nil
        signInWithAppleError = nil

        simulatedNetworkDelay = 0
    }
}

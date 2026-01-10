import Foundation
@testable import BibleStudy

// MARK: - Mock Biometric Service
// Configurable mock for testing biometric authentication flows

@MainActor
final class MockBiometricService: BiometricServiceProtocol {
    // MARK: - State Properties
    var isAvailable: Bool = true
    var biometricType: BiometricType = .faceID
    var isEnabled: Bool = false
    var hasStoredCredentials: Bool = false

    // MARK: - Stored Data
    private var storedEmail: String?
    private var storedRefreshToken: String?

    // MARK: - Call Tracking
    var authenticateCallCount = 0
    var authenticateAndGetTokenCallCount = 0
    var storeCredentialsCallCount = 0
    var clearCredentialsCallCount = 0
    var getStoredEmailCallCount = 0
    var getStoredRefreshTokenCallCount = 0

    // MARK: - Captured Arguments
    var lastStoredEmail: String?
    var lastStoredRefreshToken: String?

    // MARK: - Configurable Behavior
    var shouldAuthenticateSucceed = true
    var shouldStoreCredentialsSucceed = true

    var mockAuthenticatedEmail = "test@example.com"
    var mockStoredEmail = "stored@example.com"
    var mockStoredRefreshToken = "stored-refresh-token-12345"

    // MARK: - BiometricServiceProtocol Implementation

    func authenticate() async -> String? {
        authenticateCallCount += 1

        guard isEnabled, hasStoredCredentials else { return nil }

        if shouldAuthenticateSucceed {
            return storedEmail ?? mockAuthenticatedEmail
        }
        return nil
    }

    func authenticateAndGetToken() async -> (email: String, refreshToken: String)? {
        authenticateAndGetTokenCallCount += 1

        guard isEnabled, hasStoredCredentials else { return nil }

        if shouldAuthenticateSucceed {
            let email = storedEmail ?? mockStoredEmail
            let token = storedRefreshToken ?? mockStoredRefreshToken
            return (email, token)
        }
        return nil
    }

    func storeCredentials(email: String, refreshToken: String) throws {
        storeCredentialsCallCount += 1
        lastStoredEmail = email
        lastStoredRefreshToken = refreshToken

        if !shouldStoreCredentialsSucceed {
            throw BiometricError.keychainError(-1)
        }

        storedEmail = email
        storedRefreshToken = refreshToken
        hasStoredCredentials = true
    }

    func clearCredentials() {
        clearCredentialsCallCount += 1
        storedEmail = nil
        storedRefreshToken = nil
        hasStoredCredentials = false
        isEnabled = false
    }

    func getStoredEmail() -> String? {
        getStoredEmailCallCount += 1
        return storedEmail
    }

    func getStoredRefreshToken() -> String? {
        getStoredRefreshTokenCallCount += 1
        return storedRefreshToken
    }

    // MARK: - Test Helpers

    /// Configure service with stored credentials for testing biometric sign-in
    func configureWithStoredCredentials(email: String, refreshToken: String) {
        storedEmail = email
        storedRefreshToken = refreshToken
        hasStoredCredentials = true
        isEnabled = true
    }

    /// Configure service as available but not yet enabled
    func configureAsAvailable(type: BiometricType = .faceID) {
        isAvailable = true
        biometricType = type
        isEnabled = false
        hasStoredCredentials = false
    }

    /// Configure service as unavailable (no biometric hardware)
    func configureAsUnavailable() {
        isAvailable = false
        biometricType = .none
        isEnabled = false
        hasStoredCredentials = false
    }

    func reset() {
        // Reset state
        isAvailable = true
        biometricType = .faceID
        isEnabled = false
        hasStoredCredentials = false

        // Reset stored data
        storedEmail = nil
        storedRefreshToken = nil

        // Reset call counts
        authenticateCallCount = 0
        authenticateAndGetTokenCallCount = 0
        storeCredentialsCallCount = 0
        clearCredentialsCallCount = 0
        getStoredEmailCallCount = 0
        getStoredRefreshTokenCallCount = 0

        // Reset captured arguments
        lastStoredEmail = nil
        lastStoredRefreshToken = nil

        // Reset behavior
        shouldAuthenticateSucceed = true
        shouldStoreCredentialsSucceed = true
    }
}

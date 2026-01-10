import Foundation

// MARK: - Biometric Service Protocol
// Enables dependency injection and testability for biometric authentication

@MainActor
protocol BiometricServiceProtocol: AnyObject {
    // MARK: - State Properties
    var isAvailable: Bool { get }
    var biometricType: BiometricType { get }
    var isEnabled: Bool { get set }
    var hasStoredCredentials: Bool { get }

    // MARK: - Authentication

    /// Authenticate user with biometrics (legacy - returns email only)
    /// Returns the stored email if successful, nil otherwise
    func authenticate() async -> String?

    /// Authenticate and retrieve both email and refresh token for true quick sign-in
    /// Returns tuple of (email, refreshToken) if successful, nil otherwise
    func authenticateAndGetToken() async -> (email: String, refreshToken: String)?

    // MARK: - Credential Storage

    /// Store credentials securely in Keychain after successful login
    /// - Parameters:
    ///   - email: User's email address
    ///   - refreshToken: Supabase refresh token for session restoration
    func storeCredentials(email: String, refreshToken: String) throws

    /// Clear all stored credentials from Keychain
    func clearCredentials()

    /// Get stored email from Keychain
    func getStoredEmail() -> String?

    /// Get stored refresh token from Keychain
    func getStoredRefreshToken() -> String?
}

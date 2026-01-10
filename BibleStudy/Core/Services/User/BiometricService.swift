import Foundation
import LocalAuthentication
import Security

// MARK: - Biometric Service
// Manages Face ID / Touch ID authentication for quick sign-in

@MainActor
@Observable
final class BiometricService: BiometricServiceProtocol {
    // MARK: - Singleton
    // nonisolated(unsafe) allows access as default parameter values in @MainActor class inits
    nonisolated(unsafe) static let shared = BiometricService()

    // MARK: - Properties
    private let context = LAContext()
    private let keychainService = "com.biblestudy.credentials"
    private let emailKey = "biometric_email"
    private let tokenKey = "biometric_token"

    var isAvailable: Bool {
        canEvaluatePolicy()
    }

    var biometricType: BiometricType {
        determineBiometricType()
    }

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "biometricEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "biometricEnabled") }
    }

    var hasStoredCredentials: Bool {
        getStoredEmail() != nil && getStoredRefreshToken() != nil
    }

    // MARK: - Initialization
    // Note: nonisolated to allow initialization from nonisolated(unsafe) static let shared
    private nonisolated init() {}

    // MARK: - Biometric Type Detection

    private func canEvaluatePolicy() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    private func determineBiometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .faceID  // Treat opticID (Vision Pro) similar to Face ID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    // MARK: - Authentication

    /// Authenticate user with biometrics
    /// Returns the stored email if successful, nil otherwise
    func authenticate() async -> String? {
        guard isEnabled, hasStoredCredentials else { return nil }

        let context = LAContext()
        context.localizedCancelTitle = "Use Password"

        do {
            let reason = "Sign in to Bible Study"
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            if success {
                return getStoredEmail()
            }
        } catch {
            // User cancelled or biometric failed
            print("Biometric authentication failed: \(error.localizedDescription)")
        }

        return nil
    }

    /// Authenticate and retrieve both email and refresh token for true quick sign-in
    /// Returns tuple of (email, refreshToken) if successful, nil otherwise
    func authenticateAndGetToken() async -> (email: String, refreshToken: String)? {
        guard isEnabled, hasStoredCredentials else { return nil }

        let context = LAContext()
        context.localizedCancelTitle = "Use Password"

        do {
            let reason = "Sign in to Bible Study"
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            if success,
               let email = getStoredEmail(),
               let token = getStoredRefreshToken() {
                return (email, token)
            }
        } catch {
            print("Biometric authentication failed: \(error.localizedDescription)")
        }

        return nil
    }

    // MARK: - Credential Storage

    /// Store credentials securely in Keychain after successful login
    /// - Parameters:
    ///   - email: User's email address
    ///   - refreshToken: Supabase refresh token for session restoration
    func storeCredentials(email: String, refreshToken: String) throws {
        try setKeychainValue(email, forKey: emailKey)
        try setKeychainValue(refreshToken, forKey: tokenKey)
    }

    /// Clear all stored credentials from Keychain
    func clearCredentials() {
        deleteKeychainValue(forKey: emailKey)
        deleteKeychainValue(forKey: tokenKey)
        isEnabled = false
    }

    /// Get stored email from Keychain
    func getStoredEmail() -> String? {
        getKeychainValue(forKey: emailKey)
    }

    /// Get stored refresh token from Keychain
    func getStoredRefreshToken() -> String? {
        getKeychainValue(forKey: tokenKey)
    }

    // MARK: - Keychain Operations

    private func setKeychainValue(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw BiometricError.encodingFailed
        }

        // Delete existing item first
        deleteKeychainValue(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw BiometricError.keychainError(status)
        }
    }

    private func getKeychainValue(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func deleteKeychainValue(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Biometric Type

enum BiometricType {
    case faceID
    case touchID
    case none

    var systemImage: String {
        switch self {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .none: return "lock.fill"
        }
    }

    var displayName: String {
        switch self {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .none: return "Biometrics"
        }
    }

    var signInLabel: String {
        switch self {
        case .faceID: return "Sign in with Face ID"
        case .touchID: return "Sign in with Touch ID"
        case .none: return "Quick Sign In"
        }
    }
}

// MARK: - Biometric Errors

enum BiometricError: Error, LocalizedError {
    case notAvailable
    case encodingFailed
    case keychainError(OSStatus)
    case authenticationFailed

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .encodingFailed:
            return "Failed to encode credentials"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .authenticationFailed:
            return "Biometric authentication failed"
        }
    }
}

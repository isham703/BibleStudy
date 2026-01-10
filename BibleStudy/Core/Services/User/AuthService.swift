import Foundation
import AuthenticationServices
import Auth
import Security

// MARK: - Auth Service
// Manages user authentication state and operations

@MainActor
@Observable
final class AuthService: AuthServiceProtocol {
    // MARK: - Singleton
    // nonisolated(unsafe) allows access as default parameter values in @MainActor class inits
    nonisolated(unsafe) static let shared = AuthService()

    // MARK: - Properties
    private let supabase = SupabaseManager.shared

    var isAuthenticated: Bool {
        supabase.isAuthenticated
    }

    var currentUserId: UUID? {
        supabase.currentUser?.id
    }

    var userProfile: UserProfile?
    var isLoading: Bool = false
    var error: AuthError?

    // MARK: - Initialization
    // Note: nonisolated to allow initialization from nonisolated(unsafe) static let shared
    private nonisolated init() {}

    // MARK: - Cryptographic Utilities

    /// Generates a cryptographically secure random nonce for OIDC authentication
    /// - Parameter length: The number of random bytes to generate (default: 32)
    /// - Returns: A hexadecimal string representation of the random bytes
    private func generateSecureNonce(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            // Fallback to less secure but still functional UUID if SecRandom fails
            // This should never happen on iOS, but provides graceful degradation
            return UUID().uuidString + UUID().uuidString
        }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Auth Methods

    func signUp(email: String, password: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let user = try await supabase.signUp(email: email, password: password)
            userProfile = UserProfile(id: user.id)
        } catch {
            self.error = AuthError.signUpFailed(error.localizedDescription)
            throw self.error!
        }
    }

    @discardableResult
    func signIn(email: String, password: String) async throws -> String {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            _ = try await supabase.signIn(email: email, password: password)
            try await loadProfile()

            guard let refreshToken = supabase.getCurrentRefreshToken() else {
                throw AuthError.signInFailed("Failed to retrieve session token")
            }
            return refreshToken
        } catch let authError as AuthError {
            self.error = authError
            throw authError
        } catch {
            self.error = AuthError.signInFailed(error.localizedDescription)
            throw self.error!
        }
    }

    @discardableResult
    func signInWithApple(authorization: ASAuthorization) async throws -> String {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.appleSignInFailed("Invalid credentials")
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Generate cryptographically secure nonce for OIDC
            let nonce = generateSecureNonce()

            _ = try await supabase.signInWithApple(
                idToken: idTokenString,
                nonce: nonce
            )
            try await loadProfile()

            guard let refreshToken = supabase.getCurrentRefreshToken() else {
                throw AuthError.appleSignInFailed("Failed to retrieve session token")
            }
            return refreshToken
        } catch let authError as AuthError {
            self.error = authError
            throw authError
        } catch {
            self.error = AuthError.appleSignInFailed(error.localizedDescription)
            throw self.error!
        }
    }

    func signOut() async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await supabase.signOut()
            userProfile = nil
        } catch {
            self.error = AuthError.signOutFailed(error.localizedDescription)
            throw self.error!
        }
    }

    func resetPassword(email: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await supabase.resetPassword(email: email)
        } catch {
            self.error = AuthError.resetPasswordFailed(error.localizedDescription)
            throw self.error!
        }
    }

    func resendConfirmation(email: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await supabase.resendConfirmation(email: email)
        } catch {
            self.error = AuthError.resendConfirmationFailed(error.localizedDescription)
            throw self.error!
        }
    }

    // MARK: - Session Restoration

    /// Restore a session using a stored refresh token (for biometric quick sign-in)
    /// - Parameter refreshToken: The stored refresh token
    /// - Returns: The new refresh token from the restored session
    @discardableResult
    func restoreSession(refreshToken: String) async throws -> String {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let session = try await supabase.restoreSession(refreshToken: refreshToken)
            try await loadProfile()
            return session.refreshToken
        } catch {
            self.error = AuthError.signInFailed("Session expired. Please sign in again.")
            throw self.error!
        }
    }

    // MARK: - Profile

    func loadProfile() async throws {
        guard let dto = try await supabase.getProfile() else {
            return
        }
        userProfile = UserProfile(from: dto)
    }

    func updateProfile(
        displayName: String? = nil,
        preferredTranslation: String? = nil,
        fontSize: Int? = nil,
        theme: ThemeMode? = nil,
        devotionalModeEnabled: Bool? = nil
    ) async throws {
        var updates: [String: AnyEncodable] = [:]

        if let displayName = displayName {
            updates["display_name"] = AnyEncodable(displayName)
        }
        if let preferredTranslation = preferredTranslation {
            updates["preferred_translation"] = AnyEncodable(preferredTranslation)
        }
        if let fontSize = fontSize {
            updates["font_size"] = AnyEncodable(fontSize)
        }
        if let theme = theme {
            updates["theme"] = AnyEncodable(theme.rawValue)
        }
        if let devotionalModeEnabled = devotionalModeEnabled {
            updates["devotional_mode_enabled"] = AnyEncodable(devotionalModeEnabled)
        }

        guard !updates.isEmpty else { return }

        try await supabase.updateProfile(updates)
        try await loadProfile()
    }

    // MARK: - Onboarding State

    /// Mark onboarding as completed in the remote profile
    func markOnboardingCompleted() async throws {
        guard isAuthenticated else { return }

        let updates: [String: AnyEncodable] = [
            "has_completed_onboarding": AnyEncodable(true)
        ]

        try await supabase.updateProfile(updates)
        try await loadProfile()
    }

    /// Check if remote profile has completed onboarding
    var hasCompletedOnboardingRemote: Bool {
        userProfile?.hasCompletedOnboarding ?? false
    }
}

// MARK: - Auth Errors
enum AuthError: Error, LocalizedError {
    case signUpFailed(String)
    case signInFailed(String)
    case signOutFailed(String)
    case appleSignInFailed(String)
    case resetPasswordFailed(String)
    case resendConfirmationFailed(String)
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .signUpFailed(let message):
            return enhancedMessage(for: message, context: .signUp)
        case .signInFailed(let message):
            return enhancedMessage(for: message, context: .signIn)
        case .signOutFailed(let message):
            return "Sign out failed: \(message)"
        case .appleSignInFailed(let message):
            return enhancedMessage(for: message, context: .appleSignIn)
        case .resetPasswordFailed(let message):
            return enhancedMessage(for: message, context: .resetPassword)
        case .resendConfirmationFailed:
            return "Unable to resend email. Please try again in a moment."
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        }
    }

    /// Provides user-friendly, actionable error messages
    private func enhancedMessage(for rawMessage: String, context: AuthContext) -> String {
        let lowercased = rawMessage.lowercased()

        // Network errors
        if lowercased.contains("network") || lowercased.contains("connection") ||
           lowercased.contains("offline") || lowercased.contains("timed out") {
            return "Unable to connect. Please check your internet connection and try again."
        }

        // Invalid credentials
        if lowercased.contains("invalid") && (lowercased.contains("credential") ||
           lowercased.contains("password") || lowercased.contains("email")) {
            return "The email or password you entered is incorrect. Need to reset your password?"
        }

        // Email already in use
        if lowercased.contains("already") && (lowercased.contains("registered") ||
           lowercased.contains("exists") || lowercased.contains("in use")) {
            return "An account with this email already exists. Try signing in instead."
        }

        // Email not confirmed
        if lowercased.contains("not confirmed") || lowercased.contains("unconfirmed") {
            return "Please check your email and click the confirmation link before signing in."
        }

        // Rate limiting
        if lowercased.contains("rate") || lowercased.contains("too many") {
            return "Too many attempts. Please wait a moment before trying again."
        }

        // Apple Sign In specific
        if context == .appleSignIn {
            if lowercased.contains("cancel") {
                return "Sign in was cancelled. Tap to try again when ready."
            }
            return "Unable to complete Apple Sign In. Please try again."
        }

        // Reset password specific
        if context == .resetPassword {
            if lowercased.contains("not found") || lowercased.contains("no user") {
                return "We couldn't find an account with that email. Please check and try again."
            }
            return "Unable to send reset email. Please try again."
        }

        // Default fallback with context
        switch context {
        case .signUp:
            return "Unable to create account. Please try again."
        case .signIn:
            return "Unable to sign in. Please check your credentials and try again."
        case .appleSignIn:
            return "Unable to complete Apple Sign In. Please try again."
        case .resetPassword:
            return "Unable to reset password. Please try again."
        }
    }

    private enum AuthContext {
        case signUp, signIn, appleSignIn, resetPassword
    }
}

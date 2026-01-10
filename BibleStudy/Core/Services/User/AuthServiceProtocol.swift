import Foundation
import AuthenticationServices

// MARK: - Auth Service Protocol
// Enables dependency injection and testability for authentication

@MainActor
protocol AuthServiceProtocol: AnyObject {
    // MARK: - State Properties
    var isAuthenticated: Bool { get }
    var currentUserId: UUID? { get }
    var userProfile: UserProfile? { get set }
    var isLoading: Bool { get }
    var error: AuthError? { get }
    var hasCompletedOnboardingRemote: Bool { get }

    // MARK: - Authentication Methods
    func signUp(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws -> String
    func signInWithApple(authorization: ASAuthorization) async throws -> String
    func signOut() async throws
    func resetPassword(email: String) async throws
    func resendConfirmation(email: String) async throws

    // MARK: - Session Restoration (for biometric quick sign-in)
    func restoreSession(refreshToken: String) async throws -> String

    // MARK: - Profile Management
    func loadProfile() async throws
    func updateProfile(
        displayName: String?,
        preferredTranslation: String?,
        fontSize: Int?,
        theme: ThemeMode?,
        devotionalModeEnabled: Bool?
    ) async throws

    // MARK: - Onboarding
    func markOnboardingCompleted() async throws
}

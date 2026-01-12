import Foundation
import AuthenticationServices
import SwiftUI

// MARK: - Password Illumination
// Strength levels inspired by manuscript illumination process
enum PasswordIllumination: Int, Sendable {
    case blank = 0       // No illumination
    case rawPigment = 1  // Weak - unrefined materials
    case groundPigment = 2 // Fair - pigment prepared
    case gilded = 3      // Strong - gold leaf applied
    case illuminated = 4 // Very strong - fully illuminated

    func color(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .blank: return Color.appDivider
        case .rawPigment: return Color("FeedbackError").opacity(Theme.Opacity.overlay)
        case .groundPigment: return Color("FeedbackWarning")
        case .gilded: return Color("AccentBronze")
        case .illuminated: return Color("AccentBronze")
        }
    }

    var label: String {
        switch self {
        case .blank: return ""
        case .rawPigment: return "Needs work"
        case .groundPigment: return "Getting there"
        case .gilded: return "Well crafted"
        case .illuminated: return "Beautifully secure"
        }
    }

    var icon: String? {
        switch self {
        case .illuminated: return "sparkles"
        case .gilded: return "checkmark"
        default: return nil
        }
    }
}

// MARK: - Auth View Model
// Manages authentication UI state

@MainActor
@Observable
final class AuthViewModel {
    // MARK: - Dependencies (Protocol-based for testability)
    private let authService: AuthServiceProtocol
    private let biometricService: BiometricServiceProtocol

    // MARK: - Properties
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""

    /// Stores the refresh token temporarily after sign-in for biometric enrollment
    private var storedRefreshToken: String = ""

    var isSignUp: Bool = false
    var isLoading: Bool = false
    var showResetPassword: Bool = false
    var resetEmail: String = ""

    // Email confirmation flow
    var showEmailConfirmation: Bool = false
    var submittedEmail: String = ""

    // Biometric authentication
    var showBiometricOptIn: Bool = false
    var biometricAvailable: Bool { biometricService.isAvailable }
    var biometricEnabled: Bool { biometricService.isEnabled }
    var biometricType: BiometricType { biometricService.biometricType }
    var hasBiometricCredentials: Bool { biometricService.hasStoredCredentials }

    var errorMessage: String?
    var successMessage: String?

    var isAuthenticated: Bool {
        authService.isAuthenticated
    }

    // MARK: - Initialization

    /// Creates an AuthViewModel with dependency injection
    /// - Parameters:
    ///   - authService: Authentication service (defaults to shared singleton)
    ///   - biometricService: Biometric service (defaults to shared singleton)
    init(
        authService: AuthServiceProtocol = AuthService.shared,
        biometricService: BiometricServiceProtocol = BiometricService.shared
    ) {
        self.authService = authService
        self.biometricService = biometricService
    }

    // MARK: - Validation

    var isEmailValid: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    var isPasswordValid: Bool {
        password.count >= 8
    }

    var doPasswordsMatch: Bool {
        password == confirmPassword
    }

    var passwordStrength: PasswordIllumination {
        guard !password.isEmpty else { return .blank }

        var score = 0

        // Length checks
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }

        // Character variety checks
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasDigit = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil

        if hasUppercase && hasLowercase { score += 1 }
        if hasDigit { score += 1 }
        if hasSpecial { score += 1 }

        // Map score to illumination level
        switch score {
        case 0...1: return .rawPigment
        case 2: return .groundPigment
        case 3...4: return .gilded
        default: return .illuminated
        }
    }

    var canSubmit: Bool {
        if isSignUp {
            return isEmailValid && isPasswordValid && doPasswordsMatch
        }
        return isEmailValid && password.count > 0
    }

    // MARK: - Actions

    func signIn() async {
        guard canSubmit else { return }

        isLoading = true
        errorMessage = nil

        do {
            let refreshToken = try await authService.signIn(email: email, password: password)
            let signedInEmail = email  // Capture before clearing
            clearForm()
            isLoading = false

            // Store email and token for biometric opt-in and show prompt
            submittedEmail = signedInEmail
            storedRefreshToken = refreshToken
            handleSuccessfulSignIn()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func signUp() async {
        guard canSubmit else {
            // Show specific validation error
            if !isEmailValid {
                errorMessage = "Please enter a valid email address"
            } else if !isPasswordValid {
                errorMessage = "Password must be at least 8 characters"
            } else if !doPasswordsMatch {
                errorMessage = "Passwords don't match"
            }
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.signUp(email: email, password: password)
            // Store email for confirmation view, then navigate
            submittedEmail = email
            clearForm()
            showEmailConfirmation = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func resendConfirmationEmail() async {
        guard !submittedEmail.isEmpty else { return }

        do {
            try await authService.resendConfirmation(email: submittedEmail)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func returnToSignUp() {
        showEmailConfirmation = false
        submittedEmail = ""
        isSignUp = true
    }

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil

        switch result {
        case .success(let authorization):
            do {
                let refreshToken = try await authService.signInWithApple(authorization: authorization)
                storedRefreshToken = refreshToken
                handleSuccessfulSignIn()
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func resetPassword() async {
        guard !resetEmail.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.resetPassword(email: resetEmail)
            successMessage = "Password reset email sent"
            showResetPassword = false
            resetEmail = ""
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signOut() async {
        do {
            try await authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleMode() {
        isSignUp.toggle()
        errorMessage = nil
        password = ""
        confirmPassword = ""
    }

    // MARK: - Biometric Authentication

    /// Attempt to sign in with stored biometric credentials using token-based authentication
    func signInWithBiometrics() async {
        guard biometricEnabled, hasBiometricCredentials else { return }

        isLoading = true
        errorMessage = nil

        // Authenticate with biometrics and retrieve stored credentials
        guard let credentials = await biometricService.authenticateAndGetToken() else {
            isLoading = false
            return
        }

        do {
            // Restore the session using the stored refresh token
            let newRefreshToken = try await authService.restoreSession(refreshToken: credentials.refreshToken)

            // Update stored credentials with the new refresh token
            try biometricService.storeCredentials(
                email: credentials.email,
                refreshToken: newRefreshToken
            )
            isLoading = false
        } catch {
            // Token expired or invalid - clear credentials and prompt for password
            biometricService.clearCredentials()
            email = credentials.email
            errorMessage = "Session expired. Please sign in with your password."
            isLoading = false
        }
    }

    /// Enable biometric authentication for future sign-ins
    func enableBiometrics() {
        guard biometricAvailable, !storedRefreshToken.isEmpty else { return }

        do {
            try biometricService.storeCredentials(
                email: email.isEmpty ? submittedEmail : email,
                refreshToken: storedRefreshToken
            )
            biometricService.isEnabled = true
            showBiometricOptIn = false
            storedRefreshToken = ""  // Clear after storing
        } catch {
            errorMessage = "Failed to enable \(biometricType.displayName)"
        }
    }

    /// Skip biometric opt-in
    func skipBiometricOptIn() {
        showBiometricOptIn = false
    }

    /// Disable biometric authentication
    func disableBiometrics() {
        biometricService.clearCredentials()
    }

    /// Called after successful sign-in to potentially show biometric opt-in
    private func handleSuccessfulSignIn() {
        // Show biometric opt-in if available and not already enabled
        if biometricAvailable && !biometricEnabled {
            showBiometricOptIn = true
        }
    }

    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
    }
}

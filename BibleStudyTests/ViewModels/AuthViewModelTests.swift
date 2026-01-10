import XCTest
@testable import BibleStudy

// MARK: - Auth ViewModel Tests

@MainActor
final class AuthViewModelTests: XCTestCase {

    // MARK: - Test Properties
    private var viewModel: AuthViewModel!
    private var mockAuthService: MockAuthService!
    private var mockBiometricService: MockBiometricService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        mockBiometricService = MockBiometricService()
        viewModel = AuthViewModel(
            authService: mockAuthService,
            biometricService: mockBiometricService
        )
    }

    override func tearDown() {
        viewModel = nil
        mockAuthService = nil
        mockBiometricService = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.email, "")
        XCTAssertEqual(viewModel.password, "")
        XCTAssertEqual(viewModel.confirmPassword, "")
        XCTAssertFalse(viewModel.isSignUp)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.showResetPassword)
        XCTAssertFalse(viewModel.showEmailConfirmation)
        XCTAssertFalse(viewModel.showBiometricOptIn)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.successMessage)
    }

    func testIsAuthenticatedReflectsService() {
        XCTAssertFalse(viewModel.isAuthenticated)

        mockAuthService.isAuthenticated = true
        XCTAssertTrue(viewModel.isAuthenticated)
    }

    // MARK: - Email Validation Tests

    func testEmailValidation_ValidEmails() {
        let validEmails = [
            "test@example.com",
            "user.name@domain.org",
            "user+tag@example.co.uk",
            "a@b.cd"
        ]

        for email in validEmails {
            viewModel.email = email
            XCTAssertTrue(viewModel.isEmailValid, "Expected \(email) to be valid")
        }
    }

    func testEmailValidation_InvalidEmails() {
        let invalidEmails = [
            "",
            "notanemail",
            "@example.com",
            "user@",
            "user@.com",
            "user@domain",
            "user name@example.com"
        ]

        for email in invalidEmails {
            viewModel.email = email
            XCTAssertFalse(viewModel.isEmailValid, "Expected \(email) to be invalid")
        }
    }

    // MARK: - Password Validation Tests

    func testPasswordValidation_Valid() {
        viewModel.password = "12345678"
        XCTAssertTrue(viewModel.isPasswordValid)

        viewModel.password = "longerpassword123"
        XCTAssertTrue(viewModel.isPasswordValid)
    }

    func testPasswordValidation_Invalid() {
        viewModel.password = ""
        XCTAssertFalse(viewModel.isPasswordValid)

        viewModel.password = "1234567"
        XCTAssertFalse(viewModel.isPasswordValid)
    }

    func testPasswordsMatch() {
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        XCTAssertTrue(viewModel.doPasswordsMatch)

        viewModel.confirmPassword = "different"
        XCTAssertFalse(viewModel.doPasswordsMatch)
    }

    // MARK: - Password Strength Tests

    func testPasswordStrength_Blank() {
        viewModel.password = ""
        XCTAssertEqual(viewModel.passwordStrength, .blank)
    }

    func testPasswordStrength_RawPigment() {
        viewModel.password = "short"
        XCTAssertEqual(viewModel.passwordStrength, .rawPigment)
    }

    func testPasswordStrength_GroundPigment() {
        // Score 2 = groundPigment: 12+ chars gives score 2
        viewModel.password = "longpassword"
        XCTAssertEqual(viewModel.passwordStrength, .groundPigment)
    }

    func testPasswordStrength_Gilded() {
        viewModel.password = "LongerPass1"
        XCTAssertEqual(viewModel.passwordStrength, .gilded)
    }

    func testPasswordStrength_Illuminated() {
        viewModel.password = "LongerPass1!"
        XCTAssertEqual(viewModel.passwordStrength, .illuminated)
    }

    // MARK: - Can Submit Tests

    func testCanSubmit_SignIn_Valid() {
        viewModel.isSignUp = false
        viewModel.email = "test@example.com"
        viewModel.password = "anypassword"
        XCTAssertTrue(viewModel.canSubmit)
    }

    func testCanSubmit_SignIn_InvalidEmail() {
        viewModel.isSignUp = false
        viewModel.email = "invalid"
        viewModel.password = "anypassword"
        XCTAssertFalse(viewModel.canSubmit)
    }

    func testCanSubmit_SignIn_EmptyPassword() {
        viewModel.isSignUp = false
        viewModel.email = "test@example.com"
        viewModel.password = ""
        XCTAssertFalse(viewModel.canSubmit)
    }

    func testCanSubmit_SignUp_Valid() {
        viewModel.isSignUp = true
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        XCTAssertTrue(viewModel.canSubmit)
    }

    func testCanSubmit_SignUp_PasswordTooShort() {
        viewModel.isSignUp = true
        viewModel.email = "test@example.com"
        viewModel.password = "short"
        viewModel.confirmPassword = "short"
        XCTAssertFalse(viewModel.canSubmit)
    }

    func testCanSubmit_SignUp_PasswordsMismatch() {
        viewModel.isSignUp = true
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "different123"
        XCTAssertFalse(viewModel.canSubmit)
    }

    // MARK: - Sign In Tests

    func testSignIn_Success() async {
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        mockBiometricService.configureAsAvailable()

        await viewModel.signIn()

        XCTAssertEqual(mockAuthService.signInCallCount, 1)
        XCTAssertEqual(mockAuthService.lastSignInEmail, "test@example.com")
        XCTAssertEqual(mockAuthService.lastSignInPassword, "password123")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.showBiometricOptIn)
    }

    func testSignIn_Success_BiometricAlreadyEnabled() async {
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        mockBiometricService.configureWithStoredCredentials(
            email: "old@example.com",
            refreshToken: "old-token"
        )

        await viewModel.signIn()

        XCTAssertEqual(mockAuthService.signInCallCount, 1)
        XCTAssertFalse(viewModel.showBiometricOptIn)
    }

    func testSignIn_Failure() async {
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        mockAuthService.shouldSignInSucceed = false
        mockAuthService.signInError = .signInFailed("Invalid credentials")

        await viewModel.signIn()

        XCTAssertEqual(mockAuthService.signInCallCount, 1)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        // Error message is enhanced by AuthError.errorDescription
        XCTAssertTrue(viewModel.errorMessage?.contains("email or password") ?? false)
    }

    func testSignIn_CantSubmit() async {
        viewModel.email = "invalid"
        viewModel.password = ""

        await viewModel.signIn()

        XCTAssertEqual(mockAuthService.signInCallCount, 0)
    }

    func testSignIn_ClearsFormOnSuccess() async {
        viewModel.email = "test@example.com"
        viewModel.password = "password123"

        await viewModel.signIn()

        XCTAssertEqual(viewModel.email, "")
        XCTAssertEqual(viewModel.password, "")
    }

    // MARK: - Sign Up Tests

    func testSignUp_Success() async {
        viewModel.isSignUp = true
        viewModel.email = "newuser@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"

        await viewModel.signUp()

        XCTAssertEqual(mockAuthService.signUpCallCount, 1)
        XCTAssertEqual(mockAuthService.lastSignUpEmail, "newuser@example.com")
        XCTAssertEqual(mockAuthService.lastSignUpPassword, "password123")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.showEmailConfirmation)
        XCTAssertEqual(viewModel.submittedEmail, "newuser@example.com")
    }

    func testSignUp_Failure() async {
        viewModel.isSignUp = true
        viewModel.email = "newuser@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"
        mockAuthService.shouldSignUpSucceed = false
        mockAuthService.signUpError = .signUpFailed("Email already exists")

        await viewModel.signUp()

        XCTAssertEqual(mockAuthService.signUpCallCount, 1)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showEmailConfirmation)
    }

    func testSignUp_InvalidEmail_ShowsError() async {
        viewModel.isSignUp = true
        viewModel.email = "invalid"
        viewModel.password = "password123"
        viewModel.confirmPassword = "password123"

        await viewModel.signUp()

        XCTAssertEqual(mockAuthService.signUpCallCount, 0)
        XCTAssertEqual(viewModel.errorMessage, "Please enter a valid email address")
    }

    func testSignUp_ShortPassword_ShowsError() async {
        viewModel.isSignUp = true
        viewModel.email = "test@example.com"
        viewModel.password = "short"
        viewModel.confirmPassword = "short"

        await viewModel.signUp()

        XCTAssertEqual(mockAuthService.signUpCallCount, 0)
        XCTAssertEqual(viewModel.errorMessage, "Password must be at least 8 characters")
    }

    func testSignUp_PasswordMismatch_ShowsError() async {
        viewModel.isSignUp = true
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        viewModel.confirmPassword = "different123"

        await viewModel.signUp()

        XCTAssertEqual(mockAuthService.signUpCallCount, 0)
        XCTAssertEqual(viewModel.errorMessage, "Passwords don't match")
    }

    // MARK: - Password Reset Tests

    func testResetPassword_Success() async {
        viewModel.resetEmail = "test@example.com"
        viewModel.showResetPassword = true

        await viewModel.resetPassword()

        XCTAssertEqual(mockAuthService.resetPasswordCallCount, 1)
        XCTAssertEqual(mockAuthService.lastResetPasswordEmail, "test@example.com")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.successMessage, "Password reset email sent")
        XCTAssertFalse(viewModel.showResetPassword)
        XCTAssertEqual(viewModel.resetEmail, "")
    }

    func testResetPassword_Failure() async {
        viewModel.resetEmail = "test@example.com"
        mockAuthService.shouldResetPasswordSucceed = false

        await viewModel.resetPassword()

        XCTAssertEqual(mockAuthService.resetPasswordCallCount, 1)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.successMessage)
    }

    func testResetPassword_EmptyEmail() async {
        viewModel.resetEmail = ""

        await viewModel.resetPassword()

        XCTAssertEqual(mockAuthService.resetPasswordCallCount, 0)
        XCTAssertEqual(viewModel.errorMessage, "Please enter your email")
    }

    // MARK: - Resend Confirmation Tests

    func testResendConfirmation_Success() async {
        viewModel.submittedEmail = "test@example.com"

        await viewModel.resendConfirmationEmail()

        XCTAssertEqual(mockAuthService.resendConfirmationCallCount, 1)
        XCTAssertEqual(mockAuthService.lastResendConfirmationEmail, "test@example.com")
    }

    func testResendConfirmation_EmptyEmail() async {
        viewModel.submittedEmail = ""

        await viewModel.resendConfirmationEmail()

        XCTAssertEqual(mockAuthService.resendConfirmationCallCount, 0)
    }

    func testReturnToSignUp() {
        viewModel.showEmailConfirmation = true
        viewModel.submittedEmail = "test@example.com"
        viewModel.isSignUp = false

        viewModel.returnToSignUp()

        XCTAssertFalse(viewModel.showEmailConfirmation)
        XCTAssertEqual(viewModel.submittedEmail, "")
        XCTAssertTrue(viewModel.isSignUp)
    }

    // MARK: - Sign Out Tests

    func testSignOut_Success() async {
        mockAuthService.isAuthenticated = true

        await viewModel.signOut()

        XCTAssertEqual(mockAuthService.signOutCallCount, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSignOut_Failure() async {
        mockAuthService.shouldSignOutSucceed = false

        await viewModel.signOut()

        XCTAssertEqual(mockAuthService.signOutCallCount, 1)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Toggle Mode Tests

    func testToggleMode() {
        XCTAssertFalse(viewModel.isSignUp)
        viewModel.errorMessage = "Some error"
        viewModel.password = "password"
        viewModel.confirmPassword = "confirm"

        viewModel.toggleMode()

        XCTAssertTrue(viewModel.isSignUp)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.password, "")
        XCTAssertEqual(viewModel.confirmPassword, "")

        viewModel.toggleMode()

        XCTAssertFalse(viewModel.isSignUp)
    }

    // MARK: - Biometric Properties Tests

    func testBiometricAvailable() {
        mockBiometricService.isAvailable = true
        XCTAssertTrue(viewModel.biometricAvailable)

        mockBiometricService.isAvailable = false
        XCTAssertFalse(viewModel.biometricAvailable)
    }

    func testBiometricEnabled() {
        mockBiometricService.isEnabled = false
        XCTAssertFalse(viewModel.biometricEnabled)

        mockBiometricService.isEnabled = true
        XCTAssertTrue(viewModel.biometricEnabled)
    }

    func testBiometricType() {
        mockBiometricService.biometricType = .faceID
        XCTAssertEqual(viewModel.biometricType, .faceID)

        mockBiometricService.biometricType = .touchID
        XCTAssertEqual(viewModel.biometricType, .touchID)
    }

    func testHasBiometricCredentials() {
        mockBiometricService.hasStoredCredentials = false
        XCTAssertFalse(viewModel.hasBiometricCredentials)

        mockBiometricService.hasStoredCredentials = true
        XCTAssertTrue(viewModel.hasBiometricCredentials)
    }

    // MARK: - Biometric Sign In Tests

    func testSignInWithBiometrics_Success() async {
        mockBiometricService.configureWithStoredCredentials(
            email: "stored@example.com",
            refreshToken: "stored-token"
        )

        await viewModel.signInWithBiometrics()

        XCTAssertEqual(mockBiometricService.authenticateAndGetTokenCallCount, 1)
        XCTAssertEqual(mockAuthService.restoreSessionCallCount, 1)
        XCTAssertEqual(mockAuthService.lastRestoreSessionToken, "stored-token")
        XCTAssertEqual(mockBiometricService.storeCredentialsCallCount, 1)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testSignInWithBiometrics_NotEnabled() async {
        mockBiometricService.isEnabled = false
        mockBiometricService.hasStoredCredentials = false

        await viewModel.signInWithBiometrics()

        XCTAssertEqual(mockBiometricService.authenticateAndGetTokenCallCount, 0)
        XCTAssertEqual(mockAuthService.restoreSessionCallCount, 0)
    }

    func testSignInWithBiometrics_AuthenticationFailed() async {
        mockBiometricService.configureWithStoredCredentials(
            email: "stored@example.com",
            refreshToken: "stored-token"
        )
        mockBiometricService.shouldAuthenticateSucceed = false

        await viewModel.signInWithBiometrics()

        XCTAssertEqual(mockBiometricService.authenticateAndGetTokenCallCount, 1)
        XCTAssertEqual(mockAuthService.restoreSessionCallCount, 0)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testSignInWithBiometrics_SessionExpired() async {
        mockBiometricService.configureWithStoredCredentials(
            email: "stored@example.com",
            refreshToken: "expired-token"
        )
        mockAuthService.shouldRestoreSessionSucceed = false

        await viewModel.signInWithBiometrics()

        XCTAssertEqual(mockBiometricService.authenticateAndGetTokenCallCount, 1)
        XCTAssertEqual(mockAuthService.restoreSessionCallCount, 1)
        XCTAssertEqual(mockBiometricService.clearCredentialsCallCount, 1)
        XCTAssertEqual(viewModel.email, "stored@example.com")
        XCTAssertTrue(viewModel.errorMessage?.contains("Session expired") ?? false)
    }

    // MARK: - Enable Biometrics Tests

    func testEnableBiometrics_Success() async {
        // First sign in to get a refresh token stored
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        mockBiometricService.configureAsAvailable()

        await viewModel.signIn()

        // Now enable biometrics
        viewModel.enableBiometrics()

        XCTAssertEqual(mockBiometricService.storeCredentialsCallCount, 1)
        XCTAssertEqual(mockBiometricService.lastStoredEmail, "test@example.com")
        XCTAssertEqual(mockBiometricService.lastStoredRefreshToken, mockAuthService.mockRefreshToken)
        XCTAssertTrue(mockBiometricService.isEnabled)
        XCTAssertFalse(viewModel.showBiometricOptIn)
    }

    func testEnableBiometrics_NotAvailable() {
        mockBiometricService.configureAsUnavailable()

        viewModel.enableBiometrics()

        XCTAssertEqual(mockBiometricService.storeCredentialsCallCount, 0)
    }

    func testEnableBiometrics_StoreFailure() async {
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        mockBiometricService.configureAsAvailable()

        // First sign in to get a refresh token stored
        await viewModel.signIn()

        // Verify sign-in succeeded and biometric opt-in is showing
        XCTAssertEqual(mockAuthService.signInCallCount, 1)
        XCTAssertTrue(viewModel.showBiometricOptIn)

        // Now configure store to fail and attempt enableBiometrics
        mockBiometricService.shouldStoreCredentialsSucceed = false
        viewModel.enableBiometrics()

        XCTAssertEqual(mockBiometricService.storeCredentialsCallCount, 1)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Failed to enable") ?? false)
    }

    // MARK: - Skip and Disable Biometrics Tests

    func testSkipBiometricOptIn() {
        viewModel.showBiometricOptIn = true

        viewModel.skipBiometricOptIn()

        XCTAssertFalse(viewModel.showBiometricOptIn)
    }

    func testDisableBiometrics() {
        mockBiometricService.configureWithStoredCredentials(
            email: "test@example.com",
            refreshToken: "token"
        )

        viewModel.disableBiometrics()

        XCTAssertEqual(mockBiometricService.clearCredentialsCallCount, 1)
    }
}

// MARK: - Password Illumination Tests

final class PasswordIlluminationTests: XCTestCase {

    func testPasswordIlluminationColors() {
        XCTAssertNotNil(PasswordIllumination.blank.color)
        XCTAssertNotNil(PasswordIllumination.rawPigment.color)
        XCTAssertNotNil(PasswordIllumination.groundPigment.color)
        XCTAssertNotNil(PasswordIllumination.gilded.color)
        XCTAssertNotNil(PasswordIllumination.illuminated.color)
    }

    func testPasswordIlluminationLabels() {
        XCTAssertEqual(PasswordIllumination.blank.label, "")
        XCTAssertEqual(PasswordIllumination.rawPigment.label, "Needs work")
        XCTAssertEqual(PasswordIllumination.groundPigment.label, "Getting there")
        XCTAssertEqual(PasswordIllumination.gilded.label, "Well crafted")
        XCTAssertEqual(PasswordIllumination.illuminated.label, "Beautifully secure")
    }

    func testPasswordIlluminationIcons() {
        XCTAssertNil(PasswordIllumination.blank.icon)
        XCTAssertNil(PasswordIllumination.rawPigment.icon)
        XCTAssertNil(PasswordIllumination.groundPigment.icon)
        XCTAssertEqual(PasswordIllumination.gilded.icon, "checkmark")
        XCTAssertEqual(PasswordIllumination.illuminated.icon, "sparkles")
    }

    func testPasswordIlluminationRawValues() {
        XCTAssertEqual(PasswordIllumination.blank.rawValue, 0)
        XCTAssertEqual(PasswordIllumination.rawPigment.rawValue, 1)
        XCTAssertEqual(PasswordIllumination.groundPigment.rawValue, 2)
        XCTAssertEqual(PasswordIllumination.gilded.rawValue, 3)
        XCTAssertEqual(PasswordIllumination.illuminated.rawValue, 4)
    }
}

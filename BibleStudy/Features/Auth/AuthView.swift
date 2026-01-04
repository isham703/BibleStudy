import SwiftUI
import AuthenticationServices

// MARK: - Auth View
// Main authentication screen with sign in/up and Apple Sign In

struct AuthView: View {
    @State private var viewModel = AuthViewModel()

    // MARK: - Focus State
    enum AuthField: Hashable {
        case email, password, confirmPassword
    }
    @FocusState private var focusedField: AuthField?
    @FocusState private var resetEmailFocused: Bool

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.showEmailConfirmation {
                    EmailConfirmationView(
                        email: viewModel.submittedEmail,
                        onResend: {
                            await viewModel.resendConfirmationEmail()
                        },
                        onChangeEmail: {
                            viewModel.returnToSignUp()
                        }
                    )
                } else {
                    mainAuthContent
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("Success", isPresented: .init(
                get: { viewModel.successMessage != nil },
                set: { if !$0 { viewModel.successMessage = nil } }
            )) {
                Button("OK") { viewModel.successMessage = nil }
            } message: {
                Text(viewModel.successMessage ?? "")
            }
            .sheet(isPresented: $viewModel.showResetPassword) {
                resetPasswordSheet
            }
            .sheet(isPresented: $viewModel.showBiometricOptIn) {
                BiometricOptInView(
                    biometricType: viewModel.biometricType,
                    onEnable: { viewModel.enableBiometrics() },
                    onSkip: { viewModel.skipBiometricOptIn() }
                )
                .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Main Auth Content
    private var mainAuthContent: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Logo/Header
                headerSection

                // Auth Form
                formSection

                // Divider
                dividerSection

                // Apple Sign In
                appleSignInSection

                // Toggle Sign In/Up
                toggleSection
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(Color.primaryBackground)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Auto-focus email field with slight delay for smooth transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                focusedField = .email
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "book.closed.fill")
                .font(Typography.UI.largeTitle)
                .imageScale(.large)
                .foregroundStyle(Color.scholarAccent)

            Text("Bible Study")
                .font(Typography.Scripture.title)
                .foregroundStyle(Color.primaryText)

            Text(viewModel.isSignUp ? "Create your account" : "Welcome back")
                .font(Typography.UI.warmBody)
                .foregroundStyle(Color.secondaryText)
        }
        .padding(.top, AppTheme.Spacing.xl)
    }

    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Email
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Email")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.secondaryText)

                TextField("you@example.com", text: $viewModel.email)
                    .textFieldStyle(ScribeFocusStyle(
                        isFocused: focusedField == .email,
                        validationState: viewModel.email.isEmpty ? nil : viewModel.isEmailValid
                    ))
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }

            // Password
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Password")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.secondaryText)

                SecureField("••••••••", text: $viewModel.password)
                    .textFieldStyle(ScribeFocusStyle(
                        isFocused: focusedField == .password,
                        validationState: viewModel.password.isEmpty ? nil : viewModel.isPasswordValid
                    ))
                    .focused($focusedField, equals: .password)
                    .submitLabel(viewModel.isSignUp ? .next : .done)
                    .onSubmit {
                        if viewModel.isSignUp {
                            focusedField = .confirmPassword
                        } else {
                            focusedField = nil
                            Task { await viewModel.signIn() }
                        }
                    }

                // Password strength indicator (sign up only)
                if viewModel.isSignUp && !viewModel.password.isEmpty {
                    IlluminationMeter(strength: viewModel.passwordStrength)
                }
            }

            // Confirm Password (Sign Up only)
            if viewModel.isSignUp {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Confirm Password")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.secondaryText)

                    SecureField("••••••••", text: $viewModel.confirmPassword)
                        .textFieldStyle(ScribeFocusStyle(
                            isFocused: focusedField == .confirmPassword,
                            validationState: viewModel.confirmPassword.isEmpty ? nil : viewModel.doPasswordsMatch
                        ))
                        .focused($focusedField, equals: .confirmPassword)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                            Task { await viewModel.signUp() }
                        }

                    if !viewModel.confirmPassword.isEmpty && !viewModel.doPasswordsMatch {
                        Text("Passwords don't match")
                            .font(Typography.UI.caption2)
                            .foregroundStyle(Color.error)
                    }
                }
            }

            // Forgot Password (Sign In only)
            if !viewModel.isSignUp {
                HStack {
                    Spacer()
                    Button("Forgot password?") {
                        viewModel.showResetPassword = true
                    }
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.scholarAccent)
                }
            }

            // Submit Button
            Button {
                Task {
                    if viewModel.isSignUp {
                        await viewModel.signUp()
                    } else {
                        await viewModel.signIn()
                    }
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(viewModel.isSignUp ? "Create Account" : "Sign In")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(AppTheme.Spacing.md)
                .background(viewModel.canSubmit ? Color.scholarAccent : Color.tertiaryText)
                .foregroundStyle(.white)
                .font(Typography.UI.bodyBold)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
            }
            .disabled(!viewModel.canSubmit || viewModel.isLoading)
        }
    }

    // MARK: - Divider Section
    private var dividerSection: some View {
        HStack {
            Rectangle()
                .fill(Color.divider)
                .frame(height: AppTheme.Divider.thin)

            Text("or")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.tertiaryText)
                .padding(.horizontal, AppTheme.Spacing.sm)

            Rectangle()
                .fill(Color.divider)
                .frame(height: AppTheme.Divider.thin)
        }
    }

    // MARK: - Apple Sign In Section
    private var appleSignInSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.email, .fullName]
            } onCompletion: { result in
                Task {
                    await viewModel.handleAppleSignIn(result)
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                    .stroke(Color.divider, lineWidth: AppTheme.Border.thin)
            )

            // Biometric quick sign-in (only shown if enabled and not in sign-up mode)
            if viewModel.biometricEnabled && viewModel.hasBiometricCredentials && !viewModel.isSignUp {
                biometricSignInButton
            }
        }
    }

    // MARK: - Biometric Sign In Button
    @ViewBuilder
    private var biometricSignInButton: some View {
        Button {
            Task {
                await viewModel.signInWithBiometrics()
            }
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                // Sacred seal styling for biometric icon
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.illuminatedGold, .divineGold, .burnishedGold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: AppTheme.Border.regular
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: viewModel.biometricType.systemImage)
                        .font(Typography.UI.iconMd.weight(.medium))
                        .foregroundStyle(Color.divineGold)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(viewModel.biometricType.signInLabel)
                        .font(Typography.UI.bodyBold)
                        .foregroundStyle(Color.primaryText)
                    Text("Quick & secure access")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(AppTheme.Spacing.md)
            .background(Color.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                    .stroke(Color.divider, lineWidth: AppTheme.Border.thin)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toggle Section
    private var toggleSection: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Text(viewModel.isSignUp ? "Already have an account?" : "Don't have an account?")
                .font(Typography.UI.body)
                .foregroundStyle(Color.secondaryText)

            Button(viewModel.isSignUp ? "Sign In" : "Sign Up") {
                viewModel.toggleMode()
            }
            .font(Typography.UI.bodyBold)
            .foregroundStyle(Color.scholarAccent)
        }
        .padding(.bottom, AppTheme.Spacing.lg)
    }

    // MARK: - Reset Password Sheet
    private var resetPasswordSheet: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.lg) {
                Text("Enter your email and we'll send you a link to reset your password.")
                    .font(Typography.UI.warmBody)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)

                TextField("Email", text: $viewModel.resetEmail)
                    .textFieldStyle(ScribeFocusStyle(
                        isFocused: resetEmailFocused,
                        validationState: nil
                    ))
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .focused($resetEmailFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        resetEmailFocused = false
                        Task { await viewModel.resetPassword() }
                    }

                Button {
                    Task {
                        await viewModel.resetPassword()
                    }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Send Reset Link")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.Spacing.md)
                    .background(Color.scholarAccent)
                    .foregroundStyle(.white)
                    .font(Typography.UI.bodyBold)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
                }
                .disabled(viewModel.isLoading)

                Spacer()
            }
            .padding(AppTheme.Spacing.lg)
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showResetPassword = false
                    }
                }
            }
            .onAppear {
                // Auto-focus reset email field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    resetEmailFocused = true
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Scribe Focus Style
// "Scribe's Attention" - Focus state feels like a scribe's quill hovering over the exact writing position
struct ScribeFocusStyle: TextFieldStyle {
    let isFocused: Bool
    let validationState: Bool? // nil = no validation, true = valid, false = invalid

    private var borderColor: Color {
        if let isValid = validationState {
            return isValid ? Color.divineGold : Color.vermillion
        }
        return isFocused ? Color.divineGold : Color.divider
    }

    private var borderWidth: CGFloat {
        isFocused ? AppTheme.Border.regular : AppTheme.Border.thin
    }

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(AppTheme.Spacing.md)
            .foregroundStyle(Color.primaryText)
            .background(
                ZStack {
                    // Base surface
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                        .fill(Color.secondaryBackground)

                    // Focused glow layer - warm gold ambient
                    if isFocused {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                            .fill(Color.Glow.indigoAmbient)
                            .blur(radius: AppTheme.Blur.medium)
                            .offset(y: 2)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            // Subtle lift on focus with gold glow
            .shadow(
                color: isFocused
                    ? Color.divineGold.opacity(AppTheme.Opacity.light)
                    : .clear,
                radius: isFocused ? AppTheme.Blur.medium : 0,
                y: isFocused ? 2 : 0
            )
            .animation(
                isFocused
                    ? AppTheme.Animation.luminous  // Fast-in for appearing focus
                    : AppTheme.Animation.reverent, // Slow, dignified fade out
                value: isFocused
            )
            .animation(AppTheme.Animation.sacredSpring, value: validationState)
    }
}

// MARK: - Legacy Auth Text Field Style (deprecated, use ScribeFocusStyle)
struct AuthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(AppTheme.Spacing.md)
            .background(Color.secondaryBackground)
            .foregroundStyle(Color.primaryText)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                    .stroke(Color.divider, lineWidth: AppTheme.Border.thin)
            )
    }
}

// MARK: - Illumination Meter
// Password strength indicator inspired by manuscript illumination stages
struct IlluminationMeter: View {
    let strength: PasswordIllumination

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            // Bar with 4 segments
            HStack(spacing: AppTheme.Spacing.xxs - 1) {
                ForEach(1...4, id: \.self) { segment in
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xs)
                        .fill(segment <= strength.rawValue
                            ? strength.color
                            : Color.divider)
                        .frame(height: AppTheme.Divider.thick)
                        .overlay(
                            // Gold shimmer on filled high-strength segments
                            segment <= strength.rawValue && strength.rawValue >= 3
                            ? shimmerOverlay : nil
                        )
                }
            }

            // Label with optional icon
            if !strength.label.isEmpty {
                HStack(spacing: AppTheme.Spacing.xs) {
                    if let icon = strength.icon {
                        Image(systemName: icon)
                            .font(Typography.UI.iconXxs.weight(.medium))
                    }
                    Text(strength.label)
                        .font(Typography.UI.caption2)
                }
                .foregroundStyle(strength.color)
            }
        }
        .animation(AppTheme.Animation.sacredSpring, value: strength)
    }

    @ViewBuilder
    private var shimmerOverlay: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xs)
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.illuminatedGold.opacity(AppTheme.Opacity.medium),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .opacity(AppTheme.Opacity.heavy)
    }
}

// MARK: - Preview
#Preview {
    AuthView()
}

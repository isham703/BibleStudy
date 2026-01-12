import SwiftUI
import AuthenticationServices

// MARK: - Auth View
// Main authentication screen with sign in/up and Apple Sign In

struct AuthView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppState.self) private var appState
    @State private var viewModel = AuthViewModel()

    // MARK: - Focus State
    enum AuthField: Hashable {
        case email, password, confirmPassword
    }
    @FocusState private var focusedField: AuthField?
    @FocusState private var resetEmailFocused: Bool

    // Password visibility
    @State private var showPassword = false
    @State private var showConfirmPassword = false

    // MARK: - Computed Properties

    private var passwordBorderColor: Color {
        if !viewModel.password.isEmpty {
            return viewModel.isPasswordValid ? Color("AccentBronze") : Color("FeedbackError")
        }
        return focusedField == .password ? Color("AccentBronze") : Color.appDivider
    }

    private var confirmPasswordBorderColor: Color {
        if !viewModel.confirmPassword.isEmpty {
            return viewModel.doPasswordsMatch ? Color("AccentBronze") : Color("FeedbackError")
        }
        return focusedField == .confirmPassword ? Color("AccentBronze") : Color.appDivider
    }

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
            .onChange(of: viewModel.errorMessage) { _, newValue in
                if let error = newValue {
                    // Announce errors to VoiceOver users
                    UIAccessibility.post(notification: .announcement, argument: "Error: \(error)")
                }
            }
            .onChange(of: viewModel.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    // Update AppState to trigger navigation to MainTabView
                    appState.isAuthenticated = true
                    if let userId = AuthService.shared.currentUserId {
                        appState.userId = userId.uuidString
                    }
                }
            }
        }
    }

    // MARK: - Main Auth Content
    private var mainAuthContent: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
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
            .padding(Theme.Spacing.lg)
        }
        .background(Color.appBackground)
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
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "book.closed.fill")
                .font(Typography.Command.largeTitle)
                .imageScale(.large)
                .foregroundStyle(Color("AppAccentAction"))

            Text("Bible Study")
                .font(Typography.Scripture.title)
                .foregroundStyle(Color("AppTextPrimary"))

            Text(viewModel.isSignUp ? "Create your account" : "Welcome back")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .padding(.top, Theme.Spacing.xl)
    }

    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Inline error banner
            if let error = viewModel.errorMessage {
                inlineErrorBanner(message: error)
            }

            // Email
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Email")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppTextSecondary"))

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
                    .accessibilityLabel("Email")
                    .accessibilityHint("Enter your email address")
                    .accessibilityValue(viewModel.email.isEmpty ? "Empty" : viewModel.email)
            }

            // Password
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Password")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppTextSecondary"))

                HStack(spacing: 0) {
                    Group {
                        if showPassword {
                            TextField("••••••••", text: $viewModel.password)
                        } else {
                            SecureField("••••••••", text: $viewModel.password)
                        }
                    }
                    .textFieldStyle(PasswordFieldStyle(
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
                    .accessibilityLabel("Password")
                    .accessibilityHint(viewModel.isSignUp ? "Must be at least 8 characters" : "Enter your password")
                    .accessibilityValue("\(viewModel.password.count) characters")

                    // Visibility toggle button
                    Button {
                        showPassword.toggle()
                        HapticService.shared.selectionChanged()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .font(Typography.Icon.md)
                            .foregroundStyle(Color("TertiaryText"))
                            .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                    }
                    .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                }
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(Color.appSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .stroke(
                            passwordBorderColor,
                            lineWidth: focusedField == .password ? Theme.Stroke.control : Theme.Stroke.hairline
                        )
                )
                .shadow(
                    color: focusedField == .password
                        ? Color("AccentBronze").opacity(Theme.Opacity.selectionBackground)
                        : .clear,
                    radius: focusedField == .password ? 8 : 0,
                    y: focusedField == .password ? 2 : 0
                )
                .animation(Theme.Animation.settle, value: passwordBorderColor)

                // Password strength indicator (sign up only)
                if viewModel.isSignUp && !viewModel.password.isEmpty {
                    IlluminationMeter(strength: viewModel.passwordStrength)
                }
            }

            // Confirm Password (Sign Up only)
            if viewModel.isSignUp {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Confirm Password")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("AppTextSecondary"))

                    HStack(spacing: 0) {
                        Group {
                            if showConfirmPassword {
                                TextField("••••••••", text: $viewModel.confirmPassword)
                            } else {
                                SecureField("••••••••", text: $viewModel.confirmPassword)
                            }
                        }
                        .textFieldStyle(PasswordFieldStyle(
                            isFocused: focusedField == .confirmPassword,
                            validationState: viewModel.confirmPassword.isEmpty ? nil : viewModel.doPasswordsMatch
                        ))
                        .focused($focusedField, equals: .confirmPassword)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                            Task { await viewModel.signUp() }
                        }
                        .accessibilityLabel("Confirm password")
                        .accessibilityHint("Re-enter your password to confirm")
                        .accessibilityValue(viewModel.doPasswordsMatch ? "Passwords match" : "Passwords do not match")

                        // Visibility toggle button
                        Button {
                            showConfirmPassword.toggle()
                            HapticService.shared.selectionChanged()
                        } label: {
                            Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                .font(Typography.Icon.md)
                                .foregroundStyle(Color("TertiaryText"))
                                .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                        }
                        .accessibilityLabel(showConfirmPassword ? "Hide password" : "Show password")
                    }
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .fill(Color.appSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .stroke(
                                confirmPasswordBorderColor,
                                lineWidth: focusedField == .confirmPassword ? Theme.Stroke.control : Theme.Stroke.hairline
                            )
                    )
                    .shadow(
                        color: focusedField == .confirmPassword
                            ? Color("AccentBronze").opacity(Theme.Opacity.selectionBackground)
                            : .clear,
                        radius: focusedField == .confirmPassword ? 8 : 0,
                        y: focusedField == .confirmPassword ? 2 : 0
                    )

                    if !viewModel.confirmPassword.isEmpty && !viewModel.doPasswordsMatch {
                        Text("Passwords don't match")
                            .font(Typography.Command.meta)
                            .foregroundStyle(Color("FeedbackError"))
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
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppAccentAction"))
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
                .padding(Theme.Spacing.md)
                .background(viewModel.canSubmit ? Color("AppAccentAction") : Color("TertiaryText"))
                .foregroundStyle(.white)
                .font(Typography.Command.body.weight(.semibold))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
            .disabled(!viewModel.canSubmit || viewModel.isLoading)
            .accessibilityLabel(viewModel.isSignUp ? "Create account" : "Sign in")
            .accessibilityHint(viewModel.canSubmit ? "Double tap to submit" : "Complete all fields first")
        }
    }

    // MARK: - Divider Section
    private var dividerSection: some View {
        HStack {
            Rectangle()
                .fill(Color.appDivider)
                .frame(height: Theme.Stroke.hairline)

            Text("or")
                .font(Typography.Command.caption)
                .foregroundStyle(Color("TertiaryText"))
                .padding(.horizontal, Theme.Spacing.sm)

            Rectangle()
                .fill(Color.appDivider)
                .frame(height: Theme.Stroke.hairline)
        }
    }

    // MARK: - Apple Sign In Section
    private var appleSignInSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.email, .fullName]
            } onCompletion: { result in
                Task {
                    await viewModel.handleAppleSignIn(result)
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)
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
            HStack(spacing: Theme.Spacing.md) {
                // Sacred seal styling for biometric icon
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color("AccentBronze"), Color("AccentBronze"), Color("AccentBronze").opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: Theme.Stroke.control
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: viewModel.biometricType.systemImage)
                        .font(Typography.Icon.md.weight(.medium))
                        .foregroundStyle(Color("AccentBronze"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.biometricType.signInLabel)
                        .font(Typography.Command.body.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text("Quick & secure access")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .padding(Theme.Spacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sign in with \(viewModel.biometricType.displayName)")
        .accessibilityHint("Quick biometric authentication")
    }

    // MARK: - Toggle Section
    private var toggleSection: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(viewModel.isSignUp ? "Already have an account?" : "Don't have an account?")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))

            Button(viewModel.isSignUp ? "Sign In" : "Sign Up") {
                viewModel.toggleMode()
            }
            .font(Typography.Command.body.weight(.semibold))
            .foregroundStyle(Color("AppAccentAction"))
        }
        .padding(.bottom, Theme.Spacing.lg)
    }

    // MARK: - Reset Password Sheet
    private var resetPasswordSheet: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                Text("Enter your email and we'll send you a link to reset your password.")
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextSecondary"))
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
                    .padding(Theme.Spacing.md)
                    .background(Color("AppAccentAction"))
                    .foregroundStyle(.white)
                    .font(Typography.Command.body.weight(.semibold))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                }
                .disabled(viewModel.isLoading)

                Spacer()
            }
            .padding(Theme.Spacing.lg)
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

    // MARK: - Inline Error Banner
    @ViewBuilder
    private func inlineErrorBanner(message: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(Typography.Icon.md)
                .foregroundStyle(Color("FeedbackError"))

            Text(message)
                .font(Typography.Command.caption)
                .foregroundStyle(Color("FeedbackError"))
                .multilineTextAlignment(.leading)

            Spacer()

            Button {
                viewModel.errorMessage = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(Typography.Icon.md)
                    .foregroundStyle(Color("FeedbackError").opacity(Theme.Opacity.overlay))
            }
            .accessibilityLabel("Dismiss error")
        }
        .padding(Theme.Spacing.md)
        .background(Color("FeedbackError").opacity(Theme.Opacity.overlay))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .stroke(Color("FeedbackError").opacity(Theme.Opacity.subtle), lineWidth: Theme.Stroke.hairline)
        )
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        ))
        .animation(Theme.Animation.settle, value: message)
    }
}

// MARK: - Scribe Focus Style
// "Scribe's Attention" - Focus state feels like a scribe's quill hovering over the exact writing position
struct ScribeFocusStyle: TextFieldStyle {
    @Environment(\.colorScheme) private var colorScheme
    let isFocused: Bool
    let validationState: Bool? // nil = no validation, true = valid, false = invalid

    private var borderColor: Color {
        if let isValid = validationState {
            return isValid ? Color("AccentBronze") : Color("FeedbackError")
        }
        return isFocused ? Color("AccentBronze") : Color.appDivider
    }

    private var borderWidth: CGFloat {
        isFocused ? Theme.Stroke.control : Theme.Stroke.hairline
    }

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(Theme.Spacing.md)
            .foregroundStyle(Color("AppTextPrimary"))
            .background(
                ZStack {
                    // Base surface
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(Color.appSurface)

                    // Focused glow layer - warm gold ambient
                    if isFocused {
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .fill(Color("AppAccentAction").opacity(Theme.Opacity.subtle))
                            .blur(radius: 8)
                            .offset(y: 2)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            // Subtle lift on focus with gold glow
            .shadow(
                color: isFocused
                    ? Color("AccentBronze").opacity(Theme.Opacity.selectionBackground)
                    : .clear,
                radius: isFocused ? 8 : 0,
                y: isFocused ? 2 : 0
            )
            .animation(
                isFocused
                    ? Theme.Animation.slowFade  // Fast-in for appearing focus
                    : Theme.Animation.slowFade, // Slow, dignified fade out
                value: isFocused
            )
            .animation(Theme.Animation.settle, value: validationState)
    }
}

// MARK: - Password Field Style
// Simplified style for password fields with visibility toggle (no border/background - parent handles it)
struct PasswordFieldStyle: TextFieldStyle {
    let isFocused: Bool
    let validationState: Bool?

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.leading, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.md)
            .foregroundStyle(Color("AppTextPrimary"))
    }
}

// MARK: - Legacy Auth Text Field Style (deprecated, use ScribeFocusStyle)
struct AuthTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) private var colorScheme

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(Theme.Spacing.md)
            .background(Color.appSurface)
            .foregroundStyle(Color("AppTextPrimary"))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)
            )
    }
}

// MARK: - Illumination Meter
// Password strength indicator inspired by manuscript illumination stages
struct IlluminationMeter: View {
    let strength: PasswordIllumination
    @State private var previousStrength: PasswordIllumination = .blank

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Bar with 4 segments
            HStack(spacing: 2 - 1) {
                ForEach(1...4, id: \.self) { segment in
                    RoundedRectangle(cornerRadius: Theme.Radius.xs)
                        .fill(segment <= strength.rawValue
                            ? strength.color(for: colorScheme)
                            : Color.appDivider)
                        .frame(height: 3)
                        .overlay(
                            // Gold shimmer on filled high-strength segments
                            segment <= strength.rawValue && strength.rawValue >= 3
                            ? shimmerOverlay : nil
                        )
                }
            }

            // Label with optional icon
            if !strength.label.isEmpty {
                HStack(spacing: Theme.Spacing.xs) {
                    if let icon = strength.icon {
                        Image(systemName: icon)
                            .font(Typography.Icon.xxs.weight(.medium))
                    }
                    Text(strength.label)
                        .font(Typography.Command.meta)
                }
                .foregroundStyle(strength.color(for: colorScheme))
            }
        }
        .animation(Theme.Animation.settle, value: strength)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Password strength")
        .accessibilityValue(strength.label.isEmpty ? "Not evaluated" : strength.label)
        .onChange(of: strength) { oldValue, newValue in
            // Announce strength changes to VoiceOver users
            if oldValue != .blank && newValue != .blank && oldValue != newValue {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "Password strength: \(newValue.label)"
                )
            }
        }
    }

    @ViewBuilder
    private var shimmerOverlay: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.xs)
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        Color("AccentBronze").opacity(Theme.Opacity.focusStroke),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .opacity(Theme.Opacity.textSecondary)
    }
}

// MARK: - Preview
#Preview {
    AuthView()
}

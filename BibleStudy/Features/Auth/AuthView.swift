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
            return viewModel.isPasswordValid ? Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)) : Colors.Semantic.error(for: ThemeMode.current(from: colorScheme))
        }
        return focusedField == .password ? Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)) : Color.divider
    }

    private var confirmPasswordBorderColor: Color {
        if !viewModel.confirmPassword.isEmpty {
            return viewModel.doPasswordsMatch ? Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)) : Colors.Semantic.error(for: ThemeMode.current(from: colorScheme))
        }
        return focusedField == .confirmPassword ? Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)) : Color.divider
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
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "book.closed.fill")
                .font(Typography.Command.largeTitle)
                .imageScale(.large)
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

            Text("Bible Study")
                .font(Typography.Scripture.title)
                .foregroundStyle(Color.primaryText)

            Text(viewModel.isSignUp ? "Create your account" : "Welcome back")
                .font(Typography.Command.body)
                .foregroundStyle(Color.secondaryText)
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
                    .accessibilityLabel("Email")
                    .accessibilityHint("Enter your email address")
                    .accessibilityValue(viewModel.email.isEmpty ? "Empty" : viewModel.email)
            }

            // Password
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Password")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.secondaryText)

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
                            .foregroundStyle(Color.tertiaryText)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                }
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(Color.secondaryBackground)
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
                        ? Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light)
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
                        .foregroundStyle(Color.secondaryText)

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
                                .foregroundStyle(Color.tertiaryText)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel(showConfirmPassword ? "Hide password" : "Show password")
                    }
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .fill(Color.secondaryBackground)
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
                            ? Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light)
                            : .clear,
                        radius: focusedField == .confirmPassword ? 8 : 0,
                        y: focusedField == .confirmPassword ? 2 : 0
                    )

                    if !viewModel.confirmPassword.isEmpty && !viewModel.doPasswordsMatch {
                        Text("Passwords don't match")
                            .font(Typography.Command.meta)
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
                    .font(Typography.Command.caption)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
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
                .background(viewModel.canSubmit ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Color.tertiaryText)
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
                .fill(Color.divider)
                .frame(height: Theme.Stroke.hairline)

            Text("or")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.tertiaryText)
                .padding(.horizontal, Theme.Spacing.sm)

            Rectangle()
                .fill(Color.divider)
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
                    .stroke(Color.divider, lineWidth: Theme.Stroke.hairline)
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
                                colors: [Color.accentBronze, Color.accentBronze, .burnishedGold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: Theme.Stroke.control
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: viewModel.biometricType.systemImage)
                        .font(Typography.Icon.md.weight(.medium))
                        .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.biometricType.signInLabel)
                        .font(Typography.Command.body.weight(.semibold))
                        .foregroundStyle(Color.primaryText)
                    Text("Quick & secure access")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(Theme.Spacing.md)
            .background(Color.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(Color.divider, lineWidth: Theme.Stroke.hairline)
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
                .foregroundStyle(Color.secondaryText)

            Button(viewModel.isSignUp ? "Sign In" : "Sign Up") {
                viewModel.toggleMode()
            }
            .font(Typography.Command.body.weight(.semibold))
            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
        }
        .padding(.bottom, Theme.Spacing.lg)
    }

    // MARK: - Reset Password Sheet
    private var resetPasswordSheet: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                Text("Enter your email and we'll send you a link to reset your password.")
                    .font(Typography.Command.body)
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
                    .padding(Theme.Spacing.md)
                    .background(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
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
                .foregroundStyle(Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)))

            Text(message)
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)))
                .multilineTextAlignment(.leading)

            Spacer()

            Button {
                viewModel.errorMessage = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(Typography.Icon.md)
                    .foregroundStyle(Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.overlay))
            }
            .accessibilityLabel("Dismiss error")
        }
        .padding(Theme.Spacing.md)
        .background(Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.overlay))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .stroke(Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle), lineWidth: Theme.Stroke.hairline)
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
            return isValid ? Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)) : Colors.Semantic.error(for: ThemeMode.current(from: colorScheme))
        }
        return isFocused ? Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)) : Color.divider
    }

    private var borderWidth: CGFloat {
        isFocused ? Theme.Stroke.control : Theme.Stroke.hairline
    }

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(Theme.Spacing.md)
            .foregroundStyle(Color.primaryText)
            .background(
                ZStack {
                    // Base surface
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(Color.secondaryBackground)

                    // Focused glow layer - warm gold ambient
                    if isFocused {
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .fill(Color.Glow.indigoAmbient)
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
                    ? Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light)
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
            .foregroundStyle(Color.primaryText)
    }
}

// MARK: - Legacy Auth Text Field Style (deprecated, use ScribeFocusStyle)
struct AuthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(Theme.Spacing.md)
            .background(Color.secondaryBackground)
            .foregroundStyle(Color.primaryText)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(Color.divider, lineWidth: Theme.Stroke.hairline)
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
                            : Color.divider)
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
                        Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.medium),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .opacity(Theme.Opacity.heavy)
    }
}

// MARK: - Preview
#Preview {
    AuthView()
}

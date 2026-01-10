import SwiftUI

// MARK: - Biometric Opt-In View
// "Sacred Seal" - Shown after first successful sign-in to offer biometric quick access

struct BiometricOptInView: View {
    let biometricType: BiometricType
    let onEnable: () -> Void
    let onSkip: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Sacred Seal Icon
            sealIcon

            // Title
            Text("Enable Quick Sign In?")
                .font(Typography.Scripture.title)
                .foregroundStyle(Color.primaryText)
                .multilineTextAlignment(.center)

            // Description
            Text("Use \(biometricType.displayName) to sign in instantly next time. Your data stays secure.")
                .font(Typography.Command.body)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)

            Spacer()

            // Action Buttons
            VStack(spacing: Theme.Spacing.md) {
                // Enable button with sacred styling
                Button(action: onEnable) {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "sparkles")
                            .font(Typography.Icon.md.weight(.medium))

                        Text("Enable \(biometricType.displayName)")
                            .font(Typography.Command.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                    .background(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                }
                .accessibilityLabel("Enable \(biometricType.displayName)")
                .accessibilityHint("Secure biometric authentication for quick sign-in")

                // Skip button
                Button(action: onSkip) {
                    Text("Maybe Later")
                        .font(Typography.Command.body)
                        .foregroundStyle(Color.secondaryText)
                }
                .padding(.vertical, Theme.Spacing.sm)
                .accessibilityLabel("Skip biometric setup")
                .accessibilityHint("You can enable this later in Settings")
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Colors.Surface.background(for: ThemeMode.current(from: colorScheme)))
        .onAppear {
            withAnimation(Theme.Animation.slowFade) {
                isAnimating = true
            }
        }
    }

    // MARK: - Sacred Seal Icon
    private var sealIcon: some View {
        ZStack {
            // Outer decorative ring
            Circle()
                .stroke(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)), lineWidth: Theme.Stroke.control)
                .frame(width: 100, height: 100)
                .scaleEffect(isAnimating ? 1 : 0.9)
                .opacity(isAnimating ? 1 : 0.5)

            // Glow ring
            Circle()
                .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle))
                .frame(width: 90, height: 90)
                .blur(radius: 16)
                .scaleEffect(isAnimating ? 1.1 : 0.9)

            // Inner background
            Circle()
                .fill(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)))
                .frame(width: 80, height: 80)

            // Biometric icon
            Image(systemName: biometricType.systemImage)
                .font(Typography.Icon.hero)
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
                .scaleEffect(isAnimating ? 1 : 0.8)
                .opacity(isAnimating ? 1 : 0)
        }
        .animation(Theme.Animation.settle, value: isAnimating)
        .accessibilityHidden(true)
    }
}

// MARK: - Preview
#Preview("Face ID") {
    BiometricOptInView(
        biometricType: .faceID,
        onEnable: {},
        onSkip: {}
    )
}

#Preview("Touch ID") {
    BiometricOptInView(
        biometricType: .touchID,
        onEnable: {},
        onSkip: {}
    )
}

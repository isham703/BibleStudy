import SwiftUI

// MARK: - Biometric Opt-In View
// "Sacred Seal" - Shown after first successful sign-in to offer biometric quick access

struct BiometricOptInView: View {
    let biometricType: BiometricType
    let onEnable: () -> Void
    let onSkip: () -> Void

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
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
                .font(Typography.UI.warmBody)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.lg)

            Spacer()

            // Action Buttons
            VStack(spacing: AppTheme.Spacing.md) {
                // Enable button with sacred styling
                Button(action: onEnable) {
                    HStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "sparkles")
                            .font(Typography.UI.iconMd.weight(.medium))

                        Text("Enable \(biometricType.displayName)")
                            .font(Typography.UI.bodyBold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.Spacing.md)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.divineGold,
                                Color.burnishedGold
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
                    .shadow(AppTheme.Shadow.medium)
                }

                // Skip button
                Button(action: onSkip) {
                    Text("Maybe Later")
                        .font(Typography.UI.body)
                        .foregroundStyle(Color.secondaryText)
                }
                .padding(.vertical, AppTheme.Spacing.sm)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .background(Color.primaryBackground)
        .onAppear {
            withAnimation(AppTheme.Animation.contemplative) {
                isAnimating = true
            }
        }
    }

    // MARK: - Sacred Seal Icon
    private var sealIcon: some View {
        ZStack {
            // Outer decorative ring with gold gradient
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.illuminatedGold,
                            Color.divineGold,
                            Color.burnishedGold
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: AppTheme.Border.thick
                )
                .frame(width: 100, height: 100)
                .scaleEffect(isAnimating ? 1 : 0.9)
                .opacity(isAnimating ? 1 : 0.5)

            // Glow ring
            Circle()
                .fill(Color.Glow.indigoAmbient)
                .frame(width: 90, height: 90)
                .blur(radius: AppTheme.Blur.heavy)
                .scaleEffect(isAnimating ? 1.1 : 0.9)

            // Inner background
            Circle()
                .fill(Color.secondaryBackground)
                .frame(width: 80, height: 80)

            // Biometric icon
            Image(systemName: biometricType.systemImage)
                .font(.system(size: Typography.Scale.xxxl + 6, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.divineGold,
                            Color.burnishedGold
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(isAnimating ? 1 : 0.8)
                .opacity(isAnimating ? 1 : 0)
        }
        .animation(AppTheme.Animation.sacredSpring, value: isAnimating)
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

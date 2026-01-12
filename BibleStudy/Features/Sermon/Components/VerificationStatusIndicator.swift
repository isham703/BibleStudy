import SwiftUI

// MARK: - Verification Status Indicator
// Wax seal metaphor for verification status in illuminated manuscript aesthetic

struct VerificationStatusIndicator: View {
    let status: VerificationStatus
    @State private var shimmerPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        switch status {
        case .verified:
            // Gold wax seal with subtle glow
            Image(systemName: "checkmark.seal.fill")
                // swiftlint:disable:next hardcoded_font_system
                .font(Typography.Icon.xxs)
                .foregroundStyle(Color("AccentBronze"))
                // swiftlint:disable:next hardcoded_shadow_radius
                .shadow(color: Color("AccentBronze").opacity(Theme.Opacity.disabled), radius: 2)
                .accessibilityLabel("Verified cross-reference")

        case .partial:
            // Outline seal (not fully verified)
            Image(systemName: "checkmark.seal")
                // swiftlint:disable:next hardcoded_font_system
                .font(Typography.Icon.xxs)
                .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.overlay))
                .accessibilityLabel("Partially verified reference")

        case .unverified:
            // Ethereal sparkle (AI inspiration)
            // Respects Reduce Motion accessibility setting
            Image(systemName: "sparkle")
                // swiftlint:disable:next hardcoded_font_system
                .font(Typography.Icon.xxxs)
                .foregroundStyle(Color.appTextSecondary.opacity(Theme.Opacity.pressed))
                // swiftlint:disable:next hardcoded_opacity
                .opacity(reduceMotion ? 0.7 : (0.6 + Darwin.sin(shimmerPhase) * 0.2))
                .onAppear {
                    guard !reduceMotion else { return }
                    // swiftlint:disable:next hardcoded_animation_ease
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        shimmerPhase = .pi * 2
                    }
                }
                .accessibilityLabel("AI-suggested reference, not verified")

        case .unknown:
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview("Verification Indicators") {
    VStack(spacing: Theme.Spacing.xl) {
        HStack(spacing: Theme.Spacing.lg) {
            VStack {
                VerificationStatusIndicator(status: .verified)
                Text("Verified")
                    // swiftlint:disable:next hardcoded_swiftui_text_style
                    .font(.caption)
            }
            VStack {
                VerificationStatusIndicator(status: .partial)
                Text("Partial")
                    // swiftlint:disable:next hardcoded_swiftui_text_style
                    .font(.caption)
            }
            VStack {
                VerificationStatusIndicator(status: .unverified)
                Text("Unverified")
                    // swiftlint:disable:next hardcoded_swiftui_text_style
                    .font(.caption)
            }
            VStack {
                VerificationStatusIndicator(status: .unknown)
                Text("Unknown")
                    // swiftlint:disable:next hardcoded_swiftui_text_style
                    .font(.caption)
            }
        }
    }
    .padding()
    .background(Color("AppBackground"))
}

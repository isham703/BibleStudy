import SwiftUI

// MARK: - Ask FAB
// Floating Action Button for opening Ask modal
// Styled as a divine beacon with breathing glow animation

struct AskFAB: View {
    let action: () -> Void

    // MARK: - Animation State
    @State private var glowScale: CGFloat = 1.0
    @State private var isPressed = false

    // MARK: - Constants
    private let fabSize: CGFloat = 56
    private let iconSize: CGFloat = 24
    private let glowSize: CGFloat = 72

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        Button(action: {
            HapticService.shared.mediumTap()
            action()
        }) {
            ZStack {
                // Ambient glow ring (breathing animation)
                if !respectsReducedMotion {
                    Circle()
                        .fill(Color.divineGold.opacity(AppTheme.Opacity.medium))
                        .frame(width: glowSize, height: glowSize)
                        .blur(radius: AppTheme.Blur.medium)
                        .scaleEffect(glowScale)
                }

                // Main FAB circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.illuminatedGold,
                                Color.divineGold,
                                Color.burnishedGold
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: fabSize, height: fabSize)
                    .shadow(AppTheme.Shadow.indigoGlow)
                    .shadow(AppTheme.Shadow.medium)

                // Ask icon (Streamline asset)
                Image(AppIcons.TabBar.ask)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(FABButtonStyle())
        .scaleEffect(isPressed ? AppTheme.Scale.pressed : 1.0)
        .animation(AppTheme.Animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            startBreathingAnimation()
        }
        .accessibilityLabel("Ask AI")
        .accessibilityHint("Opens AI chat for Bible questions")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Breathing Animation

    private func startBreathingAnimation() {
        guard !respectsReducedMotion else { return }

        // Start with base scale
        glowScale = 1.0

        // Animate to expanded state
        withAnimation(AppTheme.Animation.breathingPulse) {
            glowScale = 1.08
        }
    }
}

// MARK: - FAB Button Style

private struct FABButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? 0.1 : 0)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground
            .ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                AskFAB {
                    print("FAB tapped")
                }
                .padding(AppTheme.Spacing.lg)
            }
        }
    }
}

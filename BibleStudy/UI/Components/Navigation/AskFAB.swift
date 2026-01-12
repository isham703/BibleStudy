import SwiftUI

// MARK: - Ask FAB
// Floating Action Button for opening Ask modal
// Styled as a divine beacon with breathing glow animation

struct AskFAB: View {
    @Environment(\.colorScheme) private var colorScheme
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
                        .fill(Color("AccentBronze").opacity(Theme.Opacity.focusStroke))
                        .frame(width: glowSize, height: glowSize)
                        .blur(radius: 8)
                        .scaleEffect(glowScale)
                }

                // Main FAB circle with gradient
                Circle()
                    .fill(Color("AccentBronze"))
                    .frame(width: fabSize, height: fabSize)

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
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(Theme.Animation.fade, value: isPressed)
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
        withAnimation(Theme.Animation.fade) {
            glowScale = 1.08
        }
    }
}

// MARK: - FAB Button Style

private struct FABButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? 0.1 : 0)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
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
                .padding(Theme.Spacing.lg)
            }
        }
    }
}

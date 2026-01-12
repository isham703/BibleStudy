import SwiftUI

// MARK: - Roman Background
// Unified background for the Roman/Stoic sanctuary experience
// Marble and stone aesthetic that responds to reading mode (Light/Dark)
// No time-awareness - timeless Roman monumentalism

struct RomanBackground: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var pulsePhase: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base surface - responds to theme
                baseLayer

                // Marble vignette - subtle depth
                marbleVignette(size: geometry.size)

                // Imperial glow - living purple radiance
                imperialGlow(size: geometry.size)

                // Laurel warmth - gold accent in corner
                laurelWarmth(size: geometry.size)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(Theme.Animation.fade) {
                pulsePhase = 1
            }
        }
    }

    // MARK: - Base Layer

    private var baseLayer: some View {
        Color.appBackground
    }

    // MARK: - Marble Vignette

    private func marbleVignette(size: CGSize) -> some View {
        // swiftlint:disable:next hardcoded_gradient_colors
        RadialGradient(
            colors: [
                Color.clear,
                vignetteTint.opacity(Theme.Opacity.subtle),
                vignetteTint.opacity(Theme.Opacity.subtle)
            ],
            center: .center,
            startRadius: size.width * 0.3,
            endRadius: size.width * 0.9
        )
    }

    private var vignetteTint: Color {
        switch appState.preferredTheme {
        case .light, .system:
            return Color.surfaceSlate
        case .dark:
            return Color("AppBackground")
        }
    }

    // MARK: - Imperial Glow

    private func imperialGlow(size: CGSize) -> some View {
        // swiftlint:disable:next hardcoded_gradient_colors
        RadialGradient(
            colors: [
                Color("AppAccentAction").opacity(0.06 + pulsePhase * 0.02),
                Color("AppAccentAction").opacity(Theme.Opacity.subtle),
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: min(size.width, size.height) * 0.8
        )
        // swiftlint:disable:next hardcoded_opacity
        .opacity(colorScheme == .dark ? 1.2 : 0.8)
    }

    // MARK: - Laurel Warmth

    private func laurelWarmth(size: CGSize) -> some View {
        // swiftlint:disable:next hardcoded_gradient_colors
        RadialGradient(
            colors: [
                Color("AccentBronze").opacity(Theme.Opacity.subtle),
                Color("AccentBronze").opacity(Theme.Opacity.subtle),
                Color.clear
            ],
            center: .topTrailing,
            startRadius: 0,
            endRadius: size.width * 0.5
        )
    }
}

// MARK: - Preview

#Preview("Roman Background - Light") {
    RomanBackground()
        .environment(AppState())
}

#Preview("Roman Background - Dark") {
    let appState = AppState()
    appState.preferredTheme = .dark
    return RomanBackground()
        .environment(appState)
        .preferredColorScheme(.dark)
}

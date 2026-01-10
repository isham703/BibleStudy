import SwiftUI

// MARK: - Roman Background
// Unified background for the Roman/Stoic sanctuary experience
// Marble and stone aesthetic that responds to reading mode (Light/Dark/Sepia/OLED)
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
        Colors.Surface.background(for: appState.preferredTheme)
    }

    // MARK: - Marble Vignette

    private func marbleVignette(size: CGSize) -> some View {
        // swiftlint:disable:next hardcoded_gradient_colors
        RadialGradient(
            colors: [
                Color.clear,
                vignetteTint.opacity(Theme.Opacity.faint),
                vignetteTint.opacity(Theme.Opacity.faint)
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
            return Color.surfaceInk
        case .sepia:
            return Color.brownStone
        case .oled:
            return Color.surfaceInk
        }
    }

    // MARK: - Imperial Glow

    private func imperialGlow(size: CGSize) -> some View {
        // swiftlint:disable:next hardcoded_gradient_colors
        RadialGradient(
            colors: [
                Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(0.06 + pulsePhase * 0.02),
                Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint),
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
        let accentSeal = Colors.Semantic.accentSeal(for: appState.preferredTheme)
        // swiftlint:disable:next hardcoded_gradient_colors
        return RadialGradient(
            colors: [
                accentSeal.opacity(Theme.Opacity.faint),
                accentSeal.opacity(Theme.Opacity.faint),
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

#Preview("Roman Background - Sepia") {
    let appState = AppState()
    appState.preferredTheme = .sepia
    return RomanBackground()
        .environment(appState)
}

import SwiftUI

// MARK: - Illuminated Gradients
// Gradient backgrounds and glow effects for the scholarly manuscript theme
// Migrated from gold to Scholar Indigo palette

enum IlluminatedGradients {

    // MARK: - Background Gradients

    /// Subtle vellum gradient - light mode reading background
    /// Mimics the slight color variation of aged parchment
    static var vellumGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.freshVellum,
                Color.GradientStops.vellumBottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Aged parchment gradient - sepia theme background
    /// Warmer, more aged appearance
    static var parchmentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.agedParchment,
                Color.GradientStops.parchmentBottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Candlelit chapel gradient - dark mode background
    /// Subtle warmth as if lit by candlelight
    static var chapelGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.candlelitStone,
                Color.GradientStops.chapelBottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// OLED gradient - pure black with subtle warm tint at edges
    static var oledGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.oledBlack,
                Color.GradientStops.oledBottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Accent Glow Gradients (Scholar Indigo)

    /// Radial indigo glow for highlights and celebrations
    static var indigoGlow: RadialGradient {
        RadialGradient(
            colors: [
                Color.scholarIndigo.opacity(0.4),
                Color.scholarIndigo.opacity(0.1),
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 100
        )
    }

    /// Legacy alias for goldGlow
    @available(*, deprecated, renamed: "indigoGlow")
    static var goldGlow: RadialGradient { indigoGlow }

    /// Soft ambient indigo for subtle background coolness
    static var ambientIndigo: RadialGradient {
        RadialGradient(
            colors: [
                Color.scholarIndigoLight.opacity(0.15),
                Color.scholarIndigoSubtle.opacity(0.05),
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 200
        )
    }

    /// Legacy alias for ambientGold
    @available(*, deprecated, renamed: "ambientIndigo")
    static var ambientGold: RadialGradient { ambientIndigo }

    /// Subtle light rays effect - top-down illumination
    static var subtleLight: LinearGradient {
        LinearGradient(
            colors: [
                Color.scholarIndigoSubtle.opacity(AppTheme.Opacity.medium),
                Color.scholarIndigoSubtle.opacity(AppTheme.Opacity.subtle),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .center
        )
    }

    /// Legacy alias for divineLight
    @available(*, deprecated, renamed: "subtleLight")
    static var divineLight: LinearGradient { subtleLight }

    // MARK: - Card & Surface Gradients

    /// Elevated card gradient - subtle depth effect
    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.05),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Selected/highlighted state gradient
    static var selectedGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.scholarIndigo.opacity(0.15),
                Color.scholarIndigo.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Border Gradients

    /// Indigo border gradient for premium elements
    static var indigoBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color.scholarIndigoLight,
                Color.scholarIndigo,
                Color.scholarIndigoPressed
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Legacy alias for goldBorder
    @available(*, deprecated, renamed: "indigoBorder")
    static var goldBorder: LinearGradient { indigoBorder }

    /// Subtle shimmer border (indigo-based)
    static var shimmerBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color.scholarIndigoSubtle.opacity(0.6),
                Color.scholarIndigo.opacity(0.8),
                Color.scholarIndigoSubtle.opacity(0.6)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - View Modifiers for Gradients

extension View {
    /// Apply vellum background gradient
    func vellumBackground() -> some View {
        self.background(IlluminatedGradients.vellumGradient)
    }

    /// Apply parchment background gradient
    func parchmentBackground() -> some View {
        self.background(IlluminatedGradients.parchmentGradient)
    }

    /// Apply chapel (dark mode) background gradient
    func chapelBackground() -> some View {
        self.background(IlluminatedGradients.chapelGradient)
    }

    /// Apply indigo glow effect behind content
    func indigoGlowBackground(intensity: Double = 1.0) -> some View {
        self.background(
            IlluminatedGradients.indigoGlow
                .opacity(intensity)
        )
    }

    /// Legacy alias for goldGlowBackground
    @available(*, deprecated, renamed: "indigoGlowBackground")
    func goldGlowBackground(intensity: Double = 1.0) -> some View {
        indigoGlowBackground(intensity: intensity)
    }

    /// Apply subtle light overlay from top
    func subtleLightOverlay() -> some View {
        self.overlay(
            IlluminatedGradients.subtleLight
                .allowsHitTesting(false)
        )
    }

    /// Legacy alias for divineLightOverlay
    @available(*, deprecated, renamed: "subtleLightOverlay")
    func divineLightOverlay() -> some View {
        subtleLightOverlay()
    }

    /// Apply indigo border gradient
    func indigoBorderGradient(lineWidth: CGFloat = 1) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(IlluminatedGradients.indigoBorder, lineWidth: lineWidth)
        )
    }

    /// Legacy alias for goldBorderGradient
    @available(*, deprecated, renamed: "indigoBorderGradient")
    func goldBorderGradient(lineWidth: CGFloat = 1) -> some View {
        indigoBorderGradient(lineWidth: lineWidth)
    }

    /// Apply scholarly card style with subtle indigo accent
    func scholarCardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .fill(Color.surfaceBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                            .fill(IlluminatedGradients.cardGradient)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
            .shadow(AppTheme.Shadow.small)
    }

    /// Legacy alias for illuminatedCardStyle
    @available(*, deprecated, renamed: "scholarCardStyle")
    func illuminatedCardStyle() -> some View {
        scholarCardStyle()
    }

    /// Apply selected/highlighted state with indigo tint
    func scholarSelectedStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(IlluminatedGradients.selectedGradient)
            )
    }

    /// Legacy alias for illuminatedSelectedStyle
    @available(*, deprecated, renamed: "scholarSelectedStyle")
    func illuminatedSelectedStyle() -> some View {
        scholarSelectedStyle()
    }
}

// MARK: - Animated Gradient Views

/// Animated shimmer effect for indigo elements
struct IndigoShimmerView: View {
    @State private var animating = false

    var body: some View {
        LinearGradient(
            colors: [
                Color.scholarIndigoSubtle.opacity(0.3),
                Color.scholarIndigoLight.opacity(0.6),
                Color.scholarIndigoSubtle.opacity(0.3)
            ],
            startPoint: animating ? .leading : .trailing,
            endPoint: animating ? .trailing : .leading
        )
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                animating = true
            }
        }
    }
}

/// Legacy typealias for GoldShimmerView
@available(*, deprecated, renamed: "IndigoShimmerView")
typealias GoldShimmerView = IndigoShimmerView

/// Ambient glow that pulses subtly
struct AmbientGlowView: View {
    let color: Color
    let intensity: Double

    @State private var pulsing = false

    init(color: Color = Color.scholarIndigo, intensity: Double = 0.3) {
        self.color = color
        self.intensity = intensity
    }

    var body: some View {
        RadialGradient(
            colors: [
                color.opacity(pulsing ? intensity : intensity * 0.6),
                color.opacity(pulsing ? intensity * 0.3 : intensity * 0.1),
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 150
        )
        .onAppear {
            guard !AppTheme.Animation.isReduceMotionEnabled else { return }
            withAnimation(
                .easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
            ) {
                pulsing = true
            }
        }
    }
}

// MARK: - Theme Background Provider

/// Provides the appropriate background gradient based on theme
struct ThemeBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    let theme: AppThemeMode

    var body: some View {
        switch theme {
        case .system:
            if colorScheme == .dark {
                IlluminatedGradients.chapelGradient
            } else {
                IlluminatedGradients.vellumGradient
            }
        case .light:
            IlluminatedGradients.vellumGradient
        case .dark:
            IlluminatedGradients.chapelGradient
        case .sepia:
            IlluminatedGradients.parchmentGradient
        case .oled:
            IlluminatedGradients.oledGradient
        }
    }
}

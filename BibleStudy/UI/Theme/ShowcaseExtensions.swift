import SwiftUI

// MARK: - Showcase Extensions
// Reusable theme extensions used across the app's showcase and home variants
// Includes Typography, Animation, View modifiers, and utility components

extension Typography {
    /// Body text for settings and UI elements
    static var body: Font { UI.body }

    /// Caption text for secondary information
    static var caption: Font { UI.caption1 }

    /// Footnote text for tertiary information
    static var footnote: Font { UI.footnote }

    /// Monospaced body text for values and codes
    static var monospacedBody: Font { Code.inline }
}

// MARK: - Showcase Color Tokens
// Additional color utilities for the showcase feature

extension Color {
    /// Create color from hex string (convenience for showcase designs)
    /// Note: This may already exist in the codebase - kept here for showcase isolation
    static func hex(_ hex: String) -> Color {
        Color(hex: hex)
    }
}

// MARK: - Showcase Animation Extensions

extension Animation {
    /// Standard showcase transition
    static var showcaseSpring: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }

    /// Quick feedback animation
    static var showcaseQuick: Animation {
        .easeInOut(duration: 0.15)
    }

    /// Slow, reverent transition
    static var showcaseReverent: Animation {
        .easeInOut(duration: 0.6)
    }
}

// MARK: - Showcase View Modifiers

extension View {
    /// Apply showcase card styling
    func showcaseCard(
        cornerRadius: CGFloat = AppTheme.CornerRadius.lg,
        borderColor: Color = .scholarAccent,
        borderOpacity: Double = 0.15
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(hex: "141210"))
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        borderColor.opacity(borderOpacity),
                        lineWidth: 0.5
                    )
            }
    }

    /// Apply gold glow shadow effect
    func goldGlow(radius: CGFloat = 20, opacity: Double = 0.1) -> some View {
        self.shadow(color: Color.scholarAccent.opacity(opacity), radius: radius, y: 8)
    }

    /// Apply pressed scale effect
    func pressedScale(_ isPressed: Bool) -> some View {
        self.scaleEffect(isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Showcase Constants

enum ShowcaseConstants {
    /// Standard content padding
    static let contentPadding: CGFloat = AppTheme.Spacing.lg

    /// Card spacing
    static let cardSpacing: CGFloat = AppTheme.Spacing.md

    /// Section spacing
    static let sectionSpacing: CGFloat = AppTheme.Spacing.xxl

    /// Header height for parallax calculations
    static let headerHeight: CGFloat = 320

    /// Quick nav bar height
    static let quickNavHeight: CGFloat = 70
}

// MARK: - Showcase Background Colors

enum ShowcaseBackground {
    /// Main dark background
    static let primary = Color(hex: "0A0908")

    /// Elevated card background
    static let elevated = Color(hex: "141210")

    /// Surface background with slight warmth
    static let surface = Color(hex: "1A1816")

    /// Subtle overlay for depth
    static let overlay = Color.white.opacity(0.02)
}

// MARK: - Reusable Showcase Components

/// A simple ornamental line divider
struct ShowcaseDivider: View {
    var color: Color = .scholarAccent
    var opacity: Double = 0.2
    var height: CGFloat = 1
    var leadingPadding: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(color.opacity(opacity))
            .frame(height: height)
            .padding(.leading, leadingPadding)
    }
}

/// Animated gold shimmer overlay
struct GoldShimmerOverlay: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.scholarAccent.opacity(0.1),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 2)
            .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
        }
        .onAppear {
            withAnimation(
                .linear(duration: 2)
                .repeatForever(autoreverses: false)
            ) {
                phase = 1
            }
        }
    }
}

/// Ambient background glow effect
struct AmbientGlow: View {
    let color: Color
    var radius: CGFloat = 400
    var opacity: Double = 0.08

    var body: some View {
        RadialGradient(
            colors: [
                color.opacity(opacity),
                Color.clear
            ],
            center: .center,
            startRadius: 50,
            endRadius: radius
        )
    }
}

// MARK: - Preview Support

#Preview("Showcase Components") {
    ZStack {
        ShowcaseBackground.primary
            .ignoresSafeArea()

        VStack(spacing: 20) {
            Text("Body Text")
                .font(Typography.body)
                .foregroundStyle(Color.primaryText)

            Text("Caption Text")
                .font(Typography.caption)
                .foregroundStyle(Color.secondaryText)

            Text("Footnote Text")
                .font(Typography.footnote)
                .foregroundStyle(Color.tertiaryText)

            ShowcaseDivider()
                .frame(width: 200)

            RoundedRectangle(cornerRadius: 12)
                .fill(ShowcaseBackground.elevated)
                .frame(width: 200, height: 100)
                .showcaseCard()
                .goldGlow()
        }
    }
    .preferredColorScheme(.dark)
}

import SwiftUI

// MARK: - Session Restoration View
// "Manuscript Awakening" - Shows while restoring auth session
// Creates a "manuscript coming to life" effect rather than generic shimmer

struct SessionRestorationView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            // Background
            Color.primaryBackground
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.xxl) {
                Spacer()

                // App icon area - gold circle pulse
                pulsingIconArea

                // "Text lines" skeleton - ink spreading effect
                VStack(spacing: AppTheme.Spacing.sm) {
                    InkSpreadLine(width: 200, delay: 0)
                    InkSpreadLine(width: 160, delay: 0.1)
                    InkSpreadLine(width: 180, delay: 0.2)
                }

                // Subtle message
                Text("Preparing your space...")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText)
                    .opacity(phase)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(AppTheme.Animation.contemplative) {
                phase = 1
            }
        }
    }

    private var pulsingIconArea: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.illuminatedGold.opacity(AppTheme.Opacity.medium),
                            Color.divineGold.opacity(AppTheme.Opacity.subtle),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(1 + phase * 0.1)
                .opacity(AppTheme.Opacity.strong + phase * 0.4)

            // Icon
            Image(systemName: "book.closed.fill")
                .font(.system(size: Typography.Scale.xxxl - 2, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.illuminatedGold,
                            Color.divineGold
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(AppTheme.Opacity.overlay + phase * 0.3)
        }
    }
}

// MARK: - Ink Spread Line
// Simulates ink spreading across parchment
struct InkSpreadLine: View {
    let width: CGFloat
    let delay: Double
    @State private var spread: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xs)
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color.agedInk.opacity(AppTheme.Opacity.medium), location: 0),
                        .init(color: Color.agedInk.opacity(AppTheme.Opacity.subtle), location: spread),
                        .init(color: .clear, location: min(1, spread + 0.1))
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: 8)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(AppTheme.Animation.unfurl) {
                        spread = 1
                    }
                }
            }
    }
}

// MARK: - Preview
#Preview {
    SessionRestorationView()
}

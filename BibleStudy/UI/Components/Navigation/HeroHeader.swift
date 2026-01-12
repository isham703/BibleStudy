import SwiftUI

// MARK: - Hero Header
// Full-bleed hero image with curved bottom edge and back button overlay.
// Handles safe area insets automatically, including Dynamic Island devices.
// Includes overscroll stretch behavior - image expands when user pulls down.
//
// Usage:
//   HeroHeader(imageName: "PrayerHero")
//
//   // With custom back action:
//   HeroHeader(imageName: "StoryHero") {
//       customBackAction()
//   }

struct HeroHeader: View {
    let imageName: String
    var onBack: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var topSafeArea: CGFloat = 0

    // MARK: - Constants

    private let heroHeight: CGFloat = 280
    private let curveHeight: CGFloat = 48
    private let warmGradientHeight: CGFloat = 140  // Extended for softer atmospheric falloff
    private let dynamicIslandFallback: CGFloat = 59

    var body: some View {
        GeometryReader { geometry in
            // Calculate overscroll stretch - when user pulls down, image expands
            let minY = geometry.frame(in: .global).minY
            let overscroll = max(0, minY)

            ZStack(alignment: .bottom) {
                // Hero image - extends under status bar + stretches on overscroll
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width)
                    .frame(minHeight: heroHeight + effectiveTopInset + overscroll)
                    .clipped()
                    .offset(y: -effectiveTopInset - overscroll)

                // Dark mode: atmospheric gradient bridge - light fading into warmth
                // Soft falloff: clear → warm haze → surface (not a flat mask)
                if colorScheme == .dark {
                    VStack {
                        Spacer()
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: Color.warmCharcoal.opacity(0.3), location: 0.4),
                                .init(color: Color.warmCharcoal.opacity(0.7), location: 0.7),
                                .init(color: Color.warmCharcoal, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: warmGradientHeight)
                    }
                    .offset(y: -effectiveTopInset)
                }

                // Curved bottom edge - single clean shape transition
                // Dark mode: warm charcoal for candlelit feel
                CurvedEdge()
                    .fill(colorScheme == .dark ? Color.warmCharcoal : Color.appBackground)
                    .frame(height: curveHeight)
                    .offset(y: -effectiveTopInset)

                // Back button overlay - offset to stay fixed during overscroll
                backButtonOverlay(overscroll: overscroll)
            }
        }
        .frame(height: heroHeight + effectiveTopInset)
        .ignoresSafeArea(edges: .top)
        .background(safeAreaReader)
    }

    // MARK: - Computed Properties

    private var effectiveTopInset: CGFloat {
        topSafeArea > 0 ? topSafeArea : dynamicIslandFallback
    }

    // MARK: - Back Button

    private func backButtonOverlay(overscroll: CGFloat) -> some View {
        VStack {
            HStack {
                Button {
                    HapticService.shared.lightTap()
                    if let onBack = onBack {
                        onBack()
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.black.opacity(0.3))
                        )
                }
                .accessibilityLabel("Go back")

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, effectiveTopInset + Theme.Spacing.xs)

            Spacer()
        }
        // Counteract overscroll to keep button fixed on screen
        .offset(y: -overscroll)
    }

    // MARK: - Safe Area Reader

    private var safeAreaReader: some View {
        GeometryReader { proxy in
            Color.clear.onAppear {
                topSafeArea = proxy.safeAreaInsets.top
            }
        }
    }
}

// MARK: - Curved Edge Shape

private struct CurvedEdge: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Start at top-left corner
        path.move(to: CGPoint(x: 0, y: 0))

        // Curve downward (concave) from left to right
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: 0),
            control: CGPoint(x: rect.width / 2, y: rect.height)
        )

        // Close the shape along bottom and left
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview("Hero Header") {
    NavigationStack {
        ScrollView {
            VStack(spacing: 0) {
                HeroHeader(imageName: "PrayerHero")

                VStack(spacing: Theme.Spacing.lg) {
                    Text("Content Below Hero")
                        .font(Typography.Scripture.title)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text("The hero header handles safe area and provides a curved transition.")
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .multilineTextAlignment(.center)
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.appBackground)
        .navigationBarHidden(true)
    }
}

#Preview("Hero Header - Custom Action") {
    NavigationStack {
        VStack(spacing: 0) {
            HeroHeader(imageName: "PrayerHero") {
                print("Custom back action")
            }

            Spacer()
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.appBackground)
        .navigationBarHidden(true)
    }
}

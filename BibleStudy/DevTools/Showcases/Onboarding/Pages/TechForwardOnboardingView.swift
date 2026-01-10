import SwiftUI

// MARK: - Tech Forward Onboarding View
// Bold gradients, AI emphasis, animated particles
// Modern & Premium with futuristic technology aesthetic

struct TechForwardOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var animateParticles = false
    @State private var showContent = false
    @State private var pulseGlow = false

    private let pages = TechForwardPage.allPages

    var body: some View {
        ZStack {
            // Animated gradient background
            animatedBackground

            // Floating particles
            particleField

            // Main content
            VStack(spacing: 0) {
                // Skip button
                skipButton

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageContent(for: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom section
                bottomSection
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(Theme.Animation.slowFade) {
                animateParticles = true
                showContent = true
            }
            withAnimation(Theme.Animation.fade) {
                pulseGlow = true
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Animated Background
    private var animatedBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "0a0a1a"), location: 0),
                    .init(color: Color(hex: "1a1a3a"), location: 0.4),
                    .init(color: Color.accentIndigo.opacity(Theme.Opacity.subtle), location: 0.7),
                    .init(color: Color(hex: "0a0a1a"), location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Radial glow at center
            RadialGradient(
                colors: [
                    Color.accentIndigo.opacity(pulseGlow ? 0.4 : 0.2),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .animation(Theme.Animation.fade, value: pulseGlow)

            // Top accent glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "8B8CFC").opacity(Theme.Opacity.subtle),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 200)
                .offset(y: -300)
                .blur(radius: 60)
        }
    }

    // MARK: - Particle Field
    private var particleField: some View {
        GeometryReader { geometry in
            ForEach(0..<30, id: \.self) { index in
                ParticleView(
                    index: index,
                    containerSize: geometry.size,
                    isAnimating: animateParticles
                )
            }
        }
    }

    // MARK: - Skip Button
    private var skipButton: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(Typography.Icon.base)
                    .foregroundStyle(.white.opacity(Theme.Opacity.tertiary))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Button {
                // Skip to sign up
            } label: {
                Text("Skip")
                    .font(Typography.Command.callout)
                    .foregroundStyle(.white.opacity(Theme.Opacity.heavy))
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, 60)
    }

    // MARK: - Page Content
    @ViewBuilder
    private func pageContent(for page: TechForwardPage) -> some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Spacer()

            // Icon with glow effect
            ZStack {
                // Glow rings
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(
                            Color.accentIndigo.opacity(0.3 - Double(ring) * 0.1),
                            lineWidth: 1
                        )
                        .frame(
                            width: 100 + CGFloat(ring * 30),
                            height: 100 + CGFloat(ring * 30)
                        )
                        .scaleEffect(pulseGlow ? 1.1 : 1.0)
                        .animation(
                            Theme.Animation.fade.delay(Double(ring) * 0.2),
                            value: pulseGlow
                        )
                }

                // Icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentIndigo,
                                Color.accentIndigoLight
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.accentIndigo.opacity(Theme.Opacity.medium), radius: 20)

                // Icon
                Image(systemName: page.iconName)
                    .font(Typography.Icon.xxl)
                    .foregroundStyle(.white)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            // Text content
            VStack(spacing: Theme.Spacing.lg) {
                Text(page.title)
                    .font(Typography.Scripture.display)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(Typography.Command.title3)
                    .foregroundStyle(Color(hex: "8B8CFC"))
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(Typography.Command.body)
                    .foregroundStyle(.white.opacity(Theme.Opacity.heavy))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)

            // Feature chips
            if !page.features.isEmpty {
                featureChips(page.features)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    // MARK: - Feature Chips
    private func featureChips(_ features: [String]) -> some View {
        FlowLayout(spacing: Theme.Spacing.sm) {
            ForEach(features, id: \.self) { feature in
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "checkmark")
                        .font(Typography.Icon.xxs.weight(.bold))

                    Text(feature)
                        .font(Typography.Command.caption)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(Theme.Opacity.overlay))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(Theme.Opacity.light), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    // MARK: - Bottom Section
    private var bottomSection: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Page indicator
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.accentIndigo : Color.white.opacity(Theme.Opacity.subtle))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(Theme.Animation.settle, value: currentPage)
                }
            }

            // Action buttons
            VStack(spacing: Theme.Spacing.md) {
                // Primary CTA
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(Theme.Animation.settle) {
                            currentPage += 1
                        }
                    }
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                            .font(Typography.Command.headline)

                        Image(systemName: "arrow.right")
                            .font(Typography.Command.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.accentIndigo, Color.accentIndigoLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                    .shadow(color: Color.accentIndigo.opacity(Theme.Opacity.lightMedium), radius: 15, y: 5)
                }

                // Secondary option
                Button {
                    // Sign in action
                } label: {
                    Text("Already have an account? Sign In")
                        .font(Typography.Command.callout)
                        .foregroundStyle(.white.opacity(Theme.Opacity.heavy))
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
        .padding(.bottom, 50)
    }
}

// MARK: - Tech Forward Page Model
struct TechForwardPage: Identifiable {
    let id = UUID()
    let iconName: String
    let title: String
    let subtitle: String
    let description: String
    let features: [String]

    static let allPages: [TechForwardPage] = [
        TechForwardPage(
            iconName: "brain.head.profile",
            title: "AI-Powered\nBible Study",
            subtitle: "Intelligent Scripture Analysis",
            description: "Experience Scripture like never before with AI that understands context, history, and theology.",
            features: ["Deep Analysis", "Historical Context", "Cross-References"]
        ),
        TechForwardPage(
            iconName: "text.book.closed.fill",
            title: "Read with\nUnderstanding",
            subtitle: "Multiple Translations & Commentary",
            description: "Access scholarly commentary, original language insights, and compare translations instantly.",
            features: ["Greek & Hebrew", "Expert Commentary", "Smart Search"]
        ),
        TechForwardPage(
            iconName: "sparkles",
            title: "Your Personal\nScholarly Assistant",
            subtitle: "Ask Anything, Anytime",
            description: "Get instant, thoughtful answers to your questions about any passage, theme, or topic.",
            features: ["Instant Answers", "Personalized Learning", "Study Plans"]
        )
    ]
}

// MARK: - Particle View
struct ParticleView: View {
    let index: Int
    let containerSize: CGSize
    let isAnimating: Bool

    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 0

    private var particleSize: CGFloat {
        CGFloat.random(in: 2...6)
    }

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: particleSize, height: particleSize)
            .position(position)
            .opacity(opacity)
            .onAppear {
                position = CGPoint(
                    x: CGFloat.random(in: 0...containerSize.width),
                    y: CGFloat.random(in: 0...containerSize.height)
                )

                withAnimation(
                    .easeInOut(duration: Double.random(in: 2...4))
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0...2))
                ) {
                    opacity = Double.random(in: 0.1...0.4)
                }

                withAnimation(
                    .easeInOut(duration: Double.random(in: 8...15))
                    .repeatForever(autoreverses: true)
                ) {
                    position = CGPoint(
                        x: CGFloat.random(in: 0...containerSize.width),
                        y: CGFloat.random(in: 0...containerSize.height)
                    )
                }
            }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            ), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Preview
#Preview {
    TechForwardOnboardingView()
}

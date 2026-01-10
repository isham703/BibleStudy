import SwiftUI

// MARK: - Onboarding Showcase Directory
// Internal design directory for viewing sign-up/onboarding page variations
// Team members can preview different styles before deciding on the final design

struct OnboardingShowcaseDirectory: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Deep dark background
                Color.showcaseBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Header Section
                        headerSection

                        // Page Variations
                        LazyVStack(spacing: Theme.Spacing.lg) {
                            ForEach(OnboardingVariant.allCases) { variant in
                                NavigationLink(destination: variant.destinationView) {
                                    OnboardingVariantCard(variant: variant)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)

                        // Footer info
                        footerSection
                    }
                    .padding(.vertical, Theme.Spacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Design Directory")
                        .font(Typography.Command.headline)
                        .foregroundStyle(Color.showcasePrimaryText)
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(Typography.Icon.lg)
                            .foregroundStyle(Color.showcaseSecondaryText)
                    }
                }
            }
            .toolbarBackground(Color.showcaseBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentIndigo, Color(hex: "8B8CFC")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                Image(systemName: "rectangle.stack.fill")
                    .font(Typography.Icon.xl)
                    .foregroundStyle(.white)
            }

            Text("Sign Up / Onboarding")
                .font(Typography.Scripture.title)
                .foregroundStyle(Color.showcasePrimaryText)

            Text("Preview different page styles")
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color.showcaseSecondaryText)
        }
        .padding(.top, Theme.Spacing.lg)
    }

    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Divider()
                .background(Color.showcaseTertiaryText.opacity(Theme.Opacity.subtle))
                .padding(.horizontal, Theme.Spacing.xxl)

            Text("\(OnboardingVariant.allCases.count) variations available")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.showcaseTertiaryText)

            Text("Tap a card to preview the full page")
                .font(Typography.Command.meta)
                .foregroundStyle(Color.showcaseTertiaryText.opacity(Theme.Opacity.heavy))
        }
        .padding(.top, Theme.Spacing.xl)
        .padding(.bottom, Theme.Spacing.xxl)
    }
}

// MARK: - Onboarding Variant Enum
enum OnboardingVariant: String, CaseIterable, Identifiable {
    case techForward = "tech_forward"
    case elegantMinimal = "elegant_minimal"
    case immersiveCards = "immersive_cards"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .techForward:
            return "Tech Forward"
        case .elegantMinimal:
            return "Elegant Minimal"
        case .immersiveCards:
            return "Immersive Cards"
        }
    }

    var subtitle: String {
        switch self {
        case .techForward:
            return "Bold gradients & AI emphasis"
        case .elegantMinimal:
            return "Clean typography-focused"
        case .immersiveCards:
            return "Feature cards with depth"
        }
    }

    var description: String {
        switch self {
        case .techForward:
            return "Dynamic gradients, animated particles, and a futuristic aesthetic that emphasizes AI-powered features."
        case .elegantMinimal:
            return "Refined whitespace, premium typography, and understated elegance that lets content breathe."
        case .immersiveCards:
            return "Interactive feature cards with glass morphism and micro-animations for an engaging experience."
        }
    }

    var iconName: String {
        switch self {
        case .techForward:
            return "sparkles"
        case .elegantMinimal:
            return "textformat"
        case .immersiveCards:
            return "square.stack.3d.up.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .techForward:
            return Color.accentIndigo
        case .elegantMinimal:
            return Color.showcasePrimaryText
        case .immersiveCards:
            return Color.vibrantBlue
        }
    }

    var previewGradient: LinearGradient {
        switch self {
        case .techForward:
            return LinearGradient(
                colors: [Color.accentIndigo.opacity(Theme.Opacity.pressed), Color(hex: "4338CA")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .elegantMinimal:
            return LinearGradient(
                colors: [Color.showcaseSurface, Color.showcaseCard],
                startPoint: .top,
                endPoint: .bottom
            )
        case .immersiveCards:
            return LinearGradient(
                colors: [Color.vibrantBlue.opacity(Theme.Opacity.tertiary), Color.cinematicTeal.opacity(Theme.Opacity.lightMedium)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    @ViewBuilder
    var destinationView: some View {
        switch self {
        case .techForward:
            TechForwardOnboardingView()
        case .elegantMinimal:
            ElegantMinimalOnboardingView()
        case .immersiveCards:
            ImmersiveCardsOnboardingView()
        }
    }
}

// MARK: - Variant Card
struct OnboardingVariantCard: View {
    let variant: OnboardingVariant
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Preview Area
            ZStack {
                // Background gradient
                variant.previewGradient

                // Decorative elements based on variant
                decorativeOverlay

                // Icon
                Image(systemName: variant.iconName)
                    .font(Typography.Icon.hero.weight(.light))
                    .foregroundStyle(.white.opacity(Theme.Opacity.high))
            }
            .frame(height: 140)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: Theme.Radius.card,
                    topTrailingRadius: Theme.Radius.card
                )
            )

            // Content Area
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text(variant.title)
                        .font(Typography.Command.headline)
                        .foregroundStyle(Color.showcasePrimaryText)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(Typography.Command.caption.weight(.semibold))
                        .foregroundStyle(Color.showcaseTertiaryText)
                }

                Text(variant.subtitle)
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(variant.accentColor)

                Text(variant.description)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.showcaseSecondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(Theme.Spacing.lg)
            .background(Color.showcaseCard)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color.showcaseTertiaryText.opacity(Theme.Opacity.light), lineWidth: 1)
        )
        .shadow(color: .black.opacity(Theme.Opacity.subtle), radius: 10, y: 5)
    }

    @ViewBuilder
    private var decorativeOverlay: some View {
        switch variant {
        case .techForward:
            // Animated particles effect (static for preview)
            GeometryReader { geo in
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(.white.opacity(Theme.Opacity.subtle))
                        .frame(width: CGFloat.random(in: 4...12))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height)
                        )
                }
            }

        case .elegantMinimal:
            // Clean lines
            VStack(spacing: Theme.Spacing.lg) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: Theme.Radius.xs)
                        .fill(.white.opacity(Theme.Opacity.divider))
                        .frame(width: 80, height: 4)
                }
            }

        case .immersiveCards:
            // Stacked cards preview
            HStack(spacing: -20) {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(.white.opacity(0.15 + Double(index) * 0.1))
                        .frame(width: 50, height: 70)
                        .rotationEffect(.degrees(Double(index - 1) * 8))
                }
            }
        }
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    OnboardingShowcaseDirectory()
}

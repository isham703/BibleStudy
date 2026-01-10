import SwiftUI

// MARK: - Stoic Showcase Card
// Card component for the home page showcase directory
// Design: Dark, minimal with subtle warm accents

struct StoicShowcaseCard<Destination: View>: View {
    let variant: HomePageVariant
    let destination: () -> Destination

    @State private var isPressed = false

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            cardContent
        }
        .buttonStyle(StoicCardButtonStyle())
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Preview gradient area
            previewArea
                .frame(height: 120)

            // Content area
            contentArea
                .padding(Theme.Spacing.lg)
        }
        .background(Color.showcaseCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            variant.accentColor.opacity(Theme.Opacity.subtle),
                            variant.accentColor.opacity(Theme.Opacity.overlay)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var previewArea: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: variant.previewGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Accent glow
            variant.accentColor
                .opacity(Theme.Opacity.divider)
                .blur(radius: 30)
                .offset(y: 20)

            // Icon
            Image(systemName: variant.icon)
                .font(Typography.Icon.hero.weight(.light))
                .foregroundStyle(variant.accentColor.opacity(Theme.Opacity.tertiary))
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: Theme.Radius.card,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: Theme.Radius.card
            )
        )
    }

    private var contentArea: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Title
            Text(variant.displayName)
                .font(.custom("CormorantGaramond-SemiBold", size: 20))
                .foregroundStyle(Color.showcasePrimaryText)

            // Subtitle
            Text(variant.subtitle)
                .font(Typography.Command.meta)
                .foregroundStyle(Color.showcaseSecondaryText)

            // Tags
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(variant.tags, id: \.self) { tag in
                    Text(tag.uppercased())
                        .font(Typography.Icon.xxxs)
                        .tracking(1.2)
                        .foregroundStyle(variant.accentColor.opacity(Theme.Opacity.pressed))
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(
                            variant.accentColor.opacity(Theme.Opacity.overlay)
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(.top, Theme.Spacing.xs)
        }
    }
}

// MARK: - Button Style

struct StoicCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(HomePageVariant.allCases) { variant in
                    StoicShowcaseCard(variant: variant) {
                        Text(variant.displayName)
                    }
                }
            }
            .padding()
        }
        .background(Color.showcaseBackground)
    }
    .preferredColorScheme(.dark)
}

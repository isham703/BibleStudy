import SwiftUI

// MARK: - Showcase Reader Card
// Dark glass card for the reader showcase directory list

struct ShowcaseReaderCard<Destination: View>: View {
    let variant: ReaderVariant
    let destination: () -> Destination

    @State private var isPressed = false

    init(variant: ReaderVariant, @ViewBuilder destination: @escaping () -> Destination) {
        self.variant = variant
        self.destination = destination
    }

    var body: some View {
        NavigationLink(destination: destination()) {
            cardContent
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .brightness(isPressed ? 0.05 : 0)
        .animation(Theme.Animation.settle, value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
            if pressing {
                HomeShowcaseHaptics.cardPress()
            }
        }, perform: {})
    }

    // MARK: - Card Content

    private var cardContent: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Icon
            iconView

            // Text content
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Title
                Text(variant.displayName)
                    .font(Typography.Icon.base.weight(.semibold))
                    .foregroundStyle(Color.showcasePrimaryText)

                // Subtitle
                Text(variant.subtitle)
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color.showcaseSecondaryText)

                // Reading mode badge
                readingModeBadge
                    .padding(.top, 2)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(Typography.Icon.sm)
                .foregroundStyle(Color.showcaseTertiaryText)
        }
        .padding(Theme.Spacing.lg)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(
            color: variant.accentColor.opacity(isPressed ? 0.3 : 0.15),
            radius: isPressed ? 8 : 16,
            y: isPressed ? 2 : 8
        )
    }

    // MARK: - Icon View

    private var iconView: some View {
        ZStack {
            // Glow background
            Circle()
                .fill(variant.accentColor.opacity(Theme.Opacity.light))
                .frame(width: 56, height: 56)
                .blur(radius: 8)

            // Icon container
            Circle()
                .fill(Color.white.opacity(Theme.Opacity.overlay))
                .frame(width: 48, height: 48)
                .overlay(
                    Circle()
                        .stroke(variant.accentColor.opacity(Theme.Opacity.lightMedium), lineWidth: 1)
                )

            // Icon
            Image(systemName: variant.icon)
                .font(Typography.Command.title3)
                .foregroundStyle(variant.accentColor)
        }
    }

    // MARK: - Reading Mode Badge

    private var readingModeBadge: some View {
        Text(variant.readingMode.displayName)
            .font(Typography.Icon.xxs)
            .tracking(1)
            .textCase(.uppercase)
            .foregroundStyle(variant.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(variant.accentColor.opacity(Theme.Opacity.divider))
            )
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card)
            .fill(Color.white.opacity(Theme.Opacity.faint))
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.showcaseCard)
            )
    }

    // MARK: - Card Border

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card)
            .stroke(
                LinearGradient(
                    colors: [
                        variant.accentColor.opacity(Theme.Opacity.lightMedium),
                        Color.white.opacity(Theme.Opacity.overlay),
                        variant.accentColor.opacity(Theme.Opacity.light)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.showcaseBackground.ignoresSafeArea()

        VStack(spacing: 16) {
            ShowcaseReaderCard(variant: .illuminatedScriptorium) {
                Text("Scriptorium")
            }

            ShowcaseReaderCard(variant: .candlelitChapel) {
                Text("Chapel")
            }

            ShowcaseReaderCard(variant: .scholarsMarginalia) {
                Text("Marginalia")
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}

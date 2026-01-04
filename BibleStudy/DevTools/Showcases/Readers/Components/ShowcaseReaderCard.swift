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
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
            if pressing {
                HomeShowcaseHaptics.cardPress()
            }
        }, perform: {})
    }

    // MARK: - Card Content

    private var cardContent: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // Icon
            iconView

            // Text content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                // Title
                Text(variant.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.showcasePrimaryText)

                // Subtitle
                Text(variant.subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.showcaseSecondaryText)

                // Reading mode badge
                readingModeBadge
                    .padding(.top, AppTheme.Spacing.xxs)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.showcaseTertiaryText)
        }
        .padding(AppTheme.Spacing.lg)
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
                .fill(variant.accentColor.opacity(0.2))
                .frame(width: 56, height: 56)
                .blur(radius: 8)

            // Icon container
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 48, height: 48)
                .overlay(
                    Circle()
                        .stroke(variant.accentColor.opacity(0.4), lineWidth: 1)
                )

            // Icon
            Image(systemName: variant.icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(variant.accentColor)
        }
    }

    // MARK: - Reading Mode Badge

    private var readingModeBadge: some View {
        Text(variant.readingMode.displayName)
            .font(.system(size: 10, weight: .medium))
            .tracking(1)
            .textCase(.uppercase)
            .foregroundStyle(variant.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(variant.accentColor.opacity(0.15))
            )
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
            .fill(Color.white.opacity(0.05))
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .fill(Color.showcaseCard)
            )
    }

    // MARK: - Card Border

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
            .stroke(
                LinearGradient(
                    colors: [
                        variant.accentColor.opacity(0.4),
                        Color.white.opacity(0.1),
                        variant.accentColor.opacity(0.2)
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

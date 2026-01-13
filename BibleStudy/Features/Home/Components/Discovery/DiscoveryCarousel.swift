import SwiftUI

// MARK: - Mock Discovery Carousel
// Horizontal scrolling carousel for stories and topics

struct DiscoveryCarousel: View {
    let items: [MockDiscoveryItem]
    var style: CarouselStyle = .compact

    @Environment(\.colorScheme) private var colorScheme

    enum CarouselStyle {
        case compact     // Small cards in horizontal scroll
        case cinematic   // Full-width paged cards
    }

    var body: some View {
        switch style {
        case .compact:
            compactCarousel
        case .cinematic:
            cinematicCarousel
        }
    }

    // MARK: - Compact Carousel

    private var compactCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.md) {
                ForEach(items) { item in
                    CompactDiscoveryCard(item: item)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
    }

    // MARK: - Cinematic Carousel

    @State private var currentPage = 0

    private var cinematicCarousel: some View {
        VStack(spacing: Theme.Spacing.md) {
            TabView(selection: $currentPage) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    CinematicDiscoveryCard(item: item)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 160)

            // Page dots
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(0..<items.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color("AccentBronze") : Color("AppTextSecondary").opacity(Theme.Opacity.textSecondary))
                        .frame(width: Theme.Spacing.sm, height: Theme.Spacing.sm)
                        .animation(Theme.Animation.settle, value: currentPage)
                }
            }
        }
    }
}

// MARK: - Compact Discovery Card

struct CompactDiscoveryCard: View {
    let item: MockDiscoveryItem
    @State private var isPressed = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Type badge
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: item.type.iconName)
                    .font(Typography.Icon.xxs.weight(.medium))
                Text(item.type.rawValue)
                    .font(Typography.Icon.xxs.weight(.bold))
                    .textCase(.uppercase)
            }
            .foregroundStyle(badgeColor)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(badgeColor.opacity(Theme.Opacity.selectionBackground))
            )

            // Title
            Text(item.title)
                .font(Typography.Command.headline)
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(2)

            // Subtitle
            Text(item.subtitle)
                .font(Typography.Command.caption)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(1)

            Spacer()

            // Duration
            Text("\(item.estimatedMinutes) min")
                .font(Typography.Icon.xs.weight(.medium))
                .foregroundStyle(Color("TertiaryText"))
        }
        .frame(width: 80, height: 80)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.appSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color.white.opacity(Theme.Opacity.subtle), lineWidth: Theme.Stroke.hairline)
        )
        .scaleEffect(isPressed ? 0.99 : 1.0)
        .animation(Theme.Animation.settle, value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private var badgeColor: Color {
        switch item.type {
        case .story:
            return Color("AppAccentAction")
        case .topic:
            return Color("AccentBronze")
        case .character:
            return Color("AppAccentAction")
        }
    }
}

// MARK: - Cinematic Discovery Card

struct CinematicDiscoveryCard: View {
    let item: MockDiscoveryItem

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Spacer()

            // Title
            Text(item.title)
                .font(Typography.Command.title3.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))

            // Subtitle
            Text(item.subtitle)
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))

            // Duration
            Text("\(item.estimatedMinutes) min")
                .font(Typography.Command.caption.weight(.medium))
                .foregroundStyle(Color("TertiaryText"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.xl)
        .background(
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color("AppAccentAction").opacity(Theme.Opacity.pressed),
                        Color.appBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Subtle pattern overlay could go here
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .shadow(color: .black.opacity(Theme.Opacity.textSecondary), radius: 12, y: 6)
        .padding(.horizontal, Theme.Spacing.lg)
    }
}

// MARK: - Preview

#Preview("Compact") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()

        DiscoveryCarousel(
            items: HomeMockData.allDiscoveryItems,
            style: .compact
        )
    }
}

#Preview("Cinematic") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()

        DiscoveryCarousel(
            items: HomeMockData.featuredStories,
            style: .cinematic
        )
    }
}

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
                        .fill(index == currentPage ? Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)) : Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary))
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
                    .fill(badgeColor.opacity(Theme.Opacity.light))
            )

            // Title
            Text(item.title)
                .font(SanctuaryTypography.Dashboard.cardTitle)
                .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
                .lineLimit(2)

            // Subtitle
            Text(item.subtitle)
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                .lineLimit(1)

            Spacer()

            // Duration
            Text("\(item.estimatedMinutes) min")
                .font(Typography.Icon.xs.weight(.medium))
                .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
        }
        .frame(width: 80, height: 80)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color.white.opacity(Theme.Opacity.faint), lineWidth: Theme.Stroke.hairline)
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
            return .lapisLazuli
        case .topic:
            return Color.accentBronze
        case .character:
            return .amethyst
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
                .font(SanctuaryTypography.Narrative.cardTitle)
                .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

            // Subtitle
            Text(item.subtitle)
                .font(SanctuaryTypography.Narrative.cardSubtitle)
                .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))

            // Duration
            Text("\(item.estimatedMinutes) min")
                .font(Typography.Command.caption.weight(.medium))
                .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.xl)
        .background(
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.pressed),
                        Colors.Surface.background(for: ThemeMode.current(from: colorScheme))
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Subtle pattern overlay could go here
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .shadow(color: .black.opacity(Theme.Opacity.secondary), radius: 12, y: 6)
        .padding(.horizontal, Theme.Spacing.lg)
    }
}

// MARK: - Preview

#Preview("Compact") {
    ZStack {
        Colors.Surface.background(for: .dark).ignoresSafeArea()

        DiscoveryCarousel(
            items: SanctuaryMockData.allDiscoveryItems,
            style: .compact
        )
    }
}

#Preview("Cinematic") {
    ZStack {
        Colors.Surface.background(for: .dark).ignoresSafeArea()

        DiscoveryCarousel(
            items: SanctuaryMockData.featuredStories,
            style: .cinematic
        )
    }
}

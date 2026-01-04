import SwiftUI

// MARK: - Mock Discovery Carousel
// Horizontal scrolling carousel for stories and topics

struct MockDiscoveryCarousel: View {
    let items: [MockDiscoveryItem]
    var style: CarouselStyle = .compact

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
            HStack(spacing: HomeShowcaseTheme.Spacing.md) {
                ForEach(items) { item in
                    CompactDiscoveryCard(item: item)
                }
            }
            .padding(.horizontal, HomeShowcaseTheme.Spacing.lg)
        }
    }

    // MARK: - Cinematic Carousel

    @State private var currentPage = 0

    private var cinematicCarousel: some View {
        VStack(spacing: HomeShowcaseTheme.Spacing.md) {
            TabView(selection: $currentPage) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    CinematicDiscoveryCard(item: item)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 160)

            // Page dots
            HStack(spacing: HomeShowcaseTheme.Spacing.sm) {
                ForEach(0..<items.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.divineGold : Color.fadedMoonlight.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
        }
    }
}

// MARK: - Compact Discovery Card

struct CompactDiscoveryCard: View {
    let item: MockDiscoveryItem
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: HomeShowcaseTheme.Spacing.sm) {
            // Type badge
            HStack(spacing: 4) {
                Image(systemName: item.type.iconName)
                    .font(.system(size: 10, weight: .medium))
                Text(item.type.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .textCase(.uppercase)
            }
            .foregroundStyle(badgeColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(badgeColor.opacity(0.15))
            )

            // Title
            Text(item.title)
                .font(HomeShowcaseTypography.Dashboard.cardTitle)
                .foregroundStyle(Color.moonlitParchment)
                .lineLimit(2)

            // Subtitle
            Text(item.subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.fadedMoonlight)
                .lineLimit(1)

            Spacer()

            // Duration
            Text("\(item.estimatedMinutes) min")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.mutedStone)
        }
        .frame(width: 140, height: 140)
        .padding(HomeShowcaseTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.card)
                .fill(Color.chapelShadow)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.card)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private var badgeColor: Color {
        switch item.type {
        case .story:
            return .lapisLazuli
        case .topic:
            return .divineGold
        case .character:
            return .amethyst
        }
    }
}

// MARK: - Cinematic Discovery Card

struct CinematicDiscoveryCard: View {
    let item: MockDiscoveryItem

    var body: some View {
        VStack(alignment: .leading, spacing: HomeShowcaseTheme.Spacing.md) {
            Spacer()

            // Title
            Text(item.title)
                .font(HomeShowcaseTypography.Narrative.cardTitle)
                .foregroundStyle(Color.moonlitParchment)

            // Subtitle
            Text(item.subtitle)
                .font(HomeShowcaseTypography.Narrative.cardSubtitle)
                .foregroundStyle(Color.fadedMoonlight)

            // Duration
            Text("\(item.estimatedMinutes) min")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.mutedStone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HomeShowcaseTheme.Spacing.xl)
        .background(
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.deepPurple.opacity(0.8),
                        Color.candlelitStone
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Subtle pattern overlay could go here
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.large))
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
        .padding(.horizontal, HomeShowcaseTheme.Spacing.lg)
    }
}

// MARK: - Preview

#Preview("Compact") {
    ZStack {
        Color.candlelitStone.ignoresSafeArea()

        MockDiscoveryCarousel(
            items: HomeShowcaseMockData.allDiscoveryItems,
            style: .compact
        )
    }
}

#Preview("Cinematic") {
    ZStack {
        Color.candlelitStone.ignoresSafeArea()

        MockDiscoveryCarousel(
            items: HomeShowcaseMockData.featuredStories,
            style: .cinematic
        )
    }
}

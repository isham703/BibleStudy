import SwiftUI

// MARK: - Candlelit Sanctuary Page
// Nocturnal Contemplation + Liturgical Reverence aesthetic
// Intimate, devotional design for evening and bedtime use

struct CandlelitSanctuaryPage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.settingsAction) private var settingsAction
    @State private var isVisible = false

    private let verse = HomeShowcaseMockData.dailyVerse
    private var user: MockUserData { SanctuaryDataAdapter.shared.userData }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background layers
                backgroundLayers

                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        headerSection
                            .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)
                            .padding(.top, HomeShowcaseTheme.Spacing.xl)

                        Spacer()
                            .frame(height: HomeShowcaseTheme.Spacing.xxxl)

                        // Tonight's Verse
                        verseSection

                        Spacer()
                            .frame(height: HomeShowcaseTheme.Spacing.xxl)

                        // Primary CTA - Compline
                        complineCard
                            .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)

                        Spacer()
                            .frame(height: HomeShowcaseTheme.Spacing.lg)

                        // Feature Grid
                        featureGrid
                            .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)

                        Spacer()
                            .frame(height: HomeShowcaseTheme.Spacing.xxxl)

                        // Bottom spacing for candle
                        Spacer()
                            .frame(height: 120)
                    }
                    .frame(minHeight: geometry.size.height)
                }

                // Floating candle at bottom
                VStack {
                    Spacer()
                    CandleFlame()
                        .offset(y: 20)
                }
                .ignoresSafeArea(.all, edges: .bottom)
            }
        }
        .background(Color.nightVoid)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isVisible = true
            }
        }
    }

    // MARK: - Background Layers

    private var backgroundLayers: some View {
        ZStack {
            // Base gradient
            Color.vespersSkyGradient
                .ignoresSafeArea()

            // Starfield
            StarfieldBackground()
                .opacity(reduceMotion ? 0.6 : 1.0)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center) {
            // Greeting
            Text("Good evening, \(user.userName ?? "friend")")
                .font(HomeShowcaseTypography.Candlelit.greeting)
                .foregroundStyle(Color.moonMist)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: isVisible)

            Spacer()

            // Settings
            Button(action: settingsAction) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.moonMist.opacity(0.6))
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: isVisible)

            // Streak badge
            MockStreakBadge(count: user.currentStreak)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.5), value: isVisible)
        }
    }

    // MARK: - Verse Section

    private var verseSection: some View {
        VStack(spacing: HomeShowcaseTheme.Spacing.xl) {
            // Top ornamental divider
            OrnamentalDivider()
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.5), value: isVisible)

            // Verse text
            Text("\"\(verse.text)\"")
                .font(HomeShowcaseTypography.Candlelit.verse)
                .foregroundStyle(Color.starlight)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.7), value: isVisible)

            // Reference
            Text("— \(verse.reference)")
                .font(HomeShowcaseTypography.Candlelit.reference)
                .tracking(4)
                .foregroundStyle(Color.candleAmber)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(1.0), value: isVisible)

            // Bottom ornamental divider
            OrnamentalDivider()
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(1.1), value: isVisible)
        }
        .padding(.vertical, HomeShowcaseTheme.Spacing.lg)
    }

    // MARK: - Compline Card (Primary CTA)

    private var complineCard: some View {
        SanctuaryFeatureCard(
            icon: "moon.stars.fill",
            label: "COMPLINE",
            title: "Begin your evening prayer",
            subtitle: "~15 min guided meditation",
            isPrimary: true,
            accentColor: .candleAmber
        ) {
            ComplinePOC()
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 40)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.3), value: isVisible)
    }

    // MARK: - Feature Grid

    private var featureGrid: some View {
        VStack(spacing: HomeShowcaseTheme.Spacing.md) {
            // Row 1: Prayers from Deep + Living Scripture
            HStack(spacing: HomeShowcaseTheme.Spacing.md) {
                SanctuaryFeatureCard(
                    icon: "hands.sparkles.fill",
                    label: "PRAYERS",
                    title: "Prayers from the Deep",
                    subtitle: "Craft a personal prayer",
                    isPrimary: false,
                    accentColor: .roseIncense
                ) {
                    AIFeaturePlaceholderView(feature: .prayersFromDeep)
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 30)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.5), value: isVisible)

                SanctuaryFeatureCard(
                    icon: "book.pages.fill",
                    label: "SCRIPTURE",
                    title: "Living Scripture",
                    subtitle: "Enter the Prodigal's story",
                    isPrimary: false,
                    accentColor: .thresholdGold
                ) {
                    AIFeaturePlaceholderView(feature: .livingScripture)
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 30)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.6), value: isVisible)
            }

            // Row 2: Commentary + Memory Palace
            HStack(spacing: HomeShowcaseTheme.Spacing.md) {
                SanctuaryFeatureCard(
                    icon: "text.book.closed.fill",
                    label: "COMMENTARY",
                    title: "Living Commentary",
                    subtitle: "Study John 1",
                    isPrimary: false,
                    accentColor: .thresholdIndigo
                ) {
                    AIFeaturePlaceholderView(feature: .livingCommentary)
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 30)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.7), value: isVisible)

                SanctuaryFeatureCard(
                    icon: "building.columns.fill",
                    label: "MEMORY",
                    title: "Memory Palace",
                    subtitle: "Memorize Psalm 23",
                    isPrimary: false,
                    accentColor: .thresholdPurple
                ) {
                    AIFeaturePlaceholderView(feature: .memoryPalace)
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 30)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.8), value: isVisible)
            }
        }
    }
}

// MARK: - Sanctuary Feature Card

struct SanctuaryFeatureCard<Destination: View>: View {
    let icon: String
    let label: String
    let title: String
    let subtitle: String
    let isPrimary: Bool
    let accentColor: Color
    let destination: () -> Destination

    @State private var isPressed = false

    init(
        icon: String,
        label: String,
        title: String,
        subtitle: String,
        isPrimary: Bool = false,
        accentColor: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.icon = icon
        self.label = label
        self.title = title
        self.subtitle = subtitle
        self.isPrimary = isPrimary
        self.accentColor = accentColor
        self.destination = destination
    }

    var body: some View {
        NavigationLink(destination: destination()) {
            VStack(alignment: .leading, spacing: isPrimary ? 12 : 8) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: isPrimary ? 24 : 18, weight: .medium))
                        .foregroundStyle(accentColor)

                    Text(label)
                        .font(HomeShowcaseTypography.Candlelit.featureLabel)
                        .tracking(3)
                        .foregroundStyle(accentColor)
                }

                // Title
                Text(title)
                    .font(isPrimary
                        ? HomeShowcaseTypography.Candlelit.featureTitle
                        : .system(size: 15, weight: .medium)
                    )
                    .foregroundStyle(Color.starlight)
                    .lineLimit(2)

                // Subtitle
                Text(subtitle)
                    .font(HomeShowcaseTypography.Candlelit.featureSubtitle)
                    .foregroundStyle(Color.moonMist)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(isPrimary ? 20 : 16)
            .background(cardBackground)
            .overlay(cardBorder)
            .shadow(color: accentColor.opacity(isPressed ? 0.4 : 0.2), radius: isPrimary ? 20 : 12, y: 8)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .brightness(isPressed ? 0.05 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
            if pressing {
                HomeShowcaseHaptics.candlelitPress()
            }
        }, perform: {})
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: isPrimary ? 16 : 12)
            .fill(Color.white.opacity(0.05))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: isPrimary ? 16 : 12)
            .stroke(
                isPrimary
                    ? RadialGradient(
                        colors: [accentColor.opacity(0.6), accentColor.opacity(0.1)],
                        center: .bottom,
                        startRadius: 0,
                        endRadius: 200
                    )
                    : RadialGradient(
                        colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    ),
                lineWidth: isPrimary ? 1.5 : 0.5
            )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CandlelitSanctuaryPage()
    }
}

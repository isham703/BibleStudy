import SwiftUI

// MARK: - Compline Sanctuary View
// Compline / Night Prayer - 9pm-5am
// Deep rest, sacred silence - animation breathing, pulsing, very slow, peaceful

struct ComplineSanctuaryView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.settingsAction) private var settingsAction
    @State private var isVisible = false

    let timeOfDay: SanctuaryTimeOfDay = .compline
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
                            .padding(.horizontal, AppTheme.Spacing.xl)
                            .padding(.top, AppTheme.Spacing.xl)

                        Spacer()
                            .frame(height: AppTheme.Spacing.xxxl)

                        // Tonight's Verse
                        verseSection

                        Spacer()
                            .frame(height: AppTheme.Spacing.xxl)

                        // Primary CTA - Compline
                        complineCard
                            .padding(.horizontal, AppTheme.Spacing.xl)

                        Spacer()
                            .frame(height: AppTheme.Spacing.lg)

                        // Feature Grid
                        featureGrid
                            .padding(.horizontal, AppTheme.Spacing.xl)

                        Spacer()
                            .frame(height: AppTheme.Spacing.xxxl)

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
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
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
            // Greeting - extra light, whispered
            Text("\(timeOfDay.greeting), \(user.userName ?? "friend")")
                .font(.custom("CormorantGaramond-Light", size: 15))
                .foregroundStyle(Color.moonMist.opacity(0.8))
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: isVisible)

            Spacer()

            // Settings
            Button(action: settingsAction) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.moonMist.opacity(0.5))
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: isVisible)

            // Streak badge
            StreakBadge(count: user.currentStreak)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.6), value: isVisible)
        }
    }

    // MARK: - Verse Section

    private var verseSection: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Top ornamental divider
            OrnamentalDivider()
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.6), value: isVisible)

            // Verse text - light italic, whispered feel
            Text("\"\(timeOfDay.verse)\"")
                .font(.custom("CormorantGaramond-LightItalic", size: 24))
                .foregroundStyle(Color.starlight)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 1.0).delay(0.8), value: isVisible)

            // Reference
            Text("— \(timeOfDay.verseReference)")
                .font(.custom("Cinzel-Regular", size: 11))
                .tracking(4)
                .foregroundStyle(Color.candleAmber)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(1.2), value: isVisible)

            // Bottom ornamental divider
            OrnamentalDivider()
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(1.3), value: isVisible)
        }
        .padding(.vertical, AppTheme.Spacing.lg)
    }

    // MARK: - Compline Card (Primary CTA)

    private var complineCard: some View {
        ComplineFeatureCard(
            feature: .compline,
            isPrimary: true,
            accentColor: .candleAmber
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 40)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.5), value: isVisible)
    }

    // MARK: - Feature Grid

    private var featureGrid: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Row 1: Prayers from Deep + Living Scripture
            HStack(spacing: AppTheme.Spacing.md) {
                ComplineFeatureCard(
                    feature: .prayersFromDeep,
                    isPrimary: false,
                    accentColor: .roseIncense
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 30)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.7), value: isVisible)

                ComplineFeatureCard(
                    feature: .livingScripture,
                    isPrimary: false,
                    accentColor: .thresholdGold
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 30)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.8), value: isVisible)
            }

            // Row 2: Commentary + Memory Palace
            HStack(spacing: AppTheme.Spacing.md) {
                ComplineFeatureCard(
                    feature: .livingCommentary,
                    isPrimary: false,
                    accentColor: .thresholdIndigo
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 30)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.9), value: isVisible)

                ComplineFeatureCard(
                    feature: .memoryPalace,
                    isPrimary: false,
                    accentColor: .thresholdPurple
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 30)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(2.0), value: isVisible)
            }
        }
    }
}

// MARK: - Compline Feature Card

private struct ComplineFeatureCard: View {
    let feature: AIFeature?
    let icon: String
    let label: String
    let title: String
    let subtitle: String
    let isPrimary: Bool
    let accentColor: Color

    @State private var isPressed = false

    // Convenience initializer for AIFeature-based cards
    init(feature: AIFeature, isPrimary: Bool, accentColor: Color) {
        self.feature = feature
        self.icon = feature.icon
        self.label = feature.cardLabel
        self.title = feature.cardTitle
        self.subtitle = feature.cardSubtitle
        self.isPrimary = isPrimary
        self.accentColor = accentColor
    }

    // Initializer for custom cards (like primary CTA)
    init(icon: String, label: String, title: String, subtitle: String, isPrimary: Bool, accentColor: Color) {
        self.feature = nil
        self.icon = icon
        self.label = label
        self.title = title
        self.subtitle = subtitle
        self.isPrimary = isPrimary
        self.accentColor = accentColor
    }

    var body: some View {
        Group {
            if let feature = feature {
                // NavigationLink for feature cards
                NavigationLink(destination: feature.destinationView) {
                    cardContent
                }
            } else {
                // Button for custom cards (like primary CTA)
                Button(action: {}) {
                    cardContent
                }
            }
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

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: isPrimary ? 12 : 8) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: isPrimary ? 24 : 18, weight: .medium))
                    .foregroundStyle(accentColor)

                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(accentColor)
            }

            // Title
            Text(title)
                .font(isPrimary
                    ? .custom("CormorantGaramond-SemiBold", size: 18)
                    : .system(size: 15, weight: .medium)
                )
                .foregroundStyle(Color.starlight)
                .lineLimit(2)

            // Subtitle
            Text(subtitle)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color.moonMist)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isPrimary ? 20 : 16)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: accentColor.opacity(isPressed ? 0.4 : 0.2), radius: isPrimary ? 20 : 12, y: 8)
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
        ComplineSanctuaryView()
    }
}

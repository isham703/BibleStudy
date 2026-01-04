import SwiftUI

// MARK: - Dawn Sanctuary View
// Lauds / Morning Prayer - 5am-9am
// Ethereal Aurora aesthetic - cool lavender to warm coral
// Animation: Upward, expanding, brightening - awakening hope

struct DawnSanctuaryView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.settingsAction) private var settingsAction
    @State private var isVisible = false

    let timeOfDay: SanctuaryTimeOfDay = .dawn
    private var user: MockUserData { SanctuaryDataAdapter.shared.userData }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - ethereal aurora
                DawnGlowBackground()

                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        headerSection
                            .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)
                            .padding(.top, HomeShowcaseTheme.Spacing.xl)

                        Spacer()
                            .frame(height: HomeShowcaseTheme.Spacing.xxxl)

                        // Morning verse - hero element
                        verseSection

                        Spacer()
                            .frame(height: HomeShowcaseTheme.Spacing.xxl)

                        // Primary CTA - Morning Devotion
                        primaryCard
                            .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)

                        Spacer()
                            .frame(height: HomeShowcaseTheme.Spacing.lg)

                        // Feature Grid
                        featureGrid
                            .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)

                        Spacer()
                            .frame(height: HomeShowcaseTheme.Spacing.xxxl * 1.5)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .preferredColorScheme(.light)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isVisible = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center) {
            // Greeting - dark slate for contrast
            Text("\(timeOfDay.greeting), \(user.userName ?? "friend")")
                .font(.custom("CormorantGaramond-Regular", size: 17))
                .foregroundStyle(Color.dawnSlate.opacity(0.85))
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : -10)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: isVisible)

            Spacer()

            // Settings
            Button(action: settingsAction) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.dawnSlate.opacity(0.5))
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: isVisible)

            // Streak badge - frosted glass
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.dawnAccent)
                Text("\(user.currentStreak)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.dawnSlate)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule()
                    .stroke(Color.dawnAccent.opacity(0.3), lineWidth: 0.5)
            )
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: isVisible)
        }
    }

    // MARK: - Verse Section

    private var verseSection: some View {
        VStack(spacing: HomeShowcaseTheme.Spacing.xl) {
            // Top divider - aurora-inspired
            AuroraDivider()
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: isVisible)

            // Verse text - dark slate for excellent contrast
            Text("\"\(timeOfDay.verse)\"")
                .font(.custom("CormorantGaramond-Italic", size: 26))
                .foregroundStyle(Color.dawnSlate)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : -15)
                .animation(.easeOut(duration: 0.8).delay(0.6), value: isVisible)

            // Reference - accent color
            Text("— \(timeOfDay.verseReference)")
                .font(.custom("Cinzel-Regular", size: 11))
                .tracking(4)
                .foregroundStyle(Color.dawnAccent)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.9), value: isVisible)

            // Bottom divider
            AuroraDivider()
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(1.0), value: isVisible)
        }
        .padding(.vertical, HomeShowcaseTheme.Spacing.lg)
    }

    // MARK: - Primary Card

    private var primaryCard: some View {
        DawnFeatureCard(
            feature: .livingScripture,
            isPrimary: true,
            accentColor: .dawnAccent
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -30)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.2), value: isVisible)
    }

    // MARK: - Feature Grid

    private var featureGrid: some View {
        VStack(spacing: HomeShowcaseTheme.Spacing.md) {
            // Row 1
            HStack(spacing: HomeShowcaseTheme.Spacing.md) {
                DawnFeatureCard(
                    feature: .livingScripture,
                    isPrimary: false,
                    accentColor: Color(hex: "c2410c") // Deeper orange
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : -20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.4), value: isVisible)

                DawnFeatureCard(
                    feature: .livingCommentary,
                    isPrimary: false,
                    accentColor: Color(hex: "7c3aed") // Purple
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : -20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.5), value: isVisible)
            }

            // Row 2
            HStack(spacing: HomeShowcaseTheme.Spacing.md) {
                DawnFeatureCard(
                    feature: .prayersFromDeep,
                    isPrimary: false,
                    accentColor: Color(hex: "db2777") // Rose
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : -20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.6), value: isVisible)

                DawnFeatureCard(
                    feature: .memoryPalace,
                    isPrimary: false,
                    accentColor: Color(hex: "0891b2") // Cyan
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : -20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.7), value: isVisible)
            }
        }
    }
}

// MARK: - Aurora Divider

private struct AuroraDivider: View {
    var body: some View {
        HStack(spacing: 16) {
            // Left gradient line - cool to warm
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.dawnPeriwinkle.opacity(0.5),
                            Color.dawnRosePink.opacity(0.6)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1.5)

            // Center icon - sun symbol
            Image(systemName: "sun.max.fill")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.dawnApricot, Color.dawnSunrise],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Right gradient line - warm to cool
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.dawnRosePink.opacity(0.6),
                            Color.dawnPeriwinkle.opacity(0.5),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1.5)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Dawn Feature Card

private struct DawnFeatureCard: View {
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
                    .font(.system(size: isPrimary ? 11 : 10, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(accentColor)
            }

            // Title - dark slate
            Text(title)
                .font(isPrimary
                    ? .custom("CormorantGaramond-SemiBold", size: 20)
                    : .system(size: 15, weight: .semibold)
                )
                .foregroundStyle(Color.dawnSlate)
                .lineLimit(2)

            // Subtitle
            Text(subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.dawnSlateLight)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isPrimary ? 20 : 16)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(
            color: accentColor.opacity(isPressed ? 0.2 : 0.15),
            radius: isPrimary ? 20 : 12,
            y: isPressed ? 2 : 6
        )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: isPrimary ? 16 : 12)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: isPrimary ? 16 : 12)
                    .fill(Color.dawnFrost.opacity(0.7))
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: isPrimary ? 16 : 12)
            .stroke(
                LinearGradient(
                    colors: [
                        accentColor.opacity(isPrimary ? 0.4 : 0.25),
                        Color.white.opacity(0.3),
                        accentColor.opacity(isPrimary ? 0.2 : 0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: isPrimary ? 1.5 : 1
            )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DawnSanctuaryView()
    }
}

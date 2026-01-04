import SwiftUI

// MARK: - Vespers Sanctuary View
// Vespers / Evening Prayer - 5pm-9pm
// Winding down, gratitude - animation downward fades, dimming, transitioning

struct VespersSanctuaryView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.settingsAction) private var settingsAction
    @State private var isVisible = false

    let timeOfDay: SanctuaryTimeOfDay = .vespers
    private var user: MockUserData { SanctuaryDataAdapter.shared.userData }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with emerging stars
                VespersBackground()

                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        headerSection
                            .padding(.horizontal, SanctuaryTheme.Spacing.xl)
                            .padding(.top, SanctuaryTheme.Spacing.xl)

                        Spacer()
                            .frame(height: SanctuaryTheme.Spacing.xxxl)

                        // Evening verse
                        verseSection

                        Spacer()
                            .frame(height: SanctuaryTheme.Spacing.xxl)

                        // Primary CTA - Evening Prayer
                        primaryCard
                            .padding(.horizontal, SanctuaryTheme.Spacing.xl)

                        Spacer()
                            .frame(height: SanctuaryTheme.Spacing.lg)

                        // Feature Grid
                        featureGrid
                            .padding(.horizontal, SanctuaryTheme.Spacing.xl)

                        Spacer()
                            .frame(height: SanctuaryTheme.Spacing.xxxl)

                        // Transition hint to Compline
                        complineHint
                            .padding(.horizontal, SanctuaryTheme.Spacing.xl)

                        Spacer()
                            .frame(height: SanctuaryTheme.Spacing.xxxl)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                isVisible = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center) {
            // Greeting
            Text("\(timeOfDay.greeting), \(user.userName ?? "friend")")
                .font(.custom("CormorantGaramond-Light", size: 17))
                .foregroundStyle(Color.vespersText.opacity(0.9))
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 8)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: isVisible)

            Spacer()

            // Settings
            Button(action: settingsAction) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.vespersText.opacity(0.5))
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: isVisible)

            // Streak
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.vespersAmber)
                Text("\(user.currentStreak)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.vespersText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.vespersAmber.opacity(0.2))
            )
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: isVisible)
        }
    }

    // MARK: - Verse Section

    private var verseSection: some View {
        VStack(spacing: SanctuaryTheme.Spacing.xl) {
            // Top divider
            VespersDivider()
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: isVisible)

            // Incense icon
            Image(systemName: "flame.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.vespersAmber.opacity(0.6))
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.5), value: isVisible)

            // Verse text
            Text("\"\(timeOfDay.verse)\"")
                .font(.custom("CormorantGaramond-LightItalic", size: 24))
                .foregroundStyle(Color.vespersText)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, SanctuaryTheme.Spacing.xl)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)
                .animation(.easeOut(duration: 0.7).delay(0.6), value: isVisible)

            // Reference
            Text("— \(timeOfDay.verseReference)")
                .font(.custom("Cinzel-Regular", size: 11))
                .tracking(4)
                .foregroundStyle(Color.vespersGoldAccent)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.9), value: isVisible)

            // Bottom divider
            VespersDivider()
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(1.0), value: isVisible)
        }
        .padding(.vertical, SanctuaryTheme.Spacing.lg)
    }

    // MARK: - Primary Card

    private var primaryCard: some View {
        VespersFeatureCard(
            feature: .compline,
            isPrimary: true,
            accentColor: .vespersAmber
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.2), value: isVisible)
    }

    // MARK: - Feature Grid

    private var featureGrid: some View {
        VStack(spacing: SanctuaryTheme.Spacing.md) {
            // Row 1
            HStack(spacing: SanctuaryTheme.Spacing.md) {
                VespersFeatureCard(
                    feature: .prayersFromDeep,
                    isPrimary: false,
                    accentColor: .vespersPurple
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.4), value: isVisible)

                VespersFeatureCard(
                    feature: .livingScripture,
                    isPrimary: false,
                    accentColor: .vespersGoldAccent
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.5), value: isVisible)
            }

            // Row 2
            HStack(spacing: SanctuaryTheme.Spacing.md) {
                VespersFeatureCard(
                    feature: .livingCommentary,
                    isPrimary: false,
                    accentColor: .vespersIndigo
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.6), value: isVisible)

                VespersFeatureCard(
                    feature: .compline,
                    isPrimary: false,
                    accentColor: .vespersPurple
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.7), value: isVisible)
            }
        }
    }

    // MARK: - Compline Hint

    private var complineHint: some View {
        VStack(spacing: 8) {
            Text("As night approaches...")
                .font(.custom("CormorantGaramond-Italic", size: 14))
                .foregroundStyle(Color.vespersText.opacity(0.5))

            HStack(spacing: 6) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 12))
                Text("Compline awaits")
                    .font(.system(size: 12, weight: .light))
            }
            .foregroundStyle(Color.vespersText.opacity(0.4))
        }
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(2.0), value: isVisible)
    }
}

// MARK: - Vespers Divider

private struct VespersDivider: View {
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.vespersAmber.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            Image(systemName: "sparkle")
                .font(.system(size: 10))
                .foregroundStyle(Color.vespersGoldAccent.opacity(0.5))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.vespersAmber.opacity(0.3), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Vespers Feature Card

private struct VespersFeatureCard: View {
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
        .brightness(isPressed ? 0.03 : 0)
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
                    .font(.system(size: isPrimary ? 22 : 16, weight: .medium))
                    .foregroundStyle(accentColor)

                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(accentColor)
            }

            // Title
            Text(title)
                .font(isPrimary
                    ? .custom("CormorantGaramond-SemiBold", size: 18)
                    : .system(size: 14, weight: .medium)
                )
                .foregroundStyle(Color.vespersText)
                .lineLimit(2)

            // Subtitle
            Text(subtitle)
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Color.vespersText.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isPrimary ? 18 : 14)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: accentColor.opacity(isPressed ? 0.3 : 0.2), radius: isPrimary ? 15 : 10, y: 6)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: isPrimary ? 14 : 10)
            .fill(Color.white.opacity(0.06))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: isPrimary ? 14 : 10)
            .stroke(
                isPrimary
                    ? LinearGradient(
                        colors: [accentColor.opacity(0.5), accentColor.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    : LinearGradient(
                        colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                lineWidth: isPrimary ? 1.5 : 0.5
            )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VespersSanctuaryView()
    }
}

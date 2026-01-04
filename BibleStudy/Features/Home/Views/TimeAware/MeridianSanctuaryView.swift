import SwiftUI

// MARK: - Meridian Sanctuary View
// Terce / Mid-Morning Prayer - 9am-12pm
// The Illuminated Scriptorium - golden morning light through library windows
// Animation: Horizontal, precise, crisp - focused clarity

struct MeridianSanctuaryView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.settingsAction) private var settingsAction
    @State private var isVisible = false

    let timeOfDay: SanctuaryTimeOfDay = .meridian
    private var user: MockUserData { SanctuaryDataAdapter.shared.userData }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - illuminated scriptorium
                MeridianBackground()

                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        headerSection
                            .padding(.horizontal, SanctuaryTheme.Spacing.xl)
                            .padding(.top, SanctuaryTheme.Spacing.xl)

                        Spacer()
                            .frame(height: SanctuaryTheme.Spacing.xxxl)

                        // Morning verse - hero element
                        verseSection

                        Spacer()
                            .frame(height: SanctuaryTheme.Spacing.xxl)

                        // Primary CTA - Continue Study
                        primaryCard
                            .padding(.horizontal, SanctuaryTheme.Spacing.xl)

                        Spacer()
                            .frame(height: SanctuaryTheme.Spacing.lg)

                        // Feature Grid
                        featureGrid
                            .padding(.horizontal, SanctuaryTheme.Spacing.xl)

                        Spacer()
                            .frame(height: SanctuaryTheme.Spacing.xxxl * 1.5)
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
            // Greeting - sepia text
            Text("\(timeOfDay.greeting), \(user.userName ?? "friend")")
                .font(.custom("CormorantGaramond-Regular", size: 17))
                .foregroundStyle(Color.meridianSepia.opacity(0.85))
                .opacity(isVisible ? 1 : 0)
                .offset(x: isVisible ? 0 : -15)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: isVisible)

            Spacer()

            // Settings
            Button(action: settingsAction) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.meridianUmber.opacity(0.5))
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: isVisible)

            // Streak badge - gilded
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.meridianIllumination)
                Text("\(user.currentStreak)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.meridianSepia)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule()
                    .stroke(Color.meridianGilded.opacity(0.4), lineWidth: 0.5)
            )
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: isVisible)
        }
    }

    // MARK: - Verse Section

    private var verseSection: some View {
        VStack(spacing: SanctuaryTheme.Spacing.xl) {
            // Top divider - gilded illumination
            IlluminatedDivider()
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: isVisible)

            // Verse text - sepia for excellent contrast
            Text("\"\(timeOfDay.verse)\"")
                .font(.custom("CormorantGaramond-Italic", size: 26))
                .foregroundStyle(Color.meridianSepia)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .padding(.horizontal, SanctuaryTheme.Spacing.xl)
                .opacity(isVisible ? 1 : 0)
                .offset(x: isVisible ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.6), value: isVisible)

            // Reference - gilded accent
            Text("— \(timeOfDay.verseReference)")
                .font(.custom("Cinzel-Regular", size: 11))
                .tracking(4)
                .foregroundStyle(Color.meridianIllumination)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.9), value: isVisible)

            // Bottom divider
            IlluminatedDivider()
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(1.0), value: isVisible)
        }
        .padding(.vertical, SanctuaryTheme.Spacing.lg)
    }

    // MARK: - Primary Card

    private var primaryCard: some View {
        MeridianFeatureCard(
            feature: .livingCommentary,
            isPrimary: true,
            accentColor: .meridianIllumination
        )
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : 30)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.2), value: isVisible)
    }

    // MARK: - Feature Grid

    private var featureGrid: some View {
        VStack(spacing: SanctuaryTheme.Spacing.md) {
            // Row 1
            HStack(spacing: SanctuaryTheme.Spacing.md) {
                MeridianFeatureCard(
                    feature: .livingScripture,
                    isPrimary: false,
                    accentColor: .meridianVermillion
                )
                .opacity(isVisible ? 1 : 0)
                .offset(x: isVisible ? 0 : 25)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.4), value: isVisible)

                MeridianFeatureCard(
                    feature: .livingCommentary,
                    isPrimary: false,
                    accentColor: .meridianIndigo
                )
                .opacity(isVisible ? 1 : 0)
                .offset(x: isVisible ? 0 : 25)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.5), value: isVisible)
            }

            // Row 2
            HStack(spacing: SanctuaryTheme.Spacing.md) {
                MeridianFeatureCard(
                    feature: .prayersFromDeep,
                    isPrimary: false,
                    accentColor: Color(hex: "9f1239")  // Deep rose
                )
                .opacity(isVisible ? 1 : 0)
                .offset(x: isVisible ? 0 : 25)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.6), value: isVisible)

                MeridianFeatureCard(
                    feature: .memoryPalace,
                    isPrimary: false,
                    accentColor: .meridianForest
                )
                .opacity(isVisible ? 1 : 0)
                .offset(x: isVisible ? 0 : 25)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.7), value: isVisible)
            }
        }
    }
}

// MARK: - Illuminated Divider

private struct IlluminatedDivider: View {
    var body: some View {
        HStack(spacing: 16) {
            // Left gradient line - gilded
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.meridianGilded.opacity(0.3),
                            Color.meridianIllumination.opacity(0.5)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1.5)

            // Center icon - illumination symbol
            Image(systemName: "sun.max.fill")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.meridianIllumination, Color.meridianGilded],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Right gradient line - gilded
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.meridianIllumination.opacity(0.5),
                            Color.meridianGilded.opacity(0.3),
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

// MARK: - Meridian Feature Card

private struct MeridianFeatureCard: View {
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
                HomeShowcaseHaptics.scholarlyPress()
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

            // Title - sepia text
            Text(title)
                .font(isPrimary
                    ? .custom("CormorantGaramond-SemiBold", size: 20)
                    : .system(size: 15, weight: .semibold)
                )
                .foregroundStyle(Color.meridianSepia)
                .lineLimit(2)

            // Subtitle
            Text(subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.meridianUmber)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isPrimary ? 20 : 16)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(
            color: accentColor.opacity(isPressed ? 0.15 : 0.12),
            radius: isPrimary ? 18 : 10,
            y: isPressed ? 2 : 5
        )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: isPrimary ? 16 : 12)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: isPrimary ? 16 : 12)
                    .fill(Color.meridianLinen.opacity(0.85))
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: isPrimary ? 16 : 12)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.meridianGilded.opacity(isPrimary ? 0.45 : 0.3),
                        Color.white.opacity(0.3),
                        Color.meridianGilded.opacity(isPrimary ? 0.25 : 0.15)
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
        MeridianSanctuaryView()
    }
}

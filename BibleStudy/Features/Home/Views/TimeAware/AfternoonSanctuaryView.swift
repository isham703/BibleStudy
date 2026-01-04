import SwiftUI

// MARK: - Afternoon Sanctuary View
// Sext / Midday Prayer - 12pm-5pm
// Contemplative Study aesthetic - quiet library with afternoon light
// Animation: Settling, gentle - meditative, restful

struct AfternoonSanctuaryView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.settingsAction) private var settingsAction
    @State private var isVisible = false
    @State private var breathe: CGFloat = 0

    let timeOfDay: SanctuaryTimeOfDay = .afternoon
    private var user: MockUserData { SanctuaryDataAdapter.shared.userData }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with subtle light beams
                AfternoonWindowBackground()

                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        headerSection
                            .padding(.horizontal, AppTheme.Spacing.xl)
                            .padding(.top, AppTheme.Spacing.xl)

                        Spacer()
                            .frame(height: AppTheme.Spacing.xxxl)

                        // Selah moment - central focus
                        selahSection

                        Spacer()
                            .frame(height: AppTheme.Spacing.xxl)

                        // Primary CTA
                        primaryCard
                            .padding(.horizontal, AppTheme.Spacing.xl)

                        Spacer()
                            .frame(height: AppTheme.Spacing.lg)

                        // Feature Grid
                        featureGrid
                            .padding(.horizontal, AppTheme.Spacing.xl)

                        Spacer()
                            .frame(height: AppTheme.Spacing.xxxl * 1.5)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .preferredColorScheme(.light)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                isVisible = true
            }
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    breathe = 1
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center) {
            // Greeting - espresso text
            Text("\(timeOfDay.greeting), \(user.userName ?? "friend")")
                .font(.custom("CormorantGaramond-Regular", size: 17))
                .foregroundStyle(Color.afternoonEspresso.opacity(0.85))
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.3), value: isVisible)

            Spacer()

            // Settings
            Button(action: settingsAction) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.afternoonMocha.opacity(0.5))
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.4), value: isVisible)

            // Streak badge - refined
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.afternoonAmber)
                Text("\(user.currentStreak)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.afternoonEspresso)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule()
                    .stroke(Color.afternoonAmber.opacity(0.3), lineWidth: 0.5)
            )
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: isVisible)
        }
    }

    // MARK: - Selah Section

    private var selahSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Selah label - refined typography
            Text("SELAH")
                .font(.custom("Cinzel-Regular", size: 13))
                .tracking(10)
                .foregroundStyle(Color.afternoonAmber)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.5), value: isVisible)

            // Elegant breathing circle - zen-inspired
            ZStack {
                // Outer ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.afternoonHoney.opacity(0.4),
                                Color.afternoonAmber.opacity(0.2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(1 + breathe * 0.12)

                // Inner glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.afternoonHoney.opacity(0.15 + breathe * 0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 40
                        )
                    )
                    .frame(width: 70, height: 70)
                    .scaleEffect(1 + breathe * 0.1)
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.6), value: isVisible)

            // Verse text - prominent, readable
            Text("\"\(timeOfDay.verse)\"")
                .font(.custom("CormorantGaramond-Italic", size: 28))
                .foregroundStyle(Color.afternoonEspresso)
                .multilineTextAlignment(.center)
                .lineSpacing(12)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 1.0).delay(0.8), value: isVisible)

            // Reference - amber accent
            Text("— \(timeOfDay.verseReference)")
                .font(.custom("Cinzel-Regular", size: 11))
                .tracking(4)
                .foregroundStyle(Color.afternoonAmber)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(1.2), value: isVisible)

            // Breathing prompt
            Text("Take a moment. Breathe.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color.afternoonMocha.opacity(0.6))
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(1.4), value: isVisible)
        }
        .padding(.vertical, AppTheme.Spacing.xl)
    }

    // MARK: - Primary Card

    private var primaryCard: some View {
        AfternoonFeatureCard(
            feature: .prayersFromDeep,
            isPrimary: true,
            accentColor: .afternoonSage
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.9).delay(1.5), value: isVisible)
    }

    // MARK: - Feature Grid

    private var featureGrid: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Row 1
            HStack(spacing: AppTheme.Spacing.md) {
                AfternoonFeatureCard(
                    feature: .livingScripture,
                    isPrimary: false,
                    accentColor: .afternoonTerracotta
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 15)
                .animation(.spring(response: 0.6, dampingFraction: 0.9).delay(1.7), value: isVisible)

                AfternoonFeatureCard(
                    feature: .livingCommentary,
                    isPrimary: false,
                    accentColor: Color(hex: "6366f1") // Indigo
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 15)
                .animation(.spring(response: 0.6, dampingFraction: 0.9).delay(1.8), value: isVisible)
            }

            // Row 2
            HStack(spacing: AppTheme.Spacing.md) {
                AfternoonFeatureCard(
                    feature: .prayersFromDeep,
                    isPrimary: false,
                    accentColor: Color(hex: "db2777") // Rose
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 15)
                .animation(.spring(response: 0.6, dampingFraction: 0.9).delay(1.9), value: isVisible)

                AfternoonFeatureCard(
                    feature: .memoryPalace,
                    isPrimary: false,
                    accentColor: .afternoonSage
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 15)
                .animation(.spring(response: 0.6, dampingFraction: 0.9).delay(2.0), value: isVisible)
            }
        }
    }
}

// MARK: - Afternoon Feature Card

private struct AfternoonFeatureCard: View {
    let feature: AIFeature?
    let icon: String
    let label: String
    let title: String
    let subtitle: String?
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
    init(icon: String, label: String, title: String, subtitle: String?, isPrimary: Bool, accentColor: Color) {
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
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
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
                    .font(.system(size: isPrimary ? 10 : 9, weight: .bold))
                    .tracking(2.5)
                    .foregroundStyle(accentColor)
            }

            // Title - dark espresso
            Text(title)
                .font(isPrimary
                    ? .custom("CormorantGaramond-SemiBold", size: 19)
                    : .system(size: 15, weight: .semibold)
                )
                .foregroundStyle(Color.afternoonEspresso)
                .lineLimit(2)

            // Subtitle
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.afternoonMocha)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isPrimary ? 20 : 16)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(
            color: accentColor.opacity(isPressed ? 0.1 : 0.15),
            radius: isPressed ? 6 : 12,
            y: isPressed ? 2 : 5
        )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: isPrimary ? 14 : 10)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: isPrimary ? 14 : 10)
                    .fill(Color.afternoonLinen.opacity(0.8))
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: isPrimary ? 14 : 10)
            .stroke(
                LinearGradient(
                    colors: [
                        accentColor.opacity(isPrimary ? 0.35 : 0.2),
                        Color.white.opacity(0.3),
                        accentColor.opacity(0.1)
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
        AfternoonSanctuaryView()
    }
}

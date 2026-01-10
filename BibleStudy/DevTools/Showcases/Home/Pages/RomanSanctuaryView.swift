import SwiftUI

// MARK: - Roman Sanctuary View
// Unified home view replacing the 5 time-aware variants
// Uses Roman/Stoic design system with Stone Awakening entrance
//
// Design Philosophy:
// - Monumental Clarity: Structured layouts, bold hierarchies
// - Heroic Resilience: Stone awakening animation for loading/transitions
// - Imperial Harmony: Balance opulent details with stoic restraint
//
// Reading Mode aware (Light/Dark/Sepia/OLED) but NOT time-aware
// Bible Reading is always the primary CTA (fixed order, not time-based)

struct RomanSanctuaryView: View {
    @Environment(SanctuaryViewModel.self) private var viewModel
    @Environment(AppState.self) private var appState
    @Environment(\.settingsAction) private var settingsAction
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAwakened = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - marble/stone with imperial glow
                RomanBackground()

                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header with greeting and streak
                        RomanHeaderSection(
                            userName: viewModel.userName,
                            currentStreak: viewModel.currentStreak,
                            isAwakened: isAwakened,
                            settingsAction: settingsAction
                        )
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.top, Theme.Spacing.xl)

                        Spacer()
                            .frame(height: Theme.Spacing.xxl)

                        // Daily verse - stoic wisdom
                        RomanVerseSection(isAwakened: isAwakened)

                        Spacer()
                            .frame(height: Theme.Spacing.xxl)

                        // Primary CTA - Bible Reading (always first)
                        primaryCard
                            .padding(.horizontal, Theme.Spacing.xl)

                        Spacer()
                            .frame(height: Theme.Spacing.lg)

                        // Feature Grid - fixed order
                        featureGrid
                            .padding(.horizontal, Theme.Spacing.xl)

                        Spacer()
                            .frame(height: Theme.Spacing.xxl * 1.5)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Stone awakening - content emerges from desaturated gray
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
        }
        .onDisappear {
            isAwakened = false
        }
    }

    // MARK: - Primary Card (Bible Reading)

    private var primaryCard: some View {
        RomanFeatureCard(
            icon: "book.fill",
            label: "SCRIPTURE",
            title: "Continue Reading",
            subtitle: "John 1 - Where you left off",
            isPrimary: true,
            accentColor: Color.accentIndigo,
            destination: AnyView(BibleReaderView())
        )
        .stoneAwakening(isAwakened, delay: 0.6)
    }

    // MARK: - Feature Grid

    private var featureGrid: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Row 1
            HStack(spacing: Theme.Spacing.md) {
                RomanFeatureCard(
                    feature: .compline,
                    isPrimary: false,
                    accentColor: Color.accentBronze
                )
                .stoneAwakening(isAwakened, delay: 0.8)

                RomanFeatureCard(
                    feature: .prayersFromDeep,
                    isPrimary: false,
                    // DECORATIVE: Terracotta accent for visual variety in feature cards
                    accentColor: .terracottaRed
                )
                .stoneAwakening(isAwakened, delay: 0.9)
            }

            // Row 2
            HStack(spacing: Theme.Spacing.md) {
                RomanFeatureCard(
                    feature: .sermonRecording,
                    isPrimary: false,
                    accentColor: .lapisBlue
                )
                .stoneAwakening(isAwakened, delay: 1.0)

                RomanFeatureCard(
                    feature: .breathe,
                    isPrimary: false,
                    // DECORATIVE: Malachite green accent for breathe feature
                    accentColor: .malachiteGreen
                )
                .stoneAwakening(isAwakened, delay: 1.1)
            }
        }
    }
}

// MARK: - Roman Header Section
// Unified header using Surface layer colors

struct RomanHeaderSection: View {
    let userName: String?
    let currentStreak: Int
    let isAwakened: Bool
    let settingsAction: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center) {
            // Greeting
            greetingText
                .stoneAwakening(isAwakened, delay: 0.1)

            Spacer()

            // Settings button
            settingsButton
                .opacity(isAwakened ? 1 : 0)
                // swiftlint:disable:next hardcoded_animation_ease
                .animation(.easeOut(duration: 0.4).delay(0.3), value: isAwakened)

            // Streak badge
            streakBadge
                .opacity(isAwakened ? 1 : 0)
                // swiftlint:disable:next hardcoded_animation_ease
                .animation(.easeOut(duration: 0.4).delay(0.4), value: isAwakened)
        }
    }

    // MARK: - Greeting Text

    private var greetingText: some View {
        Text("Welcome, \(userName ?? "friend")")
            .font(Typography.Scripture.heading)
            .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
    }

    // MARK: - Settings Button

    private var settingsButton: some View {
        Button(action: settingsAction) {
            Image(systemName: "gearshape")
                // swiftlint:disable:next hardcoded_font_system
                .font(Typography.Icon.base.weight(.regular))
                .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.strong))
        }
    }

    // MARK: - Streak Badge

    private var streakBadge: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "flame.fill")
                // swiftlint:disable:next hardcoded_font_system
                .font(Typography.Command.caption.weight(.semibold))
                .foregroundStyle(Color.accentBronze)
            Text("\(currentStreak)")
                // swiftlint:disable:next hardcoded_font_system
                .font(Typography.Command.caption.weight(.bold))
                .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
        }
        .padding(.horizontal, Theme.Spacing.md - 2)
        .padding(.vertical, Theme.Spacing.xs + 2)
        .background(streakBackground)
        .overlay(
            Capsule()
                // swiftlint:disable:next hardcoded_line_width
                .stroke(Color.accentBronze.opacity(Theme.Opacity.medium), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private var streakBackground: some View {
        if colorScheme == .dark {
            Capsule()
                .fill(Color.accentBronze.opacity(Theme.Opacity.lightMedium))
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
        }
    }
}

// MARK: - Roman Verse Section
// Daily wisdom verse with stoic presentation

struct RomanVerseSection: View {
    let isAwakened: Bool
    @Environment(\.colorScheme) private var colorScheme

    // Sample verse - would come from DailyVerseService in production
    private let verseText = "\"Be still, and know that I am God.\""
    private let verseReference = "Psalm 46:10"

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Decorative divider
            HStack(spacing: Theme.Spacing.md) {
                Rectangle()
                    .fill(Color.accentBronze.opacity(Theme.Opacity.disabled))
                    .frame(width: 40, height: 1)
                Image(systemName: "laurel.leading")
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.strong))
                Image(systemName: "laurel.trailing")
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.strong))
                Rectangle()
                    .fill(Color.accentBronze.opacity(Theme.Opacity.disabled))
                    .frame(width: 40, height: 1)
            }
            .stoneAwakening(isAwakened, delay: 0.2)

            // Verse text
            Text(verseText)
                // swiftlint:disable:next hardcoded_font_custom
                .font(.custom("CormorantGaramond-Italic", size: 22))
                .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, Theme.Spacing.xxl)
                .stoneAwakening(isAwakened, delay: 0.3)

            // Reference
            Text(verseReference)
                .font(Typography.Command.meta)
                .tracking(Typography.Label.tracking)
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.pressed))
                .stoneAwakening(isAwakened, delay: 0.4)
        }
    }
}

// MARK: - Roman Feature Card
// Card component that uses the Roman card style from Surface layer

struct RomanFeatureCard: View {
    let feature: AIFeature?
    let icon: String
    let label: String
    let title: String
    let subtitle: String
    let isPrimary: Bool
    let accentColor: Color
    let destination: AnyView?

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    // AIFeature-based initializer
    init(
        feature: AIFeature,
        isPrimary: Bool,
        accentColor: Color
    ) {
        self.feature = feature
        self.icon = feature.icon
        self.label = feature.cardLabel
        self.title = feature.cardTitle
        self.subtitle = feature.cardSubtitle
        self.isPrimary = isPrimary
        self.accentColor = accentColor
        self.destination = nil
    }

    // Custom content initializer
    init(
        icon: String,
        label: String,
        title: String,
        subtitle: String,
        isPrimary: Bool,
        accentColor: Color,
        destination: AnyView
    ) {
        self.feature = nil
        self.icon = icon
        self.label = label
        self.title = title
        self.subtitle = subtitle
        self.isPrimary = isPrimary
        self.accentColor = accentColor
        self.destination = destination
    }

    private var style: CardStyle {
        CardStyle.roman(isPrimary: isPrimary, colorScheme: colorScheme)
    }

    var body: some View {
        Group {
            if let feature = feature {
                NavigationLink(destination: feature.destinationView) {
                    cardContent
                }
            } else if let destination = destination {
                NavigationLink(destination: destination) {
                    cardContent
                }
            } else {
                cardContent
            }
        }
        .buttonStyle(ImperialButtonStyle())
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: isPrimary ? Theme.Spacing.md : Theme.Spacing.sm) {
            // Header
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: style.iconSize, weight: .medium))
                    .foregroundStyle(accentColor)

                Text(label)
                    .font(style.labelFont)
                    .tracking(3)
                    .foregroundStyle(accentColor)
            }

            // Title
            Text(title)
                .font(style.titleFont)
                .foregroundStyle(style.textColor)
                .lineLimit(2)

            // Subtitle
            Text(subtitle)
                .font(style.subtitleFont)
                .foregroundStyle(style.secondaryTextColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(style.padding)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(
            color: accentColor.opacity(style.shadowOpacity),
            radius: style.shadowRadius,
            y: 6
        )
    }

    // MARK: - Background

    @ViewBuilder
    private var cardBackground: some View {
        if style.useMaterial {
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: style.cornerRadius)
                        .fill(style.backgroundColor.opacity(style.backgroundOpacity))
                )
        } else {
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .fill(style.backgroundColor.opacity(style.backgroundOpacity))
        }
    }

    // MARK: - Border

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: style.cornerRadius)
            .stroke(
                LinearGradient(
                    colors: style.borderGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: style.borderWidth
            )
    }
}

// MARK: - Preview

#Preview("Roman Sanctuary - Light") {
    NavigationStack {
        RomanSanctuaryView()
            .environment(SanctuaryViewModel())
            .environment(AppState())
    }
}

#Preview("Roman Sanctuary - Dark") {
    NavigationStack {
        RomanSanctuaryView()
            .environment(SanctuaryViewModel())
            .environment(AppState())
    }
    .preferredColorScheme(.dark)
}

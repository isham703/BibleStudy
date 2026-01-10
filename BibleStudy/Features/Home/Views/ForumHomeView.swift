import SwiftUI

// MARK: - Forum Home View
// Production home view adapted from The Forum showcase design
// Clean, centered layout inspired by Roman public gathering spaces
// Design: Prominent wisdom quote, minimal navigation, generous whitespace

struct ForumHomeView: View {
    @State private var isAwakened = false
    @Environment(SanctuaryViewModel.self) private var viewModel
    @Environment(\.settingsAction) private var settingsAction
    @Environment(\.colorScheme) private var colorScheme

    // Daily verse (hardcoded for now)
    private let dailyVerse = (
        text: "Your word is a lamp for my feet, a light on my path.",
        reference: "Psalm 119:105"
    )

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Spacer for visual breathing room
                    Spacer()
                        // swiftlint:disable:next hardcoded_frame_size
                        .frame(height: 60)

                    // Greeting section with settings button
                    greetingSection
                        // swiftlint:disable:next hardcoded_padding_edge
                        .padding(.bottom, 48)

                    // Central wisdom quote (hero)
                    wisdomQuoteSection
                        .padding(.horizontal, Theme.Spacing.xl)
                        // swiftlint:disable:next hardcoded_padding_edge
                        .padding(.bottom, 56)

                    // Ornamental divider
                    forumDivider
                        // swiftlint:disable:next hardcoded_padding_edge
                        .padding(.bottom, 48)

                    // Feature pillars (primary)
                    featurePillars
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xxl)

                    // Secondary features row
                    secondaryFeatures
                        .padding(.horizontal, Theme.Spacing.lg)
                        // swiftlint:disable:next hardcoded_padding_edge
                        .padding(.bottom, 48)

                    // Bottom navigation prompt
                    continueReadingPrompt
                        .padding(.horizontal, Theme.Spacing.xl)
                        // swiftlint:disable:next hardcoded_padding_edge
                        .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
        }
    }

    // MARK: - Computed Properties

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = viewModel.userName ?? "Friend"

        switch hour {
        case 5..<12:
            return "Good morning, \(name)"
        case 12..<17:
            return "Good afternoon, \(name)"
        case 17..<21:
            return "Good evening, \(name)"
        default:
            return "Peace be with you, \(name)"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            // Base color
            Colors.Surface.background(for: ThemeMode.current(from: colorScheme))
                .ignoresSafeArea()

            // Subtle radial glow from center
            RadialGradient(
                colors: [
                    Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint / 2),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Top vignette (theme-aware)
            LinearGradient(
                colors: [
                    Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)).opacity(colorScheme == .dark ? Theme.Opacity.disabled : 0.08),
                    Color.clear,
                    Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)).opacity(colorScheme == .dark ? Theme.Opacity.lightMedium : 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Greeting Section

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Date
                Text(formattedDate.uppercased())
                    .font(Typography.Command.meta.weight(.medium))
                    // swiftlint:disable:next hardcoded_tracking
                    .tracking(3)
                    .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))

                // Greeting
                Text(greeting)
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 24, weight: .regular, design: .serif))
                    .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
            }

            Spacer()

            // Settings button
            Button {
                settingsAction()
            } label: {
                Image(systemName: "gearshape")
                    .font(Typography.Icon.lg.weight(.light))
                    .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .opacity(isAwakened ? 1 : 0)
        // swiftlint:disable:next hardcoded_offset
        .offset(y: isAwakened ? 0 : 10)
        .animation(Theme.Animation.slowFade.delay(0.1), value: isAwakened)
    }

    // MARK: - Wisdom Quote Section (Hero)

    private var wisdomQuoteSection: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Opening quotation mark
            Text("\u{201C}")
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 72, weight: .regular, design: .serif))
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary))
                // swiftlint:disable:next hardcoded_frame_size
                .frame(height: 40)

            // The quote
            Text(dailyVerse.text)
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 28, weight: .regular, design: .serif))
                .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
                .multilineTextAlignment(.center)
                // swiftlint:disable:next hardcoded_line_spacing
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)

            // Reference
            Text(dailyVerse.reference.uppercased())
                .font(Typography.Command.caption.weight(.medium))
                // swiftlint:disable:next hardcoded_tracking
                .tracking(3)
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
        }
        .padding(.vertical, Theme.Spacing.xxl)
        .padding(.horizontal, Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.input)
                .fill(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)).opacity(colorScheme == .dark ? Theme.Opacity.faint : 0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.input)
                .strokeBorder(
                    Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(colorScheme == .dark ? Theme.Opacity.lightMedium : 0.3),
                    lineWidth: Theme.Stroke.hairline
                )
        )
        .opacity(isAwakened ? 1 : 0)
        .scaleEffect(isAwakened ? 1 : 0.95)
        .animation(Theme.Animation.slowFade.delay(0.2), value: isAwakened)
    }

    // MARK: - Forum Divider

    private var forumDivider: some View {
        HStack(spacing: Theme.Spacing.lg) {
            Rectangle()
                .fill(Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)))
                // swiftlint:disable:next hardcoded_frame_size
                .frame(width: 60, height: Theme.Stroke.hairline)

            // Column icon
            Image(systemName: "building.columns")
                .font(Typography.Icon.sm.weight(.ultraLight))
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.disabled))

            Rectangle()
                .fill(Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)))
                // swiftlint:disable:next hardcoded_frame_size
                .frame(width: 60, height: Theme.Stroke.hairline)
        }
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.4), value: isAwakened)
    }

    // MARK: - Feature Pillars (Primary)

    private var featurePillars: some View {
        HStack(spacing: Theme.Spacing.md) {
            ForumPillar(
                icon: "book.fill",
                label: "Scripture",
                isAwakened: isAwakened,
                delay: 0.5
            ) {
                BibleReaderView()
            }

            ForumPillar(
                icon: "text.quote",
                label: "Reflect",
                isAwakened: isAwakened,
                delay: 0.6
            ) {
                AskTabView()
            }

            ForumPillar(
                icon: "hands.sparkles.fill",
                label: "Pray",
                isAwakened: isAwakened,
                delay: 0.7
            ) {
                PrayersFromDeepView()
            }
        }
    }

    // MARK: - Secondary Features

    private var secondaryFeatures: some View {
        HStack(spacing: Theme.Spacing.lg) {
            SecondaryFeatureButton(
                icon: "mic.fill",
                label: "Sermon",
                isAwakened: isAwakened,
                delay: 0.75
            ) {
                SermonView()
            }

            SecondaryFeatureButton(
                icon: "moon.stars.fill",
                label: "Compline",
                isAwakened: isAwakened,
                delay: 0.8
            ) {
                ComplineView()
            }

            SecondaryFeatureButton(
                icon: "wind",
                label: "Breathe",
                isAwakened: isAwakened,
                delay: 0.85
            ) {
                BreatheView()
            }
        }
    }

    // MARK: - Continue Reading Prompt

    private var continueReadingPrompt: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Progress indicator
            VStack(spacing: Theme.Spacing.sm) {
                Text("CONTINUE YOUR JOURNEY")
                    .font(Typography.Command.meta.weight(.medium))
                    // swiftlint:disable:next hardcoded_tracking
                    .tracking(2)
                    .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))

                Text("Gospel of John")
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                Text("Day 7 of 21")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)))
                        .frame(height: Theme.Stroke.control)

                    Rectangle()
                        .fill(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
                        .frame(width: geometry.size.width * 0.33, height: Theme.Stroke.control)
                }
            }
            .frame(height: Theme.Stroke.control)
            .padding(.horizontal, Theme.Spacing.xxl)

            // Continue button
            NavigationLink {
                BibleReaderView()
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Text("Continue Reading")
                        .font(Typography.Command.body.weight(.medium))

                    Image(systemName: "arrow.right")
                        .font(Typography.Command.caption.weight(.medium))
                }
                .foregroundStyle(Colors.Semantic.onAccentAction(for: ThemeMode.current(from: colorScheme)))
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.md)
                .background(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                .clipShape(Capsule())
            }
        }
        .opacity(isAwakened ? 1 : 0)
        // swiftlint:disable:next hardcoded_offset
        .offset(y: isAwakened ? 0 : 20)
        .animation(Theme.Animation.slowFade.delay(0.8), value: isAwakened)
    }
}

// MARK: - Forum Pillar Component (Primary)

private struct ForumPillar<Destination: View>: View {
    let icon: String
    let label: String
    let isAwakened: Bool
    let delay: Double
    @ViewBuilder let destination: () -> Destination
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            VStack(spacing: Theme.Spacing.md) {
                // Icon
                Image(systemName: icon)
                    .font(Typography.Icon.xl.weight(.light))
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.overlay))
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle), lineWidth: Theme.Stroke.hairline)
                    )

                // Label
                Text(label.uppercased())
                    .font(Typography.Command.meta.weight(.medium))
                    // swiftlint:disable:next hardcoded_tracking
                    .tracking(1.5)
                    .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .opacity(isAwakened ? 1 : 0)
        // swiftlint:disable:next hardcoded_offset
        .offset(y: isAwakened ? 0 : 15)
        .animation(Theme.Animation.slowFade.delay(delay), value: isAwakened)
    }
}

// MARK: - Secondary Feature Button

private struct SecondaryFeatureButton<Destination: View>: View {
    let icon: String
    let label: String
    let isAwakened: Bool
    let delay: Double
    @ViewBuilder let destination: () -> Destination
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            VStack(spacing: Theme.Spacing.xs) {
                // Smaller icon
                Image(systemName: icon)
                    .font(Typography.Icon.md.weight(.light))
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.heavy))
                    .frame(width: 32 + 8, height: 32 + 8)
                    .background(
                        Circle()
                            .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint))
                    )
                    .overlay(
                        Circle()
                            // swiftlint:disable:next hardcoded_line_width
                            .strokeBorder(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light), lineWidth: 0.5)
                    )

                // Smaller label
                Text(label.uppercased())
                    .font(Typography.Icon.xxs.weight(.medium))
                    // swiftlint:disable:next hardcoded_tracking
                    .tracking(1)
                    .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 10)
        .animation(Theme.Animation.settle.delay(delay), value: isAwakened)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ForumHomeView()
    }
    .environment(SanctuaryViewModel())
}

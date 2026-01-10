import SwiftUI

// MARK: - The Threshold Page
// Awakening design using the Dawn palette
// Design: Soft lavender and coral gradients, hopeful atmosphere, new beginnings
// Theme Tokens: dawnLavender, dawnSunrise, dawnSlate, dawnCoral, dawnRosePink, dawnFrost, dawnPeriwinkle

struct TheThresholdPage: View {
    @State private var isAwakened = false
    @State private var sunriseGlow = false
    @Environment(\.dismiss) private var dismiss

    // Mock data
    private let greeting = SanctuaryMockData.fullGreeting
    private let dailyVerse = SanctuaryMockData.dailyVerse
    private let activePlan = SanctuaryMockData.activePlan
    private let practiceData = SanctuaryMockData.practiceData

    var body: some View {
        ZStack {
            // Dawn background
            backgroundLayer

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Sunrise header
                    headerSection
                        .padding(.top, 50)
                        .padding(.bottom, Theme.Spacing.xxl)

                    // Morning intention card
                    morningIntentionCard
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Horizon divider
                    horizonLine
                        .padding(.bottom, Theme.Spacing.xl)

                    // Daily path section
                    dailyPathSection
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Hope verse
                    hopeVerseSection
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 100)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(Typography.Icon.sm)
                        Text("Back")
                            .font(Typography.Command.callout)
                    }
                    .foregroundStyle(Color.dawnCoral.opacity(Theme.Opacity.high))
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                // Sunrise time
                HStack(spacing: 4) {
                    Image(systemName: "sunrise.fill")
                        .font(Typography.Command.caption)
                    Text("6:42 AM")
                        .font(Typography.Icon.xxs.weight(.medium))
                }
                .foregroundStyle(Color.dawnSunrise.opacity(Theme.Opacity.heavy))
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
            withAnimation(
                .easeInOut(duration: 4)
                .repeatForever(autoreverses: true)
            ) {
                sunriseGlow = true
            }
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            // Deep slate base
            Color.dawnSlate
                .ignoresSafeArea()

            // Dawn sky gradient
            LinearGradient(
                colors: [
                    Color.dawnPeriwinkle.opacity(Theme.Opacity.subtle),
                    Color.dawnLavender.opacity(Theme.Opacity.light),
                    Color.dawnSlate
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            // Sunrise glow from bottom
            RadialGradient(
                colors: [
                    Color.dawnSunrise.opacity(sunriseGlow ? 0.15 : 0.1),
                    Color.dawnCoral.opacity(sunriseGlow ? 0.08 : 0.05),
                    Color.dawnRosePink.opacity(Theme.Opacity.faint),
                    Color.clear
                ],
                center: .bottom,
                startRadius: 0,
                endRadius: 450
            )
            .ignoresSafeArea()

            // Frost overlay at top
            LinearGradient(
                colors: [
                    Color.dawnFrost.opacity(Theme.Opacity.faint),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Sunrise icon with rays
            ZStack {
                // Rays
                ForEach(0..<8, id: \.self) { index in
                    Rectangle()
                        .fill(Color.dawnSunrise.opacity(sunriseGlow ? 0.3 : 0.2))
                        .frame(width: 2, height: 20)
                        .offset(y: -50)
                        .rotationEffect(.degrees(Double(index) * 45))
                }

                // Sun circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.dawnSunrise,
                                Color.dawnCoral
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.dawnSunrise.opacity(Theme.Opacity.medium), radius: 20)
            }
            .frame(height: 120)

            // Morning greeting
            VStack(spacing: Theme.Spacing.xs) {
                Text("New Day")
                    .font(.custom("CormorantGaramond-SemiBold", size: 36))
                    .foregroundStyle(Color.dawnFrost)

                Text("Cross the threshold with hope")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.dawnLavender.opacity(Theme.Opacity.pressed))
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .scaleEffect(isAwakened ? 1 : 0.95)
        .animation(.easeOut(duration: 0.8).delay(0.1), value: isAwakened)
    }

    // MARK: - Morning Intention Card

    private var morningIntentionCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Header
            HStack {
                Text("MORNING INTENTION")
                    .font(Typography.Icon.xxs.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(Color.dawnSunrise)

                Spacer()

                // Day indicator
                Text("Day \(activePlan.currentDay)")
                    .font(Typography.Icon.xxs.weight(.medium))
                    .foregroundStyle(Color.dawnCoral.opacity(Theme.Opacity.heavy))
            }

            // Intention prompt
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("What is your intention for today?")
                    .font(.custom("CormorantGaramond-SemiBold", size: 22))
                    .foregroundStyle(Color.dawnFrost.opacity(Theme.Opacity.nearOpaque))

                Text("Set a purpose to guide your steps as the sun rises on new possibilities.")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.dawnLavender.opacity(Theme.Opacity.heavy))
                    .lineSpacing(4)
            }

            // Set intention button
            Button {
                // Set intention
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(Typography.Command.caption)
                    Text("Set Today's Intention")
                        .font(Typography.Icon.sm)
                    Spacer()
                }
                .foregroundStyle(Color.dawnSlate)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(
                            LinearGradient(
                                colors: [Color.dawnSunrise, Color.dawnCoral],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.dawnSlate.opacity(Theme.Opacity.tertiary))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.dawnSunrise.opacity(Theme.Opacity.lightMedium), Color.dawnRosePink.opacity(Theme.Opacity.light)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: isAwakened)
    }

    // MARK: - Horizon Line

    private var horizonLine: some View {
        ZStack {
            // Gradient line representing horizon
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.dawnRosePink.opacity(Theme.Opacity.subtle),
                            Color.dawnSunrise.opacity(Theme.Opacity.medium),
                            Color.dawnCoral.opacity(Theme.Opacity.medium),
                            Color.dawnSunrise.opacity(Theme.Opacity.medium),
                            Color.dawnRosePink.opacity(Theme.Opacity.subtle),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)

            // Small sun on horizon
            Circle()
                .fill(Color.dawnSunrise)
                .frame(width: 8, height: 8)
                .shadow(color: Color.dawnSunrise.opacity(Theme.Opacity.tertiary), radius: 4)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .opacity(isAwakened ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: isAwakened)
    }

    // MARK: - Daily Path Section

    private var dailyPathSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            Text("TODAY'S PATH")
                .font(Typography.Icon.xxs)
                .tracking(2)
                .foregroundStyle(Color.dawnSunrise.opacity(Theme.Opacity.tertiary))

            // Path steps
            VStack(spacing: 0) {
                ThresholdPathStep(
                    icon: "book.fill",
                    title: "Morning Reading",
                    subtitle: activePlan.todayReference,
                    isFirst: true,
                    isLast: false
                )

                ThresholdPathStep(
                    icon: "hands.sparkles.fill",
                    title: "Prayer",
                    subtitle: "Start with gratitude",
                    isFirst: false,
                    isLast: false
                )

                ThresholdPathStep(
                    icon: "brain.head.profile",
                    title: "Memorization",
                    subtitle: practiceData.dueCount > 0 ? "\(practiceData.dueCount) verses due" : "Review verses",
                    isFirst: false,
                    isLast: true
                )
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.5), value: isAwakened)
    }

    // MARK: - Hope Verse Section

    private var hopeVerseSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Quote marks
            HStack {
                Image(systemName: "quote.opening")
                    .font(Typography.Command.callout)
                    .foregroundStyle(Color.dawnSunrise.opacity(Theme.Opacity.lightMedium))

                Spacer()
            }

            // Verse
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(dailyVerse.text)
                    .font(.custom("CormorantGaramond-Italic", size: 20))
                    .foregroundStyle(Color.dawnFrost.opacity(Theme.Opacity.high))
                    .lineSpacing(6)

                HStack {
                    Rectangle()
                        .fill(Color.dawnSunrise.opacity(Theme.Opacity.tertiary))
                        .frame(width: 20, height: 2)

                    Text(dailyVerse.reference)
                        .font(.custom("CormorantGaramond-SemiBold", size: 13))
                        .foregroundStyle(Color.dawnCoral)
                }
            }

            // Theme tag
            HStack {
                Spacer()

                Text(dailyVerse.theme.uppercased())
                    .font(Typography.Icon.xxxs)
                    .tracking(1)
                    .foregroundStyle(Color.dawnLavender.opacity(Theme.Opacity.tertiary))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.dawnSunrise.opacity(Theme.Opacity.overlay))
                    )
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Color.dawnSlate.opacity(Theme.Opacity.lightMedium))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .strokeBorder(Color.dawnRosePink.opacity(Theme.Opacity.divider), lineWidth: 1)
        )
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.6), value: isAwakened)
    }
}

// MARK: - Threshold Path Step

private struct ThresholdPathStep: View {
    let icon: String
    let title: String
    let subtitle: String
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Path line and circle
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(Color.dawnSunrise.opacity(Theme.Opacity.subtle))
                        .frame(width: 2, height: 12)
                }

                Circle()
                    .fill(Color.dawnSunrise.opacity(Theme.Opacity.pressed))
                    .frame(width: 10, height: 10)

                if !isLast {
                    Rectangle()
                        .fill(Color.dawnSunrise.opacity(Theme.Opacity.subtle))
                        .frame(width: 2, height: 32)
                }
            }

            // Content card
            Button {
                // Action
            } label: {
                HStack {
                    Image(systemName: icon)
                        .font(Typography.Icon.md.weight(.light))
                        .foregroundStyle(Color.dawnSunrise)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(Typography.Icon.sm)
                            .foregroundStyle(Color.dawnFrost.opacity(Theme.Opacity.high))

                        Text(subtitle)
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color.dawnLavender.opacity(Theme.Opacity.tertiary))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(Typography.Icon.xxs)
                        .foregroundStyle(Color.dawnCoral.opacity(Theme.Opacity.medium))
                }
                .padding(Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .fill(Color.dawnSunrise.opacity(Theme.Opacity.faint))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .strokeBorder(Color.dawnSunrise.opacity(Theme.Opacity.divider), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TheThresholdPage()
    }
}

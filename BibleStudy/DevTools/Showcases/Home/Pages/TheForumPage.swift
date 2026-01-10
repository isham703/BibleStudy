import SwiftUI

// MARK: - The Forum Page
// Clean, centered layout inspired by Roman public gathering spaces
// Design: Prominent wisdom quote, minimal navigation, generous whitespace

struct TheForumPage: View {
    @State private var isAwakened = false
    @Environment(\.dismiss) private var dismiss

    // Mock data
    private let greeting = SanctuaryMockData.fullGreeting
    private let dailyVerse = SanctuaryMockData.dailyVerse
    private let userData = SanctuaryMockData.userData

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Spacer for visual breathing room
                    Spacer()
                        .frame(height: 60)

                    // Greeting section
                    greetingSection
                        .padding(.bottom, 48)

                    // Central wisdom quote (hero)
                    wisdomQuoteSection
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.bottom, 56)

                    // Ornamental divider
                    forumDivider
                        .padding(.bottom, 48)

                    // Feature pillars
                    featurePillars
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 48)

                    // Bottom navigation prompt
                    continueReadingPrompt
                        .padding(.horizontal, Theme.Spacing.xl)
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
                    .foregroundStyle(Color.decorativeTaupe)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            // Base color
            Color(hex: "0F0E0D")
                .ignoresSafeArea()

            // Subtle radial glow from center
            RadialGradient(
                colors: [
                    Color.decorativeTaupe.opacity(Theme.Opacity.faint),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Top vignette
            LinearGradient(
                colors: [
                    Color.black.opacity(Theme.Opacity.lightMedium),
                    Color.clear,
                    Color.black.opacity(Theme.Opacity.light)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Greeting Section

    private var greetingSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Date
            Text(SanctuaryMockData.formattedDate.uppercased())
                .font(Typography.Icon.xxs.weight(.medium))
                .tracking(3)
                .foregroundStyle(Color.decorativeTaupe.opacity(Theme.Opacity.tertiary))

            // Greeting
            Text(greeting)
                .font(.custom("CormorantGaramond-Regular", size: 24))
                .foregroundStyle(Color.decorativeMarble)
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 10)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: isAwakened)
    }

    // MARK: - Wisdom Quote Section (Hero)

    private var wisdomQuoteSection: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Opening quotation mark
            Text("\u{201C}")
                .font(.custom("CormorantGaramond-Regular", size: 72))
                .foregroundStyle(Color.decorativeTaupe.opacity(Theme.Opacity.subtle))
                .frame(height: 40)

            // The quote
            Text(dailyVerse.text)
                .font(.custom("CormorantGaramond-Regular", size: 28))
                .foregroundStyle(Color(hex: "F5F0E8"))
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)

            // Reference
            Text(dailyVerse.reference.uppercased())
                .font(Typography.Icon.xs)
                .tracking(3)
                .foregroundStyle(Color.decorativeTaupe)
        }
        .padding(.vertical, Theme.Spacing.xxl)
        .padding(.horizontal, Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.xs)
                .fill(Color.white.opacity(Theme.Opacity.faint))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.xs)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.decorativeTaupe.opacity(Theme.Opacity.light),
                            Color.decorativeTaupe.opacity(Theme.Opacity.faint)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .opacity(isAwakened ? 1 : 0)
        .scaleEffect(isAwakened ? 1 : 0.95)
        .animation(.easeOut(duration: 0.7).delay(0.2), value: isAwakened)
    }

    // MARK: - Forum Divider

    private var forumDivider: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.decorativeTaupe.opacity(Theme.Opacity.light))
                .frame(width: 60, height: 1)

            // Column icon
            Image(systemName: "building.columns")
                .font(Typography.Icon.sm.weight(.ultraLight))
                .foregroundStyle(Color.decorativeTaupe.opacity(Theme.Opacity.lightMedium))

            Rectangle()
                .fill(Color.decorativeTaupe.opacity(Theme.Opacity.light))
                .frame(width: 60, height: 1)
        }
        .opacity(isAwakened ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: isAwakened)
    }

    // MARK: - Feature Pillars

    private var featurePillars: some View {
        HStack(spacing: Theme.Spacing.md) {
            ForumPillar(
                icon: "book.fill",
                label: "Scripture",
                isAwakened: isAwakened,
                delay: 0.5
            )

            ForumPillar(
                icon: "text.quote",
                label: "Reflect",
                isAwakened: isAwakened,
                delay: 0.6
            )

            ForumPillar(
                icon: "hands.sparkles.fill",
                label: "Pray",
                isAwakened: isAwakened,
                delay: 0.7
            )
        }
    }

    // MARK: - Continue Reading Prompt

    private var continueReadingPrompt: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Progress indicator
            VStack(spacing: Theme.Spacing.sm) {
                Text("CONTINUE YOUR JOURNEY")
                    .font(Typography.Icon.xxs)
                    .tracking(2)
                    .foregroundStyle(Color.decorativeTaupe.opacity(Theme.Opacity.tertiary))

                Text("Gospel of John")
                    .font(.custom("CormorantGaramond-SemiBold", size: 20))
                    .foregroundStyle(Color.decorativeMarble)

                Text("Day \(SanctuaryMockData.activePlan.currentDay) of \(SanctuaryMockData.activePlan.totalDays)")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color.decorativeTaupe.opacity(Theme.Opacity.pressed))
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.decorativeTaupe.opacity(Theme.Opacity.divider))
                        .frame(height: 2)

                    Rectangle()
                        .fill(Color.decorativeTaupe.opacity(Theme.Opacity.medium))
                        .frame(width: geometry.size.width * SanctuaryMockData.activePlan.progress, height: 2)
                }
            }
            .frame(height: 2)
            .padding(.horizontal, Theme.Spacing.xxl)

            // Continue button
            Button {
                // Action
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Text("Continue Reading")
                        .font(Typography.Command.label)

                    Image(systemName: "arrow.right")
                        .font(Typography.Command.meta)
                }
                .foregroundStyle(Color(hex: "0F0E0D"))
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.md)
                .background(Color.decorativeTaupe)
                .clipShape(Capsule())
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.8), value: isAwakened)
    }
}

// MARK: - Forum Pillar Component

private struct ForumPillar: View {
    let icon: String
    let label: String
    let isAwakened: Bool
    let delay: Double

    var body: some View {
        Button {
            // Action
        } label: {
            VStack(spacing: Theme.Spacing.md) {
                // Icon
                Image(systemName: icon)
                    .font(Typography.Icon.lg.weight(.light))
                    .foregroundStyle(Color.decorativeTaupe.opacity(Theme.Opacity.heavy))
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(Theme.Opacity.faint))
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.decorativeTaupe.opacity(Theme.Opacity.divider), lineWidth: 1)
                    )

                // Label
                Text(label.uppercased())
                    .font(Typography.Icon.xxs)
                    .tracking(1.5)
                    .foregroundStyle(Color.decorativeTaupe.opacity(Theme.Opacity.tertiary))
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(delay), value: isAwakened)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TheForumPage()
    }
}

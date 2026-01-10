import SwiftUI

// MARK: - The Vigil Page
// Contemplative design using the Vespers palette
// Design: Deep indigo twilight, amber accents, evening devotion atmosphere
// Theme Tokens: vespersIndigo, vespersAmber, vespersSky, vespersText, vespersPurple, vespersGoldAccent

struct TheVigilPage: View {
    @State private var isAwakened = false
    @State private var starTwinkle = false
    @Environment(\.dismiss) private var dismiss

    // Mock data
    private let greeting = SanctuaryMockData.fullGreeting
    private let dailyVerse = SanctuaryMockData.dailyVerse
    private let practiceData = SanctuaryMockData.practiceData

    var body: some View {
        ZStack {
            // Twilight background
            backgroundLayer

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Evening header with stars
                    headerSection
                        .padding(.top, 50)
                        .padding(.bottom, Theme.Spacing.xxl)

                    // Compline invitation (main focus)
                    complineCard
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Horizon divider
                    horizonDivider
                        .padding(.bottom, Theme.Spacing.xl)

                    // Evening practices
                    eveningPractices
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Reflection prompt
                    reflectionPrompt
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
                    .foregroundStyle(Color.vespersAmber.opacity(Theme.Opacity.pressed))
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                // Moon phase indicator
                Image(systemName: "moon.fill")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.vespersGoldAccent.opacity(Theme.Opacity.tertiary))
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
            withAnimation(
                .easeInOut(duration: 2)
                .repeatForever(autoreverses: true)
            ) {
                starTwinkle = true
            }
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            // Deep indigo base
            Color.vespersIndigo
                .ignoresSafeArea()

            // Twilight sky gradient
            LinearGradient(
                colors: [
                    Color.vespersSky,
                    Color.vespersIndigo,
                    Color.vespersPurple.opacity(Theme.Opacity.medium)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Horizon glow
            RadialGradient(
                colors: [
                    Color.vespersAmber.opacity(Theme.Opacity.overlay),
                    Color.vespersOrange.opacity(Theme.Opacity.faint),
                    Color.clear
                ],
                center: .bottom,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Scattered stars
            StarsOverlay(twinkle: starTwinkle)
                .opacity(Theme.Opacity.tertiary)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Moon and stars icon
            ZStack {
                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.vespersGoldAccent.opacity(starTwinkle ? 0.2 : 0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "moon.stars.fill")
                    .font(Typography.Icon.hero.weight(.light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.vespersGoldAccent, Color.vespersAmber],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Evening greeting
            VStack(spacing: Theme.Spacing.xs) {
                Text("Good Evening")
                    .font(.custom("CormorantGaramond-SemiBold", size: 34))
                    .foregroundStyle(Color.vespersText)

                Text("Time for evening prayer")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.vespersText.opacity(Theme.Opacity.tertiary))
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .scaleEffect(isAwakened ? 1 : 0.95)
        .animation(.easeOut(duration: 0.7).delay(0.1), value: isAwakened)
    }

    // MARK: - Compline Card

    private var complineCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Header
            HStack {
                Text("COMPLINE")
                    .font(Typography.Icon.xxs.weight(.semibold))
                    .tracking(3)
                    .foregroundStyle(Color.vespersAmber)

                Spacer()

                Text("Night Prayer")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color.vespersText.opacity(Theme.Opacity.medium))
            }

            // Prayer text
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text(dailyVerse.text)
                    .font(.custom("CormorantGaramond-Italic", size: 22))
                    .foregroundStyle(Color.vespersText.opacity(Theme.Opacity.nearOpaque))
                    .lineSpacing(8)

                Text(dailyVerse.reference)
                    .font(.custom("CormorantGaramond-SemiBold", size: 14))
                    .foregroundStyle(Color.vespersAmber.opacity(Theme.Opacity.pressed))
            }

            // Begin button
            Button {
                // Begin compline
            } label: {
                HStack {
                    Spacer()
                    Text("Begin Evening Prayer")
                        .font(Typography.Icon.sm)
                    Image(systemName: "play.fill")
                        .font(Typography.Icon.xxs)
                    Spacer()
                }
                .foregroundStyle(Color.vespersIndigo)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(
                            LinearGradient(
                                colors: [Color.vespersAmber, Color.vespersGoldAccent],
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
                .fill(Color.vespersPurple.opacity(Theme.Opacity.subtle))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.vespersAmber.opacity(Theme.Opacity.lightMedium), Color.vespersPurple.opacity(Theme.Opacity.light)],
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

    // MARK: - Horizon Divider

    private var horizonDivider: some View {
        ZStack {
            // Horizon line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.vespersAmber.opacity(Theme.Opacity.lightMedium),
                            Color.vespersGoldAccent.opacity(Theme.Opacity.tertiary),
                            Color.vespersAmber.opacity(Theme.Opacity.lightMedium),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Center star
            Image(systemName: "sparkle")
                .font(Typography.Icon.xxs)
                .foregroundStyle(Color.vespersGoldAccent)
                .background(
                    Circle()
                        .fill(Color.vespersIndigo)
                        .frame(width: 24, height: 24)
                )
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .opacity(isAwakened ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: isAwakened)
    }

    // MARK: - Evening Practices

    private var eveningPractices: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Section header
            HStack {
                Text("EVENING PRACTICES")
                    .font(Typography.Icon.xxs)
                    .tracking(2)
                    .foregroundStyle(Color.vespersAmber.opacity(Theme.Opacity.tertiary))

                Spacer()
            }
            .padding(.bottom, Theme.Spacing.xs)

            // Practice cards
            HStack(spacing: Theme.Spacing.md) {
                VigilPracticeCard(
                    icon: "hands.sparkles.fill",
                    title: "Pray",
                    isActive: true
                )

                VigilPracticeCard(
                    icon: "book.fill",
                    title: "Read",
                    isActive: false
                )

                VigilPracticeCard(
                    icon: "heart.fill",
                    title: "Reflect",
                    isActive: false
                )
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.5), value: isAwakened)
    }

    // MARK: - Reflection Prompt

    private var reflectionPrompt: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.vespersAmber.opacity(Theme.Opacity.medium))

                Text("EVENING REFLECTION")
                    .font(Typography.Icon.xxs)
                    .tracking(2)
                    .foregroundStyle(Color.vespersText.opacity(Theme.Opacity.medium))
            }

            Text("What grace did you encounter today? Take a moment to give thanks before rest.")
                .font(.custom("CormorantGaramond-Regular", size: 18))
                .foregroundStyle(Color.vespersText.opacity(Theme.Opacity.pressed))
                .lineSpacing(4)

            // Journal prompt
            Button {
                // Open journal
            } label: {
                HStack {
                    Image(systemName: "pencil.line")
                        .font(Typography.Command.caption)
                    Text("Write a reflection")
                        .font(Typography.Command.meta)
                }
                .foregroundStyle(Color.vespersAmber.opacity(Theme.Opacity.pressed))
            }
            .padding(.top, Theme.Spacing.sm)
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Color.vespersPurple.opacity(Theme.Opacity.divider))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .strokeBorder(Color.vespersAmber.opacity(Theme.Opacity.divider), lineWidth: 1)
        )
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.6), value: isAwakened)
    }
}

// MARK: - Stars Overlay

private struct StarsOverlay: View {
    let twinkle: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<15, id: \.self) { index in
                    Circle()
                        .fill(Color.white)
                        .frame(width: starSize(for: index), height: starSize(for: index))
                        .position(
                            x: starX(for: index, in: geometry.size.width),
                            y: starY(for: index, in: geometry.size.height)
                        )
                        .opacity(twinkle ? starOpacity(for: index) : starOpacity(for: index) * 0.6)
                }
            }
        }
    }

    private func starSize(for index: Int) -> CGFloat {
        let sizes: [CGFloat] = [1.5, 2, 1, 2.5, 1.5, 2, 1, 1.5, 2, 1, 2.5, 1.5, 1, 2, 1.5]
        return sizes[index % sizes.count]
    }

    private func starX(for index: Int, in width: CGFloat) -> CGFloat {
        let positions: [CGFloat] = [0.1, 0.25, 0.4, 0.55, 0.7, 0.85, 0.15, 0.35, 0.5, 0.65, 0.8, 0.95, 0.2, 0.45, 0.75]
        return width * positions[index % positions.count]
    }

    private func starY(for index: Int, in height: CGFloat) -> CGFloat {
        let positions: [CGFloat] = [0.08, 0.15, 0.05, 0.2, 0.12, 0.08, 0.25, 0.1, 0.18, 0.06, 0.22, 0.14, 0.03, 0.16, 0.09]
        return height * positions[index % positions.count]
    }

    private func starOpacity(for index: Int) -> Double {
        let opacities: [Double] = [0.8, 0.6, 0.9, 0.5, 0.7, 0.85, 0.55, 0.75, 0.65, 0.9, 0.5, 0.8, 0.6, 0.7, 0.85]
        return opacities[index % opacities.count]
    }
}

// MARK: - Vigil Practice Card

private struct VigilPracticeCard: View {
    let icon: String
    let title: String
    let isActive: Bool

    var body: some View {
        Button {
            // Action
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(Typography.Icon.lg.weight(.light))
                    .foregroundStyle(isActive ? Color.vespersAmber : Color.vespersText.opacity(Theme.Opacity.medium))

                Text(title)
                    .font(Typography.Icon.xs)
                    .foregroundStyle(isActive ? Color.vespersText : Color.vespersText.opacity(Theme.Opacity.tertiary))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(isActive ? Color.vespersPurple.opacity(Theme.Opacity.subtle) : Color.vespersPurple.opacity(Theme.Opacity.divider))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .strokeBorder(
                        isActive ? Color.vespersAmber.opacity(Theme.Opacity.subtle) : Color.vespersPurple.opacity(Theme.Opacity.light),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TheVigilPage()
    }
}

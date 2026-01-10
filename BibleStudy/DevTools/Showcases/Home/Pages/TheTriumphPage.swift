import SwiftUI

// MARK: - The Triumph Page
// Victorious design inspired by Roman triumphal arches
// Design: Laurel wreaths, eagles, crosses as scepters, divine legacy
// Theme Tokens: laurelGold, forumNight, shadowStone, imperialPurple, moonlitMarble
// Philosophy: Spiritual conquest, divine victory, triumph of faith

struct TheTriumphPage: View {
    @State private var isAwakened = false
    @State private var victoryGlow = false
    @Environment(\.dismiss) private var dismiss

    // Mock data
    private let greeting = SanctuaryMockData.fullGreeting
    private let dailyVerse = SanctuaryMockData.dailyVerse
    private let activePlan = SanctuaryMockData.activePlan

    var body: some View {
        ZStack {
            // Triumphal background
            backgroundLayer

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Triumphal arch header
                    triumphalArchHeader
                        .padding(.top, 40)
                        .padding(.bottom, Theme.Spacing.xxl)

                    // Victory proclamation card
                    victoryProclamationCard
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Laurel wreath divider
                    laurelDivider
                        .padding(.bottom, Theme.Spacing.xl)

                    // Spiritual conquests grid
                    conquestsGrid
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Divine legacy section
                    divineLegacySection
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
                    .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.pressed))
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                // Eagle emblem
                Image(systemName: "bird.fill")
                    .font(Typography.Command.callout)
                    .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.heavy))
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                victoryGlow = true
            }
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            // Forum night base
            Color.surfaceInk
                .ignoresSafeArea()

            // Triumphal golden rays from center
            RadialGradient(
                colors: [
                    Color.accentBronze.opacity(victoryGlow ? 0.12 : 0.08),
                    Color.accentBronze.opacity(Theme.Opacity.faint),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Imperial purple undertone
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.accentIndigo.opacity(Theme.Opacity.overlay),
                    Color.surfaceMedium.opacity(Theme.Opacity.light)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Vignette for drama
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(Theme.Opacity.medium)
                ],
                center: .center,
                startRadius: 150,
                endRadius: 500
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Triumphal Arch Header

    private var triumphalArchHeader: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Triumphal arch with cross
            ZStack {
                // Arch structure
                TriumphalArchShape()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentBronze.opacity(Theme.Opacity.light), Color.accentBronze.opacity(Theme.Opacity.overlay)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 180, height: 120)
                    .overlay(
                        TriumphalArchShape()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.accentBronze.opacity(Theme.Opacity.tertiary), Color.accentBronze.opacity(Theme.Opacity.subtle)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2
                            )
                    )

                // Cross as scepter in center
                VStack(spacing: 0) {
                    Image(systemName: "cross.fill")
                        .font(Typography.Icon.xxl.weight(.light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentBronze, Color.accentBronzeDark],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.accentBronze.opacity(Theme.Opacity.medium), radius: 10)
                }
                .offset(y: 10)

                // Eagles flanking
                HStack {
                    Image(systemName: "bird.fill")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.medium))
                        .rotationEffect(.degrees(-15))
                        .offset(x: -60, y: -30)

                    Spacer()

                    Image(systemName: "bird.fill")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.medium))
                        .rotationEffect(.degrees(15))
                        .scaleEffect(x: -1, y: 1)
                        .offset(x: 60, y: -30)
                }
                .frame(width: 200)
            }
            .frame(height: 140)

            // Victory greeting
            VStack(spacing: Theme.Spacing.xs) {
                Text("TRIUMPHUS")
                    .font(Typography.Icon.xxs.weight(.bold))
                    .tracking(6)
                    .foregroundStyle(Color.accentBronze)

                Text("Victory Awaits")
                    .font(.custom("CormorantGaramond-SemiBold", size: 34))
                    .foregroundStyle(Color.decorativeMarble)

                Text("Conquer through faith")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.stoicLightGray)
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .scaleEffect(isAwakened ? 1 : 0.95)
        .animation(.easeOut(duration: 0.8).delay(0.1), value: isAwakened)
    }

    // MARK: - Victory Proclamation Card

    private var victoryProclamationCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Laurel wreath header
            HStack {
                Image(systemName: "laurel.leading")
                    .font(Typography.Command.callout)
                    .foregroundStyle(Color.accentBronze)

                Text("TODAY'S VICTORY")
                    .font(Typography.Icon.xxs.weight(.bold))
                    .tracking(3)
                    .foregroundStyle(Color.accentBronze)

                Image(systemName: "laurel.trailing")
                    .font(Typography.Command.callout)
                    .foregroundStyle(Color.accentBronze)

                Spacer()
            }

            // Scripture proclamation
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text(dailyVerse.text)
                    .font(.custom("CormorantGaramond-SemiBold", size: 22))
                    .foregroundStyle(Color.decorativeMarble)
                    .lineSpacing(6)

                // Reference with triumph styling
                HStack {
                    Image(systemName: "seal.fill")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.heavy))

                    Text(dailyVerse.reference)
                        .font(.custom("CormorantGaramond-SemiBold", size: 14))
                        .foregroundStyle(Color.accentBronze)
                }
            }

            // Claim victory button
            Button {
                // Claim
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "crown.fill")
                        .font(Typography.Command.caption)
                    Text("Claim This Promise")
                        .font(Typography.Command.caption.weight(.semibold))
                    Spacer()
                }
                .foregroundStyle(Color.surfaceInk)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentBronze, Color.accentBronzeDark],
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
                .fill(Color.surfaceMedium.opacity(Theme.Opacity.lightMedium))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.accentBronze.opacity(Theme.Opacity.medium), Color.accentBronze.opacity(Theme.Opacity.light)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: isAwakened)
    }

    // MARK: - Laurel Divider

    private var laurelDivider: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Left laurel branch
            Image(systemName: "laurel.leading")
                .font(Typography.Command.title3)
                .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.medium))

            // Central wreath
            ZStack {
                Circle()
                    .stroke(Color.accentBronze.opacity(Theme.Opacity.subtle), lineWidth: 2)
                    .frame(width: 30, height: 30)

                Image(systemName: "star.fill")
                    .font(Typography.Icon.xxs)
                    .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.tertiary))
            }

            // Right laurel branch
            Image(systemName: "laurel.trailing")
                .font(Typography.Command.title3)
                .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.medium))
        }
        .opacity(isAwakened ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: isAwakened)
    }

    // MARK: - Conquests Grid

    private var conquestsGrid: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Section header
            HStack {
                Text("SPIRITUAL CONQUESTS")
                    .font(Typography.Icon.xxs)
                    .tracking(2)
                    .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.tertiary))

                Spacer()

                // Progress indicator
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(index < 3 ? Color.accentBronze : Color.accentBronze.opacity(Theme.Opacity.light))
                            .frame(width: 6, height: 6)
                    }
                }
            }

            // Conquest cards
            HStack(spacing: Theme.Spacing.md) {
                TriumphConquestCard(
                    icon: "book.fill",
                    title: "Scripture",
                    progress: 0.7,
                    streak: 12
                )

                TriumphConquestCard(
                    icon: "hands.sparkles.fill",
                    title: "Prayer",
                    progress: 0.5,
                    streak: 8
                )
            }

            HStack(spacing: Theme.Spacing.md) {
                TriumphConquestCard(
                    icon: "brain.head.profile",
                    title: "Memorize",
                    progress: 0.3,
                    streak: 5
                )

                TriumphConquestCard(
                    icon: "heart.fill",
                    title: "Service",
                    progress: 0.9,
                    streak: 15
                )
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.5), value: isAwakened)
    }

    // MARK: - Divine Legacy Section

    private var divineLegacySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header with eagle
            HStack {
                Image(systemName: "bird.fill")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.tertiary))

                Text("DIVINE LEGACY")
                    .font(Typography.Icon.xxs)
                    .tracking(2)
                    .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.tertiary))
            }

            // Legacy message
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("\"In all these things we are more than conquerors through him who loved us.\"")
                    .font(.custom("CormorantGaramond-Italic", size: 18))
                    .foregroundStyle(Color.decorativeMarble.opacity(Theme.Opacity.high))
                    .lineSpacing(4)

                Text("— ROMANS 8:37")
                    .font(Typography.Icon.xxs.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.heavy))
            }

            // Your legacy stats
            HStack(spacing: Theme.Spacing.xl) {
                VStack(spacing: 2) {
                    Text("142")
                        .font(Typography.Icon.lg.weight(.bold))
                        .foregroundStyle(Color.accentBronze)
                    Text("Days")
                        .font(Typography.Icon.xxs)
                        .foregroundStyle(Color.stoicLightGray)
                }

                VStack(spacing: 2) {
                    Text("28")
                        .font(Typography.Icon.lg.weight(.bold))
                        .foregroundStyle(Color.accentBronze)
                    Text("Chapters")
                        .font(Typography.Icon.xxs)
                        .foregroundStyle(Color.stoicLightGray)
                }

                VStack(spacing: 2) {
                    Text("12")
                        .font(Typography.Icon.lg.weight(.bold))
                        .foregroundStyle(Color.accentBronze)
                    Text("Victories")
                        .font(Typography.Icon.xxs)
                        .foregroundStyle(Color.stoicLightGray)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, Theme.Spacing.sm)
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Color.accentBronze.opacity(Theme.Opacity.faint))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .strokeBorder(Color.accentBronze.opacity(Theme.Opacity.light), lineWidth: 1)
        )
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.6), value: isAwakened)
    }
}

// MARK: - Triumphal Arch Shape

private struct TriumphalArchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let archWidth = width * 0.4
        let archHeight = height * 0.7
        let pillarWidth = (width - archWidth) / 2

        // Left pillar
        path.addRect(CGRect(x: 0, y: height * 0.2, width: pillarWidth, height: height * 0.8))

        // Right pillar
        path.addRect(CGRect(x: width - pillarWidth, y: height * 0.2, width: pillarWidth, height: height * 0.8))

        // Top beam
        path.addRect(CGRect(x: 0, y: 0, width: width, height: height * 0.2))

        // Arch opening (subtracting)
        let archPath = Path { p in
            p.move(to: CGPoint(x: pillarWidth, y: height))
            p.addLine(to: CGPoint(x: pillarWidth, y: height - archHeight + archWidth / 2))
            p.addArc(
                center: CGPoint(x: width / 2, y: height - archHeight + archWidth / 2),
                radius: archWidth / 2,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: false
            )
            p.addLine(to: CGPoint(x: width - pillarWidth, y: height))
            p.closeSubpath()
        }

        return path.subtracting(archPath)
    }
}

// MARK: - Triumph Conquest Card

private struct TriumphConquestCard: View {
    let icon: String
    let title: String
    let progress: Double
    let streak: Int

    var body: some View {
        Button {
            // Action
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                // Icon with crown for high progress
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(Typography.Icon.lg.weight(.light))
                        .foregroundStyle(Color.accentBronze)

                    if progress >= 0.8 {
                        Image(systemName: "crown.fill")
                            .font(Typography.Icon.xxxs)
                            .foregroundStyle(Color.accentBronze)
                            .offset(x: 8, y: -4)
                    }
                }

                Text(title)
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color.decorativeMarble.opacity(Theme.Opacity.high))

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.accentBronze.opacity(Theme.Opacity.divider))

                        Rectangle()
                            .fill(Color.accentBronze)
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 3)
                .clipShape(Capsule())

                // Streak
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(Typography.Icon.xxxs)
                    Text("\(streak)")
                        .font(Typography.Icon.xxs)
                }
                .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.heavy))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .padding(.horizontal, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color.surfaceMedium.opacity(Theme.Opacity.subtle))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .strokeBorder(Color.accentBronze.opacity(Theme.Opacity.light), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TheTriumphPage()
    }
}

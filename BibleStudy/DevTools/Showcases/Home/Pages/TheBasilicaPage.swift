import SwiftUI

// MARK: - The Basilica Page
// Grand imperial design inspired by Roman basilicas and Vatican architecture
// Design: Soaring columns, vaulted ceilings, imperial purple accents
// Theme Tokens: imperialPurple, forumNight, shadowStone, moonlitMarble, laurelGold
// Philosophy: Divine majesty, spiritual conquest, monumental scale

struct TheBasilicaPage: View {
    @State private var isAwakened = false
    @State private var columnGlow = false
    @Environment(\.dismiss) private var dismiss

    // Mock data
    private let greeting = SanctuaryMockData.fullGreeting
    private let dailyVerse = SanctuaryMockData.dailyVerse
    private let activePlan = SanctuaryMockData.activePlan

    var body: some View {
        ZStack {
            // Imperial background
            backgroundLayer

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Vaulted header with columns
                    vaultedHeader
                        .padding(.top, 40)
                        .padding(.bottom, Theme.Spacing.xxl)

                    // Sacred nave (main content area)
                    sacredNaveSection
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Columned divider
                    columnedDivider
                        .padding(.bottom, Theme.Spacing.xl)

                    // Imperial actions grid
                    imperialActionsGrid
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Marcus Aurelius wisdom
                    stoicWisdomSection
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
                    .foregroundStyle(Color.accentIndigo.opacity(Theme.Opacity.pressed))
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                // Imperial eagle
                Image(systemName: "bird.fill")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.tertiary))
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
            withAnimation(
                .easeInOut(duration: 3)
                .repeatForever(autoreverses: true)
            ) {
                columnGlow = true
            }
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            // Deep forum night base
            Color.surfaceInk
                .ignoresSafeArea()

            // Vaulted ceiling gradient
            LinearGradient(
                colors: [
                    Color.accentIndigo.opacity(Theme.Opacity.divider),
                    Color.surfaceInk,
                    Color.surfaceMedium.opacity(Theme.Opacity.subtle)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Column shadows on sides
            HStack {
                LinearGradient(
                    colors: [
                        Color.black.opacity(Theme.Opacity.lightMedium),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 60)

                Spacer()

                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(Theme.Opacity.lightMedium)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 60)
            }
            .ignoresSafeArea()

            // Central light shaft
            RadialGradient(
                colors: [
                    Color.decorativeMarble.opacity(columnGlow ? 0.08 : 0.05),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Vaulted Header

    private var vaultedHeader: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Decorative arch
            ZStack {
                // Arch outline
                ArchShape()
                    .stroke(
                        LinearGradient(
                            colors: [Color.accentIndigo.opacity(Theme.Opacity.medium), Color.accentBronze.opacity(Theme.Opacity.subtle)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 200, height: 100)

                // Central cross
                Image(systemName: "cross.fill")
                    .font(Typography.Icon.xl.weight(.light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentBronze, Color.accentBronze.opacity(Theme.Opacity.heavy)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: -10)
            }

            // Imperial greeting
            VStack(spacing: Theme.Spacing.xs) {
                Text("SANCTUM")
                    .font(Typography.Icon.xxs.weight(.semibold))
                    .tracking(6)
                    .foregroundStyle(Color.accentIndigo.opacity(Theme.Opacity.heavy))

                Text(greeting)
                    .font(.custom("CormorantGaramond-SemiBold", size: 34))
                    .foregroundStyle(Color.decorativeMarble)

                Text("Enter the basilica of your soul")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.stoicLightGray)
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .scaleEffect(isAwakened ? 1 : 0.95)
        .animation(.easeOut(duration: 0.8).delay(0.1), value: isAwakened)
    }

    // MARK: - Sacred Nave Section

    private var sacredNaveSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Section header with column ornaments
            HStack {
                // Left column
                ColumnOrnament()

                Text("TODAY'S SCRIPTURE")
                    .font(Typography.Icon.xxs.weight(.semibold))
                    .tracking(3)
                    .foregroundStyle(Color.accentIndigo)

                // Right column
                ColumnOrnament()
            }

            // Scripture in grand style
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text(dailyVerse.text)
                    .font(.custom("CormorantGaramond-Regular", size: 22))
                    .foregroundStyle(Color.decorativeMarble.opacity(Theme.Opacity.nearOpaque))
                    .lineSpacing(8)

                // Reference with imperial styling
                HStack {
                    Rectangle()
                        .fill(Color.accentIndigo)
                        .frame(width: 30, height: 2)

                    Text(dailyVerse.reference)
                        .font(.custom("CormorantGaramond-SemiBold", size: 14))
                        .foregroundStyle(Color.accentIndigo)

                    Rectangle()
                        .fill(Color.accentIndigo)
                        .frame(width: 30, height: 2)
                }
            }

            // Enter scripture button
            Button {
                // Enter
            } label: {
                HStack {
                    Spacer()
                    Text("Enter the Word")
                        .font(Typography.Icon.sm)
                    Image(systemName: "arrow.right")
                        .font(Typography.Command.caption)
                    Spacer()
                }
                .foregroundStyle(Color.decorativeMarble)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(Color.accentIndigo.opacity(Theme.Opacity.subtle))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .strokeBorder(Color.accentIndigo.opacity(Theme.Opacity.medium), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.surfaceMedium.opacity(Theme.Opacity.subtle))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.accentIndigo.opacity(Theme.Opacity.lightMedium), Color.accentBronze.opacity(Theme.Opacity.light)],
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

    // MARK: - Columned Divider

    private var columnedDivider: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Left column
            VStack(spacing: 2) {
                Rectangle()
                    .fill(Color.accentIndigo.opacity(Theme.Opacity.subtle))
                    .frame(width: 6, height: 4)
                Rectangle()
                    .fill(Color.accentIndigo.opacity(Theme.Opacity.light))
                    .frame(width: 4, height: 24)
                Rectangle()
                    .fill(Color.accentIndigo.opacity(Theme.Opacity.subtle))
                    .frame(width: 8, height: 4)
            }

            // Decorative line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.accentIndigo.opacity(Theme.Opacity.subtle),
                            Color.accentBronze.opacity(Theme.Opacity.lightMedium),
                            Color.accentIndigo.opacity(Theme.Opacity.subtle),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Right column
            VStack(spacing: 2) {
                Rectangle()
                    .fill(Color.accentIndigo.opacity(Theme.Opacity.subtle))
                    .frame(width: 6, height: 4)
                Rectangle()
                    .fill(Color.accentIndigo.opacity(Theme.Opacity.light))
                    .frame(width: 4, height: 24)
                Rectangle()
                    .fill(Color.accentIndigo.opacity(Theme.Opacity.subtle))
                    .frame(width: 8, height: 4)
            }
        }
        .padding(.horizontal, Theme.Spacing.xxl)
        .opacity(isAwakened ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: isAwakened)
    }

    // MARK: - Imperial Actions Grid

    private var imperialActionsGrid: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.md) {
                BasilicaActionCard(
                    icon: "book.fill",
                    title: "Read",
                    subtitle: "Daily lectio"
                )

                BasilicaActionCard(
                    icon: "hands.sparkles.fill",
                    title: "Pray",
                    subtitle: "Divine office"
                )
            }

            HStack(spacing: Theme.Spacing.md) {
                BasilicaActionCard(
                    icon: "brain.head.profile",
                    title: "Meditate",
                    subtitle: "Stoic practice"
                )

                BasilicaActionCard(
                    icon: "person.2.fill",
                    title: "Fellowship",
                    subtitle: "Ecclesia"
                )
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.5), value: isAwakened)
    }

    // MARK: - Stoic Wisdom Section

    private var stoicWisdomSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Laurel wreath header
            HStack {
                Image(systemName: "laurel.leading")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.tertiary))

                Text("STOIC WISDOM")
                    .font(Typography.Icon.xxs)
                    .tracking(2)
                    .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.tertiary))

                Image(systemName: "laurel.trailing")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.tertiary))
            }

            // Quote
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("\"Waste no more time arguing about what a good man should be. Be one.\"")
                    .font(.custom("CormorantGaramond-Italic", size: 18))
                    .foregroundStyle(Color.decorativeMarble.opacity(Theme.Opacity.strong))
                    .lineSpacing(4)

                Text("— MARCUS AURELIUS")
                    .font(Typography.Icon.xxs.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(Color.accentIndigo.opacity(Theme.Opacity.heavy))
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Color.accentIndigo.opacity(Theme.Opacity.overlay))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .strokeBorder(Color.accentBronze.opacity(Theme.Opacity.divider), lineWidth: 1)
        )
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.6), value: isAwakened)
    }
}

// MARK: - Arch Shape

private struct ArchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Start from bottom left
        path.move(to: CGPoint(x: 0, y: height))

        // Left side up
        path.addLine(to: CGPoint(x: 0, y: height * 0.4))

        // Arch curve
        path.addQuadCurve(
            to: CGPoint(x: width, y: height * 0.4),
            control: CGPoint(x: width / 2, y: -height * 0.2)
        )

        // Right side down
        path.addLine(to: CGPoint(x: width, y: height))

        return path
    }
}

// MARK: - Column Ornament

private struct ColumnOrnament: View {
    var body: some View {
        VStack(spacing: 1) {
            Rectangle()
                .fill(Color.accentIndigo.opacity(Theme.Opacity.lightMedium))
                .frame(width: 8, height: 2)
            Rectangle()
                .fill(Color.accentIndigo.opacity(Theme.Opacity.subtle))
                .frame(width: 4, height: 8)
            Rectangle()
                .fill(Color.accentIndigo.opacity(Theme.Opacity.lightMedium))
                .frame(width: 10, height: 2)
        }
    }
}

// MARK: - Basilica Action Card

private struct BasilicaActionCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        Button {
            // Action
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(Typography.Command.title3.weight(.light))
                    .foregroundStyle(Color.accentIndigo)

                VStack(spacing: 2) {
                    Text(title)
                        .font(Typography.Icon.sm)
                        .foregroundStyle(Color.decorativeMarble.opacity(Theme.Opacity.high))

                    Text(subtitle)
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.stoicLightGray)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color.accentIndigo.opacity(Theme.Opacity.overlay))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .strokeBorder(Color.accentIndigo.opacity(Theme.Opacity.light), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TheBasilicaPage()
    }
}

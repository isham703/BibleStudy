import SwiftUI

// MARK: - The Stoa Page
// Exaggerated minimalism inspired by the Stoa Poikile where Zeno taught
// Design: Deep navy blue, oversized typography, marble texture accents, bold simplicity

struct TheStoaPage: View {
    @State private var isAwakened = false
    @Environment(\.dismiss) private var dismiss

    // Mock data
    private let greeting = SanctuaryMockData.fullGreeting
    private let dailyVerse = SanctuaryMockData.dailyVerse
    private let activePlan = SanctuaryMockData.activePlan

    // Stoic Navy Palette
    private let stoicNavy = Color(hex: "1A2633")
    private let steelBlue = Color(hex: "5B7C99")
    private let marbleWhite = Color(hex: "F0EDE8")
    private let marbleGray = Color(hex: "C8C4BC")

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Generous top spacing
                    Spacer()
                        .frame(height: 80)

                    // Minimal greeting
                    minimalGreeting
                        .padding(.bottom, 60)

                    // Hero wisdom - exaggerated typography
                    heroWisdom
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 80)

                    // Marble divider
                    marbleDivider
                        .padding(.bottom, 60)

                    // Single virtue focus
                    virtueFocus
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.bottom, 60)

                    // Minimal actions
                    minimalActions
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 120)
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
                    .foregroundStyle(steelBlue.opacity(Theme.Opacity.pressed))
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
            // Deep navy base
            stoicNavy
                .ignoresSafeArea()

            // Subtle marble texture gradient
            LinearGradient(
                colors: [
                    marbleWhite.opacity(Theme.Opacity.faint),
                    Color.clear,
                    marbleGray.opacity(Theme.Opacity.faint),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Soft vignette
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(Theme.Opacity.lightMedium)
                ],
                center: .center,
                startRadius: 150,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Marble veining effect (subtle)
            GeometryReader { geometry in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geometry.size.height * 0.3))
                    path.addQuadCurve(
                        to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.4),
                        control: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.25)
                    )
                }
                .stroke(
                    LinearGradient(
                        colors: [
                            marbleGray.opacity(Theme.Opacity.faint),
                            marbleGray.opacity(Theme.Opacity.faint),
                            marbleGray.opacity(Theme.Opacity.faint)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Minimal Greeting

    private var minimalGreeting: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(SanctuaryMockData.formattedDate.uppercased())
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(4)
                .foregroundStyle(steelBlue.opacity(Theme.Opacity.medium))

            Text(greeting)
                .font(Typography.Icon.base.weight(.light))
                .foregroundStyle(marbleWhite.opacity(Theme.Opacity.heavy))
        }
        .opacity(isAwakened ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: isAwakened)
    }

    // MARK: - Hero Wisdom (Exaggerated Typography)

    private var heroWisdom: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            // The quote - massively oversized
            Text(dailyVerse.text)
                .font(.custom("CormorantGaramond-Light", size: 42))
                .foregroundStyle(marbleWhite)
                .multilineTextAlignment(.center)
                .lineSpacing(12)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Theme.Spacing.md)

            // Reference - stark contrast in size
            Text(dailyVerse.reference.uppercased())
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .tracking(6)
                .foregroundStyle(steelBlue)
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 20)
        .animation(.easeOut(duration: 0.8).delay(0.2), value: isAwakened)
    }

    // MARK: - Marble Divider

    private var marbleDivider: some View {
        HStack(spacing: 0) {
            // Left marble block
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            marbleGray.opacity(Theme.Opacity.overlay),
                            marbleWhite.opacity(Theme.Opacity.divider),
                            marbleGray.opacity(Theme.Opacity.overlay)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 60, height: 4)

            Spacer()

            // Center - single dot
            Circle()
                .fill(steelBlue.opacity(Theme.Opacity.lightMedium))
                .frame(width: 6, height: 6)

            Spacer()

            // Right marble block
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            marbleGray.opacity(Theme.Opacity.overlay),
                            marbleWhite.opacity(Theme.Opacity.divider),
                            marbleGray.opacity(Theme.Opacity.overlay)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 60, height: 4)
        }
        .padding(.horizontal, Theme.Spacing.xxl)
        .opacity(isAwakened ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.5), value: isAwakened)
    }

    // MARK: - Virtue Focus

    private var virtueFocus: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Today's virtue label
            Text("TODAY'S VIRTUE")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(3)
                .foregroundStyle(steelBlue.opacity(Theme.Opacity.medium))

            // The virtue - bold, single word
            Text("TEMPERANCE")
                .font(.custom("CormorantGaramond-Bold", size: 28))
                .tracking(8)
                .foregroundStyle(marbleWhite.opacity(Theme.Opacity.high))

            // Brief description
            Text("The practice of moderation in all things")
                .font(Typography.Icon.sm.weight(.light))
                .foregroundStyle(marbleGray.opacity(Theme.Opacity.tertiary))
                .multilineTextAlignment(.center)
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.6).delay(0.6), value: isAwakened)
    }

    // MARK: - Minimal Actions

    private var minimalActions: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Primary action - large, simple
            StoaActionButton(
                title: "Continue Reading",
                subtitle: activePlan.todayReference,
                accentColor: steelBlue,
                marbleWhite: marbleWhite,
                isPrimary: true
            )

            // Secondary actions - minimal row
            HStack(spacing: Theme.Spacing.md) {
                StoaActionButton(
                    title: "Reflect",
                    subtitle: nil,
                    accentColor: steelBlue,
                    marbleWhite: marbleWhite,
                    isPrimary: false
                )

                StoaActionButton(
                    title: "Pray",
                    subtitle: nil,
                    accentColor: steelBlue,
                    marbleWhite: marbleWhite,
                    isPrimary: false
                )
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.7), value: isAwakened)
    }
}

// MARK: - Stoa Action Button

private struct StoaActionButton: View {
    let title: String
    let subtitle: String?
    let accentColor: Color
    let marbleWhite: Color
    let isPrimary: Bool

    var body: some View {
        Button {
            // Action
        } label: {
            VStack(spacing: isPrimary ? Theme.Spacing.xs : 0) {
                Text(title.uppercased())
                    .font(.system(size: isPrimary ? 13 : 11, weight: .medium, design: .monospaced))
                    .tracking(isPrimary ? 3 : 2)
                    .foregroundStyle(isPrimary ? marbleWhite : marbleWhite.opacity(Theme.Opacity.heavy))

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Typography.Icon.xs.weight(.light))
                        .foregroundStyle(accentColor.opacity(Theme.Opacity.heavy))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, isPrimary ? Theme.Spacing.xl : Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                    .fill(accentColor.opacity(isPrimary ? 0.15 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                    .strokeBorder(accentColor.opacity(isPrimary ? 0.3 : 0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TheStoaPage()
    }
}

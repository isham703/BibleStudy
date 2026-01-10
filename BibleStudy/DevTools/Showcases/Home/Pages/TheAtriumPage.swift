import SwiftUI

// MARK: - The Atrium Page
// Inspired by the Roman house atrium with central impluvium
// Design: Light radiates from center, cards arranged radially, time-aware lighting

struct TheAtriumPage: View {
    @State private var isAwakened = false
    @State private var lightPulse = false
    @Environment(\.dismiss) private var dismiss

    // Mock data
    private let greeting = SanctuaryMockData.fullGreeting
    private let dailyVerse = SanctuaryMockData.dailyVerse
    private let activePlan = SanctuaryMockData.activePlan
    private let practiceData = SanctuaryMockData.practiceData

    // Atrium Palette
    private let warmBronze = Color(hex: "C9A959")
    private let atriumDark = Color(hex: "1E1A14")
    private let terracotta = Color(hex: "A67B5B")
    private let warmIvory = Color(hex: "F5EBE0")
    private let skyLight = Color(hex: "E8DED0")

    var body: some View {
        ZStack {
            // Background with central light
            backgroundLayer

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Central impluvium area (hero)
                    impluviumSection
                        .padding(.top, 40)
                        .padding(.bottom, 40)

                    // Radial feature arrangement
                    radialFeatures
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 32)

                    // Columns divider
                    columnsDivider
                        .padding(.bottom, 32)

                    // Daily wisdom card
                    wisdomCard
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 32)

                    // Journey progress
                    journeyProgress
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
                    .foregroundStyle(warmBronze.opacity(Theme.Opacity.pressed))
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                // Time indicator
                HStack(spacing: 6) {
                    Image(systemName: timeOfDayIcon)
                        .font(Typography.Command.caption)
                    Text(timeOfDayLabel)
                        .font(Typography.Icon.xs)
                }
                .foregroundStyle(warmBronze.opacity(Theme.Opacity.tertiary))
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
            // Start light pulse
            withAnimation(
                .easeInOut(duration: 4)
                .repeatForever(autoreverses: true)
            ) {
                lightPulse = true
            }
        }
    }

    // MARK: - Time of Day Helpers

    private var timeOfDayIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<8: return "sunrise.fill"
        case 8..<17: return "sun.max.fill"
        case 17..<20: return "sunset.fill"
        default: return "moon.stars.fill"
        }
    }

    private var timeOfDayLabel: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Midday"
        case 17..<21: return "Evening"
        default: return "Night"
        }
    }

    private var lightIntensity: Double {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<8: return 0.08
        case 8..<11: return 0.12
        case 11..<14: return 0.15
        case 14..<17: return 0.1
        case 17..<20: return 0.06
        default: return 0.03
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            // Dark base
            atriumDark
                .ignoresSafeArea()

            // Central skylight glow (compluvium)
            RadialGradient(
                colors: [
                    skyLight.opacity(lightPulse ? lightIntensity + 0.02 : lightIntensity),
                    warmBronze.opacity(Theme.Opacity.faint),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 450
            )
            .ignoresSafeArea()

            // Corner shadows (like room corners)
            LinearGradient(
                colors: [
                    Color.black.opacity(Theme.Opacity.subtle),
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(Theme.Opacity.subtle)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea()

            // Bottom shadow
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(Theme.Opacity.light)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Impluvium Section (Central Hero)

    private var impluviumSection: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Light rays indicator
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                warmBronze.opacity(lightPulse ? 0.2 : 0.15),
                                warmBronze.opacity(Theme.Opacity.faint),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                // Central pool (impluvium)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                skyLight.opacity(Theme.Opacity.divider),
                                warmBronze.opacity(Theme.Opacity.overlay)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .strokeBorder(warmBronze.opacity(Theme.Opacity.subtle), lineWidth: 1)
                    )

                // Reflection ripple
                Circle()
                    .strokeBorder(warmBronze.opacity(lightPulse ? 0.15 : 0.08), lineWidth: 1)
                    .frame(width: 100, height: 100)
                    .scaleEffect(lightPulse ? 1.1 : 1.0)
            }

            // Greeting
            VStack(spacing: Theme.Spacing.sm) {
                Text(greeting)
                    .font(.custom("CormorantGaramond-SemiBold", size: 28))
                    .foregroundStyle(warmIvory)

                Text(SanctuaryMockData.formattedDate)
                    .font(Typography.Command.meta)
                    .foregroundStyle(terracotta.opacity(Theme.Opacity.heavy))
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .scaleEffect(isAwakened ? 1 : 0.95)
        .animation(.easeOut(duration: 0.7).delay(0.1), value: isAwakened)
    }

    // MARK: - Radial Features

    private var radialFeatures: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Top row - 2 items
            HStack(spacing: Theme.Spacing.md) {
                AtriumFeatureCard(
                    icon: "book.fill",
                    title: "Scripture",
                    accentColor: warmBronze,
                    warmIvory: warmIvory
                )

                AtriumFeatureCard(
                    icon: "bubble.left.fill",
                    title: "Ask",
                    accentColor: warmBronze,
                    warmIvory: warmIvory
                )
            }

            // Bottom row - 2 items
            HStack(spacing: Theme.Spacing.md) {
                AtriumFeatureCard(
                    icon: "hands.sparkles.fill",
                    title: "Pray",
                    accentColor: warmBronze,
                    warmIvory: warmIvory
                )

                AtriumFeatureCard(
                    icon: "brain.head.profile",
                    title: "Memorize",
                    accentColor: warmBronze,
                    warmIvory: warmIvory
                )
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: isAwakened)
    }

    // MARK: - Columns Divider

    private var columnsDivider: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Column base left
            VStack(spacing: 4) {
                Rectangle()
                    .fill(warmBronze.opacity(Theme.Opacity.light))
                    .frame(width: 8, height: 20)

                Rectangle()
                    .fill(warmBronze.opacity(Theme.Opacity.divider))
                    .frame(width: 12, height: 4)
            }

            // Horizontal beam
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            warmBronze.opacity(Theme.Opacity.overlay),
                            warmBronze.opacity(Theme.Opacity.light),
                            warmBronze.opacity(Theme.Opacity.overlay)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)

            // Column base right
            VStack(spacing: 4) {
                Rectangle()
                    .fill(warmBronze.opacity(Theme.Opacity.light))
                    .frame(width: 8, height: 20)

                Rectangle()
                    .fill(warmBronze.opacity(Theme.Opacity.divider))
                    .frame(width: 12, height: 4)
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .opacity(isAwakened ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: isAwakened)
    }

    // MARK: - Wisdom Card

    private var wisdomCard: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Header
            HStack {
                Text("TODAY'S REFLECTION")
                    .font(Typography.Icon.xxs)
                    .tracking(2)
                    .foregroundStyle(warmBronze.opacity(Theme.Opacity.tertiary))

                Spacer()

                Text(dailyVerse.theme.uppercased())
                    .font(Typography.Icon.xxxs)
                    .tracking(1)
                    .foregroundStyle(terracotta.opacity(Theme.Opacity.medium))
            }

            // Quote
            Text(dailyVerse.text)
                .font(.custom("CormorantGaramond-Italic", size: 20))
                .foregroundStyle(warmIvory.opacity(Theme.Opacity.high))
                .multilineTextAlignment(.leading)
                .lineSpacing(6)

            // Reference and action
            HStack {
                Text(dailyVerse.reference)
                    .font(.custom("CormorantGaramond-SemiBold", size: 14))
                    .foregroundStyle(warmBronze)

                Spacer()

                Button {
                    // Dive deeper
                } label: {
                    HStack(spacing: 4) {
                        Text("Explore")
                            .font(Typography.Icon.xs)
                        Image(systemName: "arrow.right")
                            .font(Typography.Icon.xxs)
                    }
                    .foregroundStyle(warmBronze.opacity(Theme.Opacity.pressed))
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.input)
                .fill(warmBronze.opacity(Theme.Opacity.faint))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.input)
                .strokeBorder(warmBronze.opacity(Theme.Opacity.divider), lineWidth: 1)
        )
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.5), value: isAwakened)
    }

    // MARK: - Journey Progress

    private var journeyProgress: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(activePlan.title)
                        .font(.custom("CormorantGaramond-SemiBold", size: 18))
                        .foregroundStyle(warmIvory)

                    Text("Day \(activePlan.currentDay) of \(activePlan.totalDays)")
                        .font(Typography.Command.caption)
                        .foregroundStyle(terracotta.opacity(Theme.Opacity.tertiary))
                }

                Spacer()

                // Circular progress
                ZStack {
                    Circle()
                        .stroke(warmBronze.opacity(Theme.Opacity.divider), lineWidth: 3)

                    Circle()
                        .trim(from: 0, to: activePlan.progress)
                        .stroke(warmBronze, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(activePlan.progress * 100))%")
                        .font(Typography.Command.meta.weight(.semibold))
                        .foregroundStyle(warmBronze)
                }
                .frame(width: 44, height: 44)
            }

            // Continue button
            Button {
                // Continue
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Continue Reading")
                            .font(Typography.Icon.sm)
                            .foregroundStyle(warmIvory)

                        Text(activePlan.todayReference)
                            .font(Typography.Command.caption)
                            .foregroundStyle(terracotta.opacity(Theme.Opacity.heavy))
                    }

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .font(Typography.Icon.lg)
                        .foregroundStyle(warmBronze)
                }
                .padding(Theme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .fill(warmBronze.opacity(Theme.Opacity.overlay))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .strokeBorder(warmBronze.opacity(Theme.Opacity.light), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.6), value: isAwakened)
    }
}

// MARK: - Atrium Feature Card

private struct AtriumFeatureCard: View {
    let icon: String
    let title: String
    let accentColor: Color
    let warmIvory: Color

    var body: some View {
        Button {
            // Action
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(Typography.Command.title3.weight(.light))
                    .foregroundStyle(accentColor)

                Text(title)
                    .font(Typography.Command.meta)
                    .foregroundStyle(warmIvory.opacity(Theme.Opacity.pressed))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(accentColor.opacity(Theme.Opacity.faint))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .strokeBorder(accentColor.opacity(Theme.Opacity.divider), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TheAtriumPage()
    }
}

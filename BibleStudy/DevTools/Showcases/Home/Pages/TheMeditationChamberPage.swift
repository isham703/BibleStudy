import SwiftUI

// MARK: - The Meditation Chamber Page
// Dark, intimate design with warm amber accents like candlelight
// Design: Personal reflection, muted tones, contemplative atmosphere

struct TheMeditationChamberPage: View {
    @State private var isAwakened = false
    @State private var candleFlicker = false
    @Environment(\.dismiss) private var dismiss

    // Mock data
    private let greeting = SanctuaryMockData.fullGreeting
    private let dailyVerse = SanctuaryMockData.dailyVerse
    private let activePlan = SanctuaryMockData.activePlan
    private let insight = SanctuaryMockData.currentInsight

    // Candle amber color
    private let candleAmber = Color.accentBronze
    private let warmIvory = Color(hex: "F5EDE0")

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Candle glow area with greeting
                    candleHeader
                        .padding(.bottom, 40)

                    // Wisdom for meditation
                    meditationWisdom
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.bottom, 48)

                    // Reflection prompt
                    reflectionPrompt
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.bottom, 48)

                    // Gentle action buttons
                    contemplativeActions
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 48)

                    // Reading progress (subtle)
                    quietProgress
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
                    .foregroundStyle(candleAmber.opacity(Theme.Opacity.heavy))
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
            // Start candle flicker
            withAnimation(
                .easeInOut(duration: 2)
                .repeatForever(autoreverses: true)
            ) {
                candleFlicker = true
            }
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            // Deep dark base
            Color(hex: "0A0806")
                .ignoresSafeArea()

            // Warm amber glow from top (candle effect)
            RadialGradient(
                colors: [
                    candleAmber.opacity(candleFlicker ? 0.08 : 0.05),
                    candleAmber.opacity(Theme.Opacity.faint),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Subtle texture overlay
            LinearGradient(
                colors: [
                    Color.clear,
                    Color(hex: "1A1612").opacity(Theme.Opacity.subtle),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Candle Header

    private var candleHeader: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Candle flame representation
            VStack(spacing: 8) {
                // Flame
                ZStack {
                    // Outer glow
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    candleAmber.opacity(candleFlicker ? 0.4 : 0.3),
                                    candleAmber.opacity(Theme.Opacity.overlay),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(candleFlicker ? 1.1 : 1.0)

                    // Inner flame
                    Image(systemName: "flame.fill")
                        .font(Typography.Icon.xxl.weight(.light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [candleAmber, Color(hex: "F5C542")],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .scaleEffect(candleFlicker ? 1.05 : 0.95)
                }
                .padding(.top, 60)
            }

            // Time and greeting
            VStack(spacing: Theme.Spacing.sm) {
                Text(timeOfDayLabel.uppercased())
                    .font(Typography.Icon.xxs)
                    .tracking(3)
                    .foregroundStyle(candleAmber.opacity(Theme.Opacity.medium))

                Text(greeting)
                    .font(.custom("CormorantGaramond-Regular", size: 26))
                    .foregroundStyle(warmIvory)
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .animation(.easeOut(duration: 0.8).delay(0.1), value: isAwakened)
    }

    private var timeOfDayLabel: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning Meditation"
        case 12..<17: return "Afternoon Stillness"
        case 17..<21: return "Evening Vespers"
        default: return "Night Vigil"
        }
    }

    // MARK: - Meditation Wisdom

    private var meditationWisdom: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Subtle frame top
            Rectangle()
                .fill(candleAmber.opacity(Theme.Opacity.light))
                .frame(width: 40, height: 1)

            // Quote
            VStack(spacing: Theme.Spacing.md) {
                Text(dailyVerse.text)
                    .font(.custom("CormorantGaramond-Italic", size: 22))
                    .foregroundStyle(warmIvory.opacity(Theme.Opacity.high))
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)

                Text(dailyVerse.reference)
                    .font(Typography.Icon.xs)
                    .tracking(2)
                    .foregroundStyle(candleAmber.opacity(Theme.Opacity.heavy))
            }
            .padding(.vertical, Theme.Spacing.xl)

            // Subtle frame bottom
            Rectangle()
                .fill(candleAmber.opacity(Theme.Opacity.light))
                .frame(width: 40, height: 1)
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 20)
        .animation(.easeOut(duration: 0.7).delay(0.3), value: isAwakened)
    }

    // MARK: - Reflection Prompt

    private var reflectionPrompt: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Label
            Text("REFLECT")
                .font(Typography.Icon.xxxs)
                .tracking(2)
                .foregroundStyle(candleAmber.opacity(Theme.Opacity.lightMedium))

            // AI Insight as reflection
            Text(insight.summary)
                .font(.custom("CormorantGaramond-Regular", size: 16))
                .foregroundStyle(Color.stoneGray)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, Theme.Spacing.md)

            // Journal prompt
            Button {
                // Open journal
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "pencil.line")
                        .font(Typography.Command.caption)

                    Text("Write a reflection")
                        .font(Typography.Command.caption)
                }
                .foregroundStyle(candleAmber.opacity(Theme.Opacity.heavy))
            }
            .padding(.top, Theme.Spacing.sm)
        }
        .padding(Theme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.input)
                .fill(Color.white.opacity(Theme.Opacity.faint))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.input)
                .strokeBorder(candleAmber.opacity(Theme.Opacity.overlay), lineWidth: 1)
        )
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.5), value: isAwakened)
    }

    // MARK: - Contemplative Actions

    private var contemplativeActions: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Primary - Continue Reading
            ContemplativeButton(
                icon: "book.fill",
                title: "Continue Reading",
                subtitle: activePlan.todayReference,
                accentColor: candleAmber,
                isPrimary: true
            )

            // Secondary actions
            HStack(spacing: Theme.Spacing.md) {
                ContemplativeButton(
                    icon: "hands.sparkles.fill",
                    title: "Pray",
                    subtitle: nil,
                    accentColor: candleAmber,
                    isPrimary: false
                )

                ContemplativeButton(
                    icon: "moon.stars.fill",
                    title: "Compline",
                    subtitle: nil,
                    accentColor: candleAmber,
                    isPrimary: false
                )
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.6), value: isAwakened)
    }

    // MARK: - Quiet Progress

    private var quietProgress: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Minimal progress indicator
            HStack {
                Text(activePlan.title)
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color(hex: "6B6560"))

                Spacer()

                Text("Day \(activePlan.currentDay)")
                    .font(Typography.Command.meta)
                    .foregroundStyle(candleAmber.opacity(Theme.Opacity.medium))
            }

            // Progress line
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(candleAmber.opacity(Theme.Opacity.overlay))
                        .frame(height: 2)

                    Rectangle()
                        .fill(candleAmber.opacity(Theme.Opacity.lightMedium))
                        .frame(width: geometry.size.width * activePlan.progress, height: 2)
                }
            }
            .frame(height: 2)
        }
        .opacity(isAwakened ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.8), value: isAwakened)
    }
}

// MARK: - Contemplative Button

private struct ContemplativeButton: View {
    let icon: String
    let title: String
    let subtitle: String?
    let accentColor: Color
    let isPrimary: Bool

    var body: some View {
        Button {
            // Action
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: isPrimary ? 20 : 18, weight: .light))
                    .foregroundStyle(accentColor.opacity(isPrimary ? 0.8 : 0.6))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("CormorantGaramond-SemiBold", size: isPrimary ? 18 : 16))
                        .foregroundStyle(Color(hex: isPrimary ? "F5EDE0" : "A8A29E"))

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color(hex: "6B6560"))
                    }
                }

                Spacer()

                if isPrimary {
                    Image(systemName: "chevron.right")
                        .font(Typography.Icon.xs)
                        .foregroundStyle(accentColor.opacity(Theme.Opacity.medium))
                }
            }
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(isPrimary ? accentColor.opacity(Theme.Opacity.overlay) : Color.white.opacity(Theme.Opacity.faint))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .strokeBorder(accentColor.opacity(isPrimary ? 0.2 : 0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TheMeditationChamberPage()
    }
}

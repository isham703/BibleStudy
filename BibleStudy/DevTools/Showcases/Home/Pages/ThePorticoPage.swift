import SwiftUI

// MARK: - The Portico Page
// Structured layout with column-like section dividers
// Design: Inspired by philosophical porticos where Stoics taught

struct ThePorticoPage: View {
    @State private var isAwakened = false
    @Environment(\.dismiss) private var dismiss

    // Mock data
    private let greeting = SanctuaryMockData.fullGreeting
    private let dailyVerse = SanctuaryMockData.dailyVerse
    private let activePlan = SanctuaryMockData.activePlan
    private let practiceData = SanctuaryMockData.practiceData

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with greeting
                    headerSection
                        .padding(.top, 20)
                        .padding(.bottom, 32)

                    // Column divider
                    columnDivider
                        .padding(.bottom, 24)

                    // Daily wisdom section
                    wisdomSection
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 32)

                    // Column divider
                    columnDivider
                        .padding(.bottom, 24)

                    // Three-column feature grid
                    featureGrid
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 32)

                    // Column divider
                    columnDivider
                        .padding(.bottom, 24)

                    // Reading progress section
                    readingProgressSection
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 32)

                    // Column divider
                    columnDivider
                        .padding(.bottom, 24)

                    // Practice section
                    practiceSection
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
                Button {
                    // Settings
                } label: {
                    Image(systemName: "gearshape")
                        .font(Typography.Command.callout)
                        .foregroundStyle(Color(hex: "A0A0A0"))
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
            // Base - deep purple undertone
            Color(hex: "0D0A14")
                .ignoresSafeArea()

            // Vertical column effect (subtle)
            HStack(spacing: 0) {
                ForEach(0..<3) { index in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentIndigo.opacity(Theme.Opacity.faint),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(maxWidth: .infinity)
                }
            }
            .ignoresSafeArea()

            // Soft vignette
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(Theme.Opacity.lightMedium)
                ],
                center: .center,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(SanctuaryMockData.formattedDate.uppercased())
                    .font(Typography.Icon.xxs)
                    .tracking(2)
                    .foregroundStyle(Color.accentIndigo.opacity(Theme.Opacity.tertiary))

                Text(greeting)
                    .font(.custom("CormorantGaramond-SemiBold", size: 28))
                    .foregroundStyle(Color.decorativeMarble)
            }

            Spacer()

            // Streak badge
            VStack(spacing: 4) {
                Text("\(SanctuaryMockData.userData.currentStreak)")
                    .font(.custom("CormorantGaramond-SemiBold", size: 24))
                    .foregroundStyle(Color.accentIndigo.opacity(Theme.Opacity.high))

                Text("DAY STREAK")
                    .font(Typography.Icon.xxxs)
                    .tracking(1)
                    .foregroundStyle(Color.neutralGray)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(Color.accentIndigo.opacity(Theme.Opacity.overlay))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .strokeBorder(Color.accentIndigo.opacity(Theme.Opacity.light), lineWidth: 1)
            )
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 10)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: isAwakened)
    }

    // MARK: - Column Divider

    private var columnDivider: some View {
        HStack(spacing: 0) {
            // Left pillar cap
            Rectangle()
                .fill(Color.accentIndigo.opacity(Theme.Opacity.subtle))
                .frame(width: 2, height: 8)

            // Main line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentIndigo.opacity(Theme.Opacity.subtle),
                            Color.accentIndigo.opacity(Theme.Opacity.divider),
                            Color.accentIndigo.opacity(Theme.Opacity.subtle)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Right pillar cap
            Rectangle()
                .fill(Color.accentIndigo.opacity(Theme.Opacity.subtle))
                .frame(width: 2, height: 8)
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    // MARK: - Wisdom Section

    private var wisdomSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Section label
            HStack {
                Text("TODAY'S WISDOM")
                    .font(Typography.Icon.xxs)
                    .tracking(2)
                    .foregroundStyle(Color.accentIndigo.opacity(Theme.Opacity.heavy))

                Spacer()

                Text(dailyVerse.theme.uppercased())
                    .font(Typography.Icon.xxxs)
                    .tracking(1)
                    .foregroundStyle(Color.neutralGray)
            }

            // Quote card
            VStack(spacing: Theme.Spacing.md) {
                Text(dailyVerse.text)
                    .font(.custom("CormorantGaramond-Regular", size: 20))
                    .foregroundStyle(Color(hex: "F0EBE4"))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)

                HStack {
                    Text(dailyVerse.reference)
                        .font(.custom("CormorantGaramond-SemiBold", size: 14))
                        .foregroundStyle(Color.accentIndigo.opacity(Theme.Opacity.pressed))

                    Spacer()

                    Button {
                        // Share
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color.neutralGray)
                    }
                }
            }
            .padding(Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(Color.white.opacity(Theme.Opacity.faint))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .strokeBorder(Color.accentIndigo.opacity(Theme.Opacity.divider), lineWidth: 1)
            )
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: isAwakened)
    }

    // MARK: - Feature Grid

    private var featureGrid: some View {
        HStack(spacing: Theme.Spacing.md) {
            PorticoFeatureCard(
                icon: "book.fill",
                title: "Read",
                subtitle: "Scripture",
                accentColor: Color.accentIndigo
            )

            PorticoFeatureCard(
                icon: "bubble.left.fill",
                title: "Ask",
                subtitle: "Questions",
                accentColor: Color.accentIndigoLight
            )

            PorticoFeatureCard(
                icon: "hands.sparkles.fill",
                title: "Pray",
                subtitle: "Together",
                accentColor: Color.accentIndigoDark
            )
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: isAwakened)
    }

    // MARK: - Reading Progress Section

    private var readingProgressSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Section label
            HStack {
                Text("READING PLAN")
                    .font(Typography.Icon.xxs)
                    .tracking(2)
                    .foregroundStyle(Color.accentIndigo.opacity(Theme.Opacity.heavy))

                Spacer()

                Text("Day \(activePlan.currentDay)/\(activePlan.totalDays)")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color.neutralGray)
            }

            // Progress card
            HStack(spacing: Theme.Spacing.lg) {
                // Left - info
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(activePlan.title)
                        .font(.custom("CormorantGaramond-SemiBold", size: 18))
                        .foregroundStyle(Color.decorativeMarble)

                    Text(activePlan.todayReference)
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.neutralGray)
                }

                Spacer()

                // Right - progress ring
                ZStack {
                    Circle()
                        .stroke(Color.accentIndigo.opacity(Theme.Opacity.light), lineWidth: 4)

                    Circle()
                        .trim(from: 0, to: activePlan.progress)
                        .stroke(Color.accentIndigo, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(activePlan.progress * 100))%")
                        .font(Typography.Icon.xs)
                        .foregroundStyle(Color.accentIndigo)
                }
                .frame(width: 50, height: 50)
            }
            .padding(Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(Color.white.opacity(Theme.Opacity.faint))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .strokeBorder(Color.accentIndigo.opacity(Theme.Opacity.divider), lineWidth: 1)
            )
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: isAwakened)
    }

    // MARK: - Practice Section

    private var practiceSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Section label
            HStack {
                Text("MEMORIZATION")
                    .font(Typography.Icon.xxs)
                    .tracking(2)
                    .foregroundStyle(Color.accentIndigo.opacity(Theme.Opacity.heavy))

                Spacer()

                if practiceData.hasPracticeItems {
                    Text("\(practiceData.dueCount) due")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.accentIndigo.opacity(Theme.Opacity.pressed))
                }
            }

            // Practice card
            Button {
                // Start practice
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Practice Today")
                            .font(.custom("CormorantGaramond-SemiBold", size: 18))
                            .foregroundStyle(Color.decorativeMarble)

                        Text("\(practiceData.estimatedMinutes) min estimated")
                            .font(Typography.Command.meta)
                            .foregroundStyle(Color.neutralGray)
                    }

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .font(Typography.Icon.xl)
                        .foregroundStyle(Color.accentIndigo)
                }
                .padding(Theme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .fill(Color.accentIndigo.opacity(Theme.Opacity.overlay))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .strokeBorder(Color.accentIndigo.opacity(Theme.Opacity.light), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.5), value: isAwakened)
    }
}

// MARK: - Portico Feature Card

private struct PorticoFeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color

    var body: some View {
        Button {
            // Action
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(Typography.Command.title3.weight(.light))
                    .foregroundStyle(accentColor)
                    .frame(height: 28)

                VStack(spacing: 2) {
                    Text(title)
                        .font(.custom("CormorantGaramond-SemiBold", size: 16))
                        .foregroundStyle(Color.decorativeMarble)

                    Text(subtitle)
                        .font(Typography.Icon.xxs)
                        .foregroundStyle(Color.neutralGray)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(Color.white.opacity(Theme.Opacity.faint))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .strokeBorder(accentColor.opacity(Theme.Opacity.light), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ThePorticoPage()
    }
}

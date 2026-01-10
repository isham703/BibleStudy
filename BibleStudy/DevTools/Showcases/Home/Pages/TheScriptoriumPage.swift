import SwiftUI

// MARK: - The Scriptorium Page
// Manuscript-inspired design evoking medieval scriptoriums
// Design: Parchment tones, illuminated drop capitals, scroll-like sections, scholarly focus

struct TheScriptoriumPage: View {
    @State private var isAwakened = false
    @Environment(\.dismiss) private var dismiss

    // Mock data
    private let greeting = SanctuaryMockData.fullGreeting
    private let dailyVerse = SanctuaryMockData.dailyVerse
    private let activePlan = SanctuaryMockData.activePlan
    private let insight = SanctuaryMockData.currentInsight

    // Scriptorium Palette
    private let saddleBrown = Color(hex: "8B4513")
    private let parchment = Color(hex: "F0E6D2")
    private let inkBlack = Color(hex: "1C1410")
    private let sepia = Color(hex: "704214")
    private let goldLeaf = Color(hex: "CFB53B")
    private let oxblood = Color(hex: "4A0E0E")

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with decorative border
                    headerSection
                        .padding(.top, 24)
                        .padding(.bottom, 32)

                    // Illuminated manuscript section (hero)
                    illuminatedSection
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 40)

                    // Scroll divider
                    scrollDivider
                        .padding(.bottom, 32)

                    // Study progress (codex style)
                    codexProgress
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 32)

                    // Scholar's tools
                    scholarTools
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 32)

                    // Marginal notes (AI insight)
                    marginalNotes
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
                    .foregroundStyle(saddleBrown.opacity(Theme.Opacity.pressed))
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
            // Deep ink base
            inkBlack
                .ignoresSafeArea()

            // Parchment texture gradient (subtle)
            LinearGradient(
                colors: [
                    parchment.opacity(Theme.Opacity.faint),
                    sepia.opacity(Theme.Opacity.faint),
                    parchment.opacity(Theme.Opacity.faint),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Warm lamp glow from top-left (like a candle on desk)
            RadialGradient(
                colors: [
                    goldLeaf.opacity(Theme.Opacity.faint),
                    sepia.opacity(Theme.Opacity.faint),
                    Color.clear
                ],
                center: UnitPoint(x: 0.15, y: 0.1),
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()

            // Aged edges vignette
            RadialGradient(
                colors: [
                    Color.clear,
                    inkBlack.opacity(Theme.Opacity.medium)
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
        VStack(spacing: Theme.Spacing.lg) {
            // Decorative header border
            HStack(spacing: 0) {
                // Left corner ornament
                Image(systemName: "leaf.fill")
                    .font(Typography.Icon.xxs)
                    .foregroundStyle(goldLeaf.opacity(Theme.Opacity.lightMedium))
                    .rotationEffect(.degrees(-90))

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                goldLeaf.opacity(Theme.Opacity.light),
                                goldLeaf.opacity(Theme.Opacity.lightMedium),
                                goldLeaf.opacity(Theme.Opacity.light)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                // Right corner ornament
                Image(systemName: "leaf.fill")
                    .font(Typography.Icon.xxs)
                    .foregroundStyle(goldLeaf.opacity(Theme.Opacity.lightMedium))
                    .rotationEffect(.degrees(90))
                    .scaleEffect(x: -1)
            }
            .padding(.horizontal, Theme.Spacing.xl)

            // Date and greeting
            VStack(spacing: Theme.Spacing.sm) {
                Text(SanctuaryMockData.formattedDate.uppercased())
                    .font(Typography.Icon.xxs)
                    .tracking(3)
                    .foregroundStyle(sepia.opacity(Theme.Opacity.tertiary))

                Text(greeting)
                    .font(.custom("CormorantGaramond-Regular", size: 26))
                    .foregroundStyle(parchment.opacity(Theme.Opacity.high))
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: isAwakened)
    }

    // MARK: - Illuminated Section (Hero)

    private var illuminatedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The illuminated drop capital
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                // Drop cap with gold leaf effect
                dropCapital

                // Rest of the verse
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text(dailyVerse.text.dropFirst())
                        .font(.custom("CormorantGaramond-Regular", size: 20))
                        .foregroundStyle(parchment.opacity(Theme.Opacity.strong))
                        .lineSpacing(8)

                    // Reference in manuscript style
                    HStack(spacing: Theme.Spacing.sm) {
                        Rectangle()
                            .fill(saddleBrown.opacity(Theme.Opacity.subtle))
                            .frame(width: 20, height: 1)

                        Text(dailyVerse.reference)
                            .font(.custom("CormorantGaramond-Italic", size: 14))
                            .foregroundStyle(sepia)
                    }
                }
            }
        }
        .padding(Theme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.xs)
                .fill(parchment.opacity(Theme.Opacity.faint))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.xs)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            goldLeaf.opacity(Theme.Opacity.subtle),
                            saddleBrown.opacity(Theme.Opacity.light),
                            goldLeaf.opacity(Theme.Opacity.subtle)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 20)
        .animation(.easeOut(duration: 0.7).delay(0.2), value: isAwakened)
    }

    // Drop capital with illumination effect
    private var dropCapital: some View {
        ZStack {
            // Gold leaf background
            RoundedRectangle(cornerRadius: Theme.Radius.xs)
                .fill(
                    LinearGradient(
                        colors: [
                            goldLeaf.opacity(Theme.Opacity.light),
                            sepia.opacity(Theme.Opacity.divider),
                            goldLeaf.opacity(Theme.Opacity.quarter)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 64)

            // Decorative inner border
            RoundedRectangle(cornerRadius: Theme.Radius.xs)
                .strokeBorder(goldLeaf.opacity(Theme.Opacity.lightMedium), lineWidth: 1)
                .frame(width: 48, height: 56)

            // The letter
            Text(String(dailyVerse.text.prefix(1)))
                .font(.custom("CormorantGaramond-Bold", size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [oxblood, saddleBrown],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    // MARK: - Scroll Divider

    private var scrollDivider: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Left scroll end
            ScrollEndView(isLeft: true, color: saddleBrown)

            // Center line
            Rectangle()
                .fill(saddleBrown.opacity(Theme.Opacity.light))
                .frame(height: 1)

            // Right scroll end
            ScrollEndView(isLeft: false, color: saddleBrown)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .opacity(isAwakened ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: isAwakened)
    }

    // MARK: - Codex Progress

    private var codexProgress: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Section header
            HStack {
                Image(systemName: "book.closed.fill")
                    .font(Typography.Command.caption)
                    .foregroundStyle(saddleBrown.opacity(Theme.Opacity.heavy))

                Text("YOUR CODEX")
                    .font(Typography.Icon.xxs)
                    .tracking(2)
                    .foregroundStyle(sepia.opacity(Theme.Opacity.heavy))

                Spacer()

                Text("Day \(activePlan.currentDay)")
                    .font(.custom("CormorantGaramond-SemiBold", size: 14))
                    .foregroundStyle(goldLeaf.opacity(Theme.Opacity.pressed))
            }

            // Reading plan card
            Button {
                // Continue reading
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(activePlan.title)
                            .font(.custom("CormorantGaramond-SemiBold", size: 20))
                            .foregroundStyle(parchment)

                        Text(activePlan.todayReference)
                            .font(Typography.Command.meta)
                            .foregroundStyle(sepia.opacity(Theme.Opacity.heavy))

                        // Quill progress indicator
                        HStack(spacing: Theme.Spacing.sm) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(saddleBrown.opacity(Theme.Opacity.light))
                                        .frame(height: 3)

                                    Rectangle()
                                        .fill(goldLeaf.opacity(Theme.Opacity.tertiary))
                                        .frame(width: geometry.size.width * activePlan.progress, height: 3)
                                }
                            }
                            .frame(height: 3)

                            Text("\(Int(activePlan.progress * 100))%")
                                .font(Typography.Icon.xxs.weight(.medium))
                                .foregroundStyle(sepia.opacity(Theme.Opacity.tertiary))
                        }
                        .padding(.top, Theme.Spacing.xs)
                    }

                    Spacer()

                    // Quill icon
                    Image(systemName: "pencil.and.outline")
                        .font(Typography.Icon.lg)
                        .foregroundStyle(goldLeaf.opacity(Theme.Opacity.tertiary))
                }
                .padding(Theme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.tag)
                        .fill(saddleBrown.opacity(Theme.Opacity.overlay))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.tag)
                        .strokeBorder(saddleBrown.opacity(Theme.Opacity.light), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.5), value: isAwakened)
    }

    // MARK: - Scholar Tools

    private var scholarTools: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Section header
            HStack {
                Text("SCHOLAR'S TOOLS")
                    .font(Typography.Icon.xxs)
                    .tracking(2)
                    .foregroundStyle(sepia.opacity(Theme.Opacity.tertiary))

                Spacer()
            }

            // Tool buttons
            HStack(spacing: Theme.Spacing.md) {
                ScholarToolButton(
                    icon: "scroll.fill",
                    title: "Stories",
                    saddleBrown: saddleBrown,
                    parchment: parchment
                )

                ScholarToolButton(
                    icon: "magnifyingglass",
                    title: "Search",
                    saddleBrown: saddleBrown,
                    parchment: parchment
                )

                ScholarToolButton(
                    icon: "brain.head.profile",
                    title: "Memorize",
                    saddleBrown: saddleBrown,
                    parchment: parchment
                )
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.6), value: isAwakened)
    }

    // MARK: - Marginal Notes (AI Insight)

    private var marginalNotes: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Marginal note indicator
            HStack(spacing: Theme.Spacing.sm) {
                // Bracket decoration
                Text("[")
                    .font(.custom("CormorantGaramond-Light", size: 24))
                    .foregroundStyle(saddleBrown.opacity(Theme.Opacity.lightMedium))

                Text("MARGINAL NOTE")
                    .font(Typography.Icon.xxxs)
                    .tracking(2)
                    .foregroundStyle(sepia.opacity(Theme.Opacity.medium))

                Text("]")
                    .font(.custom("CormorantGaramond-Light", size: 24))
                    .foregroundStyle(saddleBrown.opacity(Theme.Opacity.lightMedium))

                Spacer()
            }

            // The insight as a marginal annotation
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                // Annotation mark
                Text("†")
                    .font(.custom("CormorantGaramond-Bold", size: 18))
                    .foregroundStyle(oxblood.opacity(Theme.Opacity.heavy))
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text(insight.summary)
                        .font(.custom("CormorantGaramond-Italic", size: 15))
                        .foregroundStyle(parchment.opacity(Theme.Opacity.heavy))
                        .lineSpacing(5)

                    // Related verses
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(insight.relatedVerses.prefix(2), id: \.self) { verse in
                            Text(verse)
                                .font(Typography.Icon.xxs)
                                .foregroundStyle(sepia.opacity(Theme.Opacity.tertiary))
                                .padding(.horizontal, Theme.Spacing.sm)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(saddleBrown.opacity(Theme.Opacity.overlay))
                                )
                        }
                    }
                }
            }
            .padding(Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                    .fill(parchment.opacity(Theme.Opacity.faint))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                    .strokeBorder(saddleBrown.opacity(Theme.Opacity.overlay), lineWidth: 1)
            )
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.7), value: isAwakened)
    }
}

// MARK: - Scroll End View

private struct ScrollEndView: View {
    let isLeft: Bool
    let color: Color

    var body: some View {
        ZStack {
            // Scroll roll
            Capsule()
                .fill(color.opacity(Theme.Opacity.light))
                .frame(width: 8, height: 16)

            // End cap
            Circle()
                .fill(color.opacity(Theme.Opacity.subtle))
                .frame(width: 10, height: 10)
                .offset(y: isLeft ? -4 : 4)
        }
    }
}

// MARK: - Scholar Tool Button

private struct ScholarToolButton: View {
    let icon: String
    let title: String
    let saddleBrown: Color
    let parchment: Color

    var body: some View {
        Button {
            // Action
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(Typography.Icon.lg.weight(.light))
                    .foregroundStyle(saddleBrown.opacity(Theme.Opacity.heavy))

                Text(title)
                    .font(Typography.Icon.xxs.weight(.medium))
                    .foregroundStyle(parchment.opacity(Theme.Opacity.heavy))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.tag)
                    .fill(saddleBrown.opacity(Theme.Opacity.faint))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.tag)
                    .strokeBorder(saddleBrown.opacity(Theme.Opacity.divider), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TheScriptoriumPage()
    }
}

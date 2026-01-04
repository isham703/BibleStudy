import SwiftUI

// MARK: - Narrative Home Page
// Cinematic Epic + Sacred Film Opening aesthetic
// Full-bleed hero with parallax, storytelling approach

struct NarrativeHomePage: View {
    @State private var isVisible = false
    @State private var scrollOffset: CGFloat = 0
    @State private var titleCharacterIndex = 0
    @State private var ctaGlowOpacity: Double = 0.3

    private let user = HomeShowcaseMockData.userData
    private let verse = HomeShowcaseMockData.dailyVerse
    private let plan = HomeShowcaseMockData.activePlan
    private let insight = HomeShowcaseMockData.currentInsight
    private let stories = HomeShowcaseMockData.featuredStories

    private let heroTitle = "YOUR JOURNEY CONTINUES"

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Section
                heroSection
                    .offset(y: scrollOffset * 0.5) // Parallax effect

                // Content
                VStack(spacing: SanctuaryTheme.Spacing.xxxl) {
                    // Today's Word
                    verseSection

                    // Continue Your Story
                    storySection

                    // Discover
                    discoverSection

                    // Insight For You
                    insightSection
                }
                .padding(.top, SanctuaryTheme.Spacing.xxxl)
                .padding(.bottom, SanctuaryTheme.Spacing.huge)
                .padding(.horizontal, SanctuaryTheme.Spacing.lg)
            }
        }
        .background(Color.candlelitStone)
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isVisible = true
            }

            // Animate title typing
            animateTitleTyping()

            // CTA glow pulse
            withAnimation(SanctuaryTheme.Animation.pulse) {
                ctaGlowOpacity = 0.6
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                stops: [
                    .init(color: Color.deepIndigo, location: 0),
                    .init(color: Color.warmBurgundy, location: 0.4),
                    .init(color: Color.candlelitStone, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Radial gold glow
            RadialGradient(
                colors: [
                    Color.divineGold.opacity(0.15),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 250
            )

            // Film grain overlay (simulated with noise pattern)
            grainOverlay

            // Vignette
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.4)
                ],
                center: .center,
                startRadius: 150,
                endRadius: 350
            )

            // Content
            VStack(spacing: SanctuaryTheme.Spacing.lg) {
                Spacer()
                    .frame(height: 60)

                // Title - types in letter by letter
                Text(String(heroTitle.prefix(titleCharacterIndex)))
                    .font(SanctuaryTypography.Narrative.heroTitle)
                    .tracking(6)
                    .foregroundStyle(Color.divineGold)
                    .multilineTextAlignment(.center)
                    .frame(height: 20) // Fixed height to prevent layout shift

                // Greeting
                Text(HomeShowcaseMockData.fullGreeting)
                    .font(SanctuaryTypography.Narrative.heroGreeting)
                    .foregroundStyle(Color.moonlitParchment)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 15)
                    .blur(radius: isVisible ? 0 : 5)
                    .animation(.easeOut(duration: 0.6).delay(0.8), value: isVisible)

                // Stats row
                HStack(spacing: SanctuaryTheme.Spacing.lg) {
                    Text("Day \(plan.currentDay) of John")
                        .font(SanctuaryTypography.Narrative.heroStats)
                        .foregroundStyle(Color.fadedMoonlight)

                    Text("·")
                        .foregroundStyle(Color.fadedMoonlight.opacity(0.5))

                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(user.currentStreak)")
                    }
                    .font(SanctuaryTypography.Narrative.heroStats)
                    .foregroundStyle(Color.moonlitParchment)
                }
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(1.0), value: isVisible)

                Spacer()
                    .frame(height: SanctuaryTheme.Spacing.xl)

                // CTA Button with glow
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Text("Continue Journey")
                            .font(SanctuaryTypography.Narrative.ctaButton)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(Color.candlelitStone)
                    .padding(.horizontal, SanctuaryTheme.Spacing.xl)
                    .padding(.vertical, SanctuaryTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: SanctuaryTheme.CornerRadius.small)
                            .fill(Color.divineGold)
                    )
                    .shadow(color: Color.divineGold.opacity(ctaGlowOpacity), radius: 16)
                }
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.9)
                .animation(.spring(duration: 0.5).delay(1.2), value: isVisible)

                Spacer()
                    .frame(height: SanctuaryTheme.Spacing.xxxl)
            }
            .padding(.horizontal, SanctuaryTheme.Spacing.xl)
        }
        .frame(height: SanctuaryTheme.Size.heroHeight)
    }

    private var grainOverlay: some View {
        // Simulated grain using a pattern
        Canvas { context, size in
            for _ in 0..<300 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let opacity = Double.random(in: 0.01...0.04)

                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(.white.opacity(opacity))
                )
            }
        }
        .blendMode(.overlay)
    }

    // MARK: - Verse Section

    private var verseSection: some View {
        VStack(spacing: SanctuaryTheme.Spacing.xl) {
            // Header
            VStack(spacing: 4) {
                Text("T O D A Y ' S")
                    .narrativeHeader()
                Text("W O R D")
                    .narrativeHeader()
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(1.4), value: isVisible)

            MockDailyVerseCard(verse: verse, style: .narrative)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(1.5), value: isVisible)
        }
    }

    // MARK: - Story Section

    private var storySection: some View {
        VStack(alignment: .leading, spacing: SanctuaryTheme.Spacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("C O N T I N U E   Y O U R")
                    .narrativeHeader()
                Text("S T O R Y")
                    .narrativeHeader()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(1.7), value: isVisible)

            // Large cinematic card
            NarrativeStoryCard(plan: plan)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 30)
                .animation(.spring(duration: 0.6).delay(1.8), value: isVisible)
        }
    }

    // MARK: - Discover Section

    private var discoverSection: some View {
        VStack(alignment: .leading, spacing: SanctuaryTheme.Spacing.lg) {
            Text("D I S C O V E R")
                .narrativeHeader()
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(2.0), value: isVisible)

            MockDiscoveryCarousel(items: stories, style: .cinematic)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(2.1), value: isVisible)
        }
        .padding(.horizontal, -SanctuaryTheme.Spacing.lg)
    }

    // MARK: - Insight Section

    private var insightSection: some View {
        VStack(alignment: .leading, spacing: SanctuaryTheme.Spacing.lg) {
            Text("I N S I G H T   F O R   Y O U")
                .narrativeHeader()
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(2.3), value: isVisible)

            MockAIInsightCard(insight: insight, showRadiantStar: true)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(2.4), value: isVisible)
        }
    }

    // MARK: - Helpers

    private func animateTitleTyping() {
        for i in 0...heroTitle.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + Double(i) * 0.04) {
                titleCharacterIndex = i
            }
        }
    }
}

// MARK: - Narrative Story Card

struct NarrativeStoryCard: View {
    let plan: MockReadingPlan
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: SanctuaryTheme.Spacing.lg) {
            // Play icon
            HStack {
                Image(systemName: "play.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color.divineGold)
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .shadow(color: Color.divineGold.opacity(isPressed ? 0.5 : 0), radius: 8)

                Spacer()
            }

            // Reference
            Text(plan.todayReference)
                .font(.system(size: 13, weight: .bold))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(Color.divineGold)

            // Title
            Text(plan.todayTitle)
                .font(SanctuaryTypography.Narrative.cardTitle)
                .foregroundStyle(Color.moonlitParchment)

            // Preview quote
            Text("\"\(plan.previewQuote)\"")
                .font(.system(size: 15, weight: .regular, design: .serif).italic())
                .foregroundStyle(Color.fadedMoonlight)
                .lineSpacing(4)

            // Progress bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.chapelShadow)
                    .frame(height: 6)

                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.divineGold)
                        .frame(width: geo.size.width * plan.progress)
                }
                .frame(height: 6)
            }

            // Progress text
            Text("\(plan.progressPercentage)%")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.divineGold)
        }
        .padding(SanctuaryTheme.Spacing.xl)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: SanctuaryTheme.CornerRadius.large)
                    .fill(Color.chapelShadow)

                // Subtle gradient overlay
                LinearGradient(
                    colors: [
                        Color.divineGold.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: SanctuaryTheme.CornerRadius.large))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: SanctuaryTheme.CornerRadius.large)
                .stroke(Color.divineGold.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
            if pressing {
                HomeShowcaseHaptics.cardPress()
            }
        }, perform: {})
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NarrativeHomePage()
    }
}

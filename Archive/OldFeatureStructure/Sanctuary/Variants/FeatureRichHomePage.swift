import SwiftUI

// MARK: - Feature-Rich Home Page
// Premium Fintech Dashboard + Illuminated Luxury aesthetic
// Complete dashboard with metrics, progress, and all features

struct FeatureRichHomePage: View {
    @State private var isVisible = false

    private let user = HomeShowcaseMockData.userData
    private let verse = HomeShowcaseMockData.dailyVerse
    private let plan = HomeShowcaseMockData.activePlan
    private let practice = HomeShowcaseMockData.practiceData
    private let insight = HomeShowcaseMockData.currentInsight
    private let stories = HomeShowcaseMockData.featuredStories
    private let topics = HomeShowcaseMockData.featuredTopics

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HomeShowcaseTheme.Spacing.xl) {
                // Header
                headerSection

                // Metrics Row
                metricsSection

                // Today's Verse
                verseSection

                // Today's Reading
                readingSection

                // Discover
                discoverSection

                // Today's Practice
                practiceSection

                // For You (AI)
                aiSection

                // Chat Entry
                chatSection
            }
            .padding(.horizontal, HomeShowcaseTheme.Spacing.lg)
            .padding(.vertical, HomeShowcaseTheme.Spacing.xl)
        }
        .background(Color.candlelitStone)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(HomeShowcaseMockData.fullGreeting)
                    .font(HomeShowcaseTypography.Dashboard.greeting)
                    .foregroundStyle(Color.moonlitParchment)

                Text(HomeShowcaseMockData.formattedDate)
                    .font(HomeShowcaseTypography.Dashboard.date)
                    .foregroundStyle(Color.fadedMoonlight)
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .animation(.easeOut(duration: 0.4), value: isVisible)

            Spacer()

            // Settings
            Button(action: {}) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.divineGold)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.divineGold.opacity(0.12))
                    )
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.3).delay(0.05), value: isVisible)

            MockStreakBadge(count: user.currentStreak)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.1), value: isVisible)
        }
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        HStack(spacing: HomeShowcaseTheme.Spacing.sm) {
            MockMetricPill(
                icon: "flame.fill",
                value: "\(user.currentStreak)",
                label: "streak",
                color: .orange
            )
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .animation(.spring(duration: 0.4).delay(0.1), value: isVisible)

            MockMetricPill(
                icon: "book.fill",
                value: "Day \(plan.currentDay)",
                label: "of John",
                color: .divineGold
            )
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .animation(.spring(duration: 0.4).delay(0.18), value: isVisible)

            MockMetricPill(
                icon: "sparkles",
                value: "\(practice.dueCount)",
                label: "due",
                color: .lapisLazuli
            )
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .animation(.spring(duration: 0.4).delay(0.26), value: isVisible)
        }
    }

    // MARK: - Verse Section

    private var verseSection: some View {
        VStack(alignment: .leading, spacing: HomeShowcaseTheme.Spacing.sm) {
            Text("TODAY'S VERSE")
                .dashboardHeader()
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.3), value: isVisible)

            MockDailyVerseCard(verse: verse, style: .standard)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
                .animation(.spring(duration: 0.5).delay(0.35), value: isVisible)
        }
    }

    // MARK: - Reading Section

    private var readingSection: some View {
        VStack(alignment: .leading, spacing: HomeShowcaseTheme.Spacing.sm) {
            Text("TODAY'S READING")
                .dashboardHeader()
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.4), value: isVisible)

            MockReadingPlanCard(plan: plan)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
                .animation(.spring(duration: 0.5).delay(0.45), value: isVisible)
        }
    }

    // MARK: - Discover Section

    private var discoverSection: some View {
        VStack(alignment: .leading, spacing: HomeShowcaseTheme.Spacing.sm) {
            HStack {
                Text("DISCOVER")
                    .dashboardHeader()

                Spacer()

                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color.divineGold)
                }
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.3).delay(0.5), value: isVisible)

            MockDiscoveryCarousel(
                items: HomeShowcaseMockData.allDiscoveryItems,
                style: .compact
            )
            .opacity(isVisible ? 1 : 0)
            .offset(x: isVisible ? 0 : 50)
            .animation(.spring(duration: 0.5).delay(0.55), value: isVisible)
        }
        .padding(.horizontal, -HomeShowcaseTheme.Spacing.lg) // Allow carousel to bleed
    }

    // MARK: - Practice Section

    private var practiceSection: some View {
        VStack(alignment: .leading, spacing: HomeShowcaseTheme.Spacing.sm) {
            Text("TODAY'S PRACTICE")
                .dashboardHeader()
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.6), value: isVisible)

            MockPracticeCard(practice: practice)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
                .animation(.spring(duration: 0.5).delay(0.65), value: isVisible)
        }
    }

    // MARK: - AI Section

    private var aiSection: some View {
        VStack(alignment: .leading, spacing: HomeShowcaseTheme.Spacing.sm) {
            Text("FOR YOU")
                .dashboardHeader()
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.7), value: isVisible)

            MockAIInsightCard(insight: insight)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.75), value: isVisible)
        }
    }

    // MARK: - Chat Section

    private var chatSection: some View {
        MockChatEntryButton()
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.9)
            .animation(.spring(duration: 0.5, bounce: 0.2).delay(0.85), value: isVisible)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FeatureRichHomePage()
    }
}

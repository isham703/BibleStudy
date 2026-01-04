import SwiftUI

// MARK: - Minimalist Home Page
// Swiss Editorial + Zen Monastery aesthetic
// Clean, spacious design focused on daily verse and key actions

struct MinimalistHomePage: View {
    @State private var isVisible = false
    @State private var verseWordIndex = 0

    private let verse = HomeShowcaseMockData.dailyVerse
    private let user = HomeShowcaseMockData.userData
    private let practice = HomeShowcaseMockData.practiceData
    private let plan = HomeShowcaseMockData.activePlan

    // Split verse into words for staggered animation
    private var verseWords: [String] {
        verse.text.components(separatedBy: " ")
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.top, AppTheme.Spacing.xl)

                    Spacer()
                        .frame(height: AppTheme.Spacing.huge)

                    // Daily Verse - The hero moment
                    verseSection

                    Spacer()
                        .frame(height: AppTheme.Spacing.huge)

                    // Action Cards
                    actionSection
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.bottom, AppTheme.Spacing.xxxl)
                }
                .frame(minHeight: geometry.size.height - 100)
            }
        }
        .background(Color.deepVellumBlack)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                isVisible = true
            }

            // Animate verse words
            animateVerseWords()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            // User name only - whisper weight
            Text(user.userName ?? "Welcome")
                .font(SanctuaryTypography.Minimalist.greeting)
                .foregroundStyle(Color.mutedStone)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: isVisible)

            Spacer()

            // Settings
            Button(action: {}) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.mutedStone)
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.15), value: isVisible)

            // Streak badge
            StreakBadge(count: user.currentStreak)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: isVisible)
        }
    }

    // MARK: - Verse Section

    private var verseSection: some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            // Top hairline
            goldHairline(delay: 0.3)

            // Verse text with word-by-word animation
            Text("\"\(verse.text)\"")
                .font(SanctuaryTypography.Minimalist.verse)
                .foregroundStyle(Color.moonlitParchment)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.5), value: isVisible)

            // Reference
            Text("— \(verse.reference)")
                .font(SanctuaryTypography.Minimalist.reference)
                .tracking(3)
                .foregroundStyle(Color.divineGold)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.9), value: isVisible)

            // Bottom hairline
            goldHairline(delay: 1.0)
        }
        .padding(.vertical, AppTheme.Spacing.xl)
    }

    private func goldHairline(delay: Double) -> some View {
        Rectangle()
            .fill(Color.divineGold)
            .frame(width: 80, height: 1)
            .scaleEffect(x: isVisible ? 1 : 0, anchor: .center)
            .animation(.easeOut(duration: 0.6).delay(delay), value: isVisible)
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Continue Reading
            MinimalistActionCard(
                title: "Continue Reading",
                subtitle: plan.todayReference,
                delay: 1.2,
                isVisible: isVisible
            )

            // Divider
            Rectangle()
                .fill(Color.mutedStone.opacity(0.2))
                .frame(height: 0.5)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(1.3), value: isVisible)

            // Practice Verses
            MinimalistActionCard(
                title: "Practice Verses",
                subtitle: "\(practice.dueCount) verses due",
                delay: 1.4,
                isVisible: isVisible
            )
        }
    }

    // MARK: - Helpers

    private func animateVerseWords() {
        // Could be used for more elaborate word-by-word animation
        // Currently using simpler fade-in approach
    }
}

// MARK: - Minimalist Action Card

struct MinimalistActionCard: View {
    let title: String
    let subtitle: String
    let delay: Double
    let isVisible: Bool

    @State private var isPressed = false

    var body: some View {
        Button(action: {}) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(SanctuaryTypography.Minimalist.action)
                        .foregroundStyle(Color.divineGold)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.fadedMoonlight)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.divineGold)
                    .offset(x: isPressed ? 4 : 0)
                    .animation(.spring(response: 0.3), value: isPressed)
            }
            .padding(.vertical, AppTheme.Spacing.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(delay), value: isVisible)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3)) {
                isPressed = pressing
            }
            if pressing {
                HomeShowcaseHaptics.cardPress()
            }
        }, perform: {})
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MinimalistHomePage()
    }
}

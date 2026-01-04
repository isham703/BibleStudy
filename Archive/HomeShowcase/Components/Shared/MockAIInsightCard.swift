import SwiftUI

// MARK: - Mock AI Insight Card
// Displays AI-generated insight with rotating gold border

struct MockAIInsightCard: View {
    let insight: MockAIInsight
    var showRadiantStar: Bool = false

    @State private var rotationAngle: Double = 0
    @State private var isGlowing = false

    var body: some View {
        ZStack {
            // Rotating gold gradient border
            RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.card)
                .stroke(
                    AngularGradient(
                        colors: [.divineGold, .illuminatedGold, .burnishedGold, .divineGold],
                        center: .center,
                        angle: .degrees(rotationAngle)
                    ),
                    lineWidth: 2
                )

            // Content
            VStack(alignment: .leading, spacing: HomeShowcaseTheme.Spacing.md) {
                // Header
                HStack(spacing: HomeShowcaseTheme.Spacing.sm) {
                    if showRadiantStar {
                        radiantStar
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.divineGold)
                    }

                    Text(insight.title)
                        .font(HomeShowcaseTypography.Dashboard.cardTitle)
                        .foregroundStyle(Color.moonlitParchment)
                }

                // Summary
                Text(insight.summary)
                    .font(HomeShowcaseTypography.Dashboard.cardBody)
                    .foregroundStyle(Color.fadedMoonlight)
                    .lineSpacing(4)

                // Explore button
                HStack {
                    Spacer()

                    Text("Explore")
                        .font(HomeShowcaseTypography.Dashboard.button)
                        .foregroundStyle(Color.divineGold)
                        .padding(.horizontal, HomeShowcaseTheme.Spacing.lg)
                        .padding(.vertical, HomeShowcaseTheme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.small)
                                .stroke(Color.divineGold, lineWidth: 1)
                        )
                }
            }
            .padding(HomeShowcaseTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.card)
                    .fill(Color.candlelitStone)
            )
        }
        // Gold glow
        .shadow(color: Color.divineGold.opacity(isGlowing ? 0.4 : 0.2), radius: isGlowing ? 16 : 8)
        .onAppear {
            withAnimation(HomeShowcaseTheme.Animation.gradientRotation) {
                rotationAngle = 360
            }

            withAnimation(HomeShowcaseTheme.Animation.pulse) {
                isGlowing = true
            }
        }
    }

    // MARK: - Radiant Star

    private var radiantStar: some View {
        ZStack {
            // Glow behind
            Image(systemName: "sparkle")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.divineGold)
                .blur(radius: 4)
                .opacity(0.6)

            // Star
            Image(systemName: "sparkle")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.illuminatedGold)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.candlelitStone.ignoresSafeArea()

        VStack(spacing: 20) {
            MockAIInsightCard(insight: HomeShowcaseMockData.currentInsight)

            MockAIInsightCard(
                insight: HomeShowcaseMockData.currentInsight,
                showRadiantStar: true
            )
        }
        .padding()
    }
}

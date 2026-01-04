import SwiftUI

// MARK: - Mock AI Insight Card
// Displays AI-generated insight with rotating gold border

struct AIInsightCard: View {
    let insight: MockAIInsight
    var showRadiantStar: Bool = false

    @State private var rotationAngle: Double = 0
    @State private var isGlowing = false

    var body: some View {
        ZStack {
            // Rotating gold gradient border
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(
                    AngularGradient(
                        colors: [.divineGold, .illuminatedGold, .burnishedGold, .divineGold],
                        center: .center,
                        angle: .degrees(rotationAngle)
                    ),
                    lineWidth: 2
                )

            // Content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                // Header
                HStack(spacing: AppTheme.Spacing.sm) {
                    if showRadiantStar {
                        radiantStar
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.divineGold)
                    }

                    Text(insight.title)
                        .font(SanctuaryTypography.Dashboard.cardTitle)
                        .foregroundStyle(Color.moonlitParchment)
                }

                // Summary
                Text(insight.summary)
                    .font(SanctuaryTypography.Dashboard.cardBody)
                    .foregroundStyle(Color.fadedMoonlight)
                    .lineSpacing(4)

                // Explore button
                HStack {
                    Spacer()

                    Text("Explore")
                        .font(SanctuaryTypography.Dashboard.button)
                        .foregroundStyle(Color.divineGold)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                .stroke(Color.divineGold, lineWidth: 1)
                        )
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .fill(Color.candlelitStone)
            )
        }
        // Gold glow
        .shadow(color: Color.divineGold.opacity(isGlowing ? 0.4 : 0.2), radius: isGlowing ? 16 : 8)
        .onAppear {
            withAnimation(AppTheme.Animation.gradientRotation) {
                rotationAngle = 360
            }

            withAnimation(AppTheme.Animation.pulse) {
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
            AIInsightCard(insight: HomeShowcaseMockData.currentInsight)

            AIInsightCard(
                insight: HomeShowcaseMockData.currentInsight,
                showRadiantStar: true
            )
        }
        .padding()
    }
}

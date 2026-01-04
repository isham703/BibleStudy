import SwiftUI

// MARK: - Mock Reading Plan Card
// Displays current reading plan progress with shimmer effect

struct MockReadingPlanCard: View {
    let plan: MockReadingPlan
    var showPreviewQuote: Bool = false

    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        VStack(alignment: .leading, spacing: HomeShowcaseTheme.Spacing.md) {
            // Header row
            HStack {
                Text(plan.title)
                    .font(HomeShowcaseTypography.Dashboard.cardTitle)
                    .foregroundStyle(Color.moonlitParchment)

                Spacer()

                Text("Day \(plan.currentDay)")
                    .font(HomeShowcaseTypography.Dashboard.progressText)
                    .foregroundStyle(Color.fadedMoonlight)
            }

            // Reference
            Text(plan.todayReference)
                .font(HomeShowcaseTypography.Dashboard.cardBody)
                .foregroundStyle(Color.fadedMoonlight)

            // Preview quote (for narrative style)
            if showPreviewQuote {
                Text("\"\(plan.previewQuote)\"")
                    .font(.system(size: 14, weight: .regular, design: .serif).italic())
                    .foregroundStyle(Color.fadedMoonlight.opacity(0.8))
                    .padding(.top, HomeShowcaseTheme.Spacing.xs)
            }

            // Progress bar with shimmer
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.chapelShadow)
                    .frame(height: 8)

                // Fill
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.divineGold)
                        .frame(width: geo.size.width * plan.progress)

                    // Shimmer overlay
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 60)
                        .offset(x: shimmerOffset)
                        .mask(
                            RoundedRectangle(cornerRadius: 4)
                                .frame(width: geo.size.width * plan.progress)
                        )
                }
                .frame(height: 8)
            }

            // Progress text row
            HStack {
                Text("\(plan.progressPercentage)%")
                    .font(HomeShowcaseTypography.Dashboard.progressText)
                    .foregroundStyle(Color.divineGold)

                Spacer()

                HStack(spacing: 4) {
                    Text("Continue")
                        .font(HomeShowcaseTypography.Dashboard.button)
                        .foregroundStyle(Color.divineGold)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.divineGold)
                }
            }
        }
        .padding(HomeShowcaseTheme.Spacing.lg)
        .glassCard()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: false)
                .delay(0.5)
            ) {
                shimmerOffset = 400
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.candlelitStone.ignoresSafeArea()

        VStack(spacing: 20) {
            MockReadingPlanCard(plan: HomeShowcaseMockData.activePlan)

            MockReadingPlanCard(
                plan: HomeShowcaseMockData.activePlan,
                showPreviewQuote: true
            )
        }
        .padding()
    }
}

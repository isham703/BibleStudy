import SwiftUI

// MARK: - Mock Reading Plan Card
// Displays current reading plan progress with shimmer effect

struct ReadingPlanCard: View {
    let plan: MockReadingPlan
    var showPreviewQuote: Bool = false

    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        VStack(alignment: .leading, spacing: SanctuaryTheme.Spacing.md) {
            // Header row
            HStack {
                Text(plan.title)
                    .font(SanctuaryTypography.Dashboard.cardTitle)
                    .foregroundStyle(Color.moonlitParchment)

                Spacer()

                Text("Day \(plan.currentDay)")
                    .font(SanctuaryTypography.Dashboard.progressText)
                    .foregroundStyle(Color.fadedMoonlight)
            }

            // Reference
            Text(plan.todayReference)
                .font(SanctuaryTypography.Dashboard.cardBody)
                .foregroundStyle(Color.fadedMoonlight)

            // Preview quote (for narrative style)
            if showPreviewQuote {
                Text("\"\(plan.previewQuote)\"")
                    .font(.system(size: 14, weight: .regular, design: .serif).italic())
                    .foregroundStyle(Color.fadedMoonlight.opacity(0.8))
                    .padding(.top, SanctuaryTheme.Spacing.xs)
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
                    .font(SanctuaryTypography.Dashboard.progressText)
                    .foregroundStyle(Color.divineGold)

                Spacer()

                HStack(spacing: 4) {
                    Text("Continue")
                        .font(SanctuaryTypography.Dashboard.button)
                        .foregroundStyle(Color.divineGold)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.divineGold)
                }
            }
        }
        .padding(SanctuaryTheme.Spacing.lg)
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
            ReadingPlanCard(plan: HomeShowcaseMockData.activePlan)

            ReadingPlanCard(
                plan: HomeShowcaseMockData.activePlan,
                showPreviewQuote: true
            )
        }
        .padding()
    }
}

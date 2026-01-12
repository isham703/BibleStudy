import SwiftUI

// MARK: - Reading Plan Card
// Displays current reading plan progress with flat styling
// Stoic-Existential Renaissance design

struct ReadingPlanCard: View {
    let plan: MockReadingPlan
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header row
            HStack {
                Text(plan.title)
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                Spacer()

                Text("Day \(plan.currentDay)")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("AppTextSecondary"))
            }

            // Reference
            Text(plan.todayReference)
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))

            // Progress bar (flat, no shimmer)
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                    .fill(Color.appDivider.opacity(Theme.Opacity.subtle))
                    .frame(height: 8)

                // Fill
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: Theme.Radius.xs)
                        .fill(Color("AccentBronze"))
                        .frame(width: geo.size.width * plan.progress)
                }
                .frame(height: 8)
            }

            // Progress text row
            HStack {
                Text("\(plan.progressPercentage)%")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("AccentBronze"))

                Spacer()

                HStack(spacing: Theme.Spacing.xs) {
                    Text("Continue")
                        .font(Typography.Command.cta)
                        .foregroundStyle(Color("AppAccentAction"))

                    Image(systemName: "arrow.right")
                        .font(Typography.Icon.xs)
                        .foregroundStyle(Color("AppAccentAction"))
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.appSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(
                    Color.appDivider,
                    lineWidth: Theme.Stroke.hairline
                )
        )
    }
}

// MARK: - Preview

#Preview("Reading Plan Card") {
    @Previewable @Environment(\.colorScheme) var colorScheme

    ZStack {
        Color.appBackground.ignoresSafeArea()

        ReadingPlanCard(plan: SanctuaryMockData.activePlan)
            .padding()
    }
}

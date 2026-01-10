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
                    .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                Spacer()

                Text("Day \(plan.currentDay)")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
            }

            // Reference
            Text(plan.todayReference)
                .font(Typography.Command.body)
                .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))

            // Progress bar (flat, no shimmer)
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                    .fill(Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle))
                    .frame(height: 8)

                // Fill
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: Theme.Radius.xs)
                        .fill(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
                        .frame(width: geo.size.width * plan.progress)
                }
                .frame(height: 8)
            }

            // Progress text row
            HStack {
                Text("\(plan.progressPercentage)%")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))

                Spacer()

                HStack(spacing: Theme.Spacing.xs) {
                    Text("Continue")
                        .font(Typography.Command.cta)
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                    Image(systemName: "arrow.right")
                        .font(Typography.Icon.xs)
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(
                    Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)),
                    lineWidth: Theme.Stroke.hairline
                )
        )
    }
}

// MARK: - Preview

#Preview("Reading Plan Card") {
    @Previewable @Environment(\.colorScheme) var colorScheme
    let themeMode = ThemeMode.current(from: colorScheme)

    ZStack {
        Colors.Surface.background(for: themeMode).ignoresSafeArea()

        ReadingPlanCard(plan: SanctuaryMockData.activePlan)
            .padding()
    }
}

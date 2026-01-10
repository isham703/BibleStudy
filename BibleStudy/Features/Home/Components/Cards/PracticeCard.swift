import SwiftUI

// MARK: - Practice Card
// Displays memorization practice status and CTA
// Stoic-Existential Renaissance design

struct PracticeCard: View {
    let practice: MockPracticeData
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Text("\(practice.dueCount) verses due")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                Text("·")
                    .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))

                Text("~\(practice.estimatedMinutes) min")
                    .font(Typography.Command.body)
                    .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
            }

            // Breakdown
            HStack(spacing: Theme.Spacing.lg) {
                HStack(spacing: Theme.Spacing.xs) {
                    Circle()
                        .fill(Colors.Semantic.success(for: ThemeMode.current(from: colorScheme)))
                        .frame(width: Theme.Spacing.sm, height: Theme.Spacing.sm)
                    Text("\(practice.learningCount) learning")
                        .font(Typography.Command.body)
                        .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                }

                HStack(spacing: Theme.Spacing.xs) {
                    Circle()
                        .fill(Colors.Semantic.info(for: ThemeMode.current(from: colorScheme)))
                        .frame(width: Theme.Spacing.sm, height: Theme.Spacing.sm)
                    Text("\(practice.reviewingCount) reviewing")
                        .font(Typography.Command.body)
                        .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                }
            }

            // CTA Button
            HStack {
                Spacer()

                Text("Start Practice")
                    .font(Typography.Command.cta)
                    .foregroundStyle(Colors.Semantic.onAccentAction(for: ThemeMode.current(from: colorScheme)))
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    )

                Spacer()
            }
            .padding(.top, Theme.Spacing.xs)
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

#Preview("Practice Card") {
    @Previewable @Environment(\.colorScheme) var colorScheme
    let themeMode = ThemeMode.current(from: colorScheme)

    ZStack {
        Colors.Surface.background(for: themeMode).ignoresSafeArea()

        PracticeCard(practice: SanctuaryMockData.practiceData)
            .padding()
    }
}

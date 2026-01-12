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
                    .foregroundStyle(Color("AppTextPrimary"))

                Text("·")
                    .foregroundStyle(Color("AppTextSecondary"))

                Text("~\(practice.estimatedMinutes) min")
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextSecondary"))
            }

            // Breakdown
            HStack(spacing: Theme.Spacing.lg) {
                HStack(spacing: Theme.Spacing.xs) {
                    Circle()
                        .fill(Color("FeedbackSuccess"))
                        .frame(width: Theme.Spacing.sm, height: Theme.Spacing.sm)
                    Text("\(practice.learningCount) learning")
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                HStack(spacing: Theme.Spacing.xs) {
                    Circle()
                        .fill(Color("FeedbackInfo"))
                        .frame(width: Theme.Spacing.sm, height: Theme.Spacing.sm)
                    Text("\(practice.reviewingCount) reviewing")
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }

            // CTA Button
            HStack {
                Spacer()

                Text("Start Practice")
                    .font(Typography.Command.cta)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .fill(Color("AppAccentAction"))
                    )

                Spacer()
            }
            .padding(.top, Theme.Spacing.xs)
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

#Preview("Practice Card") {
    @Previewable @Environment(\.colorScheme) var colorScheme

    ZStack {
        Color.appBackground.ignoresSafeArea()

        PracticeCard(practice: SanctuaryMockData.practiceData)
            .padding()
    }
}

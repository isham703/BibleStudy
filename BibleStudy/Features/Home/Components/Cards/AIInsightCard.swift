import SwiftUI

// MARK: - AI Insight Card
// Displays AI-generated insight with flat styling
// Stoic-Existential Renaissance design

struct AIInsightCard: View {
    let insight: MockAIInsight
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(Typography.Icon.md)
                    .foregroundStyle(Color("AccentBronze"))

                Text(insight.title)
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))
            }

            // Summary
            Text(insight.summary)
                .font(Typography.Scripture.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineSpacing(6)

            // Explore button
            HStack {
                Spacer()

                Text("Explore")
                    .font(Typography.Command.cta)
                    .foregroundStyle(Color("AppAccentAction"))
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .stroke(
                                Color("AppAccentAction"),
                                lineWidth: Theme.Stroke.control
                            )
                    )
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

#Preview {
    @Previewable @Environment(\.colorScheme) var colorScheme

    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: Theme.Spacing.xl) {
            AIInsightCard(insight: SanctuaryMockData.currentInsight)
        }
        .padding()
    }
}

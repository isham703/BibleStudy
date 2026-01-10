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
                    .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))

                Text(insight.title)
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
            }

            // Summary
            Text(insight.summary)
                .font(Typography.Scripture.body)
                .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                .lineSpacing(6)

            // Explore button
            HStack {
                Spacer()

                Text("Explore")
                    .font(Typography.Command.cta)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .stroke(
                                Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)),
                                lineWidth: Theme.Stroke.control
                            )
                    )
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

#Preview {
    @Previewable @Environment(\.colorScheme) var colorScheme
    let themeMode = ThemeMode.current(from: colorScheme)

    ZStack {
        Colors.Surface.background(for: themeMode).ignoresSafeArea()

        VStack(spacing: Theme.Spacing.xl) {
            AIInsightCard(insight: SanctuaryMockData.currentInsight)
        }
        .padding()
    }
}

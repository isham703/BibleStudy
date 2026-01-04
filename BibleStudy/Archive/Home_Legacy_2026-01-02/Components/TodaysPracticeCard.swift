import SwiftUI

// MARK: - Today's Practice Card
// Featured card showing memorization items due for review

struct TodaysPracticeCard: View {
    let dueCount: Int
    let learningCount: Int
    let reviewingCount: Int
    let estimatedMinutes: Int
    let onPractice: () -> Void

    var body: some View {
        Button(action: onPractice) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                // Label
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "brain.head.profile")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.accentGold)

                    Text("Today's Practice")
                        .font(Typography.UI.caption1)
                        .fontWeight(.semibold)
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .foregroundStyle(Color.accentGold)

                    Spacer()

                    // Mastery badges
                    if learningCount > 0 || reviewingCount > 0 {
                        HStack(spacing: AppTheme.Spacing.xxs) {
                            if learningCount > 0 {
                                MasteryBadge(level: .learning, count: learningCount)
                            }
                            if reviewingCount > 0 {
                                MasteryBadge(level: .reviewing, count: reviewingCount)
                            }
                        }
                    }
                }

                // Title
                Text("\(dueCount) verse\(dueCount == 1 ? "" : "s") due for review")
                    .font(Typography.Display.headline)
                    .foregroundStyle(Color.primaryText)

                // Footer
                HStack {
                    // Estimated time
                    HStack(spacing: AppTheme.Spacing.xxs) {
                        Image(systemName: "clock")
                            .font(Typography.UI.caption2)
                        Text("~\(estimatedMinutes) min")
                            .font(Typography.UI.caption2.monospacedDigit())
                    }
                    .foregroundStyle(Color.tertiaryText)

                    Spacer()

                    // Action
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Text("Practice Now")
                            .font(Typography.UI.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "arrow.right")
                            .font(Typography.UI.caption1)
                    }
                    .foregroundStyle(Color.accentGold)
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .fill(Color.surfaceBackground)
            )
            // Featured card gold accent at top
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.accentGold, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: AppTheme.Divider.medium)
                    .padding(.horizontal, AppTheme.Spacing.xl - 4)
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .stroke(Color.accentGold.opacity(AppTheme.Opacity.lightMedium), lineWidth: AppTheme.Border.thin)
            )
            .shadow(color: Color.black.opacity(AppTheme.Opacity.faint - 0.02), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State Variant

struct TodaysPracticeEmptyCard: View {
    let onAddVerse: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Label
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "brain.head.profile")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.accentGold)

                Text("Start Memorizing")
                    .font(Typography.UI.caption1)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(Color.accentGold)
            }

            // Title
            Text("Build lasting memory")
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)

            // Subtitle
            Text("Add your first verse to begin memorizing Scripture with spaced repetition.")
                .font(Typography.UI.subheadline)
                .foregroundStyle(Color.secondaryText)
                .lineLimit(2)

            // Action button
            Button(action: onAddVerse) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Verse")
                }
                .font(Typography.UI.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.accentGold)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(Color.accentGold.opacity(AppTheme.Opacity.subtle))
                )
            }
            .buttonStyle(.plain)
            .padding(.top, AppTheme.Spacing.xs)
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
        )
        .shadow(color: Color.black.opacity(AppTheme.Opacity.faint - 0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - All Caught Up Variant

struct TodaysPracticeCaughtUpCard: View {
    let masteredCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Label
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.success)

                Text("All Caught Up!")
                    .font(Typography.UI.caption1)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(Color.success)
            }

            // Title
            Text("Great work today")
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)

            // Stats
            HStack(spacing: AppTheme.Spacing.lg) {
                if masteredCount > 0 {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.success)
                        Text("\(masteredCount) mastered")
                            .font(Typography.UI.caption2)
                            .foregroundStyle(Color.secondaryText)
                    }
                }

                Text("Check back tomorrow")
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.tertiaryText)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(Color.success.opacity(AppTheme.Opacity.lightMedium), lineWidth: AppTheme.Border.thin)
        )
        .shadow(color: Color.black.opacity(AppTheme.Opacity.faint - 0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Mastery Badge

private struct MasteryBadge: View {
    let level: MasteryLevel
    let count: Int

    private var color: Color {
        switch level {
        case .learning:
            return .lapisLazuli
        case .reviewing:
            return .accentGold
        case .mastered:
            return .success
        }
    }

    private var icon: String {
        switch level {
        case .learning:
            return "book.pages"
        case .reviewing:
            return "arrow.clockwise"
        case .mastered:
            return "checkmark.seal.fill"
        }
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            Image(systemName: icon)
                .font(Typography.UI.iconXxs)
            Text("\(count)")
                .font(Typography.UI.caption2.monospacedDigit())
        }
        .foregroundStyle(color)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xxs)
        .background(
            Capsule()
                .fill(color.opacity(AppTheme.Opacity.subtle + 0.02))
        )
    }
}

// MARK: - Previews

#Preview("With Due Items") {
    TodaysPracticeCard(
        dueCount: 3,
        learningCount: 2,
        reviewingCount: 1,
        estimatedMinutes: 5,
        onPractice: {}
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("Single Item") {
    TodaysPracticeCard(
        dueCount: 1,
        learningCount: 0,
        reviewingCount: 1,
        estimatedMinutes: 2,
        onPractice: {}
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("Empty State") {
    TodaysPracticeEmptyCard(onAddVerse: {})
        .padding()
        .background(Color.appBackground)
}

#Preview("All Caught Up") {
    TodaysPracticeCaughtUpCard(masteredCount: 12)
        .padding()
        .background(Color.appBackground)
}

import SwiftUI

// MARK: - Today's Reading Card
// Shows current reading plan progress with today's passage

struct TodaysReadingCard: View {
    let planTitle: String
    let currentDay: Int
    let totalDays: Int
    let todayReference: String
    let progressPercentage: Double
    let onContinue: () -> Void

    var body: some View {
        Button(action: onContinue) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                // Label
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "book.fill")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.accentGold)

                    Text("Today's Reading")
                        .font(Typography.UI.caption1)
                        .fontWeight(.semibold)
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .foregroundStyle(Color.accentGold)
                }

                // Plan title
                Text(planTitle)
                    .font(Typography.Display.headline)
                    .foregroundStyle(Color.primaryText)

                // Today's passage
                HStack {
                    Text("Day \(currentDay) of \(totalDays)")
                        .font(Typography.UI.caption1.monospacedDigit())
                        .foregroundStyle(Color.tertiaryText)

                    Text("•")
                        .foregroundStyle(Color.tertiaryText)

                    Text(todayReference)
                        .font(Typography.UI.subheadline)
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(1)
                }

                // Progress bar with shimmer
                ReadingProgressBar(progress: progressPercentage)

                // Footer
                HStack {
                    Text("\(Int(progressPercentage * 100))% complete")
                        .font(Typography.UI.caption2.monospacedDigit())
                        .foregroundStyle(Color.tertiaryText)

                    Spacer()

                    HStack(spacing: AppTheme.Spacing.xs) {
                        Text("Continue")
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
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
            .shadow(color: Color.black.opacity(AppTheme.Opacity.faint - 0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State Variant

struct TodaysReadingEmptyCard: View {
    let onBrowsePlans: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Label
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "book.fill")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.lapisLazuli)

                Text("Reading Plans")
                    .font(Typography.UI.caption1)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(Color.lapisLazuli)
            }

            // Title
            Text("Journey through Scripture")
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)

            // Subtitle
            Text("Choose a reading plan to guide your daily study with structured passages.")
                .font(Typography.UI.subheadline)
                .foregroundStyle(Color.secondaryText)
                .lineLimit(2)

            // Action button
            Button(action: onBrowsePlans) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Browse Plans")
                }
                .font(Typography.UI.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.lapisLazuli)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(Color.lapisLazuli.opacity(AppTheme.Opacity.subtle))
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

// MARK: - Progress Bar with Shimmer

private struct ReadingProgressBar: View {
    let progress: Double

    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xs + 1)
                    .fill(Color.parchmentShadow)

                // Progress fill
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xs + 1)
                    .fill(
                        LinearGradient(
                            colors: [Color.goldBurnished, Color.accentGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(progress))
                    // Shimmer overlay
                    .overlay(
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(AppTheme.Opacity.medium), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 40)
                        .offset(x: shimmerOffset * geometry.size.width * CGFloat(progress))
                        .mask(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xs + 1)
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xs + 1))
            }
        }
        .frame(height: AppTheme.Divider.heavy)
        .onAppear {
            withAnimation(AppTheme.Animation.shimmer) {
                shimmerOffset = 1
            }
        }
    }
}

// MARK: - Helper Extension

private extension Color {
    static var parchmentShadow: Color {
        Color.agedParchment
    }

    static var goldBurnished: Color {
        Color.burnishedGold
    }
}

// MARK: - Previews

#Preview("Active Plan") {
    TodaysReadingCard(
        planTitle: "Gospel of John",
        currentDay: 8,
        totalDays: 21,
        todayReference: "John 8:1-59",
        progressPercentage: 0.38,
        onContinue: {}
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("Nearly Complete") {
    TodaysReadingCard(
        planTitle: "Psalms in 30 Days",
        currentDay: 28,
        totalDays: 30,
        todayReference: "Psalms 136-140",
        progressPercentage: 0.93,
        onContinue: {}
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("Empty State") {
    TodaysReadingEmptyCard(onBrowsePlans: {})
        .padding()
        .background(Color.appBackground)
}

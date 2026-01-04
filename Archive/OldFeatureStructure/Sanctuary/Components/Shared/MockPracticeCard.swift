import SwiftUI

// MARK: - Mock Practice Card
// Displays memorization practice status and CTA

struct MockPracticeCard: View {
    let practice: MockPracticeData

    var body: some View {
        VStack(alignment: .leading, spacing: HomeShowcaseTheme.Spacing.md) {
            // Header
            HStack {
                Text("\(practice.dueCount) verses due")
                    .font(HomeShowcaseTypography.Dashboard.cardTitle)
                    .foregroundStyle(Color.moonlitParchment)

                Text("·")
                    .foregroundStyle(Color.fadedMoonlight)

                Text("~\(practice.estimatedMinutes) min")
                    .font(HomeShowcaseTypography.Dashboard.cardBody)
                    .foregroundStyle(Color.fadedMoonlight)
            }

            // Breakdown
            HStack(spacing: HomeShowcaseTheme.Spacing.lg) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.malachite)
                        .frame(width: 8, height: 8)
                    Text("\(practice.learningCount) learning")
                        .font(HomeShowcaseTypography.Dashboard.cardBody)
                        .foregroundStyle(Color.fadedMoonlight)
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.lapisLazuli)
                        .frame(width: 8, height: 8)
                    Text("\(practice.reviewingCount) reviewing")
                        .font(HomeShowcaseTypography.Dashboard.cardBody)
                        .foregroundStyle(Color.fadedMoonlight)
                }
            }

            // CTA Button
            HStack {
                Spacer()

                Text("Start Practice")
                    .font(HomeShowcaseTypography.Dashboard.button)
                    .foregroundStyle(Color.candlelitStone)
                    .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)
                    .padding(.vertical, HomeShowcaseTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.small)
                            .fill(Color.divineGold)
                    )

                Spacer()
            }
            .padding(.top, HomeShowcaseTheme.Spacing.xs)
        }
        .padding(HomeShowcaseTheme.Spacing.lg)
        .glassCard()
    }
}

// MARK: - Compact Practice Card (for minimalist style)

struct MockPracticeCardCompact: View {
    let practice: MockPracticeData
    @State private var isPressed = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Practice Verses")
                    .font(HomeShowcaseTypography.Minimalist.action)
                    .foregroundStyle(Color.divineGold)

                Text("\(practice.dueCount) verses due")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.fadedMoonlight)
            }

            Spacer()

            Image(systemName: "arrow.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.divineGold)
                .offset(x: isPressed ? 4 : 0)
        }
        .padding(.vertical, HomeShowcaseTheme.Spacing.lg)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.candlelitStone.ignoresSafeArea()

        VStack(spacing: 20) {
            MockPracticeCard(practice: HomeShowcaseMockData.practiceData)

            MockPracticeCardCompact(practice: HomeShowcaseMockData.practiceData)
                .padding(.horizontal)
        }
        .padding()
    }
}

import SwiftUI

// MARK: - Tier Status Card
// Design Rationale: Displays subscription tier status with flat styling.
// Uses IconBadge for consistency, no shadows or glows.
// Premium/Scholar users get subtle background tint, free users get stroke border.
// Stoic-Existential Renaissance design

struct TierStatusCard: View {
    let tierName: String
    let tierDescription: String
    let tierIcon: String
    let isPremium: Bool
    let isScholar: Bool
    let showUpgradeButton: Bool
    let onUpgrade: (() -> Void)?

    init(
        tierName: String,
        tierDescription: String,
        tierIcon: String = "crown.fill",
        isPremium: Bool = false,
        isScholar: Bool = false,
        showUpgradeButton: Bool = false,
        onUpgrade: (() -> Void)? = nil
    ) {
        self.tierName = tierName
        self.tierDescription = tierDescription
        self.tierIcon = tierIcon
        self.isPremium = isPremium
        self.isScholar = isScholar
        self.showUpgradeButton = showUpgradeButton
        self.onUpgrade = onUpgrade
    }

    // Computed property for premium or higher status
    private var isPremiumOrHigher: Bool {
        isPremium || isScholar
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Tier icon - flat design, no glow
            // Rationale: IconBadge provides consistent flat styling
            IconBadge.settings(
                tierIcon,
                color: isPremiumOrHigher ? Color("AppAccentAction") : Color("AppTextSecondary")
            )

            // Tier info
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                HStack(spacing: Theme.Spacing.sm) {
                    Text(tierName)
                        .font(Typography.Command.cta)
                        .foregroundStyle(Color("AppTextPrimary"))

                    // Scholar badge
                    if isScholar {
                        Text("BEST VALUE")
                            .font(Typography.Command.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, Theme.Spacing.sm - 2)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color("AppAccentAction")))
                    }
                }

                Text(tierDescription)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }

            Spacer()

            // Upgrade button (only for free users)
            if showUpgradeButton, let onUpgrade = onUpgrade {
                Button {
                    HapticService.shared.lightTap()
                    onUpgrade()
                } label: {
                    Text("Upgrade")
                        .font(Typography.Command.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(Capsule().fill(Color("AppAccentAction")))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.Spacing.md)
        .background(cardBackground)
        .overlay(cardBorder)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tierName) tier, \(tierDescription)")
    }

    // MARK: - Card Background
    // Premium users get subtle accent tint, free users get transparent

    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card)
            .fill(isPremiumOrHigher
                ? Color("AppAccentAction").opacity(Theme.Opacity.subtle)
                : Color.clear)
    }

    // MARK: - Card Border
    // Hairline stroke - no shadows per design system

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card)
            .stroke(
                isPremiumOrHigher
                    ? Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground)
                    : Color.appDivider.opacity(Theme.Opacity.textSecondary),
                lineWidth: Theme.Stroke.hairline
            )
    }
}

// MARK: - Preview

#Preview("Free User") {
    VStack(spacing: Theme.Spacing.lg) {
        SettingsCard(title: "Subscription", icon: "crown.fill") {
            TierStatusCard(
                tierName: "Free",
                tierDescription: "Basic features with daily limits",
                tierIcon: "person.fill",
                isPremium: false,
                showUpgradeButton: true,
                onUpgrade: { print("Upgrade tapped") }
            )
        }
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Premium User") {
    VStack(spacing: Theme.Spacing.lg) {
        SettingsCard(title: "Subscription", icon: "crown.fill") {
            TierStatusCard(
                tierName: "Premium",
                tierDescription: "Unlimited insights, notes, and translations",
                tierIcon: "crown.fill",
                isPremium: true
            )
        }
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Scholar User") {
    VStack(spacing: Theme.Spacing.lg) {
        SettingsCard(title: "Subscription", icon: "crown.fill") {
            TierStatusCard(
                tierName: "Scholar",
                tierDescription: "All Premium features plus Hebrew & Greek",
                tierIcon: "graduationcap.fill",
                isPremium: true,
                isScholar: true
            )
        }
    }
    .padding()
    .background(Color.appBackground)
}

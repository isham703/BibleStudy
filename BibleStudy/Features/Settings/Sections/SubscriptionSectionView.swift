import SwiftUI

// MARK: - Subscription Section View
// Displays subscription status, upgrade CTAs, and usage statistics

struct SubscriptionSectionView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        IlluminatedSettingsCard(title: "Subscription", icon: "crown.fill") {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Tier status card
                tierStatusCard

                if viewModel.isPremiumOrHigher {
                    // Premium/Scholar: Show status and manage button
                    premiumContent
                } else {
                    // Free: Show usage stats and upgrade CTA
                    freeContent
                }
            }
        }
    }

    // MARK: - Tier Status Card

    private var tierStatusCard: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Tier icon with glow
            ZStack {
                // Glow effect for premium tiers
                if viewModel.isPremiumOrHigher {
                    Circle()
                        .fill(tierColor.opacity(AppTheme.Opacity.lightMedium))
                        .blur(radius: AppTheme.Blur.medium)
                        .frame(width: 48, height: 48)
                }

                Image(systemName: viewModel.tierIcon)
                    .font(Typography.UI.iconXl.weight(.medium))
                    .foregroundStyle(tierColor)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(tierColor.opacity(AppTheme.Opacity.subtle + 0.02))
                    )
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(viewModel.tierDisplayName)
                        .font(Typography.Display.headline)
                        .foregroundStyle(Color.primaryText)

                    if viewModel.isScholar {
                        Text("BEST VALUE")
                            .font(Typography.UI.iconXxxs.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, AppTheme.Spacing.sm - 2)
                            .padding(.vertical, AppTheme.Spacing.xxs)
                            .background(Capsule().fill(Color.scholarAccent))
                    }
                }

                Text(viewModel.tierDescription)
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.secondaryText)
            }

            Spacer()

            if !viewModel.isPremiumOrHigher {
                upgradeButton
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(tierBackgroundGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(tierColor.opacity(AppTheme.Opacity.lightMedium), lineWidth: AppTheme.Border.thin)
        )
    }

    private var upgradeButton: some View {
        Button(action: { viewModel.showUpgradePaywall() }) {
            Text("Upgrade")
                .font(Typography.UI.caption1)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(Color.scholarAccent)
                )
        }
    }

    // MARK: - Free User Content

    private var freeContent: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Usage statistics
            UsageStatisticsView(
                aiInsightsUsed: viewModel.aiInsightsUsed,
                aiInsightsTotal: viewModel.aiInsightsTotal,
                highlightsUsed: viewModel.highlightsUsed,
                highlightsTotal: viewModel.highlightsTotal,
                notesUsed: viewModel.notesUsed,
                notesTotal: viewModel.notesTotal,
                onUpgrade: { viewModel.showUpgradePaywall() }
            )

            // Feature preview
            featurePreview

            // Restore purchases
            restorePurchasesButton
        }
    }

    private var featurePreview: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Unlock with Premium:")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                featureRow(icon: "text.book.closed", text: "All Bible translations")
                featureRow(icon: "sparkles", text: "Unlimited AI insights")
                featureRow(icon: "note.text", text: "Unlimited notes")
            }
        }
        .padding(.top, AppTheme.Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(Typography.UI.iconXs)
                .foregroundStyle(Color.scholarAccent)
                .frame(width: 20)

            Text(text)
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.primaryText)
        }
    }

    // MARK: - Premium User Content

    private var premiumContent: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Features summary
            premiumFeaturesSummary

            SettingsDivider()

            // Renewal info
            if let renewalDate = viewModel.formattedRenewalDate {
                HStack {
                    Image(systemName: "calendar")
                        .font(Typography.UI.iconSm)
                        .foregroundStyle(Color.secondaryText)

                    Text("Renews \(renewalDate)")
                        .font(Typography.UI.subheadline)
                        .foregroundStyle(Color.secondaryText)

                    Spacer()
                }
            }

            // Manage subscription button
            manageSubscriptionButton

            // Restore purchases
            restorePurchasesButton
        }
    }

    private var premiumFeaturesSummary: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Your benefits:")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.xs) {
                featureBadge(icon: "checkmark.circle.fill", text: "All translations")
                featureBadge(icon: "checkmark.circle.fill", text: "Unlimited AI")
                featureBadge(icon: "checkmark.circle.fill", text: "Unlimited notes")
                if viewModel.isScholar {
                    featureBadge(icon: "checkmark.circle.fill", text: "Hebrew & Greek")
                }
            }
        }
    }

    private func featureBadge(icon: String, text: String) -> some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            Image(systemName: icon)
                .font(Typography.UI.iconXxs)
                .foregroundStyle(Color.success)

            Text(text)
                .font(Typography.UI.caption2)
                .foregroundStyle(Color.primaryText)
        }
    }

    private var manageSubscriptionButton: some View {
        Button(action: {
            Task { await viewModel.manageSubscription() }
        }) {
            HStack {
                Image(systemName: "gearshape")
                    .font(Typography.UI.iconSm)
                Text("Manage Subscription")
                    .font(Typography.UI.subheadline)
            }
            .foregroundStyle(Color.scholarAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(Color.scholarAccent.opacity(AppTheme.Opacity.medium), lineWidth: AppTheme.Border.thin)
            )
        }
    }

    private var restorePurchasesButton: some View {
        Button(action: {
            Task { await viewModel.restorePurchases() }
        }) {
            HStack(spacing: AppTheme.Spacing.xs) {
                if viewModel.isRestoringPurchases {
                    ProgressView()
                        .scaleEffect(AppTheme.Scale.reduced)
                        .tint(Color.tertiaryText)
                } else {
                    Image(systemName: "arrow.counterclockwise")
                        .font(Typography.UI.iconXs)
                }
                Text("Restore Purchases")
                    .font(Typography.UI.caption1)
            }
            .foregroundStyle(Color.tertiaryText)
        }
        .disabled(viewModel.isRestoringPurchases)
    }

    // MARK: - Styling Helpers

    private var tierColor: Color {
        switch viewModel.currentTier {
        case .free: return Color.secondaryText
        case .premium: return Color.scholarAccent
        case .scholar: return Color.scholarAccent
        }
    }

    private var tierBackgroundGradient: LinearGradient {
        if viewModel.isScholar {
            // Scholar tier: Subtle gold hint without heavy layering
            return LinearGradient(
                colors: [
                    Color.scholarAccent.opacity(AppTheme.Opacity.faint - 0.04),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if viewModel.isPremiumOrHigher {
            // Premium tier: Very subtle warmth
            return LinearGradient(
                colors: [
                    Color.scholarAccent.opacity(AppTheme.Opacity.faint - 0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Free tier: Transparent
            return LinearGradient(
                colors: [Color.clear, Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Preview

#Preview("Subscription Section - Free") {
    ScrollView {
        SubscriptionSectionView(viewModel: SettingsViewModel())
            .padding()
    }
    .background(Color.appBackground)
}

import SwiftUI

// MARK: - Subscription Section View
// Displays subscription status, upgrade CTAs, and usage statistics

struct SubscriptionSectionView: View {
    @Bindable var viewModel: SettingsViewModel

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        IlluminatedSettingsCard(title: "Subscription", icon: "crown.fill") {
            VStack(spacing: Theme.Spacing.lg) {
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
        HStack(spacing: Theme.Spacing.md) {
            // Tier icon with glow
            ZStack {
                // Glow effect for premium tiers
                if viewModel.isPremiumOrHigher {
                    Circle()
                        .fill(tierColor.opacity(Theme.Opacity.lightMedium))
                        .blur(radius: 8)
                        .frame(width: 48, height: 48)
                }

                Image(systemName: viewModel.tierIcon)
                    .font(Typography.Icon.xl.weight(.medium))
                    .foregroundStyle(tierColor)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(tierColor.opacity(Theme.Opacity.faint + 0.02))
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Theme.Spacing.sm) {
                    Text(viewModel.tierDisplayName)
                        .font(Typography.Scripture.heading)
                        .foregroundStyle(Color.primaryText)

                    if viewModel.isScholar {
                        Text("BEST VALUE")
                            .font(Typography.Icon.xxxs.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, Theme.Spacing.sm - 2)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))))
                    }
                }

                Text(viewModel.tierDescription)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.secondaryText)
            }

            Spacer()

            if !viewModel.isPremiumOrHigher {
                upgradeButton
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(tierBackgroundGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(tierColor.opacity(Theme.Opacity.lightMedium), lineWidth: Theme.Stroke.hairline)
        )
    }

    private var upgradeButton: some View {
        Button(action: { viewModel.showUpgradePaywall() }) {
            Text("Upgrade")
                .font(Typography.Command.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                )
        }
    }

    // MARK: - Free User Content

    private var freeContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
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
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Unlock with Premium:")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.secondaryText)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                featureRow(icon: "text.book.closed", text: "All Bible translations")
                featureRow(icon: "sparkles", text: "Unlimited AI insights")
                featureRow(icon: "note.text", text: "Unlimited notes")
            }
        }
        .padding(.top, Theme.Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(Typography.Icon.xs)
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                .frame(width: 20)

            Text(text)
                .font(Typography.Command.caption)
                .foregroundStyle(Color.primaryText)
        }
    }

    // MARK: - Premium User Content

    private var premiumContent: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Features summary
            premiumFeaturesSummary

            SettingsDivider()

            // Renewal info
            if let renewalDate = viewModel.formattedRenewalDate {
                HStack {
                    Image(systemName: "calendar")
                        .font(Typography.Icon.sm)
                        .foregroundStyle(Color.secondaryText)

                    Text("Renews \(renewalDate)")
                        .font(Typography.Command.subheadline)
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
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Your benefits:")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.secondaryText)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.xs) {
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
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(Typography.Icon.xxs)
                .foregroundStyle(Color.success)

            Text(text)
                .font(Typography.Command.meta)
                .foregroundStyle(Color.primaryText)
        }
    }

    private var manageSubscriptionButton: some View {
        Button(action: {
            Task { await viewModel.manageSubscription() }
        }) {
            HStack {
                Image(systemName: "gearshape")
                    .font(Typography.Icon.sm)
                Text("Manage Subscription")
                    .font(Typography.Command.subheadline)
            }
            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary), lineWidth: Theme.Stroke.hairline)
            )
        }
    }

    private var restorePurchasesButton: some View {
        Button(action: {
            Task { await viewModel.restorePurchases() }
        }) {
            HStack(spacing: Theme.Spacing.xs) {
                if viewModel.isRestoringPurchases {
                    ProgressView()
                        .scaleEffect(0.95)
                        .tint(Color.tertiaryText)
                } else {
                    Image(systemName: "arrow.counterclockwise")
                        .font(Typography.Icon.xs)
                }
                Text("Restore Purchases")
                    .font(Typography.Command.caption)
            }
            .foregroundStyle(Color.tertiaryText)
        }
        .disabled(viewModel.isRestoringPurchases)
    }

    // MARK: - Styling Helpers

    private var tierColor: Color {
        switch viewModel.currentTier {
        case .free: return Color.secondaryText
        case .premium: return Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))
        case .scholar: return Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))
        }
    }

    private var tierBackgroundGradient: LinearGradient {
        if viewModel.isScholar {
            // Scholar tier: Subtle gold hint without heavy layering
            return LinearGradient(
                colors: [
                    Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint - 0.04),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if viewModel.isPremiumOrHigher {
            // Premium tier: Very subtle warmth
            return LinearGradient(
                colors: [
                    Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint - 0.05),
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

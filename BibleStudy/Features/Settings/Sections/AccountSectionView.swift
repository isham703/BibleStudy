import SwiftUI

// MARK: - Account Section View
// Displays user account status with illuminated profile card

struct AccountSectionView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        IlluminatedSettingsCard(title: "Account", icon: "person.fill") {
            if viewModel.isAuthenticated {
                NavigationLink {
                    AccountDetailView(viewModel: viewModel)
                } label: {
                    authenticatedContent
                }
                .buttonStyle(.plain)
            } else {
                signInPrompt
            }
        }
    }

    // MARK: - Authenticated Content

    private var authenticatedContent: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Avatar with gold border
            avatarView

            // User info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(viewModel.displayName ?? "Bible Student")
                    .font(Typography.Display.headline)
                    .foregroundStyle(Color.primaryText)

                if let email = viewModel.email {
                    Text(email)
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.secondaryText)
                }

                // Tier badge
                tierBadge
            }

            Spacer()

            // Edit profile chevron
            Image(systemName: "chevron.right")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.tertiaryText)
        }
        .contentShape(Rectangle())
    }

    private var avatarView: some View {
        ZStack {
            // Gold glow
            Circle()
                .fill(Color.accentGold.opacity(AppTheme.Opacity.light))
                .blur(radius: AppTheme.Blur.light + 1)
                .frame(width: 56, height: 56)

            // Avatar background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentGold.opacity(AppTheme.Opacity.lightMedium),
                            Color.accentGold.opacity(AppTheme.Opacity.subtle)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)

            // Avatar icon
            Image(systemName: "person.fill")
                .font(Typography.UI.iconXl.weight(.medium))
                .foregroundStyle(Color.accentGold)

            // Gold border
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.accentGold.opacity(AppTheme.Opacity.strong),
                            Color.accentGold.opacity(AppTheme.Opacity.medium),
                            Color.accentGold.opacity(AppTheme.Opacity.strong)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: AppTheme.Border.regular
                )
                .frame(width: 52, height: 52)
        }
    }

    private var tierBadge: some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            Image(systemName: viewModel.tierIcon)
                .font(Typography.UI.iconXxs)

            Text(viewModel.tierDisplayName)
                .font(Typography.UI.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xxs)
        .background(
            Capsule()
                .fill(badgeColor.opacity(AppTheme.Opacity.subtle + 0.02))
        )
    }

    private var badgeColor: Color {
        switch viewModel.currentTier {
        case .free: return Color.secondaryText
        case .premium, .scholar: return Color.accentGold
        }
    }

    // MARK: - Sign In Prompt

    private var signInPrompt: some View {
        NavigationLink {
            AuthView()
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.accentGold.opacity(AppTheme.Opacity.subtle + 0.02))
                        .frame(width: 52, height: 52)

                    Image(systemName: "person.circle")
                        .font(.system(size: Typography.Scale.xl + 6, weight: .light))
                        .foregroundStyle(Color.accentGold)
                }

                // Text content
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text("Sign In")
                        .font(Typography.Display.headline)
                        .foregroundStyle(Color.primaryText)

                    Text("Sync highlights and notes across devices")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Account Section") {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Authenticated state
            AccountSectionView(viewModel: SettingsViewModel())

            // This would show signed out state in real app
            AccountSectionView(viewModel: SettingsViewModel())
        }
        .padding()
    }
    .background(Color.appBackground)
}

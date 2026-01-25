import SwiftUI

// MARK: - Account Section View
// Design Rationale: Displays user account status with flat styling.
// NO glows or shadows per design system - uses gradient stroke only.
// Stoic-Existential Renaissance design

struct AccountSectionView: View {
    @Bindable var viewModel: SettingsViewModel

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        SettingsCard(title: "Account", icon: "person.fill") {
            VStack(spacing: 0) {
                if viewModel.isAuthenticated {
                    NavigationLink {
                        AccountDetailView(viewModel: viewModel)
                    } label: {
                        authenticatedContent
                    }
                    .buttonStyle(.plain)

                    SettingsDivider()
                        .padding(.vertical, Theme.Spacing.md)

                    // Sign out row
                    signOutRow
                } else {
                    signInPrompt
                }
            }
        }
    }

    // MARK: - Sign Out Row

    private var signOutRow: some View {
        Button {
            viewModel.showSignOutConfirmation = true
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                IconBadge.settings("rectangle.portrait.and.arrow.right", color: Color("FeedbackError"))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Sign Out")
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("FeedbackError"))

                    if let email = viewModel.email {
                        Text(email)
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Authenticated Content

    private var authenticatedContent: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Avatar with gold border
            avatarView

            // User info
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.displayName ?? "Bible Student")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                if let email = viewModel.email {
                    Text(email)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                // Tier badge
                tierBadge
            }

            Spacer()

            // Edit profile chevron
            Image(systemName: "chevron.right")
                .font(Typography.Command.caption)
                .foregroundStyle(Color("TertiaryText"))
        }
        .contentShape(Rectangle())
    }

    // MARK: - Avatar View
    // Design Rationale: FLAT design - no glow/blur per design system.
    // Uses gradient stroke border for visual interest.

    private var avatarView: some View {
        ZStack {
            // Avatar background - solid fill, no gradient glow
            Circle()
                .fill(Color.appSurface)
                .frame(width: 52, height: 52)

            // Avatar icon
            Image(systemName: "person.fill")
                .font(Typography.Icon.xl.weight(.medium))
                .foregroundStyle(Color("AppAccentAction"))

            // Gradient stroke border - the ONE decorative element
            // This is acceptable because it's a stroke, not a glow
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color("AppAccentAction").opacity(Theme.Opacity.textPrimary),
                            Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: Theme.Stroke.control
                )
                .frame(width: 52, height: 52)
        }
    }

    private var tierBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: viewModel.tierIcon)
                .font(Typography.Icon.xxs)

            Text(viewModel.tierDisplayName)
                .font(Typography.Command.meta)
                .fontWeight(.medium)
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(badgeColor.opacity(Theme.Opacity.subtle + 0.02))
        )
    }

    private var badgeColor: Color {
        switch viewModel.currentTier {
        case .free: return Color("AppTextSecondary")
        case .premium, .scholar: return Color("AppAccentAction")
        }
    }

    // MARK: - Sign In Prompt

    private var signInPrompt: some View {
        NavigationLink {
            AuthView()
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color("AppAccentAction").opacity(Theme.Opacity.subtle + 0.02))
                        .frame(width: 52, height: 52)

                    Image(systemName: "person.circle")
                        .font(Typography.Icon.xl.weight(.light))
                        .foregroundStyle(Color("AppAccentAction"))
                }

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sign In")
                        .font(Typography.Scripture.heading)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text("Sync highlights and notes across devices")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Account Section") {
    ScrollView {
        VStack(spacing: Theme.Spacing.xl) {
            // Authenticated state
            AccountSectionView(viewModel: SettingsViewModel())

            // This would show signed out state in real app
            AccountSectionView(viewModel: SettingsViewModel())
        }
        .padding()
    }
    .background(Color.appBackground)
}

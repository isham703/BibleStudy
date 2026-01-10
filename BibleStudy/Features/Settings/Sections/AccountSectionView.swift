import SwiftUI

// MARK: - Account Section View
// Displays user account status with illuminated profile card

struct AccountSectionView: View {
    @Bindable var viewModel: SettingsViewModel

    @Environment(\.colorScheme) private var colorScheme

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
        HStack(spacing: Theme.Spacing.md) {
            // Avatar with gold border
            avatarView

            // User info
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.displayName ?? "Bible Student")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color.primaryText)

                if let email = viewModel.email {
                    Text(email)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.secondaryText)
                }

                // Tier badge
                tierBadge
            }

            Spacer()

            // Edit profile chevron
            Image(systemName: "chevron.right")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.tertiaryText)
        }
        .contentShape(Rectangle())
    }

    private var avatarView: some View {
        ZStack {
            // Gold glow
            Circle()
                .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light))
                .blur(radius: 4 + 1)
                .frame(width: 56, height: 56)

            // Avatar background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium),
                            Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)

            // Avatar icon
            Image(systemName: "person.fill")
                .font(Typography.Icon.xl.weight(.medium))
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

            // Gold border
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.primary),
                            Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary),
                            Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.primary)
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
                .fill(badgeColor.opacity(Theme.Opacity.faint + 0.02))
        )
    }

    private var badgeColor: Color {
        switch viewModel.currentTier {
        case .free: return Color.secondaryText
        case .premium, .scholar: return Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))
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
                        .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint + 0.02))
                        .frame(width: 52, height: 52)

                    Image(systemName: "person.circle")
                        .font(Typography.Icon.xl.weight(.light))
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                }

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sign In")
                        .font(Typography.Scripture.heading)
                        .foregroundStyle(Color.primaryText)

                    Text("Sync highlights and notes across devices")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.tertiaryText)
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

import SwiftUI

// MARK: - Reading Section View
// Coordinator view for reading preferences with expandable appearance settings

struct ReadingSectionView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    @State private var showClearCacheConfirmation = false
    @State private var isAppearanceExpanded = false
    @State private var showAdvanced = false
    @State private var revealPhase: Int = 0

    // User preferences
    @AppStorage(AppConfiguration.UserDefaultsKeys.usePagedReader) private var usePagedReader: Bool = false
    @AppStorage(AppConfiguration.UserDefaultsKeys.devotionalModeEnabled) private var devotionalModeEnabled: Bool = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Reading Settings Card with Expandable Appearance
            SettingsCard(title: "Reading", icon: "book.fill") {
                VStack(spacing: Theme.Spacing.lg) {
                    // Expandable Reading Appearance Section
                    ReadingAppearanceSection(
                        viewModel: viewModel,
                        isExpanded: $isAppearanceExpanded,
                        showAdvanced: $showAdvanced,
                        revealPhase: $revealPhase,
                        usePagedReader: $usePagedReader
                    )

                    SettingsDivider()

                    // Translation selector
                    translationRow

                    SettingsDivider()

                    // Devotional mode toggle
                    SettingsToggle(
                        isOn: $devotionalModeEnabled,
                        label: "Devotional Mode",
                        description: "Larger text with generous spacing for meditation",
                        icon: "sparkles",
                        iconColor: Color.accentIndigo
                    )
                }
            }

            // Audio Cache Section
            AudioCacheSection(
                viewModel: viewModel,
                showClearCacheConfirmation: $showClearCacheConfirmation
            )
        }
    }

    // MARK: - Translation Row

    private var translationRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon
            Image(systemName: "book.closed.fill")
                .font(Typography.Icon.sm.weight(.medium))
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.input + 2)
                        .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint + 0.02))
                )

            // Label
            VStack(alignment: .leading, spacing: 2) {
                Text("Translation")
                    .font(Typography.Command.body)
                    .foregroundStyle(Color.primaryText)

                if !viewModel.isPremiumOrHigher {
                    Text("Upgrade to access all translations")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.tertiaryText)
                }
            }

            Spacer()

            // Current translation badge
            HStack(spacing: 2) {
                Text("KJV")
                    .font(Typography.Command.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                if !viewModel.isPremiumOrHigher {
                    Image(systemName: "lock.fill")
                        .font(Typography.Icon.xxxs)
                        .foregroundStyle(.white.opacity(Theme.Opacity.pressed))
                }
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !viewModel.isPremiumOrHigher {
                viewModel.showUpgradePaywall()
            }
            // TODO: Navigate to translation picker when premium
        }
    }
}

// MARK: - Preview

#Preview("Reading Section") {
    ScrollView {
        ReadingSectionView(viewModel: SettingsViewModel())
            .padding()
            .environment(AppState())
    }
    .background(Color.appBackground)
}

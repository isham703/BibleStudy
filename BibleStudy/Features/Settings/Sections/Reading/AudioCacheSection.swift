import SwiftUI

// MARK: - Audio Cache Section
// Audio cache limit, usage, and clear cache settings

struct AudioCacheSection: View {
    @Bindable var viewModel: SettingsViewModel
    @Binding var showClearCacheConfirmation: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        SettingsCard(title: "Audio", icon: "speaker.wave.2.fill") {
            VStack(spacing: Theme.Spacing.lg) {
                // Cache size picker
                audioCacheLimitRow

                SettingsDivider()

                // Current cache usage
                audioCacheUsageRow

                SettingsDivider()

                // Clear cache button
                clearCacheRow
            }
        }
        .alert("Clear Audio Cache?", isPresented: $showClearCacheConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                viewModel.clearAudioCache()
            }
        } message: {
            Text("This will delete all cached audio files. They will be regenerated when you play chapters again.")
        }
    }

    // MARK: - Cache Limit Row

    private var audioCacheLimitRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon
            Image(systemName: "internaldrive.fill")
                .font(Typography.Icon.sm.weight(.medium))
                .foregroundStyle(Color("AppAccentAction"))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.input + 2)
                        .fill(Color("AppAccentAction").opacity(Theme.Opacity.subtle + 0.02))
                )

            // Label
            VStack(alignment: .leading, spacing: 2) {
                Text("Cache Limit")
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text("Maximum storage for cached audio")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("TertiaryText"))
            }

            Spacer()

            // Picker
            Menu {
                ForEach(viewModel.audioCacheSizeOptions, id: \.mb) { option in
                    Button {
                        viewModel.audioCacheLimitMB = option.mb
                    } label: {
                        HStack {
                            Text(option.label)
                            if viewModel.audioCacheLimitMB == option.mb {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 2) {
                    Text(viewModel.audioCacheSizeOptions.first { $0.mb == viewModel.audioCacheLimitMB }?.label ?? "\(viewModel.audioCacheLimitMB) MB")
                        .font(Typography.Command.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("AppAccentAction"))

                    Image(systemName: "chevron.up.chevron.down")
                        .font(Typography.Icon.xxxs)
                        .foregroundStyle(Color("AppAccentAction").opacity(Theme.Opacity.pressed))
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color("AppAccentAction").opacity(Theme.Opacity.subtle))
                )
            }
        }
    }

    // MARK: - Cache Usage Row

    private var audioCacheUsageRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon
            Image(systemName: "chart.pie.fill")
                .font(Typography.Icon.sm.weight(.medium))
                .foregroundStyle(Color("AppTextSecondary"))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.input + 2)
                        .fill(Color("AppTextSecondary").opacity(Theme.Opacity.subtle + 0.02))
                )

            // Label
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Usage")
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text("Audio files are cached for 30 days")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("TertiaryText"))
            }

            Spacer()

            // Size badge
            Text(viewModel.audioCacheSize)
                .font(Typography.Command.caption.monospacedDigit())
                .fontWeight(.medium)
                .foregroundStyle(Color("AppTextSecondary"))
        }
    }

    // MARK: - Clear Cache Row

    private var clearCacheRow: some View {
        Button {
            showClearCacheConfirmation = true
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                Image(systemName: "trash.fill")
                    .font(Typography.Icon.sm.weight(.medium))
                    .foregroundStyle(Color("FeedbackError"))
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.input + 2)
                            .fill(Color("FeedbackError").opacity(Theme.Opacity.subtle + 0.02))
                    )

                // Label
                Text("Clear Audio Cache")
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextPrimary"))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Icon.xxxs)
                    .foregroundStyle(Color("TertiaryText"))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Audio Cache Section") {
    ScrollView {
        AudioCacheSection(
            viewModel: SettingsViewModel(),
            showClearCacheConfirmation: .constant(false)
        )
        .padding()
    }
    .background(Color.appBackground)
}

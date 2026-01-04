import SwiftUI

// MARK: - About Section View
// App info with colophon-style footer

struct AboutSectionView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        IlluminatedSettingsCard(title: "About", icon: "info.circle.fill", showDivider: false) {
            VStack(spacing: AppTheme.Spacing.md) {
                // Version info
                versionRow

                SettingsDivider()

                // Attributions
                NavigationLink {
                    AttributionsView()
                } label: {
                    aboutRow(
                        icon: "doc.text.fill",
                        iconColor: .lapisLazuli,
                        title: "Attributions & Licenses"
                    )
                }
                .buttonStyle(.plain)

                SettingsDivider()

                // Privacy Policy
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    aboutRow(
                        icon: "shield.fill",
                        iconColor: .malachite,
                        title: "Privacy Policy",
                        isExternal: true
                    )
                }

                SettingsDivider()

                // Terms of Service
                Link(destination: URL(string: "https://example.com/terms")!) {
                    aboutRow(
                        icon: "doc.plaintext.fill",
                        iconColor: .amethyst,
                        title: "Terms of Service",
                        isExternal: true
                    )
                }

                // Colophon footer
                colophonFooter
            }
        }
    }

    // MARK: - Version Row

    private var versionRow: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // App icon placeholder
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium + 2)
                .fill(
                    LinearGradient(
                        colors: [Color.accentGold, Color.accentGold.opacity(AppTheme.Opacity.overlay)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: AppTheme.IconSize.large - 4, weight: .medium))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text("BibleStudy")
                    .font(Typography.Display.headline)
                    .foregroundStyle(Color.primaryText)

                Text("Version \(AppConfiguration.App.version) (\(AppConfiguration.App.build))")
                    .font(Typography.UI.caption1.monospacedDigit())
                    .foregroundStyle(Color.secondaryText)
            }

            Spacer()
        }
    }

    // MARK: - About Row Helper

    private func aboutRow(
        icon: String,
        iconColor: Color,
        title: String,
        isExternal: Bool = false
    ) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(Typography.UI.iconSm.weight(.medium))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small + 2)
                        .fill(iconColor.opacity(AppTheme.Opacity.subtle + 0.02))
                )

            Text(title)
                .font(Typography.UI.body)
                .foregroundStyle(Color.primaryText)

            Spacer()

            Image(systemName: isExternal ? "arrow.up.right" : "chevron.right")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.tertiaryText)
        }
        .contentShape(Rectangle())
    }

    // MARK: - Colophon Footer

    private var colophonFooter: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            OrnamentalDivider(style: .sectionBreak, color: Color.accentGold.opacity(AppTheme.Opacity.disabled))

            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Made with care for Scripture study")
                    .font(Typography.Codex.italicTiny)
                    .foregroundStyle(Color.tertiaryText)

                // Small decorative cross or ornament
                Image(systemName: "cross.fill")
                    .font(Typography.UI.iconXxxs)
                    .foregroundStyle(Color.accentGold.opacity(AppTheme.Opacity.disabled))
            }
        }
        .padding(.top, AppTheme.Spacing.lg)
    }
}

// MARK: - Preview

#Preview("About Section") {
    NavigationStack {
        ScrollView {
            AboutSectionView(viewModel: SettingsViewModel())
                .padding()
        }
        .background(Color.appBackground)
    }
}

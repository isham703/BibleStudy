import SwiftUI

// MARK: - About Section View
// App info with colophon-style footer

struct AboutSectionView: View {
    @Bindable var viewModel: SettingsViewModel

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        SettingsCard(title: "About", icon: "info.circle.fill", showDivider: false) {
            VStack(spacing: Theme.Spacing.md) {
                // Version info
                versionRow

                SettingsDivider()

                // Attributions
                NavigationLink {
                    AttributionsView()
                } label: {
                    aboutRow(
                        icon: "doc.text.fill",
                        iconColor: Color("AppAccentAction"),
                        title: "Attributions & Licenses"
                    )
                }
                .buttonStyle(.plain)

                SettingsDivider()

                // Privacy Policy
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    aboutRow(
                        icon: "shield.fill",
                        iconColor: .feedbackSuccess,
                        title: "Privacy Policy",
                        isExternal: true
                    )
                }

                SettingsDivider()

                // Terms of Service
                Link(destination: URL(string: "https://example.com/terms")!) {
                    aboutRow(
                        icon: "doc.plaintext.fill",
                        iconColor: Color("AppAccentAction"),
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
        HStack(spacing: Theme.Spacing.md) {
            // App icon placeholder
            RoundedRectangle(cornerRadius: Theme.Radius.card + 2)
                .fill(
                    LinearGradient(
                        colors: [Color("AppAccentAction"), Color("AppAccentAction").opacity(Theme.Opacity.overlay)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                .overlay(
                    Image(systemName: "book.closed.fill")
                        .font(Typography.Icon.lg)
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("BibleStudy")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text("Version \(AppConfiguration.App.version) (\(AppConfiguration.App.build))")
                    .font(Typography.Command.caption.monospacedDigit())
                    .foregroundStyle(Color("AppTextSecondary"))
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
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(Typography.Icon.sm.weight(.medium))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.input + 2)
                        .fill(iconColor.opacity(Theme.Opacity.subtle + 0.02))
                )

            Text(title)
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextPrimary"))

            Spacer()

            Image(systemName: isExternal ? "arrow.up.right" : "chevron.right")
                .font(Typography.Command.caption)
                .foregroundStyle(Color("TertiaryText"))
        }
        .contentShape(Rectangle())
    }

    // MARK: - Colophon Footer

    private var colophonFooter: some View {
        VStack(spacing: Theme.Spacing.md) {
            Rectangle()
                .fill(Color("AppAccentAction").opacity(Theme.Opacity.disabled))
                .frame(height: Theme.Stroke.hairline)

            VStack(spacing: Theme.Spacing.xs) {
                Text("Made with care for Scripture study")
                    .font(Typography.Scripture.footnote.italic())
                    .foregroundStyle(Color("TertiaryText"))

                // Small decorative cross or ornament
                Image(systemName: "cross.fill")
                    .font(Typography.Icon.xxxs)
                    .foregroundStyle(Color("AppAccentAction").opacity(Theme.Opacity.disabled))
            }
        }
        .padding(.top, Theme.Spacing.lg)
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

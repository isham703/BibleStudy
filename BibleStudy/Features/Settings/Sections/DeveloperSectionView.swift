import SwiftUI

// MARK: - Developer Section View
// Internal tools and design showcases for team review

struct DeveloperSectionView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showOnboardingShowcase = false
    @State private var showPrayerShowcase = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        IlluminatedSettingsCard(title: "Design Studio", icon: "paintbrush.fill", showDivider: false) {
            VStack(spacing: Theme.Spacing.md) {
                // Design Showcase header
                showcaseHeader

                SettingsDivider()

                // Onboarding Showcase
                Button {
                    showOnboardingShowcase = true
                } label: {
                    developerRow(
                        icon: "rectangle.stack.fill",
                        iconColor: Color.accentIndigo,
                        title: "Sign Up / Onboarding",
                        subtitle: "3 page variations"
                    )
                }
                .buttonStyle(.plain)

                SettingsDivider()

                // Prayer Showcase (if exists)
                // COMMENTED OUT: Files not added to target yet
                // NavigationLink {
                //     PrayersFromDeepShowcaseView()
                // } label: {
                //     developerRow(
                //         icon: "hands.sparkles.fill",
                //         iconColor: .thresholdRose,
                //         title: "Prayer Experience",
                //         subtitle: "Design variations"
                //     )
                // }
                // .buttonStyle(.plain)

                SettingsDivider()

                // Home Page Showcase
                // COMMENTED OUT: Files not added to target yet
                // NavigationLink {
                //     HomePageShowcaseDirectoryView()
                // } label: {
                //     developerRow(
                //         icon: "building.columns.fill",
                //         iconColor: Color.decorativeTaupe,
                //         title: "Home Page Options",
                //         subtitle: "12 stoic design variations"
                //     )
                // }
                // .buttonStyle(.plain)

                // Info footer
                infoFooter
            }
        }
        // COMMENTED OUT: OnboardingShowcaseDirectory not added to target yet
        // .fullScreenCover(isPresented: $showOnboardingShowcase) {
        //     OnboardingShowcaseDirectory()
        // }
    }

    // MARK: - Showcase Header

    private var showcaseHeader: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Gradient badge
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(
                        LinearGradient(
                            colors: [
                                Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light),
                                Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.overlay)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: "sparkles")
                    .font(Typography.Icon.lg)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Internal Design Directory")
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color.primaryText)

                Text("Preview page variations before shipping")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.secondaryText)
            }

            Spacer()
        }
    }

    // MARK: - Developer Row Helper

    private func developerRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(Typography.Icon.sm.weight(.medium))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.input + 2)
                        .fill(iconColor.opacity(Theme.Opacity.faint + 0.02))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.Command.body)
                    .foregroundStyle(Color.primaryText)

                Text(subtitle)
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color.tertiaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.tertiaryText)
        }
        .contentShape(Rectangle())
    }

    // MARK: - Info Footer

    private var infoFooter: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "info.circle")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.tertiaryText)

            Text("For internal review only")
                .font(Typography.Command.meta)
                .foregroundStyle(Color.tertiaryText)
        }
        .padding(.top, Theme.Spacing.md)
    }
}

// MARK: - Preview

#Preview("Developer Section") {
    NavigationStack {
        ScrollView {
            DeveloperSectionView(viewModel: SettingsViewModel())
                .padding()
        }
        .background(Color.appBackground)
    }
}

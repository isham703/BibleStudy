import SwiftUI

// MARK: - Developer Section View
// Internal tools and design showcases for team review

struct DeveloperSectionView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showOnboardingShowcase = false
    @State private var showPrayerShowcase = false
    @State private var showHomePageShowcase = false
    @State private var showSermonShowcase = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        SettingsCard(title: "Design Studio", icon: "paintbrush.fill", showDivider: false) {
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
                        iconColor: Color("AppAccentAction"),
                        title: "Sign Up / Onboarding",
                        subtitle: "3 page variations"
                    )
                }
                .buttonStyle(.plain)

                SettingsDivider()

                // Prayer Showcase
                Button {
                    showPrayerShowcase = true
                } label: {
                    developerRow(
                        icon: "hands.sparkles.fill",
                        iconColor: Color("HighlightRose"),
                        title: "Prayer Options",
                        subtitle: "3 page variations"
                    )
                }
                .buttonStyle(.plain)

                SettingsDivider()

                // Home Page Showcase
                Button {
                    showHomePageShowcase = true
                } label: {
                    developerRow(
                        icon: "building.columns.fill",
                        iconColor: Color("AccentBronze"),
                        title: "Home Page Options",
                        subtitle: "3 stoic design variations"
                    )
                }
                .buttonStyle(.plain)

                SettingsDivider()

                // Sermon Showcase
                Button {
                    showSermonShowcase = true
                } label: {
                    developerRow(
                        icon: "mic.fill",
                        iconColor: Color("FeedbackInfo"),
                        title: "Sermon Options",
                        subtitle: "3 page variations"
                    )
                }
                .buttonStyle(.plain)

                SettingsDivider()

                // Info footer
                infoFooter
            }
        }
        // COMMENTED OUT: OnboardingShowcaseDirectory not added to target yet
        // .fullScreenCover(isPresented: $showOnboardingShowcase) {
        //     OnboardingShowcaseDirectory()
        // }
        .fullScreenCover(isPresented: $showHomePageShowcase) {
            HomePageShowcaseDirectory()
        }
        .fullScreenCover(isPresented: $showPrayerShowcase) {
            PrayerPageShowcaseDirectory()
        }
        .fullScreenCover(isPresented: $showSermonShowcase) {
            SermonShowcaseDirectory()
        }
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
                                Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground),
                                Color("AppAccentAction").opacity(Theme.Opacity.overlay)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)

                Image(systemName: "sparkles")
                    .font(Typography.Icon.lg)
                    .foregroundStyle(Color("AppAccentAction"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Internal Design Directory")
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text("Preview page variations before shipping")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
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
                        .fill(iconColor.opacity(Theme.Opacity.subtle + 0.02))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text(subtitle)
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("TertiaryText"))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(Typography.Command.caption)
                .foregroundStyle(Color("TertiaryText"))
        }
        .contentShape(Rectangle())
    }

    // MARK: - Info Footer

    private var infoFooter: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "info.circle")
                .font(Typography.Command.caption)
                .foregroundStyle(Color("TertiaryText"))

            Text("For internal review only")
                .font(Typography.Command.meta)
                .foregroundStyle(Color("TertiaryText"))
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

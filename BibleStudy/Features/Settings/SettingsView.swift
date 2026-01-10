import SwiftUI

// MARK: - Settings View (DEPRECATED)
// ⚠️ DEPRECATED: Use FloatingSanctuarySettings instead.
// This view and its section views (AccountSectionView, SubscriptionSectionView, etc.)
// are legacy code retained for reference. FloatingSanctuarySettings is the primary settings UI.
//
// TODO: Remove this file and associated section views in a future cleanup.

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Settings header
                    settingsHeader
                        .opacity(viewModel.appeared ? 1 : 0)
                        .offset(y: viewModel.appeared ? 0 : -10)

                    // Section cards with staggered animation
                    sectionContent
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .background(Colors.Surface.background(for: ThemeMode.current(from: colorScheme)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SETTINGS")
                        .font(Typography.Scripture.footnote)
                        .tracking(3)
                        .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(Typography.Command.body)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                }
            }
            .sheet(isPresented: $viewModel.showPaywall) {
                PaywallView(trigger: viewModel.paywallTrigger)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred.")
            }
            .onAppear {
                // Trigger staggered entry animation
                withAnimation {
                    viewModel.appeared = true
                }
            }
        }
    }

    // MARK: - Settings Header

    private var settingsHeader: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Decorative ornament
            HStack(spacing: Theme.Spacing.md) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: Theme.Stroke.hairline)

                Diamond()
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    .frame(width: 8, height: 8)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: Theme.Stroke.hairline)
            }
            .padding(.horizontal, Theme.Spacing.xxl)
            .padding(.top, Theme.Spacing.md)
        }
    }

    // MARK: - Section Content

    @ViewBuilder
    private var sectionContent: some View {
        AccountSectionView(viewModel: viewModel)
            .opacity(viewModel.appeared ? 1 : 0)
            .offset(y: viewModel.appeared ? 0 : 20)
            .animation(Theme.Animation.slowFade.delay(0.08), value: viewModel.appeared)

        SubscriptionSectionView(viewModel: viewModel)
            .opacity(viewModel.appeared ? 1 : 0)
            .offset(y: viewModel.appeared ? 0 : 20)
            .animation(Theme.Animation.slowFade.delay(0.16), value: viewModel.appeared)

        ReadingSectionView(viewModel: viewModel)
            .opacity(viewModel.appeared ? 1 : 0)
            .offset(y: viewModel.appeared ? 0 : 20)
            .animation(Theme.Animation.slowFade.delay(0.24), value: viewModel.appeared)

        NotificationsSectionView(viewModel: viewModel)
            .opacity(viewModel.appeared ? 1 : 0)
            .offset(y: viewModel.appeared ? 0 : 20)
            .animation(Theme.Animation.slowFade.delay(0.32), value: viewModel.appeared)

        AboutSectionView(viewModel: viewModel)
            .opacity(viewModel.appeared ? 1 : 0)
            .offset(y: viewModel.appeared ? 0 : 20)
            .animation(Theme.Animation.slowFade.delay(0.40), value: viewModel.appeared)

        DeveloperSectionView(viewModel: viewModel)
            .opacity(viewModel.appeared ? 1 : 0)
            .offset(y: viewModel.appeared ? 0 : 20)
            .animation(Theme.Animation.slowFade.delay(0.48), value: viewModel.appeared)
    }
}

// MARK: - Preview

#Preview("Settings View") {
    SettingsView()
}

#Preview("Settings - Dark Mode") {
    SettingsView()
        .preferredColorScheme(.dark)
}

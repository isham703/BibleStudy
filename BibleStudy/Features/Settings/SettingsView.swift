import SwiftUI

// MARK: - Settings View
// Illuminated manuscript-styled settings with subscription integration

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Settings header
                    settingsHeader
                        .opacity(viewModel.appeared ? 1 : 0)
                        .offset(y: viewModel.appeared ? 0 : -10)

                    // Section cards with staggered animation
                    ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                        section
                            .opacity(viewModel.appeared ? 1 : 0)
                            .offset(y: viewModel.appeared ? 0 : 20)
                            .animation(
                                AppTheme.Animation.slow.delay(Double(index) * 0.08),
                                value: viewModel.appeared
                            )
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SETTINGS")
                        .font(.system(size: Typography.Scale.xs, weight: .medium, design: .serif))
                        .tracking(3)
                        .foregroundStyle(Color.secondaryText)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.scholarAccent)
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
        VStack(spacing: AppTheme.Spacing.sm) {
            // Decorative ornament
            HStack(spacing: AppTheme.Spacing.md) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.scholarAccent.opacity(AppTheme.Opacity.medium)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: AppTheme.Divider.thin)

                Diamond()
                    .fill(Color.scholarAccent)
                    .frame(width: AppTheme.ComponentSize.indicator, height: AppTheme.ComponentSize.indicator)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.scholarAccent.opacity(AppTheme.Opacity.medium), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: AppTheme.Divider.thin)
            }
            .padding(.horizontal, AppTheme.Spacing.xxl)
            .padding(.top, AppTheme.Spacing.md)
        }
    }

    // MARK: - Sections Array

    private var sections: [AnyView] {
        [
            AnyView(AccountSectionView(viewModel: viewModel)),
            AnyView(SubscriptionSectionView(viewModel: viewModel)),
            AnyView(ReadingSectionView(viewModel: viewModel)),
            AnyView(NotificationsSectionView(viewModel: viewModel)),
            AnyView(AboutSectionView(viewModel: viewModel))
        ]
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

import SwiftUI

// MARK: - Settings View (Refactored Orchestrator)
// Design Rationale: Clean Architecture - thin orchestrator that composes
// focused section views. Each section is independently testable and maintainable.
// Background is SOLID color - no ambient gradient per design system.
// Stoic-Existential Renaissance design

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var viewModel = SettingsViewModel()

    // Confirmation dialogs
    @State private var showSignOutConfirmation = false
    @State private var showClearCacheConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Header - flat design, no glow
                    SettingsHeaderView(
                        displayName: viewModel.displayName,
                        tierDisplayName: viewModel.tierDisplayName
                    )

                    // Subscription Section (first - monetization priority)
                    SubscriptionSectionView(viewModel: viewModel)

                    // Account Section
                    AccountSectionView(viewModel: viewModel)

                    // Feedback & Alerts Section (notifications + haptics)
                    NotificationsSectionView(viewModel: viewModel)

                    // Sermon Section (Live Captions — iOS 26+)
                    if #available(iOS 26, *) {
                        SermonSectionView(viewModel: viewModel)
                    }

                    // Audio Storage Section
                    ReadingSectionView(viewModel: viewModel)

                    // Footer
                    SettingsFooterView()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, 120)
            }
            // SOLID BACKGROUND - No ambient gradient per design system
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(Typography.Command.body.weight(.medium))
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
            }
        }
        .preferredColorScheme(appState.colorScheme)
        .task {
            await viewModel.loadInitialData()
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView(trigger: viewModel.paywallTrigger)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred.")
        }
        .confirmationDialog("Sign Out", isPresented: $viewModel.showSignOutConfirmation, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                Task { @MainActor in
                    await viewModel.signOut()
                    appState.isAuthenticated = false
                    appState.userId = nil
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppState())
    }
}

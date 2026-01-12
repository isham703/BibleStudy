import SwiftUI

// MARK: - Sanctuary Home View
// Main home view displaying the Roman/Stoic sanctuary experience
// Uses SanctuaryViewModel for centralized state management
//
// MIGRATION NOTE: Replaced ForumHomeView with HomeView (Colonnade design)
// Architectural layout: pillar-based navigation, clear hierarchy, multiple entry points

struct SanctuaryHomeView: View {
    @State private var viewModel = SanctuaryViewModel()
    @State private var showSettings = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            HomeView()
                .onSettingsTapped {
                    showSettings = true
                }
                .fullScreenCover(isPresented: $showSettings) {
                    SettingsView()
                }
        }
        .environment(viewModel)
        .task {
            // Load real user data when view appears
            await viewModel.loadUserData()
            // NOTE: Time updates no longer needed - Roman design is not time-aware
        }
        .onChange(of: scenePhase) { _, newPhase in
            viewModel.updateScenePhase(newPhase)
        }
        .onChange(of: reduceMotion) { _, reduce in
            viewModel.updateReduceMotion(reduce)
        }
    }
}

// MARK: - Preview

#Preview {
    SanctuaryHomeView()
        .environment(AppState())
}

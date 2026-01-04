import SwiftUI

// MARK: - Sanctuary Home View
// Main home view that displays the selected Sanctuary variant
// Wraps HomeShowcase views and integrates with AppState

struct SanctuaryHomeView: View {
    @Environment(AppState.self) private var appState
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            homeContent
                .onSettingsTapped {
                    showSettings = true
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
        }
        .task {
            // Load real user data when view appears
            await SanctuaryDataAdapter.shared.loadData()
        }
    }

    @ViewBuilder
    private var homeContent: some View {
        switch appState.homeVariant {
        case .liturgicalHours:
            TimeAwareSanctuaryPage()
        case .candlelitSanctuary:
            CandlelitSanctuaryPage()
        case .scholarsAtrium:
            ScholarsAtriumPage()
        case .sacredThreshold:
            SacredThresholdPage()
        }
    }
}

// MARK: - Preview

#Preview {
    SanctuaryHomeView()
        .environment(AppState())
}

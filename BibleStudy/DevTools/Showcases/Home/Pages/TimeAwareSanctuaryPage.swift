import SwiftUI

// MARK: - Time-Aware Sanctuary Page
// DEPRECATED: Now redirects to RomanSanctuaryView
// Kept for backward compatibility with DevTools showcases
//
// The Roman/Stoic design system removes time-awareness in favor of
// a unified view with fixed layout (Bible Reading always primary CTA)

@available(*, deprecated, message: "Use RomanSanctuaryView directly")
struct TimeAwareSanctuaryPage: View {
    @State private var viewModel = SanctuaryViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Redirect to unified Roman sanctuary view
        RomanSanctuaryView()
            .environment(viewModel)
            .task {
                await viewModel.loadUserData()
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

#Preview("Time-Aware (Deprecated - Now Roman)") {
    NavigationStack {
        TimeAwareSanctuaryPage()
            .environment(AppState())
    }
}

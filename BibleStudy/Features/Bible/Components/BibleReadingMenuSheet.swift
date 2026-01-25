import SwiftUI

// MARK: - Bible Reading Menu Sheet
// Thin orchestrator for Bible reading menu
// Coordinates between MenuSection, SearchSection, SettingsSection, InsightsSection
// Uses ReadingMenuState for centralized state management

struct BibleReadingMenuSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(BibleService.self) private var bibleService
    @Environment(AppState.self) private var appState

    // Actions
    let onNavigate: ((VerseRange) -> Void)?

    // Centralized state
    @State private var state = ReadingMenuState()

    init(onNavigate: ((VerseRange) -> Void)? = nil) {
        self.onNavigate = onNavigate
    }

    var body: some View {
        DynamicSheet(animation: state.animation) {
            ZStack {
                switch state.currentView {
                case .menu:
                    MenuSection(state: state)
                        .transition(.blurReplace(.downUp))

                case .search:
                    SearchSection(
                        state: state,
                        onNavigate: onNavigate
                    )
                    .transition(.blurReplace(.upUp))

                case .settings:
                    SettingsSection(state: state)
                        .transition(.blurReplace(.upUp))

                case .insights:
                    InsightsSection(state: state)
                        .transition(.blurReplace(.upUp))
                }
            }
            .geometryGroup()
            .background(Color.appBackground)
        }
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview("Bible Reading Menu") {
    struct PreviewContainer: View {
        @State private var showSheet = true

        var body: some View {
            Color.appBackground
                .ignoresSafeArea()
                .sheet(isPresented: $showSheet) {
                    BibleReadingMenuSheet(
                        onNavigate: { range in print("Navigate to \(range)") }
                    )
                    .environment(BibleService.shared)
                    .environment(AppState())
                }
        }
    }

    return PreviewContainer()
}

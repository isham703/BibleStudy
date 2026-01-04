import SwiftUI

// MARK: - Read Tab View
// Container for the Bible reader experience

struct ReadTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(BibleService.self) private var bibleService

    var body: some View {
        NavigationStack {
            ReaderView()
        }
    }
}

#Preview {
    ReadTabView()
        .environment(AppState())
        .environment(BibleService.shared)
}

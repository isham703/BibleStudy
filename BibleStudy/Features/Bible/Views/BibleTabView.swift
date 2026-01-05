import SwiftUI

// MARK: - Bible Tab View
// Root view for Bible tab
// Shows BibleHomeView as landing page, navigates to BibleReaderView fullscreen

struct BibleTabView: View {
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            BibleHomeView(navigationPath: $navigationPath)
                .navigationTitle("Bible")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Bible")
                            .font(Typography.UI.headline)
                            .foregroundStyle(Color.primaryText)
                    }
                }
                .navigationDestination(for: BibleLocation.self) { location in
                    BibleReaderView(location: location)
                        .navigationBarBackButtonHidden(false)
                }
        }
    }
}

// MARK: - Preview

#Preview {
    BibleTabView()
        .environment(AppState())
        .environment(BibleService.shared)
}

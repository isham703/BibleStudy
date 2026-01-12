import SwiftUI

// MARK: - Bible Tab View
// Root view for Bible tab
// Shows BibleHomeView as landing page, navigates to BibleReaderView fullscreen

struct BibleTabView: View {
    @State private var navigationPath = NavigationPath()
    @State private var didHandleUITestNavigation = false

    private var isUITestingReader: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui_testing_reader")
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            BibleHomeView(navigationPath: $navigationPath)
                .navigationTitle("Bible")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Bible")
                            .font(Typography.Command.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                }
                .onAppear {
                    guard isUITestingReader, !didHandleUITestNavigation else { return }
                    navigationPath = NavigationPath()
                    navigationPath.append(BibleLocation.genesis1)
                    didHandleUITestNavigation = true
                }
                .navigationDestination(for: BibleLocation.self) { location in
                    BibleReaderView(location: location)
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

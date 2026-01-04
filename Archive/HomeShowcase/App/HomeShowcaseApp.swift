import SwiftUI

// MARK: - Home Showcase App
// Internal design directory for viewing home page variations

@main
struct HomeShowcaseApp: App {
    var body: some Scene {
        WindowGroup {
            HomeShowcaseContentView()
                .preferredColorScheme(.dark)
        }
    }
}

import SwiftUI

// MARK: - Reading Section View
// Simplified to only contain Audio Storage settings
// Display settings (theme, font, etc.) are now only in the Reader Menu

struct ReadingSectionView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showClearCacheConfirmation = false

    var body: some View {
        AudioCacheSection(
            viewModel: viewModel,
            showClearCacheConfirmation: $showClearCacheConfirmation
        )
    }
}

// MARK: - Preview

#Preview("Reading Section") {
    ScrollView {
        ReadingSectionView(viewModel: SettingsViewModel())
            .padding()
            .environment(AppState())
    }
    .background(Color.appBackground)
}

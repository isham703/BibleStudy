import SwiftUI

// MARK: - HomeShowcase Environment Keys
// Environment keys for showcase previews

// MARK: - Settings Action Key

private struct SettingsActionKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var settingsAction: () -> Void {
        get { self[SettingsActionKey.self] }
        set { self[SettingsActionKey.self] = newValue }
    }
}

// MARK: - View Modifier for Settings Action

extension View {
    func onSettingsTapped(_ action: @escaping () -> Void) -> some View {
        environment(\.settingsAction, action)
    }
}

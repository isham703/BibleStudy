import SwiftUI

// MARK: - Settings Action Environment Key
// Allows Sanctuary views to trigger settings presentation

private struct SettingsActionKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var settingsAction: () -> Void {
        get { self[SettingsActionKey.self] }
        set { self[SettingsActionKey.self] = newValue }
    }
}

extension View {
    func onSettingsTapped(_ action: @escaping () -> Void) -> some View {
        environment(\.settingsAction, action)
    }
}

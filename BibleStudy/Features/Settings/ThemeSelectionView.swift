import SwiftUI

// MARK: - Theme Selection View
// Allows user to select app theme (Light, Dark, System)

struct ThemeSelectionView: View {
    @Binding var selectedTheme: ThemeMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(ThemeMode.allCases, id: \.self) { theme in
                Button {
                    selectedTheme = theme
                    dismiss()
                } label: {
                    HStack {
                        Text(theme.displayName)
                            .foregroundStyle(Color.primaryText)

                        Spacer()

                        if selectedTheme == theme {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentBlue)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .navigationTitle("Theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ThemeSelectionView(selectedTheme: .constant(.system))
    }
}

import SwiftUI

// MARK: - Theme Selection View
// Allows user to select app theme (Light, Dark, System)

struct ThemeSelectionView: View {
    @Binding var selectedTheme: ThemeMode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        List {
            ForEach(ThemeMode.allCases, id: \.self) { theme in
                Button {
                    selectedTheme = theme
                    dismiss()
                } label: {
                    HStack {
                        Text(theme.displayName)
                            .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                        Spacer()

                        if selectedTheme == theme {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
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

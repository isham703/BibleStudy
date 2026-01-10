import SwiftUI

// MARK: - Inline Theme Card
// Compact theme card for inline settings display

struct InlineThemeCard: View {
    let theme: AppThemeMode
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: Theme.Spacing.xs) {
                // Theme preview swatch
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .fill(theme.previewBackground)
                        .frame(width: 52, height: 36)
                        .overlay(
                            VStack(spacing: Theme.Spacing.xs) {
                                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                                    .fill(theme.previewText)
                                    .frame(width: 32, height: 3)
                                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                                    .fill(theme.previewText.opacity(Theme.Opacity.strong))
                                    .frame(width: 24, height: 3)
                            }
                        )

                    // Selection ring
                    if isSelected {
                        RoundedRectangle(cornerRadius: Theme.Radius.input)
                            .stroke(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)), lineWidth: Theme.Stroke.control)
                            .frame(width: 52, height: 36)
                    }
                }
                .shadow(
                    color: isSelected ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.medium) : .clear,
                    radius: 4
                )

                // Theme name
                Text(theme.displayName)
                    .font(Typography.Command.meta)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Color.secondaryText)
            }
            .padding(.vertical, Theme.Spacing.xs)
            .padding(.horizontal, 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.displayName) theme")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Preview

#Preview("Inline Theme Cards") {
    HStack(spacing: Theme.Spacing.md) {
        ForEach(AppThemeMode.allCases, id: \.self) { theme in
            InlineThemeCard(
                theme: theme,
                isSelected: theme == .system
            ) {
                print("Selected: \(theme.displayName)")
            }
        }
    }
    .padding()
    .background(Color.appBackground)
}

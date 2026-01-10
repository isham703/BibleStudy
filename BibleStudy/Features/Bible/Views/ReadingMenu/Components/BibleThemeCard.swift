import SwiftUI

// MARK: - Bible Theme Card
// Theme selection card with preview and selection indicator
// Used in SettingsSection for appearance selection

struct BibleThemeCard: View {
    let theme: AppThemeMode
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.sm) {
                // Theme preview
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(theme.previewBackground)
                    .frame(width: 56, height: 36)
                    .overlay(
                        // swiftlint:disable:next hardcoded_stack_spacing
                        VStack(spacing: 3) {
                            // swiftlint:disable:next hardcoded_rounded_rectangle
                            RoundedRectangle(cornerRadius: Theme.Radius.xs)
                                .fill(theme.previewText)
                                .frame(width: 36, height: 2)
                            // swiftlint:disable:next hardcoded_rounded_rectangle
                            RoundedRectangle(cornerRadius: Theme.Radius.xs)
                                .fill(theme.previewText.opacity(Theme.Opacity.strong))
                                .frame(width: 28, height: 2)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.input)
                            .stroke(
                                isSelected ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)),
                                lineWidth: isSelected ? Theme.Stroke.control : Theme.Stroke.hairline
                            )
                    )

                // Theme name
                Text(theme.displayName)
                    .font(Typography.Command.meta)
                    .foregroundStyle(isSelected ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Color.primaryText)

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                } else {
                    Circle()
                        .stroke(Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)), lineWidth: Theme.Stroke.hairline)
                        .frame(width: 14, height: 14)
                }
            }
            .padding(Theme.Spacing.sm)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
struct BibleThemeCard_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: Theme.Spacing.md) {
            BibleThemeCard(theme: .light, isSelected: false) {}
            BibleThemeCard(theme: .dark, isSelected: true) {}
            BibleThemeCard(theme: .system, isSelected: false) {}
        }
        .padding()
        .background(Color.surfaceBackground)
    }
}
#endif

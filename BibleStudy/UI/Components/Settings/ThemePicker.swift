import SwiftUI

// MARK: - Theme Picker
// Design Rationale: Theme selection using circle swatches with stroked borders.
// NO shadows per design system - uses stroke weight to indicate selection.
// Follows F-pattern: swatches left-aligned, labels below.
// Stoic-Existential Renaissance design

struct ThemePicker: View {
    @Binding var selectedTheme: AppThemeMode

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(AppThemeMode.allCases, id: \.self) { theme in
                ThemePill(
                    theme: theme,
                    isSelected: selectedTheme == theme
                ) {
                    withAnimation(Theme.Animation.settle) {
                        selectedTheme = theme
                        // Persist selection
                        UserDefaults.standard.set(theme.rawValue, forKey: AppConfiguration.UserDefaultsKeys.preferredTheme)
                    }
                    HapticService.shared.lightTap()
                }
            }
        }
    }
}

// MARK: - Theme Pill
// Individual theme option with swatch and label

struct ThemePill: View {
    let theme: AppThemeMode
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Theme.Spacing.xs + 2) {
                // Color swatch - flat design, no shadow
                Circle()
                    .fill(theme.previewColor)
                    .frame(width: 32, height: 32)
                    .overlay {
                        // Stroke border - thickness indicates selection
                        Circle()
                            .strokeBorder(
                                isSelected ? Color("AppAccentAction") : Color.appDivider.opacity(Theme.Opacity.selectionBackground),
                                lineWidth: isSelected ? Theme.Stroke.control : Theme.Stroke.hairline
                            )
                    }

                // Theme name
                Text(theme.displayName)
                    .font(Typography.Command.caption.weight(isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? Color("AppAccentAction") : Color("AppTextSecondary"))
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.md)
            .background {
                // Selected background - subtle tint, no shadow
                if isSelected {
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .fill(Color("AppAccentAction").opacity(Theme.Opacity.subtle))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.displayName) theme")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - AppThemeMode Extension
// Preview colors for theme swatches
// Note: displayName is already defined in BibleStudyApp.swift

extension AppThemeMode {
    var previewColor: Color {
        switch self {
        case .system: return Color("AccentBronze")  // Bronze as neutral
        case .light: return Color(white: 0.95)      // Light parchment
        case .dark: return Color(white: 0.15)       // Near-black
        }
    }
}

// MARK: - Preview

#Preview("Theme Picker") {
    struct PreviewContainer: View {
        @State private var theme: AppThemeMode = .system

        var body: some View {
            VStack(spacing: Theme.Spacing.xl) {
                SettingsCard(title: "Appearance", icon: "paintpalette.fill") {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        HStack {
                            IconBadge.settings("paintpalette.fill", color: Color("AppAccentAction"))

                            Text("Theme")
                                .font(Typography.Command.body)
                                .foregroundStyle(Color("AppTextPrimary"))
                        }

                        ThemePicker(selectedTheme: $theme)
                    }
                    .padding(.vertical, Theme.Spacing.sm)
                }
            }
            .padding()
            .background(Color.appBackground)
        }
    }

    return PreviewContainer()
}

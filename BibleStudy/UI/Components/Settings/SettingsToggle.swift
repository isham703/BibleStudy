import SwiftUI

// MARK: - Toggle
// Standard iOS toggle with flat styling
// Stoic-Existential Renaissance design

struct SettingsToggle: View {
    @Binding var isOn: Bool
    let label: String
    let description: String?
    let icon: String?
    let iconColor: Color

    @Environment(\.colorScheme) private var colorScheme

    init(
        isOn: Binding<Bool>,
        label: String,
        description: String? = nil,
        icon: String? = nil,
        iconColor: Color = .accentIndigo
    ) {
        self._isOn = isOn
        self.label = label
        self.description = description
        self.icon = icon
        self.iconColor = iconColor
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon (optional)
            if let icon = icon {
                iconView(icon: icon)
            }

            // Label and description
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(label)
                    .font(Typography.Command.body)
                    .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                if let description = description {
                    Text(description)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            // Standard iOS toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(iconColor)
        }
        .contentShape(Rectangle())
    }

    // MARK: - Icon View

    private func iconView(icon: String) -> some View {
        Image(systemName: icon)
            .font(Typography.Icon.sm.weight(.medium))
            .foregroundStyle(iconColor)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.tag)
                    .fill(iconColor.opacity(Theme.Opacity.divider))
            )
    }
}

// MARK: - Toggle Row
// Convenience wrapper for toggle in a settings row context

struct SettingsToggleRow: View {
    @Binding var isOn: Bool
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?

    init(
        isOn: Binding<Bool>,
        icon: String,
        iconColor: Color = .accentIndigo,
        title: String,
        subtitle: String? = nil
    ) {
        self._isOn = isOn
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        SettingsToggle(
            isOn: $isOn,
            label: title,
            description: subtitle,
            icon: icon,
            iconColor: iconColor
        )
    }
}

// MARK: - Preview

#Preview("Toggle") {
    struct PreviewContainer: View {
        @State private var toggle1 = true
        @State private var toggle2 = false
        @State private var toggle3 = true

        var body: some View {
            VStack(spacing: Theme.Spacing.xl) {
                IlluminatedSettingsCard(title: "Notifications", icon: "bell.fill") {
                    VStack(spacing: Theme.Spacing.lg) {
                        SettingsToggle(
                            isOn: $toggle1,
                            label: "Daily Reading Reminder",
                            description: "Get reminded at your chosen time",
                            icon: "bell.fill",
                            iconColor: .accentIndigo
                        )

                        SettingsDivider()

                        SettingsToggle(
                            isOn: $toggle2,
                            label: "Streak Protection",
                            description: "We'll remind you at 8 PM if you haven't read today",
                            icon: "flame.fill",
                            iconColor: .warning
                        )

                        SettingsDivider()

                        SettingsToggle(
                            isOn: $toggle3,
                            label: "Devotional Mode",
                            icon: "sparkles",
                            iconColor: .accentIndigo
                        )
                    }
                }
                .padding()
            }
            .background(Color.appBackground)
        }
    }

    return PreviewContainer()
}

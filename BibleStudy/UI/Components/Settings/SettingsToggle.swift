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

    init(
        isOn: Binding<Bool>,
        label: String,
        description: String? = nil,
        icon: String? = nil,
        iconColor: Color = Color("AppAccentAction")
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
                IconBadge.settings(icon, color: iconColor)
            }

            // Label and description
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(label)
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextPrimary"))

                if let description = description {
                    Text(description)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
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
        iconColor: Color = Color("AppAccentAction"),
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
                SettingsCard(title: "Notifications", icon: "bell.fill") {
                    VStack(spacing: Theme.Spacing.lg) {
                        SettingsToggle(
                            isOn: $toggle1,
                            label: "Daily Reading Reminder",
                            description: "Get reminded at your chosen time",
                            icon: "bell.fill",
                            iconColor: Color("AppAccentAction")
                        )

                        SettingsDivider()

                        SettingsToggle(
                            isOn: $toggle2,
                            label: "Streak Protection",
                            description: "We'll remind you at 8 PM if you haven't read today",
                            icon: "flame.fill",
                            iconColor: Color("FeedbackWarning")
                        )

                        SettingsDivider()

                        SettingsToggle(
                            isOn: $toggle3,
                            label: "Devotional Mode",
                            icon: "sparkles",
                            iconColor: Color("AppAccentAction")
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

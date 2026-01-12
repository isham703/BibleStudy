import SwiftUI

// MARK: - Settings Card
// Flat card wrapper for settings sections
// Stoic-Existential Renaissance design

struct SettingsCard<Content: View>: View {
    let title: String?
    let icon: String?
    let showDivider: Bool
    @ViewBuilder let content: () -> Content

    init(
        title: String? = nil,
        icon: String? = nil,
        showDivider: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.showDivider = showDivider
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header (flat, no ornaments)
            if let title = title {
                sectionHeader(title: title)
                    .padding(.bottom, Theme.Spacing.sm)
            }

            // Content card (flat styling)
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(.appDivider, lineWidth: Theme.Stroke.hairline)
            )
        }
    }

    // MARK: - Section Header

    private func sectionHeader(title: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(Typography.Icon.xxs.weight(.medium))
                    .foregroundStyle(Color("AppAccentAction"))
            }

            Text(title.uppercased())
                .font(Typography.Command.meta)
                .tracking(2.2)
                .foregroundStyle(Color("AppAccentAction"))
        }
    }
}

// MARK: - Settings Row
// Reusable row component for settings items with flat styling

struct IlluminatedSettingsRow<Accessory: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @ViewBuilder let accessory: () -> Accessory

    init(
        icon: String,
        iconColor: Color = Color("AppAccentAction"),
        title: String,
        subtitle: String? = nil,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon using IconBadge
            IconBadge.settings(icon, color: iconColor)

            // Title and subtitle
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextPrimary"))

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }

            Spacer()

            // Accessory view
            accessory()
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Settings Divider
// A subtle divider between settings rows

struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(.appDivider)
            .frame(height: Theme.Stroke.hairline)
            .padding(.leading, Theme.Size.minTapTarget)
    }
}

// MARK: - Preview

#Preview("Settings Card") {
    ScrollView {
        VStack(spacing: Theme.Spacing.xl) {
            SettingsCard(title: "Account", icon: "person.fill") {
                VStack(spacing: Theme.Spacing.md) {
                    IlluminatedSettingsRow(
                        icon: "person.circle.fill",
                        iconColor: Color("AppAccentAction"),
                        title: "Bible Student",
                        subtitle: "user@example.com"
                    ) {
                        Image(systemName: "chevron.right")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
            }

            SettingsCard(title: "Reading", icon: "book.fill") {
                VStack(spacing: Theme.Spacing.md) {
                    IlluminatedSettingsRow(
                        icon: "textformat.size",
                        title: "Font Size",
                        subtitle: "18pt"
                    ) {
                        Text("Medium")
                            .font(Typography.Command.body)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }

                    SettingsDivider()

                    IlluminatedSettingsRow(
                        icon: "book.closed",
                        title: "Translation"
                    ) {
                        Text("KJV")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.tag)
                                    .fill(Color("AppAccentAction"))
                            )
                    }
                }
            }
        }
        .padding()
    }
    .background(Color.appBackground)
}

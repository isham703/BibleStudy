import SwiftUI

// MARK: - Settings Card
// Flat card wrapper for settings sections
// Stoic-Existential Renaissance design

struct SettingsCard<Content: View>: View {
    let title: String?
    let icon: String?
    let showDivider: Bool
    @ViewBuilder let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

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
                    .fill(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(
                        Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)),
                        lineWidth: Theme.Stroke.hairline
                    )
            )
        }
    }

    // MARK: - Section Header

    private func sectionHeader(title: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(Typography.Icon.xxs.weight(.medium))
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            }

            Text(title.uppercased())
                .font(Typography.Command.meta)
                .tracking(2.2)
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
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

    @Environment(\.colorScheme) private var colorScheme

    init(
        icon: String,
        iconColor: Color = .accentIndigo,
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
            // Icon in colored square
            iconView

            // Title and subtitle
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Typography.Command.body)
                    .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                }
            }

            Spacer()

            // Accessory view
            accessory()
        }
        .contentShape(Rectangle())
    }

    private var iconView: some View {
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

// MARK: - Settings Divider
// A subtle divider between settings rows

struct SettingsDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Rectangle()
            .fill(Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)))
            .frame(height: Theme.Stroke.hairline)
            .padding(.leading, 44)
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
                        iconColor: .accentIndigo,
                        title: "Bible Student",
                        subtitle: "user@example.com"
                    ) {
                        Image(systemName: "chevron.right")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color.secondaryText)
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
                            .foregroundStyle(Color.secondaryText)
                    }

                    SettingsDivider()

                    IlluminatedSettingsRow(
                        icon: "book.closed",
                        title: "Translation"
                    ) {
                        Text("KJV")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color.primaryText)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.tag)
                                    .fill(Colors.Semantic.accentAction(for: .dark))
                            )
                    }
                }
            }
        }
        .padding()
    }
    .background(Color.appBackground)
}

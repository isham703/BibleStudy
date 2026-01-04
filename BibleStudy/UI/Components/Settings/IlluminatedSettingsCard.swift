import SwiftUI

// MARK: - Illuminated Settings Card
// A decorative card wrapper for settings sections with manuscript aesthetics

struct IlluminatedSettingsCard<Content: View>: View {
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
            // Section header with decorated margin
            if let title = title {
                sectionHeader(title: title)
                    .padding(.bottom, AppTheme.Spacing.sm)
            }

            // Content card
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(AppTheme.Spacing.lg)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
            .overlay(cardBorder)
            .shadow(color: Color.black.opacity(AppTheme.Opacity.faint - 0.05), radius: AppTheme.Blur.medium + 4, x: 0, y: AppTheme.Spacing.xs)

            // Optional decorative divider below
            if showDivider {
                OrnamentalDivider(style: .geometric, color: Color.scholarAccent.opacity(AppTheme.Opacity.disabled))
                    .padding(.top, AppTheme.Spacing.xl)
                    .padding(.horizontal, AppTheme.Spacing.xxl)
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(title: String) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Vertical ornament
            VStack(spacing: AppTheme.Spacing.xs) {
                Diamond()
                    .fill(Color.scholarAccent)
                    .frame(width: AppTheme.ComponentSize.dot, height: AppTheme.ComponentSize.dot)
                Rectangle()
                    .fill(Color.scholarAccent.opacity(AppTheme.Opacity.medium))
                    .frame(width: AppTheme.Border.thin, height: AppTheme.Spacing.lg)
                Diamond()
                    .fill(Color.scholarAccent)
                    .frame(width: AppTheme.ComponentSize.dot, height: AppTheme.ComponentSize.dot)
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(Typography.UI.iconXxs.weight(.medium))
                        .foregroundStyle(Color.scholarAccent.opacity(AppTheme.Opacity.overlay))
                }

                Text(title.uppercased())
                    .font(Typography.UI.caption2.weight(.medium))
                    .tracking(3)
                    .foregroundStyle(Color.scholarAccent.opacity(AppTheme.Opacity.pressed))
            }
        }
    }

    // MARK: - Card Styling (Lifted Vellum Design)
    // Cards blend with page background, elevation achieved through border + shadow

    private var cardBackground: some View {
        // Light vellum surface - same as page for unified feel
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
            .fill(Color.surfaceBackground)
    }

    private var cardBorder: some View {
        // Single refined border with subtle gold warmth
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.cardBorder.opacity(AppTheme.Opacity.disabled),
                        Color.scholarAccent.opacity(AppTheme.Opacity.quarter),
                        Color.cardBorder.opacity(AppTheme.Opacity.disabled)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: AppTheme.Border.thin
            )
    }

    private var cardShadow: some ShapeStyle {
        Color.black.opacity(AppTheme.Opacity.faint - 0.04)
    }
}

// MARK: - Illuminated Settings Row
// Reusable row component for settings items with illuminated styling

struct IlluminatedSettingsRow<Accessory: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @ViewBuilder let accessory: () -> Accessory

    init(
        icon: String,
        iconColor: Color = .scholarAccent,
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
        HStack(spacing: AppTheme.Spacing.md) {
            // Icon in colored capsule
            iconView

            // Title and subtitle
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(title)
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.primaryText)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.secondaryText)
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
            .font(Typography.UI.iconSm.weight(.medium))
            .foregroundStyle(iconColor)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small + 2)
                    .fill(iconColor.opacity(AppTheme.Opacity.subtle + 0.02))
            )
    }
}

// MARK: - Settings Divider
// A subtle divider between settings rows

struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.divider.opacity(AppTheme.Opacity.heavy))
            .frame(height: AppTheme.Divider.hairline)
            .padding(.leading, AppTheme.Spacing.xxxl - 4)
    }
}

// MARK: - Preview

#Preview("Illuminated Settings Card") {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.xl) {
            IlluminatedSettingsCard(title: "Account", icon: "person.fill") {
                VStack(spacing: AppTheme.Spacing.md) {
                    IlluminatedSettingsRow(
                        icon: "person.circle.fill",
                        iconColor: .scholarAccent,
                        title: "Bible Student",
                        subtitle: "user@example.com"
                    ) {
                        Image(systemName: "chevron.right")
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.tertiaryText)
                    }
                }
            }

            IlluminatedSettingsCard(title: "Reading", icon: "book.fill") {
                VStack(spacing: AppTheme.Spacing.md) {
                    IlluminatedSettingsRow(
                        icon: "textformat.size",
                        title: "Font Size",
                        subtitle: "18pt"
                    ) {
                        Text("Medium")
                            .font(Typography.UI.subheadline)
                            .foregroundStyle(Color.secondaryText)
                    }

                    SettingsDivider()

                    IlluminatedSettingsRow(
                        icon: "book.closed",
                        title: "Translation"
                    ) {
                        Text("KJV")
                            .font(Typography.UI.caption1)
                            .foregroundStyle(.white)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, AppTheme.Spacing.xxs)
                            .background(Capsule().fill(Color.scholarAccent))
                    }
                }
            }
        }
        .padding()
    }
    .background(Color.appBackground)
}

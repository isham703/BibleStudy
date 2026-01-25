import SwiftUI

// MARK: - Settings Button
// Design Rationale: Buttons in settings need clear visual hierarchy.
// Primary = solid fill, Secondary = stroked, Destructive = red stroked,
// Navigation = chevron. All use Command typography (sans for action).
// Stoic-Existential Renaissance design

struct SettingsButton: View {
    enum Style {
        case primary      // Solid fill, white text
        case secondary    // Stroked, accent text
        case destructive  // Stroked, error color
        case navigation   // Chevron, no background
    }

    let title: String
    let icon: String?
    let style: Style
    let isLoading: Bool
    let action: () -> Void

    init(
        title: String,
        icon: String? = nil,
        style: Style = .secondary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticService.shared.lightTap()
            action()
        }) {
            HStack(spacing: Theme.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(foregroundColor)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(Typography.Icon.sm)
                }

                Text(title)
                    .font(Typography.Command.cta)

                if style == .navigation {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(Typography.Icon.xs)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: style == .navigation ? .infinity : nil)
            .frame(minHeight: Theme.Size.minTapTarget)
            .padding(.horizontal, style == .navigation ? 0 : Theme.Spacing.md)
            .background(background)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return Color("AppAccentAction")
        case .destructive: return Color("FeedbackError")
        case .navigation: return Color("AppTextPrimary")
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            Capsule().fill(Color("AppAccentAction"))
        case .secondary:
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color("AppAccentAction").opacity(Theme.Opacity.textSecondary), lineWidth: Theme.Stroke.hairline)
        case .destructive:
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color("FeedbackError").opacity(Theme.Opacity.textSecondary), lineWidth: Theme.Stroke.hairline)
        case .navigation:
            Color.clear
        }
    }
}

// MARK: - Full Width Variant
// Convenience initializer for buttons that should fill width

extension SettingsButton {
    static func fullWidth(
        title: String,
        icon: String? = nil,
        style: Style = .secondary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        SettingsButton(
            title: title,
            icon: icon,
            style: style,
            isLoading: isLoading,
            action: action
        )
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Settings Buttons") {
    VStack(spacing: Theme.Spacing.lg) {
        SettingsCard(title: "Actions", icon: "gear") {
            VStack(spacing: Theme.Spacing.md) {
                SettingsButton(
                    title: "Upgrade to Premium",
                    icon: "crown.fill",
                    style: .primary,
                    action: { print("Upgrade tapped") }
                )

                SettingsButton(
                    title: "Manage Subscription",
                    icon: "gearshape",
                    style: .secondary,
                    action: { print("Manage tapped") }
                )

                SettingsButton(
                    title: "Clear Cache",
                    icon: "trash",
                    style: .destructive,
                    action: { print("Clear tapped") }
                )

                SettingsDivider()

                SettingsButton(
                    title: "About",
                    icon: "info.circle",
                    style: .navigation,
                    action: { print("About tapped") }
                )
            }
        }
        .padding()
    }
    .background(Color.appBackground)
}

#Preview("Loading State") {
    VStack(spacing: Theme.Spacing.lg) {
        SettingsButton(
            title: "Restoring...",
            icon: "arrow.counterclockwise",
            style: .secondary,
            isLoading: true,
            action: {}
        )
    }
    .padding()
    .background(Color.appBackground)
}

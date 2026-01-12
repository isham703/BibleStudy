import SwiftUI

// MARK: - Floating Navigation Row
/// A navigation row with icon, title, subtitle, and optional chevron.
/// Supports destructive styling for actions like sign out.

struct FloatingNavigationRow: View {
    let title: String
    let subtitle: String
    let icon: String
    var showChevron: Bool = true
    var isDestructive: Bool = false
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    // MARK: - Animation State for Phase 6 Enhancement
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // Haptic feedback
            if !isDestructive {
                HapticService.shared.selectionChanged()
            } else {
                HapticService.shared.warning()
            }
            action()
        }) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Icon.base)
                    .foregroundStyle(isDestructive ? Color("FeedbackError") : Color("AppTextSecondary"))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.Command.body)
                        .foregroundStyle(isDestructive ? Color("FeedbackError") : Color("AppTextPrimary"))

                    Text(subtitle)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("TertiaryText"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if showChevron {
                    Image(systemName: "chevron.right")
                        // swiftlint:disable:next hardcoded_font_system
                        .font(Typography.Icon.xs.weight(.semibold))
                        .foregroundStyle(Color("TertiaryText"))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(NavigationRowButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityHint("Double tap to open")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Navigation Row Button Style

private struct NavigationRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .opacity(configuration.isPressed ? Theme.Opacity.pressed : 1.0)
            // swiftlint:disable:next hardcoded_animation_spring
            .animation(Theme.Animation.settle, value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
struct FloatingNavigationRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            FloatingNavigationRow(
                title: "Manage Subscription",
                subtitle: "Premium · Renews Jan 15",
                icon: "crown.fill",
                action: {}
            )

            FloatingNavigationRow(
                title: "Sign Out",
                subtitle: "idon@example.com",
                icon: "rectangle.portrait.and.arrow.right",
                showChevron: false,
                isDestructive: true,
                action: {}
            )
        }
        .background(Color("AppSurface"))
    }
}
#endif

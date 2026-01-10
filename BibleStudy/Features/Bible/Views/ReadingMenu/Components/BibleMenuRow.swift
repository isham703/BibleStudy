import SwiftUI

// MARK: - Bible Menu Row
// Reusable menu row with icon, title, subtitle, and chevron
// Used in MenuSection for main menu options

struct BibleMenuRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme

    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticService.shared.lightTap()
            action()
        }) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon container
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(Theme.Opacity.subtle))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(Typography.Icon.md.weight(.semibold))
                        .foregroundStyle(iconColor)
                }

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.Scripture.body.weight(.semibold))
                        .foregroundStyle(Color.primaryText)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color.tertiaryText)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(isPressed ? Colors.StateOverlay.pressed(Color.gray) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(Theme.Animation.fade) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Preview

#if DEBUG
struct BibleMenuRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            BibleMenuRow(
                icon: "magnifyingglass",
                iconColor: Color.accentIndigo,
                title: "Search",
                subtitle: "Find verses and passages"
            ) { }

            BibleMenuRow(
                icon: "speaker.wave.2",
                iconColor: Color.greekBlue,
                title: "Listen",
                subtitle: "Audio playback"
            ) { }
        }
        .padding()
        .background(Color.surfaceBackground)
    }
}
#endif

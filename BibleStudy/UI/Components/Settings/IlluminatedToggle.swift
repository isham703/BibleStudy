import SwiftUI

// MARK: - Illuminated Toggle
// A custom toggle with gold accents and glow animation on state change

struct IlluminatedToggle: View {
    @Binding var isOn: Bool
    let label: String
    let description: String?
    let icon: String?
    let iconColor: Color

    @State private var glowRadius: CGFloat = 0
    @State private var glowOpacity: Double = 0

    init(
        isOn: Binding<Bool>,
        label: String,
        description: String? = nil,
        icon: String? = nil,
        iconColor: Color = .scholarAccent
    ) {
        self._isOn = isOn
        self.label = label
        self.description = description
        self.icon = icon
        self.iconColor = iconColor
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Icon (optional)
            if let icon = icon {
                iconView(icon: icon)
            }

            // Label and description
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(label)
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.primaryText)

                if let description = description {
                    Text(description)
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            // Custom toggle
            toggleSwitch
        }
        .contentShape(Rectangle())
        .onTapGesture {
            toggleWithAnimation()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(description ?? "")
    }

    // MARK: - Icon View

    private func iconView(icon: String) -> some View {
        Image(systemName: icon)
            .font(Typography.UI.iconSm.weight(.medium))
            .foregroundStyle(iconColor)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small + 2)
                    .fill(iconColor.opacity(AppTheme.Opacity.subtle + 0.02))
            )
    }

    // MARK: - Toggle Switch

    private var toggleSwitch: some View {
        ZStack {
            // Glow effect (behind the toggle)
            if !AppTheme.Animation.isReduceMotionEnabled {
                Circle()
                    .fill(Color.scholarAccent)
                    .blur(radius: glowRadius)
                    .opacity(glowOpacity)
                    .frame(width: 40, height: 40)
            }

            // Toggle track
            Capsule()
                .fill(isOn ? Color.scholarAccent : Color.divider.opacity(AppTheme.Opacity.heavy))
                .frame(width: 51, height: 31)
                .overlay(
                    Capsule()
                        .stroke(
                            isOn ? Color.scholarAccent.opacity(AppTheme.Opacity.medium) : Color.clear,
                            lineWidth: AppTheme.Border.regular
                        )
                        .blur(radius: AppTheme.Blur.subtle)
                )

            // Toggle thumb
            Circle()
                .fill(.white)
                .shadow(color: .black.opacity(AppTheme.Opacity.light), radius: 2, x: 0, y: 1)
                .frame(width: 27, height: 27)
                .offset(x: isOn ? 10 : -10)
        }
        .animation(AppTheme.Animation.sacredSpring, value: isOn)
    }

    // MARK: - Toggle Action

    private func toggleWithAnimation() {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Toggle state
        isOn.toggle()

        // Trigger glow animation if turning on (and motion is not reduced)
        if isOn && !AppTheme.Animation.isReduceMotionEnabled {
            withAnimation(AppTheme.Animation.standard) {
                glowRadius = 20
                glowOpacity = 0.6
            }
            withAnimation(AppTheme.Animation.slow.delay(0.3)) {
                glowRadius = AppTheme.Blur.medium
                glowOpacity = 0
            }
        }
    }
}

// MARK: - Illuminated Toggle Row
// Convenience wrapper for toggle in a settings row context

struct IlluminatedToggleRow: View {
    @Binding var isOn: Bool
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?

    init(
        isOn: Binding<Bool>,
        icon: String,
        iconColor: Color = .scholarAccent,
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
        IlluminatedToggle(
            isOn: $isOn,
            label: title,
            description: subtitle,
            icon: icon,
            iconColor: iconColor
        )
    }
}

// MARK: - Preview

#Preview("Illuminated Toggle") {
    struct PreviewContainer: View {
        @State private var toggle1 = true
        @State private var toggle2 = false
        @State private var toggle3 = true

        var body: some View {
            VStack(spacing: AppTheme.Spacing.xl) {
                IlluminatedSettingsCard(title: "Notifications", icon: "bell.fill") {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        IlluminatedToggle(
                            isOn: $toggle1,
                            label: "Daily Reading Reminder",
                            description: "Get reminded at your chosen time",
                            icon: "bell.fill",
                            iconColor: .scholarAccent
                        )

                        SettingsDivider()

                        IlluminatedToggle(
                            isOn: $toggle2,
                            label: "Streak Protection",
                            description: "We'll remind you at 8 PM if you haven't read today",
                            icon: "flame.fill",
                            iconColor: .vermillion
                        )

                        SettingsDivider()

                        IlluminatedToggle(
                            isOn: $toggle3,
                            label: "Devotional Mode",
                            icon: "sparkles",
                            iconColor: .scholarAccent
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

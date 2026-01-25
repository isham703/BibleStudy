import SwiftUI

// MARK: - Toggle with Pulse Feedback
// Design Rationale: Toggle activation is a critical moment.
// The pulse animation provides immediate visual feedback that
// the action was registered, reinforcing the user's intent.
// This follows the "ceremonial restraint" principle - subtle
// but meaningful motion that serves a purpose.
// Stoic-Existential Renaissance design

struct SettingsToggle: View {
    @Binding var isOn: Bool
    let label: String
    let description: String?
    let icon: String?
    let iconColor: Color

    // MARK: - Animation State
    // Purpose: Track toggle state for pulse effect
    @State private var justToggled = false
    @State private var pulseScale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

            // Label and description - all Command typography (Sans)
            // Rationale: Settings is "action" space, not "contemplation"
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

            // Toggle with pulse feedback
            // Rationale: The pulse provides immediate visual confirmation
            // that scales from center outward, mimicking a "ripple" of activation
            ZStack {
                // Pulse effect - only on activation, respects reduce motion
                if justToggled && isOn && !reduceMotion {
                    Circle()
                        .fill(iconColor.opacity(Theme.Opacity.selectionBackground))
                        .scaleEffect(pulseScale)
                        .opacity(1 - (pulseScale - 1) / 1.5) // Fade as it expands
                        .frame(width: 30, height: 30)
                }

                Toggle("", isOn: $isOn)
                    .toggleStyle(GoldToggleStyle())
                    .labelsHidden()
            }
            .onChange(of: isOn) { _, newValue in
                triggerFeedback(newValue: newValue)
            }
        }
        .frame(minHeight: Theme.Size.minTapTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label)\(description.map { ", \($0)" } ?? "")")
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Feedback Trigger
    // Design Rationale: Multi-sensory feedback (visual + haptic) creates
    // a complete interaction moment. The 0.5s duration matches the
    // Theme.Animation.slowFade timing for consistency.

    private func triggerFeedback(newValue: Bool) {
        guard !reduceMotion else { return }

        justToggled = true
        pulseScale = 1.0

        // Animate pulse expansion using design system timing
        withAnimation(Theme.Animation.slowFade) {
            pulseScale = 2.5
        }

        // Haptic feedback
        HapticService.shared.lightTap()

        // Reset after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            justToggled = false
            pulseScale = 1.0
        }
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

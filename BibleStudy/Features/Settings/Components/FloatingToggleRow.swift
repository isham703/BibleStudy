import SwiftUI

// MARK: - Floating Toggle Row
/// A toggle row with icon, title, and subtitle for Floating Sanctuary Settings.
/// Features the gold toggle style for consistent design.

struct FloatingToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool

    // MARK: - Animation State for Phase 6 Enhancement
    @State private var justToggled = false
    @State private var pulseScale: CGFloat = 1.0

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                // swiftlint:disable:next hardcoded_font_system
                .font(Typography.Icon.base)
                .foregroundStyle(Color.secondaryText)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.Command.body)
                    .foregroundStyle(Color.primaryText)

                Text(subtitle)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.tertiaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Toggle with illumination pulse effect
            ZStack {
                // Radial pulse on activation (Phase 6 enhancement)
                if justToggled && isOn && !Theme.Animation.isReduceMotionEnabled {
                    Circle()
                        .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium))
                        .scaleEffect(pulseScale)
                        .opacity(1 - (pulseScale - 1) / 1.5)
                        .frame(width: 30, height: 30)
                }

                Toggle("", isOn: $isOn)
                    .toggleStyle(GoldToggleStyle())
                    .labelsHidden()
            }
            .onChange(of: isOn) { _, newValue in
                guard !Theme.Animation.isReduceMotionEnabled else { return }

                justToggled = true
                pulseScale = 1.0

                withAnimation(Theme.Animation.slowFade) {
                    // swiftlint:disable:next hardcoded_scale_value
                    pulseScale = 2.5
                }

                HapticService.shared.lightTap()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    justToggled = false
                    pulseScale = 1.0
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#if DEBUG
struct FloatingToggleRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            FloatingToggleRow(
                title: "Scholar Insights",
                subtitle: "AI-powered verse analysis",
                icon: "brain.head.profile",
                isOn: .constant(true)
            )

            FloatingToggleRow(
                title: "Voice Guidance",
                subtitle: "Audio narration",
                icon: "speaker.wave.2.fill",
                isOn: .constant(false)
            )
        }
        .background(Color.surfaceBackground)
    }
}
#endif

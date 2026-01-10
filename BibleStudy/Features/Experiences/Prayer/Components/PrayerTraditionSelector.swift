import SwiftUI

// MARK: - Prayer Tradition Selector
// Horizontal chip selector for 4 traditions with Sacred Manuscript styling

struct PrayerTraditionSelector: View {
    @Binding var selectedTradition: PrayerTradition

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // swiftlint:disable:next hardcoded_stack_spacing
        HStack(spacing: 12) {  // Tradition pill spacing
            ForEach(PrayerTradition.allCases) { tradition in
                Button {
                    // Soft haptic
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4)
                    // swiftlint:disable:next hardcoded_animation_spring
                    withAnimation(Theme.Animation.settle) {
                        selectedTradition = tradition
                    }
                } label: {
                    Text(tradition.shortName)
                        // swiftlint:disable:next hardcoded_font_custom
                        .font(.system(size: 10, weight: .medium, design: .serif))
                        // swiftlint:disable:next hardcoded_tracking
                        .tracking(2)
                        .foregroundStyle(
                            selectedTradition == tradition
                            ? Color.surfaceBackground
                            : Color.primaryText
                        )
                        // swiftlint:disable:next hardcoded_padding_edge
                        .padding(.horizontal, 14)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(
                                    selectedTradition == tradition
                                    ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))
                                    : Color.appBackground
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    selectedTradition == tradition
                                    ? Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme))
                                    : Color.tertiaryText.opacity(Theme.Opacity.heavy),
                                    lineWidth: Theme.Stroke.hairline
                                )
                        )
                        // swiftlint:disable:next hardcoded_shadow_params
                        .shadow(
                            color: selectedTradition == tradition
                            ? Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.medium)
                            : Color.clear,
                            radius: 4
                        )
                }
                .buttonStyle(.plain)
                // swiftlint:disable:next hardcoded_scale_effect
                .scaleEffect(selectedTradition == tradition ? 1.02 : 1.0)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        PrayerTraditionSelector(
            selectedTradition: .constant(.psalmicLament)
        )
    }
}

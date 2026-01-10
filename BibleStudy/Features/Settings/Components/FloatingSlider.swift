import SwiftUI

// MARK: - Floating Slider
/// A custom slider with gold accent track and glowing thumb.
/// Features smooth drag interaction with haptic feedback at boundaries.

struct FloatingSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double? = nil
    var label: String = "Slider"
    var onEditingChanged: ((Bool) -> Void)? = nil

    // MARK: - State
    @State private var isDragging = false
    @State private var lastStepValue: Double = 0

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View{
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(Color.white.opacity(Theme.Opacity.faint))
                    // swiftlint:disable:next hardcoded_divider_frame
                    .frame(height: 6)

                // Filled track with gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.pressed), Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    // swiftlint:disable:next hardcoded_divider_frame
                    .frame(width: thumbPosition(in: geometry.size.width), height: 6)

                // Thumb with glow effect
                ZStack {
                    // Outer glow when dragging
                    if isDragging && !reduceMotion {
                        Circle()
                            .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary))
                            // swiftlint:disable:next hardcoded_frame_size
                            .frame(width: 36, height: 36)
                            .blur(radius: 4)
                    }

                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        // swiftlint:disable:next hardcoded_shadow_params
                        .shadow(color: Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(isDragging ? Theme.Opacity.primary : Theme.Opacity.disabled), radius: isDragging ? 12 : 8)
                }
                // swiftlint:disable:next hardcoded_offset
                .offset(x: thumbPosition(in: geometry.size.width) - 12)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            if !isDragging {
                                isDragging = true
                                onEditingChanged?(true)
                                HapticService.shared.selectionChanged()
                            }

                            let newValue = Double(gesture.location.x / geometry.size.width)
                            let clampedValue = min(max(newValue, 0), 1)
                            var newValueInRange = range.lowerBound + clampedValue * (range.upperBound - range.lowerBound)

                            // Apply step snapping if provided
                            if let step = step {
                                newValueInRange = round(newValueInRange / step) * step
                                newValueInRange = min(max(newValueInRange, range.lowerBound), range.upperBound)

                                // Haptic feedback on step change
                                if newValueInRange != lastStepValue {
                                    HapticService.shared.lightTap()
                                    lastStepValue = newValueInRange
                                }
                            }

                            value = newValueInRange
                        }
                        .onEnded { _ in
                            isDragging = false
                            onEditingChanged?(false)
                        }
                )
            }
        }
        .frame(height: 24)
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityValue("\(Int(value))")
        .accessibilityAdjustableAction { direction in
            let stepAmount = step ?? ((range.upperBound - range.lowerBound) / 10)
            switch direction {
            case .increment:
                value = min(value + stepAmount, range.upperBound)
            case .decrement:
                value = max(value - stepAmount, range.lowerBound)
            @unknown default:
                break
            }
        }
    }

    private func thumbPosition(in width: CGFloat) -> CGFloat {
        let rangeSpan = range.upperBound - range.lowerBound
        guard rangeSpan > 0 else { return 0 }
        let percentage = (value - range.lowerBound) / rangeSpan
        return CGFloat(percentage) * width
    }
}

// MARK: - Preview

#if DEBUG
struct FloatingSlider_Previews: PreviewProvider {
    static var previews: some View {
        // swiftlint:disable:next hardcoded_stack_spacing
        VStack(spacing: 32) {  // Preview layout spacing
            VStack(alignment: .leading) {
                Text("Font Size: 18")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.secondaryText)
                FloatingSlider(value: .constant(18), range: 14...24, step: 1)
            }

            VStack(alignment: .leading) {
                Text("Line Spacing: 1.5")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.secondaryText)
                FloatingSlider(value: .constant(1.5), range: 1.0...2.0, step: 0.1)
            }
        }
        // swiftlint:disable:next hardcoded_padding_single
        .padding(24)  // Preview container padding
        .background(Color.surfaceBackground)
    }
}
#endif

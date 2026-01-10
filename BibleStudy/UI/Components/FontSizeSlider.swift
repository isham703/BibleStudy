import SwiftUI

// MARK: - Font Size Slider
// Shared discrete slider for scripture font size selection
// Performance: Uses cached width to avoid GeometryReader recalculation on scroll

struct FontSizeSlider: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedSize: ScriptureFontSize

    private let sizes = ScriptureFontSize.allCases

    // Cached slider width to avoid GeometryReader recalculation during scroll
    @State private var sliderWidth: CGFloat = 200 // Default fallback

    // Computed from cached width
    private var stepWidth: CGFloat {
        guard sizes.count > 1 else { return sliderWidth }
        return sliderWidth / CGFloat(sizes.count - 1)
    }

    private var currentIndex: Int {
        sizes.firstIndex(of: selectedSize) ?? 2
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Track
            // swiftlint:disable:next hardcoded_rounded_rectangle
            RoundedRectangle(cornerRadius: Theme.Radius.xs)
                .fill(Color.secondaryText.opacity(Theme.Opacity.subtle))
                // swiftlint:disable:next hardcoded_divider_frame
                .frame(height: 4)

            // Filled portion
            // swiftlint:disable:next hardcoded_rounded_rectangle
            RoundedRectangle(cornerRadius: Theme.Radius.xs)
                .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                // swiftlint:disable:next hardcoded_divider_frame
                .frame(width: stepWidth * CGFloat(currentIndex), height: 4)

            // Thumb
            Circle()
                .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                .frame(width: 20, height: 20)
                .shadow(color: Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.medium), radius: 4)
                .offset(x: stepWidth * CGFloat(currentIndex) - 10)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newIndex = Int(round(value.location.x / stepWidth))
                            let clampedIndex = max(0, min(sizes.count - 1, newIndex))
                            if sizes[clampedIndex] != selectedSize {
                                selectedSize = sizes[clampedIndex]
                                HapticService.shared.lightTap()
                            }
                        }
                )
        }
        .frame(height: 20)
        .background(
            // Measure width once and cache it
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        sliderWidth = geometry.size.width
                    }
                    .onChange(of: geometry.size.width) { _, newWidth in
                        sliderWidth = newWidth
                    }
            }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Text size")
        .accessibilityValue(selectedSize.displayName)
        .accessibilityAdjustableAction { direction in
            let currentIndex = sizes.firstIndex(of: selectedSize) ?? 2
            switch direction {
            case .increment:
                if currentIndex < sizes.count - 1 {
                    selectedSize = sizes[currentIndex + 1]
                    HapticService.shared.lightTap()
                }
            case .decrement:
                if currentIndex > 0 {
                    selectedSize = sizes[currentIndex - 1]
                    HapticService.shared.lightTap()
                }
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var size: ScriptureFontSize = .medium

        var body: some View {
            VStack(spacing: Theme.Spacing.xl) {
                Text("Selected: \(size.rawValue)")
                FontSizeSlider(selectedSize: $size)
                    .frame(width: 200)
            }
            .padding()
        }
    }
    return PreviewWrapper()
}

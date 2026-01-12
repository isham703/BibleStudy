import SwiftUI

// MARK: - Bible Font Size Slider
// Custom stepped slider for scripture font size selection
// Used in SettingsSection for text size adjustment

struct BibleFontSizeSlider: View {
    @Binding var selectedSize: ScriptureFontSize

    @Environment(\.colorScheme) private var colorScheme
    private let sizes = ScriptureFontSize.allCases

    var body: some View {
        GeometryReader { geometry in
            let stepWidth = geometry.size.width / CGFloat(sizes.count - 1)
            let currentIndex = sizes.firstIndex(of: selectedSize) ?? 2

            ZStack(alignment: .leading) {
                // Track
                // swiftlint:disable:next hardcoded_rounded_rectangle
                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                    .fill(Color.appDivider)
                    .frame(height: 3)

                // Filled portion
                // swiftlint:disable:next hardcoded_rounded_rectangle
                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                    .fill(Color("AppAccentAction"))
                    .frame(width: stepWidth * CGFloat(currentIndex), height: 3)

                // Thumb
                Circle()
                    .fill(Color("AppAccentAction"))
                    .frame(width: 20, height: 20)
                    .shadow(color: Color("AppAccentAction").opacity(Theme.Opacity.focusStroke), radius: 4)
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
        }
        .frame(height: 20)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewContainer: View {
        @State private var size: ScriptureFontSize = .medium

        var body: some View {
            // swiftlint:disable:next hardcoded_stack_spacing
            VStack(spacing: 20) {
                HStack(spacing: Theme.Spacing.md) {
                    Text("A")
                        .font(Typography.Scripture.footnote)
                        .foregroundStyle(Color("TertiaryText"))

                    BibleFontSizeSlider(selectedSize: $size)

                    Text("A")
                        .font(Typography.Scripture.prompt)
                        .foregroundStyle(Color("TertiaryText"))
                }
                .padding()

                Text("Selected: \(size.rawValue)")
                    // swiftlint:disable:next hardcoded_swiftui_text_style
                    .font(.caption)
            }
            .padding()
            .background(Color("AppSurface"))
        }
    }

    return PreviewContainer()
}

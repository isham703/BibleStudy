import SwiftUI

// MARK: - Font Size Slider
// Shared discrete slider for scripture font size selection

struct FontSizeSlider: View {
    @Binding var selectedSize: ScriptureFontSize

    private let sizes = ScriptureFontSize.allCases

    var body: some View {
        GeometryReader { geometry in
            let stepWidth = geometry.size.width / CGFloat(sizes.count - 1)
            let currentIndex = sizes.firstIndex(of: selectedSize) ?? 2

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondaryText.opacity(AppTheme.Opacity.subtle))
                    .frame(height: 4)

                // Filled portion
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.scholarAccent)
                    .frame(width: stepWidth * CGFloat(currentIndex), height: 4)

                // Thumb
                Circle()
                    .fill(Color.scholarAccent)
                    .frame(width: 20, height: 20)
                    .shadow(color: Color.scholarAccent.opacity(0.3), radius: 4)
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
    struct PreviewWrapper: View {
        @State private var size: ScriptureFontSize = .medium

        var body: some View {
            VStack(spacing: 20) {
                Text("Selected: \(size.rawValue)")
                FontSizeSlider(selectedSize: $size)
                    .frame(width: 200)
            }
            .padding()
        }
    }
    return PreviewWrapper()
}

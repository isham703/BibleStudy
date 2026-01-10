import SwiftUI

// MARK: - Minimal Tradition Picker
// Horizontal chip selector for prayer traditions

struct MinimalTraditionPicker: View {
    @Binding var selectedTradition: PrayerTradition

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prayer Style")
                .font(Typography.Icon.xs)
                .foregroundStyle(DeepPrayerColors.tertiaryText)
                .textCase(.uppercase)
                .tracking(1)

            // Horizontal scrolling chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PrayerTradition.allCases) { tradition in
                        traditionChip(tradition)
                    }
                }
            }
        }
    }

    // MARK: - Tradition Chip

    private func traditionChip(_ tradition: PrayerTradition) -> some View {
        let isSelected = selectedTradition == tradition

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTradition = tradition
            }
        }) {
            Text(tradition.shortName)
                .font(Typography.Icon.sm)
                .foregroundStyle(
                    isSelected
                        ? DeepPrayerColors.primaryText
                        : DeepPrayerColors.secondaryText
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? DeepPrayerColors.roseHighlight
                                : DeepPrayerColors.surfaceElevated
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected
                                ? DeepPrayerColors.roseBorder
                                : Color.clear,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Preview

#Preview("Minimal Tradition Picker") {
    ZStack {
        DeepPrayerColors.sacredNavy.ignoresSafeArea()

        VStack(spacing: 40) {
            MinimalTraditionPicker(selectedTradition: .constant(.psalmicLament))
            MinimalTraditionPicker(selectedTradition: .constant(.celtic))
        }
        .padding()
    }
}

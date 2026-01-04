import SwiftUI

// MARK: - Prayer Tradition Selector
// Horizontal chip selector for 4 traditions with Sacred Manuscript styling

struct PrayerTraditionSelector: View {
    @Binding var selectedTradition: PrayerTradition

    var body: some View {
        HStack(spacing: 12) {
            ForEach(PrayerTradition.allCases) { tradition in
                Button {
                    // Soft haptic
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4)
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        selectedTradition = tradition
                    }
                } label: {
                    Text(tradition.shortName)
                        .font(.custom("Cinzel-Regular", size: 10))
                        .tracking(2)
                        .foregroundStyle(
                            selectedTradition == tradition
                            ? Color.prayerCandlelight
                            : Color.prayerUmber
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(
                                    selectedTradition == tradition
                                    ? Color.prayerVermillion
                                    : Color.prayerVellum
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    selectedTradition == tradition
                                    ? Color.prayerGold
                                    : Color.prayerOxide.opacity(0.5),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: selectedTradition == tradition
                            ? Color.prayerGold.opacity(0.3)
                            : Color.clear,
                            radius: 4
                        )
                }
                .buttonStyle(.plain)
                .scaleEffect(selectedTradition == tradition ? 1.02 : 1.0)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.prayerVellum.ignoresSafeArea()
        PrayerTraditionSelector(
            selectedTradition: .constant(.psalmicLament)
        )
    }
}

import SwiftUI

// MARK: - Prayers From the Deep Showcase
// Main directory screen showing all prayer variation options

struct PrayersFromDeepShowcaseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = false
    @State private var breathePhase: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background
                AnimatedDeepPrayerBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        header
                            .opacity(isVisible ? 1 : 0)
                            .offset(y: isVisible ? 0 : -20)

                        // Variation cards
                        variationList
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: PrayerVariationType.self) { variation in
                destinationView(for: variation)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isVisible = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            // Dismiss button row
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DeepPrayerColors.secondaryText)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(DeepPrayerColors.surfaceElevated)
                        )
                }

                Spacer()
            }

            // Title section
            VStack(spacing: 8) {
                // Eyebrow
                Text("DESIGN SHOWCASE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(DeepPrayerColors.roseAccent)

                // Main title
                Text("Prayers from the Deep")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(DeepPrayerColors.primaryText)
                    .multilineTextAlignment(.center)

                // Subtitle
                Text("Choose a style variation to preview")
                    .font(.system(size: 15))
                    .foregroundStyle(DeepPrayerColors.secondaryText)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Variation List

    private var variationList: some View {
        VStack(spacing: 16) {
            ForEach(Array(PrayerVariationType.allCases.enumerated()), id: \.element.id) { index, variation in
                NavigationLink(value: variation) {
                    VariationPreviewCard(variation: variation)
                }
                .buttonStyle(.plain)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
                .animation(
                    .easeOut(duration: 0.5)
                    .delay(0.1 + Double(index) * 0.1),
                    value: isVisible
                )
            }
        }
    }

    // MARK: - Destination Views

    @ViewBuilder
    private func destinationView(for variation: PrayerVariationType) -> some View {
        switch variation {
        case .minimal:
            MinimalPrayerView()
        case .balanced:
            BalancedPrayerView()
        case .ornate:
            OrnatePrayerView()
        }
    }
}

// MARK: - Preview

#Preview("Showcase Directory") {
    PrayersFromDeepShowcaseView()
}

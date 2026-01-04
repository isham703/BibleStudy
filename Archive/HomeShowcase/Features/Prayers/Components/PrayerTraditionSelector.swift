import SwiftUI

// MARK: - Prayer Tradition Selector
// Horizontal chip selector for 4 traditions with variant-specific styling

struct PrayerTraditionSelector: View {
    @Binding var selectedTradition: PrayerTradition
    let variant: PrayersShowcaseVariant

    var body: some View {
        switch variant {
        case .sacredManuscript:
            manuscriptStyle
        case .desertSilence:
            silenceStyle
        case .auroraVeil:
            auroraStyle
        }
    }

    // MARK: - Sacred Manuscript Style (Pills with borders)

    private var manuscriptStyle: some View {
        HStack(spacing: 12) {
            ForEach(PrayerTradition.allCases) { tradition in
                Button {
                    HomeShowcaseHaptics.manuscriptPress()
                    withAnimation(HomeShowcaseTheme.Animation.manuscriptSpring) {
                        selectedTradition = tradition
                    }
                } label: {
                    Text(tradition.shortName)
                        .font(.custom("Cinzel-Regular", size: 10))
                        .tracking(2)
                        .foregroundStyle(
                            selectedTradition == tradition
                            ? Color.manuscriptCandlelight
                            : Color.manuscriptUmber
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(
                                    selectedTradition == tradition
                                    ? Color.manuscriptVermillion
                                    : Color.manuscriptVellum
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    selectedTradition == tradition
                                    ? Color.manuscriptGold
                                    : Color.manuscriptOxide.opacity(0.5),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: selectedTradition == tradition
                            ? Color.manuscriptGold.opacity(0.3)
                            : Color.clear,
                            radius: 4
                        )
                }
                .buttonStyle(.plain)
                .scaleEffect(selectedTradition == tradition ? 1.02 : 1.0)
            }
        }
    }

    // MARK: - Desert Silence Style (Text links with dots)

    private var silenceStyle: some View {
        HStack(spacing: 0) {
            ForEach(Array(PrayerTradition.allCases.enumerated()), id: \.element.id) { index, tradition in
                if index > 0 {
                    Text(" · ")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color.desertAsh)
                }

                Button {
                    HomeShowcaseHaptics.silencePress()
                    withAnimation(HomeShowcaseTheme.Animation.silenceEase) {
                        selectedTradition = tradition
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(tradition.shortName.lowercased())
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(
                                selectedTradition == tradition
                                ? Color.desertSumiInk
                                : Color.desertAsh
                            )

                        // Subtle underline for selected
                        Rectangle()
                            .fill(Color.desertSumiInk)
                            .frame(height: 1)
                            .opacity(selectedTradition == tradition ? 1 : 0)
                            .animation(.easeOut(duration: 0.2), value: selectedTradition)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Aurora Veil Style (Glass pills)

    private var auroraStyle: some View {
        HStack(spacing: 10) {
            ForEach(PrayerTradition.allCases) { tradition in
                Button {
                    HomeShowcaseHaptics.auroraPress()
                    withAnimation(HomeShowcaseTheme.Animation.auroraSpring) {
                        selectedTradition = tradition
                    }
                } label: {
                    Text(tradition.shortName)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    selectedTradition == tradition
                                    ? LinearGradient(
                                        colors: [.auroraViolet, .auroraTeal],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [.clear, .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    selectedTradition == tradition
                                    ? Color.clear
                                    : Color.white.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: selectedTradition == tradition
                            ? Color.auroraViolet.opacity(0.4)
                            : Color.clear,
                            radius: 8
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preview

#Preview("Sacred Manuscript") {
    ZStack {
        Color.manuscriptVellum.ignoresSafeArea()
        PrayerTraditionSelector(
            selectedTradition: .constant(.psalmicLament),
            variant: .sacredManuscript
        )
    }
}

#Preview("Desert Silence") {
    ZStack {
        Color.desertDawnMist.ignoresSafeArea()
        PrayerTraditionSelector(
            selectedTradition: .constant(.desertFathers),
            variant: .desertSilence
        )
    }
}

#Preview("Aurora Veil") {
    ZStack {
        Color.auroraVoid.ignoresSafeArea()
        PrayerTraditionSelector(
            selectedTradition: .constant(.celtic),
            variant: .auroraVeil
        )
    }
}

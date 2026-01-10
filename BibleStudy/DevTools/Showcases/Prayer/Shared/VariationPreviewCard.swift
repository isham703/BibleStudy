import SwiftUI

// MARK: - Variation Type
// Defines the three showcase variations

enum PrayerVariationType: String, CaseIterable, Identifiable {
    case minimal = "Minimal"
    case balanced = "Balanced"
    case ornate = "Ornate"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .minimal:
            return "Clean & Focused"
        case .balanced:
            return "Immersive & Flowing"
        case .ornate:
            return "Rich & Conversational"
        }
    }

    var description: String {
        switch self {
        case .minimal:
            return "Card-based interface with subtle animations and generous whitespace. Perfect for quick, focused prayer moments."
        case .balanced:
            return "Full-screen immersive phases with breathing animations. A contemplative journey from heart to prayer."
        case .ornate:
            return "Chat-like conversational flow with dramatic animations and medieval manuscript aesthetics."
        }
    }

    var visualDensity: String {
        switch self {
        case .minimal: return "Light"
        case .balanced: return "Medium"
        case .ornate: return "Rich"
        }
    }

    var animationLevel: String {
        switch self {
        case .minimal: return "Subtle"
        case .balanced: return "Moderate"
        case .ornate: return "Immersive"
        }
    }

    var interactionStyle: String {
        switch self {
        case .minimal: return "Cards"
        case .balanced: return "Full-screen"
        case .ornate: return "Conversational"
        }
    }

    var icon: String {
        switch self {
        case .minimal: return "square.grid.2x2"
        case .balanced: return "circle.hexagongrid"
        case .ornate: return "text.bubble"
        }
    }

    var densityDots: Int {
        switch self {
        case .minimal: return 1
        case .balanced: return 2
        case .ornate: return 3
        }
    }
}

// MARK: - Variation Preview Card

struct VariationPreviewCard: View {
    let variation: PrayerVariationType
    var isSelected: Bool = false

    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon and badges
            HStack(alignment: .top) {
                // Variation icon
                ZStack {
                    Circle()
                        .fill(DeepPrayerColors.roseAccent.opacity(Theme.Opacity.divider))
                        .frame(width: 48, height: 48)

                    Image(systemName: variation.icon)
                        .font(Typography.Icon.lg)
                        .foregroundStyle(DeepPrayerColors.roseAccent)
                }

                Spacer()

                // Density indicator
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index < variation.densityDots
                                ? DeepPrayerColors.roseAccent
                                : DeepPrayerColors.surfaceBorder)
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(DeepPrayerColors.surfaceElevated)
                )
            }

            // Title and subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(variation.rawValue)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(DeepPrayerColors.primaryText)

                Text(variation.subtitle)
                    .font(Typography.Icon.sm)
                    .foregroundStyle(DeepPrayerColors.roseAccent)
            }

            // Description
            Text(variation.description)
                .font(Typography.Command.caption)
                .foregroundStyle(DeepPrayerColors.secondaryText)
                .lineLimit(3)
                .lineSpacing(2)

            // Feature tags
            HStack(spacing: 8) {
                featureTag(variation.animationLevel, icon: "waveform")
                featureTag(variation.interactionStyle, icon: "hand.tap")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(DeepPrayerColors.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .stroke(
                    isSelected
                        ? DeepPrayerColors.roseAccent
                        : DeepPrayerColors.surfaceBorder,
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    // MARK: - Feature Tag

    private func featureTag(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(Typography.Icon.xxs)

            Text(text)
                .font(Typography.Icon.xxs.weight(.medium))
        }
        .foregroundStyle(DeepPrayerColors.tertiaryText)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(DeepPrayerColors.surfaceElevated)
        )
    }
}

// MARK: - Preview

#Preview("Variation Cards") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(PrayerVariationType.allCases) { variation in
                VariationPreviewCard(
                    variation: variation,
                    isSelected: variation == .balanced
                )
            }
        }
        .padding()
    }
    .background(DeepPrayerColors.sacredNavy)
}

#Preview("Single Card") {
    VariationPreviewCard(variation: .ornate)
        .padding()
        .background(DeepPrayerColors.sacredNavy)
}

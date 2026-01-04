import SwiftUI

// MARK: - Prayer Action Toolbar
// Save/Share/New buttons with haptic + toast feedback

struct PrayerActionToolbar: View {
    let variant: PrayersShowcaseVariant
    let onSave: () -> Void
    let onShare: () -> Void
    let onNew: () -> Void

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

    // MARK: - Sacred Manuscript Style

    private var manuscriptStyle: some View {
        HStack(spacing: 32) {
            ManuscriptActionButton(icon: "bookmark", label: "Save", action: onSave)
            ManuscriptActionButton(icon: "square.and.arrow.up", label: "Share", action: onShare)
            ManuscriptActionButton(icon: "arrow.counterclockwise", label: "New", action: onNew)
        }
    }

    // MARK: - Desert Silence Style

    private var silenceStyle: some View {
        HStack(spacing: 48) {
            SilenceActionButton(icon: "bookmark", accessibilityLabel: "Save prayer", action: onSave)
            SilenceActionButton(icon: "square.and.arrow.up", accessibilityLabel: "Share prayer", action: onShare)
            SilenceActionButton(icon: "arrow.counterclockwise", accessibilityLabel: "New prayer", action: onNew)
        }
    }

    // MARK: - Aurora Veil Style

    private var auroraStyle: some View {
        HStack(spacing: 24) {
            AuroraActionButton(icon: "bookmark", label: "Save", action: onSave)
            AuroraActionButton(icon: "square.and.arrow.up", label: "Share", action: onShare)
            AuroraActionButton(icon: "arrow.counterclockwise", label: "New", action: onNew)
        }
    }
}

// MARK: - Manuscript Action Button

private struct ManuscriptActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HomeShowcaseHaptics.manuscriptPress()
            action()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.manuscriptGold, lineWidth: 1.5)
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.manuscriptGold)
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .shadow(
                    color: isPressed ? Color.manuscriptGold.opacity(0.4) : Color.clear,
                    radius: 8
                )

                Text(label)
                    .font(.custom("Cinzel-Regular", size: 10))
                    .tracking(1)
                    .foregroundStyle(Color.manuscriptOxide)
            }
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Silence Action Button

private struct SilenceActionButton: View {
    let icon: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            HomeShowcaseHaptics.silencePress()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.desertAsh)
                .frame(width: 44, height: 44) // Minimum touch target
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Aurora Action Button

private struct AuroraActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HomeShowcaseHaptics.auroraPress()
            action()
        }) {
            VStack(spacing: 6) {
                ZStack {
                    Capsule()
                        .fill(.ultraThinMaterial.opacity(0.5))
                        .frame(width: 56, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .shadow(
                    color: isPressed ? Color.auroraViolet.opacity(0.5) : Color.clear,
                    radius: 12
                )

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.auroraStarlight.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Toast View

struct PrayerToast: View {
    let message: String
    let variant: PrayersShowcaseVariant

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(textColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(backgroundColor)
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
            )
    }

    private var textColor: Color {
        switch variant {
        case .sacredManuscript:
            return .manuscriptUmber
        case .desertSilence:
            return .desertSumiInk
        case .auroraVeil:
            return .white
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .sacredManuscript:
            return .manuscriptCandlelight
        case .desertSilence:
            return .desertDawnMist
        case .auroraVeil:
            return Color.auroraViolet.opacity(0.9)
        }
    }
}

// MARK: - Preview

#Preview("Sacred Manuscript") {
    ZStack {
        Color.manuscriptVellum.ignoresSafeArea()
        VStack {
            Spacer()
            PrayerActionToolbar(
                variant: .sacredManuscript,
                onSave: {},
                onShare: {},
                onNew: {}
            )
            .padding(.bottom, 40)
        }
    }
}

#Preview("Desert Silence") {
    ZStack {
        Color.desertDawnMist.ignoresSafeArea()
        VStack {
            Spacer()
            PrayerActionToolbar(
                variant: .desertSilence,
                onSave: {},
                onShare: {},
                onNew: {}
            )
            .padding(.bottom, 40)
        }
    }
}

#Preview("Aurora Veil") {
    ZStack {
        Color.auroraVoid.ignoresSafeArea()
        VStack {
            Spacer()
            PrayerActionToolbar(
                variant: .auroraVeil,
                onSave: {},
                onShare: {},
                onNew: {}
            )
            .padding(.bottom, 40)
        }
    }
}

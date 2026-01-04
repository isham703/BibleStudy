import SwiftUI

// MARK: - Prayer Action Toolbar
// Save/Share/New buttons with Sacred Manuscript styling

struct PrayerActionToolbar: View {
    let onSave: () -> Void
    let onShare: () -> Void
    let onNew: () -> Void

    var body: some View {
        HStack(spacing: 32) {
            ManuscriptActionButton(icon: "bookmark", label: "Save", action: onSave)
            ManuscriptActionButton(icon: "square.and.arrow.up", label: "Share", action: onShare)
            ManuscriptActionButton(icon: "arrow.counterclockwise", label: "New", action: onNew)
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
            // Soft haptic
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4)
            action()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.prayerGold, lineWidth: 1.5)
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.prayerGold)
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .shadow(
                    color: isPressed ? Color.prayerGold.opacity(0.4) : Color.clear,
                    radius: 8
                )

                Text(label)
                    .font(.custom("Cinzel-Regular", size: 10))
                    .tracking(1)
                    .foregroundStyle(Color.prayerOxide)
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

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.prayerUmber)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.prayerCandlelight)
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
            )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.prayerVellum.ignoresSafeArea()
        VStack {
            Spacer()
            PrayerActionToolbar(
                onSave: {},
                onShare: {},
                onNew: {}
            )
            .padding(.bottom, 40)
        }
    }
}

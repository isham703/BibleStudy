import SwiftUI

// MARK: - Prayer Action Toolbar
// Save/Share/New buttons with Sacred Manuscript styling

struct PrayerActionToolbar: View {
    let onSave: () -> Void
    let onShare: () -> Void
    let onNew: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.xxl) {
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
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // Soft haptic
            // swiftlint:disable:next hardcoded_haptic_intensity
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4)
            action()
        }) {
            VStack(spacing: Theme.Spacing.sm) {
                ZStack {
                    Circle()
                        // swiftlint:disable:next hardcoded_line_width
                        .stroke(Color("AccentBronze"), lineWidth: 1.5)
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(Typography.Icon.xl)
                        .foregroundStyle(Color("AccentBronze"))
                }
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .shadow(
                    color: isPressed ? Color("AccentBronze").opacity(Theme.Opacity.disabled) : Color.clear,
                    // swiftlint:disable:next hardcoded_shadow_radius
                    radius: 8
                )

                Text(label)
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .tracking(1)
                    .foregroundStyle(Color("TertiaryText"))
            }
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(Theme.Animation.settle) {
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
            // swiftlint:disable:next hardcoded_font_system
            .font(Typography.Icon.sm)
            .foregroundStyle(Color("AppTextPrimary"))
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                Capsule()
                    .fill(Color("AppSurface"))
                    // swiftlint:disable:next hardcoded_shadow_radius
                    .shadow(color: .black.opacity(Theme.Opacity.selectionBackground), radius: 10, y: 4)
            )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack {
            Spacer()
            PrayerActionToolbar(
                onSave: {},
                onShare: {},
                onNew: {}
            )
            // swiftlint:disable:next hardcoded_padding_edge
            .padding(.bottom, 40)  // Safe area offset
        }
    }
}

import SwiftUI

// MARK: - Action Button
// Vertical icon + label button for prayer actions (Copy, Share, Save)
// Features gold styling with accessibility support

struct ActionButton: View {
    let icon: String
    let label: String

    /// Whether this is a "save" action that should use success haptic
    var isSuccessAction: Bool = false

    let action: () -> Void

    var body: some View {
        Button(action: {
            if isSuccessAction {
                HapticService.shared.success()
            } else {
                HapticService.shared.softTap()
            }
            action()
        }) {
            // swiftlint:disable:next hardcoded_stack_spacing
            VStack(spacing: 6) {  // Tight icon/label spacing
                Image(systemName: icon)
                    .font(Typography.Icon.lg)
                Text(label)
                    .font(Typography.Editorial.label)
            }
            .foregroundColor(Color.accentBronze)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color.surfaceRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .stroke(Color.accentBronze.opacity(Theme.Opacity.lightMedium), lineWidth: Theme.Stroke.hairline)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint("Double tap to \(label.lowercased()) this prayer")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview("Action Buttons") {
    ZStack {
        Color.surfaceParchment.ignoresSafeArea()

        HStack(spacing: Theme.Spacing.lg) {
            ActionButton(icon: "doc.on.doc", label: "Copy") {}
            ActionButton(icon: "square.and.arrow.up", label: "Share") {}
            ActionButton(icon: "bookmark", label: "Save", isSuccessAction: true) {}
        }
        .padding()
    }
}

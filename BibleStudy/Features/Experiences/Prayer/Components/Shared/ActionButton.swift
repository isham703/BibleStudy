import SwiftUI

// MARK: - Action Button
// Vertical icon + label button for prayer actions (Copy, Share, Save)
// Portico-style blue accents with accessibility support

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
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(Typography.Icon.md)
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(label)
                    .font(Typography.Command.caption.weight(.medium))
                    .foregroundStyle(Color("AppTextPrimary"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .stroke(Color.appDivider, lineWidth: Theme.Stroke.control)
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
        Color("AppBackground").ignoresSafeArea()

        HStack(spacing: Theme.Spacing.lg) {
            ActionButton(icon: "doc.on.doc", label: "Copy") {}
            ActionButton(icon: "square.and.arrow.up", label: "Share") {}
            ActionButton(icon: "bookmark", label: "Save", isSuccessAction: true) {}
        }
        .padding()
    }
}

import SwiftUI

// MARK: - Sermon Atrium Action Button
// Reusable action button with icon and label

struct SermonAtriumActionButton: View {
    let icon: String
    let label: String
    var tint: Color?  // Optional custom tint for icon and label
    let delay: Double
    let isAwakened: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(Typography.Icon.md)
                    .foregroundStyle(tint ?? Color("AppTextSecondary"))

                Text(label)
                    .font(Typography.Command.caption)
                    .foregroundStyle(tint ?? Color("TertiaryText"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color("AppSurface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
            )
        }
        .accessibilityLabel(label)
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 10)
        .animation(Theme.Animation.slowFade.delay(delay), value: isAwakened)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: Theme.Spacing.md) {
        SermonAtriumActionButton(
            icon: "square.and.arrow.up",
            label: "Share",
            delay: 0.1,
            isAwakened: true
        ) {
            print("Share tapped")
        }

        SermonAtriumActionButton(
            icon: "doc.on.doc",
            label: "Copy",
            delay: 0.2,
            isAwakened: true
        ) {
            print("Copy tapped")
        }

        SermonAtriumActionButton(
            icon: "plus",
            label: "New",
            delay: 0.3,
            isAwakened: true
        ) {
            print("New tapped")
        }
    }
    .padding()
    .background(Color("AppBackground"))
}

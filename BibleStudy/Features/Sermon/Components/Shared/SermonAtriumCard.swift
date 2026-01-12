import SwiftUI

// MARK: - Sermon Atrium Card
// Reusable card container with staggered entrance animation

struct SermonAtriumCard<Content: View>: View {
    let delay: Double
    let isAwakened: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color("AppSurface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
            )
            .opacity(isAwakened ? 1 : 0)
            .offset(y: isAwakened ? 0 : 10)
            .animation(Theme.Animation.slowFade.delay(delay), value: isAwakened)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Theme.Spacing.lg) {
        SermonAtriumCard(delay: 0.1, isAwakened: true) {
            Text("Card Content")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextPrimary"))
        }

        SermonAtriumCard(delay: 0.2, isAwakened: true) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Another Card")
                    .font(Typography.Command.body.weight(.medium))
                    .foregroundStyle(Color("AppTextPrimary"))
                Text("With more content")
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
    }
    .padding()
    .background(Color("AppBackground"))
}

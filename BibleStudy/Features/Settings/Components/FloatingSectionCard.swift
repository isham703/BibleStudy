import SwiftUI

// MARK: - Floating Section Card
/// A styled card container for settings sections with gradient border and shadow.
/// Part of the Floating Sanctuary Settings design system.

struct FloatingSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let accentColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(accentColor)

                Text(title)
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(accentColor)
                    .textCase(.uppercase)
                    // swiftlint:disable:next hardcoded_tracking
                    .kerning(1.5)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Content card
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.surfaceBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(Theme.Opacity.secondary),
                                accentColor.opacity(Theme.Opacity.faint),
                                accentColor.opacity(Theme.Opacity.secondary)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        // swiftlint:disable:next hardcoded_line_width
                        lineWidth: 0.5
                    )
            }
            // swiftlint:disable:next hardcoded_shadow_params
            .shadow(color: accentColor.opacity(Theme.Opacity.faint), radius: 20, y: 8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#if DEBUG
struct FloatingSectionCard_Previews: PreviewProvider {
    static var previews: some View {
        FloatingSectionCard(
            title: "AI & Insights",
            icon: "sparkles",
            accentColor: Color.accentIndigo
        ) {
            Text("Sample content")
                .padding()
        }
        .padding()
        .background(Color.appBackground)
    }
}
#endif

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
                    .font(Typography.Scripture.footnote.weight(.medium))
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
                    .fill(Color("AppSurface"))
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(Theme.Opacity.textSecondary),
                                accentColor.opacity(Theme.Opacity.subtle),
                                accentColor.opacity(Theme.Opacity.textSecondary)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        // swiftlint:disable:next hardcoded_line_width
                        lineWidth: 0.5
                    )
            }
            // swiftlint:disable:next hardcoded_shadow_params
            .shadow(color: accentColor.opacity(Theme.Opacity.subtle), radius: 20, y: 8)
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
            accentColor: Color("AppAccentAction")
        ) {
            Text("Sample content")
                .padding()
        }
        .padding()
        .background(Color.appBackground)
    }
}
#endif

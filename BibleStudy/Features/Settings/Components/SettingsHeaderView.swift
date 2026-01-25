import SwiftUI

// MARK: - Settings Header View
// Design Rationale: FLAT design - no glow/blur per design system.
// The gradient stroke border provides visual interest while maintaining
// flat design principles. No shadows, no radial glows.
// Stoic-Existential Renaissance design

struct SettingsHeaderView: View {
    let displayName: String?
    let tierDisplayName: String

    // MARK: - Computed Properties

    /// Generate user initials from display name
    private var userInitials: String {
        guard let name = displayName, !name.isEmpty else {
            return "G"
        }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = String(components[0].prefix(1))
            let last = String(components[1].prefix(1))
            return first + last
        } else {
            return String(name.prefix(2))
        }
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Profile avatar - FLAT design, no radial glow
            // Uses gradient stroke border for visual interest
            avatarView

            // Name and tier badge
            VStack(spacing: Theme.Spacing.xs) {
                Text(displayName ?? "Guest")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                // Tier badge - flat capsule, no shadow
                Text(tierDisplayName)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppAccentAction"))
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground))
                    )
            }
        }
        .padding(.bottom, Theme.Spacing.lg)
    }

    // MARK: - Avatar View
    // Design Rationale: FLAT design - no glow/blur per design system.
    // Uses gradient stroke border only for visual interest.

    private var avatarView: some View {
        Circle()
            .fill(Color.appSurface)
            .frame(width: 80, height: 80)
            .overlay {
                Text(userInitials)
                    .font(Typography.Scripture.title)
                    .foregroundStyle(Color("AppAccentAction"))
            }
            .overlay {
                // Gradient stroke - the ONE decorative element
                // This is acceptable because it's a stroke, not a glow
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color("AppAccentAction").opacity(Theme.Opacity.textPrimary),
                                Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: Theme.Stroke.control
                    )
            }
    }
}

// MARK: - Preview

#Preview("Settings Header") {
    VStack {
        SettingsHeaderView(
            displayName: "John Doe",
            tierDisplayName: "Premium"
        )

        SettingsHeaderView(
            displayName: nil,
            tierDisplayName: "Free"
        )
    }
    .padding()
    .background(Color.appBackground)
}

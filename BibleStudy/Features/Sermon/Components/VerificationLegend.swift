import SwiftUI

// MARK: - Verification Legend
// Help overlay explaining verification status indicators

struct VerificationLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            legendItem(
                icon: "checkmark.seal.fill",
                color: Color("AccentBronze"),
                title: "Verified",
                description: "Cross-reference found in our curated database"
            )

            Divider()
                .background(Color.appTextSecondary.opacity(Theme.Opacity.selectionBackground))

            legendItem(
                icon: "checkmark.seal",
                color: Color("AccentBronze").opacity(Theme.Opacity.overlay),
                title: "Valid Reference",
                description: "Valid verse, but connection not in database"
            )

            Divider()
                .background(Color.appTextSecondary.opacity(Theme.Opacity.selectionBackground))

            legendItem(
                icon: "sparkle",
                color: Color.appTextSecondary.opacity(Theme.Opacity.pressed),
                title: "AI-Suggested",
                description: "Suggested by AI, not verified by database"
            )
        }
        .padding(Theme.Spacing.lg)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .stroke(Color("AccentBronze").opacity(Theme.Opacity.selectionBackground), lineWidth: Theme.Stroke.hairline)
        )
    }

    private func legendItem(
        icon: String,
        color: Color,
        title: String,
        description: String
    ) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(Typography.Icon.md)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color.appTextPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Legend Button

struct VerificationLegendButton: View {
    @State private var showLegend = false

    var body: some View {
        Button {
            HapticService.shared.lightTap()
            showLegend = true
        } label: {
            Image(systemName: "questionmark.circle")
                .font(Typography.Icon.sm)
                .foregroundStyle(Color.appTextSecondary)
        }
        .popover(isPresented: $showLegend) {
            VerificationLegend()
                .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - Preview

#Preview("Legend") {
    VStack(spacing: Theme.Spacing.xl) {
        VerificationLegend()

        VerificationLegendButton()
    }
    .padding()
    .background(Color("AppBackground"))
}

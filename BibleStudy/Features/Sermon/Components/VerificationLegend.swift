import SwiftUI

// MARK: - Verification Legend
// Help overlay explaining verification status indicators

struct VerificationLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            legendItem(
                icon: "checkmark.seal.fill",
                color: Color.accentBronze,
                title: "Verified",
                description: "Cross-reference found in our curated database"
            )

            Divider()
                .background(Color.textSecondary.opacity(Theme.Opacity.lightMedium))

            legendItem(
                icon: "checkmark.seal",
                color: Color(hex: "6B5844").opacity(Theme.Opacity.overlay),
                title: "Valid Reference",
                description: "Valid verse, but connection not in database"
            )

            Divider()
                .background(Color.textSecondary.opacity(Theme.Opacity.lightMedium))

            legendItem(
                icon: "sparkle",
                color: Color.textSecondary.opacity(Theme.Opacity.strong),
                title: "AI-Suggested",
                description: "Suggested by AI, not verified by database"
            )
        }
        .padding(Theme.Spacing.lg)
        .background(Color.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .stroke(Color.accentBronze.opacity(Theme.Opacity.lightMedium), lineWidth: Theme.Stroke.hairline)
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
                    .foregroundStyle(Color.textPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
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
                .foregroundStyle(Color.textSecondary)
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
    .background(Color.surfaceParchment)
}

import SwiftUI

// MARK: - Crisis Help Modal
// Displayed when self-harm or crisis content is detected
// Provides compassionate support with crisis helpline resources

struct CrisisHelpModal: View {
    var onDismiss: () -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 24) {
            // Heart icon
            Image(systemName: "heart.fill")
                .font(.system(size: 48))
                .foregroundStyle(DeepPrayerColors.roseAccent)
                .padding(.top, 8)

            // Caring message
            VStack(spacing: 12) {
                Text("We care about you")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(DeepPrayerColors.primaryText)

                Text("If you're struggling, please reach out to someone who can help. You don't have to face this alone.")
                    .font(.system(size: 16))
                    .foregroundStyle(DeepPrayerColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            // Helpline buttons
            VStack(spacing: 12) {
                helplineButton(
                    icon: "phone.fill",
                    title: "Call 988",
                    subtitle: "Suicide & Crisis Lifeline",
                    action: { openURL(URL(string: "tel:988")!) }
                )

                helplineButton(
                    icon: "message.fill",
                    title: "Text HOME to 741741",
                    subtitle: "Crisis Text Line",
                    action: { openURL(URL(string: "sms:741741&body=HOME")!) }
                )
            }
            .padding(.vertical, 8)

            // Dismiss button
            Button(action: onDismiss) {
                Text("I'm Okay")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DeepPrayerColors.secondaryText)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .stroke(DeepPrayerColors.surfaceBorder, lineWidth: 1)
                    )
            }
            .padding(.bottom, 8)
        }
        .padding(24)
        .background(DeepPrayerColors.sacredNavy)
    }

    // MARK: - Helpline Button

    private func helplineButton(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(DeepPrayerColors.roseAccent)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(DeepPrayerColors.roseHighlight)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DeepPrayerColors.primaryText)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(DeepPrayerColors.tertiaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DeepPrayerColors.tertiaryText)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DeepPrayerColors.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(DeepPrayerColors.surfaceBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Crisis Help Modal") {
    CrisisHelpModal(onDismiss: {})
        .background(DeepPrayerColors.sacredNavy)
}

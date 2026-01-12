import SwiftUI

// MARK: - Crisis Help Modal
// Displayed when self-harm or crisis content is detected
// Provides compassionate support with crisis helpline resources

struct CrisisHelpModal: View {
    var onDismiss: () -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            // Heart icon
            Image(systemName: "heart.fill")
                // swiftlint:disable:next hardcoded_font_system
                .font(Typography.Icon.hero)
                .foregroundStyle(Color("FeedbackError").opacity(0.8))
                .padding(.top, Theme.Spacing.sm)

            // Caring message
            VStack(spacing: Theme.Spacing.md) {
                Text("We care about you")
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Scripture.prompt)
                    .foregroundStyle(Color.appTextPrimary)

                Text("If you're struggling, please reach out to someone who can help. You don't have to face this alone.")
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Command.callout)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.sm)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("We care about you. If you're struggling, please reach out to someone who can help.")

            // Helpline buttons
            VStack(spacing: Theme.Spacing.md) {
                helplineButton(
                    icon: "phone.fill",
                    title: "Call 988",
                    subtitle: "Suicide & Crisis Lifeline",
                    accessibilityHint: "Double tap to call for immediate support",
                    action: {
                        HapticService.shared.mediumTap()
                        openURL(URL(string: "tel:988")!)
                    }
                )

                helplineButton(
                    icon: "message.fill",
                    title: "Text HOME to 741741",
                    subtitle: "Crisis Text Line",
                    accessibilityHint: "Double tap to open text message",
                    action: {
                        HapticService.shared.mediumTap()
                        openURL(URL(string: "sms:741741&body=HOME")!)
                    }
                )
            }
            .padding(.vertical, Theme.Spacing.sm)

            // Dismiss button
            Button(action: {
                HapticService.shared.lightTap()
                onDismiss()
            }) {
                Text("I'm Okay")
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Command.label)
                    .foregroundStyle(Color.appTextSecondary)
                    .padding(.horizontal, Theme.Spacing.xxl)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(
                        Capsule()
                            .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
                    )
            }
            .accessibilityLabel("I'm Okay")
            .accessibilityHint("Double tap to dismiss this support screen")
            .padding(.bottom, Theme.Spacing.sm)
        }
        .padding(Theme.Spacing.xxl)
        .background(Color("AppAccentAction"))
        .onAppear {
            HapticService.shared.warning()
        }
    }

    // MARK: - Helpline Button

    private func helplineButton(
        icon: String,
        title: String,
        subtitle: String,
        accessibilityHint: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.lg) {
                Image(systemName: icon)
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Command.title3)
                    .foregroundStyle(Color("FeedbackError").opacity(0.8))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color("FeedbackError").opacity(0.8).opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        // swiftlint:disable:next hardcoded_font_system
                        .font(Typography.Command.callout.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)

                    Text(subtitle)
                        // swiftlint:disable:next hardcoded_font_system
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.appTextSecondary.opacity(Theme.Opacity.textTertiary))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Icon.sm)
                    .foregroundStyle(Color.appTextSecondary.opacity(Theme.Opacity.textTertiary))
            }
            .padding(Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color.white.opacity(Theme.Opacity.subtle))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityHint(accessibilityHint)
    }
}

// MARK: - Preview

#Preview("Crisis Help Modal") {
    CrisisHelpModal(onDismiss: {})
        .background(Color("AppAccentAction"))
}

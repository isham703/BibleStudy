import SwiftUI

// MARK: - Email Confirmation View
// Shown after successful sign-up to guide user through email confirmation

struct EmailConfirmationView: View {
    let email: String
    let onResend: () async -> Void
    let onChangeEmail: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var secondsRemaining: Int = 0
    @State private var isResending: Bool = false
    @State private var showResendSuccess: Bool = false
    @State private var timer: Timer?

    private let cooldownDuration: Int = 60

    var body: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Spacer()

            // Sacred confirmation icon
            confirmationIcon

            // Title
            Text("Check Your Email")
                .font(Typography.Scripture.title)
                .foregroundStyle(Color("AppTextPrimary"))

            // Email display (masked)
            VStack(spacing: Theme.Spacing.sm) {
                Text("We've sent a confirmation link to:")
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextSecondary"))

                Text(maskedEmail)
                    .font(Typography.Command.body.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
            }

            // Guidance card
            guidanceCard

            Spacer()

            // Action buttons
            VStack(spacing: Theme.Spacing.md) {
                // Resend button with timer
                resendButton

                // Change email button
                Button(action: onChangeEmail) {
                    Text("Use a different email")
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("AppAccentAction"))
                }
                .accessibilityLabel("Change email")
                .accessibilityHint("Go back to enter a different email address")
            }
            .padding(.bottom, Theme.Spacing.xl)
        }
        .padding(Theme.Spacing.lg)
        .background(Color.appBackground)
        .onAppear {
            // Start initial cooldown (user just signed up)
            startCooldown()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Confirmation Icon
    private var confirmationIcon: some View {
        ZStack {
            // Outer glow ring - simplified
            Circle()
                .fill(Color("AccentBronze").opacity(Theme.Opacity.selectionBackground))
                .frame(width: 120, height: 120)
                .blur(radius: 16)

            // Icon circle - simplified to single color
            Circle()
                .fill(Color("AccentBronze"))
                .frame(width: 80, height: 80)

            // Mail icon
            Image(systemName: "envelope.open.fill")
                .font(Typography.Icon.xxl)
                .foregroundStyle(.white)
        }
    }

    // MARK: - Guidance Card
    private var guidanceCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            GuidanceRow(
                icon: "clock",
                text: "The link expires in 24 hours"
            )
            GuidanceRow(
                icon: "tray.full",
                text: "Check your spam or junk folder"
            )
            GuidanceRow(
                icon: "checkmark.circle",
                text: "Click the link to verify your account"
            )
        }
        .padding(Theme.Spacing.lg)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)
        )
    }

    // MARK: - Resend Button
    private var resendButton: some View {
        Button {
            Task {
                await resendEmail()
            }
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                if isResending {
                    ProgressView()
                        .tint(secondsRemaining > 0 ? Color("TertiaryText") : .white)
                } else if secondsRemaining > 0 {
                    // Vespers Hourglass Timer
                    VespersTimerRing(
                        secondsRemaining: secondsRemaining,
                        totalSeconds: cooldownDuration
                    )
                } else if showResendSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Typography.Icon.lg)
                        .foregroundStyle(Color("FeedbackSuccess"))
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(Typography.Icon.md.weight(.medium))
                }

                Text(buttonText)
                    .font(Typography.Command.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(secondsRemaining > 0 ? Color.appSurface : Color("AppAccentAction"))
            .foregroundStyle(secondsRemaining > 0 ? Color("TertiaryText") : .white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(
                        secondsRemaining > 0 ? Color.appDivider : Color.clear,
                        lineWidth: Theme.Stroke.hairline
                    )
            )
        }
        .disabled(secondsRemaining > 0 || isResending)
        .animation(Theme.Animation.settle, value: secondsRemaining)
        .animation(Theme.Animation.settle, value: showResendSuccess)
        .accessibilityLabel("Resend confirmation email")
        .accessibilityHint(secondsRemaining > 0 ? "Wait \(secondsRemaining) seconds" : "Double tap to resend")
    }

    // MARK: - Helpers
    private var maskedEmail: String {
        guard let atIndex = email.firstIndex(of: "@") else { return email }
        let localPart = String(email[..<atIndex])
        let domain = String(email[atIndex...])

        if localPart.count <= 3 {
            return localPart + domain
        }

        let visibleChars = min(3, localPart.count)
        let prefix = String(localPart.prefix(visibleChars))
        let maskedCount = max(0, localPart.count - visibleChars)
        let mask = String(repeating: "•", count: min(maskedCount, 5))

        return prefix + mask + domain
    }

    private var buttonText: String {
        if isResending {
            return "Sending..."
        } else if showResendSuccess {
            return "Email Sent!"
        } else if secondsRemaining > 0 {
            return "Resend in \(secondsRemaining)s"
        } else {
            return "Resend Confirmation Email"
        }
    }

    private func startCooldown() {
        secondsRemaining = cooldownDuration
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            } else {
                timer?.invalidate()
            }
        }
    }

    private func resendEmail() async {
        isResending = true
        showResendSuccess = false

        await onResend()

        isResending = false
        showResendSuccess = true

        // Show success briefly, then start cooldown
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        showResendSuccess = false
        startCooldown()
    }
}

// MARK: - Vespers Timer Ring
// Evokes monastic time-keeping - sand through an hourglass
struct VespersTimerRing: View {
    let secondsRemaining: Int
    let totalSeconds: Int

    @Environment(\.colorScheme) private var colorScheme

    private var progress: CGFloat {
        CGFloat(secondsRemaining) / CGFloat(totalSeconds)
    }

    var body: some View {
        ZStack {
            // Background ring - subtle divider color
            Circle()
                .stroke(Color.appDivider, lineWidth: Theme.Stroke.control)

            // Active ring - simplified to single accent color
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color("AccentBronze"),
                    style: StrokeStyle(lineWidth: Theme.Stroke.control, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            // Inner number using Cinzel-style
            Text("\(secondsRemaining)")
                .font(Typography.Command.caption.weight(.semibold))
                .foregroundStyle(Color("AppTextPrimary"))
                .monospacedDigit()
        }
        .frame(width: 36, height: 36)
        .animation(Theme.Animation.fade, value: secondsRemaining)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Resend timer")
        .accessibilityValue("\(secondsRemaining) seconds remaining")
    }
}

// MARK: - Guidance Row
struct GuidanceRow: View {
    let icon: String
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(Typography.Icon.md.weight(.medium))
                .foregroundStyle(Color("AccentBronze"))
                .frame(width: 24)

            Text(text)
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))

            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    EmailConfirmationView(
        email: "john.doe@example.com",
        onResend: {},
        onChangeEmail: {}
    )
}

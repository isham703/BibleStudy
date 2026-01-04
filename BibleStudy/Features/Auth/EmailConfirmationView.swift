import SwiftUI

// MARK: - Email Confirmation View
// Shown after successful sign-up to guide user through email confirmation

struct EmailConfirmationView: View {
    let email: String
    let onResend: () async -> Void
    let onChangeEmail: () -> Void

    @State private var secondsRemaining: Int = 0
    @State private var isResending: Bool = false
    @State private var showResendSuccess: Bool = false
    @State private var timer: Timer?

    private let cooldownDuration: Int = 60

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            Spacer()

            // Sacred confirmation icon
            confirmationIcon

            // Title
            Text("Check Your Email")
                .font(Typography.Scripture.title)
                .foregroundStyle(Color.primaryText)

            // Email display (masked)
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("We've sent a confirmation link to:")
                    .font(Typography.UI.warmBody)
                    .foregroundStyle(Color.secondaryText)

                Text(maskedEmail)
                    .font(Typography.UI.bodyBold)
                    .foregroundStyle(Color.primaryText)
            }

            // Guidance card
            guidanceCard

            Spacer()

            // Action buttons
            VStack(spacing: AppTheme.Spacing.md) {
                // Resend button with timer
                resendButton

                // Change email button
                Button(action: onChangeEmail) {
                    Text("Use a different email")
                        .font(Typography.UI.body)
                        .foregroundStyle(Color.scholarAccent)
                }
            }
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .padding(AppTheme.Spacing.lg)
        .background(Color.primaryBackground)
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
            // Outer glow ring
            Circle()
                .fill(Color.Glow.indigoAmbient)
                .frame(width: 120, height: 120)
                .blur(radius: AppTheme.Blur.heavy)

            // Icon circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.divineGold,
                            Color.burnishedGold
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)

            // Mail icon
            Image(systemName: "envelope.open.fill")
                .font(.system(size: Typography.Scale.xxl, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Guidance Card
    private var guidanceCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
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
        .padding(AppTheme.Spacing.lg)
        .background(Color.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .stroke(Color.divider, lineWidth: AppTheme.Border.thin)
        )
    }

    // MARK: - Resend Button
    private var resendButton: some View {
        Button {
            Task {
                await resendEmail()
            }
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                if isResending {
                    ProgressView()
                        .tint(secondsRemaining > 0 ? Color.tertiaryText : .white)
                } else if secondsRemaining > 0 {
                    // Vespers Hourglass Timer
                    VespersTimerRing(
                        secondsRemaining: secondsRemaining,
                        totalSeconds: cooldownDuration
                    )
                } else if showResendSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Typography.UI.iconLg)
                        .foregroundStyle(Color.malachite)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(Typography.UI.iconMd.weight(.medium))
                }

                Text(buttonText)
                    .font(Typography.UI.bodyBold)
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.md)
            .background(secondsRemaining > 0 ? Color.secondaryBackground : Color.scholarAccent)
            .foregroundStyle(secondsRemaining > 0 ? Color.tertiaryText : .white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                    .stroke(
                        secondsRemaining > 0 ? Color.divider : Color.clear,
                        lineWidth: AppTheme.Border.thin
                    )
            )
        }
        .disabled(secondsRemaining > 0 || isResending)
        .animation(AppTheme.Animation.sacredSpring, value: secondsRemaining)
        .animation(AppTheme.Animation.sacredSpring, value: showResendSuccess)
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

    private var progress: CGFloat {
        CGFloat(secondsRemaining) / CGFloat(totalSeconds)
    }

    var body: some View {
        ZStack {
            // Background ring - aged parchment color
            Circle()
                .stroke(Color.monasteryStone, lineWidth: AppTheme.Border.thick)

            // Active ring - gold gradient with glow
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.illuminatedGold,
                            Color.divineGold,
                            Color.burnishedGold
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: AppTheme.Border.thick, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(AppTheme.Shadow.small)

            // Inner number using Cinzel-style
            Text("\(secondsRemaining)")
                .font(Typography.UI.caption1.weight(.semibold))
                .foregroundStyle(Color.primaryText)
                .monospacedDigit()
        }
        .frame(width: 36, height: 36)
        .animation(AppTheme.Animation.quick, value: secondsRemaining)
    }
}

// MARK: - Guidance Row
struct GuidanceRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(Typography.UI.iconMd.weight(.medium))
                .foregroundStyle(Color.divineGold)
                .frame(width: AppTheme.IconContainer.small)

            Text(text)
                .font(Typography.UI.body)
                .foregroundStyle(Color.secondaryText)

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

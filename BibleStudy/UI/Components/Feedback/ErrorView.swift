import SwiftUI

// MARK: - Error View
// Displays error states with retry option

struct ErrorView: View {
    let error: Error
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(Typography.Command.largeTitle)
                .foregroundStyle(Color("FeedbackWarning"))

            VStack(spacing: Theme.Spacing.sm) {
                Text("Something went wrong")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text(error.localizedDescription)
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
            }

            if let retryAction = retryAction {
                Button("Try Again", action: retryAction)
                    .buttonStyle(.primary)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.opacity(Theme.Opacity.textPrimary))
    }
}

// MARK: - Inline Error View
struct InlineErrorView: View {
    let message: String
    var retryAction: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(Color("FeedbackError"))

            Text(message)
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))

            Spacer()

            if let retryAction = retryAction {
                Button("Retry", action: retryAction)
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color("AppAccentAction"))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Color("FeedbackError").opacity(Theme.Opacity.subtle))
        )
    }
}

// MARK: - AI Error View
struct AIErrorView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "sparkles.slash")
                .font(Typography.Command.title1)
                .foregroundStyle(Color("FeedbackWarning"))

            Text("AI Unavailable")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color("AppTextPrimary"))

            Text(message)
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)

            if let retryAction = retryAction {
                Button("Try Again", action: retryAction)
                    .buttonStyle(.secondary)
            }
        }
        .padding(Theme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface"))
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: Theme.Spacing.xxl) {
        ErrorView(
            error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not load chapter data"])
        ) {
            print("Retry tapped")
        }
        .frame(height: 300)

        InlineErrorView(message: "Failed to load cross-references") {
            print("Retry tapped")
        }
        .padding()

        AIErrorView(message: "Could not connect to AI service. Please check your internet connection.") {
            print("Retry tapped")
        }
    }
    .background(Color.appBackground)
}

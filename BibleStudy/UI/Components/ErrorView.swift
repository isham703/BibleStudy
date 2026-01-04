import SwiftUI

// MARK: - Error View
// Displays error states with retry option

struct ErrorView: View {
    let error: Error
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(Typography.UI.largeTitle)
                .foregroundStyle(Color.warning)

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Something went wrong")
                    .font(Typography.Display.headline)
                    .foregroundStyle(Color.primaryText)

                Text(error.localizedDescription)
                    .font(Typography.UI.warmSubheadline)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
            }

            if let retryAction = retryAction {
                Button("Try Again", action: retryAction)
                    .buttonStyle(.primary)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.opacity(AppTheme.Opacity.nearOpaque))
    }
}

// MARK: - Inline Error View
struct InlineErrorView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(Color.error)

            Text(message)
                .font(Typography.UI.warmSubheadline)
                .foregroundStyle(Color.secondaryText)

            Spacer()

            if let retryAction = retryAction {
                Button("Retry", action: retryAction)
                    .font(Typography.UI.warmSubheadline)
                    .foregroundStyle(Color.accentGold)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(Color.error.opacity(AppTheme.Opacity.subtle))
        )
    }
}

// MARK: - AI Error View
struct AIErrorView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "sparkles.slash")
                .font(Typography.UI.title1)
                .foregroundStyle(Color.warning)

            Text("AI Unavailable")
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)

            Text(message)
                .font(Typography.UI.warmSubheadline)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)

            if let retryAction = retryAction {
                Button("Try Again", action: retryAction)
                    .buttonStyle(.secondary)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .fill(Color.surfaceBackground)
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: AppTheme.Spacing.xxxl) {
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

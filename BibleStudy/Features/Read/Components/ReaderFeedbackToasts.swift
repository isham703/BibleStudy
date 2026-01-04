import SwiftUI

// MARK: - Collection Feedback

enum CollectionFeedback: Equatable {
    case added(reference: String, collectionName: String)
    case alreadyExists(reference: String, collectionName: String)
    case error(message: String)

    var message: String {
        switch self {
        case .added(let reference, let collectionName):
            return "\(reference) added to \(collectionName)"
        case .alreadyExists(let reference, let collectionName):
            return "\(reference) is already in \(collectionName)"
        case .error(let message):
            return message
        }
    }

    var icon: String {
        switch self {
        case .added: return "checkmark.circle.fill"
        case .alreadyExists: return "info.circle.fill"
        case .error: return "exclamationmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .added: return .success
        case .alreadyExists: return .info
        case .error: return .error
        }
    }
}

// MARK: - Collection Feedback Toast

struct CollectionFeedbackToast: View {
    let feedback: CollectionFeedback

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: feedback.icon)
                .foregroundStyle(feedback.color)

            Text(feedback.message)
                .font(Typography.UI.subheadline)
                .foregroundStyle(Color.primaryText)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            Capsule()
                .fill(Color.elevatedBackground)
                .shadow(color: .black.opacity(AppTheme.Opacity.light), radius: 8, y: 4)
        )
        .padding(.top, AppTheme.Spacing.xxxl + AppTheme.Spacing.md)
    }
}

// MARK: - Memorization Feedback

enum MemorizationFeedback: Equatable {
    case added(reference: String)
    case alreadyExists(reference: String)
    case error(message: String)

    var message: String {
        switch self {
        case .added(let reference):
            return "\(reference) added to memorization queue"
        case .alreadyExists(let reference):
            return "\(reference) is already in your queue"
        case .error(let message):
            return message
        }
    }

    var icon: String {
        switch self {
        case .added: return "checkmark.circle.fill"
        case .alreadyExists: return "info.circle.fill"
        case .error: return "exclamationmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .added: return .success
        case .alreadyExists: return .info
        case .error: return .error
        }
    }
}

// MARK: - Memorization Feedback Toast

struct MemorizationFeedbackToast: View {
    let feedback: MemorizationFeedback

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: feedback.icon)
                .foregroundStyle(feedback.color)

            Text(feedback.message)
                .font(Typography.UI.subheadline)
                .foregroundStyle(Color.primaryText)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            Capsule()
                .fill(Color.elevatedBackground)
                .shadow(color: .black.opacity(AppTheme.Opacity.light), radius: 8, y: 4)
        )
        .padding(.top, AppTheme.Spacing.xxxl + AppTheme.Spacing.md)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview("Collection Feedback - Added") {
    CollectionFeedbackToast(feedback: .added(reference: "John 3:16", collectionName: "Favorites"))
}

#Preview("Memorization Feedback - Added") {
    MemorizationFeedbackToast(feedback: .added(reference: "Psalm 23:1"))
}

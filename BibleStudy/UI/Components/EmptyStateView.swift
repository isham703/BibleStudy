import SwiftUI

// MARK: - Empty State View
// Displays when there's no content to show
// Now with animated "lines & connections" illustrations

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?
    var animation: EmptyStateAnimationType?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Animated illustration or fallback icon
            if let animationType = animation {
                animationType.view
                    .frame(height: 120)
                    .frame(maxWidth: 200)
            } else {
                Image(systemName: icon)
                    .font(Typography.UI.largeTitle)
                    .foregroundStyle(Color.tertiaryText)
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                Text(title)
                    .font(Typography.Display.headline)
                    .foregroundStyle(Color.primaryText)

                Text(message)
                    .font(Typography.UI.warmSubheadline)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.primary)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State Animation Types
enum EmptyStateAnimationType {
    case noHighlights
    case noNotes
    case noCrossRefs
    case noTopics
    case noPlans
    case noMessages
    case allCaughtUp
    case noVersesToMemorize
    case noSearchResults
    case noBookmarks
    case noHistory

    @ViewBuilder
    var view: some View {
        switch self {
        case .noHighlights:
            NoHighlightsAnimation()
        case .noNotes:
            NoNotesAnimation()
        case .noCrossRefs:
            NoCrossRefsAnimation()
        case .noTopics:
            NoTopicsAnimation()
        case .noPlans:
            NoPlansAnimation()
        case .noMessages:
            NoMessagesAnimation()
        case .allCaughtUp:
            AllCaughtUpAnimation()
        case .noVersesToMemorize:
            NoVersesToMemorizeAnimation()
        case .noSearchResults:
            NoSearchResultsAnimation()
        case .noBookmarks:
            NoBookmarksAnimation()
        case .noHistory:
            NoHistoryAnimation()
        }
    }
}

// MARK: - Preset Empty States
extension EmptyStateView {
    static var noHighlights: EmptyStateView {
        EmptyStateView(
            icon: "highlighter",
            title: "No Highlights",
            message: "Select verses and tap Highlight to save them here.",
            animation: .noHighlights
        )
    }

    static var noNotes: EmptyStateView {
        EmptyStateView(
            icon: "note.text",
            title: "No Notes",
            message: "Select verses and tap Note to add your thoughts.",
            animation: .noNotes
        )
    }

    static var noCrossRefs: EmptyStateView {
        EmptyStateView(
            icon: "arrow.triangle.branch",
            title: "No Cross-References",
            message: "Cross-references for this passage will appear here.",
            animation: .noCrossRefs
        )
    }

    static var noTopics: EmptyStateView {
        EmptyStateView(
            icon: "tag",
            title: "No Topics Found",
            message: "Try searching for a different topic.",
            animation: .noTopics
        )
    }

    static var noPlans: EmptyStateView {
        EmptyStateView(
            icon: "calendar",
            title: "No Reading Plans",
            message: "Create a reading plan to track your Bible study.",
            animation: .noPlans
        )
    }

    static var noMessages: EmptyStateView {
        EmptyStateView(
            icon: "bubble.left.and.bubble.right",
            title: "Start a Conversation",
            message: "Ask questions about the Bible and get AI-powered answers.",
            animation: .noMessages
        )
    }

    static var allCaughtUp: EmptyStateView {
        EmptyStateView(
            icon: "checkmark.circle",
            title: "All Caught Up!",
            message: "You've reviewed all your verses for now. Great work!",
            animation: .allCaughtUp
        )
    }

    static var noVersesToMemorize: EmptyStateView {
        EmptyStateView(
            icon: "brain.head.profile",
            title: "No Verses to Memorize",
            message: "Add verses to start building your memory pathways.",
            animation: .noVersesToMemorize
        )
    }

    static var noSearchResults: EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "Try different keywords or check your spelling.",
            animation: .noSearchResults
        )
    }

    static var noBookmarks: EmptyStateView {
        EmptyStateView(
            icon: "bookmark",
            title: "No Bookmarks",
            message: "Bookmark verses to quickly return to them later.",
            animation: .noBookmarks
        )
    }

    static var noHistory: EmptyStateView {
        EmptyStateView(
            icon: "clock.arrow.circlepath",
            title: "No Reading History",
            message: "Your recently read passages will appear here.",
            animation: .noHistory
        )
    }
}

// MARK: - Preview
#Preview("Animated Empty States") {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.xxxl) {
            EmptyStateView.noHighlights
            EmptyStateView.noNotes
            EmptyStateView.noCrossRefs
            EmptyStateView.noMessages
            EmptyStateView.allCaughtUp
            EmptyStateView.noSearchResults
            EmptyStateView.noBookmarks
            EmptyStateView.noHistory
        }
    }
    .background(Color.appBackground)
}

#Preview("Empty State with Action") {
    EmptyStateView(
        icon: "book",
        title: "Select a Passage",
        message: "Choose a book and chapter to start reading.",
        actionTitle: "Browse Books"
    ) {
        print("Action tapped")
    }
    .background(Color.appBackground)
}

import SwiftUI
import UIKit

// MARK: - Selection Toolbar
// Action bar that appears when verses are selected

struct SelectionToolbar: View {
    let range: VerseRange
    let onCopy: () -> Void
    let onShare: () -> Void
    let onHighlight: () -> Void
    let onNote: () -> Void
    let onStudy: () -> Void
    let onMemorize: () -> Void
    let onAddToCollection: () -> Void
    let onClear: () -> Void

    @State private var showMoreActions = false

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: AppTheme.Spacing.md) {
                // Copy (Primary action)
                ToolbarButton(
                    icon: AppIcons.Action.copy,
                    label: "Copy",
                    color: .primaryText,
                    action: onCopy
                )

                // Share
                ToolbarButton(
                    icon: AppIcons.Action.share,
                    label: "Share",
                    color: .primaryText,
                    action: onShare
                )

                // Study (consolidated AI insights - single entry point)
                ToolbarButton(
                    icon: AppIcons.Action.study,
                    label: "Study",
                    color: .accentGold,
                    action: onStudy
                )

                // Highlight
                ToolbarButton(
                    icon: AppIcons.Action.highlight,
                    label: "Highlight",
                    color: .accentGold,
                    action: onHighlight
                )

                // Note (promoted from More menu for visibility)
                ToolbarButton(
                    icon: AppIcons.Action.note,
                    label: "Note",
                    color: .accentBlue,
                    action: onNote
                )

                // More actions menu
                Menu {
                    Button {
                        onMemorize()
                    } label: {
                        Label {
                            Text("Memorize")
                        } icon: {
                            Image(AppIcons.Action.memorize)
                                .renderingMode(.template)
                        }
                    }

                    Button {
                        onAddToCollection()
                    } label: {
                        Label {
                            Text("Add to Collection")
                        } icon: {
                            Image(AppIcons.Action.collection)
                                .renderingMode(.template)
                        }
                    }
                } label: {
                    VStack(spacing: AppTheme.Spacing.xxs) {
                        Image(systemName: AppIcons.Action.more)
                            .font(Typography.UI.title3)
                            .foregroundStyle(Color.secondaryText)

                        Text("More")
                            .font(Typography.UI.caption2)
                            .foregroundStyle(Color.secondaryText)
                    }
                    .frame(minWidth: AppTheme.TouchTarget.minimum, minHeight: AppTheme.TouchTarget.minimum)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()

                // Clear Selection
                Button(action: onClear) {
                    Image(systemName: AppIcons.Action.clear)
                        .font(Typography.UI.title2)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(Color.surfaceBackground)
        }
    }
}

// MARK: - Toolbar Button
struct ToolbarButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    /// Whether this icon is a Streamline asset (vs SF Symbol)
    private var isStreamlineIcon: Bool {
        icon.hasPrefix("streamline-")
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.xxs) {
                iconView
                    .foregroundStyle(color)

                Text(label)
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.secondaryText)
            }
            .frame(minWidth: AppTheme.TouchTarget.minimum, minHeight: AppTheme.TouchTarget.minimum)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var iconView: some View {
        if isStreamlineIcon {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)
        } else {
            Image(systemName: icon)
                .font(Typography.UI.title3)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        Spacer()
        SelectionToolbar(
            range: .genesis1_1,
            onCopy: {},
            onShare: {},
            onHighlight: {},
            onNote: {},
            onStudy: {},
            onMemorize: {},
            onAddToCollection: {},
            onClear: {}
        )
    }
    .background(Color.appBackground)
}

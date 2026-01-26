import SwiftUI

// MARK: - Collapsible Insight Card
// Card that shows a limited number of items by default with "Read more" expansion.
// Used for Discussion Questions, Reflection Prompts, and Application Points.
//
// Behavior:
// - Shows first 5 items by default
// - "Read more (X more)" button expands to show all items
// - Respects reduce motion accessibility setting

struct CollapsibleInsightCard<Item: Identifiable, Content: View>: View {
    // MARK: - Properties

    let icon: String
    let iconColor: Color
    let title: String
    let items: [Item]
    let delay: Double
    let isAwakened: Bool
    @ViewBuilder let itemView: (Item, Int) -> Content

    @State private var isExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Constants

    private let defaultVisibleCount = 5

    // MARK: - Computed Properties

    private var visibleItems: [Item] {
        isExpanded ? items : Array(items.prefix(defaultVisibleCount))
    }

    private var remainingCount: Int {
        max(0, items.count - defaultVisibleCount)
    }

    private var shouldShowExpandButton: Bool {
        items.count > defaultVisibleCount && !isExpanded
    }

    // MARK: - Body

    var body: some View {
        SermonAtriumCard(delay: delay, isAwakened: isAwakened) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Header
                HStack {
                    Image(systemName: icon)
                        .font(Typography.Icon.md)
                        .foregroundStyle(iconColor)

                    Text(title)
                        .font(Typography.Command.body.weight(.medium))
                        .foregroundStyle(Color("AppTextPrimary"))

                    Spacer()

                    if isExpanded {
                        collapseButton
                    }
                }
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("\(title) section")

                // Items
                ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                    itemView(item, index)
                }

                // Expand button
                if shouldShowExpandButton {
                    expandButton
                }
            }
        }
    }

    // MARK: - Expand Button

    private var expandButton: some View {
        Button {
            withAnimation(reduceMotion ? nil : Theme.Animation.settle) {
                isExpanded = true
            }
        } label: {
            Text("Read more (\(remainingCount) more)")
                .font(Typography.Command.label)
                .foregroundStyle(iconColor)
        }
        .accessibilityLabel("Show \(remainingCount) more items")
    }

    // MARK: - Collapse Button

    private var collapseButton: some View {
        Button {
            withAnimation(reduceMotion ? nil : Theme.Animation.settle) {
                isExpanded = false
            }
        } label: {
            Text("Show less")
                .font(Typography.Command.meta)
                .foregroundStyle(Color("TertiaryText"))
        }
        .accessibilityLabel("Collapse to show fewer items")
    }
}

// MARK: - Indexed String Wrapper
// Used to make string arrays work with CollapsibleInsightCard

struct IndexedString: Identifiable {
    let id: Int
    let value: String

    init(_ index: Int, _ value: String) {
        self.id = index
        self.value = value
    }
}

extension Array where Element == String {
    /// Convert to indexed array for use with CollapsibleInsightCard
    var indexed: [IndexedString] {
        enumerated().map { IndexedString($0.offset, $0.element) }
    }
}

// MARK: - Preview Helper

private struct PreviewItem: Identifiable {
    let id = UUID()
    let text: String
}

#Preview {
    ScrollView {
        VStack(spacing: Theme.Spacing.lg) {
            CollapsibleInsightCard(
                icon: "bubble.left.and.bubble.right",
                iconColor: Color("FeedbackInfo"),
                title: "Discussion Questions",
                items: (1...8).map { PreviewItem(text: "Question \($0): What does this mean?") },
                delay: 0.4,
                isAwakened: true
            ) { item, index in
                Text("\(index + 1). \(item.text)")
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .padding(.vertical, Theme.Spacing.xs)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
    .background(Color("AppBackground"))
}

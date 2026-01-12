import SwiftUI

// MARK: - Timeline View
// Horizontal scrolling timeline for story segments

struct TimelineView: View {
    let segments: [StorySegment]
    let currentIndex: Int
    let completedIndices: Set<Int>
    let onSegmentTap: (Int) -> Void

    @Namespace private var timelineNamespace

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                        HStack(spacing: 0) {
                            // Connection line (before node, except for first)
                            if index > 0 {
                                TimelineConnector(
                                    isCompleted: completedIndices.contains(index - 1)
                                )
                            }

                            // Timeline node
                            TimelineNodeView(
                                segment: segment,
                                index: index,
                                state: nodeState(for: index),
                                onTap: { onSegmentTap(index) }
                            )
                            .id(index)

                            // Connection line (after node, except for last)
                            if index < segments.count - 1 {
                                TimelineConnector(
                                    isCompleted: completedIndices.contains(index)
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
            }
            .onChange(of: currentIndex) { _, newIndex in
                withAnimation(Theme.Animation.settle) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
            .onAppear {
                proxy.scrollTo(currentIndex, anchor: .center)
            }
        }
    }

    private func nodeState(for index: Int) -> TimelineNodeState {
        if index == currentIndex {
            return .current
        } else if completedIndices.contains(index) {
            return .completed
        } else {
            return .upcoming
        }
    }
}

// MARK: - Timeline Node State
enum TimelineNodeState {
    case upcoming
    case current
    case completed

    func circleColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .upcoming: return Color("AppSurface")
        case .current: return Color("AppAccentAction")
        case .completed: return Color("FeedbackSuccess")
        }
    }

    func borderColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .upcoming: return Color("AppDivider")
        case .current: return Color("AppAccentAction")
        case .completed: return Color("FeedbackSuccess")
        }
    }

    func textColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .upcoming: return Color("TertiaryText")
        case .current: return Color("AppTextPrimary")
        case .completed: return Color("AppTextSecondary")
        }
    }

    func iconColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .upcoming: return Color("TertiaryText")
        case .current: return .white
        case .completed: return .white
        }
    }
}

// MARK: - Timeline Connector
struct TimelineConnector: View {
    let isCompleted: Bool

    var body: some View {
        Rectangle()
            .fill(isCompleted ? Color("FeedbackSuccess") : Color("AppDivider"))
            .frame(width: 24, height: 2)
    }
}

// MARK: - Preview
#Preview {
    VStack {
        TimelineView(
            segments: [
                StorySegment(
                    storyId: UUID(),
                    order: 1,
                    title: "Day One",
                    content: "Sample",
                    timelineLabel: "Day 1"
                ),
                StorySegment(
                    storyId: UUID(),
                    order: 2,
                    title: "Day Two",
                    content: "Sample",
                    timelineLabel: "Day 2"
                ),
                StorySegment(
                    storyId: UUID(),
                    order: 3,
                    title: "Day Three",
                    content: "Sample",
                    timelineLabel: "Day 3"
                ),
                StorySegment(
                    storyId: UUID(),
                    order: 4,
                    title: "Day Four",
                    content: "Sample",
                    timelineLabel: "Day 4"
                )
            ],
            currentIndex: 1,
            completedIndices: [0],
            onSegmentTap: { _ in }
        )
        .background(Color.appBackground)
    }
}

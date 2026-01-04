import SwiftUI

// MARK: - Timeline Node View
// Individual node in the story timeline

struct TimelineNodeView: View {
    let segment: StorySegment
    let index: Int
    let state: TimelineNodeState
    let onTap: () -> Void

    private let nodeSize: CGFloat = 40

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppTheme.Spacing.sm) {
                // Timeline label (e.g., "Day 1")
                if let label = segment.timelineLabel {
                    Text(label)
                        .font(Typography.UI.caption2)
                        .foregroundStyle(state.textColor)
                        .lineLimit(1)
                }

                // Node circle
                ZStack {
                    Circle()
                        .fill(state.circleColor)
                        .frame(width: nodeSize, height: nodeSize)

                    Circle()
                        .stroke(state.borderColor, lineWidth: AppTheme.Border.regular)
                        .frame(width: nodeSize, height: nodeSize)

                    // Icon or number
                    Group {
                        switch state {
                        case .completed:
                            Image(systemName: "checkmark")
                                .font(Typography.UI.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(state.iconColor)
                                .transition(.scale.combined(with: .opacity))
                        case .current:
                            if let mood = segment.mood {
                                Image(systemName: mood.icon)
                                    .font(Typography.UI.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(state.iconColor)
                            } else {
                                Text("\(index + 1)")
                                    .font(Typography.UI.caption1Bold.monospacedDigit())
                                    .foregroundStyle(state.iconColor)
                            }
                        case .upcoming:
                            Text("\(index + 1)")
                                .font(Typography.UI.caption1.monospacedDigit())
                                .foregroundStyle(state.iconColor)
                        }
                    }
                }
                .shadow(state == .current ? AppTheme.Shadow.small : ShadowStyle(color: .clear, radius: 0, x: 0, y: 0))

                // Segment title
                Text(segment.title)
                    .font(Typography.UI.caption1)
                    .foregroundStyle(state.textColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
        .animation(AppTheme.Animation.spring, value: state)
    }
}

// MARK: - Preview
#Preview {
    HStack(spacing: AppTheme.Spacing.xl) {
        TimelineNodeView(
            segment: StorySegment(
                storyId: UUID(),
                order: 1,
                title: "In the Beginning",
                content: "Sample",
                timelineLabel: "Day 1",
                mood: .peaceful
            ),
            index: 0,
            state: .completed,
            onTap: {}
        )

        TimelineNodeView(
            segment: StorySegment(
                storyId: UUID(),
                order: 2,
                title: "Waters Above",
                content: "Sample",
                timelineLabel: "Day 2",
                mood: .dramatic
            ),
            index: 1,
            state: .current,
            onTap: {}
        )

        TimelineNodeView(
            segment: StorySegment(
                storyId: UUID(),
                order: 3,
                title: "Land Appears",
                content: "Sample",
                timelineLabel: "Day 3"
            ),
            index: 2,
            state: .upcoming,
            onTap: {}
        )
    }
    .padding()
    .background(Color.appBackground)
}

import SwiftUI

// MARK: - Timeline Node View
// Individual node in the story timeline

struct TimelineNodeView: View {
    let segment: StorySegment
    let index: Int
    let state: TimelineNodeState
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    private let nodeSize: CGFloat = 40

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Theme.Spacing.sm) {
                // Timeline label (e.g., "Day 1")
                if let label = segment.timelineLabel {
                    Text(label)
                        .font(Typography.Command.meta)
                        .foregroundStyle(state.textColor(for: colorScheme))
                        .lineLimit(1)
                }

                // Node circle
                ZStack {
                    Circle()
                        .fill(state.circleColor(for: colorScheme))
                        .frame(width: nodeSize, height: nodeSize)

                    Circle()
                        .stroke(state.borderColor(for: colorScheme), lineWidth: Theme.Stroke.control)
                        .frame(width: nodeSize, height: nodeSize)

                    // Icon or number
                    Group {
                        switch state {
                        case .completed:
                            Image(systemName: "checkmark")
                                .font(Typography.Command.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(state.iconColor(for: colorScheme))
                                .transition(.scale.combined(with: .opacity))
                        case .current:
                            if let mood = segment.mood {
                                Image(systemName: mood.icon)
                                    .font(Typography.Command.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(state.iconColor(for: colorScheme))
                            } else {
                                Text("\(index + 1)")
                                    .font(Typography.Command.caption.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(state.iconColor(for: colorScheme))
                            }
                        case .upcoming:
                            Text("\(index + 1)")
                                .font(Typography.Command.caption.monospacedDigit())
                                .foregroundStyle(state.iconColor(for: colorScheme))
                        }
                    }
                }
                .shadow(color: state == .current ? .black.opacity(Theme.Opacity.overlay) : .clear, radius: state == .current ? 4 : 0, x: 0, y: state == .current ? 2 : 0)

                // Segment title
                Text(segment.title)
                    .font(Typography.Command.caption)
                    .foregroundStyle(state.textColor(for: colorScheme))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
        .animation(Theme.Animation.settle, value: state)
    }
}

// MARK: - Preview
#Preview {
    HStack(spacing: Theme.Spacing.xl) {
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

import SwiftUI

// MARK: - Sermon Flow Layout
// Custom layout that wraps items horizontally like a flow/flex layout

struct SermonFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)

        for (index, placement) in result.placements.enumerated() {
            subviews[index].place(
                at: CGPoint(
                    x: bounds.minX + placement.x,
                    y: bounds.minY + placement.y
                ),
                proposal: ProposedViewSize(placement.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, placements: [Placement]) {
        let maxWidth = proposal.width ?? .infinity

        var placements: [Placement] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            placements.append(Placement(x: currentX, y: currentY, size: size))

            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), placements)
    }

    private struct Placement {
        let x: CGFloat
        let y: CGFloat
        let size: CGSize
    }
}

// MARK: - Preview

#Preview {
    SermonFlowLayout(spacing: 8) {
        ForEach(["Short", "Medium Length", "Long Item Here", "Another", "More", "Items"], id: \.self) { item in
            Text(item)
                .font(Typography.Command.label)
                .foregroundStyle(Color("AppAccentAction"))
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.tag)
                        .stroke(Color("AppAccentAction").opacity(0.3), lineWidth: Theme.Stroke.hairline)
                )
        }
    }
    .padding()
    .background(Color("AppBackground"))
}

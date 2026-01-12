import SwiftUI

// MARK: - Inline Citation View
// Scripture citations displayed below message text
// Connected with golden thread visual

struct InlineCitationView: View {
    let citations: [VerseRange]
    let onCitationTap: (VerseRange) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var threadLength: CGFloat = 0
    @State private var pillsVisible: Bool = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Golden thread connection
            goldenThread
                .frame(height: 20)

            // Citation pills
            CitationFlowLayout(spacing: Theme.Spacing.sm) {
                ForEach(citations) { citation in
                    CitationPill(citation: citation) {
                        onCitationTap(citation)
                    }
                    .opacity(pillsVisible ? 1 : 0)
                    .offset(y: pillsVisible ? 0 : 8)
                }
            }
        }
        .onAppear {
            animateAppearance()
        }
    }

    // MARK: - Golden Thread

    private var goldenThread: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let midX = width * 0.15 // Start from left side
                let height = geometry.size.height

                // Vertical line down
                path.move(to: CGPoint(x: midX, y: 0))
                path.addLine(to: CGPoint(x: midX, y: height * 0.6))

                // Small horizontal tick
                path.addLine(to: CGPoint(x: midX + 8, y: height * 0.6))
            }
            .trim(from: 0, to: threadLength)
            .stroke(
                Color("AccentBronze").opacity(Theme.Opacity.textPrimary),
                style: StrokeStyle(
                    lineWidth: Theme.Stroke.hairline,
                    lineCap: .round,
                    dash: [4, 4]
                )
            )

            // Connection node
            Circle()
                .fill(Color("AccentBronze"))
                .frame(width: 4, height: 4)
                .position(x: geometry.size.width * 0.15, y: 0)
                .opacity(threadLength > 0 ? Theme.Opacity.pressed : 0)
        }
    }

    // MARK: - Animation

    private func animateAppearance() {
        if respectsReducedMotion {
            threadLength = 1
            pillsVisible = true
            return
        }

        // Thread draws first
        withAnimation(Theme.Animation.slowFade) {
            threadLength = 1
        }

        // Then pills fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(Theme.Animation.settle) {
                pillsVisible = true
            }
        }
    }
}

// MARK: - Citation Pill

struct CitationPill: View {
    let citation: VerseRange
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "book.closed")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("AccentBronze"))

                Text(citation.shortReference)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AccentBronze"))
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(Color("AccentBronze").opacity(Theme.Opacity.subtle))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color("AccentBronze").opacity(Theme.Opacity.textSecondary), lineWidth: Theme.Stroke.hairline)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel("Go to \(citation.reference)")
        .accessibilityHint("Opens the verse in the Read tab")
    }
}

// MARK: - Flow Layout
// Wrapping horizontal layout for citation pills

private struct CitationFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, containerWidth: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let layout = layout(sizes: sizes, containerWidth: bounds.width)

        for (index, subview) in subviews.enumerated() {
            let position = layout.positions[index]
            subview.place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(sizes: [CGSize], containerWidth: CGFloat) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for size in sizes {
            if currentX + size.width > containerWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentX - spacing)
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

// MARK: - Citation Group
// Container for multiple citations with shared golden thread

struct CitationGroup: View {
    let citations: [VerseRange]
    let onCitationTap: (VerseRange) -> Void

    var body: some View {
        if citations.isEmpty {
            EmptyView()
        } else {
            InlineCitationView(
                citations: citations,
                onCitationTap: onCitationTap
            )
            .padding(.top, Theme.Spacing.xs)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct InlineCitationView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Text("Inline Citations")
                .font(Typography.Command.headline)

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("When Jesus saw the crowds, he went up on a mountainside and sat down. His disciples came to him, and he began to teach them.")
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Color("AppTextPrimary"))

                InlineCitationView(
                    citations: [
                        VerseRange(bookId: 40, chapter: 5, verseStart: 1, verseEnd: 2),
                        VerseRange(bookId: 42, chapter: 6, verse: 20)
                    ],
                    onCitationTap: { _ in }
                )
            }
            .padding()
            .background(Color("AppSurface"))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))

            Text("Single Citation")
                .font(Typography.Command.headline)

            CitationPill(
                citation: VerseRange(bookId: 43, chapter: 3, verse: 16),
                onTap: {}
            )
        }
        .padding()
        .background(Color.appBackground)
    }
}
#endif

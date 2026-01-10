import SwiftUI

// MARK: - Bible Context Menu Overlay
// Context menu overlay for verse selection actions
// Wraps UnifiedContextMenu with Bible-specific actions

struct BibleContextMenuOverlay: View {
    let verseRange: VerseRange
    let selectionBounds: CGRect
    let containerBounds: CGRect
    let safeAreaInsets: EdgeInsets
    let existingHighlightColor: HighlightColor?
    let onCopy: () -> Void
    let onShare: () -> Void
    let onNote: () -> Void
    let onHighlight: (HighlightColor) -> Void
    let onRemoveHighlight: () -> Void
    let onStudy: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        UnifiedContextMenu(
            mode: .actionsFirst,
            verseRange: verseRange,
            selectionBounds: selectionBounds,
            containerBounds: containerBounds,
            safeAreaInsets: safeAreaInsets,
            existingHighlightColor: existingHighlightColor,
            insight: nil,  // Scholar mode: no insight preview
            isInsightLoading: false,
            isLimitReached: false,
            onCopy: onCopy,
            onShare: onShare,
            onNote: onNote,
            onHighlight: onHighlight,
            onRemoveHighlight: onRemoveHighlight,
            onStudy: onStudy,
            onDismiss: onDismiss
        )
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - Preview

#Preview {
    GeometryReader { geo in
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            BibleContextMenuOverlay(
                verseRange: VerseRange(bookId: 43, chapter: 3, verseStart: 16, verseEnd: 16),
                selectionBounds: CGRect(x: 50, y: 200, width: 300, height: 60),
                containerBounds: geo.frame(in: .global),
                safeAreaInsets: geo.safeAreaInsets,
                existingHighlightColor: nil,
                onCopy: { print("Copy") },
                onShare: { print("Share") },
                onNote: { print("Note") },
                onHighlight: { color in print("Highlight: \(color)") },
                onRemoveHighlight: { print("Remove highlight") },
                onStudy: { print("Study") },
                onDismiss: { print("Dismiss") }
            )
        }
    }
}

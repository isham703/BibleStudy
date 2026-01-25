import SwiftUI

// MARK: - Highlight Library Card
// Simple card displaying highlight reference and date
// Tappable to navigate to verse, context menu for delete

struct HighlightLibraryCard: View {
    let highlight: Highlight
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Color indicator strip
            RoundedRectangle(cornerRadius: Theme.Radius.xs)
                .fill(highlight.color.solidColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Reference
                Text(highlight.reference)
                    .font(Typography.Command.subheadline.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))

                // Date
                Text(highlight.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("TertiaryText"))
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
        )
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Theme.Spacing.md) {
        HighlightLibraryCard(
            highlight: Highlight(
                userId: UUID(),
                bookId: 1,
                chapter: 1,
                verseStart: 1,
                verseEnd: 1,
                color: .blue,
                category: .promise
            ),
            onDelete: { print("Delete") }
        )

        HighlightLibraryCard(
            highlight: Highlight(
                userId: UUID(),
                bookId: 43,
                chapter: 3,
                verseStart: 16,
                verseEnd: 16,
                color: .green,
                category: .doctrine
            ),
            onDelete: { print("Delete") }
        )

        HighlightLibraryCard(
            highlight: Highlight(
                userId: UUID(),
                bookId: 19,
                chapter: 23,
                verseStart: 1,
                verseEnd: 6,
                color: .amber,
                category: .none
            ),
            onDelete: { print("Delete") }
        )
    }
    .padding()
    .background(Color("AppBackground"))
}

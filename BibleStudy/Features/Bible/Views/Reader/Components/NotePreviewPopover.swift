import SwiftUI

// MARK: - Note Preview Popover
// Quick preview of a note shown when tapping verse indicator
// Tap "Edit Note" or tap indicator again to open full editor

struct NotePreviewPopover: View {
    let note: Note
    let onEdit: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with template indicator
            header
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.sm)

            // Thin divider
            Rectangle()
                .fill(Color("AppDivider"))
                .frame(height: Theme.Stroke.hairline)

            // Reference (Serif - scripture location)
            Text(note.reference)
                .font(Typography.Scripture.footnote.weight(.semibold))
                .foregroundStyle(Color("AppTextPrimary"))
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.sm)

            // Preview content (Serif - contemplation)
            Text(note.preview)
                .font(Typography.Scripture.footnote)
                .lineSpacing(Typography.Scripture.footnoteLineSpacing)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(4)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.xs)
                .padding(.bottom, Theme.Spacing.md)

            // Thin divider
            Rectangle()
                .fill(Color("AppDivider"))
                .frame(height: Theme.Stroke.hairline)

            // Edit CTA (Sans - command)
            Button { onEdit() } label: {
                HStack {
                    Image(systemName: "pencil")
                        .font(Typography.Icon.sm)
                    Text("Edit Note")
                        .font(Typography.Command.cta)
                }
                .foregroundStyle(Color("AppAccentAction"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
            }
        }
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
        )
        .frame(width: 280)
        // Subtle shadow for popover only (documented exception for floating elements)
        .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 2)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            // Template badge (left-aligned)
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: note.template.icon)
                    .font(Typography.Icon.xxs)
                Text(note.template.displayName.uppercased())
                    .font(Typography.Label.uppercase)
                    .tracking(Typography.Label.tracking)
            }
            .foregroundStyle(note.template.accentColor)

            Spacer()

            // Close button (meets 44pt via contentShape)
            Button { onDismiss() } label: {
                Image(systemName: "xmark")
                    .font(Typography.Icon.xxs.weight(.medium))
                    .foregroundStyle(Color("TertiaryText"))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color("AppSurface")))
            }
            .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color("AppBackground")
            .ignoresSafeArea()

        VStack(spacing: Theme.Spacing.xl) {
            NotePreviewPopover(
                note: Note(
                    id: UUID(),
                    userId: UUID(),
                    bookId: 43,
                    chapter: 3,
                    verseStart: 16,
                    verseEnd: 16,
                    content: "For God so loved the world - this is the heart of the Gospel message. The word 'so' emphasizes the manner and extent of God's love.",
                    template: .observation,
                    linkedNoteIds: []
                ),
                onEdit: {},
                onDismiss: {}
            )

            NotePreviewPopover(
                note: Note(
                    id: UUID(),
                    userId: UUID(),
                    bookId: 1,
                    chapter: 1,
                    verseStart: 1,
                    verseEnd: 3,
                    content: "How does the creation account speak to God's sovereignty? What does 'without form and void' mean in the original Hebrew?",
                    template: .questions,
                    linkedNoteIds: []
                ),
                onEdit: {},
                onDismiss: {}
            )
        }
    }
}

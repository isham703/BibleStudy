import SwiftUI

// MARK: - Note Preview Card
// Individual note display card for NotePreviewSheet
// Shows template badge, reference, and full markdown content
// Designed for horizontal paging in bottom sheet

struct NotePreviewCard: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: template badge
            templateHeader
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.sm)

            // Reference (serif - scripture location)
            Text(note.reference)
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color("AppTextPrimary"))
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.sm)

            // Hairline divider
            Rectangle()
                .fill(Color("AppDivider"))
                .frame(height: Theme.Stroke.hairline)
                .padding(.horizontal, Theme.Spacing.lg)

            // Full content with markdown rendering
            ScrollView {
                MarkdownRenderer(content: note.content)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.md)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("AppSurface"))
    }

    // MARK: - Template Header

    private var templateHeader: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            Image(systemName: note.template.icon)
                .font(Typography.Icon.xxs)

            Text(note.template.displayName.uppercased())
                .font(Typography.Label.uppercase)
                .tracking(Typography.Label.tracking)
        }
        .foregroundStyle(Color("AppAccentAction"))
    }
}

// MARK: - Preview

#Preview("Note Preview Card") {
    NotePreviewCard(
        note: Note(
            userId: UUID(),
            bookId: 1,
            chapter: 1,
            verseStart: 1,
            verseEnd: 3,
            content: """
            ## What I Notice

            - The creation begins with God speaking
            - Light is the first thing created
            - There is a pattern of evening and morning

            ## Key Words

            - **Beginning** (בְּרֵאשִׁית) - First, chief, head
            - **Created** (בָּרָא) - Divine creation from nothing

            ## Questions

            1. Why does God create through speaking?
            2. What is the significance of light being first?
            """,
            template: .observation
        )
    )
    .frame(height: 400)
    .background(Color("AppBackground"))
}

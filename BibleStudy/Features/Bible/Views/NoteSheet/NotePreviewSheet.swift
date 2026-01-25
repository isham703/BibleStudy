import SwiftUI

// MARK: - Note Preview Sheet
// Bottom sheet for previewing notes with horizontal paging
// Shows one note at a time with edge peek for multiple notes
// Follows BibleInsightSheet patterns for consistency

struct NotePreviewSheet: View {
    /// Sheet state management
    @Bindable var state: NotePreviewSheetState

    /// Delete confirmation dialog
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            sheetHeader

            // Hairline divider
            Rectangle()
                .fill(Color("AppDivider"))
                .frame(height: Theme.Stroke.hairline)

            // Content area with paging
            if state.hasMultipleNotes {
                multiNoteContent
            } else {
                singleNoteContent
            }

            // Hairline divider
            Rectangle()
                .fill(Color("AppDivider"))
                .frame(height: Theme.Stroke.hairline)

            // Footer with actions
            sheetFooter
        }
        .background(Color("AppSurface"))
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .confirmationDialog(
            "Delete Note",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { @MainActor in
                    await state.handleDelete()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack {
            // Page indicator (only for multiple notes)
            if state.hasMultipleNotes {
                pageIndicator
            } else {
                Spacer()
            }

            Spacer()

            // Close button
            Button {
                HapticService.shared.lightTap()
                state.onDismiss?()
            } label: {
                Image(systemName: "xmark")
                    .font(Typography.Icon.sm.weight(.medium))
                    .foregroundStyle(Color("TertiaryText"))
                    .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(0..<state.noteCount, id: \.self) { index in
                Circle()
                    .fill(index == state.currentIndex ? Color("AppAccentAction") : Color("AppDivider"))
                    .frame(width: 6, height: 6)
                    .animation(Theme.Animation.settle, value: state.currentIndex)
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            Capsule()
                .fill(Color("AppBackground").opacity(Theme.Opacity.selectionBackground))
        )
    }

    // MARK: - Single Note Content

    private var singleNoteContent: some View {
        Group {
            if let note = state.currentNote {
                NotePreviewCard(note: note)
            }
        }
    }

    // MARK: - Multi-Note Content (Horizontal Paging)
    // Uses TabView with PageTabViewStyle - the professional iOS pattern for paging

    private var multiNoteContent: some View {
        TabView(selection: Binding(
            get: { state.currentIndex },
            set: { newIndex in
                let previousIndex = state.currentIndex
                state.currentIndex = newIndex

                // Haptic feedback on page change
                if newIndex != previousIndex {
                    HapticService.shared.selectionChanged()
                }
            }
        )) {
            ForEach(Array(state.notes.enumerated()), id: \.element.id) { index, note in
                NotePreviewCard(note: note)
                    .padding(.horizontal, Theme.Spacing.md)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never)) // Hide default indicator, we have custom one
    }

    // MARK: - Footer

    private var sheetFooter: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Edit button
            Button {
                HapticService.shared.lightTap()
                state.handleEdit()
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "pencil")
                        .font(Typography.Icon.sm)
                    Text("Edit")
                        .font(Typography.Command.cta)
                }
                .foregroundStyle(Color("AppAccentAction"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground))
                )
            }

            // Delete button
            Button {
                HapticService.shared.warning()
                showDeleteConfirmation = true
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "trash")
                        .font(Typography.Icon.sm)
                    Text("Delete")
                        .font(Typography.Command.cta)
                }
                .foregroundStyle(Color("FeedbackError"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(Color("FeedbackError").opacity(Theme.Opacity.subtle))
                )
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
    }
}

// MARK: - Preview

#Preview("Note Preview Sheet - Single") {
    struct PreviewContainer: View {
        @State private var state = NotePreviewSheetState()

        var body: some View {
            Color.clear
                .sheet(isPresented: .constant(true)) {
                    NotePreviewSheet(state: state)
                }
                .onAppear {
                    state.configure(
                        notes: [
                            Note(
                                userId: UUID(),
                                bookId: 1,
                                chapter: 1,
                                verseStart: 1,
                                verseEnd: 1,
                                content: "This is a test note with some markdown content.\n\n## Observations\n- Point one\n- Point two",
                                template: .observation
                            )
                        ],
                        onEdit: { _ in },
                        onDelete: { _ in },
                        onDismiss: {},
                        onRefresh: { [] }
                    )
                }
        }
    }
    return PreviewContainer()
}

#Preview("Note Preview Sheet - Multiple") {
    struct PreviewContainer: View {
        @State private var state = NotePreviewSheetState()

        var body: some View {
            Color.clear
                .sheet(isPresented: .constant(true)) {
                    NotePreviewSheet(state: state)
                }
                .onAppear {
                    state.configure(
                        notes: [
                            Note(
                                userId: UUID(),
                                bookId: 1,
                                chapter: 1,
                                verseStart: 1,
                                verseEnd: 1,
                                content: "First note - observations about the text.",
                                template: .observation
                            ),
                            Note(
                                userId: UUID(),
                                bookId: 1,
                                chapter: 1,
                                verseStart: 1,
                                verseEnd: 1,
                                content: "Second note - questions raised.\n\n1. Why does this happen?\n2. What is the context?",
                                template: .questions
                            ),
                            Note(
                                userId: UUID(),
                                bookId: 1,
                                chapter: 1,
                                verseStart: 1,
                                verseEnd: 1,
                                content: "Third note - prayer response.\n\n## Praise\nThank you for this word.",
                                template: .prayer
                            )
                        ],
                        onEdit: { _ in },
                        onDelete: { _ in },
                        onDismiss: {},
                        onRefresh: { [] }
                    )
                }
        }
    }
    return PreviewContainer()
}

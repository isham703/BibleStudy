//
//  SermonJournalView.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  My Journal spoke — user bookmarks and journal entries.
//  Sections: "Bookmarks" (timestamped notes) and "Journal Responses"
//  (discussion/reflection entries from SermonEngagementService).
//

import SwiftUI

// MARK: - Sermon Journal View

struct SermonJournalView: View {
    @Bindable var flowState: SermonFlowState
    @Binding var bookmarks: [SermonBookmark]
    let onSeek: (TimeInterval) -> Void
    let onAddNote: () -> Void
    let onShare: () -> Void
    let onNewSermon: () -> Void
    let onDelete: () -> Void

    // MARK: - State

    @State private var editingBookmark: SermonBookmark?
    @State private var editingNote: String = ""
    @State private var isKeyboardVisible = false

    private let engagementService = SermonEngagementService.shared

    // MARK: - Computed

    private var journalEntries: [SermonEngagement] {
        guard let sermonId = flowState.currentSermon?.id else { return [] }
        return engagementService.engagements.filter {
            $0.engagementType == .journalEntry && $0.sermonId == sermonId
        }
    }

    private var hasBookmarks: Bool {
        !bookmarks.isEmpty
    }

    private var hasJournalEntries: Bool {
        !journalEntries.isEmpty
    }

    private var isEmpty: Bool {
        !hasBookmarks && !hasJournalEntries
    }

    private var isSampleSermon: Bool {
        flowState.isViewingSample
    }

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.lg) {
                if isEmpty {
                    emptyState
                } else {
                    if hasBookmarks {
                        bookmarksSection
                    }
                    if hasJournalEntries {
                        journalEntriesSection
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xxl * 2)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SermonFloatingBottomBar(
                isVisible: !isKeyboardVisible,
                isSampleSermon: isSampleSermon,
                onAddNoteTap: onAddNote,
                onShareTap: onShare,
                onNewSermonTap: onNewSermon,
                onDeleteTap: onDelete
            )
        }
        .navigationTitle("My Journal")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        .sheet(item: $editingBookmark) { bookmark in
            bookmarkEditSheet(bookmark: bookmark)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer().frame(height: Theme.Spacing.xxl)

            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundStyle(Color("TertiaryText"))

            VStack(spacing: Theme.Spacing.sm) {
                Text("No Journal Entries Yet")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text("Your bookmarks, notes, and responses to discussion questions will appear here.")
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
            }

            Button(action: onAddNote) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "pencil.line")
                        .font(Typography.Icon.sm)
                    Text("Add a quick note")
                        .font(Typography.Command.cta)
                }
                .foregroundStyle(Color("AccentBronze"))
                .frame(minHeight: Theme.Size.minTapTarget)
                .padding(.horizontal, Theme.Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(Color("AccentBronze"), lineWidth: Theme.Stroke.control)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add a quick note")

            NavigationLink(value: SermonDestination.studyGuide(scrollTo: .discussionQuestions)) {
                Text("Or answer a discussion question in the Study Guide.")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Theme.Spacing.lg)
    }

    // MARK: - Bookmarks Section

    private var bookmarksSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section header
            HStack {
                Image(systemName: "bookmark.fill")
                    .font(Typography.Icon.sm)
                    .foregroundStyle(Color("AccentBronze"))

                Text("BOOKMARKS")
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.labelTracking)
                    .foregroundStyle(Color("TertiaryText"))

                Spacer()

                Text("\(bookmarks.count)")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("TertiaryText"))
            }

            ForEach(bookmarks) { bookmark in
                BookmarkRow(bookmark: bookmark, onSeek: onSeek)
                    .contextMenu {
                        Button {
                            editingBookmark = bookmark
                            editingNote = bookmark.note ?? ""
                        } label: {
                            Label("Edit Note", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            deleteBookmark(bookmark)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }

    // MARK: - Journal Entries Section

    private var journalEntriesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section header
            HStack {
                Image(systemName: "text.book.closed")
                    .font(Typography.Icon.sm)
                    .foregroundStyle(Color("FeedbackSuccess"))

                Text("JOURNAL RESPONSES")
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.labelTracking)
                    .foregroundStyle(Color("TertiaryText"))

                Spacer()

                Text("\(journalEntries.count)")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("TertiaryText"))
            }

            ForEach(journalEntries, id: \.id) { entry in
                journalEntryRow(entry)
            }
        }
    }

    // MARK: - Journal Entry Row

    private func journalEntryRow(_ entry: SermonEngagement) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Entry type indicator
            HStack {
                Image(systemName: "pencil.and.outline")
                    .font(Typography.Icon.sm)
                    .foregroundStyle(Color("FeedbackSuccess"))

                Text("Response")
                    .font(Typography.Command.label)
                    .foregroundStyle(Color("FeedbackSuccess"))

                Spacer()

                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("TertiaryText"))
            }

            // Content
            if let content = entry.content, !content.isEmpty {
                Text(content)
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineSpacing(Typography.Command.bodyLineSpacing)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface"))
        )
    }

    // MARK: - Bookmark Edit Sheet

    private func bookmarkEditSheet(bookmark: SermonBookmark) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Bookmark info
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("BOOKMARK")
                        .font(Typography.Command.meta)
                        .tracking(Typography.Editorial.labelTracking)
                        .foregroundStyle(Color("TertiaryText"))

                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: bookmark.label?.icon ?? "bookmark")
                            .font(Typography.Icon.sm)
                            .foregroundStyle(Color("AccentBronze"))

                        Text(bookmark.displayLabel)
                            .font(Typography.Command.body)
                            .foregroundStyle(Color("AppTextPrimary"))

                        Spacer()

                        Text(bookmark.formattedTimestamp)
                            .font(Typography.Command.caption.monospacedDigit())
                            .foregroundStyle(Color("TertiaryText"))
                    }
                }

                // Note editor
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("NOTE")
                        .font(Typography.Command.meta)
                        .tracking(Typography.Editorial.labelTracking)
                        .foregroundStyle(Color("TertiaryText"))

                    TextEditor(text: $editingNote)
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120, maxHeight: 240)
                        .padding(Theme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.input)
                                .fill(Color("AppSurface"))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.input)
                                .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
                        )
                }

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .background(Color("AppBackground"))
            .navigationTitle("Edit Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        editingBookmark = nil
                    }
                    .foregroundStyle(Color("AppTextSecondary"))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBookmarkNote(bookmark)
                    }
                    .font(Typography.Command.body.weight(.semibold))
                    .foregroundStyle(Color("AppAccentAction"))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Actions

    private func deleteBookmark(_ bookmark: SermonBookmark) {
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) else { return }
        var mutable = bookmarks[index]
        mutable.markDeleted()
        do {
            try SermonRepository.shared.updateBookmark(mutable)
            bookmarks.remove(at: index)
            HapticService.shared.deleteConfirmed()
        } catch {
            print("[SermonJournalView] Failed to delete bookmark: \(error)")
        }
    }

    private func saveBookmarkNote(_ bookmark: SermonBookmark) {
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) else {
            editingBookmark = nil
            return
        }
        var mutable = bookmarks[index]
        let trimmed = editingNote.trimmingCharacters(in: .whitespacesAndNewlines)
        mutable.updateNote(trimmed.isEmpty ? nil : trimmed)
        do {
            try SermonRepository.shared.updateBookmark(mutable)
            bookmarks[index] = mutable
            HapticService.shared.selectionChanged()
        } catch {
            print("[SermonJournalView] Failed to update bookmark: \(error)")
        }
        editingBookmark = nil
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var flowState = SermonFlowState()
    @Previewable @State var bookmarks: [SermonBookmark] = []

    NavigationStack {
        SermonJournalView(
            flowState: flowState,
            bookmarks: $bookmarks,
            onSeek: { _ in },
            onAddNote: {},
            onShare: {},
            onNewSermon: {},
            onDelete: {}
        )
    }
    .preferredColorScheme(.dark)
    .onAppear {
        flowState.currentSermon = Sermon(
            userId: UUID(),
            title: "The Power of Grace",
            speakerName: "Pastor John",
            recordedAt: Date(),
            durationSeconds: 2700
        )
    }
}

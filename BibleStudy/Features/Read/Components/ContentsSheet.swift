//
//  ContentsSheet.swift
//  BibleStudy
//
//  Apple Books-style Contents sheet with progress, recents, and book picker
//  Follows Miller's Law: ~7 items max for recents
//

import SwiftUI

// MARK: - Contents Sheet

struct ContentsSheet: View {
    @Environment(\.dismiss) private var dismiss

    // Current reading state
    let currentBookId: Int
    let currentChapter: Int
    let currentVerse: Int
    let totalVerses: Int

    // User content for current book
    let highlights: [Highlight]
    let notes: [Note]

    // Reading history
    let recentChapters: [RecentChapter]

    // Selection callback
    let onSelect: (Int, Int) -> Void

    // Internal state
    @State private var selectedTestament: Testament = .old
    @State private var selectedBook: Book?
    @State private var selectedChapter: Int = 1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Current Position with Progress
                    currentPositionSection

                    // Recent Chapters (Miller's Law: max 7)
                    if !recentChapters.isEmpty {
                        recentChaptersSection
                    }

                    // Book Picker
                    bookPickerSection

                    // Highlights & Notes in current book
                    if !highlights.isEmpty || !notes.isEmpty {
                        highlightsNotesSection
                    }
                }
                .padding(.vertical)
            }
            .background(Color.appBackground)
            .navigationTitle("Contents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if let book = Book.find(byId: currentBookId) {
                selectedBook = book
                selectedTestament = book.testament
                selectedChapter = currentChapter
            }
        }
    }

    // MARK: - Current Position Section

    private var currentPositionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("CURRENT POSITION")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                if let book = Book.find(byId: currentBookId) {
                    Text("\(book.name) \(currentChapter):\(currentVerse)")
                        .font(Typography.UI.title3.monospacedDigit())
                        .foregroundStyle(Color.primaryText)

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xs)
                                .fill(Color.surfaceBackground)
                                .frame(height: 8)

                            // Progress
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xs)
                                .fill(Color.accentGold)
                                .frame(width: geometry.size.width * progressFraction, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(progressFraction * 100))% through chapter")
                        .font(Typography.UI.caption1.monospacedDigit())
                        .foregroundStyle(Color.secondaryText)
                }
            }
            .padding()
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            .padding(.horizontal)
        }
    }

    private var progressFraction: Double {
        guard totalVerses > 0 else { return 0 }
        return Double(currentVerse) / Double(totalVerses)
    }

    // MARK: - Recent Chapters Section

    private var recentChaptersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("RECENT")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(recentChapters.prefix(7)) { recent in
                    Button {
                        onSelect(recent.bookId, recent.chapter)
                        dismiss()
                    } label: {
                        HStack {
                            Text(recent.displayName)
                                .font(Typography.UI.body)
                                .foregroundStyle(Color.primaryText)

                            Spacer()

                            Text(recent.relativeTime)
                                .font(Typography.UI.caption1)
                                .foregroundStyle(Color.tertiaryText)

                            Image(systemName: "chevron.right")
                                .font(Typography.UI.caption1)
                                .foregroundStyle(Color.tertiaryText)
                        }
                        .padding()
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if recent.id != recentChapters.prefix(7).last?.id {
                        Divider()
                            .padding(.leading)
                    }
                }
            }
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            .padding(.horizontal)
        }
    }

    // MARK: - Book Picker Section

    private var bookPickerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("BOOKS")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)
                .padding(.horizontal)

            VStack(spacing: AppTheme.Spacing.md) {
                // Testament Picker
                Picker("Testament", selection: $selectedTestament) {
                    Text("Old Testament").tag(Testament.old)
                    Text("New Testament").tag(Testament.new)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Books Grid
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80, maximum: 100))
                ], spacing: AppTheme.Spacing.sm) {
                    ForEach(booksForTestament, id: \.id) { book in
                        BookButton(
                            book: book,
                            isSelected: selectedBook?.id == book.id
                        ) {
                            selectedBook = book
                            selectedChapter = 1
                        }
                    }
                }
                .padding(.horizontal)

                // Chapter Selector (if book selected)
                if let book = selectedBook {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("\(book.name) - Select Chapter")
                            .font(Typography.UI.subheadline)
                            .foregroundStyle(Color.secondaryText)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                ForEach(1...book.chapters, id: \.self) { chapter in
                                    ChapterButton(
                                        chapter: chapter,
                                        isSelected: selectedChapter == chapter
                                    ) {
                                        selectedChapter = chapter
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        Button {
                            onSelect(book.id, selectedChapter)
                            dismiss()
                        } label: {
                            Text("Go to \(book.abbreviation) \(selectedChapter)")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.primary)
                        .padding(.horizontal)
                    }
                    .padding(.top, AppTheme.Spacing.sm)
                }
            }
            .padding(.vertical)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            .padding(.horizontal)
        }
    }

    private var booksForTestament: [Book] {
        Book.all.filter { $0.testament == selectedTestament }
    }

    // MARK: - Highlights & Notes Section

    private var highlightsNotesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            if let book = Book.find(byId: currentBookId) {
                Text("HIGHLIGHTS & NOTES IN \(book.name.uppercased())")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.secondaryText)
                    .padding(.horizontal)
            }

            VStack(spacing: 0) {
                // Highlights
                ForEach(highlights.prefix(5)) { highlight in
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Circle()
                            .fill(highlight.color.color)
                            .frame(width: 12, height: 12)

                        Text(highlight.verseReference)
                            .font(Typography.UI.subheadline)
                            .foregroundStyle(Color.primaryText)

                        Spacer()

                        Text(highlight.previewText)
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.secondaryText)
                            .lineLimit(1)
                    }
                    .padding()

                    if highlight.id != highlights.prefix(5).last?.id || !notes.isEmpty {
                        Divider()
                            .padding(.leading)
                    }
                }

                // Notes
                ForEach(notes.prefix(5)) { note in
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "note.text")
                            .foregroundStyle(Color.accentBlue)
                            .frame(width: 12)

                        Text(note.verseReference)
                            .font(Typography.UI.subheadline)
                            .foregroundStyle(Color.primaryText)

                        Spacer()

                        Text(note.previewText)
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.secondaryText)
                            .lineLimit(1)
                    }
                    .padding()

                    if note.id != notes.prefix(5).last?.id {
                        Divider()
                            .padding(.leading)
                    }
                }
            }
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            .padding(.horizontal)
        }
    }
}

// MARK: - Recent Chapter Model

struct RecentChapter: Identifiable {
    let id: UUID
    let bookId: Int
    let chapter: Int
    let visitedAt: Date

    var displayName: String {
        guard let book = Book.find(byId: bookId) else { return "" }
        return "\(book.name) \(chapter)"
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: visitedAt, relativeTo: Date())
    }
}

// MARK: - Highlight Extensions

extension Highlight {
    var verseReference: String {
        guard let book = Book.find(byId: range.bookId) else { return "" }
        if range.verseStart == range.verseEnd {
            return "\(book.abbreviation) \(range.chapter):\(range.verseStart)"
        }
        return "\(book.abbreviation) \(range.chapter):\(range.verseStart)-\(range.verseEnd)"
    }

    var previewText: String {
        // Return first 30 chars of highlighted text if available
        // This would need to be populated from the actual verse text
        return ""
    }
}

// MARK: - Note Extensions

extension Note {
    var verseReference: String {
        guard let book = Book.find(byId: range.bookId) else { return "" }
        if range.verseStart == range.verseEnd {
            return "\(book.abbreviation) \(range.chapter):\(range.verseStart)"
        }
        return "\(book.abbreviation) \(range.chapter):\(range.verseStart)-\(range.verseEnd)"
    }

    var previewText: String {
        // Return first 30 chars of note content
        let preview = content.prefix(30)
        return preview.count < content.count ? "\(preview)..." : String(preview)
    }
}

// MARK: - Preview

#Preview("Contents Sheet") {
    Color.appBackground
        .sheet(isPresented: .constant(true)) {
            ContentsSheet(
                currentBookId: 1,
                currentChapter: 1,
                currentVerse: 15,
                totalVerses: 31,
                highlights: [],
                notes: [],
                recentChapters: [
                    RecentChapter(id: UUID(), bookId: 19, chapter: 23, visitedAt: Date().addingTimeInterval(-86400)),
                    RecentChapter(id: UUID(), bookId: 43, chapter: 3, visitedAt: Date().addingTimeInterval(-172800)),
                    RecentChapter(id: UUID(), bookId: 45, chapter: 8, visitedAt: Date().addingTimeInterval(-259200))
                ]
            ) { bookId, chapter in
                print("Selected: \(bookId):\(chapter)")
            }
        }
}

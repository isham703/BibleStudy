import SwiftUI

// MARK: - Verse Preview Sheet
// Displays Bible verses from a verse range in a sheet

struct VersePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(BibleService.self) private var bibleService

    let verseRange: VerseRange
    @State private var verses: [Verse] = []
    @State private var isLoading = true
    @State private var error: Error?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        if let book = verseRange.book {
                            Text(book.name)
                                .font(Typography.Command.caption)
                                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                                .textCase(.uppercase)
                                .tracking(1)
                        }

                        Text(verseRange.reference)
                            .font(Typography.Scripture.title)
                            .foregroundStyle(Color.primaryText)
                    }
                    .padding(.bottom, Theme.Spacing.sm)

                    // Content
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, Theme.Spacing.xl)
                    } else if let error = error {
                        errorView(error)
                    } else if verses.isEmpty {
                        Text("No verses found.")
                            .font(Typography.Command.body)
                            .foregroundStyle(Color.secondaryText)
                    } else {
                        // Verses with numbers
                        ForEach(verses, id: \.id) { verse in
                            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                                Text(String(verse.verse))
                                    .font(Typography.Command.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(Color.verseNumber)
                                    .frame(width: 24, alignment: .trailing)

                                Text(verse.text)
                                    .font(Typography.Scripture.body)
                                    .foregroundStyle(Color.primaryText)
                                    .lineSpacing(6)
                                    .textSelection(.enabled)
                            }
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Scripture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadVerses()
        }
    }

    // MARK: - Error View
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(Typography.Command.title1)
                .foregroundStyle(Color.warning)

            Text("Unable to load verses")
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color.primaryText)

            Button("Try Again") {
                Task { await loadVerses() }
            }
            .font(Typography.Command.caption.weight(.semibold))
            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.xl)
    }

    // MARK: - Load Verses
    private func loadVerses() async {
        isLoading = true
        error = nil

        do {
            verses = try await bibleService.getVerses(range: verseRange)
        } catch {
            self.error = error
        }

        isLoading = false
    }
}

// MARK: - Preview
#Preview {
    VersePreviewSheet(
        verseRange: VerseRange(bookId: 1, chapter: 1, verseStart: 1, verseEnd: 5)
    )
    .environment(BibleService.shared)
}

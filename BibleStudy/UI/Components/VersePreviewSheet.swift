import SwiftUI

// MARK: - Verse Preview Sheet
// Displays Bible verses from a verse range in a sheet

struct VersePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(BibleService.self) private var bibleService

    let verseRange: VerseRange
    @State private var verses: [Verse] = []
    @State private var isLoading = true
    @State private var error: Error?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        if let book = verseRange.book {
                            Text(book.name)
                                .font(Typography.UI.caption1)
                                .foregroundStyle(Color.accentGold)
                                .textCase(.uppercase)
                                .tracking(1)
                        }

                        Text(verseRange.reference)
                            .font(Typography.Scripture.title)
                            .foregroundStyle(Color.primaryText)
                    }
                    .padding(.bottom, AppTheme.Spacing.sm)

                    // Content
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, AppTheme.Spacing.xl)
                    } else if let error = error {
                        errorView(error)
                    } else if verses.isEmpty {
                        Text("No verses found.")
                            .font(Typography.UI.warmSubheadline)
                            .foregroundStyle(Color.secondaryText)
                    } else {
                        // Verses with numbers
                        ForEach(verses) { verse in
                            HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                                Text("\(verse.verse)")
                                    .font(Typography.UI.caption1Bold.monospacedDigit())
                                    .foregroundStyle(Color.verseNumber)
                                    .frame(width: 24, alignment: .trailing)

                                Text(verse.text)
                                    .font(Typography.Scripture.body(size: 18))
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
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(Typography.UI.title1)
                .foregroundStyle(Color.warning)

            Text("Unable to load verses")
                .font(Typography.UI.subheadline)
                .foregroundStyle(Color.primaryText)

            Button("Try Again") {
                Task { await loadVerses() }
            }
            .font(Typography.UI.caption1Bold)
            .foregroundStyle(Color.accentGold)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppTheme.Spacing.xl)
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

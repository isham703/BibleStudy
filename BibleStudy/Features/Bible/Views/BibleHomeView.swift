import SwiftUI

// MARK: - Bible Home View
// Landing page for Bible tab
// Shows featured book, continue reading option, and full Bible navigation

struct BibleHomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(BibleService.self) private var bibleService
    @State private var selectedBook: Book?
    @State private var showBookPicker = false
    @State private var showSettings = false
    @State private var isAppeared = false

    // Last reading position (persisted)
    @AppStorage("scholarLastBookId") private var lastBookId: Int = 43 // John
    @AppStorage("scholarLastChapter") private var lastChapter: Int = 1

    // Navigation binding for push to reader
    @Binding var navigationPath: NavigationPath

    private var lastBook: Book? {
        Book.find(byId: lastBookId)
    }

    // Chapter grid columns (7 columns like CommentaryHomeView)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xxl) {
                // Hero section with featured book
                heroSection

                // Continue reading card
                if lastBook != nil && lastChapter > 0 {
                    continueReadingCard
                }

                // Quick access - Gospels
                quickAccessSection

                // Full Bible access button
                fullBibleButton

                // About section
                aboutSection
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.xl)
        }
        .background(Color.appBackground)
        .onAppear {
            withAnimation(AppTheme.Animation.cardUnfurl.delay(0.1)) {
                isAppeared = true
            }
        }
        .sheet(isPresented: $showBookPicker) {
            BibleBookPickerView(
                currentBookId: lastBookId,
                currentChapter: lastChapter
            ) { bookId, chapter in
                navigateToChapter(bookId: bookId, chapter: chapter)
            }
        }
        .sheet(isPresented: $showSettings) {
            BibleSettingsSheet()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticService.shared.lightTap()
                    showSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(Typography.UI.body)
                        .foregroundStyle(Color.scholarIndigo)
                }
                .accessibilityLabel("Bible Settings")
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Decorative book cover - Scholar themed
            ZStack {
                // Book shadow
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 120, height: 160)
                    .offset(x: 4, y: 6)

                // Book cover
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color.scholarIndigo, Color.scholarIndigo.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 160)
                    .overlay(
                        VStack(spacing: 8) {
                            Text(bibleService.currentTranslation?.abbreviation ?? "KJV")
                                .font(.system(size: 9, weight: .semibold))
                                .tracking(2)
                                .foregroundStyle(Color.white.opacity(0.7))

                            Image(systemName: "book.pages")
                                .font(.system(size: 32, weight: .light))
                                .foregroundStyle(Color.white)

                            // Decorative line
                            Rectangle()
                                .fill(Color.divineGold)
                                .frame(width: 40, height: 1)
                        }
                    )
                    .overlay(
                        // Spine effect
                        HStack {
                            Rectangle()
                                .fill(Color.black.opacity(0.1))
                                .frame(width: 4)
                            Spacer()
                        }
                    )
            }
            .padding(.top, AppTheme.Spacing.lg)
            .opacity(isAppeared ? 1 : 0)
            .offset(y: isAppeared ? 0 : 20)
            .animation(AppTheme.Animation.cardUnfurl.delay(0.1), value: isAppeared)

            // Title and description
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(bibleService.currentTranslation?.name ?? "King James Version")
                    .font(Typography.Display.title3)
                    .foregroundStyle(Color.primaryText)
                    .multilineTextAlignment(.center)

                Text("Deep study with AI-powered insights")
                    .font(Typography.UI.subheadline)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .opacity(isAppeared ? 1 : 0)
            .animation(AppTheme.Animation.cardUnfurl.delay(0.2), value: isAppeared)
        }
    }

    // MARK: - Continue Reading Card

    private var continueReadingCard: some View {
        Button {
            navigateToChapter(bookId: lastBookId, chapter: lastChapter)
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.scholarIndigo.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: "book.fill")
                        .font(Typography.UI.iconMd)
                        .foregroundStyle(Color.scholarIndigo)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue Reading")
                        .font(Typography.UI.subheadline.weight(.medium))
                        .foregroundStyle(Color.primaryText)

                    if let book = lastBook {
                        Text("\(book.name) Chapter \(lastChapter)")
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.secondaryText)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(isAppeared ? 1 : 0)
        .animation(AppTheme.Animation.cardUnfurl.delay(0.3), value: isAppeared)
        .accessibilityLabel("Continue reading \(lastBook?.name ?? "") chapter \(lastChapter)")
        .accessibilityHint("Double tap to resume reading")
    }

    // MARK: - Quick Access Section (Gospels)

    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("QUICK ACCESS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(Color.tertiaryText)

            // Gospels row
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach([Book.matthew, Book.find(byId: 41)!, Book.find(byId: 42)!, Book.john], id: \.id) { book in
                    quickAccessBookButton(book: book)
                }
            }
        }
        .opacity(isAppeared ? 1 : 0)
        .animation(AppTheme.Animation.cardUnfurl.delay(0.4), value: isAppeared)
    }

    private func quickAccessBookButton(book: Book) -> some View {
        Button {
            HapticService.shared.lightTap()
            selectedBook = book
            // Navigate to chapter 1 of this book
            navigateToChapter(bookId: book.id, chapter: 1)
        } label: {
            VStack(spacing: AppTheme.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(Color.scholarIndigo.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Text(String(book.name.prefix(1)))
                        .font(CustomFonts.cormorantSemiBold(size: 18))
                        .foregroundStyle(Color.scholarIndigo)
                }

                Text(book.abbreviation)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(Color.scholarIndigo.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Full Bible Button

    private var fullBibleButton: some View {
        Button {
            HapticService.shared.lightTap()
            showBookPicker = true
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "books.vertical")
                    .font(Typography.UI.iconMd)
                    .foregroundStyle(Color.scholarIndigo)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Browse All Books")
                        .font(Typography.UI.subheadline.weight(.medium))
                        .foregroundStyle(Color.primaryText)

                    Text("66 books • Old & New Testament")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.tertiaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .stroke(Color.scholarIndigo.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(isAppeared ? 1 : 0)
        .animation(AppTheme.Animation.cardUnfurl.delay(0.5), value: isAppeared)
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.divineGold)

                Text("AI-Powered Study")
                    .font(Typography.UI.caption1.weight(.medium))
                    .foregroundStyle(Color.secondaryText)
            }

            Text("Long-press any verse to reveal theological insights, cross-references, original Greek analysis, and reflection prompts.")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.tertiaryText)
                .lineSpacing(4)

            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "hand.tap")
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.scholarIndigo)

                Text("Tap to select • Long-press for insights")
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.tertiaryText)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(Color.surfaceBackground.opacity(0.5))
        )
        .opacity(isAppeared ? 1 : 0)
        .animation(AppTheme.Animation.cardUnfurl.delay(0.6), value: isAppeared)
    }

    // MARK: - Navigation Helper

    private func navigateToChapter(bookId: Int, chapter: Int) {
        // Save as last position
        lastBookId = bookId
        lastChapter = chapter

        // Create location and push to navigation
        let location = BibleLocation(bookId: bookId, chapter: chapter, verse: 1)
        navigationPath.append(location)

        HapticService.shared.mediumTap()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BibleHomeView(navigationPath: .constant(NavigationPath()))
    }
    .environment(AppState())
    .environment(BibleService.shared)
}

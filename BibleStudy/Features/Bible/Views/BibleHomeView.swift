import SwiftUI

// MARK: - Bible Home View
// Landing page for Bible tab
// Shows featured book, continue reading option, and full Bible navigation

struct BibleHomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
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
            VStack(spacing: Theme.Spacing.xxl) {
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
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.xl)
        }
        .background(Color.appBackground)
        .onAppear {
            withAnimation(Theme.Animation.settle.delay(0.1)) {
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
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("AppAccentAction"))
                }
                .accessibilityLabel("Bible Settings")
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Decorative book cover - Scholar themed
            ZStack {
                // Book shadow
                // swiftlint:disable:next hardcoded_rounded_rectangle
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(Color.black.opacity(Theme.Opacity.selectionBackground))
                    .frame(width: 120, height: 160)
                    .offset(x: 4, y: 6)

                // Book cover
                // swiftlint:disable:next hardcoded_rounded_rectangle
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(
                        LinearGradient(
                            colors: [Color("AppAccentAction"), Color("AppAccentAction").opacity(Theme.Opacity.pressed)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 160)
                    .overlay(
                        // swiftlint:disable:next hardcoded_stack_spacing
                        VStack(spacing: 8) {
                            Text(bibleService.currentTranslation?.abbreviation ?? "KJV")
                                .font(Typography.Icon.xxs.weight(.semibold))
                                .tracking(2)
                                .foregroundStyle(Color.white.opacity(Theme.Opacity.overlay))

                            Image(systemName: "book.pages")
                                .font(Typography.Icon.xxl.weight(.light))
                                .foregroundStyle(Color.white)

                            // Decorative line
                            Rectangle()
                                .fill(Color("AccentBronze"))
                                .frame(width: 40, height: Theme.Stroke.hairline)
                        }
                    )
                    .overlay(
                        // Spine effect
                        HStack {
                            Rectangle()
                                .fill(Color.black.opacity(Theme.Opacity.subtle))
                                .frame(width: 4)
                            Spacer()
                        }
                    )
            }
            .padding(.top, Theme.Spacing.lg)
            .opacity(isAppeared ? 1 : 0)
            .offset(y: isAppeared ? 0 : 20)
            .animation(Theme.Animation.settle.delay(0.1), value: isAppeared)

            // Title and description
            VStack(spacing: Theme.Spacing.sm) {
                Text(bibleService.currentTranslation?.name ?? "King James Version")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .multilineTextAlignment(.center)

                Text("Deep study with AI-powered insights")
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
            }
            .opacity(isAppeared ? 1 : 0)
            .animation(Theme.Animation.settle.delay(0.2), value: isAppeared)
        }
    }

    // MARK: - Continue Reading Card

    private var continueReadingCard: some View {
        Button {
            navigateToChapter(bookId: lastBookId, chapter: lastChapter)
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color("AppAccentAction").opacity(Theme.Opacity.subtle))
                        .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)

                    Image(systemName: "book.fill")
                        .font(Typography.Icon.md)
                        .foregroundStyle(Color("AppAccentAction"))
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue Reading")
                        .font(Typography.Command.subheadline.weight(.medium))
                        .foregroundStyle(Color("AppTextPrimary"))

                    if let book = lastBook {
                        Text("\(book.name) Chapter \(lastChapter)")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color("AppSurface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
        .opacity(isAppeared ? 1 : 0)
        .animation(Theme.Animation.settle.delay(0.3), value: isAppeared)
        .accessibilityLabel("Continue reading \(lastBook?.name ?? "") chapter \(lastChapter)")
        .accessibilityHint("Double tap to resume reading")
    }

    // MARK: - Quick Access Section (Gospels)

    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("QUICK ACCESS")
                .font(Typography.Command.meta.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(Color("TertiaryText"))

            // Gospels row
            HStack(spacing: Theme.Spacing.sm) {
                ForEach([Book.matthew, Book.find(byId: 41)!, Book.find(byId: 42)!, Book.john], id: \.id) { book in
                    quickAccessBookButton(book: book)
                }
            }
        }
        .opacity(isAppeared ? 1 : 0)
        .animation(Theme.Animation.settle.delay(0.4), value: isAppeared)
    }

    private func quickAccessBookButton(book: Book) -> some View {
        Button {
            HapticService.shared.lightTap()
            selectedBook = book
            // Navigate to chapter 1 of this book
            navigateToChapter(bookId: book.id, chapter: 1)
        } label: {
            VStack(spacing: Theme.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(Color("AppAccentAction").opacity(Theme.Opacity.subtle))
                        .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)

                    Text(String(book.name.prefix(1)))
                        .font(Typography.Scripture.body.weight(.semibold))
                        .foregroundStyle(Color("AppAccentAction"))
                }

                Text(book.abbreviation)
                    .font(Typography.Command.caption.weight(.medium))
                    .foregroundStyle(Color("AppTextPrimary"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(Color("AppSurface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .stroke(Color("AppAccentAction").opacity(Theme.Opacity.subtle), lineWidth: Theme.Stroke.hairline)
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
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "books.vertical")
                    .font(Typography.Icon.md)
                    .foregroundStyle(Color("AppAccentAction"))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Browse All Books")
                        .font(Typography.Command.subheadline.weight(.medium))
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text("66 books • Old & New Testament")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("TertiaryText"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color("AppSurface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground), lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
        .opacity(isAppeared ? 1 : 0)
        .animation(Theme.Animation.settle.delay(0.5), value: isAppeared)
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AccentBronze"))

                Text("AI-Powered Study")
                    .font(Typography.Command.caption.weight(.medium))
                    .foregroundStyle(Color("AppTextSecondary"))
            }

            Text("Long-press any verse to reveal theological insights, cross-references, original Greek analysis, and reflection prompts.")
                .font(Typography.Command.caption)
                .foregroundStyle(Color("AppTextSecondary").opacity(Theme.Opacity.pressed))
                .lineSpacing(4)

            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "hand.tap")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("AppAccentAction"))

                Text("Tap to select • Long-press for insights")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("TertiaryText"))
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Color("AppSurface").opacity(Theme.Opacity.textSecondary))
        )
        .opacity(isAppeared ? 1 : 0)
        .animation(Theme.Animation.settle.delay(0.6), value: isAppeared)
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

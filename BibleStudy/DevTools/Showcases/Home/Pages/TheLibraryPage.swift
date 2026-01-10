import SwiftUI

// MARK: - The Library Page
// Scholarly design using the Meridian palette
// Design: Warm parchment tones, gilded accents, midday light streaming through library windows
// Theme Tokens: meridianParchment, meridianSepia, meridianGilded, meridianVellum, meridianIllumination

struct TheLibraryPage: View {
    @State private var isAwakened = false
    @State private var shimmer = false
    @Environment(\.dismiss) private var dismiss

    // Mock data
    private let greeting = SanctuaryMockData.fullGreeting
    private let dailyVerse = SanctuaryMockData.dailyVerse
    private let activePlan = SanctuaryMockData.activePlan

    var body: some View {
        ZStack {
            // Warm scholarly background
            backgroundLayer

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with light beam effect
                    headerSection
                        .padding(.top, 60)
                        .padding(.bottom, Theme.Spacing.xxl)

                    // Reading desk card (main focus)
                    readingDeskCard
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Shelf divider
                    shelfDivider
                        .padding(.bottom, Theme.Spacing.xl)

                    // Study materials grid
                    studyMaterialsGrid
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Bookmarks section
                    bookmarksSection
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 100)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(Typography.Icon.sm)
                        Text("Back")
                            .font(Typography.Command.callout)
                    }
                    .foregroundStyle(Color.meridianGilded.opacity(Theme.Opacity.pressed))
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Image(systemName: "magnifyingglass")
                    .font(Typography.Icon.md)
                    .foregroundStyle(Color.meridianGilded.opacity(Theme.Opacity.tertiary))
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
            withAnimation(
                .easeInOut(duration: 3)
                .repeatForever(autoreverses: true)
            ) {
                shimmer = true
            }
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            // Deep sepia base
            Color.meridianSepia
                .ignoresSafeArea()

            // Warm light from above (window effect)
            RadialGradient(
                colors: [
                    Color.meridianIllumination.opacity(shimmer ? 0.12 : 0.08),
                    Color.meridianGilded.opacity(Theme.Opacity.faint),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Parchment texture gradient
            LinearGradient(
                colors: [
                    Color.meridianParchment.opacity(Theme.Opacity.faint),
                    Color.clear,
                    Color.meridianVellum.opacity(Theme.Opacity.faint)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Vignette for depth
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(Theme.Opacity.lightMedium)
                ],
                center: .center,
                startRadius: 150,
                endRadius: 450
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Library icon with glow
            ZStack {
                // Glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.meridianIllumination.opacity(shimmer ? 0.15 : 0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "books.vertical.fill")
                    .font(Typography.Icon.hero.weight(.light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.meridianGilded, Color.meridianIllumination],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            // Greeting
            VStack(spacing: Theme.Spacing.xs) {
                Text(greeting)
                    .font(.custom("CormorantGaramond-SemiBold", size: 32))
                    .foregroundStyle(Color.meridianParchment)

                Text("Your study awaits")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.meridianVellum.opacity(Theme.Opacity.heavy))
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .scaleEffect(isAwakened ? 1 : 0.95)
        .animation(.easeOut(duration: 0.7).delay(0.1), value: isAwakened)
    }

    // MARK: - Reading Desk Card

    private var readingDeskCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Card header
            HStack {
                Text("TODAY'S READING")
                    .font(Typography.Icon.xxs.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(Color.meridianGilded)

                Spacer()

                // Open book indicator
                HStack(spacing: 4) {
                    Image(systemName: "book.fill")
                        .font(Typography.Icon.xxs)
                    Text("Open")
                        .font(Typography.Icon.xxs)
                }
                .foregroundStyle(Color.meridianIllumination.opacity(Theme.Opacity.heavy))
            }

            // Scripture content
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text(dailyVerse.text)
                    .font(.custom("CormorantGaramond-Regular", size: 20))
                    .foregroundStyle(Color.meridianParchment.opacity(Theme.Opacity.nearOpaque))
                    .lineSpacing(6)

                // Reference with gilded accent
                HStack {
                    Rectangle()
                        .fill(Color.meridianGilded)
                        .frame(width: 24, height: 2)

                    Text(dailyVerse.reference)
                        .font(.custom("CormorantGaramond-SemiBold", size: 14))
                        .foregroundStyle(Color.meridianGilded)
                }
            }

            // Action row
            HStack {
                Text(dailyVerse.theme)
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color.meridianVellum.opacity(Theme.Opacity.tertiary))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.meridianGilded.opacity(Theme.Opacity.overlay))
                    )

                Spacer()

                Button {
                    // Continue reading
                } label: {
                    HStack(spacing: 6) {
                        Text("Continue")
                            .font(Typography.Command.meta)
                        Image(systemName: "arrow.right")
                            .font(Typography.Command.meta)
                    }
                    .foregroundStyle(Color.meridianGilded)
                }
            }
        }
        .padding(Theme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.meridianSepia.opacity(Theme.Opacity.tertiary))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.meridianGilded.opacity(Theme.Opacity.subtle), Color.meridianIllumination.opacity(Theme.Opacity.divider)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: isAwakened)
    }

    // MARK: - Shelf Divider

    private var shelfDivider: some View {
        HStack(spacing: Theme.Spacing.md) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.meridianGilded.opacity(Theme.Opacity.subtle)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Center ornament
            HStack(spacing: 6) {
                Image(systemName: "book.closed.fill")
                    .font(Typography.Icon.xxs)
                    .foregroundStyle(Color.meridianGilded.opacity(Theme.Opacity.medium))

                Image(systemName: "book.closed.fill")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.meridianGilded.opacity(Theme.Opacity.tertiary))

                Image(systemName: "book.closed.fill")
                    .font(Typography.Icon.xxs)
                    .foregroundStyle(Color.meridianGilded.opacity(Theme.Opacity.medium))
            }

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.meridianGilded.opacity(Theme.Opacity.subtle), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, Theme.Spacing.xxl)
        .opacity(isAwakened ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: isAwakened)
    }

    // MARK: - Study Materials Grid

    private var studyMaterialsGrid: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.md) {
                LibraryMaterialCard(
                    icon: "book.fill",
                    title: "Scripture",
                    subtitle: "Daily reading"
                )

                LibraryMaterialCard(
                    icon: "text.quote",
                    title: "Commentary",
                    subtitle: "Deep study"
                )
            }

            HStack(spacing: Theme.Spacing.md) {
                LibraryMaterialCard(
                    icon: "highlighter",
                    title: "Highlights",
                    subtitle: "12 saved"
                )

                LibraryMaterialCard(
                    icon: "note.text",
                    title: "Notes",
                    subtitle: "8 entries"
                )
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.5), value: isAwakened)
    }

    // MARK: - Bookmarks Section

    private var bookmarksSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section header
            HStack {
                Text("RECENT BOOKMARKS")
                    .font(Typography.Icon.xxs)
                    .tracking(2)
                    .foregroundStyle(Color.meridianGilded.opacity(Theme.Opacity.tertiary))

                Spacer()

                Button {
                    // View all
                } label: {
                    Text("View All")
                        .font(Typography.Icon.xxs.weight(.medium))
                        .foregroundStyle(Color.meridianIllumination.opacity(Theme.Opacity.heavy))
                }
            }

            // Bookmark items
            VStack(spacing: Theme.Spacing.sm) {
                BookmarkRow(reference: "Romans 8:28", note: "All things work together...")
                BookmarkRow(reference: "Psalm 23:1", note: "The Lord is my shepherd...")
                BookmarkRow(reference: "John 3:16", note: "For God so loved...")
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Color.meridianGilded.opacity(Theme.Opacity.faint))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .strokeBorder(Color.meridianGilded.opacity(Theme.Opacity.overlay), lineWidth: 1)
        )
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.6), value: isAwakened)
    }
}

// MARK: - Library Material Card

private struct LibraryMaterialCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        Button {
            // Action
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(Typography.Icon.lg.weight(.light))
                    .foregroundStyle(Color.meridianGilded)

                VStack(spacing: 2) {
                    Text(title)
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.meridianParchment.opacity(Theme.Opacity.high))

                    Text(subtitle)
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color.meridianVellum.opacity(Theme.Opacity.tertiary))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color.meridianGilded.opacity(Theme.Opacity.faint))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .strokeBorder(Color.meridianGilded.opacity(Theme.Opacity.divider), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bookmark Row

private struct BookmarkRow: View {
    let reference: String
    let note: String

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Bookmark icon
            Image(systemName: "bookmark.fill")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.meridianGilded.opacity(Theme.Opacity.tertiary))

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(reference)
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color.meridianParchment.opacity(Theme.Opacity.high))

                Text(note)
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color.meridianVellum.opacity(Theme.Opacity.medium))
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(Typography.Icon.xxs)
                .foregroundStyle(Color.meridianGilded.opacity(Theme.Opacity.lightMedium))
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TheLibraryPage()
    }
}

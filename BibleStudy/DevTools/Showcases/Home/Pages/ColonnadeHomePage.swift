//
//  ColonnadeHomePage.swift
//  BibleStudy
//
//  Home Page Variation 2: The Colonnade
//  Architectural structure and order with pillar-based navigation.
//  Clear hierarchy with multiple entry points organized by practice type.
//

import SwiftUI

// MARK: - Colonnade Home Page

struct ColonnadeHomePage: View {
    @State private var isAwakened = false
    @Environment(\.colorScheme) private var colorScheme

    // Mock data
    private let dailyVerse = SanctuaryMockData.dailyVerse
    private let readingPlan = SanctuaryMockData.activePlan
    private let practiceData = SanctuaryMockData.practiceData

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Top breathing space
                    Spacer()
                        .frame(height: Theme.Spacing.xl)

                    // Header with date and greeting
                    headerSection
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Primary Pillars (3-column grid)
                    primaryPillars
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Daily Verse (Compact)
                    dailyVerseCompact
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Continue Reading (Prominent)
                    continueReadingCard
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Secondary Actions (2x2 grid)
                    secondaryActionsGrid
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Recent Activity Horizontal
                    recentActivityHorizontal
                        .padding(.bottom, Theme.Spacing.xl)

                    // Suggested Next
                    suggestedNextRow
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xxl * 2)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            // Subtle top-down gradient for architectural feel
            LinearGradient(
                colors: [
                    Color("AppAccentAction").opacity(Theme.Opacity.subtle / 2),
                    Color.clear,
                    Color("AccentBronze").opacity(Theme.Opacity.subtle / 3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(SanctuaryMockData.formattedDate.uppercased())
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.sectionTracking)
                    .foregroundStyle(Color("TertiaryText"))

                Text(SanctuaryMockData.fullGreeting)
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))
            }

            Spacer()

            // Streak badge
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "flame.fill")
                    .font(Typography.Icon.sm)
                    .foregroundStyle(Color("AccentBronze"))

                Text("\(SanctuaryMockData.userData.currentStreak)")
                    .font(Typography.Command.headline)
                    .foregroundStyle(Color("AccentBronze"))
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(Color("AccentBronze").opacity(Theme.Opacity.overlay))
            )
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 10)
        .animation(Theme.Animation.slowFade.delay(0.1), value: isAwakened)
    }

    // MARK: - Primary Pillars

    private var primaryPillars: some View {
        HStack(spacing: Theme.Spacing.md) {
            ColonnadePillar(
                icon: "book.fill",
                label: "Scripture",
                isAwakened: isAwakened,
                delay: 0.2,
                accentColor: Color("AppAccentAction")
            )

            ColonnadePillar(
                icon: "text.quote",
                label: "Reflect",
                isAwakened: isAwakened,
                delay: 0.25,
                accentColor: Color("FeedbackInfo")
            )

            ColonnadePillar(
                icon: "hands.sparkles.fill",
                label: "Pray",
                isAwakened: isAwakened,
                delay: 0.3,
                accentColor: Color("AccentBronze")
            )
        }
    }

    // MARK: - Daily Verse Compact

    private var dailyVerseCompact: some View {
        Button {
            // Navigate to verse
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                // Verse icon
                ZStack {
                    Circle()
                        .fill(Color("AccentBronze").opacity(Theme.Opacity.overlay))
                        .frame(width: 44, height: 44)

                    Text("\u{201C}")
                        .font(Typography.Scripture.heading)
                        .foregroundStyle(Color("AccentBronze"))
                        .offset(y: -2)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Verse")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color("TertiaryText"))

                    Text(dailyVerse.reference)
                        .font(Typography.Command.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color("AccentBronze").opacity(colorScheme == .dark ? 0.2 : 0.15), lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(Theme.Animation.slowFade.delay(0.35), value: isAwakened)
    }

    // MARK: - Continue Reading Card

    private var continueReadingCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section header
            HStack {
                Text("CONTINUE READING")
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.labelTracking)
                    .foregroundStyle(Color("TertiaryText"))

                Spacer()

                Text("Day \(readingPlan.currentDay)/\(readingPlan.totalDays)")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("AppTextSecondary"))
            }

            // Card
            Button {
                // Navigate
            } label: {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    // Title row
                    HStack {
                        Text(readingPlan.title)
                            .font(Typography.Scripture.heading)
                            .foregroundStyle(Color("AppTextPrimary"))

                        Spacer()

                        // Progress ring
                        ZStack {
                            Circle()
                                .stroke(Color.appDivider, lineWidth: 3)
                                .frame(width: 44, height: 44)

                            Circle()
                                .trim(from: 0, to: readingPlan.progress)
                                .stroke(Color("AccentBronze"), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: 44, height: 44)
                                .rotationEffect(.degrees(-90))

                            Text("\(readingPlan.progressPercentage)%")
                                .font(Typography.Command.caption)
                                .foregroundStyle(Color("AccentBronze"))
                        }
                    }

                    // Today's reading
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "bookmark.fill")
                            .font(Typography.Icon.xs)
                            .foregroundStyle(Color("AppAccentAction"))

                        Text(readingPlan.todayReference)
                            .font(Typography.Command.body)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }

                    // Preview quote
                    Text("\"\(readingPlan.previewQuote)\"")
                        .font(Typography.Scripture.footnote)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .italic()
                        .lineLimit(2)

                    // CTA
                    HStack {
                        Spacer()

                        Text("Continue")
                            .font(Typography.Command.cta)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(Color("AppAccentAction"))
                            .clipShape(Capsule())
                    }
                }
                .padding(Theme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .fill(Color.appSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)
                )
            }
            .buttonStyle(.plain)
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(Theme.Animation.slowFade.delay(0.4), value: isAwakened)
    }

    // MARK: - Secondary Actions Grid

    private var secondaryActionsGrid: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.md) {
                ColonnadeActionCard(
                    icon: "mic.fill",
                    title: "Sermon",
                    subtitle: "Record & analyze",
                    accentColor: Color("AppAccentAction")
                )

                ColonnadeActionCard(
                    icon: "moon.stars.fill",
                    title: "Compline",
                    subtitle: "Evening prayer",
                    accentColor: Color("FeedbackInfo")
                )
            }

            HStack(spacing: Theme.Spacing.md) {
                ColonnadeActionCard(
                    icon: "wind",
                    title: "Breathe",
                    subtitle: "Centered stillness",
                    accentColor: Color("FeedbackSuccess")
                )

                ColonnadeActionCard(
                    icon: "brain.head.profile",
                    title: "Memorize",
                    subtitle: "\(practiceData.dueCount) verses due",
                    accentColor: Color("AccentBronze")
                )
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(Theme.Animation.slowFade.delay(0.5), value: isAwakened)
    }

    // MARK: - Recent Activity Horizontal

    private var recentActivityHorizontal: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section header
            HStack {
                Text("RECENT ACTIVITY")
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.labelTracking)
                    .foregroundStyle(Color("TertiaryText"))

                Spacer()

                Button {
                    // See all
                } label: {
                    Text("See all")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("AppAccentAction"))
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)

            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ColonnadeActivityChip(
                        icon: "bookmark.fill",
                        title: "John 3:16",
                        time: "Yesterday"
                    )

                    ColonnadeActivityChip(
                        icon: "highlighter",
                        title: "Romans 8:28",
                        time: "2 days ago"
                    )

                    ColonnadeActivityChip(
                        icon: "note.text",
                        title: "Psalm 23 note",
                        time: "Last week"
                    )

                    ColonnadeActivityChip(
                        icon: "text.book.closed.fill",
                        title: "Matthew 5",
                        time: "Last week"
                    )
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(Theme.Animation.slowFade.delay(0.55), value: isAwakened)
    }

    // MARK: - Suggested Next Row

    private var suggestedNextRow: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("SUGGESTED FOR YOU")
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.labelTracking)
                .foregroundStyle(Color("TertiaryText"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ColonnadeSuggestionCard(
                        icon: "lightbulb.fill",
                        title: "Topic: Grace",
                        subtitle: "Explore grace across Scripture",
                        accentColor: Color("FeedbackInfo")
                    )

                    ColonnadeSuggestionCard(
                        icon: "person.2.fill",
                        title: "Character: David",
                        subtitle: "A man after God's heart",
                        accentColor: Color("AccentBronze")
                    )

                    ColonnadeSuggestionCard(
                        icon: "book.fill",
                        title: "Story: The Prodigal",
                        subtitle: "Luke 15:11-32",
                        accentColor: Color("AppAccentAction")
                    )
                }
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(Theme.Animation.slowFade.delay(0.6), value: isAwakened)
    }
}

// MARK: - Colonnade Pillar Component

private struct ColonnadePillar: View {
    let icon: String
    let label: String
    let isAwakened: Bool
    let delay: Double
    let accentColor: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            // Navigate
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                // Pillar icon with architectural styling
                ZStack {
                    // Base
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .fill(accentColor.opacity(Theme.Opacity.overlay))
                        .frame(width: 64, height: 64)

                    // Icon
                    Image(systemName: icon)
                        .font(Typography.Icon.xl.weight(.light))
                        .foregroundStyle(accentColor)
                }

                // Label
                Text(label.uppercased())
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.referenceTracking)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(Theme.Animation.slowFade.delay(delay), value: isAwakened)
    }
}

// MARK: - Colonnade Action Card

private struct ColonnadeActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            // Navigate
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(Typography.Icon.lg.weight(.light))
                    .foregroundStyle(accentColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.Command.label)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text(subtitle)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("TertiaryText"))
                }

                Spacer()
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Colonnade Activity Chip

private struct ColonnadeActivityChip: View {
    let icon: String
    let title: String
    let time: String

    var body: some View {
        Button {
            // Navigate
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(Typography.Icon.xs)
                    .foregroundStyle(Color("AppAccentAction").opacity(Theme.Opacity.textSecondary))

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(Typography.Command.label)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text(time)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("TertiaryText"))
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Colonnade Suggestion Card

private struct ColonnadeSuggestionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color

    var body: some View {
        Button {
            // Navigate
        } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .fill(accentColor.opacity(Theme.Opacity.overlay))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(Typography.Icon.md.weight(.light))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.Command.label)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text(subtitle)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("TertiaryText"))
                        .lineLimit(2)
                }
            }
            .frame(width: 140)
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Colonnade Home Page") {
    NavigationStack {
        ColonnadeHomePage()
    }
}

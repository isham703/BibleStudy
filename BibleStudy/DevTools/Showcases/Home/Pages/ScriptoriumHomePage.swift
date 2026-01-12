//
//  ScriptoriumHomePage.swift
//  BibleStudy
//
//  Home Page Variation 1: The Scriptorium
//  Manuscript-inspired reading focus with codex-like layout.
//  Emphasizes contemplation, daily verse meditation, and reading continuity.
//

import SwiftUI

// MARK: - Scriptorium Home Page

struct ScriptoriumHomePage: View {
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
                        .frame(height: Theme.Spacing.xxl)

                    // Greeting header
                    greetingHeader
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Daily Verse (Hero)
                    dailyVerseSection
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xxl)

                    // Continue Reading (Primary CTA)
                    continueReadingSection
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Study Tools Row
                    studyToolsRow
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Recent Activity
                    recentActivitySection
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Suggested Next
                    suggestedNextSection
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

            // Parchment-like subtle warmth from center
            RadialGradient(
                colors: [
                    Color("AccentBronze").opacity(Theme.Opacity.subtle / 3),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.3),
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Date
            Text(SanctuaryMockData.formattedDate.uppercased())
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.sectionTracking)
                .foregroundStyle(Color("TertiaryText"))

            // Greeting
            Text(SanctuaryMockData.fullGreeting)
                .font(Typography.Scripture.title)
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 10)
        .animation(Theme.Animation.slowFade.delay(0.1), value: isAwakened)
    }

    // MARK: - Daily Verse Section (Hero)

    private var dailyVerseSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Section label
            HStack {
                Text("TODAY'S MEDITATION")
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.labelTracking)
                    .foregroundStyle(Color("AccentBronze"))

                Spacer()
            }

            // Verse card with illuminated styling
            VStack(spacing: Theme.Spacing.lg) {
                // Opening illuminated mark
                Text("\u{201C}")
                    .font(Typography.Decorative.dropCapCompact)
                    .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.textSecondary))
                    .frame(height: Theme.Spacing.xl)

                // Verse text
                Text(dailyVerse.text)
                    .font(Typography.Scripture.prompt)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(Typography.Scripture.promptLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)

                // Reference
                Text(dailyVerse.reference.uppercased())
                    .font(Typography.Command.caption)
                    .tracking(Typography.Editorial.sectionTracking)
                    .foregroundStyle(Color("AccentBronze"))

                // Reflect CTA
                Button {
                    // Action
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "text.quote")
                            .font(Typography.Icon.sm)
                        Text("Reflect")
                            .font(Typography.Command.cta)
                    }
                    .foregroundStyle(Color("AppAccentAction"))
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(
                        Capsule()
                            .stroke(Color("AppAccentAction").opacity(Theme.Opacity.textTertiary), lineWidth: Theme.Stroke.hairline)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, Theme.Spacing.xxl)
            .padding(.horizontal, Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(
                        Color("AccentBronze").opacity(colorScheme == .dark ? 0.2 : 0.15),
                        lineWidth: Theme.Stroke.hairline
                    )
            )
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(Theme.Animation.slowFade.delay(0.2), value: isAwakened)
    }

    // MARK: - Continue Reading Section

    private var continueReadingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section label
            Text("CONTINUE READING")
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.labelTracking)
                .foregroundStyle(Color("TertiaryText"))

            // Reading card
            Button {
                // Navigate to reader
            } label: {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    // Plan info
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(readingPlan.title)
                                .font(Typography.Scripture.heading)
                                .foregroundStyle(Color("AppTextPrimary"))

                            Text("Day \(readingPlan.currentDay) of \(readingPlan.totalDays)")
                                .font(Typography.Command.meta)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }

                        Spacer()

                        // Progress percentage
                        Text("\(readingPlan.progressPercentage)%")
                            .font(Typography.Command.headline)
                            .foregroundStyle(Color("AccentBronze"))
                    }

                    // Today's passage
                    Text(readingPlan.todayReference)
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("AppTextSecondary"))

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: Theme.Radius.xs)
                                .fill(Color.appDivider)
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: Theme.Radius.xs)
                                .fill(Color("AccentBronze"))
                                .frame(width: geometry.size.width * readingPlan.progress, height: 6)
                        }
                    }
                    .frame(height: 6)

                    // CTA row
                    HStack {
                        Spacer()
                        HStack(spacing: Theme.Spacing.xs) {
                            Text("Continue")
                                .font(Typography.Command.cta)
                            Image(systemName: "arrow.right")
                                .font(Typography.Icon.xs)
                        }
                        .foregroundStyle(Color("AppAccentAction"))
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
        .animation(Theme.Animation.slowFade.delay(0.3), value: isAwakened)
    }

    // MARK: - Study Tools Row

    private var studyToolsRow: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section label
            Text("STUDY TOOLS")
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.labelTracking)
                .foregroundStyle(Color("TertiaryText"))

            HStack(spacing: Theme.Spacing.md) {
                // Sermon
                ScriptoriumToolButton(
                    icon: "mic.fill",
                    label: "Sermon",
                    subtitle: "Record & analyze"
                )

                // Notes
                ScriptoriumToolButton(
                    icon: "note.text",
                    label: "Notes",
                    subtitle: "Your reflections"
                )

                // Insights
                ScriptoriumToolButton(
                    icon: "sparkles",
                    label: "Insights",
                    subtitle: "AI guidance"
                )
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(Theme.Animation.slowFade.delay(0.4), value: isAwakened)
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section label
            Text("RECENT ACTIVITY")
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.labelTracking)
                .foregroundStyle(Color("TertiaryText"))

            VStack(spacing: 0) {
                // History item 1
                ScriptoriumActivityRow(
                    icon: "bookmark.fill",
                    title: "John 3:16-21",
                    subtitle: "Bookmarked yesterday",
                    showDivider: true
                )

                // History item 2
                ScriptoriumActivityRow(
                    icon: "highlighter",
                    title: "Romans 8:28",
                    subtitle: "Highlighted 2 days ago",
                    showDivider: true
                )

                // History item 3
                ScriptoriumActivityRow(
                    icon: "note.text",
                    title: "Psalm 23 reflection",
                    subtitle: "Note from last week",
                    showDivider: false
                )
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)
            )
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(Theme.Animation.slowFade.delay(0.5), value: isAwakened)
    }

    // MARK: - Suggested Next Section

    private var suggestedNextSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section label
            HStack {
                Text("SUGGESTED FOR YOU")
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

            // Suggestion card
            Button {
                // Navigate
            } label: {
                HStack(spacing: Theme.Spacing.md) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.Radius.input)
                            .fill(Color("FeedbackInfo").opacity(Theme.Opacity.overlay))
                            .frame(width: 48, height: 48)

                        Image(systemName: "lightbulb.fill")
                            .font(Typography.Icon.lg.weight(.light))
                            .foregroundStyle(Color("FeedbackInfo"))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Topic Study: Grace")
                            .font(Typography.Command.headline)
                            .foregroundStyle(Color("AppTextPrimary"))

                        Text("Explore grace across Scripture")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
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
                        .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)
                )
            }
            .buttonStyle(.plain)
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(Theme.Animation.slowFade.delay(0.6), value: isAwakened)
    }
}

// MARK: - Scriptorium Tool Button

private struct ScriptoriumToolButton: View {
    let icon: String
    let label: String
    let subtitle: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            // Action
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(Typography.Icon.lg.weight(.light))
                    .foregroundStyle(Color("AppAccentAction"))
                    .frame(width: 40, height: 40)

                VStack(spacing: 2) {
                    Text(label)
                        .font(Typography.Command.label)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text(subtitle)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("TertiaryText"))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
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

// MARK: - Scriptorium Activity Row

private struct ScriptoriumActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let showDivider: Bool

    var body: some View {
        Button {
            // Navigate
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: icon)
                        .font(Typography.Icon.sm.weight(.medium))
                        .foregroundStyle(Color("AppAccentAction").opacity(Theme.Opacity.textSecondary))
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(Typography.Command.body)
                            .foregroundStyle(Color("AppTextPrimary"))

                        Text(subtitle)
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("TertiaryText"))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("TertiaryText"))
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)

                if showDivider {
                    Rectangle()
                        .fill(Color.appDivider)
                        .frame(height: Theme.Stroke.hairline)
                        .padding(.leading, Theme.Spacing.md + 24 + Theme.Spacing.md)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Scriptorium Home Page") {
    NavigationStack {
        ScriptoriumHomePage()
    }
}

//
//  ThresholdHomePage.swift
//  BibleStudy
//
//  Home Page Variation 3: The Threshold
//  Minimal contemplative space with maximum breathing room.
//  Single focal point design for calm entry into daily practice.
//

import SwiftUI

// MARK: - Threshold Home Page

struct ThresholdHomePage: View {
    @State private var isAwakened = false
    @State private var showMoreActions = false
    @Environment(\.colorScheme) private var colorScheme

    // Mock data
    private let dailyVerse = SanctuaryMockData.dailyVerse
    private let readingPlan = SanctuaryMockData.activePlan

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            // Main content
            VStack(spacing: 0) {
                // Top section with greeting
                topSection
                    .padding(.top, Theme.Spacing.xxl)

                Spacer()

                // Central focus area
                centralFocus
                    .padding(.horizontal, Theme.Spacing.xl)

                Spacer()

                // Bottom actions
                bottomActions
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.bottom, Theme.Spacing.xxl)
            }

            // Expandable drawer
            if showMoreActions {
                actionsDrawer
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(Theme.Animation.slowFade) {
                isAwakened = true
            }
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            // Subtle center glow
            RadialGradient(
                colors: [
                    Color("AccentBronze").opacity(Theme.Opacity.subtle / 4),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Very subtle vignette
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.appBackground.opacity(Theme.Opacity.textTertiary)
                ],
                center: .center,
                startRadius: 200,
                endRadius: 600
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Top Section

    private var topSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Date
            Text(SanctuaryMockData.formattedDate.uppercased())
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.sectionTracking)
                .foregroundStyle(Color("TertiaryText"))

            // Greeting
            Text(SanctuaryMockData.fullGreeting)
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : -10)
        .animation(Theme.Animation.slowFade.delay(0.1), value: isAwakened)
    }

    // MARK: - Central Focus

    private var centralFocus: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            // Daily Verse (Hero element)
            dailyVerseHero

            // Reading continuation
            readingContinuation
        }
    }

    // MARK: - Daily Verse Hero

    private var dailyVerseHero: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Opening mark
            Text("\u{201C}")
                .font(Typography.Decorative.dropCap)
                .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.textTertiary))
                .frame(height: Theme.Spacing.xxl)

            // Verse text
            Text(dailyVerse.text)
                .font(Typography.Scripture.title)
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)
                .lineSpacing(Typography.Scripture.titleLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: Theme.Reading.maxWidth)

            // Reference
            Text(dailyVerse.reference.uppercased())
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.sectionTracking)
                .foregroundStyle(Color("AccentBronze"))

            // Meditate button
            Button {
                // Navigate to meditation
            } label: {
                Text("Meditate")
                    .font(Typography.Command.cta)
                    .foregroundStyle(Color("AppAccentAction"))
            }
            .padding(.top, Theme.Spacing.sm)
        }
        .opacity(isAwakened ? 1 : 0)
        .scaleEffect(isAwakened ? 1 : 0.95)
        .animation(Theme.Animation.slowFade.delay(0.2), value: isAwakened)
    }

    // MARK: - Reading Continuation

    private var readingContinuation: some View {
        Button {
            // Navigate to reader
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                // Divider ornament
                HStack(spacing: Theme.Spacing.md) {
                    Rectangle()
                        .fill(Color.appDivider)
                        .frame(width: Theme.Spacing.xl, height: Theme.Stroke.hairline)

                    Circle()
                        .fill(Color("AccentBronze").opacity(Theme.Opacity.textTertiary))
                        .frame(width: 4, height: 4)

                    Rectangle()
                        .fill(Color.appDivider)
                        .frame(width: Theme.Spacing.xl, height: Theme.Stroke.hairline)
                }
                .padding(.bottom, Theme.Spacing.md)

                // Label
                Text("CONTINUE READING")
                    .font(Typography.Command.caption)
                    .tracking(Typography.Editorial.labelTracking)
                    .foregroundStyle(Color("TertiaryText"))

                // Plan title
                Text(readingPlan.title)
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                // Progress
                HStack(spacing: Theme.Spacing.sm) {
                    Text(readingPlan.todayReference)
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("AppTextSecondary"))

                    Text("·")
                        .foregroundStyle(Color("TertiaryText"))

                    Text("Day \(readingPlan.currentDay)")
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("AccentBronze"))
                }

                // Subtle progress indicator
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(0..<10, id: \.self) { index in
                        Circle()
                            .fill(
                                index < Int(readingPlan.progress * 10)
                                    ? Color("AccentBronze")
                                    : Color.appDivider
                            )
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .buttonStyle(.plain)
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 20)
        .animation(Theme.Animation.slowFade.delay(0.4), value: isAwakened)
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Primary CTA
            Button {
                // Begin reading
            } label: {
                Text("Begin")
                    .font(Typography.Command.cta)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Color("AppAccentAction"))
                    .clipShape(Capsule())
            }

            // More options
            Button {
                withAnimation(Theme.Animation.settle) {
                    showMoreActions = true
                }
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Text("More")
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("AppTextSecondary"))

                    Image(systemName: "chevron.up")
                        .font(Typography.Icon.xs)
                        .foregroundStyle(Color("TertiaryText"))
                }
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 20)
        .animation(Theme.Animation.slowFade.delay(0.5), value: isAwakened)
    }

    // MARK: - Actions Drawer

    private var actionsDrawer: some View {
        ZStack {
            // Scrim
            Color.black
                .opacity(Theme.Opacity.overlay * 3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(Theme.Animation.settle) {
                        showMoreActions = false
                    }
                }

            // Drawer
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: Theme.Spacing.md) {
                    // Handle
                    RoundedRectangle(cornerRadius: Theme.Radius.xs)
                        .fill(Color.appDivider)
                        .frame(width: 36, height: 4)
                        .padding(.top, Theme.Spacing.sm)

                    // Title
                    Text("Quick Actions")
                        .font(Typography.Command.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding(.top, Theme.Spacing.sm)

                    // Divider
                    Rectangle()
                        .fill(Color.appDivider)
                        .frame(height: Theme.Stroke.hairline)
                        .padding(.horizontal, Theme.Spacing.lg)

                    // Actions grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Theme.Spacing.lg) {
                        ThresholdQuickAction(icon: "book.fill", label: "Scripture")
                        ThresholdQuickAction(icon: "text.quote", label: "Reflect")
                        ThresholdQuickAction(icon: "hands.sparkles.fill", label: "Pray")
                        ThresholdQuickAction(icon: "mic.fill", label: "Sermon")
                        ThresholdQuickAction(icon: "moon.stars.fill", label: "Compline")
                        ThresholdQuickAction(icon: "wind", label: "Breathe")
                    }
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.vertical, Theme.Spacing.lg)

                    // Recent section
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("RECENT")
                            .font(Typography.Command.meta)
                            .tracking(Typography.Editorial.labelTracking)
                            .foregroundStyle(Color("TertiaryText"))
                            .padding(.horizontal, Theme.Spacing.lg)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.Spacing.md) {
                                ThresholdRecentItem(title: "John 3:16", subtitle: "Bookmarked")
                                ThresholdRecentItem(title: "Romans 8:28", subtitle: "Highlighted")
                                ThresholdRecentItem(title: "Psalm 23", subtitle: "Note")
                            }
                            .padding(.horizontal, Theme.Spacing.lg)
                        }
                    }
                    .padding(.bottom, Theme.Spacing.lg)

                    // Suggested
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("SUGGESTED")
                            .font(Typography.Command.meta)
                            .tracking(Typography.Editorial.labelTracking)
                            .foregroundStyle(Color("TertiaryText"))
                            .padding(.horizontal, Theme.Spacing.lg)

                        Button {
                            // Navigate
                        } label: {
                            HStack(spacing: Theme.Spacing.md) {
                                Image(systemName: "lightbulb.fill")
                                    .font(Typography.Icon.md)
                                    .foregroundStyle(Color("FeedbackInfo"))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Topic Study: Grace")
                                        .font(Typography.Command.body)
                                        .foregroundStyle(Color("AppTextPrimary"))

                                    Text("Explore grace across Scripture")
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
                                    .fill(Color.appSurface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.card)
                                    .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, Theme.Spacing.lg)
                    }
                    .padding(.bottom, Theme.Spacing.xxl)
                }
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sheet)
                        .fill(Color.appBackground)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Threshold Quick Action

private struct ThresholdQuickAction: View {
    let icon: String
    let label: String

    var body: some View {
        Button {
            // Navigate
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(Typography.Icon.lg.weight(.light))
                    .foregroundStyle(Color("AppAccentAction"))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Color("AppAccentAction").opacity(Theme.Opacity.overlay))
                    )

                Text(label)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Threshold Recent Item

private struct ThresholdRecentItem: View {
    let title: String
    let subtitle: String

    var body: some View {
        Button {
            // Navigate
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.Command.label)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text(subtitle)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
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

// MARK: - Preview

#Preview("Threshold Home Page") {
    NavigationStack {
        ThresholdHomePage()
    }
}

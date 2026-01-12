//
//  HomePageShowcaseDirectory.swift
//  BibleStudy
//
//  Internal POC design directory for Home page variations.
//  Allows stakeholders to compare Home page directions side-by-side.
//

import SwiftUI

// MARK: - Home Page Showcase Directory

struct HomePageShowcaseDirectory: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAwakened = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.appBackground
                    .ignoresSafeArea()

                // Subtle radial accent
                RadialGradient(
                    colors: [
                        Color("AccentBronze").opacity(Theme.Opacity.subtle / 2),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 500
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header section
                        headerSection
                            .padding(.top, Theme.Spacing.xxl)
                            .padding(.bottom, Theme.Spacing.xl)

                        // Variation cards
                        variationCards
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.bottom, Theme.Spacing.xxl * 2)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(Typography.Icon.md.weight(.medium))
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
            }
        }
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Title
            Text("Home Options")
                .font(Typography.Scripture.title)
                .foregroundStyle(Color("AppTextPrimary"))
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.1), value: isAwakened)

            // Subtitle
            Text("Three distinct approaches to the sanctuary experience")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xxl)
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.2), value: isAwakened)

            // Divider ornament
            HStack(spacing: Theme.Spacing.md) {
                Rectangle()
                    .fill(Color.appDivider)
                    .frame(width: Theme.Spacing.xxl, height: Theme.Stroke.hairline)

                Image(systemName: "building.columns")
                    .font(Typography.Icon.xs.weight(.ultraLight))
                    .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.textTertiary))

                Rectangle()
                    .fill(Color.appDivider)
                    .frame(width: Theme.Spacing.xxl, height: Theme.Stroke.hairline)
            }
            .padding(.top, Theme.Spacing.sm)
            .opacity(isAwakened ? 1 : 0)
            .animation(Theme.Animation.slowFade.delay(0.3), value: isAwakened)
        }
    }

    // MARK: - Variation Cards

    private var variationCards: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Variation 1: The Scriptorium
            NavigationLink {
                ScriptoriumHomePage()
            } label: {
                ShowcaseVariationCard(
                    title: "The Scriptorium",
                    subtitle: "Manuscript-inspired reading focus",
                    description: "Classic codex layout with reading as the primary action. Emphasizes contemplation and daily verse meditation.",
                    icon: "text.book.closed.fill",
                    accentColor: Color("AccentBronze"),
                    index: 0,
                    isAwakened: isAwakened
                )
            }
            .buttonStyle(VariationCardButtonStyle())

            // Variation 2: The Colonnade
            NavigationLink {
                ColonnadeHomePage()
            } label: {
                ShowcaseVariationCard(
                    title: "The Colonnade",
                    subtitle: "Architectural structure and order",
                    description: "Pillar-based navigation with clear hierarchy. Multiple entry points organized by practice type.",
                    icon: "building.columns.fill",
                    accentColor: Color("AppAccentAction"),
                    index: 1,
                    isAwakened: isAwakened
                )
            }
            .buttonStyle(VariationCardButtonStyle())

            // Variation 3: The Threshold
            NavigationLink {
                ThresholdHomePage()
            } label: {
                ShowcaseVariationCard(
                    title: "The Threshold",
                    subtitle: "Minimal contemplative space",
                    description: "Maximum breathing room with a single focal point. Designed for calm entry into daily practice.",
                    icon: "rectangle.portrait.on.rectangle.portrait.angled.fill",
                    accentColor: Color("FeedbackInfo"),
                    index: 2,
                    isAwakened: isAwakened
                )
            }
            .buttonStyle(VariationCardButtonStyle())
        }
    }
}

// MARK: - Showcase Variation Card

private struct ShowcaseVariationCard: View {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let accentColor: Color
    let index: Int
    let isAwakened: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Icon and title row
            HStack(spacing: Theme.Spacing.md) {
                // Icon badge
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .fill(accentColor.opacity(Theme.Opacity.overlay))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(Typography.Icon.lg.weight(.light))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.Scripture.heading)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text(subtitle.uppercased())
                        .font(Typography.Command.meta)
                        .tracking(Typography.Editorial.referenceTracking)
                        .foregroundStyle(Color("TertiaryText"))
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(Typography.Command.body.weight(.medium))
                    .foregroundStyle(Color("TertiaryText"))
            }

            // Hairline divider
            Rectangle()
                .fill(Color.appDivider)
                .frame(height: Theme.Stroke.hairline)

            // Description
            Text(description)
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineSpacing(Typography.Command.bodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)

            // Preview tag
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "eye")
                    .font(Typography.Icon.xxs)
                Text("Tap to preview")
                    .font(Typography.Command.caption)
            }
            .foregroundStyle(accentColor.opacity(Theme.Opacity.textSecondary))
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.appSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(colorScheme == .dark ? 0.3 : 0.2),
                            Color.appDivider
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: Theme.Stroke.hairline
                )
        )
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(Theme.Animation.slowFade.delay(0.3 + Double(index) * 0.1), value: isAwakened)
    }
}

// MARK: - Variation Card Button Style

private struct VariationCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? Theme.Opacity.pressed : 1.0)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Home Page Showcase Directory") {
    HomePageShowcaseDirectory()
}

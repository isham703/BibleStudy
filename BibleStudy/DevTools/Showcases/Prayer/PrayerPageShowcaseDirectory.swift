// PrayerPageShowcaseDirectory.swift
// BibleStudy
//
// Prayer Page Variations Showcase Directory
// Internal POC for comparing Prayer page design directions

import SwiftUI

struct PrayerPageShowcaseDirectory: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAwakened = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection
                            .padding(.top, Theme.Spacing.xxl)
                            .padding(.bottom, Theme.Spacing.xl)

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
            Text("Prayer Options")
                .font(Typography.Scripture.title)
                .foregroundStyle(Color("AppTextPrimary"))
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.1), value: isAwakened)

            Text("AI-crafted prayers from your intentions")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.2), value: isAwakened)

            // Ornamental divider
            HStack(spacing: Theme.Spacing.md) {
                Rectangle()
                    .fill(Color.appDivider)
                    .frame(width: Theme.Spacing.xxl, height: Theme.Stroke.hairline)

                Image(systemName: "hands.and.sparkles")
                    .font(Typography.Icon.xs.weight(.ultraLight))
                    .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.textTertiary))

                Rectangle()
                    .fill(Color.appDivider)
                    .frame(width: Theme.Spacing.xxl, height: Theme.Stroke.hairline)
            }
            .opacity(isAwakened ? 1 : 0)
            .animation(Theme.Animation.slowFade.delay(0.25), value: isAwakened)
        }
    }

    // MARK: - Variation Cards

    private var variationCards: some View {
        VStack(spacing: Theme.Spacing.lg) {
            NavigationLink {
                CloisterPrayerPage()
            } label: {
                PrayerVariationCard(
                    title: "The Cloister",
                    subtitle: "Monastic Discipline",
                    description: "Structured AI prayer generation with tradition selection. Emphasizes reverence, silence, and contemplative flow.",
                    icon: "cross.fill",
                    accentColor: Color("AccentBronze"),
                    index: 0,
                    isAwakened: isAwakened,
                    colorScheme: colorScheme
                )
            }
            .buttonStyle(PrayerCardButtonStyle())

            NavigationLink {
                ScriptoriumPrayerPage()
            } label: {
                PrayerVariationCard(
                    title: "The Scriptorium",
                    subtitle: "Stoic-Roman Style",
                    description: "AI prayer generation with mood-based guidance. Drop caps, warm typography, and Scripture anchoring for a classical feel.",
                    icon: "text.book.closed.fill",
                    accentColor: Color("HighlightAmber"),
                    index: 1,
                    isAwakened: isAwakened,
                    colorScheme: colorScheme
                )
            }
            .buttonStyle(PrayerCardButtonStyle())

            NavigationLink {
                PorticoPrayerPage()
            } label: {
                PrayerVariationCard(
                    title: "The Portico",
                    subtitle: "Modern Clarity",
                    description: "Clean, action-oriented AI prayer generation. Focus-based input with progress feedback and quick actions.",
                    icon: "building.columns.fill",
                    accentColor: Color("HighlightBlue"),
                    index: 2,
                    isAwakened: isAwakened,
                    colorScheme: colorScheme
                )
            }
            .buttonStyle(PrayerCardButtonStyle())
        }
    }
}

// MARK: - Prayer Variation Card

private struct PrayerVariationCard: View {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let accentColor: Color
    let index: Int
    let isAwakened: Bool
    let colorScheme: ColorScheme

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
                .multilineTextAlignment(.leading)
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

// MARK: - Button Style

private struct PrayerCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? Theme.Opacity.pressed : 1.0)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
    }
}

#Preview {
    PrayerPageShowcaseDirectory()
}

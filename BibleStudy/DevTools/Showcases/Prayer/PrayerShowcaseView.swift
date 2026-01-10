//
//  PrayerShowcaseView.swift
//  BibleStudy
//
//  Prayer Creator Feature Showcase - Internal Design Directory
//

import SwiftUI

// MARK: - Prayer Page Option Model

struct PrayerPageOption: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let styleName: String
    let previewGradient: [Color]
    let icon: String
    let pageType: PrayerPageType
}

enum PrayerPageType {
    case contemplativeManuscript
    case modernLuminous
    case sacredMinimal
    case auroraDreams
    case celestialTouch
    case boldFaith
}

// MARK: - Main Showcase Directory View

struct PrayerShowcaseView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPage: PrayerPageOption?
    @State private var showingPage = false

    private let options: [PrayerPageOption] = [
        PrayerPageOption(
            title: "Contemplative Manuscript",
            subtitle: "Illuminated prayer experience with ornate gold accents and flowing calligraphy-inspired typography",
            styleName: "Style A",
            previewGradient: [Color.accentBronze, Color.ochreDeep],
            icon: "book.closed.fill",
            pageType: .contemplativeManuscript
        ),
        PrayerPageOption(
            title: "Modern Luminous",
            subtitle: "Clean, elevated design with subtle gradients, floating elements, and focused AI interaction",
            styleName: "Style B",
            previewGradient: [Color.accentIndigoLight, Color.accentIndigo],
            icon: "sparkles",
            pageType: .modernLuminous
        ),
        PrayerPageOption(
            title: "Sacred Minimal",
            subtitle: "Stripped-back simplicity with gentle breathing animations and meditative whitespace",
            styleName: "Style C",
            previewGradient: [Color.surfaceCharcoal, Color.surfaceWarm],
            icon: "leaf.fill",
            pageType: .sacredMinimal
        ),
        PrayerPageOption(
            title: "Aurora Dreams",
            subtitle: "Mesmerizing northern lights with dark glassmorphism - screenshot-worthy animated gradients",
            styleName: "Style D",
            previewGradient: [Color.purpleAccent, Color(hex: "EC4899")],
            icon: "aurora.northern",
            pageType: .auroraDreams
        ),
        PrayerPageOption(
            title: "Celestial Touch",
            subtitle: "Interactive constellation effects - every keystroke creates a star in your prayer cosmos",
            styleName: "Style E",
            previewGradient: [Color.blueAccent, Color.violetAccent],
            icon: "stars.fill",
            pageType: .celestialTouch
        ),
        PrayerPageOption(
            title: "Bold Faith",
            subtitle: "Neubrutalist rebellion - thick borders, bold colors, raw honesty. God can handle your mess.",
            styleName: "Style F",
            previewGradient: [Color.brightRed, Color(hex: "F97316")],
            icon: "bolt.fill",
            pageType: .boldFaith
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundGradient

                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        headerSection

                        // Options Grid
                        optionsSection

                        // Footer
                        footerSection
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedPage) { page in
                PrayerPageContainer(pageType: page.pageType, pageName: page.title)
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "0F0D0C"),
                Color.surfaceCharcoal,
                Color.surfaceCharcoal
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Decorative Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentBronze.opacity(Theme.Opacity.light), Color.accentBronze.opacity(Theme.Opacity.faint)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "hands.and.sparkles.fill")
                    .font(Typography.Icon.xxl)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentBronze, Color.goldWarm],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 60)

            // Title
            VStack(spacing: 8) {
                Text("Prayer from the Deep")
                    .font(.custom("Cinzel", size: 28))
                    .fontWeight(.medium)
                    .foregroundColor(Color.decorativeMarble)
                    .multilineTextAlignment(.center)

                Text("OPTIONS")
                    .font(Typography.Icon.xxs.weight(.bold))
                    .tracking(3)
                    .foregroundColor(Color.accentIndigo)
            }

            // Subtitle
            Text("Choose a design direction for the AI-powered prayer creation experience")
                .font(.custom("Cormorant Garamond", size: 16))
                .foregroundColor(Color.stoneGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 4)
        }
        .padding(.bottom, 32)
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(spacing: 16) {
            ForEach(options) { option in
                PrayerOptionCard(option: option) {
                    selectedPage = option
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 12) {
            Rectangle()
                .fill(Color.accentBronze.opacity(Theme.Opacity.subtle))
                .frame(width: 40, height: 1)

            Text("Internal Design Directory")
                .font(Typography.Icon.xxs.weight(.medium))
                .tracking(1.5)
                .foregroundColor(Color.stoneGray.opacity(Theme.Opacity.tertiary))

            Text("v1.0 \u{2022} Bible Study App")
                .font(Typography.Icon.xxs)
                .foregroundColor(Color.stoneGray.opacity(Theme.Opacity.lightMedium))
        }
        .padding(.top, 40)
    }
}

// MARK: - Prayer Option Card

struct PrayerOptionCard: View {
    let option: PrayerPageOption
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Preview Gradient Circle
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: option.previewGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: option.icon)
                        .font(Typography.Command.title3)
                        .foregroundColor(.white)
                }

                // Text Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(option.styleName)
                            .font(Typography.Icon.xxs.weight(.bold))
                            .tracking(1.5)
                            .foregroundColor(Color.accentIndigo)

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(Typography.Icon.xs)
                            .foregroundColor(Color.stoneGray)
                    }

                    Text(option.title)
                        .font(.custom("Cinzel", size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(Color.decorativeMarble)

                    Text(option.subtitle)
                        .font(Typography.Command.meta)
                        .foregroundColor(Color.stoneGray)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(Color.surfaceWarm)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.lg)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.accentBronze.opacity(Theme.Opacity.light),
                                        Color.accentBronze.opacity(Theme.Opacity.faint)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color.black.opacity(Theme.Opacity.subtle), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PressableCardStyle())
    }
}

// MARK: - Pressable Card Style

struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Prayer Page Container

struct PrayerPageContainer: View {
    let pageType: PrayerPageType
    let pageName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Page Content
            Group {
                switch pageType {
                case .contemplativeManuscript:
                    ContemplativeManuscriptPage()
                case .modernLuminous:
                    ModernLuminousPage()
                case .sacredMinimal:
                    SacredMinimalPage()
                case .auroraDreams:
                    AuroraDreamsPage()
                case .celestialTouch:
                    CelestialTouchPage()
                case .boldFaith:
                    BoldFaithPage()
                }
            }

            // Close Button - adapts styling based on page type
            VStack {
                HStack {
                    Spacer()

                    Button(action: { dismiss() }) {
                        if pageType == .boldFaith {
                            // Neubrutalist close button for light background
                            ZStack {
                                Rectangle()
                                    .fill(Color.surfaceRaised)
                                    .frame(width: 36, height: 36)
                                    .offset(x: 3, y: 3)

                                Image(systemName: "xmark")
                                    .font(Typography.Command.caption.weight(.bold))
                                    .foregroundColor(Color.surfaceRaised)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white)
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.surfaceRaised, lineWidth: 2)
                                    )
                            }
                        } else {
                            // Default dark-themed close button
                            Image(systemName: "xmark")
                                .font(Typography.Icon.sm)
                                .foregroundColor(Color.decorativeMarble)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(Color.surfaceWarm.opacity(Theme.Opacity.pressed))
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(Theme.Opacity.overlay), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PrayerShowcaseView()
}

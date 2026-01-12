import SwiftUI

// MARK: - Sermon Showcase Directory

/// Main directory for Sermon page design variations.
/// Presents three distinct approaches for stakeholder review.
struct SermonShowcaseDirectory: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAwakened = false

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer

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

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

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
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text("Sermon Options")
                .font(Typography.Scripture.title)
                .foregroundStyle(Color("AppTextPrimary"))
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.1), value: isAwakened)

            Text("Three distinct approaches to sermon listening and study")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xxl)
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.2), value: isAwakened)

            ornamentalDivider
                .padding(.top, Theme.Spacing.sm)
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.3), value: isAwakened)
        }
    }

    private var ornamentalDivider: some View {
        HStack(spacing: Theme.Spacing.md) {
            Rectangle()
                .fill(Color("AppDivider"))
                .frame(width: Theme.Spacing.xxl, height: Theme.Stroke.hairline)

            Image(systemName: "mic.fill")
                .font(Typography.Icon.xs.weight(.ultraLight))
                .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.textTertiary))

            Rectangle()
                .fill(Color("AppDivider"))
                .frame(width: Theme.Spacing.xxl, height: Theme.Stroke.hairline)
        }
    }

    // MARK: - Variation Cards

    private var variationCards: some View {
        VStack(spacing: Theme.Spacing.lg) {
            NavigationLink {
                CodexSermonPage()
            } label: {
                SermonShowcaseCard(
                    title: "The Codex",
                    subtitle: "Manuscript-inspired study layout",
                    description: "Classic page structure with expandable sections. Emphasizes transcript reading alongside audio playback with scholarly annotations.",
                    icon: "text.book.closed.fill",
                    accentColor: Color("AccentBronze"),
                    index: 0,
                    isAwakened: isAwakened
                )
            }
            .buttonStyle(SermonCardButtonStyle())

            NavigationLink {
                AtriumSermonPage()
            } label: {
                SermonShowcaseCard(
                    title: "The Atrium",
                    subtitle: "Open and spacious listening experience",
                    description: "Generous breathing room with audio-first design. Cards float in calm space with clear hierarchy and deliberate pacing.",
                    icon: "rectangle.portrait.on.rectangle.portrait.angled.fill",
                    accentColor: Color("AppAccentAction"),
                    index: 1,
                    isAwakened: isAwakened
                )
            }
            .buttonStyle(SermonCardButtonStyle())

            NavigationLink {
                StudySermonPage()
            } label: {
                SermonShowcaseCard(
                    title: "The Study",
                    subtitle: "Scholar's research workspace",
                    description: "Dense yet organized information architecture. Quick access to transcript, insights, references, and study tools in a unified view.",
                    icon: "books.vertical.fill",
                    accentColor: Color("FeedbackInfo"),
                    index: 2,
                    isAwakened: isAwakened
                )
            }
            .buttonStyle(SermonCardButtonStyle())
        }
    }
}

// MARK: - Showcase Card

private struct SermonShowcaseCard: View {
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
            HStack(spacing: Theme.Spacing.md) {
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

            Rectangle()
                .fill(Color("AppDivider"))
                .frame(height: Theme.Stroke.hairline)

            Text(description)
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineSpacing(Typography.Command.bodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)

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
                .fill(Color("AppSurface"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(colorScheme == .dark ? 0.3 : 0.2),
                            Color("AppDivider")
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

private struct SermonCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? Theme.Opacity.pressed : 1.0)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
    }
}

#Preview {
    SermonShowcaseDirectory()
        .preferredColorScheme(.dark)
}

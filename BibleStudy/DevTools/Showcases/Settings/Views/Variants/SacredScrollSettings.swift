import SwiftUI

// MARK: - Sacred Scroll Settings
/// An immersive, continuous scroll design featuring parallax sections,
/// full-width controls, bold typography, and manuscript-inspired visual layers.

struct SacredScrollSettings: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset: CGFloat = 0

    // Settings State
    @State private var aiInsightsEnabled = true
    @State private var scholarModeEnabled = true
    @State private var personalizedLearning = true
    @State private var fontSize: Double = 18
    @State private var lineSpacing: Double = 1.6
    @State private var selectedTranslation = "ESV"
    @State private var cloudSyncEnabled = true
    @State private var dailyVerseEnabled = true
    @State private var readingReminders = true

    var body: some View {
        ZStack {
            // Layered manuscript background
            manuscriptBackground

            ScrollView {
                VStack(spacing: 0) {
                    heroSection

                    contentSections
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geo.frame(in: .named("scroll")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }

            // Floating back button
            VStack {
                HStack {
                    backButton
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.sm)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
    }

    // MARK: - Manuscript Background

    private var manuscriptBackground: some View {
        ZStack {
            // Base layer
            LinearGradient(
                colors: [
                    Color(hex: "0E0C0A"),
                    Color(hex: "14110F"),
                    Color(hex: "1A1614")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Vellum texture overlay
            VellumTextureView()
                .opacity(Theme.Opacity.faint)
                .ignoresSafeArea()

            // Parallax gold accent strip
            GeometryReader { geometry in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentBronze.opacity(0),
                                Color.accentBronze.opacity(Theme.Opacity.faint),
                                Color.accentBronze.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 300)
                    .offset(y: -scrollOffset * 0.3)
            }
        }
    }

    // MARK: - Back Button

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "chevron.left")
                    .font(Typography.Command.caption.weight(.semibold))
                Text("Back")
                    .font(Typography.body)
            }
            .foregroundStyle(Color.accentBronze)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
                .frame(height: 80)

            // Illuminated title
            VStack(spacing: Theme.Spacing.md) {
                // Decorative cross
                Image(systemName: "cross.fill")
                    .font(Typography.Icon.lg)
                    .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.tertiary))
                    .rotationEffect(.degrees(-scrollOffset * 0.1))

                Text("SETTINGS")
                    .font(.custom("Cinzel-Regular", size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "C9943D"),
                                Color.accentBronze,
                                Color.decorativeCream,
                                Color.accentBronze,
                                Color(hex: "C9943D")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .kerning(8)

                // Subtitle with flourishes
                HStack(spacing: Theme.Spacing.md) {
                    flourishLine

                    Text("Customize Your Journey")
                        .font(.custom("CormorantGaramond-Italic", size: 16))
                        .foregroundStyle(Color.secondaryText)

                    flourishLine
                }
            }
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .frame(height: 320)
    }

    private var flourishLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.clear, Color.accentBronze.opacity(Theme.Opacity.lightMedium), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 40, height: 1)
    }

    // MARK: - Content Sections

    private var contentSections: some View {
        VStack(spacing: 0) {
            // AI & Intelligence
            ScrollSection(
                title: "Divine Intelligence",
                subtitle: "AI-Powered Spiritual Insights"
            ) {
                VStack(spacing: Theme.Spacing.lg) {
                    ImmersiveToggle(
                        title: "Scholar Insights",
                        description: "Receive AI-powered analysis of scripture with historical context, cross-references, and theological depth.",
                        icon: "sparkles",
                        isOn: $aiInsightsEnabled
                    )

                    ImmersiveToggle(
                        title: "Advanced Scholar Mode",
                        description: "Unlock deeper commentary with Greek/Hebrew word studies and scholarly interpretations.",
                        icon: "graduationcap.fill",
                        isOn: $scholarModeEnabled
                    )

                    ImmersiveToggle(
                        title: "Personalized Learning",
                        description: "AI adapts to your reading patterns and provides tailored spiritual growth recommendations.",
                        icon: "brain.head.profile",
                        isOn: $personalizedLearning
                    )
                }
            }

            // Reading Experience
            ScrollSection(
                title: "The Written Word",
                subtitle: "Typography & Reading"
            ) {
                VStack(spacing: Theme.Spacing.xxl) {
                    // Font Size
                    ImmersiveSlider(
                        title: "Scripture Size",
                        value: $fontSize,
                        range: 12...32,
                        icon: "textformat.size"
                    ) {
                        Text("In the beginning God created the heaven and the earth.")
                            .font(.system(size: fontSize))
                            .foregroundStyle(Color.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.lg)
                    }

                    // Line Spacing
                    ImmersiveSlider(
                        title: "Line Height",
                        value: $lineSpacing,
                        range: 1.2...2.2,
                        icon: "text.alignleft"
                    ) {
                        VStack(spacing: lineSpacing * 12) {
                            Text("And the earth was without form,")
                            Text("and void; and darkness was")
                            Text("upon the face of the deep.")
                        }
                        .font(Typography.Command.callout)
                        .foregroundStyle(Color.tertiaryText)
                        .multilineTextAlignment(.center)
                    }

                    // Translation Selector
                    TranslationSelector(selected: $selectedTranslation)
                }
            }

            // Sync & Account
            ScrollSection(
                title: "Cloud of Witnesses",
                subtitle: "Sync & Account"
            ) {
                VStack(spacing: Theme.Spacing.lg) {
                    ImmersiveToggle(
                        title: "Heavenly Sync",
                        description: "Keep your highlights, notes, and reading progress synchronized across all your devices.",
                        icon: "icloud.fill",
                        isOn: $cloudSyncEnabled
                    )

                    // Account card
                    AccountCard()
                }
            }

            // Notifications
            ScrollSection(
                title: "Daily Bread",
                subtitle: "Reminders & Notifications"
            ) {
                VStack(spacing: Theme.Spacing.lg) {
                    ImmersiveToggle(
                        title: "Morning Verse",
                        description: "Start each day with an inspiring verse delivered to your lock screen.",
                        icon: "sun.horizon.fill",
                        isOn: $dailyVerseEnabled
                    )

                    ImmersiveToggle(
                        title: "Reading Reminders",
                        description: "Gentle nudges to maintain your spiritual reading habit.",
                        icon: "bell.badge.fill",
                        isOn: $readingReminders
                    )
                }
            }

            // Footer
            footerSection
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Ornamental footer
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "book.closed.fill")
                    .font(Typography.Icon.xl)
                    .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.lightMedium))

                Text("BIBLE STUDY")
                    .font(.custom("Cinzel-Regular", size: 14))
                    .foregroundStyle(Color.tertiaryText)
                    .kerning(4)

                Text("Sacred Scroll Design")
                    .font(Typography.caption)
                    .foregroundStyle(Color.tertiaryText.opacity(Theme.Opacity.tertiary))
            }
        }
        .padding(.vertical, Theme.Spacing.xxl)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.surfaceDeep],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Scroll Section

struct ScrollSection<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            // Section header
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(subtitle.uppercased())
                    .font(Typography.Icon.xxs.weight(.medium))
                    .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.heavy))
                    .kerning(2)

                Text(title)
                    .font(.custom("Cinzel-Regular", size: 28))
                    .foregroundStyle(Color.primaryText)
            }
            .padding(.horizontal, Theme.Spacing.xl)

            // Decorative line
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.accentBronze)
                    .frame(width: 40, height: 2)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentBronze.opacity(Theme.Opacity.medium), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }
            .padding(.horizontal, Theme.Spacing.xl)

            // Content
            content
                .padding(.horizontal, Theme.Spacing.xl)
        }
        .padding(.vertical, Theme.Spacing.xxl)
    }
}

// MARK: - Immersive Toggle

struct ImmersiveToggle: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(alignment: .top, spacing: Theme.Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            isOn
                                ? Color.accentBronze.opacity(Theme.Opacity.divider)
                                : Color.white.opacity(Theme.Opacity.faint)
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(Typography.Command.title3)
                        .foregroundStyle(isOn ? Color.accentBronze : Color.secondaryText)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(title)
                        .font(.custom("Cinzel-Regular", size: 18))
                        .foregroundStyle(Color.primaryText)

                    Text(description)
                        .font(Typography.footnote)
                        .foregroundStyle(Color.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            // Full-width toggle track
            Button {
                withAnimation(Theme.Animation.settle) {
                    isOn.toggle()
                }
            } label: {
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? Color.accentBronze.opacity(Theme.Opacity.light) : Color.white.opacity(Theme.Opacity.faint))
                        .frame(height: 40)
                        .overlay {
                            Capsule()
                                .strokeBorder(
                                    isOn ? Color.accentBronze.opacity(Theme.Opacity.lightMedium) : Color.white.opacity(Theme.Opacity.overlay),
                                    lineWidth: 1
                                )
                        }

                    // Thumb
                    HStack {
                        if isOn {
                            Spacer()
                        }

                        HStack(spacing: Theme.Spacing.sm) {
                            if isOn {
                                Text("ENABLED")
                                    .font(Typography.Icon.xxs.weight(.bold))
                                    .foregroundStyle(Color.accentBronze)
                            }

                            Circle()
                                .fill(isOn ? Color.accentBronze : Color.white.opacity(Theme.Opacity.subtle))
                                .frame(width: 32, height: 32)
                                .shadow(color: isOn ? Color.accentBronze.opacity(Theme.Opacity.medium) : .clear, radius: 8)

                            if !isOn {
                                Text("DISABLED")
                                    .font(Typography.Icon.xxs.weight(.medium))
                                    .foregroundStyle(Color.tertiaryText)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.sm)

                        if !isOn {
                            Spacer()
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Color.white.opacity(Theme.Opacity.faint))
        )
    }
}

// MARK: - Immersive Slider

struct ImmersiveSlider<Preview: View>: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let icon: String
    @ViewBuilder let preview: Preview

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            HStack {
                Image(systemName: icon)
                    .font(Typography.Icon.base)
                    .foregroundStyle(Color.accentBronze)

                Text(title)
                    .font(.custom("Cinzel-Regular", size: 16))
                    .foregroundStyle(Color.primaryText)

                Spacer()

                Text(String(format: "%.1f", value))
                    .font(Typography.monospacedBody)
                    .foregroundStyle(Color.accentBronze)
            }

            // Preview
            preview
                .frame(minHeight: 60)
                .padding(.vertical, Theme.Spacing.md)

            // Slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.white.opacity(Theme.Opacity.overlay))
                        .frame(height: 8)

                    // Filled portion
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentBronze.opacity(Theme.Opacity.tertiary), Color.accentBronze],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: thumbOffset(in: geometry.size.width), height: 8)

                    // Thumb
                    ZStack {
                        Circle()
                            .fill(Color.accentBronze)
                            .frame(width: 28, height: 28)
                            .shadow(color: Color.accentBronze.opacity(Theme.Opacity.medium), radius: 10)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                    }
                    .offset(x: thumbOffset(in: geometry.size.width) - 14)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newValue = Double(gesture.location.x / geometry.size.width)
                                let clampedValue = min(max(newValue, 0), 1)
                                value = range.lowerBound + clampedValue * (range.upperBound - range.lowerBound)
                            }
                    )
                }
            }
            .frame(height: 28)
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Color.white.opacity(Theme.Opacity.faint))
        )
    }

    private func thumbOffset(in width: CGFloat) -> CGFloat {
        let percentage = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return CGFloat(percentage) * width
    }
}

// MARK: - Translation Selector

struct TranslationSelector: View {
    @Binding var selected: String

    private let translations = ["ESV", "NIV", "KJV", "NASB", "NLT"]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "book.fill")
                    .font(Typography.Icon.base)
                    .foregroundStyle(Color.accentBronze)

                Text("Translation")
                    .font(.custom("Cinzel-Regular", size: 16))
                    .foregroundStyle(Color.primaryText)
            }

            // Horizontal scroll of translations
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(translations, id: \.self) { translation in
                        Button {
                            withAnimation(Theme.Animation.settle) {
                                selected = translation
                            }
                        } label: {
                            Text(translation)
                                .font(.custom("Cinzel-Regular", size: 14))
                                .foregroundStyle(
                                    selected == translation
                                        ? Color.accentBronze
                                        : Color.secondaryText
                                )
                                .padding(.horizontal, Theme.Spacing.lg)
                                .padding(.vertical, Theme.Spacing.md)
                                .background {
                                    if selected == translation {
                                        RoundedRectangle(cornerRadius: Theme.Radius.input)
                                            .fill(Color.accentBronze.opacity(Theme.Opacity.divider))
                                            .overlay {
                                                RoundedRectangle(cornerRadius: Theme.Radius.input)
                                                    .strokeBorder(Color.accentBronze.opacity(Theme.Opacity.lightMedium), lineWidth: 1)
                                            }
                                    } else {
                                        RoundedRectangle(cornerRadius: Theme.Radius.input)
                                            .fill(Color.white.opacity(Theme.Opacity.faint))
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Color.white.opacity(Theme.Opacity.faint))
        )
    }
}

// MARK: - Account Card

struct AccountCard: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            HStack(spacing: Theme.Spacing.lg) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentBronze.opacity(Theme.Opacity.subtle), Color.accentBronze.opacity(Theme.Opacity.overlay)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Text("JS")
                        .font(.custom("Cinzel-Regular", size: 22))
                        .foregroundStyle(Color.accentBronze)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("John Smith")
                        .font(.custom("Cinzel-Regular", size: 18))
                        .foregroundStyle(Color.primaryText)

                    Text("john.smith@email.com")
                        .font(Typography.footnote)
                        .foregroundStyle(Color.tertiaryText)

                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "crown.fill")
                            .font(Typography.Icon.xxs)
                        Text("Premium Member")
                            .font(Typography.Icon.xxs.weight(.medium))
                    }
                    .foregroundStyle(Color.accentBronze)
                    .padding(.top, 2)
                }

                Spacer()
            }

            // Account actions
            HStack(spacing: Theme.Spacing.md) {
                AccountAction(title: "Manage", icon: "gearshape.fill")
                AccountAction(title: "Subscription", icon: "crown.fill")
                AccountAction(title: "Sign Out", icon: "rectangle.portrait.and.arrow.right", isDestructive: true)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Color.white.opacity(Theme.Opacity.faint))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .strokeBorder(Color.accentBronze.opacity(Theme.Opacity.overlay), lineWidth: 1)
                }
        )
    }
}

struct AccountAction: View {
    let title: String
    let icon: String
    var isDestructive: Bool = false

    var body: some View {
        Button {
            // Action
        } label: {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(Typography.Command.callout)
                Text(title)
                    .font(Typography.Icon.xxs.weight(.medium))
            }
            .foregroundStyle(isDestructive ? Color(hex: "C94A4A") : Color.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(Color.white.opacity(Theme.Opacity.faint))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Vellum Texture View

struct VellumTextureView: View {
    var body: some View {
        Canvas { context, size in
            for _ in 0..<500 {
                let x = Double.random(in: 0...size.width)
                let y = Double.random(in: 0...size.height)
                let opacity = Double.random(in: 0.02...0.08)

                context.opacity = opacity
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)),
                    with: .color(.white)
                )
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SacredScrollSettings()
    }
}

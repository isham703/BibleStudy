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
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.sm)

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
                .opacity(0.03)
                .ignoresSafeArea()

            // Parallax gold accent strip
            GeometryReader { geometry in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.divineGold.opacity(0.0),
                                Color.divineGold.opacity(0.05),
                                Color.divineGold.opacity(0.0)
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
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                Text("Back")
                    .font(Typography.body)
            }
            .foregroundStyle(Color.divineGold)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
                .frame(height: 80)

            // Illuminated title
            VStack(spacing: AppTheme.Spacing.md) {
                // Decorative cross
                Image(systemName: "cross.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.divineGold.opacity(0.6))
                    .rotationEffect(.degrees(-scrollOffset * 0.1))

                Text("SETTINGS")
                    .font(.custom("Cinzel-Regular", size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "C9943D"),
                                Color.divineGold,
                                Color(hex: "F5E6B8"),
                                Color.divineGold,
                                Color(hex: "C9943D")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .kerning(8)

                // Subtitle with flourishes
                HStack(spacing: AppTheme.Spacing.md) {
                    flourishLine

                    Text("Customize Your Journey")
                        .font(.custom("CormorantGaramond-Italic", size: 16))
                        .foregroundStyle(Color.secondaryText)

                    flourishLine
                }
            }
            .padding(.bottom, AppTheme.Spacing.xxxl)
        }
        .frame(height: 320)
    }

    private var flourishLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.clear, Color.divineGold.opacity(0.4), Color.clear],
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
                VStack(spacing: AppTheme.Spacing.lg) {
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
                VStack(spacing: AppTheme.Spacing.xxl) {
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
                            .padding(.horizontal, AppTheme.Spacing.lg)
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
                        .font(.system(size: 16))
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
                VStack(spacing: AppTheme.Spacing.lg) {
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
                VStack(spacing: AppTheme.Spacing.lg) {
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
        VStack(spacing: AppTheme.Spacing.xl) {
            // Ornamental footer
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.divineGold.opacity(0.4))

                Text("BIBLE STUDY")
                    .font(.custom("Cinzel-Regular", size: 14))
                    .foregroundStyle(Color.tertiaryText)
                    .kerning(4)

                Text("Sacred Scroll Design")
                    .font(Typography.caption)
                    .foregroundStyle(Color.tertiaryText.opacity(0.6))
            }
        }
        .padding(.vertical, AppTheme.Spacing.xxxl)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.clear, Color(hex: "0A0908")],
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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
            // Section header
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(subtitle.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.divineGold.opacity(0.7))
                    .kerning(2)

                Text(title)
                    .font(.custom("Cinzel-Regular", size: 28))
                    .foregroundStyle(Color.primaryText)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)

            // Decorative line
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.divineGold)
                    .frame(width: 40, height: 2)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.divineGold.opacity(0.5), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)

            // Content
            content
                .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .padding(.vertical, AppTheme.Spacing.xxxl)
    }
}

// MARK: - Immersive Toggle

struct ImmersiveToggle: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            isOn
                                ? Color.divineGold.opacity(0.15)
                                : Color.white.opacity(0.05)
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(isOn ? Color.divineGold : Color.secondaryText)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
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
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isOn.toggle()
                }
            } label: {
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? Color.divineGold.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(height: 40)
                        .overlay {
                            Capsule()
                                .strokeBorder(
                                    isOn ? Color.divineGold.opacity(0.4) : Color.white.opacity(0.1),
                                    lineWidth: 1
                                )
                        }

                    // Thumb
                    HStack {
                        if isOn {
                            Spacer()
                        }

                        HStack(spacing: AppTheme.Spacing.sm) {
                            if isOn {
                                Text("ENABLED")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.divineGold)
                            }

                            Circle()
                                .fill(isOn ? Color.divineGold : Color.white.opacity(0.3))
                                .frame(width: 32, height: 32)
                                .shadow(color: isOn ? Color.divineGold.opacity(0.5) : .clear, radius: 8)

                            if !isOn {
                                Text("DISABLED")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.tertiaryText)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.sm)

                        if !isOn {
                            Spacer()
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                .fill(Color.white.opacity(0.02))
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
        VStack(spacing: AppTheme.Spacing.lg) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.divineGold)

                Text(title)
                    .font(.custom("Cinzel-Regular", size: 16))
                    .foregroundStyle(Color.primaryText)

                Spacer()

                Text(String(format: "%.1f", value))
                    .font(Typography.monospacedBody)
                    .foregroundStyle(Color.divineGold)
            }

            // Preview
            preview
                .frame(minHeight: 60)
                .padding(.vertical, AppTheme.Spacing.md)

            // Slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    // Filled portion
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.divineGold.opacity(0.6), Color.divineGold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: thumbOffset(in: geometry.size.width), height: 8)

                    // Thumb
                    ZStack {
                        Circle()
                            .fill(Color.divineGold)
                            .frame(width: 28, height: 28)
                            .shadow(color: Color.divineGold.opacity(0.5), radius: 10)

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
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                .fill(Color.white.opacity(0.02))
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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.divineGold)

                Text("Translation")
                    .font(.custom("Cinzel-Regular", size: 16))
                    .foregroundStyle(Color.primaryText)
            }

            // Horizontal scroll of translations
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(translations, id: \.self) { translation in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selected = translation
                            }
                        } label: {
                            Text(translation)
                                .font(.custom("Cinzel-Regular", size: 14))
                                .foregroundStyle(
                                    selected == translation
                                        ? Color.divineGold
                                        : Color.secondaryText
                                )
                                .padding(.horizontal, AppTheme.Spacing.lg)
                                .padding(.vertical, AppTheme.Spacing.md)
                                .background {
                                    if selected == translation {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.divineGold.opacity(0.15))
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .strokeBorder(Color.divineGold.opacity(0.4), lineWidth: 1)
                                            }
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.03))
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                .fill(Color.white.opacity(0.02))
        )
    }
}

// MARK: - Account Card

struct AccountCard: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            HStack(spacing: AppTheme.Spacing.lg) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.divineGold.opacity(0.3), Color.divineGold.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Text("JS")
                        .font(.custom("Cinzel-Regular", size: 22))
                        .foregroundStyle(Color.divineGold)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text("John Smith")
                        .font(.custom("Cinzel-Regular", size: 18))
                        .foregroundStyle(Color.primaryText)

                    Text("john.smith@email.com")
                        .font(Typography.footnote)
                        .foregroundStyle(Color.tertiaryText)

                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                        Text("Premium Member")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(Color.divineGold)
                    .padding(.top, AppTheme.Spacing.xxs)
                }

                Spacer()
            }

            // Account actions
            HStack(spacing: AppTheme.Spacing.md) {
                AccountAction(title: "Manage", icon: "gearshape.fill")
                AccountAction(title: "Subscription", icon: "crown.fill")
                AccountAction(title: "Sign Out", icon: "rectangle.portrait.and.arrow.right", isDestructive: true)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                .fill(Color.white.opacity(0.02))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                        .strokeBorder(Color.divineGold.opacity(0.1), lineWidth: 1)
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
            VStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(isDestructive ? Color(hex: "C94A4A") : Color.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.03))
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

import SwiftUI

// MARK: - Floating Sanctuary Settings
/// A bold, innovative settings design featuring elevated floating cards
/// with ambient gold glow effects, contextual groupings, and a floating
/// quick-access navigation bar.

struct FloatingSanctuarySettings: View {
    @Environment(\.dismiss) private var dismiss
    @State private var activeSection: SanctuarySection = .ai
    @State private var scrollOffset: CGFloat = 0
    @State private var showQuickNav = true

    // Settings State
    @State private var aiInsightsEnabled = true
    @State private var scholarModeEnabled = false
    @State private var voiceGuidanceEnabled = false
    @State private var fontSize: Double = 18
    @State private var selectedTheme: AppThemeOption = .dark
    @State private var hapticFeedback = true
    @State private var cloudSyncEnabled = true
    @State private var notificationsEnabled = true
    @State private var dailyVerseEnabled = true

    var body: some View {
        ZStack {
            // Ambient background
            ambientBackground

            // Main content
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xxl) {
                        headerSection

                        // AI Section
                        sectionAnchor(.ai)
                        aiSection

                        // Reading Section
                        sectionAnchor(.reading)
                        readingSection

                        // Account Section
                        sectionAnchor(.account)
                        accountSection

                        // More Section
                        sectionAnchor(.more)
                        moreSection

                        footerSection
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, 100)
                    .padding(.bottom, 120)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: ScrollOffsetKey.self,
                                value: geo.frame(in: .named("scroll")).minY
                            )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetKey.self) { value in
                    scrollOffset = value
                }
                .onChange(of: activeSection) { _, newSection in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(newSection, anchor: .top)
                    }
                }
            }

            // Floating quick navigation
            VStack {
                Spacer()
                floatingQuickNav
            }

            // Top navigation bar
            VStack {
                topNavBar
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
    }

    // MARK: - Section Anchor

    private func sectionAnchor(_ section: SanctuarySection) -> some View {
        Color.clear
            .frame(height: 1)
            .id(section)
    }

    // MARK: - Ambient Background

    private var ambientBackground: some View {
        ZStack {
            Color(hex: "0A0908")
                .ignoresSafeArea()

            // Dynamic ambient glow based on active section
            RadialGradient(
                colors: [
                    activeSection.accentColor.opacity(0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.8), value: activeSection)

            // Floating particles effect
            FloatingSanctuaryParticles()
                .opacity(0.3)
        }
    }

    // MARK: - Top Navigation Bar

    private var topNavBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("Back")
                        .font(Typography.body)
                }
                .foregroundStyle(Color.accentGold)
            }

            Spacer()

            Text("Settings")
                .font(.custom("Cinzel-Regular", size: 18))
                .foregroundStyle(Color.primaryText)

            Spacer()

            // Placeholder for balance
            Color.clear.frame(width: 60)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(scrollOffset < -50 ? 1 : 0)
                .ignoresSafeArea()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Profile avatar with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.accentGold.opacity(0.3),
                                Color.accentGold.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(Color(hex: "1A1816"))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Text("JS")
                            .font(.custom("Cinzel-Regular", size: 28))
                            .foregroundStyle(Color.accentGold)
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.accentGold.opacity(0.6), Color.accentGold.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }
            }

            VStack(spacing: AppTheme.Spacing.xs) {
                Text("John Smith")
                    .font(.custom("Cinzel-Regular", size: 22))
                    .foregroundStyle(Color.primaryText)

                Text("Premium Member")
                    .font(Typography.caption)
                    .foregroundStyle(Color.accentGold)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(Color.accentGold.opacity(0.15))
                    )
            }
        }
        .padding(.bottom, AppTheme.Spacing.lg)
    }

    // MARK: - AI Section

    private var aiSection: some View {
        FloatingSectionCard(
            title: "AI & Insights",
            icon: "sparkles",
            accentColor: .accentGold
        ) {
            VStack(spacing: 0) {
                FloatingToggleRow(
                    title: "Scholar Insights",
                    subtitle: "AI-powered verse analysis and context",
                    icon: "brain.head.profile",
                    isOn: $aiInsightsEnabled
                )

                FloatingDivider()

                FloatingToggleRow(
                    title: "Scholar Mode",
                    subtitle: "Advanced theological commentary",
                    icon: "graduationcap.fill",
                    isOn: $scholarModeEnabled
                )

                FloatingDivider()

                FloatingToggleRow(
                    title: "Voice Guidance",
                    subtitle: "Audio narration of insights",
                    icon: "waveform",
                    isOn: $voiceGuidanceEnabled
                )

                FloatingDivider()

                FloatingNavigationRow(
                    title: "AI Preferences",
                    subtitle: "Customize insight types and depth",
                    icon: "slider.horizontal.3"
                )
            }
        }
    }

    // MARK: - Reading Section

    private var readingSection: some View {
        FloatingSectionCard(
            title: "Reading Experience",
            icon: "book.fill",
            accentColor: Color(hex: "6B8E9F")
        ) {
            VStack(spacing: 0) {
                // Font Size Slider
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    HStack {
                        Image(systemName: "textformat.size")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: "6B8E9F"))
                            .frame(width: 32)

                        Text("Font Size")
                            .font(Typography.body)
                            .foregroundStyle(Color.primaryText)

                        Spacer()

                        Text("\(Int(fontSize))pt")
                            .font(Typography.monospacedBody)
                            .foregroundStyle(Color.secondaryText)
                    }

                    FloatingSlider(value: $fontSize, range: 12...28)

                    // Preview text
                    Text("In the beginning was the Word...")
                        .font(.system(size: fontSize))
                        .foregroundStyle(Color.secondaryText)
                        .padding(.top, AppTheme.Spacing.xs)
                }
                .padding(AppTheme.Spacing.lg)

                FloatingDivider()

                // Theme Selection
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: "6B8E9F"))
                            .frame(width: 32)

                        Text("Theme")
                            .font(Typography.body)
                            .foregroundStyle(Color.primaryText)
                    }

                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(AppThemeOption.allCases) { theme in
                            ThemePill(
                                theme: theme,
                                isSelected: selectedTheme == theme
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedTheme = theme
                                }
                            }
                        }
                    }
                }
                .padding(AppTheme.Spacing.lg)

                FloatingDivider()

                FloatingNavigationRow(
                    title: "Typography",
                    subtitle: "Font family, line spacing, margins",
                    icon: "text.alignleft"
                )

                FloatingDivider()

                FloatingNavigationRow(
                    title: "Reading Modes",
                    subtitle: "Page curl, scroll, continuous",
                    icon: "book.pages"
                )
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        FloatingSectionCard(
            title: "Account & Sync",
            icon: "person.crop.circle.fill",
            accentColor: Color(hex: "7A9E7A")
        ) {
            VStack(spacing: 0) {
                FloatingToggleRow(
                    title: "Cloud Sync",
                    subtitle: "Sync highlights and notes across devices",
                    icon: "icloud.fill",
                    isOn: $cloudSyncEnabled
                )

                FloatingDivider()

                FloatingNavigationRow(
                    title: "Subscription",
                    subtitle: "Premium • Renews Jan 2027",
                    icon: "crown.fill"
                )

                FloatingDivider()

                FloatingNavigationRow(
                    title: "Data & Privacy",
                    subtitle: "Export, delete, privacy settings",
                    icon: "hand.raised.fill"
                )

                FloatingDivider()

                FloatingNavigationRow(
                    title: "Sign Out",
                    subtitle: "john.smith@email.com",
                    icon: "rectangle.portrait.and.arrow.right",
                    showChevron: false,
                    isDestructive: true
                )
            }
        }
    }

    // MARK: - More Section

    private var moreSection: some View {
        FloatingSectionCard(
            title: "Notifications & More",
            icon: "bell.fill",
            accentColor: Color(hex: "9E7A8E")
        ) {
            VStack(spacing: 0) {
                FloatingToggleRow(
                    title: "Notifications",
                    subtitle: "Reading reminders and updates",
                    icon: "bell.badge.fill",
                    isOn: $notificationsEnabled
                )

                FloatingDivider()

                FloatingToggleRow(
                    title: "Daily Verse",
                    subtitle: "Morning inspiration widget",
                    icon: "sun.horizon.fill",
                    isOn: $dailyVerseEnabled
                )

                FloatingDivider()

                FloatingToggleRow(
                    title: "Haptic Feedback",
                    subtitle: "Tactile response for interactions",
                    icon: "hand.tap.fill",
                    isOn: $hapticFeedback
                )

                FloatingDivider()

                FloatingNavigationRow(
                    title: "About",
                    subtitle: "Version 1.0.0 • What's New",
                    icon: "info.circle.fill"
                )
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            OrnamentalDivider(style: .simple)
                .frame(width: 40)
                .foregroundStyle(Color.accentGold.opacity(0.3))

            Text("Bible Study • Floating Sanctuary")
                .font(Typography.caption)
                .foregroundStyle(Color.tertiaryText)
        }
        .padding(.top, AppTheme.Spacing.xl)
    }

    // MARK: - Floating Quick Navigation

    private var floatingQuickNav: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            ForEach(SanctuarySection.allCases) { section in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        activeSection = section
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: section.icon)
                            .font(.system(size: 16, weight: .medium))

                        Text(section.shortTitle)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(activeSection == section ? Color.accentGold : Color.secondaryText)
                    .frame(width: 56, height: 50)
                    .background {
                        if activeSection == section {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accentGold.opacity(0.15))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .strokeBorder(Color.accentGold.opacity(0.2), lineWidth: 0.5)
                }
        }
        .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
        .padding(.bottom, AppTheme.Spacing.xl)
    }
}

// MARK: - Sanctuary Section

enum SanctuarySection: String, CaseIterable, Identifiable {
    case ai, reading, account, more

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .ai: return "sparkles"
        case .reading: return "book.fill"
        case .account: return "person.fill"
        case .more: return "ellipsis"
        }
    }

    var shortTitle: String {
        switch self {
        case .ai: return "AI"
        case .reading: return "Read"
        case .account: return "Account"
        case .more: return "More"
        }
    }

    var accentColor: Color {
        switch self {
        case .ai: return .accentGold
        case .reading: return Color(hex: "6B8E9F")
        case .account: return Color(hex: "7A9E7A")
        case .more: return Color(hex: "9E7A8E")
        }
    }
}

// MARK: - Floating Section Card

struct FloatingSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let accentColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accentColor)

                Text(title)
                    .font(.custom("Cinzel-Regular", size: 14))
                    .foregroundStyle(accentColor)
                    .textCase(.uppercase)
                    .kerning(1.5)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.md)

            // Content card
            content
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                        .fill(Color(hex: "141210"))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.3),
                                    accentColor.opacity(0.1),
                                    accentColor.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
                .shadow(color: accentColor.opacity(0.1), radius: 20, y: 8)
        }
    }
}

// MARK: - Floating Toggle Row

struct FloatingToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.secondaryText)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.body)
                    .foregroundStyle(Color.primaryText)

                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(Color.tertiaryText)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(GoldToggleStyle())
                .labelsHidden()
        }
        .padding(AppTheme.Spacing.lg)
    }
}

// MARK: - Floating Navigation Row

struct FloatingNavigationRow: View {
    let title: String
    let subtitle: String
    let icon: String
    var showChevron: Bool = true
    var isDestructive: Bool = false

    var body: some View {
        Button {
            // Navigation action
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isDestructive ? Color(hex: "C94A4A") : Color.secondaryText)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.body)
                        .foregroundStyle(isDestructive ? Color(hex: "C94A4A") : Color.primaryText)

                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Color.tertiaryText)
                }

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Floating Divider

struct FloatingDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
            .padding(.leading, 56)
    }
}

// MARK: - Floating Slider

struct FloatingSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 6)

                // Filled track
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentGold.opacity(0.8), Color.accentGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: thumbPosition(in: geometry.size.width), height: 6)

                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: Color.accentGold.opacity(0.4), radius: 8)
                    .offset(x: thumbPosition(in: geometry.size.width) - 12)
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
        .frame(height: 24)
    }

    private func thumbPosition(in width: CGFloat) -> CGFloat {
        let percentage = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return CGFloat(percentage) * width
    }
}

// MARK: - Theme Pill

struct ThemePill: View {
    let theme: AppThemeOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Circle()
                    .fill(theme.previewColor)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                isSelected ? Color.accentGold : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    }

                Text(theme.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? Color.accentGold : Color.secondaryText)
            }
            .padding(.vertical, AppTheme.Spacing.sm)
            .padding(.horizontal, AppTheme.Spacing.md)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentGold.opacity(0.1))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Theme Option

enum AppThemeOption: String, CaseIterable, Identifiable {
    case light, dark, sepia, oled

    var id: String { rawValue }

    var name: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .sepia: return "Sepia"
        case .oled: return "OLED"
        }
    }

    var previewColor: Color {
        switch self {
        case .light: return Color(hex: "FBF7F0")
        case .dark: return Color(hex: "1A1816")
        case .sepia: return Color(hex: "F5EDE0")
        case .oled: return Color(hex: "000000")
        }
    }
}

// MARK: - Gold Toggle Style

struct GoldToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            ZStack {
                Capsule()
                    .fill(configuration.isOn ? Color.accentGold : Color.white.opacity(0.15))
                    .frame(width: 50, height: 30)

                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .offset(x: configuration.isOn ? 10 : -10)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    configuration.isOn.toggle()
                }
            }
        }
    }
}

// MARK: - Floating Sanctuary Particles

struct FloatingSanctuaryParticles: View {
    @State private var particles: [SanctuaryParticle] = (0..<20).map { _ in SanctuaryParticle() }

    var body: some View {
        GeometryReader { geometry in
            ForEach(particles) { particle in
                Circle()
                    .fill(Color.accentGold)
                    .frame(width: particle.size, height: particle.size)
                    .position(
                        x: particle.x * geometry.size.width,
                        y: particle.y * geometry.size.height
                    )
                    .opacity(particle.opacity)
                    .blur(radius: particle.blur)
            }
        }
        .onAppear {
            animateParticles()
        }
    }

    private func animateParticles() {
        for index in particles.indices {
            let delay = Double.random(in: 0...3)
            let duration = Double.random(in: 8...15)

            withAnimation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true)
                .delay(delay)
            ) {
                particles[index].y = CGFloat.random(in: 0...1)
                particles[index].opacity = Double.random(in: 0.1...0.4)
            }
        }
    }
}

struct SanctuaryParticle: Identifiable {
    let id = UUID()
    var x: CGFloat = .random(in: 0...1)
    var y: CGFloat = .random(in: 0...1)
    var size: CGFloat = .random(in: 2...6)
    var opacity: Double = .random(in: 0.1...0.3)
    var blur: CGFloat = .random(in: 0...2)
}

// MARK: - Scroll Offset Key

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FloatingSanctuarySettings()
    }
}

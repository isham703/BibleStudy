import SwiftUI

// MARK: - Divine Hub Settings
/// A bold hub-and-spoke navigation design with prominent iconography,
/// quick-access toggle grid, and expandable category panels.

struct DivineHubSettings: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expandedCategory: HubCategory?
    @State private var showProfileSheet = false

    // Quick toggles state
    @State private var aiEnabled = true
    @State private var darkMode = true
    @State private var syncEnabled = true
    @State private var notificationsEnabled = true

    // Detailed settings state
    @State private var scholarMode = false
    @State private var voiceNarration = false
    @State private var fontSize: Double = 18
    @State private var hapticFeedback = true
    @State private var dailyVerse = true

    var body: some View {
        ZStack {
            // Background
            hubBackground

            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    headerSection

                    quickAccessGrid

                    categoryHubs

                    footerSection
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, 60)
                .padding(.bottom, Theme.Spacing.xxl)
            }

            // Top bar
            VStack {
                topBar
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Hub Background

    private var hubBackground: some View {
        ZStack {
            Color.surfaceDeep
                .ignoresSafeArea()

            // Radial hub glow
            RadialGradient(
                colors: [
                    Color.accentBronze.opacity(Theme.Opacity.faint),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Grid pattern overlay
            GridPatternView()
                .opacity(Theme.Opacity.faint)
                .ignoresSafeArea()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(Typography.Icon.md)
                    .foregroundStyle(Color.secondaryText)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(Theme.Opacity.faint))
                    )
            }

            Spacer()

            Text("SETTINGS")
                .font(Typography.Icon.xs.weight(.bold))
                .foregroundStyle(Color.tertiaryText)
                .kerning(3)

            Spacer()

            Button {
                showProfileSheet = true
            } label: {
                Circle()
                    .fill(Color.accentBronze.opacity(Theme.Opacity.light))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Text("JS")
                            .font(Typography.Icon.xs.weight(.bold))
                            .foregroundStyle(Color.accentBronze)
                    }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial.opacity(Theme.Opacity.medium))
                .ignoresSafeArea()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Central hub icon
            ZStack {
                // Outer glow rings
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.accentBronze.opacity(0.1 - Double(index) * 0.03), lineWidth: 1)
                        .frame(width: 120 + CGFloat(index) * 40)
                }

                // Main hub
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.accentBronze.opacity(Theme.Opacity.subtle),
                                Color.accentBronze.opacity(Theme.Opacity.overlay)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay {
                        Image(systemName: "gearshape.2.fill")
                            .font(Typography.Icon.hero)
                            .foregroundStyle(Color.accentBronze)
                    }
            }
            .padding(.vertical, Theme.Spacing.lg)

            Text("Control Center")
                .font(.custom("Cinzel-Regular", size: 24))
                .foregroundStyle(Color.primaryText)

            Text("Tap to toggle • Hold for details")
                .font(Typography.caption)
                .foregroundStyle(Color.tertiaryText)
        }
    }

    // MARK: - Quick Access Grid

    private var quickAccessGrid: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text("QUICK ACCESS")
                .font(Typography.Icon.xxs.weight(.bold))
                .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.heavy))
                .kerning(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Theme.Spacing.md),
                    GridItem(.flexible(), spacing: Theme.Spacing.md)
                ],
                spacing: Theme.Spacing.md
            ) {
                QuickToggleTile(
                    icon: "sparkles",
                    title: "AI Insights",
                    isOn: $aiEnabled,
                    color: Color.accentBronze
                )

                QuickToggleTile(
                    icon: "moon.fill",
                    title: "Dark Mode",
                    isOn: $darkMode,
                    color: Color(hex: "6B7A9E")
                )

                QuickToggleTile(
                    icon: "icloud.fill",
                    title: "Cloud Sync",
                    isOn: $syncEnabled,
                    color: Color(hex: "6B9E8F")
                )

                QuickToggleTile(
                    icon: "bell.fill",
                    title: "Notifications",
                    isOn: $notificationsEnabled,
                    color: Color(hex: "9E6B7A")
                )
            }
        }
        .padding(.top, Theme.Spacing.lg)
    }

    // MARK: - Category Hubs

    private var categoryHubs: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text("CATEGORIES")
                .font(Typography.Icon.xxs.weight(.bold))
                .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.heavy))
                .kerning(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Theme.Spacing.lg)

            ForEach(HubCategory.allCases) { category in
                CategoryHub(
                    category: category,
                    isExpanded: expandedCategory == category,
                    onTap: {
                        withAnimation(Theme.Animation.settle) {
                            if expandedCategory == category {
                                expandedCategory = nil
                            } else {
                                expandedCategory = category
                            }
                        }
                    }
                ) {
                    expandedContent(for: category)
                }
            }
        }
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private func expandedContent(for category: HubCategory) -> some View {
        switch category {
        case .ai:
            VStack(spacing: Theme.Spacing.md) {
                HubToggleRow(
                    title: "Scholar Mode",
                    subtitle: "Advanced theological analysis",
                    isOn: $scholarMode
                )
                HubToggleRow(
                    title: "Voice Narration",
                    subtitle: "Audio guidance for insights",
                    isOn: $voiceNarration
                )
                HubNavigationRow(title: "AI Preferences", subtitle: "Customize insight depth")
            }

        case .reading:
            VStack(spacing: Theme.Spacing.md) {
                // Font size mini slider
                HStack {
                    Text("Font Size")
                        .font(Typography.body)
                        .foregroundStyle(Color.primaryText)

                    Spacer()

                    HStack(spacing: Theme.Spacing.md) {
                        Button {
                            if fontSize > 12 { fontSize -= 2 }
                        } label: {
                            Image(systemName: "minus")
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.white.opacity(Theme.Opacity.overlay)))
                        }

                        Text("\(Int(fontSize))")
                            .font(Typography.monospacedBody)
                            .foregroundStyle(Color.accentBronze)
                            .frame(width: 30)

                        Button {
                            if fontSize < 32 { fontSize += 2 }
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.white.opacity(Theme.Opacity.overlay)))
                        }
                    }
                    .foregroundStyle(Color.secondaryText)
                }
                .padding(.vertical, Theme.Spacing.xs)

                HubNavigationRow(title: "Typography", subtitle: "Fonts, spacing, margins")
                HubNavigationRow(title: "Theme", subtitle: "Light, Dark, Sepia, OLED")
                HubNavigationRow(title: "Reading Mode", subtitle: "Scroll, Page Curl")
            }

        case .account:
            VStack(spacing: Theme.Spacing.md) {
                HubNavigationRow(title: "Profile", subtitle: "john.smith@email.com")
                HubNavigationRow(title: "Subscription", subtitle: "Premium • Active")
                HubNavigationRow(title: "Data & Privacy", subtitle: "Export, delete data")
                HubDestructiveRow(title: "Sign Out")
            }

        case .more:
            VStack(spacing: Theme.Spacing.md) {
                HubToggleRow(
                    title: "Daily Verse",
                    subtitle: "Morning inspiration",
                    isOn: $dailyVerse
                )
                HubToggleRow(
                    title: "Haptic Feedback",
                    subtitle: "Tactile responses",
                    isOn: $hapticFeedback
                )
                HubNavigationRow(title: "About", subtitle: "Version 1.0.0")
                HubNavigationRow(title: "Help & Support", subtitle: "FAQs, contact us")
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Decorative spokes
            HStack(spacing: Theme.Spacing.lg) {
                ForEach(0..<5) { _ in
                    Circle()
                        .fill(Color.accentBronze.opacity(Theme.Opacity.light))
                        .frame(width: 6, height: 6)
                }
            }

            Text("Divine Hub Design")
                .font(Typography.caption)
                .foregroundStyle(Color.tertiaryText)
        }
        .padding(.top, Theme.Spacing.xxl)
    }
}

// MARK: - Hub Category

enum HubCategory: String, CaseIterable, Identifiable {
    case ai = "AI & Intelligence"
    case reading = "Reading Experience"
    case account = "Account & Sync"
    case more = "More Options"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .ai: return "brain.head.profile"
        case .reading: return "book.fill"
        case .account: return "person.crop.circle.fill"
        case .more: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .ai: return Color.accentBronze
        case .reading: return Color(hex: "6B8E9F")
        case .account: return Color(hex: "7A9E7A")
        case .more: return Color(hex: "9E7A8E")
        }
    }

    var itemCount: Int {
        switch self {
        case .ai: return 3
        case .reading: return 4
        case .account: return 4
        case .more: return 4
        }
    }
}

// MARK: - Quick Toggle Tile

struct QuickToggleTile: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let color: Color

    @State private var isPressed = false

    var body: some View {
        Button {
            withAnimation(Theme.Animation.settle) {
                isOn.toggle()
            }
        } label: {
            VStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(isOn ? color.opacity(Theme.Opacity.light) : Color.white.opacity(Theme.Opacity.faint))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(Typography.Icon.lg)
                        .foregroundStyle(isOn ? color : Color.tertiaryText)
                }

                Text(title)
                    .font(Typography.Icon.xs)
                    .foregroundStyle(isOn ? Color.primaryText : Color.tertiaryText)

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(isOn ? color : Color.tertiaryText.opacity(Theme.Opacity.medium))
                        .frame(width: 6, height: 6)

                    Text(isOn ? "ON" : "OFF")
                        .font(Typography.Icon.xxs.weight(.bold))
                        .foregroundStyle(isOn ? color : Color.tertiaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(Color.white.opacity(isOn ? 0.05 : 0.02))
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.lg)
                            .strokeBorder(
                                isOn ? color.opacity(Theme.Opacity.subtle) : Color.white.opacity(Theme.Opacity.faint),
                                lineWidth: 1
                            )
                    }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
                }
        )
    }
}

// MARK: - Category Hub

struct CategoryHub<Content: View>: View {
    let category: HubCategory
    let isExpanded: Bool
    let onTap: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onTap) {
                HStack(spacing: Theme.Spacing.lg) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(Theme.Opacity.divider))
                            .frame(width: 48, height: 48)

                        Image(systemName: category.icon)
                            .font(Typography.Command.title3)
                            .foregroundStyle(category.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.rawValue)
                            .font(.custom("Cinzel-Regular", size: 16))
                            .foregroundStyle(Color.primaryText)

                        Text("\(category.itemCount) options")
                            .font(Typography.caption)
                            .foregroundStyle(Color.tertiaryText)
                    }

                    Spacer()

                    // Expand indicator
                    Image(systemName: "chevron.right")
                        .font(Typography.Command.caption.weight(.semibold))
                        .foregroundStyle(category.color)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(Theme.Spacing.lg)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(category.color.opacity(Theme.Opacity.light))
                        .frame(height: 1)

                    content
                        .padding(Theme.Spacing.lg)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Color.white.opacity(Theme.Opacity.faint))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .strokeBorder(
                            isExpanded ? category.color.opacity(Theme.Opacity.subtle) : Color.white.opacity(Theme.Opacity.faint),
                            lineWidth: 1
                        )
                }
        )
    }
}

// MARK: - Hub Toggle Row

struct HubToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
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
        .padding(.vertical, Theme.Spacing.xs)
    }
}

// MARK: - Hub Navigation Row

struct HubNavigationRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        Button {
            // Navigate
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.body)
                        .foregroundStyle(Color.primaryText)

                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Color.tertiaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Icon.xs)
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hub Destructive Row

struct HubDestructiveRow: View {
    let title: String

    var body: some View {
        Button {
            // Action
        } label: {
            HStack {
                Text(title)
                    .font(Typography.body)
                    .foregroundStyle(Color(hex: "C94A4A"))

                Spacer()

                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color(hex: "C94A4A"))
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Sheet

struct ProfileSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
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
                    .frame(width: 100, height: 100)

                Text("JS")
                    .font(.custom("Cinzel-Regular", size: 36))
                    .foregroundStyle(Color.accentBronze)
            }
            .padding(.top, Theme.Spacing.xl)

            VStack(spacing: Theme.Spacing.xs) {
                Text("John Smith")
                    .font(.custom("Cinzel-Regular", size: 24))
                    .foregroundStyle(Color.primaryText)

                Text("john.smith@email.com")
                    .font(Typography.body)
                    .foregroundStyle(Color.secondaryText)

                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "crown.fill")
                        .font(Typography.Command.caption)
                    Text("Premium Member")
                        .font(Typography.Command.meta)
                }
                .foregroundStyle(Color.accentBronze)
                .padding(.top, Theme.Spacing.sm)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(Typography.body)
                    .foregroundStyle(Color.accentBronze)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.md)
                            .fill(Color.accentBronze.opacity(Theme.Opacity.divider))
                    )
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Color(hex: "141210"))
    }
}

// MARK: - Grid Pattern View

struct GridPatternView: View {
    var body: some View {
        Canvas { context, size in
            let gridSize: CGFloat = 30

            // Vertical lines
            for x in stride(from: 0, to: size.width, by: gridSize) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.white), lineWidth: 0.5)
            }

            // Horizontal lines
            for y in stride(from: 0, to: size.height, by: gridSize) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.white), lineWidth: 0.5)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DivineHubSettings()
    }
}
